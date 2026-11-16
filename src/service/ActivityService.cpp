#include "ActivityService.h"
#include "persistence/JsonStore.h"
#include <QDate>
#include <QCoreApplication>

#if defined(QT_WIDGETS_LIB)
#include <QApplication>
#include <QSystemTrayIcon>
#include <QIcon>
#endif
#include <QString>
#include <QTimer>

// ─────────────────────────────────────────────────────────────────────────────
// Constructor
//
// 'new ActivityListModel(this)' — allocates model on the heap.
//   - 'this' is passed as the parent, so Qt will automatically delete
//     m_model when ActivityService is destroyed (RAII ownership tree).
//   - JS equivalent: this.model = new ActivityListModel();
//     but in Qt, the parent handles cleanup — no manual delete needed.
// ─────────────────────────────────────────────────────────────────────────────
ActivityService::ActivityService(QObject *parent)
    : QObject(parent)
    , m_model(new ActivityListModel(this))   // parent = this → auto-deleted
{
    // Load persisted data on startup
    const QVector<Activity> saved = JsonStore::load();
    if (!saved.isEmpty())
        m_model->resetWith(saved);

    // Keep stats in sync whenever model row count changes
    connect(m_model, &ActivityListModel::countChanged, this, &ActivityService::statsChanged);

    // Initialize native OS notification tray icon (with graceful in-app fallback)
#if defined(QT_WIDGETS_LIB)
    if (qobject_cast<QApplication*>(QCoreApplication::instance()) && QSystemTrayIcon::isSystemTrayAvailable()) {
        m_trayIcon = new QSystemTrayIcon(this);
        m_trayIcon->setIcon(QIcon(":/qt/qml/ActivityTracker/resources/icons/app_icon.svg"));
        m_trayIcon->setToolTip("CVS Activity Tracker");
        m_trayIcon->show();
    }
#endif

    // Heartbeat timer checking for start & due schedule reminders every 30 seconds
    connect(&m_reminderTimer, &QTimer::timeout, this, &ActivityService::checkReminders);
    m_reminderTimer.start(30000);

    // Immediate initial schedule evaluation on application startup
    QTimer::singleShot(500, this, &ActivityService::checkReminders);
}

// ─────────────────────────────────────────────────────────────────────────────
// totalDurationToday — computed property (no cache; recalculated on each read)
//
// STL-style: std::accumulate would also work, but a plain loop is clearer here.
// ─────────────────────────────────────────────────────────────────────────────
int ActivityService::totalDurationToday() const
{
    const QDate today = QDate::currentDate();
    int total = 0;
    for (const Activity &a : m_model->activities()) {
        if (a.createdAt.date() == today)
            total += a.durationMinutes;
    }
    return total;
}

int ActivityService::totalDurationAllTime() const
{
    int total = 0;
    for (const Activity &a : m_model->activities()) {
        total += a.durationMinutes;
    }
    return total;
}

int ActivityService::completedCount() const
{
    int count = 0;
    for (const Activity &a : m_model->activities()) {
        if (a.done) ++count;
    }
    return count;
}

int ActivityService::pendingCount() const
{
    return m_model->count() - completedCount();
}

int ActivityService::completionPercentage() const
{
    const int total = m_model->count();
    if (total == 0) return 0;
    return (completedCount() * 100) / total;
}

// ─────────────────────────────────────────────────────────────────────────────
// addActivity
// ─────────────────────────────────────────────────────────────────────────────
void ActivityService::addActivity(const QString &name,
                                  const QString &category,
                                  int durationMinutes,
                                  const QString &priority)
{
    // Input validation — emit an error signal instead of crashing
    if (name.trimmed().isEmpty()) {
        Q_EMIT errorOccurred("Activity name cannot be empty.");
        return;
    }
    if (durationMinutes <= 0) {
        Q_EMIT errorOccurred("Duration must be greater than 0.");
        return;
    }

    const Activity activity = Activity::create(name.trimmed(), category, durationMinutes, priority);
    m_model->addActivity(activity);
    save();
    Q_EMIT totalDurationTodayChanged();
}

// ─────────────────────────────────────────────────────────────────────────────
// removeActivity (Optimistic UI: stashes deleted item for Undo action)
// ─────────────────────────────────────────────────────────────────────────────
void ActivityService::removeActivity(int index)
{
    if (index < 0 || index >= m_model->count()) {
        Q_EMIT errorOccurred("Invalid activity index.");
        return;
    }

    m_lastDeletedActivity = m_model->activities().at(index);
    m_lastDeletedIndex = index;
    m_canUndo = true;

    m_model->removeActivity(index);
    save();

    Q_EMIT totalDurationTodayChanged();
    Q_EMIT canUndoChanged();
    Q_EMIT lastDeletedNameChanged();
    Q_EMIT activityRemoved(m_lastDeletedActivity.name);
}

// ─────────────────────────────────────────────────────────────────────────────
// undoLastDelete (Restores last deleted activity to its original position)
// ─────────────────────────────────────────────────────────────────────────────
void ActivityService::undoLastDelete()
{
    if (!m_canUndo || m_lastDeletedActivity.name.isEmpty()) {
        return;
    }

    m_model->insertActivity(m_lastDeletedIndex, m_lastDeletedActivity);
    m_canUndo = false;
    save();

    Q_EMIT totalDurationTodayChanged();
    Q_EMIT canUndoChanged();
    Q_EMIT lastDeletedNameChanged();
}

// ─────────────────────────────────────────────────────────────────────────────
// triggerSync (Simulates / triggers cloud DB sync cycle)
// ─────────────────────────────────────────────────────────────────────────────
void ActivityService::triggerSync()
{
    m_syncStatus = "syncing";
    Q_EMIT syncStatusChanged();

    QTimer::singleShot(800, this, [this]() {
        m_syncStatus = "synced";
        Q_EMIT syncStatusChanged();
    });
}

// ─────────────────────────────────────────────────────────────────────────────
// refresh (Reloads persisted activities from disk/DB and refreshes all metrics)
// ─────────────────────────────────────────────────────────────────────────────
void ActivityService::refresh()
{
    m_syncStatus = "syncing";
    Q_EMIT syncStatusChanged();

    const QVector<Activity> loaded = JsonStore::load();
    m_model->resetWith(loaded);

    Q_EMIT totalDurationTodayChanged();
    Q_EMIT statsChanged();
    Q_EMIT completedCountChanged();

    QTimer::singleShot(500, this, [this]() {
        m_syncStatus = "synced";
        Q_EMIT syncStatusChanged();
        Q_EMIT dataRefreshed();
    });
}

// ─────────────────────────────────────────────────────────────────────────────
// markComplete
// ─────────────────────────────────────────────────────────────────────────────
void ActivityService::markComplete(int index)
{
    if (index < 0 || index >= m_model->count()) {
        Q_EMIT errorOccurred("Invalid activity index.");
        return;
    }

    m_model->setDone(index, true);
    save();
    Q_EMIT completedCountChanged();
    Q_EMIT statsChanged();
}

// ─────────────────────────────────────────────────────────────────────────────
// setActivityStatus ("Created" | "In Progress" | "Done")
// ─────────────────────────────────────────────────────────────────────────────
void ActivityService::setActivityStatus(int index, const QString &status)
{
    if (index < 0 || index >= m_model->count()) {
        Q_EMIT errorOccurred("Invalid activity index.");
        return;
    }

    m_model->setStatus(index, status);
    save();
    Q_EMIT completedCountChanged();
    Q_EMIT statsChanged();
}

// ─────────────────────────────────────────────────────────────────────────────
// setActivityPriority ("Urgent" | "High" | "Medium" | "Low")
// ─────────────────────────────────────────────────────────────────────────────
void ActivityService::setActivityPriority(int index, const QString &priority)
{
    if (index < 0 || index >= m_model->count() || priority.trimmed().isEmpty()) {
        Q_EMIT errorOccurred("Invalid activity priority parameters.");
        return;
    }

    m_model->setPriority(index, priority);
    save();
}

// ─────────────────────────────────────────────────────────────────────────────
// updateActivity (Edits all activity properties in-place)
// ─────────────────────────────────────────────────────────────────────────────
void ActivityService::updateActivity(int index,
                                     const QString &name,
                                     const QString &category,
                                     int durationMinutes,
                                     const QString &status,
                                     const QString &priority)
{
    if (index < 0 || index >= m_model->count()) {
        Q_EMIT errorOccurred("Invalid activity index.");
        return;
    }
    if (name.trimmed().isEmpty()) {
        Q_EMIT errorOccurred("Activity name cannot be empty.");
        return;
    }
    if (durationMinutes <= 0) {
        Q_EMIT errorOccurred("Duration must be greater than 0.");
        return;
    }

    m_model->updateActivity(index, name.trimmed(), category, durationMinutes, status, priority);
    save();
    Q_EMIT totalDurationTodayChanged();
    Q_EMIT completedCountChanged();
    Q_EMIT statsChanged();
}

// ─────────────────────────────────────────────────────────────────────────────
// reopenActivity (Reopens a finished task back into active progress)
// ─────────────────────────────────────────────────────────────────────────────
void ActivityService::reopenActivity(int index)
{
    if (index < 0 || index >= m_model->count()) {
        Q_EMIT errorOccurred("Invalid activity index.");
        return;
    }

    m_model->setStatus(index, "In Progress");
    save();
    Q_EMIT completedCountChanged();
    Q_EMIT statsChanged();
}

// ─────────────────────────────────────────────────────────────────────────────
// extendActivity (Adds additional minutes to existing activity in-place)
// ─────────────────────────────────────────────────────────────────────────────
void ActivityService::extendActivity(int index, int additionalMinutes)
{
    if (index < 0 || index >= m_model->count() || additionalMinutes <= 0) {
        Q_EMIT errorOccurred("Invalid extension parameters.");
        return;
    }

    m_model->incrementExtension(index, additionalMinutes);
    save();
    Q_EMIT totalDurationTodayChanged();
    Q_EMIT statsChanged();
}

// ─────────────────────────────────────────────────────────────────────────────
// createExtension (Forks a follow-up activity for the task)
// ─────────────────────────────────────────────────────────────────────────────
void ActivityService::createExtension(int index, int minutes)
{
    if (index < 0 || index >= m_model->count()) {
        Q_EMIT errorOccurred("Invalid activity index.");
        return;
    }

    const Activity &parent = m_model->activities().at(index);
    const QString newName = parent.name + " (Extension)";
    addActivity(newName, parent.category, minutes > 0 ? minutes : 15);
}

// ─────────────────────────────────────────────────────────────────────────────
// save — private helper; always call after any mutation
// ─────────────────────────────────────────────────────────────────────────────
void ActivityService::save()
{
    m_syncStatus = "syncing";
    Q_EMIT syncStatusChanged();

    if (!JsonStore::save(m_model->activities())) {
        m_syncStatus = "offline";
        Q_EMIT syncStatusChanged();
        Q_EMIT errorOccurred("Failed to save activities to disk.");
        return;
    }

    // Flash syncing -> synced to give tactile feedback
    QTimer::singleShot(600, this, [this]() {
        m_syncStatus = "synced";
        Q_EMIT syncStatusChanged();
    });
}

// ─────────────────────────────────────────────────────────────────────────────
// addActivityWithSchedule
// ─────────────────────────────────────────────────────────────────────────────
void ActivityService::addActivityWithSchedule(const QString &name,
                                             const QString &category,
                                             int durationMinutes,
                                             const QString &priority,
                                             const QString &startTimeIso,
                                             const QString &endTimeIso,
                                             bool reminderEnabled)
{
    const QString trimmed = name.trimmed();
    if (trimmed.isEmpty()) {
        Q_EMIT errorOccurred("Activity name cannot be empty.");
        return;
    }

    QDateTime start;
    if (!startTimeIso.trimmed().isEmpty()) {
        start = QDateTime::fromString(startTimeIso.trimmed(), Qt::ISODate);
    }

    QDateTime end;
    if (!endTimeIso.trimmed().isEmpty()) {
        end = QDateTime::fromString(endTimeIso.trimmed(), Qt::ISODate);
    }

    int dur = durationMinutes;
    if (start.isValid() && end.isValid() && end > start) {
        int diffMins = static_cast<int>(start.secsTo(end) / 60);
        if (dur <= 0 || dur != diffMins) {
            dur = diffMins;
        }
    } else if (dur <= 0) {
        dur = 30;
    }

    if (start.isValid() && !end.isValid() && dur > 0) {
        end = start.addSecs(dur * 60);
    }

    Activity a = Activity::create(trimmed,
                                 category.isEmpty() ? "Work" : category,
                                 dur,
                                 priority.isEmpty() ? "Medium" : priority,
                                 start,
                                 end,
                                 reminderEnabled);

    m_model->addActivity(a);
    save();

    Q_EMIT totalDurationTodayChanged();
    Q_EMIT statsChanged();
}

// ─────────────────────────────────────────────────────────────────────────────
// updateActivitySchedule
// ─────────────────────────────────────────────────────────────────────────────
void ActivityService::updateActivitySchedule(int index,
                                            const QString &name,
                                            const QString &category,
                                            int durationMinutes,
                                            const QString &status,
                                            const QString &priority,
                                            const QString &startTimeIso,
                                            const QString &endTimeIso,
                                            bool reminderEnabled)
{
    if (index < 0 || index >= m_model->count())
        return;

    const QString trimmed = name.trimmed();
    if (trimmed.isEmpty()) {
        Q_EMIT errorOccurred("Activity name cannot be empty.");
        return;
    }

    QDateTime start;
    if (!startTimeIso.trimmed().isEmpty()) {
        start = QDateTime::fromString(startTimeIso.trimmed(), Qt::ISODate);
    }

    QDateTime end;
    if (!endTimeIso.trimmed().isEmpty()) {
        end = QDateTime::fromString(endTimeIso.trimmed(), Qt::ISODate);
    }

    int dur = durationMinutes;
    if (start.isValid() && end.isValid() && end > start) {
        int diffMins = static_cast<int>(start.secsTo(end) / 60);
        if (dur <= 0) dur = diffMins;
    } else if (dur <= 0) {
        dur = 30;
    }

    m_model->updateActivity(index, trimmed, category, dur, status, priority, start, end, reminderEnabled);
    save();

    Q_EMIT totalDurationTodayChanged();
    Q_EMIT statsChanged();
}

// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
// snoozeActivity (Snoozes reminders for N minutes without overwriting actual duration)
// ─────────────────────────────────────────────────────────────────────────────
void ActivityService::snoozeActivity(int index, int minutes)
{
    if (index < 0 || index >= m_model->count() || minutes <= 0)
        return;

    const QDateTime snoozeDeadline = QDateTime::currentDateTime().addSecs(minutes * 60);
    m_model->setSnoozedUntil(index, snoozeDeadline);
    m_model->setEndNotified(index, false); // Reset so it will notify when deadline arrives
    save();

    Q_EMIT statsChanged();
}

// ─────────────────────────────────────────────────────────────────────────────
// setReminderEnabled
// ─────────────────────────────────────────────────────────────────────────────
void ActivityService::setReminderEnabled(int index, bool enabled)
{
    if (index < 0 || index >= m_model->count())
        return;

    m_model->setReminderEnabled(index, enabled);
    save();
}

// ─────────────────────────────────────────────────────────────────────────────
// showDesktopNotification (Native OS tray toast with in-app fallback)
// ─────────────────────────────────────────────────────────────────────────────
void ActivityService::showDesktopNotification(const QString &title, const QString &message)
{
#if defined(QT_WIDGETS_LIB)
    if (m_trayIcon && m_trayIcon->isVisible()) {
        m_trayIcon->showMessage(title, message, QIcon(":/qt/qml/ActivityTracker/resources/icons/app_icon.svg"), 5000);
    }
#else
    Q_UNUSED(title);
    Q_UNUSED(message);
#endif
}

// ─────────────────────────────────────────────────────────────────────────────
// checkReminders — 30-second heartbeat evaluating scheduled milestones
// ─────────────────────────────────────────────────────────────────────────────
void ActivityService::checkReminders()
{
    const QVector<Activity> &items = m_model->activities();
    const QDateTime now = QDateTime::currentDateTime();
    bool stateChanged = false;

    for (int i = 0; i < items.size(); ++i) {
        const Activity &a = items.at(i);

        // Acceptance criteria: Completed activities suppress future reminders
        if (a.done || !a.reminderEnabled || !a.hasSchedule())
            continue;

        // Snooze protection: suppress alerts until deadline expires
        if (a.snoozedUntil.isValid() && now < a.snoozedUntil)
            continue;

        // 1. Scheduled Start Milestone (Window: scheduledStartTime - 60s to + 5m)
        if (a.scheduledStartTime.isValid() && !a.startNotified) {
            if (now >= a.scheduledStartTime.addSecs(-60) && now <= a.scheduledStartTime.addSecs(300)) {
                m_model->setStartNotified(i, true);
                stateChanged = true;
                const QString timeStr = a.scheduledStartTime.toLocalTime().toString("h:mm AP");
                const QString msg = QString("Activity '%1' is starting now (%2).").arg(a.name, timeStr);
                showDesktopNotification("CVS Activity: Starting Now", msg);
                Q_EMIT activityReminderTriggered(i, a.id, a.name, "start", msg);
            }
        }

        // 2. Scheduled End / Due Milestone (Window: at or past scheduledEndTime)
        if (a.scheduledEndTime.isValid() && !a.endNotified) {
            if (now >= a.scheduledEndTime.addSecs(-30)) {
                m_model->setEndNotified(i, true);
                stateChanged = true;
                const QString timeStr = a.scheduledEndTime.toLocalTime().toString("h:mm AP");
                const QString msg = QString("Activity '%1' is due / scheduled to end now (%2).").arg(a.name, timeStr);
                showDesktopNotification("CVS Activity: Due Now", msg);
                Q_EMIT activityReminderTriggered(i, a.id, a.name, "due", msg);
            }
        }
    }

    // Persist notification states immediately to prevent duplicate alerts on restart
    if (stateChanged) {
        save();
    }
}

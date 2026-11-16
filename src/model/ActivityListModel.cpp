#include "ActivityListModel.h"

// ─────────────────────────────────────────────────────────────────────────────
// Constructor
// Pass 'parent' up to QAbstractListModel so Qt's ownership tree is correct.
// ─────────────────────────────────────────────────────────────────────────────
ActivityListModel::ActivityListModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

// ─────────────────────────────────────────────────────────────────────────────
// rowCount — how many rows does this model have?
// QML's ListView calls this to know how many delegates to create.
// The 'parent' check is boilerplate for list models (always empty/invalid).
// ─────────────────────────────────────────────────────────────────────────────
int ActivityListModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;               // flat list: no tree children
    return m_activities.size();
}

// ─────────────────────────────────────────────────────────────────────────────
// data — return a single field for a given row + role
//
// QML calls: model.name  →  data(index, NameRole)
//
// QVariant is Qt's "any" type — can hold QString, int, bool, QDateTime, etc.
// Like TypeScript's 'any' but with runtime type safety (toInt(), toString()…).
// ─────────────────────────────────────────────────────────────────────────────
QVariant ActivityListModel::data(const QModelIndex &index, int role) const
{
    // Bounds check — always guard against invalid indices
    if (!index.isValid() || index.row() < 0 || index.row() >= m_activities.size())
        return {};               // default-constructed QVariant = null/undefined

    const Activity &activity = m_activities.at(index.row()); // const ref: no copy

    switch (role) {
    case IdRole:                 return activity.id;
    case NameRole:               return activity.name;
    case CategoryRole:           return activity.category;
    case DurationRole:           return activity.durationMinutes;
    case DoneRole:               return activity.done;
    case StatusRole:             return activity.status;
    case PriorityRole:           return activity.priority;
    case ExtensionCountRole:     return activity.extensionCount;
    case CreatedAtRole:          return activity.createdAt;
    case ScheduledStartTimeRole: return activity.scheduledStartTime.isValid() ? activity.scheduledStartTime.toString(Qt::ISODate) : QString();
    case ScheduledEndTimeRole:   return activity.scheduledEndTime.isValid() ? activity.scheduledEndTime.toString(Qt::ISODate) : QString();
    case ActualStartTimeRole:    return activity.actualStartTime.isValid() ? activity.actualStartTime.toString(Qt::ISODate) : QString();
    case ActualEndTimeRole:      return activity.actualEndTime.isValid() ? activity.actualEndTime.toString(Qt::ISODate) : QString();
    case ScheduledDurationRole:  return activity.scheduledDurationMinutes();
    case ReminderEnabledRole:    return activity.reminderEnabled;
    case ScheduleStatusRole:     return activity.scheduleStatus();
    case IsOverdueRole:          return activity.isOverdue();
    case SnoozedUntilRole:       return activity.snoozedUntil.isValid() ? activity.snoozedUntil.toString(Qt::ISODate) : QString();
    default:                     return {};
    }
}

QVariantMap ActivityListModel::get(int index) const
{
    if (index < 0 || index >= m_activities.size())
        return {};

    const Activity &activity = m_activities.at(index);
    return {
        { "activityId", activity.id },
        { "name", activity.name },
        { "category", activity.category },
        { "durationMinutes", activity.durationMinutes },
        { "done", activity.done },
        { "status", activity.status },
        { "priority", activity.priority },
        { "extensionCount", activity.extensionCount },
        { "createdAt", activity.createdAt },
        { "scheduledStartTime", activity.scheduledStartTime.isValid() ? activity.scheduledStartTime.toString(Qt::ISODate) : QString() },
        { "scheduledEndTime", activity.scheduledEndTime.isValid() ? activity.scheduledEndTime.toString(Qt::ISODate) : QString() },
        { "startTime", activity.scheduledStartTime.isValid() ? activity.scheduledStartTime.toString(Qt::ISODate) : QString() },
        { "endTime", activity.scheduledEndTime.isValid() ? activity.scheduledEndTime.toString(Qt::ISODate) : QString() },
        { "actualStartTime", activity.actualStartTime.isValid() ? activity.actualStartTime.toString(Qt::ISODate) : QString() },
        { "actualEndTime", activity.actualEndTime.isValid() ? activity.actualEndTime.toString(Qt::ISODate) : QString() },
        { "scheduledDurationMinutes", activity.scheduledDurationMinutes() },
        { "reminderEnabled", activity.reminderEnabled },
        { "scheduleStatus", activity.scheduleStatus() },
        { "isOverdue", activity.isOverdue() },
        { "snoozedUntil", activity.snoozedUntil.isValid() ? activity.snoozedUntil.toString(Qt::ISODate) : QString() }
    };
}

// ─────────────────────────────────────────────────────────────────────────────
// roleNames — map integer role IDs → QML property names
//
// This is what makes  model.name  work in a QML delegate.
// QByteArray is Qt's raw byte string (used for internal names, not display).
// ─────────────────────────────────────────────────────────────────────────────
QHash<int, QByteArray> ActivityListModel::roleNames() const
{
    return {
        { IdRole,                 "activityId"               },
        { NameRole,               "name"                     },
        { CategoryRole,           "category"                 },
        { DurationRole,           "durationMinutes"          },
        { DoneRole,               "done"                     },
        { StatusRole,             "status"                   },
        { PriorityRole,           "priority"                 },
        { ExtensionCountRole,     "extensionCount"           },
        { CreatedAtRole,          "createdAt"                },
        { ScheduledStartTimeRole, "scheduledStartTime"       },
        { ScheduledEndTimeRole,   "scheduledEndTime"         },
        { ActualStartTimeRole,    "actualStartTime"          },
        { ActualEndTimeRole,      "actualEndTime"            },
        { ScheduledDurationRole,  "scheduledDurationMinutes" },
        { ReminderEnabledRole,    "reminderEnabled"          },
        { ScheduleStatusRole,     "scheduleStatus"           },
        { IsOverdueRole,          "isOverdue"                },
        { SnoozedUntilRole,       "snoozedUntil"             }
    };
}

// ─────────────────────────────────────────────────────────────────────────────
// addActivity
//
// beginInsertRows / endInsertRows  ←  this is the Qt model notification protocol.
// Any ListView watching this model will automatically insert the new row.
// No manual re-render call, no state update function — Qt handles it.
// ─────────────────────────────────────────────────────────────────────────────
void ActivityListModel::addActivity(const Activity &activity)
{
    const int newRow = m_activities.size();
    beginInsertRows(QModelIndex(), newRow, newRow); // notify: "row N is about to appear"
    m_activities.append(activity);
    endInsertRows();                                // notify: "row N is now there"
    Q_EMIT countChanged();
}

void ActivityListModel::insertActivity(int index, const Activity &activity)
{
    if (index < 0 || index > m_activities.size())
        index = m_activities.size();

    beginInsertRows(QModelIndex(), index, index);
    m_activities.insert(index, activity);
    endInsertRows();
    Q_EMIT countChanged();
}

// ─────────────────────────────────────────────────────────────────────────────
// removeActivity
// ─────────────────────────────────────────────────────────────────────────────
void ActivityListModel::removeActivity(int index)
{
    if (index < 0 || index >= m_activities.size())
        return;

    beginRemoveRows(QModelIndex(), index, index);
    m_activities.removeAt(index);
    endRemoveRows();
    Q_EMIT countChanged();
}

// ─────────────────────────────────────────────────────────────────────────────
// setDone
//
// dataChanged(topLeft, bottomRight, roles) tells the view: "the data at these
// rows changed for these roles — please re-read and repaint."
// ─────────────────────────────────────────────────────────────────────────────
void ActivityListModel::setDone(int index, bool done)
{
    if (index < 0 || index >= m_activities.size())
        return;

    m_activities[index].done = done;
    m_activities[index].status = done ? "Done" : "In Progress";
    if (done && !m_activities[index].actualEndTime.isValid()) {
        m_activities[index].actualEndTime = QDateTime::currentDateTime();
    }

    const QModelIndex changedIndex = createIndex(index, 0);
    Q_EMIT dataChanged(changedIndex, changedIndex, { DoneRole, StatusRole, ActualEndTimeRole, ScheduleStatusRole });
}

void ActivityListModel::setStatus(int index, const QString &status)
{
    if (index < 0 || index >= m_activities.size())
        return;

    m_activities[index].status = status;
    m_activities[index].done = (status == "Done");
    if (status == "In Progress" && !m_activities[index].actualStartTime.isValid()) {
        m_activities[index].actualStartTime = QDateTime::currentDateTime();
    }
    if (status == "Done" && !m_activities[index].actualEndTime.isValid()) {
        m_activities[index].actualEndTime = QDateTime::currentDateTime();
    }

    const QModelIndex changedIndex = createIndex(index, 0);
    Q_EMIT dataChanged(changedIndex, changedIndex, { DoneRole, StatusRole, ActualStartTimeRole, ActualEndTimeRole, ScheduleStatusRole });
}

void ActivityListModel::setDuration(int index, int minutes)
{
    if (index < 0 || index >= m_activities.size() || minutes <= 0)
        return;

    m_activities[index].durationMinutes = minutes;

    const QModelIndex changedIndex = createIndex(index, 0);
    Q_EMIT dataChanged(changedIndex, changedIndex, { DurationRole });
}

void ActivityListModel::setPriority(int index, const QString &priority)
{
    if (index < 0 || index >= m_activities.size() || priority.isEmpty())
        return;

    m_activities[index].priority = priority;

    const QModelIndex changedIndex = createIndex(index, 0);
    Q_EMIT dataChanged(changedIndex, changedIndex, { PriorityRole });
}

void ActivityListModel::incrementExtension(int index, int additionalMinutes)
{
    if (index < 0 || index >= m_activities.size() || additionalMinutes <= 0)
        return;

    m_activities[index].durationMinutes += additionalMinutes;
    m_activities[index].extensionCount += 1;

    const QModelIndex changedIndex = createIndex(index, 0);
    Q_EMIT dataChanged(changedIndex, changedIndex, { DurationRole, ExtensionCountRole });
}

void ActivityListModel::setSchedule(int index, const QDateTime &start, const QDateTime &end, bool reminder)
{
    if (index < 0 || index >= m_activities.size())
        return;

    m_activities[index].scheduledStartTime = start;
    m_activities[index].scheduledEndTime = end;
    m_activities[index].reminderEnabled = reminder;
    m_activities[index].startNotified = false;
    m_activities[index].endNotified = false;
    m_activities[index].snoozedUntil = QDateTime();

    const QModelIndex changedIndex = createIndex(index, 0);
    Q_EMIT dataChanged(changedIndex, changedIndex, {
        ScheduledStartTimeRole, ScheduledEndTimeRole, ScheduledDurationRole,
        ReminderEnabledRole, ScheduleStatusRole, IsOverdueRole, SnoozedUntilRole
    });
}

void ActivityListModel::setReminderEnabled(int index, bool enabled)
{
    if (index < 0 || index >= m_activities.size())
        return;

    m_activities[index].reminderEnabled = enabled;
    const QModelIndex changedIndex = createIndex(index, 0);
    Q_EMIT dataChanged(changedIndex, changedIndex, { ReminderEnabledRole });
}

void ActivityListModel::setStartNotified(int index, bool notified)
{
    if (index < 0 || index >= m_activities.size())
        return;
    m_activities[index].startNotified = notified;
}

void ActivityListModel::setEndNotified(int index, bool notified)
{
    if (index < 0 || index >= m_activities.size())
        return;
    m_activities[index].endNotified = notified;
}

void ActivityListModel::setSnoozedUntil(int index, const QDateTime &until)
{
    if (index < 0 || index >= m_activities.size())
        return;
    m_activities[index].snoozedUntil = until;
    const QModelIndex changedIndex = createIndex(index, 0);
    Q_EMIT dataChanged(changedIndex, changedIndex, { SnoozedUntilRole });
}

void ActivityListModel::updateActivity(int index,
                                      const QString &name,
                                      const QString &category,
                                      int durationMinutes,
                                      const QString &status,
                                      const QString &priority,
                                      const QDateTime &schedStart,
                                      const QDateTime &schedEnd,
                                      bool reminderEnabled)
{
    if (index < 0 || index >= m_activities.size())
        return;

    Activity &a = m_activities[index];
    a.name = name;
    a.category = category;
    a.durationMinutes = durationMinutes; // Actual tracked duration
    a.status = status;
    a.done = (status == "Done");
    a.priority = priority;
    if (schedStart.isValid() || !schedStart.isNull()) a.scheduledStartTime = schedStart;
    if (schedEnd.isValid() || !schedEnd.isNull()) a.scheduledEndTime = schedEnd;
    a.reminderEnabled = reminderEnabled;

    if (status == "In Progress" && !a.actualStartTime.isValid()) {
        a.actualStartTime = QDateTime::currentDateTime();
    }
    if (a.done && !a.actualEndTime.isValid()) {
        a.actualEndTime = QDateTime::currentDateTime();
    }

    const QModelIndex changedIndex = createIndex(index, 0);
    Q_EMIT dataChanged(changedIndex, changedIndex, {
        NameRole, CategoryRole, DurationRole, StatusRole, DoneRole, PriorityRole,
        ScheduledStartTimeRole, ScheduledEndTimeRole, ActualStartTimeRole, ActualEndTimeRole,
        ScheduledDurationRole, ReminderEnabledRole, ScheduleStatusRole, IsOverdueRole, SnoozedUntilRole
    });
}

// ─────────────────────────────────────────────────────────────────────────────
// resetWith — bulk-replace all activities (called on app startup from JsonStore)
// ─────────────────────────────────────────────────────────────────────────────
void ActivityListModel::resetWith(const QVector<Activity> &activities)
{
    beginResetModel();
    m_activities = activities;
    endResetModel();
    Q_EMIT countChanged();
}


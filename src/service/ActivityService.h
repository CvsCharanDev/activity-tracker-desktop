#pragma once

#include <QObject>
#include <QTimer>
#include "model/ActivityListModel.h"

class QSystemTrayIcon;

// ─────────────────────────────────────────────────────────────────────────────
// ActivityService — owns the model, handles mutations, triggers persistence.
//
// This is the layer between QML (UI) and the model+storage.
// Equivalent to a React Context + reducer, or a MobX store.
//
// Lifetime: created in main.cpp, set as a QML context property, lives for
//           the duration of the app.
// ─────────────────────────────────────────────────────────────────────────────
class ActivityService : public QObject
{
    Q_OBJECT

    // ── Properties exposed to QML ─────────────────────────────────────────────
    Q_PROPERTY(int totalDurationToday READ totalDurationToday NOTIFY totalDurationTodayChanged)
    Q_PROPERTY(int totalDurationAllTime READ totalDurationAllTime NOTIFY totalDurationTodayChanged)
    Q_PROPERTY(int completedCount READ completedCount NOTIFY statsChanged)
    Q_PROPERTY(int pendingCount READ pendingCount NOTIFY statsChanged)
    Q_PROPERTY(int completionPercentage READ completionPercentage NOTIFY statsChanged)
    Q_PROPERTY(bool canUndo READ canUndo NOTIFY canUndoChanged)
    Q_PROPERTY(QString lastDeletedName READ lastDeletedName NOTIFY lastDeletedNameChanged)
    Q_PROPERTY(QString syncStatus READ syncStatus NOTIFY syncStatusChanged)

    // The model itself — QML binds: model: activityService.model
    Q_PROPERTY(ActivityListModel* model READ model CONSTANT)

public:
    explicit ActivityService(QObject *parent = nullptr);

    // ── Property getters ──────────────────────────────────────────────────────
    int totalDurationToday() const;
    int totalDurationAllTime() const;
    int completedCount() const;
    int pendingCount() const;
    int completionPercentage() const;
    bool canUndo() const { return m_canUndo; }
    QString lastDeletedName() const { return m_lastDeletedActivity.name; }
    QString syncStatus() const { return m_syncStatus; }
    ActivityListModel *model() const { return m_model; }

    // ── Q_INVOKABLE methods — callable from QML ───────────────────────────────
    Q_INVOKABLE void addActivity(const QString &name,
                                 const QString &category,
                                 int durationMinutes,
                                 const QString &priority = "Medium");

    Q_INVOKABLE void addActivityWithSchedule(const QString &name,
                                             const QString &category,
                                             int durationMinutes,
                                             const QString &priority,
                                             const QString &startTimeIso,
                                             const QString &endTimeIso,
                                             bool reminderEnabled = true);

    Q_INVOKABLE void removeActivity(int index);
    Q_INVOKABLE void undoLastDelete();
    Q_INVOKABLE void markComplete(int index);
    Q_INVOKABLE void setActivityStatus(int index, const QString &status);
    Q_INVOKABLE void setActivityPriority(int index, const QString &priority);
    Q_INVOKABLE void updateActivity(int index,
                                    const QString &name,
                                    const QString &category,
                                    int durationMinutes,
                                    const QString &status,
                                    const QString &priority);
    Q_INVOKABLE void updateActivitySchedule(int index,
                                            const QString &name,
                                            const QString &category,
                                            int durationMinutes,
                                            const QString &status,
                                            const QString &priority,
                                            const QString &startTimeIso,
                                            const QString &endTimeIso,
                                            bool reminderEnabled = true);
    Q_INVOKABLE void reopenActivity(int index);
    Q_INVOKABLE void extendActivity(int index, int additionalMinutes);
    Q_INVOKABLE void createExtension(int index, int minutes = 15);
    Q_INVOKABLE void snoozeActivity(int index, int minutes = 15);
    Q_INVOKABLE void setReminderEnabled(int index, bool enabled);
    Q_INVOKABLE void playAlertSound();
    Q_INVOKABLE void checkReminders();
    Q_INVOKABLE void triggerSync();
    Q_INVOKABLE void refresh();

signals:
    void totalDurationTodayChanged();
    void completedCountChanged();
    void statsChanged();
    void canUndoChanged();
    void lastDeletedNameChanged();
    void syncStatusChanged();
    void activityRemoved(const QString &name);
    void activityReminderTriggered(int index, const QString &activityId, const QString &name, const QString &type, const QString &message);
    void dataRefreshed();

    // Emitted when something goes wrong — QML can connect to show a toast/dialog
    void errorOccurred(const QString &message);

private:
    void save();  // serializes current model to JsonStore
    void showDesktopNotification(const QString &title, const QString &message);

    ActivityListModel *m_model = nullptr;  // owned: destroyed when 'this' is destroyed
    Activity m_lastDeletedActivity;
    int m_lastDeletedIndex = -1;
    bool m_canUndo = false;
    QString m_syncStatus = "synced"; // "syncing", "synced", "offline"
    QTimer m_reminderTimer;
    QSystemTrayIcon *m_trayIcon = nullptr;
};

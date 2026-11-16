#pragma once

#include <QAbstractListModel>
#include <QVector>
#include <QHash>
#include <QByteArray>
#include <QVariant>
#include <QModelIndex>
#include "Activity.h"

// ─────────────────────────────────────────────────────────────────────────────
// ActivityListModel — exposes a list of Activity structs to QML
//
// Inheritance:  ActivityListModel  →  QAbstractListModel  →  QObject
//
// Q_OBJECT macro is mandatory for any class that uses signals/slots or
// Q_PROPERTY. It tells the Meta-Object Compiler (moc) to generate the
// underlying C++ plumbing that makes those features work.
//
// JS analogy: think of this as a MobX observable array — mutations
// automatically notify all listeners (QML views) without manual wiring.
// ─────────────────────────────────────────────────────────────────────────────
class ActivityListModel : public QAbstractListModel
{
    Q_OBJECT

    // Q_PROPERTY exposes a C++ value to QML as a bindable property.
    // Syntax: Q_PROPERTY(Type name READ getter NOTIFY signal)
    // JS analogy: Object.defineProperty with a getter + change event.
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    // ── Role enum ─────────────────────────────────────────────────────────────
    // Roles are integer IDs that QML uses to ask for a specific field.
    // Qt reserves roles 0–255 for itself; start custom roles at Qt::UserRole.
    enum ActivityRole {
        IdRole           = Qt::UserRole + 1,
        NameRole,
        CategoryRole,
        DurationRole,
        DoneRole,
        StatusRole,
        PriorityRole,
        ExtensionCountRole,
        CreatedAtRole,
        ScheduledStartTimeRole,
        ScheduledEndTimeRole,
        ActualStartTimeRole,
        ActualEndTimeRole,
        ScheduledDurationRole,
        ReminderEnabledRole,
        ScheduleStatusRole,
        IsOverdueRole,
        SnoozedUntilRole
    };
    Q_ENUM(ActivityRole)  // makes the enum accessible from QML

    // ── Constructor ───────────────────────────────────────────────────────────
    // 'explicit' prevents implicit conversions:  model = nullptr  won't compile.
    // 'parent' is the QObject ownership parent — if parent is destroyed, so is
    // this object. Pass nullptr to manage lifetime yourself.
    explicit ActivityListModel(QObject *parent = nullptr);

    // ── QAbstractListModel interface (must override these three) ──────────────
    int      rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    // ── Convenience accessor ──────────────────────────────────────────────────
    int count() const { return m_activities.size(); }
    Q_INVOKABLE QVariantMap get(int index) const;

    // ── Mutation helpers (called by ActivityService) ──────────────────────────
    void addActivity(const Activity &activity);
    void insertActivity(int index, const Activity &activity);
    void removeActivity(int index);
    void setDone(int index, bool done);
    void setStatus(int index, const QString &status);
    void setDuration(int index, int minutes);
    void setPriority(int index, const QString &priority);
    void incrementExtension(int index, int additionalMinutes);
    void setSchedule(int index, const QDateTime &start, const QDateTime &end, bool reminder);
    void setReminderEnabled(int index, bool enabled);
    void setStartNotified(int index, bool notified);
    void setEndNotified(int index, bool notified);
    void setSnoozedUntil(int index, const QDateTime &until);
    void updateActivity(int index,
                        const QString &name,
                        const QString &category,
                        int durationMinutes,
                        const QString &status,
                        const QString &priority,
                        const QDateTime &schedStart = QDateTime(),
                        const QDateTime &schedEnd = QDateTime(),
                        bool reminderEnabled = false);

    // ── Bulk load (used by persistence on startup) ────────────────────────────
    void resetWith(const QVector<Activity> &activities);

    // ── Read access for persistence ───────────────────────────────────────────
    const QVector<Activity> &activities() const { return m_activities; }

signals:
    // Emitted whenever count changes so QML bindings on 'count' refresh.
    void countChanged();

private:
    // m_ prefix convention (matches existing repo style): private member fields
    QVector<Activity> m_activities;  // QVector ≈ JS Array but typed, contiguous memory
};


#pragma once

// Qt headers - each gives us specific types
#include <QString>
#include <QDateTime>

// ─────────────────────────────────────────────────────────────────────────────
// Activity — plain data struct (no QObject, no signals, no heap allocation)
//
// JS equivalent:
//   interface Activity {
//     id: string;
//     name: string;
//     category: string;
//     durationMinutes: number;
//     done: boolean;
//     createdAt: Date;
//   }
// ─────────────────────────────────────────────────────────────────────────────
struct Activity
{
    QString   id;                             // Unique identifier (e.g. QUuid string)
    QString   name;                           // Display name e.g. "Write unit tests"
    QString   category;                       // "Work" | "Learning" | "Personal"
    int       durationMinutes = 0;            // Planned duration in minutes
    bool      done            = false;        // Completion flag
    QString   status          = "Created";    // "Created" | "In Progress" | "Done"
    QString   priority        = "Medium";     // "Urgent" | "High" | "Medium" | "Low"
    int       extensionCount  = 0;            // Number of in-place extension sessions logged
    QDateTime createdAt;                      // Creation timestamp

    // ── Scheduling & Telemetry (Phase 1) ──────────────────────────────────────
    QDateTime scheduledStartTime;             // Planned start timestamp (ISO with offset)
    QDateTime scheduledEndTime;               // Planned end / due timestamp
    QDateTime actualStartTime;                // Timestamp when status moved to "In Progress"
    QDateTime actualEndTime;                  // Timestamp when status moved to "Done"

    // ── Notification & Alert State (Persisted) ────────────────────────────────
    bool      reminderEnabled = false;        // Default false for existing/unscheduled tasks
    bool      startNotified   = false;        // Persisted to prevent duplicate alerts on restart
    bool      endNotified     = false;        // Persisted to prevent duplicate alerts on restart
    QDateTime snoozedUntil;                   // Persisted snooze deadline

    // ── Derived helpers ───────────────────────────────────────────────────────
    bool hasSchedule() const {
        return scheduledStartTime.isValid() || scheduledEndTime.isValid();
    }

    int scheduledDurationMinutes() const {
        if (scheduledStartTime.isValid() && scheduledEndTime.isValid() && scheduledEndTime > scheduledStartTime) {
            return static_cast<int>(scheduledStartTime.secsTo(scheduledEndTime) / 60);
        }
        return durationMinutes;
    }

    bool isOverdue() const {
        if (done) return false;
        if (!scheduledEndTime.isValid()) return false;
        return QDateTime::currentDateTime() > scheduledEndTime;
    }

    QString scheduleStatus() const {
        if (done) return QStringLiteral("Completed");
        const QDateTime now = QDateTime::currentDateTime();
        if (scheduledEndTime.isValid() && now > scheduledEndTime) {
            return QStringLiteral("Overdue");
        }
        if (scheduledStartTime.isValid()) {
            if (now < scheduledStartTime) return QStringLiteral("Upcoming");
            if (!scheduledEndTime.isValid() || now <= scheduledEndTime) return QStringLiteral("Active");
        }
        return (status == QLatin1String("In Progress")) ? QStringLiteral("Active") : QStringLiteral("Created");
    }

    // ── Convenience factory ───────────────────────────────────────────────────
    // 'static' means it belongs to the struct type, not to an instance.
    // Like a static method in a JS class: Activity.create(...)
    static Activity create(const QString &name,
                           const QString &category,
                           int durationMinutes,
                           const QString &priority = QStringLiteral("Medium"),
                           const QDateTime &schedStart = QDateTime(),
                           const QDateTime &schedEnd = QDateTime(),
                           bool reminderEnabled = false);
};


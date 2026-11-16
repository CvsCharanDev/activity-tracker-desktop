#include "JsonStore.h"

#include <QFile>
#include <QDir>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QStandardPaths>
#include <QDebug>

// ─────────────────────────────────────────────────────────────────────────────
// filePath — resolves %APPDATA%\ActivityTracker\activities.json on Windows
//
// QStandardPaths::writableLocation(AppDataLocation) is like
// process.env.APPDATA in Node.js — gives the OS-appropriate user data folder.
// ─────────────────────────────────────────────────────────────────────────────
QString JsonStore::filePath()
{
    // QCoreApplication::applicationName() must be set in main.cpp for this to
    // produce a nice subdirectory name like "ActivityTracker".
    const QString dir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dir);                          // create directory if it doesn't exist
    return dir + "/activities.json";
}

// ─────────────────────────────────────────────────────────────────────────────
// save
// ─────────────────────────────────────────────────────────────────────────────
bool JsonStore::save(const QVector<Activity> &activities)
{
    QJsonArray array;
    for (const Activity &a : activities) {         // range-based for (like JS for...of)
        QJsonObject obj;
        obj["id"]              = a.id;
        obj["name"]            = a.name;
        obj["category"]        = a.category;
        obj["durationMinutes"] = a.durationMinutes;
        obj["done"]            = a.done;
        obj["status"]          = a.status.isEmpty() ? (a.done ? "Done" : "Created") : a.status;
        obj["priority"]        = a.priority.isEmpty() ? "Medium" : a.priority;
        obj["extensionCount"]  = a.extensionCount;
        obj["createdAt"]       = a.createdAt.toString(Qt::ISODate);  // ISO 8601 string
        if (a.scheduledStartTime.isValid())
            obj["scheduledStartTime"] = a.scheduledStartTime.toString(Qt::ISODate);
        if (a.scheduledEndTime.isValid())
            obj["scheduledEndTime"]   = a.scheduledEndTime.toString(Qt::ISODate);
        if (a.actualStartTime.isValid())
            obj["actualStartTime"]    = a.actualStartTime.toString(Qt::ISODate);
        if (a.actualEndTime.isValid())
            obj["actualEndTime"]      = a.actualEndTime.toString(Qt::ISODate);
        if (a.snoozedUntil.isValid())
            obj["snoozedUntil"]       = a.snoozedUntil.toString(Qt::ISODate);
        obj["reminderEnabled"]        = a.reminderEnabled;
        obj["startNotified"]          = a.startNotified;
        obj["endNotified"]            = a.endNotified;
        array.append(obj);
    }

    QJsonDocument doc(array);
    QFile file(filePath());

    // QIODevice::WriteOnly | QIODevice::Truncate  — open for writing, clear old content
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        qWarning() << "JsonStore: cannot open file for writing:" << file.errorString();
        return false;
    }

    file.write(doc.toJson(QJsonDocument::Indented)); // pretty-printed JSON
    return true;
}

// ─────────────────────────────────────────────────────────────────────────────
// load
// ─────────────────────────────────────────────────────────────────────────────
QVector<Activity> JsonStore::load()
{
    QFile file(filePath());
    if (!file.exists()) {
        qInfo() << "JsonStore: no saved data at" << filePath();
        return {};                                 // empty vector — first run
    }

    if (!file.open(QIODevice::ReadOnly)) {
        qWarning() << "JsonStore: cannot open file for reading:" << file.errorString();
        return {};
    }

    const QByteArray raw = file.readAll();
    QJsonParseError parseError;
    const QJsonDocument doc = QJsonDocument::fromJson(raw, &parseError);

    if (parseError.error != QJsonParseError::NoError) {
        qWarning() << "JsonStore: JSON parse error:" << parseError.errorString();
        return {};                                 // corrupt file — start fresh
    }

    if (!doc.isArray()) {
        qWarning() << "JsonStore: expected a JSON array at root";
        return {};
    }

    QVector<Activity> result;
    for (const QJsonValue &val : doc.array()) {
        if (!val.isObject()) continue;
        const QJsonObject obj = val.toObject();

        Activity a;
        a.id              = obj["id"].toString();
        a.name            = obj["name"].toString();
        a.category        = obj["category"].toString();
        a.durationMinutes = obj["durationMinutes"].toInt();
        a.done            = obj["done"].toBool();
        a.status          = obj.contains("status") ? obj["status"].toString() : (a.done ? "Done" : "Created");
        a.priority        = obj.contains("priority") ? obj["priority"].toString() : "Medium";
        a.extensionCount  = obj.contains("extensionCount") ? obj["extensionCount"].toInt() : 0;
        a.createdAt       = QDateTime::fromString(obj["createdAt"].toString(), Qt::ISODate);

        if (obj.contains("scheduledStartTime") && !obj["scheduledStartTime"].toString().isEmpty()) {
            a.scheduledStartTime = QDateTime::fromString(obj["scheduledStartTime"].toString(), Qt::ISODate);
        } else if (obj.contains("startTime") && !obj["startTime"].toString().isEmpty()) {
            a.scheduledStartTime = QDateTime::fromString(obj["startTime"].toString(), Qt::ISODate);
        }

        if (obj.contains("scheduledEndTime") && !obj["scheduledEndTime"].toString().isEmpty()) {
            a.scheduledEndTime   = QDateTime::fromString(obj["scheduledEndTime"].toString(), Qt::ISODate);
        } else if (obj.contains("endTime") && !obj["endTime"].toString().isEmpty()) {
            a.scheduledEndTime   = QDateTime::fromString(obj["endTime"].toString(), Qt::ISODate);
        }

        if (obj.contains("actualStartTime") && !obj["actualStartTime"].toString().isEmpty()) {
            a.actualStartTime    = QDateTime::fromString(obj["actualStartTime"].toString(), Qt::ISODate);
        }
        if (obj.contains("actualEndTime") && !obj["actualEndTime"].toString().isEmpty()) {
            a.actualEndTime      = QDateTime::fromString(obj["actualEndTime"].toString(), Qt::ISODate);
        }
        if (obj.contains("snoozedUntil") && !obj["snoozedUntil"].toString().isEmpty()) {
            a.snoozedUntil       = QDateTime::fromString(obj["snoozedUntil"].toString(), Qt::ISODate);
        }

        a.reminderEnabled = obj.contains("reminderEnabled") ? obj["reminderEnabled"].toBool() : false;
        a.startNotified   = obj.contains("startNotified") ? obj["startNotified"].toBool() : false;
        a.endNotified     = obj.contains("endNotified") ? obj["endNotified"].toBool() : false;

        if (a.id.isEmpty() || a.name.isEmpty())
            continue;            // skip malformed entries

        result.append(a);
    }

    qInfo() << "JsonStore: loaded" << result.size() << "activities";
    return result;
}


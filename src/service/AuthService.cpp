#include "AuthService.h"

#include <QCryptographicHash>
#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QSysInfo>
#include <QDebug>

static const QString SALT_PREFIX = "cvs_salt_";

AuthService::AuthService(QObject *parent)
    : QObject(parent)
{
    loadLocalData();
    restoreSavedSession();
}

QString AuthService::hashPassword(const QString &password)
{
    const QByteArray data = (SALT_PREFIX + password).toUtf8();
    return QString(QCryptographicHash::hash(data, QCryptographicHash::Sha256).toHex());
}

QString AuthService::sessionDeviceName() const
{
#if defined(Q_OS_WIN)
    return QString("%1 (Windows %2)").arg(QSysInfo::machineHostName(), QSysInfo::currentCpuArchitecture());
#elif defined(Q_OS_MACOS)
    return QString("%1 (macOS %2)").arg(QSysInfo::machineHostName(), QSysInfo::currentCpuArchitecture());
#else
    return QString("%1 (%2)").arg(QSysInfo::machineHostName(), QSysInfo::prettyProductName());
#endif
}

void AuthService::clearError()
{
    if (!m_errorMessage.isEmpty()) {
        m_errorMessage.clear();
        Q_EMIT errorChanged();
    }
}

void AuthService::setHasSeenTour(bool seen)
{
    if (m_preferences.hasSeenTour != seen) {
        m_preferences.hasSeenTour = seen;
        saveLocalData();
        Q_EMIT preferencesChanged();
    }
}

int AuthService::activeSessionsCount() const
{
    int count = 0;
    for (const UserSession &s : m_sessions) {
        if (s.userId == m_currentUser.id && s.isValid()) {
            count++;
        }
    }
    return count;
}

UserSession AuthService::createSessionForUser(const QString &userId)
{
    m_bearerToken = UserSession::generateToken();
    const QString platform = 
#if defined(Q_OS_WIN)
        "windows";
#elif defined(Q_OS_MACOS)
        "macos";
#else
        "linux";
#endif

    const QString thisDevice = sessionDeviceName();

    // Revoke any previous active session from the same physical machine for this user
    for (UserSession &s : m_sessions) {
        if (s.userId == userId && s.deviceName == thisDevice && s.isValid()) {
            s.isRevoked = true;
        }
    }

    const UserSession session = UserSession::create(
        userId,
        m_bearerToken,
        thisDevice,
        platform,
        30 // 30-day valid session
    );
    m_sessions.append(session);
    m_currentSession = session;
    return session;
}

bool AuthService::login(const QString &email, const QString &password, bool rememberMe)
{
    clearError();
    const QString cleanEmail = email.trimmed().toLower();

    if (cleanEmail.isEmpty() || password.isEmpty()) {
        m_errorMessage = "Please enter both email and password.";
        Q_EMIT errorChanged();
        return false;
    }

    const QString computedHash = hashPassword(password);

    for (const User &u : m_users) {
        if (u.email.toLower() == cleanEmail) {
            if (u.passwordHash == computedHash) {
                m_currentUser = u;
                m_isLoggedIn = true;

                // Create cryptographic session
                createSessionForUser(u.id);

                // Load or initialize user preferences
                bool foundPrefs = false;
                for (const UserPreferences &p : m_userPreferencesList) {
                    if (p.userId == u.id) {
                        m_preferences = p;
                        foundPrefs = true;
                        break;
                    }
                }
                if (!foundPrefs) {
                    m_preferences = UserPreferences{};
                    m_preferences.userId = u.id;
                    m_userPreferencesList.append(m_preferences);
                }

                QSettings settings;
                settings.setValue("auth/rememberMe", rememberMe);
                if (rememberMe) {
                    settings.setValue("auth/bearerToken", m_bearerToken);
                    settings.setValue("auth/savedUserId", u.id);
                } else {
                    settings.remove("auth/bearerToken");
                    settings.remove("auth/savedUserId");
                }

                saveLocalData();
                Q_EMIT authStateChanged();
                Q_EMIT sessionChanged();
                Q_EMIT sessionsChanged();
                Q_EMIT preferencesChanged();
                Q_EMIT loginSuccess();
                return true;
            } else {
                m_errorMessage = "Incorrect password. Please try again.";
                Q_EMIT errorChanged();
                return false;
            }
        }
    }

    m_errorMessage = "No account found with this email.";
    Q_EMIT errorChanged();
    return false;
}

bool AuthService::registerUser(const QString &name, const QString &email, const QString &password, int dailyGoalMinutes)
{
    clearError();
    const QString cleanName = name.trimmed();
    const QString cleanEmail = email.trimmed().toLower();

    if (cleanName.isEmpty()) {
        m_errorMessage = "Please enter your full name.";
        Q_EMIT errorChanged();
        return false;
    }
    if (cleanEmail.isEmpty() || !cleanEmail.contains('@') || !cleanEmail.contains('.')) {
        m_errorMessage = "Please enter a valid email address.";
        Q_EMIT errorChanged();
        return false;
    }
    if (password.length() < 6) {
        m_errorMessage = "Password must be at least 6 characters long.";
        Q_EMIT errorChanged();
        return false;
    }

    for (const User &u : m_users) {
        if (u.email.toLower() == cleanEmail) {
            m_errorMessage = "An account with this email already exists.";
            Q_EMIT errorChanged();
            return false;
        }
    }

    const User newUser = User::create(cleanName, cleanEmail, hashPassword(password), dailyGoalMinutes);
    m_users.append(newUser);

    // Initialize cross-device preferences
    UserPreferences prefs;
    prefs.userId = newUser.id;
    prefs.dailyGoalMinutes = dailyGoalMinutes;
    prefs.hasSeenTour = false; // New registration starts with fresh UI Tour!
    m_userPreferencesList.append(prefs);

    saveLocalData();
    Q_EMIT registrationSuccess();
    return true;
}

bool AuthService::resetPassword(const QString &email, const QString &newPassword)
{
    clearError();
    const QString cleanEmail = email.trimmed().toLower();

    if (cleanEmail.isEmpty()) {
        m_errorMessage = "Please enter your email address.";
        Q_EMIT errorChanged();
        return false;
    }
    if (newPassword.length() < 6) {
        m_errorMessage = "New password must be at least 6 characters long.";
        Q_EMIT errorChanged();
        return false;
    }

    for (int i = 0; i < m_users.size(); ++i) {
        if (m_users[i].email.toLower() == cleanEmail) {
            m_users[i].passwordHash = hashPassword(newPassword);

            // Invalidate all existing active sessions on password reset for security
            for (UserSession &s : m_sessions) {
                if (s.userId == m_users[i].id) {
                    s.isRevoked = true;
                }
            }

            saveLocalData();
            Q_EMIT resetPasswordSuccess();
            Q_EMIT sessionsChanged();
            return true;
        }
    }

    m_errorMessage = "No account found with this email.";
    Q_EMIT errorChanged();
    return false;
}

void AuthService::loginDemoUser()
{
    clearError();
    for (const User &u : m_users) {
        if (u.email == "charan@cvs.com") {
            m_currentUser = u;
            m_isLoggedIn = true;
            createSessionForUser(u.id);

            for (const UserPreferences &p : m_userPreferencesList) {
                if (p.userId == u.id) {
                    m_preferences = p;
                    break;
                }
            }

            saveLocalData();
            Q_EMIT authStateChanged();
            Q_EMIT sessionChanged();
            Q_EMIT sessionsChanged();
            Q_EMIT preferencesChanged();
            Q_EMIT loginSuccess();
            return;
        }
    }

    // Provision default demo user
    const User demoUser{
        "usr_charan_demo_01",
        "Charan Developer",
        "charan@cvs.com",
        hashPassword("Password123!"),
        240,
        QDateTime::currentDateTime()
    };
    m_users.append(demoUser);

    UserPreferences demoPrefs;
    demoPrefs.userId = demoUser.id;
    demoPrefs.hasSeenTour = false;
    m_userPreferencesList.append(demoPrefs);

    m_currentUser = demoUser;
    m_preferences = demoPrefs;
    m_isLoggedIn = true;
    createSessionForUser(demoUser.id);

    saveLocalData();
    Q_EMIT authStateChanged();
    Q_EMIT sessionChanged();
    Q_EMIT sessionsChanged();
    Q_EMIT preferencesChanged();
    Q_EMIT loginSuccess();
}

void AuthService::logout()
{
    // Revoke current session
    if (!m_currentSession.id.isEmpty()) {
        for (UserSession &s : m_sessions) {
            if (s.id == m_currentSession.id) {
                s.isRevoked = true;
                break;
            }
        }
    }

    QSettings settings;
    settings.remove("auth/bearerToken");
    settings.remove("auth/savedUserId");
    settings.setValue("auth/rememberMe", false);

    m_currentUser = User{};
    m_currentSession = UserSession{};
    m_bearerToken.clear();
    m_isLoggedIn = false;
    clearError();

    saveLocalData();
    Q_EMIT authStateChanged();
    Q_EMIT sessionChanged();
    Q_EMIT sessionsChanged();
}

bool AuthService::validateSession()
{
    QSettings settings;
    const bool rememberMe = settings.value("auth/rememberMe", false).toBool();
    const QString bearerToken = settings.value("auth/bearerToken").toString();

    if (!rememberMe || bearerToken.isEmpty()) {
        return false;
    }

    const QString tokenHash = UserSession::hashToken(bearerToken);

    for (int i = 0; i < m_sessions.size(); ++i) {
        if (m_sessions[i].tokenHash == tokenHash) {
            // Check remote revocation
            if (m_sessions[i].isRevoked) {
                m_errorMessage = "Your session was remotely revoked or logged out from another device.";
                logout();
                Q_EMIT sessionRevoked(m_errorMessage);
                return false;
            }

            // Check expiration
            if (m_sessions[i].expiresAt <= QDateTime::currentDateTime()) {
                m_errorMessage = "Your session has expired. Please sign in again.";
                logout();
                return false;
            }

            // Session is 100% valid -> restore user context
            for (const User &u : m_users) {
                if (u.id == m_sessions[i].userId) {
                    m_currentUser = u;
                    m_currentSession = m_sessions[i];
                    m_currentSession.lastActiveAt = QDateTime::currentDateTime();
                    m_sessions[i].lastActiveAt = m_currentSession.lastActiveAt;
                    m_bearerToken = bearerToken;
                    m_isLoggedIn = true;

                    // Load user preferences
                    for (const UserPreferences &p : m_userPreferencesList) {
                        if (p.userId == u.id) {
                            m_preferences = p;
                            break;
                        }
                    }

                    saveLocalData();
                    Q_EMIT authStateChanged();
                    Q_EMIT sessionChanged();
                    Q_EMIT sessionsChanged();
                    Q_EMIT preferencesChanged();
                    return true;
                }
            }
        }
    }

    return false;
}

void AuthService::revokeSession(const QString &sessionId)
{
    for (int i = 0; i < m_sessions.size(); ++i) {
        if (m_sessions[i].id == sessionId) {
            m_sessions[i].isRevoked = true;

            // If the revoked session is this current machine, trigger logout immediately
            if (m_currentSession.id == sessionId) {
                m_errorMessage = "This device's session was revoked.";
                logout();
                Q_EMIT sessionRevoked(m_errorMessage);
            } else {
                saveLocalData();
                Q_EMIT sessionsChanged();
            }
            return;
        }
    }
}

QVariantList AuthService::activeSessions() const
{
    QVariantList list;
    for (const UserSession &s : m_sessions) {
        if (s.userId == m_currentUser.id && s.isValid()) {
            QVariantMap map;
            map["id"]           = s.id;
            map["deviceName"]   = s.deviceName;
            map["platform"]     = s.platform;
            map["lastActiveAt"] = s.lastActiveAt.toString(Qt::ISODate);
            map["isCurrent"]    = (s.id == m_currentSession.id);
            map["isValid"]      = true;
            list.append(map);
        }
    }
    return list;
}

void AuthService::completeTour()
{
    setHasSeenTour(true);
}

void AuthService::resetTour()
{
    setHasSeenTour(false);
}

void AuthService::updateDailyGoal(int minutes)
{
    if (minutes <= 0) return;
    m_currentUser.dailyGoalMinutes = minutes;
    for (User &u : m_users) {
        if (u.id == m_currentUser.id) {
            u.dailyGoalMinutes = minutes;
            break;
        }
    }
    m_preferences.dailyGoalMinutes = minutes;
    for (UserPreferences &p : m_userPreferencesList) {
        if (p.userId == m_currentUser.id) {
            p.dailyGoalMinutes = minutes;
            break;
        }
    }
    saveLocalData();
    Q_EMIT authStateChanged();
    Q_EMIT preferencesChanged();
}

void AuthService::syncPreferences(const QString &theme,
                                  const QString &sidebarDock,
                                  bool sidebarCollapsed,
                                  const QString &activeTimeframe,
                                  bool hasSeenTour)
{
    m_preferences.userId = m_currentUser.id;
    m_preferences.theme = theme;
    m_preferences.sidebarDock = sidebarDock;
    m_preferences.sidebarCollapsed = sidebarCollapsed;
    m_preferences.activeTimeframe = activeTimeframe;
    m_preferences.hasSeenTour = hasSeenTour;

    for (int i = 0; i < m_userPreferencesList.size(); ++i) {
        if (m_userPreferencesList[i].userId == m_currentUser.id) {
            m_userPreferencesList[i] = m_preferences;
            saveLocalData();
            Q_EMIT preferencesChanged();
            return;
        }
    }
    m_userPreferencesList.append(m_preferences);
    saveLocalData();
    Q_EMIT preferencesChanged();
}

void AuthService::restoreSavedSession()
{
    validateSession();
}

void AuthService::loadLocalData()
{
    const QString dir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);

    // 1. Load Users
    QFile userFile(dir + "/users.json");
    if (userFile.open(QIODevice::ReadOnly)) {
        const QJsonDocument doc = QJsonDocument::fromJson(userFile.readAll());
        if (doc.isArray()) {
            m_users.clear();
            for (const QJsonValue &val : doc.array()) {
                if (val.isObject()) {
                    m_users.append(User::fromJson(val.toObject()));
                }
            }
        }
    }

    // 2. Load Sessions
    QFile sessionFile(dir + "/sessions.json");
    if (sessionFile.open(QIODevice::ReadOnly)) {
        const QJsonDocument doc = QJsonDocument::fromJson(sessionFile.readAll());
        if (doc.isArray()) {
            m_sessions.clear();
            for (const QJsonValue &val : doc.array()) {
                if (val.isObject()) {
                    m_sessions.append(UserSession::fromJson(val.toObject()));
                }
            }
        }
    }

    // 3. Load Preferences
    QFile prefFile(dir + "/preferences.json");
    if (prefFile.open(QIODevice::ReadOnly)) {
        const QJsonDocument doc = QJsonDocument::fromJson(prefFile.readAll());
        if (doc.isArray()) {
            m_userPreferencesList.clear();
            for (const QJsonValue &val : doc.array()) {
                if (val.isObject()) {
                    m_userPreferencesList.append(UserPreferences::fromJson(val.toObject()));
                }
            }
        }
    }
}

void AuthService::saveLocalData()
{
    const QString dir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dir);

    // 1. Save Users
    QJsonArray userArray;
    for (const User &u : m_users) userArray.append(u.toJson());
    QFile userFile(dir + "/users.json");
    if (userFile.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        userFile.write(QJsonDocument(userArray).toJson(QJsonDocument::Indented));
    }

    // 2. Save Sessions (clean up revoked or expired sessions older than 7 days)
    QJsonArray sessionArray;
    const QDateTime cutoff = QDateTime::currentDateTime().addDays(-7);
    for (const UserSession &s : m_sessions) {
        if (s.isValid() || (s.lastActiveAt >= cutoff)) {
            sessionArray.append(s.toJson());
        }
    }
    QFile sessionFile(dir + "/sessions.json");
    if (sessionFile.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        sessionFile.write(QJsonDocument(sessionArray).toJson(QJsonDocument::Indented));
    }

    // 3. Save Preferences
    QJsonArray prefArray;
    for (const UserPreferences &p : m_userPreferencesList) prefArray.append(p.toJson());
    QFile prefFile(dir + "/preferences.json");
    if (prefFile.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        prefFile.write(QJsonDocument(prefArray).toJson(QJsonDocument::Indented));
    }
}

#pragma once

#include <QObject>
#include <QString>
#include <QSettings>
#include <QVector>
#include <QVariantList>
#include "model/User.h"
#include "model/Session.h"

// ─────────────────────────────────────────────────────────────────────────────
// AuthService — Manages cryptographic session tokens, multi-device management,
// remote revocation, and cross-device workstation preferences synchronization.
// ─────────────────────────────────────────────────────────────────────────────
class AuthService : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool isLoggedIn READ isLoggedIn NOTIFY authStateChanged)
    Q_PROPERTY(QString currentUserId READ currentUserId NOTIFY authStateChanged)
    Q_PROPERTY(QString currentUserName READ currentUserName NOTIFY authStateChanged)
    Q_PROPERTY(QString currentUserEmail READ currentUserEmail NOTIFY authStateChanged)
    Q_PROPERTY(int dailyGoalMinutes READ dailyGoalMinutes NOTIFY authStateChanged)
    Q_PROPERTY(bool isBusy READ isBusy NOTIFY busyChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorChanged)
    Q_PROPERTY(bool hasSeenTour READ hasSeenTour WRITE setHasSeenTour NOTIFY preferencesChanged)
    Q_PROPERTY(int activeSessionsCount READ activeSessionsCount NOTIFY sessionsChanged)
    Q_PROPERTY(QVariantList activeSessions READ activeSessions NOTIFY sessionsChanged)
    Q_PROPERTY(QString currentSessionId READ currentSessionId NOTIFY sessionChanged)
    Q_PROPERTY(QString sessionDeviceName READ sessionDeviceName CONSTANT)

public:
    explicit AuthService(QObject *parent = nullptr);

    bool isLoggedIn() const { return m_isLoggedIn; }
    QString currentUserId() const { return m_currentUser.id; }
    QString currentUserName() const { return m_currentUser.name; }
    QString currentUserEmail() const { return m_currentUser.email; }
    int dailyGoalMinutes() const { return m_currentUser.dailyGoalMinutes; }
    bool isBusy() const { return m_isBusy; }
    QString errorMessage() const { return m_errorMessage; }
    bool hasSeenTour() const { return m_preferences.hasSeenTour; }
    void setHasSeenTour(bool seen);
    int activeSessionsCount() const;
    QString currentSessionId() const { return m_currentSession.id; }
    QString sessionDeviceName() const;

    const User &currentUser() const { return m_currentUser; }
    const UserSession &currentSession() const { return m_currentSession; }
    const UserPreferences &preferences() const { return m_preferences; }

    // Authentication Actions
    Q_INVOKABLE bool login(const QString &email, const QString &password, bool rememberMe);
    Q_INVOKABLE bool registerUser(const QString &name, const QString &email, const QString &password, int dailyGoalMinutes);
    Q_INVOKABLE bool resetPassword(const QString &email, const QString &newPassword);
    Q_INVOKABLE void loginDemoUser();
    Q_INVOKABLE void logout();
    Q_INVOKABLE void clearError();

    // Session Management & Remote Revocation
    Q_INVOKABLE bool validateSession();
    Q_INVOKABLE void revokeSession(const QString &sessionId);
    Q_INVOKABLE QVariantList activeSessions() const;

    // Cross-Device Preferences Sync & Guided Tour
    Q_INVOKABLE void completeTour();
    Q_INVOKABLE void resetTour();
    Q_INVOKABLE void updateDailyGoal(int minutes);
    Q_INVOKABLE void syncPreferences(const QString &theme,
                                    const QString &sidebarDock,
                                    bool sidebarCollapsed,
                                    const QString &activeTimeframe,
                                    bool hasSeenTour);

    static QString hashPassword(const QString &password);

signals:
    void authStateChanged();
    void busyChanged();
    void errorChanged();
    void loginSuccess();
    void registrationSuccess();
    void resetPasswordSuccess();
    void preferencesChanged();
    void sessionsChanged();
    void sessionChanged();
    void sessionRevoked(const QString &reason);

private:
    void loadLocalData();
    void saveLocalData();
    void restoreSavedSession();
    UserSession createSessionForUser(const QString &userId);

    bool m_isLoggedIn = false;
    bool m_isBusy = false;
    QString m_errorMessage;
    User m_currentUser;
    UserSession m_currentSession;
    UserPreferences m_preferences;
    QString m_bearerToken; // Kept in memory while app runs

    QVector<User> m_users;
    QVector<UserSession> m_sessions;
    QVector<UserPreferences> m_userPreferencesList;
};

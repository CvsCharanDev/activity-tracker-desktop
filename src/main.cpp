#include <QApplication>
#include <QCoreApplication>
#include <QFont>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QIcon>
#include <QDebug>
#include <QUrl>

#include "service/ActivityService.h"
#include "service/AuthService.h"

int main(int argc, char *argv[])
{
    // ── Application metadata ──────────────────────────────────────────────────
    QGuiApplication::setOrganizationName("CVS");
    QGuiApplication::setApplicationName("CVS Activity Tracker");
    QGuiApplication::setApplicationDisplayName("CVS Activity Tracker");
    QGuiApplication::setApplicationVersion("1.0.0");

    // ── Create the application ────────────────────────────────────────────────
    QApplication app(argc, argv);
    app.setQuitOnLastWindowClosed(true);
    app.setWindowIcon(QIcon(":/qt/qml/ActivityTracker/resources/icons/app_icon.svg"));

    // ── High-legibility modern sans-serif typography (MERN / desktop aesthetic) ──
    QFont appFont("Segoe UI Variable Text", 10);
    appFont.setStyleHint(QFont::SansSerif);
    app.setFont(appFont);

    // ── Set Material style for Qt Quick Controls 2 ───────────────────────────
    // Must be called BEFORE QQmlApplicationEngine is created.
    QQuickStyle::setStyle("Material");

    // ── Business logic / services ─────────────────────────────────────────────
    // Stack-allocated: destroyed automatically when main() returns (RAII).
    AuthService authService;
    ActivityService service;

    // ── QML engine ────────────────────────────────────────────────────────────
    QQmlApplicationEngine engine;

    // Expose C++ objects to QML as named globals.
    engine.rootContext()->setContextProperty("authService", &authService);
    engine.rootContext()->setContextProperty("activityService", &service);
    engine.rootContext()->setContextProperty("activityModel", service.model());

    // ── Load the root QML file ────────────────────────────────────────────────
    // In Qt 6 with QTP0001 (default resource prefix :/qt/qml/),
    // the module files are located at "qrc:/qt/qml/ActivityTracker/..."
    const QUrl mainQml("qrc:/qt/qml/ActivityTracker/qml/main.qml");

    // If the root object fails to load, quit immediately with a non-zero exit code.
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        [](const QUrl &url) {
            qCritical() << "Failed to load QML:" << url;
            QCoreApplication::exit(1);
        },
        Qt::QueuedConnection
    );

    engine.load(mainQml);

    // ── Event loop ────────────────────────────────────────────────────────────
    // app.exec() blocks here, processing events until the last window closes.
    // Returns the exit code (0 = success).
    return app.exec();
}


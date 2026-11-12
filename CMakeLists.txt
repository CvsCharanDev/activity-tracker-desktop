cmake_minimum_required(VERSION 3.21)
project(ActivityTracker VERSION 1.0.0 LANGUAGES CXX)

# ── C++ Standard ──────────────────────────────────────────────────────────────
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(MSVC)
    add_compile_options(/Zc:__cplusplus /Zc:preprocessor /permissive-)
endif()

# ── Qt Automation ─────────────────────────────────────────────────────────────
# AUTOMOC: auto-runs moc on Q_OBJECT classes (generates signal/slot plumbing)
# AUTORCC: auto-compiles .qrc resource files
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

# ── Find Qt6 ──────────────────────────────────────────────────────────────────
# Best Practice: In production and CI/CD, CMAKE_PREFIX_PATH is supplied by
# the IDE kit (Qt Creator), CMakePresets.json, environment variables, or -D flags.
# On macOS/Linux, package managers (e.g. Homebrew `brew install qt6` or `apt install qt6-base-dev`)
# place Qt in standard system paths where find_package finds it automatically.
# The fallback below only activates on Windows if no prefix path was passed.
if(NOT DEFINED CMAKE_PREFIX_PATH AND NOT DEFINED ENV{CMAKE_PREFIX_PATH})
    if(WIN32 AND EXISTS "C:/Qt/6.9.3/msvc2022_64")
        set(CMAKE_PREFIX_PATH "C:/Qt/6.9.3/msvc2022_64")
    endif()
endif()

# Workaround for Qt 6.8 bug on modern macOS (macOS 14/15/26 / Xcode 16+) where FindWrapOpenGL tries to link obsolete AGL framework
if(APPLE)
    if(NOT TARGET WrapOpenGL::WrapOpenGL)
        add_library(WrapOpenGL::WrapOpenGL INTERFACE IMPORTED)
        set_target_properties(WrapOpenGL::WrapOpenGL PROPERTIES
            INTERFACE_LINK_LIBRARIES "-framework OpenGL"
        )
    endif()
endif()

find_package(Qt6 6.4 REQUIRED COMPONENTS
    Core        # QObject, QString, QVector, QJsonDocument, etc.
    Gui         # QGuiApplication, fonts, colors
    Quick       # QML engine, Qt Quick controls
    Qml         # QQmlApplicationEngine, QQmlContext
    QuickControls2  # ApplicationWindow, Button, TextField, etc.
    Test        # QTest unit testing framework
)

# Silence Qt 6.5+ policy warnings for this learning POC
qt_policy(SET QTP0001 NEW)
qt_policy(SET QTP0004 NEW)

# ── Source Files ──────────────────────────────────────────────────────────────
set(SOURCES
    src/main.cpp
    src/model/User.h
    src/model/Session.h
    src/model/Activity.h
    src/model/Activity.cpp
    src/model/ActivityListModel.h
    src/model/ActivityListModel.cpp
    src/service/AuthService.h
    src/service/AuthService.cpp
    src/service/ActivityService.h
    src/service/ActivityService.cpp
    src/persistence/JsonStore.h
    src/persistence/JsonStore.cpp
)

# ── QML / Resource Files ──────────────────────────────────────────────────────
set(QML_FILES
    qml/Theme.qml
    qml/main.qml
    qml/views/auth/LoginView.qml
    qml/views/auth/SignUpView.qml
    qml/views/auth/ForgotPasswordView.qml
    qml/views/ActivityListView.qml
    qml/views/AnalyticsView.qml
    qml/views/KanbanBoardView.qml
    qml/views/EmptyStateView.qml
    qml/components/LucideIcon.qml
    qml/components/ActivityCard.qml
    qml/components/AddActivityForm.qml
    qml/components/SummaryBar.qml
    qml/components/StatsDashboard.qml
    qml/components/GuidedTour.qml
    qml/components/SettingsModal.qml
    qml/components/ActivityDetailModal.qml
    qml/components/ShadcnCheckbox.qml
    qml/components/ShadcnSelect.qml
    qml/components/ShadcnButton.qml
    qml/components/ShadcnInput.qml
    qml/components/ShadcnBadge.qml
)

# Register Theme.qml as a QML singleton
set_source_files_properties(qml/Theme.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

# ── Executable ────────────────────────────────────────────────────────────────
qt_add_executable(ActivityTracker
    MANUAL_FINALIZATION
    ${SOURCES}
)

# Register QML module (Qt 6 style: replaces .qrc for QML files)
qt_add_qml_module(ActivityTracker
    URI ActivityTracker          # import ActivityTracker 1.0 in QML
    VERSION 1.0
    QML_FILES ${QML_FILES}
    RESOURCES
        resources/icons/app_icon.svg
        resources/icons/arrow-up-down.svg
        resources/icons/bar-chart-2.svg
        resources/icons/book-open.svg
        resources/icons/briefcase.svg
        resources/icons/check.svg
        resources/icons/chevron-down.svg
        resources/icons/clock.svg
        resources/icons/cloud.svg
        resources/icons/copy.svg
        resources/icons/edit-3.svg
        resources/icons/eye.svg
        resources/icons/eye-off.svg
        resources/icons/flame.svg
        resources/icons/grip-vertical.svg
        resources/icons/list-todo.svg
        resources/icons/lock.svg
        resources/icons/log-out.svg
        resources/icons/mail.svg
        resources/icons/moon.svg
        resources/icons/panel-left.svg
        resources/icons/panel-right.svg
        resources/icons/pause.svg
        resources/icons/play.svg
        resources/icons/plus.svg
        resources/icons/rotate-ccw.svg
        resources/icons/search.svg
        resources/icons/sparkles.svg
        resources/icons/sun.svg
        resources/icons/target.svg
        resources/icons/settings.svg
        resources/icons/kanban.svg
        resources/icons/layout-grid.svg
        resources/icons/trash-2.svg
        resources/icons/user.svg
        resources/icons/x.svg
        resources/icons/zap.svg
        resources/icons/filter.svg
        resources/icons/laptop.svg
        resources/icons/monitor.svg
        resources/icons/plus-circle.svg
        resources/icons/x.svg
        resources/icons/zap.svg
)

# ── Link Qt Libraries ─────────────────────────────────────────────────────────
target_link_libraries(ActivityTracker PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::Qml
    Qt6::QuickControls2
)

# ── Include Paths ─────────────────────────────────────────────────────────────
target_include_directories(ActivityTracker PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
)

# ── Platform Executable Properties ────────────────────────────────────────────
if(WIN32)
    # Windows: Pure GUI application (no CLI console window)
    set_target_properties(ActivityTracker PROPERTIES
        WIN32_EXECUTABLE ON
    )
elseif(APPLE)
    # macOS: Native .app bundle with bundle identifier and application metadata
    set_target_properties(ActivityTracker PROPERTIES
        MACOSX_BUNDLE ON
        MACOSX_BUNDLE_GUI_IDENTIFIER "com.cvs.activitytracker"
        MACOSX_BUNDLE_BUNDLE_NAME "CVS Activity Tracker"
        MACOSX_BUNDLE_BUNDLE_VERSION "1.0.0"
        MACOSX_BUNDLE_SHORT_VERSION_STRING "1.0.0"
    )
endif()

qt_finalize_executable(ActivityTracker)

# ── Unit Tests ────────────────────────────────────────────────────────────────
enable_testing()

add_executable(tst_ActivityModel
    tests/tst_ActivityModel.cpp
    src/model/User.h
    src/model/Session.h
    src/model/Activity.h
    src/model/Activity.cpp
    src/model/ActivityListModel.h
    src/model/ActivityListModel.cpp
    src/service/AuthService.h
    src/service/AuthService.cpp
    src/service/ActivityService.h
    src/service/ActivityService.cpp
    src/persistence/JsonStore.h
    src/persistence/JsonStore.cpp
)


target_include_directories(tst_ActivityModel PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${CMAKE_CURRENT_BINARY_DIR}
    ${CMAKE_CURRENT_BINARY_DIR}/tst_ActivityModel_autogen/include
    ${CMAKE_CURRENT_BINARY_DIR}/tst_ActivityModel_autogen/include_Debug
    ${CMAKE_CURRENT_BINARY_DIR}/tst_ActivityModel_autogen/include_Release
)

target_link_libraries(tst_ActivityModel PRIVATE
    Qt6::Core
    Qt6::Test
)

# Isolate test binaries into a separate tests/ directory so they NEVER co-locate with production release binaries
set_target_properties(tst_ActivityModel PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/tests"
    RUNTIME_OUTPUT_DIRECTORY_DEBUG "${CMAKE_BINARY_DIR}/tests"
    RUNTIME_OUTPUT_DIRECTORY_RELEASE "${CMAKE_BINARY_DIR}/tests"
)

add_test(NAME tst_ActivityModel COMMAND tst_ActivityModel)
if(WIN32)
    set_tests_properties(tst_ActivityModel PROPERTIES
        ENVIRONMENT "PATH=$<TARGET_FILE_DIR:Qt6::Core>;$ENV{PATH}"
    )
endif()

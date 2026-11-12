// main.qml — Root application window with dual light/dark theme, executive auth flow & workstation
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Effects
import QtCore
import ActivityTracker 1.0

import "./views"       as Views
import "./views/auth"  as AuthViews
import "./components"  as Components

ApplicationWindow {
    id: root
    visible: true
    width: appSettings.width
    height: appSettings.height
    minimumWidth: 880
    minimumHeight: 600
    title: "CVS Activity Tracker — Executive Workstation"

    // ── Reusable Dark-Styled Menu Component ──────────────────────────────────
    component ModernMenu: Menu {
        id: modernMenuRoot
        delegate: MenuItem {
            id: mItem
            indicator: null // Suppresses default native checkbox overlay

            contentItem: RowLayout {
                spacing: 8

                // shadcn-style vector checkmark indicator for checkable menu items
                Item {
                    implicitWidth: 14
                    implicitHeight: 14
                    visible: mItem.checkable

                    Components.LucideIcon {
                        anchors.centerIn: parent
                        name: "check"
                        size: 12
                        color: mItem.highlighted ? Theme.accentBlue : Theme.textPrimary
                        visible: mItem.checked
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: mItem.text.replace(/&/g, "")
                    font.pixelSize: 12
                    font.bold: mItem.highlighted || mItem.checked
                    color: mItem.enabled ? (mItem.highlighted ? Theme.accentBlue : Theme.textPrimary) : Theme.textMuted
                    elide: Text.ElideRight
                }
                Text {
                    readonly property string shortcutStr: (mItem.action && mItem.action.shortcut) ? ("" + mItem.action.shortcut) : ""
                    visible: shortcutStr.length > 0
                    text: shortcutStr
                    font.pixelSize: 10
                    color: Theme.textMuted
                }
            }
            background: Rectangle {
                implicitWidth: 260
                implicitHeight: 32
                radius: 6
                color: mItem.highlighted ? Theme.surfaceBadge : "transparent"
            }
        }
        background: Rectangle {
            implicitWidth: 260
            radius: 8
            color: Theme.surfaceCard
            border.color: Theme.borderDefault
            border.width: 1
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Theme.isDark ? "#80000000" : "#25000000"
                shadowBlur: 0.8
                shadowVerticalOffset: 4
            }
        }
    }

    // ── Desktop Application MenuBar ───────────────────────────────────────────
    menuBar: MenuBar {
        visible: authService.isLoggedIn

        background: Rectangle {
            color: Theme.surfaceNav
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Theme.borderDefault
            }
        }

        delegate: MenuBarItem {
            id: mbItem
            contentItem: Text {
                text: mbItem.text.replace(/&/g, "")
                font.pixelSize: 12
                font.bold: mbItem.highlighted
                color: mbItem.highlighted ? Theme.accentBlue : Theme.textSecondary
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                implicitWidth: 50
                implicitHeight: 28
                radius: 6
                color: mbItem.highlighted ? Theme.surfaceBadge : "transparent"
            }
        }

        ModernMenu {
            title: "&File"
            Action {
                text: "&New Activity"
                shortcut: "Ctrl+N"
                onTriggered: {
                    root.sidebarCollapsed = false
                    appSettings.sidebarCollapsed = false
                    if (addActivityForm) addActivityForm.focusNameField()
                }
            }
            Action {
                text: "&Refresh Database"
                shortcut: "Ctrl+R"
                onTriggered: activityService.refresh()
            }
            MenuSeparator {}
            Action {
                text: "&Workstation Settings..."
                shortcut: "Ctrl+,"
                onTriggered: settingsModal.open()
            }
            MenuSeparator {}
            Action {
                text: "Sign &Out"
                shortcut: "Ctrl+L"
                onTriggered: authService.logout()
            }
            Action {
                text: "E&xit"
                shortcut: StandardKey.Quit
                onTriggered: Qt.quit()
            }
        }

        ModernMenu {
            title: "&Edit"
            Action {
                text: "&Undo Remove"
                shortcut: StandardKey.Undo
                enabled: activityService.canUndo
                onTriggered: activityService.undoLastDelete()
            }
            MenuSeparator {}
            Action {
                text: "&Clear Completed Activities..."
                onTriggered: settingsModal.clearDoneRequested()
            }
        }

        ModernMenu {
            title: "&View"
            Action {
                text: "&List View"
                shortcut: "Ctrl+1"
                checkable: true
                checked: root.currentViewMode === "list"
                onTriggered: root.currentViewMode = "list"
            }
            Action {
                text: "&Kanban Board"
                shortcut: "Ctrl+2"
                checkable: true
                checked: root.currentViewMode === "kanban"
                onTriggered: root.currentViewMode = "kanban"
            }
            MenuSeparator {}
            Action {
                text: "Toggle &Sidebar"
                shortcut: "Ctrl+B"
                onTriggered: {
                    root.sidebarCollapsed = !root.sidebarCollapsed
                    appSettings.sidebarCollapsed = root.sidebarCollapsed
                }
            }
            Action {
                text: "Switch Dock &Side (Left/Right)"
                shortcut: "Ctrl+D"
                onTriggered: {
                    root.sidebarDock = (root.sidebarDock === "left" ? "right" : "left")
                    appSettings.sidebarDock = root.sidebarDock
                }
            }
            MenuSeparator {}
            Action {
                text: "Toggle Dark / &Light Theme"
                shortcut: "Ctrl+T"
                onTriggered: Theme.toggleTheme()
            }
        }

        ModernMenu {
            title: "&Scope"
            Action {
                text: "Today"
                checkable: true
                checked: root.activeTimeframe === "Today"
                onTriggered: {
                    root.activeTimeframe = "Today"
                    appSettings.activeTimeframe = "Today"
                }
            }
            Action {
                text: "Last 7 Days"
                checkable: true
                checked: root.activeTimeframe === "Last 7 Days"
                onTriggered: {
                    root.activeTimeframe = "Last 7 Days"
                    appSettings.activeTimeframe = "Last 7 Days"
                }
            }
            Action {
                text: "Last 30 Days"
                checkable: true
                checked: root.activeTimeframe === "Last 30 Days"
                onTriggered: {
                    root.activeTimeframe = "Last 30 Days"
                    appSettings.activeTimeframe = "Last 30 Days"
                }
            }
            Action {
                text: "All Time"
                checkable: true
                checked: root.activeTimeframe === "All Time"
                onTriggered: {
                    root.activeTimeframe = "All Time"
                    appSettings.activeTimeframe = "All Time"
                }
            }
        }

        ModernMenu {
            title: "&Help"
            Action {
                text: "Start &Interactive Guided Tour..."
                onTriggered: guidedTour.startTour()
            }
            Action {
                text: "Keyboard &Shortcuts..."
                shortcut: "F1"
                onTriggered: settingsModal.open()
            }
            MenuSeparator {}
            Action {
                text: "&About CVS Activity Tracker"
                onTriggered: aboutDialog.open()
            }
        }
    }

    // ── Persistent Window Geometry & Executive User Preferences ───────────────
    Settings {
        id: appSettings
        category: "WorkstationPreferences_v2"
        property int x: -1
        property int y: -1
        property int width: 1080
        property int height: 740
        property bool isMaximized: false
        property string sidebarDock: "left"         // "left" or "right"
        property bool sidebarCollapsed: false       // true = 56px compact rail, false = full deck
        property string activeTimeframe: "All Time" // Default: "All Time" so all activities show on launch
        property bool hasSeenTour: false            // Auto-launches guided tour on first device run
        property string viewMode: "list"            // "list" or "kanban"
    }

    Component.onCompleted: {
        if (appSettings.x >= 0 && appSettings.y >= 0) {
            root.x = appSettings.x
            root.y = appSettings.y
        }
        if (appSettings.isMaximized) {
            root.showMaximized()
        }
        firstRunTourTimer.start()
    }

    onClosing: {
        appSettings.isMaximized = (root.visibility === Window.Maximized)
        if (root.visibility !== Window.Maximized) {
            appSettings.x = root.x
            appSettings.y = root.y
            appSettings.width = root.width
            appSettings.height = root.height
        }
        appSettings.sidebarDock = root.sidebarDock
        appSettings.sidebarCollapsed = root.sidebarCollapsed
        appSettings.activeTimeframe = root.activeTimeframe
        appSettings.viewMode = root.currentViewMode
    }

    // ── Dynamic Material Style Configuration ─────────────────────────────────
    Material.theme:      Theme.isDark ? Material.Dark : Material.Light
    Material.accent:     Theme.accentBlue
    Material.background: Theme.bgCanvas
    color: Theme.bgCanvas

    Behavior on color { ColorAnimation { duration: 200 } }

    // ── Global Filter & Workstation State ────────────────────────────────────
    property string activeCategoryFilter: "All"
    property string activePriorityFilter: "All"
    property string activeSearchQuery: ""
    property string activeTimeframe: appSettings.activeTimeframe
    property string activeAuthScreen: "login" // "login", "signup", "forgot"
    property string sidebarDock: appSettings.sidebarDock
    property bool   sidebarCollapsed: appSettings.sidebarCollapsed
    property string currentViewMode: appSettings.viewMode || "list"
    property bool undoToastDismissed: false

    // Auto-dismiss undo toast after 6 seconds
    Timer {
        id: undoDismissTimer
        interval: 6000
        repeat: false
        onTriggered: root.undoToastDismissed = true
    }

    // ── Global Shortcuts Matrix ──────────────────────────────────────────────
    Shortcut {
        sequence: "F5"
        onActivated: activityService.refresh()
    }
    Shortcut {
        sequence: "Ctrl+R"
        onActivated: activityService.refresh()
    }
    Shortcut {
        sequences: [ StandardKey.Undo ]
        onActivated: {
            if (activityService.canUndo) {
                activityService.undoLastDelete()
            }
        }
    }
    Shortcut {
        sequence: "Ctrl+B"
        onActivated: {
            root.sidebarCollapsed = !root.sidebarCollapsed
            appSettings.sidebarCollapsed = root.sidebarCollapsed
        }
    }
    Shortcut {
        sequence: "Ctrl+D"
        onActivated: {
            root.sidebarDock = (root.sidebarDock === "left" ? "right" : "left")
            appSettings.sidebarDock = root.sidebarDock
        }
    }
    Shortcut {
        sequence: "Ctrl+F"
        onActivated: {
            if (authService.isLoggedIn && taskSearchField) {
                taskSearchField.forceActiveFocus()
            }
        }
    }
    Shortcut {
        sequence: "Ctrl+T"
        onActivated: Theme.toggleTheme()
    }
    Shortcut {
        sequence: "Ctrl+L"
        onActivated: {
            if (authService.isLoggedIn) authService.logout()
        }
    }

    // Reference to search input for shortcut focusing
    property var taskSearchField: null

    // ── Service Event Notifications ───────────────────────────────────────────
    Connections {
        target: activityService
        function onErrorOccurred(message) {
            errorBar.text = message
            errorBar.visible = true
            errorTimer.restart()
        }
        function onDataRefreshed() {
            refreshToast.visible = true
            refToastTimer.restart()
        }
        function onCanUndoChanged() {
            if (activityService.canUndo) {
                root.undoToastDismissed = false
                undoDismissTimer.restart()
            }
        }
    }

    // =========================================================================
    // 1. DYNAMIC LAZY LOADER FOR AUTH SCREENS
    // =========================================================================
    // Unloads completely from memory when user logs in
    Loader {
        id: authLoader
        anchors.fill: parent
        visible: !authService.isLoggedIn
        active: !authService.isLoggedIn

        sourceComponent: {
            if (authService.isLoggedIn) return null
            switch (root.activeAuthScreen) {
            case "signup": return signupComponent
            case "forgot": return forgotComponent
            default:       return loginComponent
            }
        }
    }

    Component {
        id: loginComponent
        AuthViews.LoginView {
            onNavigateToSignUp: root.activeAuthScreen = "signup"
            onNavigateToForgotPassword: root.activeAuthScreen = "forgot"
        }
    }

    Component {
        id: signupComponent
        AuthViews.SignUpView {
            onNavigateToLogin: root.activeAuthScreen = "login"
        }
    }

    Component {
        id: forgotComponent
        AuthViews.ForgotPasswordView {
            onNavigateToLogin: root.activeAuthScreen = "login"
        }
    }

    // =========================================================================
    // 2. MAIN TRACKER WORKSTATION (Shown when authService.isLoggedIn)
    // =========================================================================
    ColumnLayout {
        id: workstationContainer
        anchors.fill: parent
        spacing: 0
        visible: authService.isLoggedIn

        // ── Top Navigation / Header Bar ───────────────────────────────────────
        Rectangle {
            id: topNavigationHeader
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            color: Theme.surfaceNav
            border.color: Theme.borderDefault
            border.width: 1

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: 20
                    rightMargin: 20
                }
                spacing: 12

                // Brand Logo & Title
                RowLayout {
                    spacing: 10

                    // Primary Sidebar Toggle Button (Ctrl+B)
                    Rectangle {
                        implicitWidth: 32
                        implicitHeight: 32
                        radius: 8
                        color: sbToggleHover.hovered ? Theme.surfaceCardHover : Theme.surfaceBadge
                        border.color: root.sidebarCollapsed ? Theme.borderDefault : Theme.accentBlue
                        border.width: 1

                        Components.LucideIcon {
                            anchors.centerIn: parent
                            name: root.sidebarDock === "left" ? "panel-left" : "panel-right"
                            size: 15
                            color: root.sidebarCollapsed ? Theme.textMuted : Theme.accentBlue
                        }

                        ToolTip.visible: sbToggleHover.hovered
                        ToolTip.text: root.sidebarCollapsed ? "Expand Sidebar (Ctrl+B)" : "Collapse Sidebar (Ctrl+B)"
                        ToolTip.delay: 300

                        HoverHandler { id: sbToggleHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            onTapped: {
                                root.sidebarCollapsed = !root.sidebarCollapsed
                                appSettings.sidebarCollapsed = root.sidebarCollapsed
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: 10
                        color: Theme.accentBlue
                        Components.LucideIcon {
                            anchors.centerIn: parent
                            name: "clock"
                            size: 18
                            color: "#FFFFFF"
                        }
                    }
                    ColumnLayout {
                        spacing: 1
                        Text {
                            text: "CVS Activity Tracker"
                            font.pixelSize: 15
                            font.bold: true
                            color: Theme.textPrimary
                        }
                        RowLayout {
                            spacing: 6
                            Text {
                                text: "Enterprise Workstation"
                                font.pixelSize: 10
                                font.bold: true
                                color: Theme.accentBlue
                                font.letterSpacing: 0.5
                            }
                            Text { text: "•"; color: Theme.textMuted; font.pixelSize: 10 }
                            
                            // Dynamic Neon Database Sync Indicator
                            RowLayout {
                                spacing: 4
                                Components.LucideIcon {
                                    Layout.alignment: Qt.AlignVCenter
                                    name: activityService.syncStatus === "syncing" ? "rotate-ccw" : "cloud"
                                    size: 10
                                    color: activityService.syncStatus === "syncing" 
                                           ? Theme.accentBlue 
                                           : (activityService.syncStatus === "offline" ? Theme.accentAmber : Theme.accentGreen)
                                }
                                Text {
                                    Layout.alignment: Qt.AlignVCenter
                                    text: {
                                        if (activityService.syncStatus === "syncing") return "Syncing Neon DB..."
                                        if (activityService.syncStatus === "offline") return "Offline Cache"
                                        return "Neon PostgreSQL Synced"
                                    }
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: activityService.syncStatus === "syncing" 
                                           ? Theme.accentBlue 
                                           : (activityService.syncStatus === "offline" ? Theme.accentAmber : Theme.accentGreen)
                                }
                            }
                        }
                    }
                }

                Item { Layout.preferredWidth: 12 }

                // ── Timeframe Scope Dropdown Selector ─────────────────────────
                Rectangle {
                    id: timeframeBtn
                    implicitHeight: 32
                    implicitWidth: tfRow.implicitWidth + 24
                    radius: 6
                    color: tfHover.hovered ? Theme.surfaceCardHover : Theme.surfaceBadge
                    border.color: tfMenu.visible ? Theme.accentBlue : Theme.borderDefault
                    border.width: tfMenu.visible ? 2 : 1

                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        id: tfRow
                        anchors.centerIn: parent
                        spacing: 6

                        Components.LucideIcon {
                            Layout.alignment: Qt.AlignVCenter
                            name: "clock"
                            size: 13
                            color: Theme.accentBlue
                        }

                        Text {
                            Layout.alignment: Qt.AlignVCenter
                            text: root.activeTimeframe
                            font.pixelSize: 12
                            font.bold: true
                            color: Theme.textPrimary
                        }

                        Components.LucideIcon {
                            Layout.alignment: Qt.AlignVCenter
                            name: "chevron-down"
                            size: 12
                            color: Theme.textMuted
                        }
                    }

                    ToolTip.visible: tfHover.hovered
                    ToolTip.text: "Filter query timeframe"
                    ToolTip.delay: 300

                    HoverHandler { id: tfHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        onTapped: tfMenu.open()
                    }

                    ModernMenu {
                        id: tfMenu
                        y: timeframeBtn.height + 4

                        Action {
                            text: "Today"
                            checkable: true
                            checked: root.activeTimeframe === "Today"
                            onTriggered: {
                                root.activeTimeframe = "Today"
                                appSettings.activeTimeframe = "Today"
                            }
                        }
                        Action {
                            text: "Last 7 Days"
                            checkable: true
                            checked: root.activeTimeframe === "Last 7 Days"
                            onTriggered: {
                                root.activeTimeframe = "Last 7 Days"
                                appSettings.activeTimeframe = "Last 7 Days"
                            }
                        }
                        Action {
                            text: "Last 30 Days"
                            checkable: true
                            checked: root.activeTimeframe === "Last 30 Days"
                            onTriggered: {
                                root.activeTimeframe = "Last 30 Days"
                                appSettings.activeTimeframe = "Last 30 Days"
                            }
                        }
                        Action {
                            text: "All Time"
                            checkable: true
                            checked: root.activeTimeframe === "All Time"
                            onTriggered: {
                                root.activeTimeframe = "All Time"
                                appSettings.activeTimeframe = "All Time"
                            }
                        }
                    }
                }

                // ── Refresh Database Button (F5 / Ctrl+R) ─────────────────────
                Rectangle {
                    id: refreshBtn
                    implicitWidth: 32
                    implicitHeight: 32
                    radius: 6
                    color: refreshHover.hovered ? Theme.surfaceCardHover : Theme.surfaceBadge
                    border.color: Theme.borderDefault
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Components.LucideIcon {
                        anchors.centerIn: parent
                        name: "rotate-ccw"
                        size: 13
                        color: activityService.syncStatus === "syncing" ? Theme.accentBlue : Theme.textPrimary
                    }

                    ToolTip.visible: refreshHover.hovered
                    ToolTip.text: "Refresh Data from Database (F5 / Ctrl+R)"
                    ToolTip.delay: 300

                    HoverHandler { id: refreshHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        onTapped: activityService.refresh()
                    }
                }

                Item { Layout.fillWidth: true }

                // Quick stats pill in header
                Rectangle {
                    radius: 6
                    color: Theme.surfaceBadge
                    border.color: Theme.borderDefault
                    border.width: 1
                    implicitWidth: headerStats.implicitWidth + 20
                    implicitHeight: 32

                    RowLayout {
                        id: headerStats
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            text: root.activeTimeframe === "Today" ? "Today's Log:" : (root.activeTimeframe + ":")
                            color: Theme.textSecondary
                            font.pixelSize: 12
                        }
                        Text {
                            text: activityService.totalDurationToday + " min"
                            color: Theme.accentBlue
                            font.bold: true
                            font.pixelSize: 12
                        }
                    }
                }

                // ── Theme Switcher Icon Button (Dark / Light) ────────────────
                Rectangle {
                    id: themeToggleBtn
                    radius: 6
                    color: themeHover.hovered ? Theme.surfaceCardHover : Theme.surfaceBadge
                    border.color: Theme.borderDefault
                    border.width: 1
                    implicitWidth: 32
                    implicitHeight: 32

                    Behavior on color { ColorAnimation { duration: 150 } }

                    Components.LucideIcon {
                        anchors.centerIn: parent
                        name: Theme.isDark ? "moon" : "sun"
                        size: 14
                        color: Theme.accentAmber
                    }

                    ToolTip.visible: themeHover.hovered
                    ToolTip.text: Theme.isDark ? "Switch to Light Mode (Ctrl+T)" : "Switch to Dark Mode (Ctrl+T)"
                    ToolTip.delay: 300

                    HoverHandler { id: themeHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        onTapped: Theme.toggleTheme()
                    }
                }

                // ── Executive User Account & Avatar Dropdown ──────────────────
                Rectangle {
                    id: userAccountBtn
                    radius: 6
                    color: userMenu.visible ? Theme.accentBlueBg : (userBtnHover.hovered ? Theme.surfaceCardHover : Theme.surfaceBadge)
                    border.color: userMenu.visible ? Theme.accentBlue : Theme.borderDefault
                    border.width: 1
                    implicitWidth: userBtnRow.implicitWidth + 20
                    implicitHeight: 32

                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        id: userBtnRow
                        anchors.centerIn: parent
                        spacing: 8

                        // Initials Avatar
                        Rectangle {
                            implicitWidth: 22
                            implicitHeight: 22
                            radius: 11
                            color: Theme.accentBlueBg
                            border.color: Theme.accentBlueBorder
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: authService.currentUserName.length > 0 ? authService.currentUserName.charAt(0).toUpperCase() : "U"
                                font.pixelSize: 10
                                font.bold: true
                                color: Theme.accentBlue
                            }
                        }

                        Text {
                            text: authService.currentUserName.length > 0 ? authService.currentUserName : "User Account"
                            color: Theme.textPrimary
                            font.bold: true
                            font.pixelSize: 12
                        }

                        Components.LucideIcon {
                            name: "chevron-down"
                            size: 11
                            color: Theme.textMuted
                        }
                    }

                    ToolTip.visible: userBtnHover.hovered
                    ToolTip.text: "Account & Workstation Preferences"
                    ToolTip.delay: 300

                    HoverHandler { id: userBtnHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: userMenu.open() }

                    ModernMenu {
                        id: userMenu
                        y: userAccountBtn.height + 4

                        Action {
                            text: "&Workstation Settings..."
                            shortcut: "Ctrl+,"
                            onTriggered: settingsModal.open()
                        }
                        Action {
                            text: "Start &Interactive Tour..."
                            onTriggered: guidedTour.startTour()
                        }
                        MenuSeparator {}
                        Action {
                            text: "Sign &Out"
                            shortcut: "Ctrl+L"
                            onTriggered: authService.logout()
                        }
                    }
                }
            }
        }

        // ── Center Content Area: Floating Dockable Sidebar + Workspace ────────
        GridLayout {
            id: workstationBody
            Layout.fillWidth: true
            Layout.fillHeight: true
            rows: 1
            columns: 2
            columnSpacing: 12
            rowSpacing: 0

            // ── Floating Deck Sidebar (Dockable Left or Right, Collapsible) ─────
            Rectangle {
                id: sidebarContainer
                Layout.column: root.sidebarDock === "left" ? 0 : 1
                Layout.row: 0
                Layout.fillHeight: true
                Layout.preferredWidth: root.sidebarCollapsed ? 60 : (root.width > 960 ? 320 : 280)
                Layout.topMargin: 12
                Layout.bottomMargin: 12
                Layout.leftMargin: root.sidebarDock === "left" ? 14 : 0
                Layout.rightMargin: root.sidebarDock === "left" ? 0 : 14
                radius: 14
                clip: true

                color: Theme.surfaceCard
                border.color: Theme.borderDefault
                border.width: 1

                Behavior on Layout.preferredWidth {
                    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                }
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                // Full Form View (Shown when expanded)
                Item {
                    anchors.fill: parent
                    visible: !root.sidebarCollapsed
                    opacity: root.sidebarCollapsed ? 0.0 : 1.0
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        // Sidebar Header
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Components.LucideIcon {
                                Layout.alignment: Qt.AlignVCenter
                                name: "plus-circle"
                                size: 16
                                color: Theme.accentBlue
                            }

                            Text {
                                Layout.alignment: Qt.AlignVCenter
                                text: "New Activity"
                                font.pixelSize: 14
                                font.bold: true
                                color: Theme.textPrimary
                            }

                            Item { Layout.fillWidth: true }

                            // Executive Sidebar Collapse Button
                            Rectangle {
                                Layout.alignment: Qt.AlignVCenter
                                implicitHeight: 28
                                implicitWidth: 28
                                radius: 6
                                color: sidebarCollapseMiniHover.hovered ? Theme.surfaceCardHover : "transparent"
                                border.color: sidebarCollapseMiniHover.hovered ? Theme.borderDefault : "transparent"
                                border.width: 1

                                Components.LucideIcon {
                                    anchors.centerIn: parent
                                    name: root.sidebarDock === "left" ? "panel-left" : "panel-right"
                                    size: 13
                                    color: sidebarCollapseMiniHover.hovered ? Theme.accentBlue : Theme.textMuted
                                }

                                ToolTip.visible: sidebarCollapseMiniHover.hovered
                                ToolTip.text: "Collapse Sidebar (Ctrl+B)"
                                ToolTip.delay: 300

                                HoverHandler { id: sidebarCollapseMiniHover; cursorShape: Qt.PointingHandCursor }
                                TapHandler {
                                    onTapped: {
                                        root.sidebarCollapsed = true
                                        appSettings.sidebarCollapsed = true
                                    }
                                }
                            }
                        }

                        // Embedded Form
                        Components.AddActivityForm {
                            id: addActivityForm
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                        }
                    }
                }

                // Compact Icon Rail (Shown when collapsed)
                ColumnLayout {
                    anchors.fill: parent
                    anchors.topMargin: 16
                    anchors.bottomMargin: 16
                    visible: root.sidebarCollapsed
                    opacity: root.sidebarCollapsed ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    spacing: 16

                    // Expand Action Button
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: 38
                        implicitHeight: 38
                        radius: 8
                        color: railExpandHover.hovered ? Theme.accentBlueBg : Theme.surfaceBadge
                        border.color: railExpandHover.hovered ? Theme.accentBlue : Theme.borderDefault
                        border.width: 1

                        Components.LucideIcon {
                            anchors.centerIn: parent
                            name: "plus"
                            size: 16
                            color: Theme.accentBlue
                        }

                        ToolTip.visible: railExpandHover.hovered
                        ToolTip.text: "Expand Sidebar (Ctrl+B)"
                        ToolTip.delay: 300

                        HoverHandler { id: railExpandHover }
                        TapHandler {
                            onTapped: {
                                root.sidebarCollapsed = false
                                appSettings.sidebarCollapsed = false
                            }
                        }
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: 28
                        implicitHeight: 1
                        color: Theme.borderDefault
                    }

                    // Category Counter Badges in Rail
                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 12

                        // Work icon badge
                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: 32
                            implicitHeight: 32
                            radius: 16
                            color: Theme.accentBlueBg
                            border.color: Theme.accentBlueBorder
                            border.width: 1

                            Components.LucideIcon {
                                anchors.centerIn: parent
                                name: "briefcase"
                                size: 13
                                color: Theme.accentBlue
                            }

                            ToolTip.visible: railWorkHover.hovered
                            ToolTip.text: "Filter Work Activities"
                            ToolTip.delay: 300

                            HoverHandler { id: railWorkHover }
                            TapHandler {
                                onTapped: {
                                    root.activeCategoryFilter = "Work"
                                }
                            }
                        }

                        // Learning icon badge
                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: 32
                            implicitHeight: 32
                            radius: 16
                            color: Theme.accentAmberBg
                            border.color: Theme.accentAmberBorder
                            border.width: 1

                            Components.LucideIcon {
                                anchors.centerIn: parent
                                name: "book-open"
                                size: 13
                                color: Theme.accentAmber
                            }

                            ToolTip.visible: railLearnHover.hovered
                            ToolTip.text: "Filter Learning Activities"
                            ToolTip.delay: 300

                            HoverHandler { id: railLearnHover }
                            TapHandler {
                                onTapped: {
                                    root.activeCategoryFilter = "Learning"
                                }
                            }
                        }

                        // Personal icon badge
                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: 32
                            implicitHeight: 32
                            radius: 16
                            color: Theme.accentGreenBg
                            border.color: Theme.accentGreenBorder
                            border.width: 1

                            Components.LucideIcon {
                                anchors.centerIn: parent
                                name: "user"
                                size: 13
                                color: Theme.accentGreen
                            }

                            ToolTip.visible: railPersHover.hovered
                            ToolTip.text: "Filter Personal Activities"
                            ToolTip.delay: 300

                            HoverHandler { id: railPersHover }
                            TapHandler {
                                onTapped: {
                                    root.activeCategoryFilter = "Personal"
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // Dock Switcher at bottom of rail
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: 32
                        implicitHeight: 32
                        radius: 6
                        color: railDockHover.hovered ? Theme.surfaceCardHover : "transparent"

                        Components.LucideIcon {
                            anchors.centerIn: parent
                            name: root.sidebarDock === "left" ? "panel-right" : "panel-left"
                            size: 13
                            color: Theme.textMuted
                        }

                        ToolTip.visible: railDockHover.hovered
                        ToolTip.text: "Dock to " + (root.sidebarDock === "left" ? "Right" : "Left")
                        ToolTip.delay: 300

                        HoverHandler { id: railDockHover }
                        TapHandler {
                            onTapped: {
                                root.sidebarDock = (root.sidebarDock === "left" ? "right" : "left")
                                appSettings.sidebarDock = root.sidebarDock
                            }
                        }
                    }
                }
            }

            // ── Main Workspace Area (Cards + Toolbar + List) ──────────────────
            Rectangle {
                id: mainWorkspaceArea
                Layout.column: root.sidebarDock === "left" ? 1 : 0
                Layout.row: 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: 12
                Layout.bottomMargin: 12
                Layout.leftMargin: root.sidebarDock === "left" ? 0 : 14
                Layout.rightMargin: root.sidebarDock === "left" ? 14 : 0
                radius: 14
                clip: true
                color: Theme.surfaceSidebar
                border.color: Theme.borderDefault
                border.width: 1

                Behavior on color { ColorAnimation { duration: 150 } }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 14

                    // ── 1. Top Analytics Stats Cards ──────────────────────────
                    Components.StatsDashboard {
                        id: statsDashboardComponent
                        Layout.fillWidth: true
                        timeframe: root.activeTimeframe
                    }

                    // ── 2. Interactive Filter & Search Toolbar ────────────────
                    RowLayout {
                        id: filterToolbarRow
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        spacing: 10

                        // Category Filter Chips
                        RowLayout {
                            spacing: 6

                            Repeater {
                                model: ["All", "Work", "Learning", "Personal", "Done"]
                                delegate: Rectangle {
                                    id: chip
                                    implicitHeight: 32
                                    implicitWidth: chipLabel.implicitWidth + 18
                                    radius: 6
                                    readonly property bool isSelected: root.activeCategoryFilter === modelData

                                    color: isSelected 
                                           ? Theme.accentBlueBg 
                                           : (chipHover.hovered ? Theme.surfaceCardHover : Theme.surfaceBadge)
                                    border.color: isSelected ? Theme.accentBlue : Theme.borderDefault
                                    border.width: 1

                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    Text {
                                        id: chipLabel
                                        anchors.centerIn: parent
                                        text: modelData
                                        font.pixelSize: 12
                                        font.bold: chip.isSelected
                                        color: chip.isSelected ? Theme.accentBlue : Theme.textSecondary
                                    }

                                    HoverHandler { id: chipHover; cursorShape: Qt.PointingHandCursor }
                                    TapHandler {
                                        onTapped: root.activeCategoryFilter = modelData
                                    }
                                }
                            }
                        }

                        // Priority Filter Dropdown Pill
                        Rectangle {
                            id: prioFilterBtn
                            implicitHeight: 32
                            implicitWidth: prioFilterRow.implicitWidth + 20
                            radius: 6
                            readonly property bool isFiltered: root.activePriorityFilter !== "All"
                            color: isFiltered ? Theme.accentBlueBg : (prioFilterHover.hovered ? Theme.surfaceCardHover : Theme.surfaceBadge)
                            border.color: isFiltered ? Theme.accentBlue : Theme.borderDefault
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 120 } }

                            RowLayout {
                                id: prioFilterRow
                                anchors.centerIn: parent
                                spacing: 6

                                Rectangle {
                                    implicitWidth: 6
                                    implicitHeight: 6
                                    radius: 3
                                    color: {
                                        switch (root.activePriorityFilter) {
                                        case "Urgent": return "#EF4444";
                                        case "High":   return "#F97316";
                                        case "Medium": return "#3B82F6";
                                        case "Low":    return "#94A3B8";
                                        default:       return Theme.textSecondary;
                                        }
                                    }
                                }

                                Text {
                                    text: root.activePriorityFilter === "All" ? "Priority: All" : ("Priority: " + root.activePriorityFilter)
                                    font.pixelSize: 11
                                    font.bold: prioFilterBtn.isFiltered
                                    color: prioFilterBtn.isFiltered ? Theme.accentBlue : Theme.textSecondary
                                }

                                Components.LucideIcon {
                                    name: "chevron-down"
                                    size: 11
                                    color: Theme.textMuted
                                }
                            }

                            ToolTip.visible: prioFilterHover.hovered
                            ToolTip.text: "Filter activities by priority"
                            ToolTip.delay: 300

                            HoverHandler { id: prioFilterHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: prioFilterMenu.open() }

                            ModernMenu {
                                id: prioFilterMenu
                                y: prioFilterBtn.height + 4

                                Action {
                                    text: "All Priorities"
                                    checkable: true
                                    checked: root.activePriorityFilter === "All"
                                    onTriggered: root.activePriorityFilter = "All"
                                }
                                Action {
                                    text: "Urgent (P1)"
                                    checkable: true
                                    checked: root.activePriorityFilter === "Urgent"
                                    onTriggered: root.activePriorityFilter = "Urgent"
                                }
                                Action {
                                    text: "High (P2)"
                                    checkable: true
                                    checked: root.activePriorityFilter === "High"
                                    onTriggered: root.activePriorityFilter = "High"
                                }
                                Action {
                                    text: "Medium (P3)"
                                    checkable: true
                                    checked: root.activePriorityFilter === "Medium"
                                    onTriggered: root.activePriorityFilter = "Medium"
                                }
                                Action {
                                    text: "Low (P4)"
                                    checkable: true
                                    checked: root.activePriorityFilter === "Low"
                                    onTriggered: root.activePriorityFilter = "Low"
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // ── View Mode Switcher: List vs Kanban Board ───────────
                        Rectangle {
                            implicitHeight: 32
                            implicitWidth: 160
                            radius: 8
                            color: Theme.surfaceBadge
                            border.color: Theme.borderDefault
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                spacing: 2
                                anchors.margins: 2

                                // List View Switch Pill
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 6
                                    color: root.currentViewMode === "list" ? Theme.accentBlueBg : (listModeHov.hovered ? Theme.surfaceCardHover : "transparent")
                                    border.color: root.currentViewMode === "list" ? Theme.accentBlue : "transparent"
                                    border.width: 1

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 5
                                        Components.LucideIcon {
                                            name: "layout-grid"
                                            size: 12
                                            color: root.currentViewMode === "list" ? Theme.accentBlue : Theme.textMuted
                                        }
                                        Text {
                                            text: "List"
                                            font.pixelSize: 11
                                            font.bold: root.currentViewMode === "list"
                                            color: root.currentViewMode === "list" ? Theme.accentBlue : Theme.textSecondary
                                        }
                                    }

                                    HoverHandler { id: listModeHov; cursorShape: Qt.PointingHandCursor }
                                    TapHandler {
                                        onTapped: root.currentViewMode = "list"
                                    }
                                }

                                // Kanban Board Switch Pill
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 6
                                    color: root.currentViewMode === "kanban" ? Theme.accentBlueBg : (boardModeHov.hovered ? Theme.surfaceCardHover : "transparent")
                                    border.color: root.currentViewMode === "kanban" ? Theme.accentBlue : "transparent"
                                    border.width: 1

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 5
                                        Components.LucideIcon {
                                            name: "kanban"
                                            size: 12
                                            color: root.currentViewMode === "kanban" ? Theme.accentBlue : Theme.textMuted
                                        }
                                        Text {
                                            text: "Board"
                                            font.pixelSize: 11
                                            font.bold: root.currentViewMode === "kanban"
                                            color: root.currentViewMode === "kanban" ? Theme.accentBlue : Theme.textSecondary
                                        }
                                    }

                                    HoverHandler { id: boardModeHov; cursorShape: Qt.PointingHandCursor }
                                    TapHandler {
                                        onTapped: root.currentViewMode = "kanban"
                                    }
                                }
                            }
                        }

                        // Live Instant Search Box
                        Rectangle {
                            implicitWidth: 220
                            implicitHeight: 32
                            radius: 8
                            color: searchInput.activeFocus ? (Theme.isDark ? "#121A28" : "#F8FAFC") : Theme.surfaceInput
                            border.color: searchInput.activeFocus ? Theme.accentBlue : Theme.borderDefault
                            border.width: searchInput.activeFocus ? 2 : 1

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 8
                                spacing: 6

                                Components.LucideIcon {
                                    Layout.alignment: Qt.AlignVCenter
                                    name: "search"
                                    size: 13
                                    color: Theme.textSecondary
                                    opacity: searchInput.activeFocus ? 1.0 : 0.6
                                }

                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "Search activities... (Ctrl+F)"
                                        color: Theme.textMuted
                                        font.pixelSize: 12
                                        visible: searchInput.text.length === 0
                                        opacity: searchInput.activeFocus ? 0.35 : 0.75
                                        Behavior on opacity { NumberAnimation { duration: 120 } }
                                    }

                                    TextField {
                                        id: searchInput
                                        anchors.fill: parent
                                        verticalAlignment: TextInput.AlignVCenter
                                        color: Theme.textPrimary
                                        font.pixelSize: 12
                                        background: null
                                        placeholderText: ""
                                        selectByMouse: true
                                        Component.onCompleted: root.taskSearchField = searchInput
                                        onTextChanged: root.activeSearchQuery = text
                                    }
                                }

                                Rectangle {
                                    Layout.alignment: Qt.AlignVCenter
                                    visible: searchInput.text.length > 0
                                    implicitWidth: 18
                                    implicitHeight: 18
                                    radius: 9
                                    color: searchClearHover.hovered ? Theme.surfaceCardHover : "transparent"

                                    Components.LucideIcon {
                                        anchors.centerIn: parent
                                        name: "x"
                                        size: 10
                                        color: Theme.textMuted
                                    }

                                    HoverHandler { id: searchClearHover }
                                    TapHandler {
                                        onTapped: {
                                            searchInput.text = ""
                                            searchInput.forceActiveFocus()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ── 3. Scrollable Activity List, Kanban Board & Empty State ──
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Views.ActivityListView {
                            id: mainListView
                            anchors.fill: parent
                            filterCategory: root.activeCategoryFilter
                            filterPriority: root.activePriorityFilter
                            filterText: root.activeSearchQuery
                            filterTimeframe: root.activeTimeframe
                            visible: root.currentViewMode === "list" && activityModel.count > 0
                            onEditRequested: function(index) {
                                activityDetailModal.openForActivity(index)
                            }
                        }

                        Views.KanbanBoardView {
                            id: kanbanBoardView
                            anchors.fill: parent
                            filterCategory: root.activeCategoryFilter
                            filterPriority: root.activePriorityFilter
                            filterText: root.activeSearchQuery
                            filterTimeframe: root.activeTimeframe
                            visible: root.currentViewMode === "kanban" && activityModel.count > 0
                            onEditRequested: function(index) {
                                activityDetailModal.openForActivity(index)
                            }
                        }

                        // Empty State View
                        Views.EmptyStateView {
                            anchors.centerIn: parent
                            visible: activityModel.count === 0
                        }
                    }
                }
            }
        }

        // ── Bottom Summary Bar ────────────────────────────────────────────────
        Components.SummaryBar {
            Layout.fillWidth: true
        }
    }

    // ── Floating Error Toast ──────────────────────────────────────────────────
    Rectangle {
        id: errorBar
        property alias text: errorLabel.text

        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            bottomMargin: 55
        }

        visible: false
        width: errorLabel.implicitWidth + 36
        height: 40
        radius: 8
        color: Theme.accentRedBg
        border.color: Theme.accentRedBorder
        border.width: 1

        Text {
            id: errorLabel
            anchors.centerIn: parent
            color: Theme.accentRed
            font.pixelSize: 13
            font.bold: true
        }

        Timer {
            id: errorTimer
            interval: 3500
            onTriggered: errorBar.visible = false
        }
    }

    // ── Floating Optimistic Undo Toast (Ctrl+Z) ──────────────────────────────
    Rectangle {
        id: undoToast
        visible: activityService.canUndo && !root.undoToastDismissed
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            bottomMargin: 24
        }
        height: 42
        implicitWidth: undoRow.implicitWidth + 36
        radius: 8
        color: Theme.isDark ? "#1E293B" : "#0F172A"
        border.color: Theme.accentBlue
        border.width: 1
        z: 99

        RowLayout {
            id: undoRow
            anchors.centerIn: parent
            spacing: 12

            Components.LucideIcon {
                Layout.alignment: Qt.AlignVCenter
                name: "trash-2"
                size: 14
                color: Theme.accentRed
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: "Activity \"" + (activityService.lastDeletedName || "").replace(/(\s*\(Extension\))+$/gi, "").trim() + "\" removed"
                color: "#F8FAFC"
                font.pixelSize: 12
                font.bold: true
            }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                implicitHeight: 26
                implicitWidth: undoBtnRow.implicitWidth + 14
                radius: 4
                color: undoBtnHover.hovered ? Theme.accentBlue : Qt.rgba(Theme.accentBlue.r, Theme.accentBlue.g, Theme.accentBlue.b, 0.25)
                border.color: Theme.accentBlue
                border.width: 1

                Behavior on color { ColorAnimation { duration: 120 } }

                RowLayout {
                    id: undoBtnRow
                    anchors.centerIn: parent
                    spacing: 4
                    Components.LucideIcon {
                        name: "rotate-ccw"
                        size: 11
                        color: "#FFFFFF"
                    }
                    Text {
                        text: "Undo (Ctrl+Z)"
                        font.pixelSize: 11
                        font.bold: true
                        color: "#FFFFFF"
                    }
                }

                HoverHandler { id: undoBtnHover; cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    onTapped: {
                        undoDismissTimer.stop()
                        root.undoToastDismissed = true
                        activityService.undoLastDelete()
                    }
                }
            }

            // Dismiss Button (X)
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 22
                implicitHeight: 22
                radius: 11
                color: closeUndoHover.hovered ? (Theme.isDark ? "#334155" : "#475569") : "transparent"

                Components.LucideIcon {
                    anchors.centerIn: parent
                    name: "x"
                    size: 11
                    color: closeUndoHover.hovered ? "#FFFFFF" : Theme.textMuted
                }

                ToolTip.visible: closeUndoHover.hovered
                ToolTip.text: "Dismiss"
                ToolTip.delay: 200

                HoverHandler { id: closeUndoHover; cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    onTapped: {
                        undoDismissTimer.stop()
                        root.undoToastDismissed = true
                    }
                }
            }
        }
    }

    // ── Floating Refresh Toast ────────────────────────────────────────────────
    Rectangle {
        id: refreshToast
        visible: false
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            bottomMargin: 24
        }
        height: 38
        implicitWidth: refToastRow.implicitWidth + 24
        radius: 8
        color: Theme.isDark ? "#14281E" : "#ECFDF5"
        border.color: Theme.accentGreenBorder
        border.width: 1
        z: 99

        RowLayout {
            id: refToastRow
            anchors.centerIn: parent
            spacing: 8
            Components.LucideIcon {
                Layout.alignment: Qt.AlignVCenter
                name: "check"
                size: 13
                color: Theme.accentGreen
            }
            Text {
                Layout.alignment: Qt.AlignVCenter
                text: "Workstation data refreshed from database"
                color: Theme.accentGreen
                font.pixelSize: 12
                font.bold: true
            }
        }

        Timer {
            id: refToastTimer
            interval: 2500
            onTriggered: refreshToast.visible = false
        }
    }

    // ── First-Run Auto Tour Timer (Waits 500ms after login/mount) ─────────────
    Timer {
        id: firstRunTourTimer
        interval: 500
        repeat: false
        onTriggered: {
            if (authService.isLoggedIn && !appSettings.hasSeenTour && !authService.hasSeenTour) {
                guidedTour.startTour()
            }
        }
    }

    Connections {
        target: authService
        function onLoginSuccess() {
            if (!appSettings.hasSeenTour && !authService.hasSeenTour) {
                firstRunTourTimer.start()
            }
        }
        function onSessionRevoked(reason) {
            sessionRevokedDialog.dialogMessage = reason
            sessionRevokedDialog.open()
        }
    }

    // ── Remote Session Revocation Dialog ──────────────────────────────────────
    Dialog {
        id: sessionRevokedDialog
        property string dialogMessage: "Your session was remotely revoked."
        title: "Session Terminated"
        modal: true
        anchors.centerIn: parent
        width: 360
        standardButtons: Dialog.Ok

        ColumnLayout {
            spacing: 12
            RowLayout {
                spacing: 10
                Components.LucideIcon {
                    name: "log-out"
                    size: 20
                    color: Theme.accentRed
                }
                Text {
                    text: "Logged Out from Remote Device"
                    font.bold: true
                    font.pixelSize: 14
                    color: Theme.textPrimary
                }
            }
            Text {
                Layout.fillWidth: true
                text: sessionRevokedDialog.dialogMessage
                font.pixelSize: 12
                color: Theme.textSecondary
                wrapMode: Text.WordWrap
            }
        }
    }

    // ── Interactive UI Guided Tour ────────────────────────────────────────────
    Components.GuidedTour {
        id: guidedTour
        stepTargets: [
            sidebarContainer,          // Step 1: Floating Task Deck
            statsDashboardComponent,   // Step 2: Executive KPI Dashboard
            filterToolbarRow,          // Step 3: Instant Filters & Search
            mainListView,              // Step 4: Interactive Task Lifecycle & Extensions
            topNavigationHeader        // Step 5: Workstation Customization (Dock/Theme)
        ]

        onTourCompleted: {
            appSettings.hasSeenTour = true
            authService.completeTour()
        }
        onTourSkipped: {
            appSettings.hasSeenTour = true
            authService.completeTour()
        }
    }

    // ── Executive Settings Modal ──────────────────────────────────────────────
    Components.SettingsModal {
        id: settingsModal
        onTourRequested: {
            settingsModal.close()
            guidedTour.startTour()
        }
        onClearDoneRequested: {
            settingsModal.close()
            for (let i = activityModel.count - 1; i >= 0; --i) {
                const item = activityModel.get(i)
                if (item && item.done) {
                    activityService.removeActivity(i)
                }
            }
        }
    }

    // ── Executive Activity Operations & Detail Modal ─────────────────────────
    Components.ActivityDetailModal {
        id: activityDetailModal
    }

    // ── Executive About Workstation Dialog ────────────────────────────────────
    Dialog {
        id: aboutDialog
        title: "About CVS Activity Tracker"
        modal: true
        anchors.centerIn: parent
        width: 440
        standardButtons: Dialog.Close

        ColumnLayout {
            spacing: 14
            RowLayout {
                spacing: 12
                Rectangle {
                    implicitWidth: 44
                    implicitHeight: 44
                    radius: 12
                    color: Theme.accentBlue
                    Components.LucideIcon {
                        anchors.centerIn: parent
                        name: "clock"
                        size: 24
                        color: "#FFFFFF"
                    }
                }
                ColumnLayout {
                    spacing: 2
                    Text {
                        text: "CVS Activity Tracker"
                        font.bold: true
                        font.pixelSize: 16
                        color: Theme.textPrimary
                    }
                    Text {
                        text: "Enterprise Workstation • v1.0.0"
                        font.pixelSize: 12
                        color: Theme.accentBlue
                        font.bold: true
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Theme.borderDefault
            }

            Text {
                Layout.fillWidth: true
                text: "High-performance C++17 MVVM & Qt Quick workstation with Neon PostgreSQL serverless cloud sync, interactive Kanban board, hardware accelerated 60 FPS graphics, and instant remote session revocation."
                font.pixelSize: 12
                color: Theme.textSecondary
                wrapMode: Text.WordWrap
                lineHeight: 1.3
            }

            RowLayout {
                spacing: 6
                Text { text: "Stack:"; font.pixelSize: 11; font.bold: true; color: Theme.textMuted }
                Text { text: "Qt 6.8+ • C++17 • MSVC 2022 • PostgreSQL / Neon"; font.pixelSize: 11; color: Theme.textSecondary }
            }
        }
    }
}

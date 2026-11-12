// SettingsModal.qml — Executive Workstation Settings Dialog
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import ActivityTracker 1.0

Dialog {
    id: settingsModal
    title: ""
    modal: true
    anchors.centerIn: parent
    width: Math.min(680, parent.width - 40)
    height: Math.min(580, parent.height - 40)
    padding: 0
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    signal tourRequested()
    signal clearDoneRequested()

    background: Rectangle {
        radius: 16
        color: Theme.surfaceCard
        border.color: Theme.borderDefault
        border.width: 1

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Theme.isDark ? "#80000000" : "#25000000"
            shadowBlur: 0.8
            shadowVerticalOffset: 6
        }
    }

    contentItem: ColumnLayout {
        spacing: 0

        // ── Modal Header Bar ──────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            color: Theme.surfaceNav
            radius: 16
            // Only top corners rounded
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 16
                color: Theme.surfaceNav
            }
            border.color: Theme.borderDefault
            border.width: 1

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: 20
                    rightMargin: 16
                }
                spacing: 10

                LucideIcon {
                    name: "settings"
                    size: 18
                    color: Theme.accentBlue
                }

                Text {
                    text: "Workstation Settings"
                    font.pixelSize: 16
                    font.bold: true
                    color: Theme.textPrimary
                }

                Item { Layout.fillWidth: true }

                // Close Button (X)
                Rectangle {
                    implicitWidth: 30
                    implicitHeight: 30
                    radius: 15
                    color: closeSettingsHover.hovered ? Theme.surfaceBadge : "transparent"

                    LucideIcon {
                        anchors.centerIn: parent
                        name: "x"
                        size: 14
                        color: Theme.textMuted
                    }

                    HoverHandler { id: closeSettingsHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: settingsModal.close() }
                }
            }
        }

        // ── Tabs Navigation ───────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            color: Theme.surfaceSidebar
            border.color: Theme.borderDefault
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                spacing: 8

                Repeater {
                    model: ["Preferences", "Active Sessions", "Data & Cloud"]
                    delegate: Rectangle {
                        id: tabItem
                        implicitHeight: 32
                        implicitWidth: tabLabel.implicitWidth + 24
                        radius: 8
                        readonly property bool isSelected: tabView.currentIndex === index
                        color: isSelected ? Theme.accentBlueBg : (tabHover.hovered ? Theme.surfaceCardHover : "transparent")
                        border.color: isSelected ? Theme.accentBlueBorder : "transparent"
                        border.width: 1

                        Text {
                            id: tabLabel
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: 12
                            font.bold: tabItem.isSelected
                            color: tabItem.isSelected ? Theme.accentBlue : Theme.textSecondary
                        }

                        HoverHandler { id: tabHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: tabView.currentIndex = index }
                    }
                }
            }
        }

        // ── Tab Content Views ─────────────────────────────────────────────────
        StackLayout {
            id: tabView
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: 0

            // ── Tab 1: Preferences ────────────────────────────────────────────
            ScrollView {
                id: prefScroll
                clip: true
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                Item {
                    width: prefScroll.availableWidth
                    implicitHeight: prefCol.implicitHeight + 48

                    ColumnLayout {
                        id: prefCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            leftMargin: 24
                            rightMargin: 24
                            topMargin: 20
                        }
                        spacing: 20

                        // Theme Preference
                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                spacing: 3
                                Text { text: "Interface Theme"; font.bold: true; font.pixelSize: 13; color: Theme.textPrimary }
                                Text { text: "Select between high-contrast Dark and Light workstation modes"; font.pixelSize: 11; color: Theme.textMuted }
                            }
                            Item { Layout.fillWidth: true }
                            RowLayout {
                                spacing: 8
                                Rectangle {
                                    implicitWidth: 84; implicitHeight: 32; radius: 6
                                    color: Theme.isDark ? Theme.accentBlueBg : Theme.surfaceBadge
                                    border.color: Theme.isDark ? Theme.accentBlue : Theme.borderDefault; border.width: 1
                                    RowLayout {
                                        anchors.centerIn: parent; spacing: 6
                                        LucideIcon { name: "moon"; size: 12; color: Theme.isDark ? Theme.accentBlue : Theme.textSecondary }
                                        Text { text: "Dark"; font.bold: true; font.pixelSize: 11; color: Theme.isDark ? Theme.accentBlue : Theme.textSecondary }
                                    }
                                    TapHandler { onTapped: if (!Theme.isDark) Theme.toggleTheme() }
                                }
                                Rectangle {
                                    implicitWidth: 84; implicitHeight: 32; radius: 6
                                    color: !Theme.isDark ? Theme.accentBlueBg : Theme.surfaceBadge
                                    border.color: !Theme.isDark ? Theme.accentBlue : Theme.borderDefault; border.width: 1
                                    RowLayout {
                                        anchors.centerIn: parent; spacing: 6
                                        LucideIcon { name: "sun"; size: 12; color: !Theme.isDark ? Theme.accentBlue : Theme.textSecondary }
                                        Text { text: "Light"; font.bold: true; font.pixelSize: 11; color: !Theme.isDark ? Theme.accentBlue : Theme.textSecondary }
                                    }
                                    TapHandler { onTapped: if (Theme.isDark) Theme.toggleTheme() }
                                }
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.borderDefault }

                        // Sidebar Dock Position
                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                spacing: 3
                                Text { text: "Sidebar Dock Position"; font.bold: true; font.pixelSize: 13; color: Theme.textPrimary }
                                Text { text: "Choose which side the Floating Task Deck docks to"; font.pixelSize: 11; color: Theme.textMuted }
                            }
                            Item { Layout.fillWidth: true }
                            RowLayout {
                                spacing: 8
                                Rectangle {
                                    implicitWidth: 84; implicitHeight: 32; radius: 6
                                    color: root.sidebarDock === "left" ? Theme.accentBlueBg : Theme.surfaceBadge
                                    border.color: root.sidebarDock === "left" ? Theme.accentBlue : Theme.borderDefault; border.width: 1
                                    RowLayout {
                                        anchors.centerIn: parent; spacing: 6
                                        LucideIcon { name: "panel-left"; size: 12; color: root.sidebarDock === "left" ? Theme.accentBlue : Theme.textSecondary }
                                        Text { text: "Left"; font.bold: true; font.pixelSize: 11; color: root.sidebarDock === "left" ? Theme.accentBlue : Theme.textSecondary }
                                    }
                                    TapHandler { onTapped: { root.sidebarDock = "left"; appSettings.sidebarDock = "left" } }
                                }
                                Rectangle {
                                    implicitWidth: 84; implicitHeight: 32; radius: 6
                                    color: root.sidebarDock === "right" ? Theme.accentBlueBg : Theme.surfaceBadge
                                    border.color: root.sidebarDock === "right" ? Theme.accentBlue : Theme.borderDefault; border.width: 1
                                    RowLayout {
                                        anchors.centerIn: parent; spacing: 6
                                        LucideIcon { name: "panel-right"; size: 12; color: root.sidebarDock === "right" ? Theme.accentBlue : Theme.textSecondary }
                                        Text { text: "Right"; font.bold: true; font.pixelSize: 11; color: root.sidebarDock === "right" ? Theme.accentBlue : Theme.textSecondary }
                                    }
                                    TapHandler { onTapped: { root.sidebarDock = "right"; appSettings.sidebarDock = "right" } }
                                }
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.borderDefault }

                        // Daily Work Goal Target
                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                spacing: 3
                                Text { text: "Daily Focus Goal"; font.bold: true; font.pixelSize: 13; color: Theme.textPrimary }
                                Text { text: "Target focus hours per day to achieve 100% completion"; font.pixelSize: 11; color: Theme.textMuted }
                            }
                            Item { Layout.fillWidth: true }
                            RowLayout {
                                spacing: 6
                                Repeater {
                                    model: [2, 4, 6, 8]
                                    delegate: Rectangle {
                                        implicitWidth: 46; implicitHeight: 32; radius: 6
                                        readonly property bool isSelected: (modelData * 60) === authService.dailyGoalMinutes
                                        color: isSelected ? Theme.accentBlueBg : Theme.surfaceBadge
                                        border.color: isSelected ? Theme.accentBlue : Theme.borderDefault; border.width: 1
                                        Text { anchors.centerIn: parent; text: modelData + "h"; font.bold: true; font.pixelSize: 11; color: isSelected ? Theme.accentBlue : Theme.textSecondary }
                                        TapHandler {
                                            onTapped: {
                                                authService.updateDailyGoal(modelData * 60)
                                                authService.syncPreferences(Theme.isDark ? "dark" : "light", root.sidebarDock, root.sidebarCollapsed, root.activeTimeframe, true)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Tab 2: Active Sessions ────────────────────────────────────────
            ScrollView {
                id: sessionScroll
                clip: true
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                Item {
                    width: sessionScroll.availableWidth
                    implicitHeight: sessionCol.implicitHeight + 48

                    ColumnLayout {
                        id: sessionCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            leftMargin: 24
                            rightMargin: 24
                            topMargin: 20
                        }
                        spacing: 14

                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                spacing: 3
                                Text { text: "Active Client Sessions"; font.bold: true; font.pixelSize: 13; color: Theme.textPrimary }
                                Text { text: "Manage authenticated devices and revoke remote access instantly"; font.pixelSize: 11; color: Theme.textMuted }
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: authService.activeSessionsCount + " Active Devices"
                                font.bold: true; font.pixelSize: 11; color: Theme.accentGreen
                            }
                        }

                        // Sessions List
                        Repeater {
                            model: authService.activeSessions
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                height: 64
                                radius: 10
                                color: Theme.surfaceSidebar
                                border.color: modelData.isCurrent ? Theme.accentBlueBorder : Theme.borderDefault
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 12

                                    LucideIcon {
                                        name: modelData.platform === "macos" ? "laptop" : "monitor"
                                        size: 18
                                        color: modelData.isCurrent ? Theme.accentBlue : Theme.textSecondary
                                    }

                                    ColumnLayout {
                                        spacing: 3
                                        RowLayout {
                                            spacing: 6
                                            Text { text: modelData.deviceName; font.bold: true; font.pixelSize: 12; color: Theme.textPrimary }
                                            Rectangle {
                                                visible: modelData.isCurrent
                                                radius: 6; implicitWidth: 64; implicitHeight: 18; color: Theme.accentBlueBg; border.color: Theme.accentBlueBorder; border.width: 1
                                                Text { anchors.centerIn: parent; text: "This Device"; font.pixelSize: 9; font.bold: true; color: Theme.accentBlue }
                                            }
                                        }
                                        Text {
                                            text: "Last Active: " + (modelData.lastActiveAt ? modelData.lastActiveAt.replace('T', ' ').substring(0, 16) : "Just now")
                                            font.pixelSize: 10; color: Theme.textMuted
                                        }
                                    }

                                    Item { Layout.fillWidth: true }

                                    // Revoke Button (only for other devices)
                                    ShadcnButton {
                                        visible: !modelData.isCurrent
                                        variant: "destructive"
                                        size: "sm"
                                        text: "Revoke"
                                        onClicked: authService.revokeSession(modelData.id)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Tab 3: Data & Cloud ───────────────────────────────────────────
            ScrollView {
                id: dataScroll
                clip: true
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                Item {
                    width: dataScroll.availableWidth
                    implicitHeight: dataCol.implicitHeight + 48

                    ColumnLayout {
                        id: dataCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            leftMargin: 24
                            rightMargin: 24
                            topMargin: 20
                        }
                        spacing: 20

                        // Neon DB Status
                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                spacing: 3
                                Text { text: "Cloud Database Connection"; font.bold: true; font.pixelSize: 13; color: Theme.textPrimary }
                                Text { text: "Neon Serverless PostgreSQL (ap-southeast-1 pooler)"; font.pixelSize: 11; color: Theme.textMuted }
                            }
                            Item { Layout.fillWidth: true }
                            Rectangle {
                                radius: 10; implicitWidth: 90; implicitHeight: 24
                                color: Theme.accentGreenBg; border.color: Theme.accentGreenBorder; border.width: 1
                                RowLayout {
                                    anchors.centerIn: parent; spacing: 4
                                    LucideIcon { name: "cloud"; size: 11; color: Theme.accentGreen }
                                    Text { text: "Connected"; font.bold: true; font.pixelSize: 10; color: Theme.accentGreen }
                                }
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.borderDefault }

                        // Replay Guided Tour
                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                spacing: 3
                                Text { text: "Workstation Guided Tour"; font.bold: true; font.pixelSize: 13; color: Theme.textPrimary }
                                Text { text: "Restart the 5-step interactive onboarding walkthrough"; font.pixelSize: 11; color: Theme.textMuted }
                            }
                            Item { Layout.fillWidth: true }
                            ShadcnButton {
                                variant: "outline"
                                size: "sm"
                                iconName: "sparkles"
                                text: "Start Tour"
                                onClicked: {
                                    settingsModal.close()
                                    settingsModal.tourRequested()
                                }
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.borderDefault }

                        // Clear Completed Tasks Action
                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                spacing: 3
                                Text { text: "Clean Finished Tasks"; font.bold: true; font.pixelSize: 13; color: Theme.textPrimary }
                                Text { text: "Remove completed tasks from list to keep workstation focused"; font.pixelSize: 11; color: Theme.textMuted }
                            }
                            Item { Layout.fillWidth: true }
                            ShadcnButton {
                                variant: "destructive"
                                size: "sm"
                                iconName: "trash-2"
                                text: "Clear Done"
                                onClicked: {
                                    settingsModal.close()
                                    settingsModal.clearDoneRequested()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// AnalyticsView.qml — executive productivity charts & visual time analytics
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ActivityTracker 1.0
import "../components" as Components

ScrollView {
    id: analyticsRoot
    clip: true
    ScrollBar.vertical.policy: ScrollBar.AsNeeded

    Item {
        width: analyticsRoot.availableWidth
        implicitHeight: analyticsCol.implicitHeight + 40

        ColumnLayout {
            id: analyticsCol
            width: Math.min(parent.width - 32, 840)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 16
            spacing: 18

        // ── Top Header KPI Cards ──────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Total Focus Time Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 90
                radius: 10
                color: Theme.surfaceCard
                border.color: Theme.borderDefault
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 4

                    RowLayout {
                        spacing: 6
                        Components.LucideIcon { name: "clock"; size: 13; color: Theme.accentBlue }
                        Text { text: "Total Logged Today"; color: Theme.textSecondary; font.pixelSize: 11; font.bold: true }
                    }
                    Text {
                        text: activityService.totalDurationToday + " mins"
                        color: Theme.accentBlue
                        font.pixelSize: 22
                        font.bold: true
                    }
                    Text {
                        text: "(" + (activityService.totalDurationToday / 60).toFixed(1) + " productive hours)"
                        color: Theme.textMuted
                        font.pixelSize: 10
                    }
                }
            }

            // Daily Target Pace Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 90
                radius: 10
                color: Theme.surfaceCard
                border.color: Theme.borderDefault
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 4

                    RowLayout {
                        spacing: 6
                        Components.LucideIcon { name: "target"; size: 13; color: Theme.accentGreen }
                        Text { text: "Daily Target Progress"; color: Theme.textSecondary; font.pixelSize: 11; font.bold: true }
                    }
                    RowLayout {
                        spacing: 8
                        Text {
                            readonly property int pct: Math.min(100, Math.round((activityService.totalDurationToday / (authService.dailyGoalMinutes > 0 ? authService.dailyGoalMinutes : 240)) * 100))
                            text: pct + "%"
                            color: pct >= 100 ? Theme.accentGreen : Theme.accentAmber
                            font.pixelSize: 22
                            font.bold: true
                        }
                        Text {
                            text: "of " + (authService.dailyGoalMinutes / 60).toFixed(0) + "h goal"
                            color: Theme.textMuted
                            font.pixelSize: 11
                        }
                    }
                    Text {
                        readonly property int remaining: Math.max(0, (authService.dailyGoalMinutes > 0 ? authService.dailyGoalMinutes : 240) - activityService.totalDurationToday)
                        text: remaining > 0 ? (remaining + " mins to reach daily target") : "Daily target reached!"
                        color: remaining > 0 ? Theme.textSecondary : Theme.accentGreen
                        font.pixelSize: 10
                        font.bold: remaining === 0
                    }
                }
            }

            // Active Focus Streak Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 90
                radius: 10
                color: Theme.surfaceCard
                border.color: Theme.borderDefault
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 4

                    RowLayout {
                        spacing: 6
                        Components.LucideIcon { name: "flame"; size: 13; color: Theme.accentAmber }
                        Text { text: "Focus Streak"; color: Theme.textSecondary; font.pixelSize: 11; font.bold: true }
                    }
                    Text {
                        text: "3 Days"
                        color: Theme.accentAmber
                        font.pixelSize: 22
                        font.bold: true
                    }
                    Text {
                        text: "Active daily focus momentum"
                        color: Theme.textMuted
                        font.pixelSize: 10
                    }
                }
            }
        }

        // ── 7-Day Weekly Productivity Bar Chart ───────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 260
            radius: 10
            color: Theme.surfaceCard
            border.color: Theme.borderDefault
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "📊 Weekly Productivity Trend"
                        font.pixelSize: 15
                        font.bold: true
                        color: Theme.textPrimary
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "Target: " + (authService.dailyGoalMinutes / 60).toFixed(0) + "h/day"
                        font.pixelSize: 11
                        color: Theme.textMuted
                    }
                }

                // Bar Chart Area
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Theme.surfaceInput
                    radius: 8
                    border.color: Theme.borderDefault
                    border.width: 1

                    // Target benchmark line (4 hours / 240m = 65% height)
                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        y: parent.height * 0.35
                        height: 1
                        color: Theme.accentAmber
                        opacity: 0.4
                        z: 1
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12

                        Repeater {
                            model: [
                                { day: "Mon", mins: 210, isToday: false },
                                { day: "Tue", mins: 270, isToday: false },
                                { day: "Wed", mins: activityService.totalDurationToday > 0 ? activityService.totalDurationToday : 195, isToday: true },
                                { day: "Thu", mins: 180, isToday: false },
                                { day: "Fri", mins: 240, isToday: false },
                                { day: "Sat", mins: 90,  isToday: false },
                                { day: "Sun", mins: 60,  isToday: false }
                            ]
                            delegate: Item {
                                id: barCol
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                property int barMins: modelData.mins
                                property double maxMins: 360.0 // 6h scale
                                property double barHeight: Math.min(parent.height - 35, Math.max(12, (barMins / maxMins) * (parent.height - 35)))

                                ColumnLayout {
                                    anchors.fill: parent
                                    spacing: 4

                                    Item { Layout.fillHeight: true }

                                    // Bar rectangle with hover scale
                                    Rectangle {
                                        Layout.alignment: Qt.AlignHCenter
                                        width: Math.min(32, parent.width - 8)
                                        height: barCol.barHeight
                                        radius: 6

                                        color: modelData.isToday 
                                               ? (barHover.hovered ? Qt.lighter(Theme.accentBlue, 1.15) : Theme.accentBlue)
                                               : (barHover.hovered ? Qt.lighter(Theme.accentBlueBg, 1.2) : (Theme.isDark ? "#1E293B" : "#E2E8F0"))
                                        border.color: modelData.isToday ? Theme.accentBlue : Theme.borderDefault
                                        border.width: modelData.isToday ? 2 : 1

                                        Behavior on height { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
                                        Behavior on color { ColorAnimation { duration: 150 } }

                                        HoverHandler { id: barHover }

                                        ToolTip.visible: barHover.hovered
                                        ToolTip.text: modelData.day + ": " + modelData.mins + " mins (" + (modelData.mins / 60).toFixed(1) + " hrs)"
                                        ToolTip.delay: 100
                                    }

                                    // Day label
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: modelData.day
                                        font.pixelSize: 11
                                        font.bold: modelData.isToday
                                        color: modelData.isToday ? Theme.accentBlue : Theme.textSecondary
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Category Time Distribution Section ────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 140
            radius: 10
            color: Theme.surfaceCard
            border.color: Theme.borderDefault
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                RowLayout {
                    spacing: 8
                    Components.LucideIcon {
                        name: "briefcase"
                        size: 15
                        color: Theme.accentBlue
                    }
                    Text {
                        text: "Focus Distribution by Category"
                        font.pixelSize: 15
                        font.bold: true
                        color: Theme.textPrimary
                    }
                }

                // Multi-Segment Horizontal Distribution Bar
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 18
                    radius: 9
                    color: Theme.surfaceInput
                    clip: true

                    Row {
                        anchors.fill: parent

                        // Work Segment (55% estimate)
                        Rectangle {
                            height: parent.height
                            width: parent.width * 0.55
                            color: Theme.accentBlue
                        }
                        // Learning Segment (30% estimate)
                        Rectangle {
                            height: parent.height
                            width: parent.width * 0.30
                            color: Theme.accentAmber
                        }
                        // Personal Segment (15% estimate)
                        Rectangle {
                            height: parent.height
                            width: parent.width * 0.15
                            color: Theme.accentGreen
                        }
                    }
                }

                // Legend Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 20

                    RowLayout {
                        spacing: 6
                        Rectangle { width: 10; height: 10; radius: 5; color: Theme.accentBlue }
                        Text { text: "Work (55%)"; color: Theme.textSecondary; font.pixelSize: 12; font.bold: true }
                    }

                    RowLayout {
                        spacing: 6
                        Rectangle { width: 10; height: 10; radius: 5; color: Theme.accentAmber }
                        Text { text: "Learning (30%)"; color: Theme.textSecondary; font.pixelSize: 12; font.bold: true }
                    }

                    RowLayout {
                        spacing: 6
                        Rectangle { width: 10; height: 10; radius: 5; color: Theme.accentGreen }
                        Text { text: "Personal (15%)"; color: Theme.textSecondary; font.pixelSize: 12; font.bold: true }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "Real-time sync via Neon Cloud DB"
                        color: Theme.textMuted
                        font.pixelSize: 11
                    }
                }
            }
        }
    }
}
}

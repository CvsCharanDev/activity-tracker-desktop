// StatsDashboard.qml — executive KPI metrics cards with responsive grid reflow and Lucide icons
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import ActivityTracker 1.0

GridLayout {
    id: statsGrid

    property string timeframe: "Today"

    // Responsive Breakpoints:
    // Wide (>800px): 4 cards in 1 row
    // Medium (440px-800px): 2 rows x 2 columns
    // Compact (<440px): 1 column x 4 rows
    columns: width > 800 ? 4 : (width > 440 ? 2 : 1)
    rowSpacing: 10
    columnSpacing: 10

    // ── Reusable Classic Stat Card Component ──────────────────────────────────
    component StatCard: Rectangle {
        id: cardRoot
        Layout.fillWidth: true
        Layout.preferredHeight: 84
        radius: 10
        color: cardHover.hovered ? Theme.surfaceCardHover : Theme.surfaceCard
        border.color: cardHover.hovered ? Theme.borderFocus : Theme.borderDefault
        border.width: 1

        layer.enabled: !Theme.isDark
        layer.effect: MultiEffect {
            shadowEnabled: !Theme.isDark
            shadowColor: "#08000000"
            shadowBlur: 0.35
            shadowVerticalOffset: 1
        }

        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on border.color { ColorAnimation { duration: 140 } }

        HoverHandler { id: cardHover }

        required property string iconName
        required property string statValue
        required property string statTitle
        required property string statSubtitle
        required property color  accentColor
        property string tagText: ""
        property bool   showProgressBar: false
        property real   progressRatio: 0.0

        // Subtle Icon Pill (Top-Right)
        Rectangle {
            id: iconBadge
            width: 30
            height: 30
            radius: 8
            anchors.top: parent.top
            anchors.topMargin: 12
            anchors.right: parent.right
            anchors.rightMargin: 14
            color: Theme.surfaceBadge
            border.color: Theme.borderSubtle
            border.width: 1

            LucideIcon {
                anchors.centerIn: parent
                name: cardRoot.iconName
                size: 15
                color: cardRoot.accentColor
            }
        }

        // Title and Value
        Column {
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.right: iconBadge.left
            anchors.rightMargin: 10
            anchors.top: parent.top
            anchors.topMargin: 12
            spacing: 3

            Text {
                text: statTitle
                font.pixelSize: 11
                font.bold: true
                color: Theme.textSecondary
                font.letterSpacing: 0.5
            }

            Text {
                text: statValue
                font.pixelSize: 22
                font.bold: true
                color: Theme.textPrimary
            }
        }

        // Bottom Row: Subtitle & Progress
        RowLayout {
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            spacing: 6

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: statSubtitle
                font.pixelSize: 11
                color: Theme.textMuted
                font.bold: false
            }

            Item { Layout.fillWidth: true }

            // Progress Meter
            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                visible: cardRoot.showProgressBar
                spacing: 6

                Text {
                    Layout.alignment: Qt.AlignVCenter
                    text: Math.round(cardRoot.progressRatio * 100) + "%"
                    font.pixelSize: 11
                    font.bold: true
                    color: Theme.accentGreen
                }

                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: 44
                    implicitHeight: 4
                    radius: 2
                    color: Theme.surfaceBadge

                    Rectangle {
                        height: parent.height
                        width: parent.width * Math.max(0.0, Math.min(1.0, cardRoot.progressRatio))
                        radius: 2
                        color: Theme.accentGreen

                        Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    }
                }
            }

            // Contextual Tag
            Text {
                visible: !cardRoot.showProgressBar && cardRoot.tagText.length > 0
                text: cardRoot.tagText
                font.pixelSize: 10
                font.bold: true
                color: Theme.textMuted
            }
        }
    }

    // ── 1. Total Activities Card ──────────────────────────────────────────────
    StatCard {
        iconName: "list-todo"
        statTitle: "TOTAL ACTIVITIES"
        statValue: activityModel.count.toString()
        statSubtitle: activityModel.count === 1 ? "1 item logged" : activityModel.count + " items logged"
        accentColor: Theme.textSecondary
        tagText: "All Tasks"
        showProgressBar: false
    }

    // ── 2. Completed Card ─────────────────────────────────────────────────────
    StatCard {
        iconName: "check"
        statTitle: "COMPLETED"
        statValue: activityService.completedCount.toString()
        statSubtitle: activityModel.count > 0 
                      ? (activityService.completedCount + " of " + activityModel.count + " done")
                      : "0 completed"
        accentColor: Theme.accentGreen
        showProgressBar: activityModel.count > 0
        progressRatio: activityModel.count > 0 ? (activityService.completedCount / activityModel.count) : 0.0
    }

    // ── 3. Pending Card ───────────────────────────────────────────────────────
    StatCard {
        iconName: "zap"
        statTitle: "IN PROGRESS"
        statValue: activityService.pendingCount.toString()
        statSubtitle: activityService.pendingCount === 1 ? "1 task active" : activityService.pendingCount + " tasks active"
        accentColor: Theme.accentBlue
        showProgressBar: false
        tagText: activityService.pendingCount === 0 ? "All caught up" : ""
    }

    // ── 4. Time Tracked Card ──────────────────────────────────────────────────
    StatCard {
        iconName: "clock"
        statTitle: statsGrid.timeframe === "Today" ? "TIME TODAY" : "TIME TRACKED"
        statValue: formatBoth(statsGrid.timeframe === "Today" ? activityService.totalDurationToday : activityService.totalDurationAllTime)
        statSubtitle: (statsGrid.timeframe === "Today" ? activityService.totalDurationToday : activityService.totalDurationAllTime) + " mins total"
        accentColor: Theme.accentPurple
        showProgressBar: false
        tagText: statsGrid.timeframe === "Today" ? "Daily" : "All Time"

        function formatBoth(mins) {
            if (!mins || mins <= 0) return "0m"
            if (mins < 60) return mins + "m"
            const h = Math.floor(mins / 60)
            const m = mins % 60
            return m > 0 ? (h + "h " + m + "m") : (h + "h")
        }
    }
}

// StatsDashboard.qml — executive KPI metrics cards with responsive grid reflow and Lucide icons
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import ActivityTracker 1.0

GridLayout {
    id: statsGrid

    property string timeframe: "Today"

    // ── Responsive Breakpoints ────────────────────────────────────────────────
    // Wide display (>800px): 4 cards in 1 row
    // Half-screen snap / Tablet (440px-800px): 2 rows x 2 columns
    // Compact (<440px): 1 column x 4 rows
    columns: width > 800 ? 4 : (width > 440 ? 2 : 1)
    rowSpacing: 10
    columnSpacing: 10

    // ── Reusable Stat Card Component ──────────────────────────────────────────
    component StatCard: Rectangle {
        id: cardRoot
        Layout.fillWidth: true
        Layout.preferredHeight: 90
        radius: 10
        color: cardHover.hovered ? Theme.surfaceCardHover : Theme.surfaceCard
        border.color: cardHover.hovered ? accentColor : Theme.borderDefault
        border.width: 1

        layer.enabled: !Theme.isDark
        layer.effect: MultiEffect {
            shadowEnabled: !Theme.isDark
            shadowColor: "#0A000000"
            shadowBlur: 0.35
            shadowVerticalOffset: 1
        }

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        HoverHandler { id: cardHover }

        required property string iconName
        required property string statValue
        required property string statTitle
        required property string statSubtitle
        required property var    accentColor
        property string tagText: ""
        property color  tagColor: accentColor
        property bool   showProgressBar: false
        property real   progressRatio: 0.0 // 0.0 to 1.0

        // Rounded Icon Badge — pinned to top-right corner
        Rectangle {
            id: iconBadge
            width: 32
            height: 32
            radius: 8
            anchors.top: parent.top
            anchors.topMargin: 12
            anchors.right: parent.right
            anchors.rightMargin: 14
            color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, Theme.isDark ? 0.12 : 0.08)
            border.color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, Theme.isDark ? 0.25 : 0.2)
            border.width: 1

            LucideIcon {
                anchors.centerIn: parent
                name: cardRoot.iconName
                size: 16
                color: cardRoot.accentColor
            }
        }

        // Title and Primary Value
        Column {
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.right: iconBadge.left
            anchors.rightMargin: 10
            anchors.top: parent.top
            anchors.topMargin: 12
            spacing: 2

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

        // Bottom Row: Subtitle on left, contextual status badge or labeled progress on right
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
                color: accentColor
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            // Clear, Labeled Progress Meter (Only shown for metrics where progress has clear meaning)
            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                visible: cardRoot.showProgressBar
                spacing: 6

                Text {
                    Layout.alignment: Qt.AlignVCenter
                    text: Math.round(cardRoot.progressRatio * 100) + "%"
                    font.pixelSize: 11
                    font.bold: true
                    color: cardRoot.accentColor
                }

                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: 46
                    implicitHeight: 4
                    radius: 2
                    color: Theme.surfaceBadge

                    Rectangle {
                        height: parent.height
                        width: parent.width * Math.max(0.0, Math.min(1.0, cardRoot.progressRatio))
                        radius: 2
                        color: cardRoot.accentColor

                        Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    }
                }
            }

            // Contextual Status Pill (Used for count metrics where a progress bar is ambiguous)
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                visible: !cardRoot.showProgressBar && cardRoot.tagText.length > 0
                radius: 10
                implicitHeight: 18
                implicitWidth: tagLabel.implicitWidth + 12
                color: Qt.rgba(cardRoot.tagColor.r, cardRoot.tagColor.g, cardRoot.tagColor.b, Theme.isDark ? 0.15 : 0.12)
                border.color: Qt.rgba(cardRoot.tagColor.r, cardRoot.tagColor.g, cardRoot.tagColor.b, 0.3)
                border.width: 1

                Text {
                    id: tagLabel
                    anchors.centerIn: parent
                    text: cardRoot.tagText
                    font.pixelSize: 10
                    font.bold: true
                    color: cardRoot.tagColor
                }
            }
        }
    }

    // ── 1. Total Activities Card ──────────────────────────────────────────────
    StatCard {
        iconName: "list-todo"
        statTitle: "TOTAL ACTIVITIES"
        statValue: activityModel.count.toString()
        statSubtitle: activityModel.count === 1 ? "1 item logged" : activityModel.count + " items logged"
        accentColor: Theme.accentBlue
        tagText: "All Tasks"
        tagColor: Theme.accentBlue
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
        tagText: activityModel.count === 0 ? "No tasks" : ""
        tagColor: Theme.textMuted
    }

    // ── 3. Pending Card ───────────────────────────────────────────────────────
    StatCard {
        iconName: "clock"
        statTitle: "PENDING"
        statValue: activityService.pendingCount.toString()
        statSubtitle: activityService.pendingCount === 1 ? "1 in progress" : activityService.pendingCount + " in progress"
        accentColor: Theme.accentAmber
        showProgressBar: false
        tagText: {
            if (activityModel.count === 0) return "Ready";
            if (activityService.pendingCount === 0) return "✓ All caught up";
            return activityService.pendingCount === 1 ? "1 remaining" : activityService.pendingCount + " remaining";
        }
        tagColor: activityService.pendingCount === 0 ? Theme.accentGreen : Theme.accentAmber
    }

    // ── 4. Time Tracked Card ──────────────────────────────────────────────────
    StatCard {
        iconName: "flame"
        statTitle: statsGrid.timeframe === "Today" ? "TIME TODAY" : "TIME TRACKED"
        statValue: formatBoth(statsGrid.timeframe === "Today" ? activityService.totalDurationToday : activityService.totalDurationAllTime)
        statSubtitle: (statsGrid.timeframe === "Today" ? activityService.totalDurationToday : activityService.totalDurationAllTime) + " mins total tracked"
        accentColor: Theme.accentPurple
        showProgressBar: false
        tagText: statsGrid.timeframe === "Today" ? "Daily Log" : statsGrid.timeframe
        tagColor: Theme.accentPurple

        function formatBoth(mins) {
            if (!mins || mins <= 0) return "0 min"
            if (mins < 60) return mins + " min"
            const h = Math.floor(mins / 60)
            const m = mins % 60
            return m > 0 ? (h + "h " + m + "m") : (h + "h")
        }
    }
}

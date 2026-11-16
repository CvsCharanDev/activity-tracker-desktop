// ActivityCard.qml — high-contrast modern activity card with light/dark theme support
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Effects
import ActivityTracker 1.0

Rectangle {
    id: card

    // Required properties match the exact C++ ActivityListModel roleNames
    required property string name
    required property string category
    required property int    durationMinutes
    required property bool   done
    required property int    index
    required property var    createdAt
    required property string status
    required property string priority
    required property int    extensionCount
    required property var    scheduledStartTime
    required property var    scheduledEndTime
    required property bool   reminderEnabled
    required property string scheduleStatus
    required property bool   isOverdue

    readonly property string activeStatus: (typeof card.status !== "undefined" && card.status && card.status.length > 0)
                                           ? card.status
                                           : (card.done ? "Done" : "Created")

    readonly property string activePriority: (typeof card.priority !== "undefined" && card.priority && card.priority.length > 0)
                                             ? card.priority
                                             : "Medium"

    signal removeRequested()
    signal completeRequested()
    signal reopenRequested()
    signal statusChangeRequested(string newStatus)
    signal priorityChangeRequested(string newPriority)
    signal extendRequested(int additionalMinutes)
    signal createExtensionRequested(int minutes)
    signal editRequested()

    height: 76
    radius: 10
    color: cardHover.hovered ? Theme.surfaceCardHover : Theme.surfaceCard
    border.color: cardHover.hovered ? (card.done ? Theme.accentGreen : Theme.accentBlue) : Theme.borderDefault
    border.width: 1
    opacity: card.done ? 0.78 : 1.0

    layer.enabled: !Theme.isDark
    layer.effect: MultiEffect {
        shadowEnabled: !Theme.isDark
        shadowColor: "#0A000000"
        shadowBlur: 0.35
        shadowVerticalOffset: 1
    }

    // ── Smooth Hover Lift (Using transform so ListView item.y coordinate is NOT corrupted) ─
    transform: Translate {
        y: cardHover.hovered ? -2 : 0
        Behavior on y { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    }

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    HoverHandler { id: cardHover }

    // Helper: Formats historical timestamps into human-readable labels
    function formatHistoryDate(created) {
        if (!created) return "Today"
        const date = new Date(created)
        if (isNaN(date.getTime())) return "Today"
        const now = new Date()
        const diffMs = now - date
        const diffDays = Math.floor(diffMs / (86400 * 1000))

        if (date.toDateString() === now.toDateString()) {
            const h = date.getHours()
            const m = date.getMinutes()
            const ampm = h >= 12 ? 'PM' : 'AM'
            const h12 = h % 12 || 12
            return "Today, " + h12 + ":" + (m < 10 ? '0' + m : m) + " " + ampm
        } else if (diffDays === 1) {
            return "Yesterday"
        } else if (diffDays < 7) {
            const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            return days[date.getDay()]
        } else {
            const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
            return months[date.getMonth()] + " " + date.getDate()
        }
    }

    // Helper: Formats duration in clean standard format (e.g. 45m or 1h 30m)
    function formatDurationClean(mins) {
        if (!mins || mins <= 0) return "0m"
        if (mins < 60) return mins + "m"
        const h = Math.floor(mins / 60)
        const m = mins % 60
        return m > 0 ? (h + "h " + m + "m") : (h + "h")
    }

    // Helper: Formats scheduled start and end window (e.g. 2:30 PM – 3:30 PM)
    function formatScheduleWindow(startStr, endStr) {
        if (!startStr || startStr.length === 0) return ""
        const s = new Date(startStr)
        if (isNaN(s.getTime())) return ""
        const fmt = (d) => {
            const h = d.getHours() % 12 || 12
            const m = d.getMinutes() < 10 ? '0' + d.getMinutes() : d.getMinutes()
            const ampm = d.getHours() >= 12 ? 'PM' : 'AM'
            return h + ":" + m + " " + ampm
        }
        if (!endStr || endStr.length === 0) return fmt(s)
        const e = new Date(endStr)
        if (isNaN(e.getTime())) return fmt(s)
        return fmt(s) + " – " + fmt(e)
    }

    // Helper: Clean display name (removes ugly legacy "(Extension)" text strings)
    function cleanDisplayName(rawName) {
        if (!rawName) return "(Untitled Activity)"
        return rawName.replace(/(\s*\(Extension\))+$/gi, "").trim()
    }

    // Helper: Returns total extension count from either model or legacy name
    function totalExtensions() {
        const legacyMatches = (card.name || "").match(/\(Extension\)/gi)
        const legacyCount = legacyMatches ? legacyMatches.length : 0
        return Math.max(card.extensionCount || 0, legacyCount)
    }

    // Helper: Priority colors (delegated to centralized Theme)
    function priorityColor(prio) { return Theme.priorityColor(prio) }
    function priorityBg(prio) { return Theme.priorityBg(prio) }
    function priorityBorder(prio) { return Theme.priorityBorder(prio) }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 16
            rightMargin: 16
            topMargin: 8
            bottomMargin: 8
        }
        spacing: 12

        // ── Done / Toggle checkbox ────────────────────────────────────────────
        ShadcnCheckbox {
            id: doneBox
            Layout.alignment: Qt.AlignVCenter
            checked: card.done
            accentColor: Theme.accentGreen
            toolTipText: card.done ? "Reopen" : "Complete"

            onClicked: {
                if (card.done) {
                    card.reopenRequested()
                } else {
                    card.completeRequested()
                }
            }
        }

        // ── Title + Metadata badges ───────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 6

            // Activity Name
            Text {
                Layout.fillWidth: true
                text: card.cleanDisplayName(card.name)
                color: titleHover.hovered ? Theme.accentBlue : (card.done ? Theme.textMuted : Theme.textPrimary)
                font.pixelSize: 13
                font.bold: true
                elide: Text.ElideRight
                font.strikeout: card.done

                HoverHandler { id: titleHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: card.editRequested() }
            }

            // Badges row: Priority pill + Category pill + Duration & Extra Time + Status + Timestamp
            RowLayout {
                spacing: 6

                // Priority Pill (P0, P1, P2, P3)
                Rectangle {
                    id: prioBadge
                    radius: 6
                    implicitWidth: prioRow.implicitWidth + 12
                    implicitHeight: 20
                    color: card.priorityBg(card.activePriority)
                    border.color: prioBadgeHover.hovered ? card.priorityColor(card.activePriority) : card.priorityBorder(card.activePriority)
                    border.width: 1

                    scale: prioBadgeHover.hovered ? 1.05 : 1.0
                    Behavior on scale { NumberAnimation { duration: 120 } }

                    RowLayout {
                        id: prioRow
                        anchors.centerIn: parent
                        spacing: 4

                        Rectangle {
                            implicitWidth: 5
                            implicitHeight: 5
                            radius: 2.5
                            color: card.priorityColor(card.activePriority)
                        }

                        Text {
                            text: Theme.priorityCode(card.activePriority)
                            font.pixelSize: 9
                            font.bold: true
                            color: card.priorityColor(card.activePriority)
                        }
                    }

                    ToolTip.visible: prioBadgeHover.hovered
                    ToolTip.text: Theme.priorityCode(card.activePriority) + " Priority"
                    ToolTip.delay: 350

                    HoverHandler { id: prioBadgeHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: card.editRequested() }
                }

                // Category pill
                Rectangle {
                    radius: 6
                    implicitWidth: catRow.implicitWidth + 14
                    implicitHeight: 20
                    color: {
                        if (card.done) return Theme.accentGreenBg;
                        switch (card.category) {
                        case "Work":     return Theme.accentBlueBg;
                        case "Learning": return Theme.accentAmberBg;
                        case "Personal": return Theme.accentGreenBg;
                        default:         return Theme.surfaceBadge;
                        }
                    }
                    border.color: {
                        if (card.done) return Theme.accentGreenBorder;
                        switch (card.category) {
                        case "Work":     return Theme.accentBlueBorder;
                        case "Learning": return Theme.accentAmberBorder;
                        case "Personal": return Theme.accentGreenBorder;
                        default:         return Theme.borderDefault;
                        }
                    }
                    border.width: 1

                    Row {
                        id: catRow
                        anchors.centerIn: parent
                        spacing: 4

                        LucideIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: {
                                switch (card.category) {
                                case "Work":     return "briefcase";
                                case "Learning": return "book-open";
                                case "Personal": return "user";
                                default:         return "list-todo";
                                }
                            }
                            size: 11
                            color: {
                                if (card.done) return Theme.accentGreen;
                                switch (card.category) {
                                case "Work":     return Theme.accentBlue;
                                case "Learning": return Theme.accentAmber;
                                case "Personal": return Theme.accentGreen;
                                default:         return Theme.textSecondary;
                                }
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: card.category && card.category.length > 0 ? card.category : "General"
                            font.pixelSize: 10
                            font.bold: true
                            color: {
                                if (card.done) return Theme.accentGreen;
                                switch (card.category) {
                                case "Work":     return Theme.accentBlue;
                                case "Learning": return Theme.accentAmber;
                                case "Personal": return Theme.accentGreen;
                                default:         return Theme.textSecondary;
                                }
                            }
                        }
                    }
                }

                // In-Progress Indicator (Only shown if actively in-progress)
                Rectangle {
                    visible: !card.done && card.activeStatus === "In Progress"
                    radius: 6
                    implicitWidth: inProgRow.implicitWidth + 12
                    implicitHeight: 20
                    color: Theme.accentBlueBg
                    border.color: Theme.accentBlueBorder
                    border.width: 1

                    Row {
                        id: inProgRow
                        anchors.centerIn: parent
                        spacing: 4

                        LucideIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: "zap"
                            size: 10
                            color: Theme.accentBlue
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "In Progress"
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.accentBlue
                        }
                    }
                }

                // Overdue Alert Badge (High-priority semantic deadline alert)
                Rectangle {
                    visible: !card.done && card.isOverdue
                    radius: 6
                    implicitWidth: overdueRow.implicitWidth + 12
                    implicitHeight: 20
                    color: Theme.accentRoseBg
                    border.color: Theme.accentRoseBorder
                    border.width: 1

                    Row {
                        id: overdueRow
                        anchors.centerIn: parent
                        spacing: 4

                        LucideIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: "alert-triangle"
                            size: 10
                            color: Theme.accentRose
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Overdue"
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.accentRose
                        }
                    }

                    ToolTip.visible: overdueHov.hovered
                    ToolTip.text: "Task is past its scheduled deadline"
                    ToolTip.delay: 250
                    HoverHandler { id: overdueHov }
                }

                // Scheduled Window Pill (if scheduled)
                Rectangle {
                    visible: card.scheduledStartTime && card.scheduledStartTime.length > 0
                    radius: 6
                    implicitWidth: schedRow.implicitWidth + 12
                    implicitHeight: 20
                    color: Theme.surfaceBadge
                    border.color: Theme.borderDefault
                    border.width: 1

                    Row {
                        id: schedRow
                        anchors.centerIn: parent
                        spacing: 4

                        LucideIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: "calendar"
                            size: 10
                            color: Theme.accentBlue
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: card.formatScheduleWindow(card.scheduledStartTime, card.scheduledEndTime)
                            font.pixelSize: 10
                            color: Theme.textSecondary
                            font.bold: true
                        }
                    }

                    ToolTip.visible: schedHov.hovered
                    ToolTip.text: "Scheduled: " + card.formatScheduleWindow(card.scheduledStartTime, card.scheduledEndTime)
                    ToolTip.delay: 250
                    HoverHandler { id: schedHov }
                }

                // Reminder Bell Icon (if notifications active)
                Rectangle {
                    visible: !card.done && card.reminderEnabled
                    radius: 4
                    implicitWidth: 18
                    implicitHeight: 20
                    color: "transparent"

                    LucideIcon {
                        anchors.centerIn: parent
                        name: "bell"
                        size: 11
                        color: Theme.accentBlue
                    }

                    ToolTip.visible: bellIconHov.hovered
                    ToolTip.text: "Reminder alerts active"
                    ToolTip.delay: 250
                    HoverHandler { id: bellIconHov }
                }

                // Creation Timestamp (Muted)
                Row {
                    visible: !card.scheduledStartTime || card.scheduledStartTime.length === 0
                    spacing: 4
                    LucideIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: "clock"
                        size: 10
                        color: Theme.textMuted
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: card.formatHistoryDate(card.createdAt)
                        font.pixelSize: 10
                        color: Theme.textMuted
                        font.bold: false
                    }
                }
            }
        }

        // ── Dedicated Time & Overtime Telemetry Metric Box (Center-Right) ───
        Rectangle {
            id: timeMetricCard
            Layout.alignment: Qt.AlignVCenter
            radius: 8
            implicitHeight: 44
            implicitWidth: Math.max(90, timeCol.implicitWidth + 24)
            color: card.totalExtensions() > 0 ? (Theme.isDark ? "#241530" : "#FAF5FF") : Theme.surfaceBadge
            border.color: card.totalExtensions() > 0 ? (Theme.isDark ? "#4A1A68" : "#E9D5FF") : Theme.borderDefault
            border.width: 1

            ColumnLayout {
                id: timeCol
                anchors.centerIn: parent
                spacing: 2

                // Top: Prominent Tracked Duration
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 4
                    LucideIcon {
                        name: "clock"
                        size: 11
                        color: card.totalExtensions() > 0 ? Theme.accentPurple : Theme.textSecondary
                    }
                    Text {
                        text: card.formatDurationClean(card.durationMinutes)
                        font.pixelSize: 12
                        font.bold: true
                        color: card.totalExtensions() > 0 ? (Theme.isDark ? "#F3E8FF" : "#6B21A8") : Theme.textPrimary
                    }
                }

                // Bottom: Overtime Telemetry
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    visible: card.totalExtensions() > 0
                    spacing: 3
                    LucideIcon {
                        name: "sparkles"
                        size: 9
                        color: Theme.accentPurple
                    }
                    Text {
                        text: "+" + (card.totalExtensions() * 15) + "m OT"
                        font.pixelSize: 9
                        font.bold: true
                        color: Theme.accentPurple
                    }
                }
            }

            ToolTip.visible: timeHover.hovered
            ToolTip.text: {
                if (card.totalExtensions() > 0) {
                    const extra = card.totalExtensions() * 15
                    const base = Math.max(0, card.durationMinutes - extra)
                    return "Total Tracked: " + card.formatDurationClean(card.durationMinutes) +
                           "\n• Scheduled Base: " + card.formatDurationClean(base) +
                           "\n• Overtime Added: +" + extra + "m (" + card.totalExtensions() + " sessions)"
                }
                return "Tracked Duration: " + card.formatDurationClean(card.durationMinutes)
            }
            ToolTip.delay: 250
            HoverHandler { id: timeHover; cursorShape: Qt.PointingHandCursor }
        }

        // ── Right Actions Deck (Reopen, +15m, Edit, Delete) ───────────────────
        RowLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 6
            opacity: cardHover.hovered || card.done ? 1.0 : (Theme.isDark ? 0.35 : 0.45)
            Behavior on opacity { NumberAnimation { duration: 150 } }

            // Reopen Action Button (Visible when completed)
            Rectangle {
                id: reopenBtn
                visible: card.done
                implicitWidth: 32
                implicitHeight: 32
                radius: 6
                color: reopenHover.hovered ? (Theme.isDark ? "#10281E" : "#DCFCE7") : "transparent"
                border.color: reopenHover.hovered ? Theme.accentGreen : "transparent"
                border.width: 1

                scale: reopenHover.hovered ? 1.1 : 1.0
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                LucideIcon {
                    anchors.centerIn: parent
                    name: "rotate-ccw"
                    size: 14
                    color: Theme.accentGreen
                }

                ToolTip.visible: reopenHover.hovered
                ToolTip.text: "Reopen"
                ToolTip.delay: 350

                HoverHandler { id: reopenHover }
                TapHandler {
                    onTapped: card.reopenRequested()
                }
            }

            // Quick Extension Action (+15m or Follow-up)
            Rectangle {
                id: extBtn
                implicitWidth: card.done ? 32 : 46
                implicitHeight: 32
                radius: 6
                color: extHover.hovered 
                       ? (card.done ? (Theme.isDark ? "#2A1838" : "#F3E8FF") : (Theme.isDark ? "#17263C" : "#EFF6FF"))
                       : (cardHover.hovered ? (Theme.isDark ? "#1B2230" : "#F1F5F9") : "transparent")
                border.color: extHover.hovered 
                              ? (card.done ? Theme.accentPurple : Theme.accentBlue) 
                              : (cardHover.hovered ? Theme.borderDefault : "transparent")
                border.width: 1

                scale: extHover.hovered ? 1.08 : 1.0
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                Row {
                    anchors.centerIn: parent
                    spacing: 3
                    LucideIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: card.done ? "sparkles" : "plus"
                        size: 13
                        color: card.done ? Theme.accentPurple : Theme.accentBlue
                    }
                    Text {
                        visible: !card.done
                        anchors.verticalCenter: parent.verticalCenter
                        text: "15m"
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.accentBlue
                    }
                }

                ToolTip.visible: extHover.hovered
                ToolTip.text: "Add 15m"
                ToolTip.delay: 350

                HoverHandler { id: extHover }
                TapHandler {
                    onTapped: {
                        card.extendRequested(15)
                    }
                }
            }

            // Edit / Details Button (Opens Activity Detail Modal)
            Rectangle {
                id: editBtn
                implicitWidth: 32
                implicitHeight: 32
                radius: 6
                color: editHover.hovered 
                       ? Theme.surfaceCardHover 
                       : (cardHover.hovered ? (Theme.isDark ? "#1B2230" : "#F1F5F9") : "transparent")
                border.color: editHover.hovered ? Theme.accentBlue : "transparent"
                border.width: 1

                scale: editHover.hovered ? 1.08 : 1.0
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                LucideIcon {
                    anchors.centerIn: parent
                    name: "edit-3"
                    size: 13
                    color: editHover.hovered ? Theme.accentBlue : Theme.textMuted
                }

                ToolTip.visible: editHover.hovered
                ToolTip.text: "Edit activity"
                ToolTip.delay: 350

                HoverHandler { id: editHover; cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    onTapped: card.editRequested()
                }
            }

            // Delete Button (Always Red with Framer-like Hover Spring & Rotation)
            Rectangle {
                id: delBtn
                implicitWidth: 32
                implicitHeight: 32
                radius: 6
                color: delHover.hovered 
                       ? (Theme.isDark ? "#3A1418" : "#FEE2E2") 
                       : (cardHover.hovered ? (Theme.isDark ? "#241014" : "#FFF1F2") : "transparent")
                border.color: delHover.hovered 
                              ? Theme.accentRed 
                              : (cardHover.hovered ? Theme.accentRedBorder : "transparent")
                border.width: 1

                // Framer Motion style spring micro-interactions: scale + rotation tilt
                scale: delHover.hovered ? 1.12 : 1.0
                rotation: delHover.hovered ? -8 : 0

                Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }
                Behavior on rotation { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }
                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on border.color { ColorAnimation { duration: 140 } }

                LucideIcon {
                    anchors.centerIn: parent
                    name: "trash-2"
                    size: 14
                    color: Theme.accentRed // Crisp, vibrant red
                }

                ToolTip.visible: delHover.hovered
                ToolTip.text: "Delete"
                ToolTip.delay: 350

                HoverHandler { id: delHover }
                TapHandler {
                    onTapped: card.removeRequested()
                }
            }
        }
    }
}

// ActivityCard.qml — executive Linear-grade desktop activity card with quiet metadata and tactile telemetry
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Effects
import ActivityTracker 1.0

Rectangle {
    id: card

    // Required properties matching C++ ActivityListModel roleNames
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

    height: 72
    radius: 10
    color: cardHover.hovered ? Theme.surfaceCardHover : Theme.surfaceCard
    border.color: cardHover.hovered ? (card.done ? Theme.accentGreen : Theme.accentBlue) : Theme.borderDefault
    border.width: 1
    opacity: card.done ? 0.72 : 1.0

    layer.enabled: !Theme.isDark
    layer.effect: MultiEffect {
        shadowEnabled: !Theme.isDark
        shadowColor: "#08000000"
        shadowBlur: 0.35
        shadowVerticalOffset: 1
    }

    transform: Translate {
        y: cardHover.hovered ? -1.5 : 0
        Behavior on y { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    }

    Behavior on color { ColorAnimation { duration: 140 } }
    Behavior on border.color { ColorAnimation { duration: 140 } }

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

    // Helper: Clean display name (removes legacy "(Extension)" text strings)
    function cleanDisplayName(rawName) {
        if (!rawName) return "(Untitled Activity)"
        return rawName.replace(/(\s*\(Extension\))+$/gi, "").trim()
    }

    // Helper: Returns total extension count
    function totalExtensions() {
        const legacyMatches = (card.name || "").match(/\(Extension\)/gi)
        const legacyCount = legacyMatches ? legacyMatches.length : 0
        return Math.max(card.extensionCount || 0, legacyCount)
    }

    // Live Focus Countdown Calculator
    readonly property int remainingSeconds: {
        const _tick = activityService.currentTimestamp
        if (!card.scheduledEndTime || card.scheduledEndTime.length === 0) return 0
        const endMs = new Date(card.scheduledEndTime).getTime()
        const nowMs = new Date().getTime()
        return Math.floor((endMs - nowMs) / 1000)
    }
    readonly property bool isOverdueTimer: remainingSeconds < 0
    readonly property bool isUrgentCountdown: remainingSeconds >= 0 && remainingSeconds <= 300
    readonly property string liveTimerText: {
        if (!card.scheduledEndTime || card.scheduledEndTime.length === 0) return ""
        const absSec = Math.abs(remainingSeconds)
        const mins = Math.floor(absSec / 60)
        const secs = absSec % 60
        const pad = (n) => n < 10 ? "0" + n : "" + n
        if (isOverdueTimer) {
            return "+" + pad(mins) + ":" + pad(secs) + " OT"
        } else {
            return pad(mins) + ":" + pad(secs) + " left"
        }
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 14
            rightMargin: 14
            topMargin: 8
            bottomMargin: 8
        }
        spacing: 12

        // ── 1. Linear-Style Interactive Status Ring / Checkbox ────────────────
        Rectangle {
            id: statusRing
            implicitWidth: 20
            implicitHeight: 20
            radius: 10
            Layout.alignment: Qt.AlignVCenter

            color: card.done 
                   ? Theme.accentGreen 
                   : (card.activeStatus === "In Progress" ? Theme.accentBlueBg : (statusRingHov.hovered ? Theme.surfaceBadge : "transparent"))
            border.color: card.done 
                          ? Theme.accentGreen 
                          : (card.activeStatus === "In Progress" ? Theme.accentBlue : (statusRingHov.hovered ? Theme.accentBlue : Theme.borderDefault))
            border.width: card.done ? 0 : (card.activeStatus === "In Progress" ? 2 : 1.5)

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            // Checked vector mark when done
            LucideIcon {
                anchors.centerIn: parent
                name: "check"
                size: 11
                color: "#FFFFFF"
                visible: card.done
            }

            // In-Progress inner pulsing dot when active
            Rectangle {
                anchors.centerIn: parent
                width: 7
                height: 7
                radius: 3.5
                color: Theme.accentBlue
                visible: !card.done && card.activeStatus === "In Progress"
            }

            ToolTip.visible: statusRingHov.hovered
            ToolTip.text: card.done ? "Click to Reopen" : (card.activeStatus === "In Progress" ? "In Progress — Click to Mark Done" : "Click to Mark Done")
            ToolTip.delay: 250

            HoverHandler { id: statusRingHov; cursorShape: Qt.PointingHandCursor }
            TapHandler {
                onTapped: {
                    if (card.done) {
                        card.reopenRequested()
                    } else {
                        card.completeRequested()
                    }
                }
            }
        }

        // ── 2. Primary Title + Quiet Metadata Row (Linear Standard) ───────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 4

            // Activity Title
            Text {
                Layout.fillWidth: true
                text: card.cleanDisplayName(card.name)
                color: titleHover.hovered ? Theme.accentBlue : (card.done ? Theme.textMuted : Theme.textPrimary)
                font.pixelSize: 13
                font.bold: true
                elide: Text.ElideRight
                font.strikeout: card.done

                ToolTip.visible: titleHover.hovered && truncated
                ToolTip.text: card.cleanDisplayName(card.name)
                ToolTip.delay: 350

                HoverHandler { id: titleHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: card.editRequested() }
            }

            // Quiet, Borderless Metadata Row (No visual clutter or badge boxes!)
            RowLayout {
                spacing: 7
                Layout.alignment: Qt.AlignVCenter

                // Priority Indicator: Clean vector micro-dot + Code
                RowLayout {
                    spacing: 4
                    Rectangle {
                        implicitWidth: 6
                        implicitHeight: 6
                        radius: 3
                        color: Theme.priorityColor(card.activePriority)
                    }
                    Text {
                        text: Theme.priorityCode(card.activePriority)
                        font.pixelSize: 10
                        font.bold: true
                        color: Theme.priorityColor(card.activePriority)
                    }
                }

                // Subtle separator bullet
                Text {
                    text: "•"
                    font.pixelSize: 10
                    color: Theme.textMuted
                }

                // Category: Subtle icon + Text
                RowLayout {
                    spacing: 4
                    LucideIcon {
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
                            switch (card.category) {
                            case "Work":     return Theme.accentBlue;
                            case "Learning": return Theme.accentAmber;
                            case "Personal": return Theme.accentGreen;
                            default:         return Theme.textSecondary;
                            }
                        }
                    }
                    Text {
                        text: card.category && card.category.length > 0 ? card.category : "General"
                        font.pixelSize: 10
                        font.bold: true
                        color: Theme.textSecondary
                    }
                }

                // Scheduled Window or Timestamp
                Item {
                    visible: (card.scheduledStartTime && card.scheduledStartTime.length > 0) || card.isOverdue
                    implicitWidth: schedMetaRow.implicitWidth
                    implicitHeight: 16

                    RowLayout {
                        id: schedMetaRow
                        spacing: 6

                        Text {
                            text: "•"
                            font.pixelSize: 10
                            color: Theme.textMuted
                        }

                        LucideIcon {
                            name: card.isOverdue ? "alert-triangle" : "calendar"
                            size: 10
                            color: card.isOverdue ? Theme.accentRose : Theme.textMuted
                        }

                        Text {
                            text: {
                                if (card.isOverdue && !card.done) return "Overdue"
                                return card.formatScheduleWindow(card.scheduledStartTime, card.scheduledEndTime)
                            }
                            font.pixelSize: 10
                            font.bold: card.isOverdue
                            color: card.isOverdue ? Theme.accentRose : Theme.textSecondary
                        }
                    }
                }

                // Creation Timestamp (Fallback when no schedule exists)
                Item {
                    visible: !card.scheduledStartTime || card.scheduledStartTime.length === 0
                    implicitWidth: dateMetaRow.implicitWidth
                    implicitHeight: 16

                    RowLayout {
                        id: dateMetaRow
                        spacing: 6

                        Text {
                            text: "•"
                            font.pixelSize: 10
                            color: Theme.textMuted
                        }

                        Text {
                            text: card.formatHistoryDate(card.createdAt)
                            font.pixelSize: 10
                            color: Theme.textMuted
                        }
                    }
                }

                // Reminder Active Bell Icon
                LucideIcon {
                    visible: !card.done && card.reminderEnabled
                    name: "bell"
                    size: 11
                    color: Theme.accentBlue
                }
            }
        }

        // ── 3. Consolidated Single Telemetry Section (No duplicate boxes!) ────
        RowLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 6

            // Live Focus Countdown Pill (Active only when In Progress)
            Rectangle {
                visible: !card.done && card.activeStatus === "In Progress" && card.liveTimerText.length > 0
                radius: 6
                implicitHeight: 26
                implicitWidth: liveTimerRow.implicitWidth + 14
                color: card.isOverdueTimer ? Theme.accentRoseBg : (card.isUrgentCountdown ? Theme.accentAmberBg : Theme.accentBlueBg)
                border.color: card.isOverdueTimer ? Theme.accentRoseBorder : (card.isUrgentCountdown ? Theme.accentAmberBorder : Theme.accentBlueBorder)
                border.width: 1

                RowLayout {
                    id: liveTimerRow
                    anchors.centerIn: parent
                    spacing: 4
                    LucideIcon {
                        name: card.isOverdueTimer ? "alert-triangle" : "zap"
                        size: 10
                        color: card.isOverdueTimer ? Theme.accentRose : (card.isUrgentCountdown ? Theme.accentAmber : Theme.accentBlue)
                    }
                    Text {
                        text: card.liveTimerText
                        font.pixelSize: 10
                        font.bold: true
                        font.family: "Segoe UI, Consolas, monospace"
                        color: card.isOverdueTimer ? Theme.accentRose : (card.isUrgentCountdown ? Theme.accentAmber : Theme.accentBlue)
                    }
                }

                ToolTip.visible: liveTimerHov.hovered
                ToolTip.text: card.isOverdueTimer ? "Session exceeded scheduled time" : "Live focus countdown"
                ToolTip.delay: 250
                HoverHandler { id: liveTimerHov }
            }

            // Primary Tracked Duration Pill
            Rectangle {
                radius: 6
                implicitHeight: 26
                implicitWidth: durPillRow.implicitWidth + 14
                color: card.totalExtensions() > 0 ? (Theme.isDark ? "#241530" : "#FAF5FF") : Theme.surfaceBadge
                border.color: card.totalExtensions() > 0 ? (Theme.isDark ? "#4A1A68" : "#DDD6FE") : Theme.borderDefault
                border.width: 1

                RowLayout {
                    id: durPillRow
                    anchors.centerIn: parent
                    spacing: 4

                    LucideIcon {
                        name: "clock"
                        size: 11
                        color: card.totalExtensions() > 0 ? Theme.accentPurple : Theme.textSecondary
                    }
                    Text {
                        text: card.formatDurationClean(card.durationMinutes)
                        font.pixelSize: 11
                        font.bold: true
                        color: card.totalExtensions() > 0 ? (Theme.isDark ? "#F3E8FF" : "#6B21A8") : Theme.textPrimary
                    }
                }

                ToolTip.visible: durPillHover.hovered
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
                HoverHandler { id: durPillHover; cursorShape: Qt.PointingHandCursor }
            }

            // Overtime Indicator (Only shown if extensions exist)
            Rectangle {
                visible: card.totalExtensions() > 0
                radius: 6
                implicitHeight: 26
                implicitWidth: extPillRow.implicitWidth + 12
                color: Theme.accentPurpleBg
                border.color: Theme.accentPurpleBorder
                border.width: 1

                RowLayout {
                    id: extPillRow
                    anchors.centerIn: parent
                    spacing: 3

                    LucideIcon {
                        name: "sparkles"
                        size: 10
                        color: Theme.accentPurple
                    }
                    Text {
                        text: "+" + (card.totalExtensions() * 15) + "m OT"
                        font.pixelSize: 10
                        font.bold: true
                        color: Theme.accentPurple
                    }
                }

                ToolTip.visible: extPillHover.hovered
                ToolTip.text: "+" + (card.totalExtensions() * 15) + "m overtime added"
                ToolTip.delay: 250
                HoverHandler { id: extPillHover }
            }
        }

        // ── 4. Tactile Action Chips Deck ──────────────────────────────────────
        RowLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 4

            // Reopen Action Chip (Visible when completed)
            Rectangle {
                id: reopenBtn
                visible: card.done
                implicitHeight: 26
                implicitWidth: reopenRow.implicitWidth + 12
                radius: 6
                color: reopenHover.hovered ? Theme.accentGreenBg : Theme.surfaceBadge
                border.color: reopenHover.hovered ? Theme.accentGreen : Theme.borderDefault
                border.width: 1

                RowLayout {
                    id: reopenRow
                    anchors.centerIn: parent
                    spacing: 4
                    LucideIcon {
                        name: "rotate-ccw"
                        size: 11
                        color: Theme.accentGreen
                    }
                    Text {
                        text: "Reopen"
                        font.pixelSize: 10
                        font.bold: true
                        color: Theme.accentGreen
                    }
                }

                ToolTip.visible: reopenHover.hovered
                ToolTip.text: "Reopen task"
                ToolTip.delay: 250

                HoverHandler { id: reopenHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: card.reopenRequested() }
            }

            // Quick Extension Action (+15m or Follow-up)
            Rectangle {
                id: extBtn
                implicitHeight: 26
                implicitWidth: extBtnRow.implicitWidth + 12
                radius: 6
                color: extHover.hovered 
                       ? (card.done ? Theme.accentPurpleBg : Theme.accentBlueBg)
                       : Theme.surfaceBadge
                border.color: extHover.hovered 
                              ? (card.done ? Theme.accentPurple : Theme.accentBlue) 
                              : Theme.borderDefault
                border.width: 1

                RowLayout {
                    id: extBtnRow
                    anchors.centerIn: parent
                    spacing: 3
                    LucideIcon {
                        name: card.done ? "sparkles" : "plus"
                        size: 10
                        color: extHover.hovered
                               ? (card.done ? Theme.accentPurple : Theme.accentBlue)
                               : (card.done ? Theme.accentPurple : Theme.textSecondary)
                    }
                    Text {
                        text: card.done ? "+15m" : "15m"
                        font.pixelSize: 10
                        font.bold: true
                        color: extHover.hovered
                               ? (card.done ? Theme.accentPurple : Theme.accentBlue)
                               : Theme.textSecondary
                    }
                }

                ToolTip.visible: extHover.hovered
                ToolTip.text: card.done ? "Add 15m follow-up" : "Quick extend +15m"
                ToolTip.delay: 250

                HoverHandler { id: extHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: card.extendRequested(15) }
            }

            // Edit / Details Button
            Rectangle {
                id: editBtn
                implicitWidth: 26
                implicitHeight: 26
                radius: 6
                color: editHover.hovered ? Theme.accentBlueBg : Theme.surfaceBadge
                border.color: editHover.hovered ? Theme.accentBlue : Theme.borderDefault
                border.width: 1

                LucideIcon {
                    anchors.centerIn: parent
                    name: "edit-3"
                    size: 11
                    color: editHover.hovered ? Theme.accentBlue : Theme.textSecondary
                }

                ToolTip.visible: editHover.hovered
                ToolTip.text: "Edit task details"
                ToolTip.delay: 250

                HoverHandler { id: editHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: card.editRequested() }
            }

            // Delete Button
            Rectangle {
                id: delBtn
                implicitWidth: 26
                implicitHeight: 26
                radius: 6
                color: delHover.hovered ? Theme.accentRedBg : Theme.surfaceBadge
                border.color: delHover.hovered ? Theme.accentRed : Theme.borderDefault
                border.width: 1

                LucideIcon {
                    anchors.centerIn: parent
                    name: "trash-2"
                    size: 11
                    color: delHover.hovered ? Theme.accentRed : Theme.textMuted
                }

                ToolTip.visible: delHover.hovered
                ToolTip.text: "Delete activity"
                ToolTip.delay: 250

                HoverHandler { id: delHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: card.removeRequested() }
            }
        }
    }
}

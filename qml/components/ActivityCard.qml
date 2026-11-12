// ActivityCard.qml — high-contrast modern activity card with light/dark theme support
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
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
    color: card.done 
           ? (Theme.isDark ? "#0E1C14" : "#F0FDF4")
           : (card.activeStatus === "In Progress"
              ? (cardHover.hovered ? (Theme.isDark ? "#172338" : "#EFF6FF") : (Theme.isDark ? "#131B2A" : "#F8FAFC"))
              : (cardHover.hovered ? Theme.surfaceCardHover : Theme.surfaceCard))

    border.color: card.done 
                  ? Theme.accentGreenBorder
                  : (card.activeStatus === "In Progress"
                     ? (cardHover.hovered ? Theme.accentBlue : (Theme.isDark ? "#1E3A5F" : "#BFDBFE"))
                     : (cardHover.hovered ? Theme.accentBlue : Theme.borderDefault))
    border.width: 1

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

    // Helper: Formats duration in both hours and minutes
    function formatDurationBoth(mins) {
        if (!mins || mins <= 0) return "0 min"
        if (mins < 60) return mins + " min"
        const h = Math.floor(mins / 60)
        const m = mins % 60
        return m > 0 ? (h + "h " + m + "m (" + mins + "m)") : (h + "h (" + mins + "m)")
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

    // Left accent category strip
    Rectangle {
        id: accentStrip
        width: 4
        height: card.height - 20
        radius: 2
        anchors.left: card.left
        anchors.leftMargin: 8
        anchors.verticalCenter: card.verticalCenter
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

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 20
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
            toolTipText: card.done ? "Click to Reopen Task" : "Mark as Completed"

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

            // Activity Name + Extension / Iteration Badge
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: card.cleanDisplayName(card.name)
                    color: titleHover.hovered ? Theme.accentBlue : (card.done ? Theme.textMuted : Theme.textPrimary)
                    font.pixelSize: 14
                    font.bold: true
                    elide: Text.ElideRight
                    font.strikeout: card.done

                    HoverHandler { id: titleHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: card.editRequested() }
                }

                // Executive Extension / Iteration Badge (shown if extended)
                Rectangle {
                    visible: card.totalExtensions() > 0
                    radius: 6
                    implicitWidth: extLabel.implicitWidth + 14
                    implicitHeight: 20
                    color: Theme.accentPurpleBg
                    border.color: Theme.accentPurpleBorder
                    border.width: 1

                    RowLayout {
                        id: extLabel
                        anchors.centerIn: parent
                        spacing: 4

                        LucideIcon {
                            name: "zap"
                            size: 10
                            color: Theme.accentPurple
                        }
                        Text {
                            text: "Ext +" + (card.totalExtensions() * 15) + "m (" + card.totalExtensions() + ")"
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.accentPurple
                        }
                    }

                    ToolTip.visible: extBadgeHover.hovered
                    ToolTip.text: "Activity duration extended by " + (card.totalExtensions() * 15) + " minutes across " + card.totalExtensions() + " logged session(s)"
                    ToolTip.delay: 300

                    HoverHandler { id: extBadgeHover }
                }
            }

            // Badges row: Priority pill + Category pill + Duration pill + Status pill
            RowLayout {
                spacing: 8

                // Priority Pill (Urgent, High, Medium, Low)
                Rectangle {
                    id: prioBadge
                    radius: 6
                    implicitWidth: prioRow.implicitWidth + 14
                    implicitHeight: 22
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
                            implicitWidth: 6
                            implicitHeight: 6
                            radius: 3
                            color: card.priorityColor(card.activePriority)
                        }

                        Text {
                            text: Theme.priorityCode(card.activePriority)
                            font.pixelSize: 10
                            font.bold: true
                            color: card.priorityColor(card.activePriority)
                        }
                    }

                    ToolTip.visible: prioBadgeHover.hovered
                    ToolTip.text: Theme.priorityCode(card.activePriority) + " - Click to edit"
                    ToolTip.delay: 300

                    HoverHandler { id: prioBadgeHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: card.editRequested() }
                }

                // Category pill
                Rectangle {
                    radius: 6
                    implicitWidth: catRow.implicitWidth + 16
                    implicitHeight: 22
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
                        spacing: 5

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
                            size: 12
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
                            font.pixelSize: 11
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

                // Duration pill
                Rectangle {
                    radius: 10
                    implicitWidth: durRow.implicitWidth + 14
                    implicitHeight: 22
                    color: Theme.surfaceBadge
                    border.color: Theme.borderDefault
                    border.width: 1

                    Row {
                        id: durRow
                        anchors.centerIn: parent
                        spacing: 4

                        LucideIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: "clock"
                            size: 12
                            color: Theme.textSecondary
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: card.formatDurationBoth(card.durationMinutes)
                            font.pixelSize: 11
                            color: Theme.textSecondary
                            font.bold: true
                        }
                    }
                }

                // History Date Pill (shows exact historical timeframe: Today, Yesterday, Oct 24)
                Rectangle {
                    radius: 10
                    implicitWidth: historyRow.implicitWidth + 14
                    implicitHeight: 22
                    color: Theme.surfaceBadge
                    border.color: Theme.borderDefault
                    border.width: 1

                    Row {
                        id: historyRow
                        anchors.centerIn: parent
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

                // Status pill (Interactive Lifecycle Badge: Todo / In Progress / Done)
                Rectangle {
                    id: statusBadge
                    radius: 6
                    implicitWidth: statusRow.implicitWidth + 16
                    implicitHeight: 22
                    color: {
                        if (card.done || card.activeStatus === "Done") return Theme.accentGreenBg;
                        if (card.activeStatus === "In Progress") return Theme.accentBlueBg;
                        return Theme.surfaceBadge;
                    }
                    border.color: {
                        if (card.done || card.activeStatus === "Done") return Theme.accentGreenBorder;
                        if (card.activeStatus === "In Progress") return Theme.accentBlueBorder;
                        return Theme.borderDefault;
                    }
                    border.width: 1

                    scale: statusBadgeHover.hovered ? 1.05 : 1.0
                    Behavior on scale { NumberAnimation { duration: 120 } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Row {
                        id: statusRow
                        anchors.centerIn: parent
                        spacing: 4

                        LucideIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: {
                                if (card.done || card.activeStatus === "Done") return "check";
                                if (card.activeStatus === "In Progress") return "zap";
                                return "list-todo";
                            }
                            size: 11
                            color: {
                                if (card.done || card.activeStatus === "Done") return Theme.accentGreen;
                                if (card.activeStatus === "In Progress") return Theme.accentBlue;
                                return Theme.textSecondary;
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: {
                                if (card.done || card.activeStatus === "Done") return "Done";
                                if (card.activeStatus === "In Progress") return "In Progress";
                                return "Todo";
                            }
                            font.pixelSize: 10
                            font.bold: true
                            color: {
                                if (card.done || card.activeStatus === "Done") return Theme.accentGreen;
                                if (card.activeStatus === "In Progress") return Theme.accentBlue;
                                return Theme.textSecondary;
                            }
                        }
                    }

                    HoverHandler { id: statusBadgeHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: card.editRequested() }

                    ToolTip.visible: statusBadgeHover.hovered
                    ToolTip.text: "Click to open activity details and operations"
                    ToolTip.delay: 300
                }
            }
        }

        // ── Right Actions Deck (Reopen, +15m / Extension, Delete) ─────────────
        RowLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 6

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
                ToolTip.text: "Reopen Activity (to In Progress)"
                ToolTip.delay: 300

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
                ToolTip.text: "Extend Duration in-place (+15 min)"
                ToolTip.delay: 300

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
                ToolTip.text: "Open Activity Details & Operations"
                ToolTip.delay: 300

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
                ToolTip.text: "Delete Activity"
                ToolTip.delay: 300

                HoverHandler { id: delHover }
                TapHandler {
                    onTapped: card.removeRequested()
                }
            }
        }
    }
}

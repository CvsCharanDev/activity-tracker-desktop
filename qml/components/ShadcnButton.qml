// ShadcnButton.qml — shadcn/ui Button primitive with variants, sizes, and micro-interactions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ActivityTracker 1.0

Item {
    id: btnRoot

    property string text: ""
    property string iconName: ""
    property int iconSize: 13
    property string variant: "default" // "default" | "secondary" | "outline" | "ghost" | "destructive"
    property string size: "default"    // "sm" | "default" | "lg" | "icon"
    property bool loading: false
    property string toolTipText: ""

    signal clicked()

    opacity: btnRoot.enabled ? 1.0 : 0.5
    Behavior on opacity { NumberAnimation { duration: 120 } }

    implicitHeight: {
        switch (btnRoot.size) {
        case "sm": return 32
        case "lg": return 40
        case "icon": return 32
        default: return 36
        }
    }

    implicitWidth: {
        if (btnRoot.size === "icon") return btnRoot.implicitHeight
        return btnRow.implicitWidth + (btnRoot.size === "sm" ? 20 : 28)
    }

    activeFocusOnTab: true

    Keys.onSpacePressed: (event) => {
        if (!btnRoot.enabled) return
        btnRoot.clicked()
        event.accepted = true
    }
    Keys.onReturnPressed: (event) => {
        if (!btnRoot.enabled) return
        btnRoot.clicked()
        event.accepted = true
    }

    readonly property color baseColor: {
        switch (btnRoot.variant) {
        case "secondary":
            return Theme.surfaceBadge
        case "outline":
        case "ghost":
            return "transparent"
        case "destructive":
            return "#EF4444"
        default:
            return Theme.accentBlue
        }
    }

    readonly property color hoverColor: {
        switch (btnRoot.variant) {
        case "secondary":
            return Theme.surfaceCardHover
        case "outline":
        case "ghost":
            return Theme.surfaceBadge
        case "destructive":
            return "#DC2626"
        default:
            return Qt.darker(Theme.accentBlue, 1.1)
        }
    }

    readonly property color textColor: {
        switch (btnRoot.variant) {
        case "secondary":
            return Theme.textPrimary
        case "outline":
            return btnHover.hovered ? Theme.accentBlue : Theme.textPrimary
        case "ghost":
            return btnHover.hovered ? Theme.accentBlue : Theme.textSecondary
        case "destructive":
        case "default":
        default:
            return "#FFFFFF"
        }
    }

    Rectangle {
        id: bgRect
        anchors.fill: parent
        radius: 6

        color: btnTap.pressed ? Qt.darker(btnRoot.baseColor, 1.15) : (btnHover.hovered ? btnRoot.hoverColor : btnRoot.baseColor)
        border.color: {
            if (btnRoot.variant === "outline" || btnRoot.variant === "secondary") {
                return btnHover.hovered ? Theme.accentBlue : Theme.borderDefault
            }
            return "transparent"
        }
        border.width: (btnRoot.variant === "outline" || btnRoot.variant === "secondary") ? 1 : 0

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        // Focus ring glow (ring-2 ring-ring ring-offset-2)
        Rectangle {
            anchors.fill: parent
            anchors.margins: -3
            radius: 8
            color: "transparent"
            border.color: Theme.accentBlue
            border.width: 1.5
            visible: btnRoot.activeFocus
            opacity: 0.6
        }

        RowLayout {
            id: btnRow
            anchors.centerIn: parent
            spacing: 6

            LucideIcon {
                Layout.alignment: Qt.AlignVCenter
                visible: btnRoot.iconName.length > 0
                name: btnRoot.iconName
                size: btnRoot.iconSize
                color: btnRoot.textColor
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                visible: btnRoot.text.length > 0 && btnRoot.size !== "icon"
                text: btnRoot.text
                font.pixelSize: btnRoot.size === "sm" ? 11 : (btnRoot.size === "lg" ? 13 : 12)
                font.bold: true
                color: btnRoot.textColor
            }
        }

        HoverHandler {
            id: btnHover
            cursorShape: btnRoot.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        }

        ToolTip.visible: btnRoot.toolTipText.length > 0 && btnHover.hovered
        ToolTip.text: btnRoot.toolTipText
        ToolTip.delay: 300

        TapHandler {
            id: btnTap
            enabled: btnRoot.enabled
            onTapped: {
                btnRoot.forceActiveFocus()
                btnRoot.clicked()
            }
        }
    }
}

// ShadcnBadge.qml — shadcn/ui Badge primitive with variants and clean borders
import QtQuick
import QtQuick.Layouts
import ActivityTracker 1.0

Rectangle {
    id: badgeRoot

    property string text: ""
    property string variant: "secondary" // "default" | "secondary" | "destructive" | "outline" | "success" | "warning"
    property color customColor: "transparent"
    property color customTextColor: "transparent"

    implicitHeight: 20
    implicitWidth: badgeRow.implicitWidth + 12
    radius: 6

    color: {
        if (customColor !== "transparent") return customColor
        switch (variant) {
        case "default": return Theme.accentBlue
        case "destructive": return "#FEE2E2"
        case "outline": return "transparent"
        case "success": return Theme.isDark ? "#064E3B" : "#DCFCE7"
        case "warning": return Theme.isDark ? "#78350F" : "#FEF3C7"
        case "secondary":
        default: return Theme.surfaceBadge
        }
    }

    border.color: {
        switch (variant) {
        case "outline": return Theme.borderDefault
        case "destructive": return "#FCA5A5"
        case "success": return Theme.accentGreen
        case "warning": return "#F59E0B"
        default: return Theme.borderDefault
        }
    }
    border.width: 1

    RowLayout {
        id: badgeRow
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: badgeRoot.text
            font.pixelSize: 10
            font.bold: true
            color: {
                if (badgeRoot.customTextColor !== "transparent") return badgeRoot.customTextColor
                switch (badgeRoot.variant) {
                case "default": return "#FFFFFF"
                case "destructive": return "#DC2626"
                case "success": return Theme.accentGreen
                case "warning": return "#D97706"
                case "secondary":
                case "outline":
                default: return Theme.textSecondary
                }
            }
        }
    }
}

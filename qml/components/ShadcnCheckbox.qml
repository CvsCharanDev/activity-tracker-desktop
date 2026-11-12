// ShadcnCheckbox.qml — shadcn/ui inspired crisp vector checkbox primitive
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ActivityTracker 1.0

Item {
    id: checkRoot

    property bool checked: false
    property string text: ""
    property color accentColor: Theme.accentBlue
    property bool checkable: true
    property alias toolTipText: checkToolTip.text

    signal clicked()
    signal toggled(bool isChecked)

    implicitHeight: Math.max(18, labelText.implicitHeight)
    implicitWidth: text.length > 0 ? (18 + 8 + labelText.implicitWidth) : 18

    activeFocusOnTab: true

    Keys.onSpacePressed: (event) => {
        if (!checkRoot.enabled) return
        checkRoot.toggle()
        event.accepted = true
    }
    Keys.onReturnPressed: (event) => {
        if (!checkRoot.enabled) return
        checkRoot.toggle()
        event.accepted = true
    }

    function toggle() {
        if (!checkRoot.enabled) return
        checkRoot.checked = !checkRoot.checked
        checkRoot.toggled(checkRoot.checked)
        checkRoot.clicked()
    }

    RowLayout {
        anchors.fill: parent
        spacing: 8

        // ── 16x16 Checkbox Box ────────────────────────────────────────────────
        Rectangle {
            id: boxRect
            implicitWidth: 16
            implicitHeight: 16
            Layout.alignment: Qt.AlignVCenter
            radius: 4

            color: checkRoot.checked
                   ? checkRoot.accentColor
                   : (checkHover.hovered ? Theme.surfaceBadge : "transparent")

            border.color: checkRoot.checked
                          ? checkRoot.accentColor
                          : (checkHover.hovered ? Theme.textSecondary : Theme.borderDefault)
            border.width: checkRoot.activeFocus ? 2 : 1.5

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            // Focus ring glow (shadcn ring-2 ring-ring ring-offset-2)
            Rectangle {
                anchors.fill: parent
                anchors.margins: -3
                radius: 6
                color: "transparent"
                border.color: checkRoot.accentColor
                border.width: 1.5
                visible: checkRoot.activeFocus
                opacity: 0.6
            }

            // Lucide Check Icon
            LucideIcon {
                id: checkIcon
                anchors.centerIn: parent
                name: "check"
                size: 11
                color: "#FFFFFF"
                visible: checkRoot.checked
                opacity: checkRoot.checked ? 1.0 : 0.0
                scale: checkRoot.checked ? 1.0 : 0.6

                Behavior on opacity { NumberAnimation { duration: 100 } }
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }
            }
        }

        // ── Optional Text Label ───────────────────────────────────────────────
        Text {
            id: labelText
            Layout.alignment: Qt.AlignVCenter
            visible: checkRoot.text.length > 0
            text: checkRoot.text
            font.pixelSize: 12
            color: checkHover.hovered ? Theme.textPrimary : Theme.textSecondary
            elide: Text.ElideRight

            Behavior on color { ColorAnimation { duration: 100 } }
        }
    }

    ToolTip {
        id: checkToolTip
        visible: checkToolTip.text.length > 0 && checkHover.hovered
        delay: 350
        padding: 4
        leftPadding: 8
        rightPadding: 8
        topPadding: 4
        bottomPadding: 4
        contentItem: Text {
            text: checkToolTip.text
            font.pixelSize: 11
            font.weight: Font.Medium
            color: "#F8FAFC"
        }
        background: Rectangle {
            color: Theme.isDark ? "#18181B" : "#0F172A"
            radius: 5
            border.color: Theme.isDark ? "#3F3F46" : "#1E293B"
            border.width: 1
        }
    }

    HoverHandler {
        id: checkHover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        onTapped: {
            checkRoot.forceActiveFocus()
            checkRoot.toggle()
        }
    }
}

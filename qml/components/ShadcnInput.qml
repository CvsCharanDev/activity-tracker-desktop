// ShadcnInput.qml — shadcn/ui Input primitive with clean focus ring, leading/trailing icons, and placeholder
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ActivityTracker 1.0

Item {
    id: inputRoot

    property alias text: textField.text
    property alias placeholderText: placeholderLabel.text
    property string leadingIcon: ""
    property string trailingIcon: ""
    property bool isPassword: false
    property alias readOnly: textField.readOnly
    property int inputHeight: 36
    property int echoMode: isPassword ? (showPassword ? TextInput.Normal : TextInput.Password) : TextInput.Normal

    property bool showPassword: false

    signal accepted()
    signal trailingIconClicked()

    implicitHeight: inputHeight
    implicitWidth: 240

    Rectangle {
        id: bgBox
        anchors.fill: parent
        radius: 6

        color: textField.activeFocus
               ? (Theme.isDark ? "#121A28" : "#F8FAFC")
               : (inputHover.hovered ? Theme.surfaceCardHover : Theme.surfaceInput)

        border.color: textField.activeFocus
                      ? Theme.accentBlue
                      : (inputHover.hovered ? Theme.textMuted : Theme.borderDefault)
        border.width: textField.activeFocus ? 2 : 1

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 8
            spacing: 8

            // Optional Leading Icon
            LucideIcon {
                Layout.alignment: Qt.AlignVCenter
                visible: inputRoot.leadingIcon.length > 0
                name: inputRoot.leadingIcon
                size: 13
                color: textField.activeFocus ? Theme.accentBlue : Theme.textMuted
            }

            // Input Text Field + Floating / Vanishing Placeholder
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Text {
                    id: placeholderLabel
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.textMuted
                    font.pixelSize: 12
                    visible: textField.text.length === 0
                    opacity: textField.activeFocus ? 0.35 : 0.8
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }

                TextField {
                    id: textField
                    anchors.fill: parent
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.textPrimary
                    font.pixelSize: 12
                    echoMode: inputRoot.echoMode
                    selectByMouse: true
                    clip: true
                    background: null
                    placeholderText: ""
                    activeFocusOnTab: true

                    onAccepted: inputRoot.accepted()
                }
            }

            // Password Toggle or Custom Trailing Icon
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                visible: inputRoot.isPassword || (inputRoot.trailingIcon.length > 0)
                implicitWidth: 20
                implicitHeight: 20
                radius: 4
                color: trailHover.hovered ? Theme.surfaceBadge : "transparent"

                LucideIcon {
                    anchors.centerIn: parent
                    name: inputRoot.isPassword ? (inputRoot.showPassword ? "eye-off" : "eye") : inputRoot.trailingIcon
                    size: 13
                    color: Theme.textMuted
                }

                HoverHandler { id: trailHover; cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    onTapped: {
                        if (inputRoot.isPassword) {
                            inputRoot.showPassword = !inputRoot.showPassword
                        } else {
                            inputRoot.trailingIconClicked()
                        }
                    }
                }
            }
        }

        HoverHandler {
            id: inputHover
        }
    }

    function forceActiveFocus() {
        textField.forceActiveFocus()
    }
}

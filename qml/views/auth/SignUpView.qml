// SignUpView.qml — executive registration screen with password strength & Lucide icons
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ActivityTracker 1.0
import "../../components" as Components

Rectangle {
    id: signUpRoot
    color: Theme.bgCanvas

    signal navigateToLogin()

    property int selectedGoalMinutes: 240 // 4 hours default

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ── Left Brand & Hero Pane ────────────────────────────────────────────
        Rectangle {
            Layout.preferredWidth: parent.width > 900 ? 400 : 340
            Layout.fillHeight: true
            color: Theme.isDark ? "#090D16" : "#0F172A"
            border.color: Theme.borderDefault
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 40
                spacing: 24

                RowLayout {
                    spacing: 12
                    Rectangle {
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 44
                        radius: 12
                        color: Theme.accentBlue
                        Components.LucideIcon {
                            anchors.centerIn: parent
                            name: "clock"
                            size: 22
                            color: "#FFFFFF"
                        }
                    }

                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: "CVS Tracker"
                            font.pixelSize: 20
                            font.bold: true
                            color: "#FFFFFF"
                        }
                        Text {
                            text: "Executive Productivity Workstation"
                            font.pixelSize: 11
                            color: "#94A3B8"
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                ColumnLayout {
                    spacing: 12
                    Text {
                        text: "Start logging your productivity today."
                        font.pixelSize: 24
                        font.bold: true
                        color: "#F8FAFC"
                        lineHeight: 1.2
                    }
                    Text {
                        text: "Join professionals tracking high-impact activities with interactive focus timers, real-time analytics, and serverless cloud sync."
                        font.pixelSize: 13
                        color: "#94A3B8"
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }

                Item { Layout.fillHeight: true }

                Text {
                    text: "Your data stays private & securely isolated."
                    color: "#64748B"
                    font.pixelSize: 11
                }
            }
        }

        // ── Right Registration Form Card ──────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.bgCanvas

            Item {
                id: formContainer
                anchors.centerIn: parent
                width: Math.min(parent.width - 60, 420)
                height: formColumn.implicitHeight

                ColumnLayout {
                    id: formColumn
                    anchors.fill: parent
                    spacing: 14

                    // Header
                    ColumnLayout {
                        spacing: 4
                        Text {
                            text: "Create Account"
                            font.pixelSize: 24
                            font.bold: true
                            color: Theme.textPrimary
                        }
                        Text {
                            text: "Set up your profile to sync activities across devices"
                            font.pixelSize: 13
                            color: Theme.textSecondary
                        }
                    }

                    // Error Banner
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: errorRow.implicitHeight + 14
                        radius: 6
                        color: Theme.accentRedBg
                        border.color: Theme.accentRedBorder
                        border.width: 1
                        visible: authService.errorMessage.length > 0

                        RowLayout {
                            id: errorRow
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8
                            Components.LucideIcon { name: "x"; size: 13; color: Theme.accentRed }
                            Text {
                                text: authService.errorMessage
                                color: Theme.accentRed
                                font.pixelSize: 12
                                font.bold: true
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }
                    }

                    // Full Name Field
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Text { text: "Full Name"; color: Theme.textSecondary; font.pixelSize: 12; font.bold: true }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 40
                            radius: 8
                            color: nameInput.activeFocus ? (Theme.isDark ? "#121A28" : "#F8FAFC") : Theme.surfaceInput
                            border.color: nameInput.activeFocus ? Theme.accentBlue : Theme.borderDefault
                            border.width: nameInput.activeFocus ? 2 : 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 8
                                Components.LucideIcon {
                                    name: "user"
                                    size: 13
                                    color: nameInput.activeFocus ? Theme.accentBlue : Theme.textMuted
                                }
                                TextField {
                                    id: nameInput
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: Theme.textPrimary
                                    font.pixelSize: 13
                                    background: null
                                    placeholderText: "e.g. Charan Developer"
                                    placeholderTextColor: Theme.textMuted
                                    selectByMouse: true
                                }
                            }
                        }
                    }

                    // Email Field
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Text { text: "Email Address"; color: Theme.textSecondary; font.pixelSize: 12; font.bold: true }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 40
                            radius: 8
                            color: emailInput.activeFocus ? (Theme.isDark ? "#121A28" : "#F8FAFC") : Theme.surfaceInput
                            border.color: emailInput.activeFocus ? Theme.accentBlue : Theme.borderDefault
                            border.width: emailInput.activeFocus ? 2 : 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 8
                                Components.LucideIcon {
                                    name: "mail"
                                    size: 13
                                    color: emailInput.activeFocus ? Theme.accentBlue : Theme.textMuted
                                }
                                TextField {
                                    id: emailInput
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: Theme.textPrimary
                                    font.pixelSize: 13
                                    background: null
                                    placeholderText: "name@company.com"
                                    placeholderTextColor: Theme.textMuted
                                    selectByMouse: true
                                }
                            }
                        }
                    }

                    // Password Field
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Text { text: "Password"; color: Theme.textSecondary; font.pixelSize: 12; font.bold: true }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 40
                            radius: 8
                            color: passInput.activeFocus ? (Theme.isDark ? "#121A28" : "#F8FAFC") : Theme.surfaceInput
                            border.color: passInput.activeFocus ? Theme.accentBlue : Theme.borderDefault
                            border.width: passInput.activeFocus ? 2 : 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 8
                                Components.LucideIcon {
                                    name: "lock"
                                    size: 13
                                    color: passInput.activeFocus ? Theme.accentBlue : Theme.textMuted
                                }
                                TextField {
                                    id: passInput
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: Theme.textPrimary
                                    font.pixelSize: 13
                                    background: null
                                    placeholderText: "At least 6 characters"
                                    placeholderTextColor: Theme.textMuted
                                    selectByMouse: true
                                    echoMode: TextInput.Password
                                }
                            }
                        }

                        // Password Strength Bar
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            visible: passInput.text.length > 0

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 4
                                radius: 2
                                color: passInput.text.length >= 6 ? Theme.accentAmber : Theme.accentRed
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 4
                                radius: 2
                                color: passInput.text.length >= 8 && /[0-9]/.test(passInput.text) ? Theme.accentGreen : Theme.borderDefault
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 4
                                radius: 2
                                color: passInput.text.length >= 10 && /[^A-Za-z0-9]/.test(passInput.text) ? Theme.accentGreen : Theme.borderDefault
                            }

                            Text {
                                text: passInput.text.length < 6 ? "Weak" : (passInput.text.length < 8 ? "Good" : "Strong")
                                color: passInput.text.length < 6 ? Theme.accentRed : (passInput.text.length < 8 ? Theme.accentAmber : Theme.accentGreen)
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }
                    }

                    // Daily Focus Goal Selector
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Text { text: "Daily Focus Target Goal"; color: Theme.textSecondary; font.pixelSize: 12; font.bold: true }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Repeater {
                                model: [
                                    { label: "2 Hours", mins: 120 },
                                    { label: "4 Hours", mins: 240 },
                                    { label: "6 Hours", mins: 360 },
                                    { label: "8 Hours", mins: 480 }
                                ]
                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: 32
                                    radius: 6
                                    readonly property bool isSelected: signUpRoot.selectedGoalMinutes === modelData.mins

                                    color: isSelected ? Theme.accentBlueBg : (goalHover.hovered ? Theme.surfaceCardHover : Theme.surfaceInput)
                                    border.color: isSelected ? Theme.accentBlue : Theme.borderDefault
                                    border.width: isSelected ? 2 : 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        font.pixelSize: 11
                                        font.bold: parent.isSelected
                                        color: parent.isSelected ? Theme.accentBlue : Theme.textSecondary
                                    }

                                    HoverHandler { id: goalHover }
                                    TapHandler {
                                        onTapped: signUpRoot.selectedGoalMinutes = modelData.mins
                                    }
                                }
                            }
                        }
                    }

                    // Register Button
                    Components.ShadcnButton {
                        id: registerBtn
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        size: "lg"
                        variant: "default"
                        text: "Create Account"

                        onClicked: {
                            authService.registerUser(nameInput.text, emailInput.text, passInput.text, signUpRoot.selectedGoalMinutes);
                        }
                    }

                    // Back to Login Link
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 4
                        spacing: 4

                        Text {
                            text: "Already have an account?"
                            color: Theme.textSecondary
                            font.pixelSize: 12
                        }

                        Text {
                            text: "Sign In"
                            color: Theme.accentBlue
                            font.pixelSize: 12
                            font.bold: true

                            HoverHandler { id: loginLinkHover }
                            TapHandler { onTapped: signUpRoot.navigateToLogin() }
                        }
                    }
                }
            }
        }
    }
}

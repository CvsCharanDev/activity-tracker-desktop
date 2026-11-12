// ForgotPasswordView.qml — executive password recovery screen with Lucide icons
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ActivityTracker 1.0
import "../../components" as Components

Rectangle {
    id: forgotRoot
    color: Theme.bgCanvas

    signal navigateToLogin()

    property bool isSuccess: false

    Connections {
        target: authService
        function onResetPasswordSuccess() {
            forgotRoot.isSuccess = true
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ── Left Brand Pane ───────────────────────────────────────────────────
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
                        text: "Account Security & Recovery."
                        font.pixelSize: 24
                        font.bold: true
                        color: "#F8FAFC"
                        lineHeight: 1.2
                    }
                    Text {
                        text: "Reset your master password securely to regain access to your activities and serverless cloud database."
                        font.pixelSize: 13
                        color: "#94A3B8"
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }

                Item { Layout.fillHeight: true }

                Text {
                    text: "End-to-end encrypted with SHA-256."
                    color: "#64748B"
                    font.pixelSize: 11
                }
            }
        }

        // ── Right Password Reset Form Card ────────────────────────────────────
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
                    spacing: 16

                    // Title
                    ColumnLayout {
                        spacing: 4
                        Text {
                            text: "Reset Password"
                            font.pixelSize: 24
                            font.bold: true
                            color: Theme.textPrimary
                        }
                        Text {
                            text: "Enter your email and choose a new password"
                            font.pixelSize: 13
                            color: Theme.textSecondary
                        }
                    }

                    // Success Banner
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: successRow.implicitHeight + 14
                        radius: 6
                        color: Theme.accentGreenBg
                        border.color: Theme.accentGreenBorder
                        border.width: 1
                        visible: forgotRoot.isSuccess

                        RowLayout {
                            id: successRow
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8
                            Components.LucideIcon { name: "check"; size: 13; color: Theme.accentGreen }
                            Text {
                                text: "Password successfully updated! You can now sign in."
                                color: Theme.accentGreen
                                font.pixelSize: 12
                                font.bold: true
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
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
                        visible: authService.errorMessage.length > 0 && !forgotRoot.isSuccess

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

                    // Registered Email Field
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        Text { text: "Registered Email"; color: Theme.textSecondary; font.pixelSize: 12; font.bold: true }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 44
                            radius: 8
                            color: resetEmail.activeFocus ? (Theme.isDark ? "#121A28" : "#F8FAFC") : Theme.surfaceInput
                            border.color: resetEmail.activeFocus ? Theme.accentBlue : Theme.borderDefault
                            border.width: resetEmail.activeFocus ? 2 : 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 8
                                Components.LucideIcon {
                                    name: "mail"
                                    size: 13
                                    color: resetEmail.activeFocus ? Theme.accentBlue : Theme.textMuted
                                }
                                TextField {
                                    id: resetEmail
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

                    // New Password Field
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        Text { text: "New Password"; color: Theme.textSecondary; font.pixelSize: 12; font.bold: true }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 44
                            radius: 8
                            color: newPass.activeFocus ? (Theme.isDark ? "#121A28" : "#F8FAFC") : Theme.surfaceInput
                            border.color: newPass.activeFocus ? Theme.accentBlue : Theme.borderDefault
                            border.width: newPass.activeFocus ? 2 : 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 8
                                Components.LucideIcon {
                                    name: "lock"
                                    size: 13
                                    color: newPass.activeFocus ? Theme.accentBlue : Theme.textMuted
                                }
                                TextField {
                                    id: newPass
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
                    }

                    // Submit Button
                    Components.ShadcnButton {
                        id: resetBtn
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        size: "lg"
                        variant: "default"
                        text: "Update Password"

                        onClicked: {
                            authService.resetPassword(resetEmail.text, newPass.text);
                        }
                    }

                    // Back to Login Link
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 4
                        spacing: 4

                        Text {
                            text: "Remembered your credentials?"
                            color: Theme.textSecondary
                            font.pixelSize: 12
                        }

                        Text {
                            text: "Back to Sign In"
                            color: Theme.accentBlue
                            font.pixelSize: 12
                            font.bold: true

                            HoverHandler { id: backHover }
                            TapHandler { onTapped: forgotRoot.navigateToLogin() }
                        }
                    }
                }
            }
        }
    }
}

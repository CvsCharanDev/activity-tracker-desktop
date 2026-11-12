// ShadcnSelect.qml — shadcn/ui Select (Dropdown) primitive with clean popover, hover states, and checkmark
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import ActivityTracker 1.0

Item {
    id: selectRoot

    property var model: []
    property int currentIndex: 0
    property string placeholder: "Select an option..."
    property string currentValue: (model && model.length > currentIndex && currentIndex >= 0) ? model[currentIndex] : ""
    property int itemHeight: 32
    property int selectHeight: 32
    property int selectWidth: 150

    signal activated(int index, string value)

    implicitWidth: selectWidth
    implicitHeight: selectHeight

    // ── Select Trigger Button ─────────────────────────────────────────────────
    Rectangle {
        id: triggerBox
        anchors.fill: parent
        radius: 6
        color: selectHover.hovered ? Theme.surfaceCardHover : Theme.surfaceInput
        border.color: popup.visible ? Theme.accentBlue : (selectHover.hovered ? Theme.textMuted : Theme.borderDefault)
        border.width: popup.visible ? 2 : 1

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 8
            spacing: 6

            Text {
                Layout.fillWidth: true
                text: selectRoot.currentValue.length > 0 ? selectRoot.currentValue : selectRoot.placeholder
                font.pixelSize: 12
                font.bold: false
                color: selectRoot.currentValue.length > 0 ? Theme.textPrimary : Theme.textMuted
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            LucideIcon {
                Layout.alignment: Qt.AlignVCenter
                name: "chevron-down"
                size: 13
                color: popup.visible ? Theme.accentBlue : Theme.textMuted
                rotation: popup.visible ? 180 : 0
                Behavior on rotation { NumberAnimation { duration: 150 } }
            }
        }

        HoverHandler {
            id: selectHover
            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            onTapped: {
                if (popup.visible) {
                    popup.close()
                } else {
                    popup.open()
                }
            }
        }
    }

    // ── Floating Select Popover ───────────────────────────────────────────────
    Popup {
        id: popup
        y: triggerBox.height + 4
        width: Math.max(triggerBox.width, 160)
        padding: 4
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

        background: Rectangle {
            radius: 8
            color: Theme.surfaceCard
            border.color: Theme.borderDefault
            border.width: 1

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Theme.isDark ? "#80000000" : "#20000000"
                shadowBlur: 0.8
                shadowVerticalOffset: 4
            }
        }

        contentItem: ListView {
            implicitHeight: Math.min(contentHeight, 220)
            model: selectRoot.model
            clip: true
            spacing: 2

            delegate: Rectangle {
                id: itemDelegate
                width: ListView.view.width
                implicitHeight: selectRoot.itemHeight
                radius: 6

                readonly property bool isSelected: index === selectRoot.currentIndex
                color: isSelected
                       ? Theme.accentBlueBg
                       : (itemHover.hovered ? Theme.surfaceBadge : "transparent")

                Behavior on color { ColorAnimation { duration: 100 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 6

                    // Checkmark indicator for selected item
                    Item {
                        implicitWidth: 14
                        implicitHeight: 14
                        LucideIcon {
                            anchors.centerIn: parent
                            name: "check"
                            size: 12
                            color: Theme.accentBlue
                            visible: itemDelegate.isSelected
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: typeof modelData === "string" ? modelData : (modelData.text || "")
                        font.pixelSize: 12
                        font.bold: itemDelegate.isSelected
                        color: itemDelegate.isSelected
                               ? Theme.accentBlue
                               : (itemHover.hovered ? Theme.textPrimary : Theme.textSecondary)
                        elide: Text.ElideRight
                    }
                }

                HoverHandler {
                    id: itemHover
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: {
                        selectRoot.currentIndex = index
                        selectRoot.activated(index, selectRoot.currentValue)
                        popup.close()
                    }
                }
            }

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }
        }
    }
}

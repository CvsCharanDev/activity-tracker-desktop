// ActivityDetailModal.qml — Executive Activity Details, Operations & Lifecycle Editor
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import ActivityTracker 1.0

Dialog {
    id: detailModal
    title: ""
    modal: true
    anchors.centerIn: parent
    width: Math.min(640, parent.width - 32)
    height: Math.min(620, parent.height - 32)
    padding: 0
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    property int    activityIndex: -1
    property string originalName: ""
    property string currentName: ""
    property string currentCategory: "Work"
    property int    currentDuration: 30
    property string currentStatus: "Created"
    property string currentPriority: "Medium"
    property int    currentExtensionCount: 0
    property string createdAtStr: ""

    // Public method to open modal with a given activity's model properties
    function openForActivity(index) {
        if (index < 0 || index >= activityModel.count) return;
        const item = activityModel.get(index);
        if (!item) return;

        activityIndex = index;
        const rawName = item.name || "";
        originalName = rawName;
        currentName = rawName.replace(/(\s*\(Extension\))+$/gi, "").trim();
        currentCategory = item.category || "Work";
        currentDuration = item.durationMinutes || 30;
        currentStatus = item.status || (item.done ? "Done" : "Created");
        currentPriority = item.priority || "Medium";
        currentExtensionCount = item.extensionCount || 0;

        const date = item.createdAt ? new Date(item.createdAt) : new Date();
        createdAtStr = date.toLocaleString();

        nameEditField.text = currentName;
        detailModal.open();
    }

    background: Rectangle {
        radius: 16
        color: Theme.surfaceCard
        border.color: Theme.borderDefault
        border.width: 1

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Theme.isDark ? "#80000000" : "#25000000"
            shadowBlur: 0.8
            shadowVerticalOffset: 6
        }
    }

    contentItem: ColumnLayout {
        spacing: 0

        // ── Modal Header Bar ──────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            color: Theme.surfaceNav
            radius: 16

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 16
                color: Theme.surfaceNav
            }
            border.color: Theme.borderDefault
            border.width: 1

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: 20
                    rightMargin: 16
                }
                spacing: 10

                LucideIcon {
                    name: "edit-3"
                    size: 18
                    color: Theme.accentBlue
                }

                Text {
                    text: "Activity Operations & Details"
                    font.pixelSize: 15
                    font.bold: true
                    color: Theme.textPrimary
                }

                Item { Layout.fillWidth: true }

                // Close Button (X)
                Rectangle {
                    implicitWidth: 30
                    implicitHeight: 30
                    radius: 15
                    color: closeHover.hovered ? Theme.surfaceBadge : "transparent"

                    LucideIcon {
                        anchors.centerIn: parent
                        name: "x"
                        size: 14
                        color: Theme.textMuted
                    }

                    HoverHandler { id: closeHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: detailModal.close() }
                }
            }
        }

        // ── Scrollable Form Body ──────────────────────────────────────────────
        ScrollView {
            id: modalScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            Item {
                width: modalScroll.availableWidth
                implicitHeight: modalFormCol.implicitHeight + 40

                ColumnLayout {
                    id: modalFormCol
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        leftMargin: 24
                        rightMargin: 24
                        topMargin: 20
                    }
                    spacing: 16

                // ── 1. Activity Name Input ────────────────────────────────────
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "Activity Name"
                        font.pixelSize: 12
                        font.bold: true
                        color: Theme.textSecondary
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 42
                        radius: 8
                        color: nameEditField.activeFocus ? (Theme.isDark ? "#121A28" : "#F8FAFC") : Theme.surfaceInput
                        border.color: nameEditField.activeFocus ? Theme.accentBlue : Theme.borderDefault
                        border.width: nameEditField.activeFocus ? 2 : 1

                        TextField {
                            id: nameEditField
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            verticalAlignment: TextInput.AlignVCenter
                            color: Theme.textPrimary
                            font.pixelSize: 13
                            background: null
                            selectByMouse: true
                            onTextChanged: detailModal.currentName = text
                        }
                    }
                }

                // ── 2. Lifecycle Status Segment ───────────────────────────────
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "Lifecycle Status"
                        font.pixelSize: 12
                        font.bold: true
                        color: Theme.textSecondary
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        // Todo Button
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 36
                            radius: 8
                            readonly property bool isSelected: detailModal.currentStatus === "Created"
                            color: isSelected ? Theme.surfaceBadge : (stTodoHov.hovered ? Theme.surfaceCardHover : Theme.surfaceInput)
                            border.color: isSelected ? Theme.textSecondary : Theme.borderDefault
                            border.width: isSelected ? 2 : 1

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                LucideIcon { name: "list-todo"; size: 13; color: Theme.textSecondary }
                                Text { text: "Todo / Backlog"; font.pixelSize: 12; font.bold: true; color: Theme.textSecondary }
                            }
                            HoverHandler { id: stTodoHov; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: detailModal.currentStatus = "Created" }
                        }

                        // In Progress Button
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 36
                            radius: 8
                            readonly property bool isSelected: detailModal.currentStatus === "In Progress"
                            color: isSelected ? Theme.accentBlueBg : (stInProgHov.hovered ? Theme.surfaceCardHover : Theme.surfaceInput)
                            border.color: isSelected ? Theme.accentBlue : Theme.borderDefault
                            border.width: isSelected ? 2 : 1

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                LucideIcon { name: "zap"; size: 13; color: Theme.accentBlue }
                                Text { text: "In Progress"; font.pixelSize: 12; font.bold: true; color: Theme.accentBlue }
                            }
                            HoverHandler { id: stInProgHov; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: detailModal.currentStatus = "In Progress" }
                        }

                        // Completed Button
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 36
                            radius: 8
                            readonly property bool isSelected: detailModal.currentStatus === "Done"
                            color: isSelected ? Theme.accentGreenBg : (stDoneHov.hovered ? Theme.surfaceCardHover : Theme.surfaceInput)
                            border.color: isSelected ? Theme.accentGreen : Theme.borderDefault
                            border.width: isSelected ? 2 : 1

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                LucideIcon { name: "check"; size: 13; color: Theme.accentGreen }
                                Text { text: "Completed"; font.pixelSize: 12; font.bold: true; color: Theme.accentGreen }
                            }
                            HoverHandler { id: stDoneHov; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: detailModal.currentStatus = "Done" }
                        }
                    }
                }

                // ── 3. Priority Level Segment ─────────────────────────────────
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "Priority Level"
                        font.pixelSize: 12
                        font.bold: true
                        color: Theme.textSecondary
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Repeater {
                            model: [
                                { name: "Urgent", label: "Urgent (P1)" },
                                { name: "High",   label: "High (P2)" },
                                { name: "Medium", label: "Medium (P3)" },
                                { name: "Low",    label: "Low (P4)" }
                            ]

                            delegate: Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 34
                                radius: 8
                                readonly property bool isSelected: detailModal.currentPriority === modelData.name
                                color: isSelected ? Theme.priorityBg(modelData.name) : (prioHov.hovered ? Theme.surfaceCardHover : Theme.surfaceInput)
                                border.color: isSelected ? Theme.priorityColor(modelData.name) : Theme.borderDefault
                                border.width: isSelected ? 2 : 1

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 5
                                    Rectangle { implicitWidth: 6; implicitHeight: 6; radius: 3; color: Theme.priorityColor(modelData.name) }
                                    Text {
                                        text: modelData.label
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: isSelected ? Theme.priorityColor(modelData.name) : Theme.textSecondary
                                    }
                                }
                                HoverHandler { id: prioHov; cursorShape: Qt.PointingHandCursor }
                                TapHandler { onTapped: detailModal.currentPriority = modelData.name }
                            }
                        }
                    }
                }

                // ── 4. Category Segment ───────────────────────────────────────
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "Category"
                        font.pixelSize: 12
                        font.bold: true
                        color: Theme.textSecondary
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Repeater {
                            model: [
                                { name: "Work",     icon: "briefcase", color: Theme.accentBlue,  bg: Theme.accentBlueBg },
                                { name: "Learning", icon: "book-open", color: Theme.accentAmber, bg: Theme.accentAmberBg },
                                { name: "Personal", icon: "user",      color: Theme.accentGreen, bg: Theme.accentGreenBg }
                            ]

                            delegate: Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 34
                                radius: 8
                                readonly property bool isSelected: detailModal.currentCategory === modelData.name
                                color: isSelected ? modelData.bg : (catHov.hovered ? Theme.surfaceCardHover : Theme.surfaceInput)
                                border.color: isSelected ? modelData.color : Theme.borderDefault
                                border.width: isSelected ? 2 : 1

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    LucideIcon { name: modelData.icon; size: 12; color: modelData.color }
                                    Text {
                                        text: modelData.name
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: isSelected ? modelData.color : Theme.textSecondary
                                    }
                                }
                                HoverHandler { id: catHov; cursorShape: Qt.PointingHandCursor }
                                TapHandler { onTapped: detailModal.currentCategory = modelData.name }
                            }
                        }
                    }
                }

                // ── 5. Duration & In-Place Extension Operations ───────────────
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Tracked Duration"
                            font.pixelSize: 12
                            font.bold: true
                            color: Theme.textSecondary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: detailModal.currentDuration + " min (" + (detailModal.currentDuration / 60).toFixed(1) + " hrs)"
                            font.pixelSize: 12
                            font.bold: true
                            color: Theme.accentBlue
                        }
                    }

                    // Stepper + Quick In-Place Extensions
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        // -5m
                        Rectangle {
                            implicitWidth: 44
                            implicitHeight: 32
                            radius: 6
                            color: subHov.hovered ? Theme.surfaceCardHover : Theme.surfaceBadge
                            border.color: Theme.borderDefault; border.width: 1
                            Text { anchors.centerIn: parent; text: "- 5m"; font.pixelSize: 11; font.bold: true; color: Theme.textSecondary }
                            HoverHandler { id: subHov; cursorShape: Qt.PointingHandCursor }
                            TapHandler {
                                onTapped: {
                                    if (detailModal.currentDuration > 5) detailModal.currentDuration -= 5
                                }
                            }
                        }

                        // +5m
                        Rectangle {
                            implicitWidth: 44
                            implicitHeight: 32
                            radius: 6
                            color: addHov.hovered ? Theme.surfaceCardHover : Theme.surfaceBadge
                            border.color: Theme.borderDefault; border.width: 1
                            Text { anchors.centerIn: parent; text: "+ 5m"; font.pixelSize: 11; font.bold: true; color: Theme.textSecondary }
                            HoverHandler { id: addHov; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: detailModal.currentDuration += 5 }
                        }

                        Item { Layout.fillWidth: true }

                        // In-Place Extension Presets
                        Text { text: "Add Extension:"; font.pixelSize: 11; color: Theme.textMuted }

                        Repeater {
                            model: [15, 30, 45, 60]
                            delegate: Rectangle {
                                implicitWidth: 46
                                implicitHeight: 32
                                radius: 6
                                color: extHov.hovered ? Theme.accentBlueBg : Theme.surfaceBadge
                                border.color: extHov.hovered ? Theme.accentBlue : Theme.borderDefault
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: "+" + modelData + "m"
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: extHov.hovered ? Theme.accentBlue : Theme.textSecondary
                                }
                                HoverHandler { id: extHov; cursorShape: Qt.PointingHandCursor }
                                TapHandler {
                                    onTapped: {
                                        detailModal.currentDuration += modelData
                                        detailModal.currentExtensionCount += 1
                                    }
                                }
                            }
                        }
                    }
                }

                // ── 6. Timestamps & Audit Log ─────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 36
                    radius: 8
                    color: Theme.surfaceBadge
                    border.color: Theme.borderDefault
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        LucideIcon { name: "clock"; size: 12; color: Theme.textMuted }
                        Text {
                            text: "Logged at: " + detailModal.createdAtStr
                            font.pixelSize: 11
                            color: Theme.textMuted
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            visible: detailModal.currentExtensionCount > 0
                            text: detailModal.currentExtensionCount + " in-place extension(s)"
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.accentPurple
                        }
                    }
                }
            }
        }
        }

        // ── Modal Footer Action Deck ──────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            color: Theme.surfaceNav
            border.color: Theme.borderDefault
            border.width: 1

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: 20
                    rightMargin: 20
                }
                spacing: 12

                // Delete Button
                ShadcnButton {
                    variant: "destructive"
                    iconName: "trash-2"
                    text: "Delete Task"
                    onClicked: {
                        detailModal.close()
                        if (detailModal.activityIndex >= 0) {
                            activityService.removeActivity(detailModal.activityIndex)
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Cancel Button
                ShadcnButton {
                    variant: "outline"
                    text: "Cancel"
                    onClicked: detailModal.close()
                }

                // Save Changes Button
                ShadcnButton {
                    variant: "default"
                    iconName: "check"
                    text: "Save Changes"
                    onClicked: {
                        detailModal.close()
                        if (detailModal.activityIndex >= 0) {
                            activityService.updateActivity(
                                detailModal.activityIndex,
                                detailModal.currentName,
                                detailModal.currentCategory,
                                detailModal.currentDuration,
                                detailModal.currentStatus,
                                detailModal.currentPriority
                            )
                        }
                    }
                }
            }
        }
    }
}

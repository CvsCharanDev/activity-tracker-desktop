// AddActivityForm.qml — ergonomic, modern input form with custom desktop text fields
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ActivityTracker 1.0

ColumnLayout {
    id: formRoot
    spacing: 16

    property string selectedCategory: "Work"
    property string selectedPriority: "Medium"
    property bool scheduleEnabled: false
    property var startTimeDate: new Date()
    property bool reminderAlertsEnabled: true
    property int selectedPresetIndex: 0
    function focusNameField() { nameField.forceActiveFocus() }

    // ── Activity Name (Custom Desktop Input Field) ─────────────────────────────
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Activity Name"
                color: Theme.textSecondary
                font.pixelSize: 13
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            Text {
                text: nameField.text.length > 0 ? nameField.text.length + " chars" : ""
                color: Theme.textMuted
                font.pixelSize: 11
            }
        }

        // Modern input container with focus halo and zero placeholder overlay
        Rectangle {
            id: inputWrapper
            Layout.fillWidth: true
            implicitHeight: 44
            radius: 8
            color: nameField.activeFocus 
                   ? (Theme.isDark ? "#121A28" : "#F8FAFC") 
                   : Theme.surfaceInput
            border.color: nameField.activeFocus ? Theme.accentBlue : Theme.borderDefault
            border.width: nameField.activeFocus ? 2 : 1

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 10
                spacing: 8

                LucideIcon {
                    name: "plus"
                    size: 13
                    color: nameField.activeFocus ? Theme.accentBlue : Theme.textMuted
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // Custom Smooth Placeholder (vanishes completely when user types; never overlays text)
                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "e.g. Code review, Study Qt/QML..."
                        color: Theme.textMuted
                        font.pixelSize: 13
                        visible: nameField.text.length === 0
                        opacity: nameField.activeFocus ? 0.35 : 0.8
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    TextField {
                        id: nameField
                        anchors.fill: parent
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.textPrimary
                        font.pixelSize: 13
                        font.bold: false
                        selectByMouse: true
                        clip: true
                        background: null
                        placeholderText: "" // Empty so Material style's internal floating label does NOT clash
                        activeFocusOnTab: true
                        KeyNavigation.tab: catWork

                        onAccepted: {
                            if (nameField.text.trim().length > 0) {
                                addBtn.clicked()
                            }
                        }
                    }
                }

                // Clear button (✕)
                Rectangle {
                    visible: nameField.text.length > 0
                    implicitWidth: 20
                    implicitHeight: 20
                    radius: 10
                    color: clearNameHover.hovered ? Theme.surfaceCardHover : "transparent"

                    LucideIcon {
                        anchors.centerIn: parent
                        name: "x"
                        size: 11
                        color: Theme.textMuted
                    }

                    HoverHandler { id: clearNameHover }
                    TapHandler {
                        onTapped: {
                            nameField.text = ""
                            nameField.forceActiveFocus()
                        }
                    }
                }

                // Enter key shortcut hint
                Rectangle {
                    visible: nameField.text.trim().length > 0
                    radius: 4
                    implicitWidth: 22
                    implicitHeight: 20
                    color: Theme.accentBlueBg
                    border.color: Theme.accentBlueBorder
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "↵"
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.accentBlue
                    }
                }
            }
        }
    }

    // ── Category (Interactive Visual Selector Cards) ──────────────────────────
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6

        Text {
            text: "Category"
            color: Theme.textSecondary
            font.pixelSize: 13
            font.bold: true
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Work
            Rectangle {
                id: catWork
                Layout.fillWidth: true
                implicitHeight: 38
                radius: 8
                readonly property bool isSelected: formRoot.selectedCategory === "Work"
                activeFocusOnTab: true
                KeyNavigation.tab: durationSpinBox
                Keys.onRightPressed: formRoot.selectedCategory = "Learning"

                color: isSelected 
                       ? Theme.accentBlueBg 
                       : (workHover.hovered || catWork.activeFocus ? Theme.surfaceCardHover : Theme.surfaceInput)
                border.color: isSelected ? Theme.accentBlue : (catWork.activeFocus ? Theme.accentBlue : Theme.borderDefault)
                border.width: 1

                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }

                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    LucideIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: "briefcase"
                        size: 12
                        color: catWork.isSelected ? Theme.accentBlue : Theme.textPrimary
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Work"
                        font.pixelSize: 12
                        font.bold: catWork.isSelected
                        color: catWork.isSelected ? Theme.accentBlue : Theme.textPrimary
                    }
                }

                HoverHandler { id: workHover }
                TapHandler { onTapped: formRoot.selectedCategory = "Work" }
            }

            // Learning
            Rectangle {
                id: catLearn
                Layout.fillWidth: true
                implicitHeight: 38
                radius: 8
                readonly property bool isSelected: formRoot.selectedCategory === "Learning"
                activeFocusOnTab: true
                KeyNavigation.tab: durationSpinBox
                Keys.onLeftPressed: formRoot.selectedCategory = "Work"
                Keys.onRightPressed: formRoot.selectedCategory = "Personal"

                color: isSelected 
                       ? Theme.accentAmberBg 
                       : (learnHover.hovered || catLearn.activeFocus ? Theme.surfaceCardHover : Theme.surfaceInput)
                border.color: isSelected ? Theme.accentAmber : (catLearn.activeFocus ? Theme.accentAmber : Theme.borderDefault)
                border.width: 1

                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }

                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    LucideIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: "book-open"
                        size: 12
                        color: catLearn.isSelected ? Theme.accentAmber : Theme.textPrimary
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Learning"
                        font.pixelSize: 12
                        font.bold: catLearn.isSelected
                        color: catLearn.isSelected ? Theme.accentAmber : Theme.textPrimary
                    }
                }

                HoverHandler { id: learnHover }
                TapHandler { onTapped: formRoot.selectedCategory = "Learning" }
            }

            // Personal
            Rectangle {
                id: catPers
                Layout.fillWidth: true
                implicitHeight: 38
                radius: 8
                readonly property bool isSelected: formRoot.selectedCategory === "Personal"
                activeFocusOnTab: true
                KeyNavigation.tab: durationSpinBox
                Keys.onLeftPressed: formRoot.selectedCategory = "Learning"

                color: isSelected 
                       ? Theme.accentGreenBg 
                       : (persHover.hovered || catPers.activeFocus ? Theme.surfaceCardHover : Theme.surfaceInput)
                border.color: isSelected ? Theme.accentGreen : (catPers.activeFocus ? Theme.accentGreen : Theme.borderDefault)
                border.width: 1

                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }

                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    LucideIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: "user"
                        size: 12
                        color: catPers.isSelected ? Theme.accentGreen : Theme.textPrimary
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Personal"
                        font.pixelSize: 12
                        font.bold: catPers.isSelected
                        color: catPers.isSelected ? Theme.accentGreen : Theme.textPrimary
                    }
                }

                HoverHandler { id: persHover }
                TapHandler { onTapped: formRoot.selectedCategory = "Personal" }
            }
        }
    }

    // ── Priority Selector (Executive P1-P4 Segment) ───────────────────────────
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Priority"
                color: Theme.textSecondary
                font.pixelSize: 13
                font.bold: true
            }
            Item { Layout.fillWidth: true }
            Text {
                text: Theme.priorityCode(formRoot.selectedPriority)
                color: formRoot.selectedPriority === "Urgent" ? Theme.accentRed :
                       (formRoot.selectedPriority === "High" ? Theme.accentAmber :
                       (formRoot.selectedPriority === "Medium" ? Theme.accentBlue : Theme.textMuted))
                font.pixelSize: 11
                font.bold: true
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: ["Urgent", "High", "Medium", "Low"]

                delegate: Rectangle {
                    id: prioPill
                    Layout.fillWidth: true
                    implicitHeight: 32
                    radius: 6
                    readonly property bool isSelected: formRoot.selectedPriority === modelData

                    color: isSelected 
                           ? Theme.priorityBg(modelData) 
                           : (prioHover.hovered ? Theme.surfaceCardHover : Theme.surfaceInput)
                    border.color: isSelected ? Theme.priorityColor(modelData) : Theme.borderDefault
                    border.width: isSelected ? 1.5 : 1

                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 5

                        Rectangle {
                            implicitWidth: 6
                            implicitHeight: 6
                            radius: 3
                            color: Theme.priorityColor(modelData)
                        }

                        Text {
                            text: Theme.priorityCode(modelData)
                            font.pixelSize: 11
                            font.bold: prioPill.isSelected
                            color: prioPill.isSelected ? Theme.priorityColor(modelData) : Theme.textSecondary
                        }
                    }

                    ToolTip.visible: prioHover.hovered
                    ToolTip.text: Theme.priorityCode(modelData) + " (" + modelData + ")"
                    ToolTip.delay: 250

                    HoverHandler { id: prioHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: formRoot.selectedPriority = modelData }
                }
            }
        }
    }

    // ── Duration with 1-Click Quick Pills & Stepper ────────────────────────────
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Duration"
                color: Theme.textSecondary
                font.pixelSize: 13
                font.bold: true
            }
            Item { Layout.fillWidth: true }
            Text {
                text: durationSpinBox.value + " min  (" + (durationSpinBox.value / 60).toFixed(1) + " hrs)"
                color: Theme.accentBlue
                font.pixelSize: 12
                font.bold: true
            }
        }

        // Quick Preset Pills: 15m, 30m, 45m, 60m, 90m
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: [15, 30, 45, 60, 90]
                delegate: Rectangle {
                    id: pill
                    Layout.fillWidth: true
                    implicitHeight: 30
                    radius: 6
                    readonly property bool isSelected: durationSpinBox.value === modelData
                    color: isSelected ? Theme.accentBlueBg : (pillHover.hovered ? Theme.surfaceCardHover : Theme.surfaceInput)
                    border.color: isSelected ? Theme.accentBlue : Theme.borderDefault
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: modelData + "m"
                        font.pixelSize: 12
                        font.bold: pill.isSelected
                        color: pill.isSelected ? Theme.accentBlue : Theme.textSecondary
                    }

                    HoverHandler { id: pillHover }
                    TapHandler {
                        onTapped: durationSpinBox.value = modelData
                    }
                }
            }
        }

        // Fine-tuning Stepper with [-] and [+] Buttons
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Decrement Button
            Rectangle {
                implicitWidth: 42
                implicitHeight: 38
                radius: 6
                color: decHover.hovered ? Theme.surfaceCardHover : Theme.surfaceInput
                border.color: Theme.borderDefault
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "− 5m"
                    font.pixelSize: 12
                    font.bold: true
                    color: Theme.textPrimary
                }

                HoverHandler { id: decHover }
                TapHandler {
                    onTapped: {
                        if (durationSpinBox.value >= 10) durationSpinBox.value -= 5
                    }
                }
            }

            // Central SpinBox display
            SpinBox {
                id: durationSpinBox
                Layout.fillWidth: true
                implicitHeight: 38
                from: 5
                to: 480
                value: 30
                stepSize: 5
                editable: true
                font.pixelSize: 13
                activeFocusOnTab: true
                KeyNavigation.tab: addBtn

                contentItem: TextInput {
                    text: durationSpinBox.value.toString()
                    font: durationSpinBox.font
                    color: Theme.textPrimary
                    horizontalAlignment: TextInput.AlignHCenter
                    verticalAlignment: Qt.AlignVCenter
                    readOnly: !durationSpinBox.editable
                    validator: durationSpinBox.validator
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                }

                background: Rectangle {
                    radius: 6
                    color: Theme.surfaceInput
                    border.color: durationSpinBox.activeFocus ? Theme.accentBlue : Theme.borderDefault
                    border.width: durationSpinBox.activeFocus ? 2 : 1
                }
            }

            // Increment Button
            Rectangle {
                implicitWidth: 42
                implicitHeight: 38
                radius: 6
                color: incHover.hovered ? Theme.surfaceCardHover : Theme.surfaceInput
                border.color: Theme.borderDefault
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "+ 5m"
                    font.pixelSize: 12
                    font.bold: true
                    color: Theme.textPrimary
                }

                HoverHandler { id: incHover }
                TapHandler {
                    onTapped: {
                        if (durationSpinBox.value <= 475) durationSpinBox.value += 5
                    }
                }
            }
        }
    }

    // ── Scheduling & Notification Alerts (Phase 4) ───────────────────────────
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Row {
                spacing: 6
                LucideIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: "calendar"
                    size: 13
                    color: formRoot.scheduleEnabled ? Theme.accentBlue : Theme.textSecondary
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Schedule & Alerts"
                    color: formRoot.scheduleEnabled ? Theme.accentBlue : Theme.textSecondary
                    font.pixelSize: 13
                    font.bold: true
                }
            }

            Item { Layout.fillWidth: true }

            // Switch toggle
            Rectangle {
                implicitWidth: 36
                implicitHeight: 20
                radius: 10
                color: formRoot.scheduleEnabled ? Theme.accentBlue : Theme.surfaceBadge
                border.color: Theme.borderDefault
                border.width: 1

                Behavior on color { ColorAnimation { duration: 120 } }

                Rectangle {
                    width: 14
                    height: 14
                    radius: 7
                    anchors.verticalCenter: parent.verticalCenter
                    x: formRoot.scheduleEnabled ? parent.width - width - 3 : 3
                    color: "#FFFFFF"
                    Behavior on x { NumberAnimation { duration: 120 } }
                }

                HoverHandler { id: schedToggleHov; cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    onTapped: {
                        formRoot.scheduleEnabled = !formRoot.scheduleEnabled
                        if (formRoot.scheduleEnabled) {
                            formRoot.startTimeDate = new Date()
                        }
                    }
                }
            }
        }

        // Expanded scheduling controls
        ColumnLayout {
            Layout.fillWidth: true
            visible: formRoot.scheduleEnabled
            spacing: 8

            // Quick Start Time presets: Now, +5m, +15m, +30m, Tomorrow
            RowLayout {
                Layout.fillWidth: true
                spacing: 5

                Repeater {
                    model: [
                        { label: "Now", offsetMinutes: 0 },
                        { label: "+5m", offsetMinutes: 5 },
                        { label: "+15m", offsetMinutes: 15 },
                        { label: "+30m", offsetMinutes: 30 },
                        { label: "Tomorrow", offsetMinutes: 1440 }
                    ]

                    delegate: Rectangle {
                        id: schedPresetPill
                        Layout.fillWidth: true
                        implicitHeight: 26
                        radius: 5
                        color: formRoot.selectedPresetIndex === index
                               ? Theme.accentBlueBg
                               : (schedPreHov.hovered ? Theme.surfaceCardHover : Theme.surfaceInput)
                        border.color: formRoot.selectedPresetIndex === index
                                      ? Theme.accentBlue
                                      : Theme.borderDefault
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            font.pixelSize: 11
                            font.bold: formRoot.selectedPresetIndex === index
                            color: formRoot.selectedPresetIndex === index
                                   ? Theme.accentBlue
                                   : Theme.textSecondary
                        }

                        HoverHandler { id: schedPreHov; cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            onTapped: {
                                formRoot.selectedPresetIndex = index
                                const now = new Date()
                                formRoot.startTimeDate = new Date(now.getTime() + modelData.offsetMinutes * 60000)
                            }
                        }
                    }
                }
            }

            // Scheduled Window summary pill
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 34
                radius: 6
                color: Theme.surfaceBadge
                border.color: Theme.borderDefault
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    LucideIcon {
                        name: "clock"
                        size: 11
                        color: Theme.accentBlue
                    }

                    Text {
                        Layout.fillWidth: true
                        text: {
                            const start = formRoot.startTimeDate
                            const end = new Date(start.getTime() + durationSpinBox.value * 60000)
                            const fmt = (d) => {
                                const h = d.getHours() % 12 || 12
                                const m = d.getMinutes() < 10 ? '0' + d.getMinutes() : d.getMinutes()
                                const ampm = d.getHours() >= 12 ? 'PM' : 'AM'
                                return h + ":" + m + " " + ampm
                            }
                            return fmt(start) + " → " + fmt(end)
                        }
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.textPrimary
                    }
                }
            }

            // Audio Alert Toggle & Preview Chime
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Toggle Alert ON / OFF pill
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 30
                    radius: 6
                    color: formRoot.reminderAlertsEnabled ? Theme.accentBlueBg : Theme.surfaceInput
                    border.color: formRoot.reminderAlertsEnabled ? Theme.accentBlue : Theme.borderDefault
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        LucideIcon {
                            name: "bell"
                            size: 13
                            color: formRoot.reminderAlertsEnabled ? Theme.accentBlue : Theme.textMuted
                        }
                        Text {
                            text: formRoot.reminderAlertsEnabled ? "Sound Alert: ON" : "Sound Alert: OFF"
                            font.pixelSize: 11
                            font.bold: true
                            color: formRoot.reminderAlertsEnabled ? Theme.accentBlue : Theme.textMuted
                        }
                    }

                    HoverHandler { id: soundTogHov; cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        onTapped: {
                            formRoot.reminderAlertsEnabled = !formRoot.reminderAlertsEnabled
                            if (formRoot.reminderAlertsEnabled) {
                                activityService.playAlertSound()
                            }
                        }
                    }
                }

                // Test Chime Button
                Rectangle {
                    implicitWidth: 62
                    implicitHeight: 30
                    radius: 6
                    color: testSoundHov.hovered ? Theme.surfaceCardHover : Theme.surfaceBadge
                    border.color: Theme.borderDefault
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        LucideIcon { name: "zap"; size: 11; color: Theme.accentPurple }
                        Text { text: "Test"; font.pixelSize: 11; font.bold: true; color: Theme.textSecondary }
                    }

                    ToolTip.visible: testSoundHov.hovered
                    ToolTip.text: "Preview alert sound chime"
                    ToolTip.delay: 200
                    HoverHandler { id: testSoundHov; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: activityService.playAlertSound() }
                }
            }
        }
    }

    // ── Add Button ────────────────────────────────────────────────────────────
    ShadcnButton {
        id: addBtn
        Layout.fillWidth: true
        Layout.topMargin: 4
        size: "lg"
        variant: "default"
        iconName: "plus"
        text: "Log Activity"
        enabled: nameField.text.trim().length > 0
        activeFocusOnTab: true
        KeyNavigation.tab: nameField

        onClicked: {
            if (formRoot.scheduleEnabled) {
                const start = formRoot.startTimeDate
                const end = new Date(start.getTime() + durationSpinBox.value * 60000)
                activityService.addActivityWithSchedule(
                    nameField.text.trim(),
                    formRoot.selectedCategory,
                    durationSpinBox.value,
                    formRoot.selectedPriority,
                    start.toISOString(),
                    end.toISOString(),
                    formRoot.reminderAlertsEnabled
                )
            } else {
                activityService.addActivity(
                    nameField.text.trim(),
                    formRoot.selectedCategory,
                    durationSpinBox.value,
                    formRoot.selectedPriority
                )
            }
            nameField.text = ""
            nameField.forceActiveFocus()
        }
    }

    // ── Daily Focus Target & Productivity Card (Fills Sidebar purposeful space) ──
    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 8
        implicitHeight: 110
        radius: 8
        color: Theme.surfaceCard
        border.color: Theme.borderDefault
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "DAILY FOCUS TARGET"
                    font.pixelSize: 10
                    font.bold: true
                    color: Theme.textSecondary
                    font.letterSpacing: 0.5
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    radius: 4
                    implicitHeight: 16
                    implicitWidth: streakText.implicitWidth + 8
                    color: Theme.accentAmberBg
                    border.color: Theme.accentAmberBorder
                    border.width: 1
                    Text {
                        id: streakText
                        anchors.centerIn: parent
                        text: "🔥 3-Day Streak"
                        font.pixelSize: 9
                        font.bold: true
                        color: Theme.accentAmber
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: activityService.totalDurationToday + "m / " + (authService.dailyGoalMinutes || 240) + "m"
                    font.pixelSize: 14
                    font.bold: true
                    color: Theme.textPrimary
                }
                Item { Layout.fillWidth: true }
                Text {
                    readonly property real ratio: Math.min(1.0, activityService.totalDurationToday / (authService.dailyGoalMinutes || 240))
                    text: Math.round(ratio * 100) + "%"
                    font.pixelSize: 12
                    font.bold: true
                    color: Theme.accentGreen
                }
            }

            // Progress bar
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 6
                radius: 3
                color: Theme.surfaceBadge

                Rectangle {
                    height: parent.height
                    width: parent.width * Math.max(0.0, Math.min(1.0, activityService.totalDurationToday / (authService.dailyGoalMinutes || 240)))
                    radius: 3
                    color: Theme.accentGreen
                    Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                }
            }

            Text {
                text: activityService.totalDurationToday >= (authService.dailyGoalMinutes || 240)
                      ? "🎉 Daily focus goal achieved!"
                      : ((authService.dailyGoalMinutes || 240) - activityService.totalDurationToday) + " mins remaining to hit goal"
                font.pixelSize: 10
                color: Theme.textMuted
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }

    // Bottom filler spacer
    Item { Layout.fillHeight: true }
}

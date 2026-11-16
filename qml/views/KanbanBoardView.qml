// KanbanBoardView.qml — Executive 3-Column Kanban Board with floating unclipped drag proxy, true reactive column counts, and column empty states
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import ActivityTracker 1.0
import "../components" as Components

Item {
    id: kanbanRoot

    property string filterCategory: "All"
    property string filterPriority: "All"
    property string filterText: ""
    property string filterTimeframe: "All Time"

    signal editRequested(int index)
    signal addRequested()

    // Reactive model mutation version counter — forces recalculation when activities update
    property int modelVersion: 0

    Connections {
        target: activityService
        function onStatsChanged() { kanbanRoot.modelVersion++ }
        function onTotalDurationTodayChanged() { kanbanRoot.modelVersion++ }
        function onDataRefreshed() { kanbanRoot.modelVersion++ }
    }

    Connections {
        target: activityModel
        function onDataChanged() { kanbanRoot.modelVersion++ }
        function onRowsInserted() { kanbanRoot.modelVersion++ }
        function onRowsRemoved() { kanbanRoot.modelVersion++ }
        function onModelReset() { kanbanRoot.modelVersion++ }
    }

    // Helper: Formats duration in both hours and minutes
    function formatDurationBoth(mins) {
        if (!mins || mins <= 0) return "0m"
        if (mins < 60) return mins + "m"
        const h = Math.floor(mins / 60)
        const m = mins % 60
        return m > 0 ? (h + "h " + m + "m") : (h + "h")
    }

    RowLayout {
        anchors.fill: parent
        spacing: 14

        // ── Column 1: TODO (Created) ──────────────────────────────────────────
        KanbanColumn {
            id: colTodo
            Layout.fillWidth: true
            Layout.fillHeight: true
            columnTitle: "Todo / Backlog"
            columnStatus: "Created"
            statusColor: Theme.textMuted
            iconName: "list-todo"
            canAdd: true
        }

        // ── Column 2: IN PROGRESS ─────────────────────────────────────────────
        KanbanColumn {
            id: colInProgress
            Layout.fillWidth: true
            Layout.fillHeight: true
            columnTitle: "In Progress"
            columnStatus: "In Progress"
            statusColor: Theme.accentBlue
            iconName: "zap"
        }

        // ── Column 3: COMPLETED ───────────────────────────────────────────────
        KanbanColumn {
            id: colDone
            Layout.fillWidth: true
            Layout.fillHeight: true
            columnTitle: "Completed"
            columnStatus: "Done"
            statusColor: Theme.accentGreen
            iconName: "check"
        }
    }

    // ── Floating Drag Proxy (Floats above all columns, unclipped, z: 99999) ───
    Rectangle {
        id: dragProxy
        visible: false
        z: 99999
        width: 280
        height: 96
        radius: 10
        color: Theme.isDark ? "#1A253D" : "#EFF6FF"
        border.color: Theme.accentBlue
        border.width: 2
        opacity: 0.96

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Theme.isDark ? "#90000000" : "#30000000"
            shadowBlur: 0.9
            shadowVerticalOffset: 8
        }

        Drag.active: visible
        Drag.source: currentItemRoot
        Drag.keys: ["activity-card"]

        property var currentItemRoot: null
        property string titleText: ""
        property string categoryText: ""
        property string priorityText: "Medium"
        property string durationText: "0m"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    Layout.fillWidth: true
                    text: dragProxy.titleText
                    font.pixelSize: 12
                    font.bold: true
                    color: Theme.textPrimary
                    elide: Text.ElideRight
                }

                Rectangle {
                    radius: 4
                    implicitWidth: dragPrioTxt.implicitWidth + 12
                    implicitHeight: 18
                    color: Theme.priorityBg(dragProxy.priorityText)
                    border.color: Theme.priorityBorder(dragProxy.priorityText)
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 3
                        Rectangle {
                            implicitWidth: 5
                            implicitHeight: 5
                            radius: 2.5
                            color: Theme.priorityColor(dragProxy.priorityText)
                        }
                        Text {
                            id: dragPrioTxt
                            text: Theme.priorityCode(dragProxy.priorityText)
                            font.pixelSize: 9
                            font.bold: true
                            color: Theme.priorityColor(dragProxy.priorityText)
                        }
                    }
                }

                Rectangle {
                    radius: 6
                    implicitWidth: catDragLbl.implicitWidth + 10
                    implicitHeight: 18
                    color: Theme.surfaceBadge
                    border.color: Theme.borderDefault
                    border.width: 1
                    Text {
                        id: catDragLbl
                        anchors.centerIn: parent
                        text: dragProxy.categoryText
                        font.pixelSize: 9
                        font.bold: true
                        color: Theme.textSecondary
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Components.LucideIcon { name: "clock"; size: 10; color: Theme.accentBlue }
                Text {
                    text: dragProxy.durationText
                    font.pixelSize: 10
                    font.bold: true
                    color: Theme.textSecondary
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "Moving task..."
                    font.pixelSize: 10
                    font.bold: true
                    color: Theme.accentBlue
                }
            }
        }
    }

    // ── Reusable Kanban Column Component ──────────────────────────────────────
    component KanbanColumn: Rectangle {
        id: colRoot
        required property string columnTitle
        required property string columnStatus
        required property color  statusColor
        required property string iconName
        property bool canAdd: false

        radius: 12
        color: colDropArea.containsDrag ? Theme.surfaceCardHover : (Theme.isDark ? "#121215" : "#F1F5F9")
        border.color: colDropArea.containsDrag ? statusColor : Theme.borderDefault
        border.width: colDropArea.containsDrag ? 2 : 1

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        // Reactive Column Count Calculator
        function getColumnCount() {
            const _trigger = kanbanRoot.modelVersion; // subscribes to live model changes!
            let count = 0;
            for (let i = 0; i < activityModel.count; ++i) {
                const item = activityModel.get(i);
                if (!item) continue;
                const itemStatus = (item.status && item.status.length > 0) ? item.status : (item.done ? "Done" : "Created");
                let matchesStatus = false;
                if (colRoot.columnStatus === "Done") matchesStatus = item.done;
                else if (colRoot.columnStatus === "In Progress") matchesStatus = (!item.done && itemStatus === "In Progress");
                else matchesStatus = (!item.done && itemStatus !== "In Progress");

                if (!matchesStatus) continue;

                if (kanbanRoot.filterCategory !== "All") {
                    if (item.category !== kanbanRoot.filterCategory) continue;
                }

                if (kanbanRoot.filterPriority !== "All" && (item.priority || "Medium") !== kanbanRoot.filterPriority) continue;

                if (kanbanRoot.filterText.trim().length > 0) {
                    const clean = item.name.replace(/(\s*\(Extension\))+$/gi, "").trim();
                    if (!clean.toLowerCase().includes(kanbanRoot.filterText.trim().toLowerCase())) continue;
                }

                count++;
            }
            return count;
        }

        readonly property int visibleCount: getColumnCount()

        DropArea {
            id: colDropArea
            anchors.fill: parent
            keys: ["activity-card"]
            onDropped: (drop) => {
                if (!drop.source || drop.source.modelIndex === undefined) return
                const itemIndex = drop.source.modelIndex
                if (colRoot.columnStatus === "Done") {
                    activityService.markComplete(itemIndex)
                } else if (colRoot.columnStatus === "In Progress") {
                    activityService.setActivityStatus(itemIndex, "In Progress")
                } else {
                    activityService.setActivityStatus(itemIndex, "Created")
                }
                kanbanRoot.modelVersion++
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            // Column Header
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                radius: 8
                color: Theme.surfaceCard
                border.color: Theme.borderDefault
                border.width: 1

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 12
                        rightMargin: 12
                    }
                    spacing: 8

                    Rectangle {
                        implicitWidth: 8
                        implicitHeight: 8
                        radius: 4
                        color: colRoot.statusColor
                    }

                    Text {
                        text: colRoot.columnTitle
                        font.pixelSize: 13
                        font.bold: true
                        color: Theme.textPrimary
                    }

                    Item { Layout.fillWidth: true }

                    // Count Badge
                    Rectangle {
                        radius: 6
                        implicitWidth: Math.max(22, countText.implicitWidth + 12)
                        implicitHeight: 20
                        color: Theme.surfaceBadge
                        border.color: Theme.borderDefault
                        border.width: 1

                        Text {
                            id: countText
                            anchors.centerIn: parent
                            text: colRoot.visibleCount.toString()
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.textSecondary
                        }
                    }

                    // Quick Add Button in Todo / Backlog Header
                    Rectangle {
                        visible: colRoot.canAdd
                        implicitWidth: 22
                        implicitHeight: 22
                        radius: 6
                        color: addBtnHov.hovered ? Theme.surfaceCardHover : "transparent"
                        border.color: addBtnHov.hovered ? Theme.borderDefault : "transparent"
                        border.width: 1

                        Components.LucideIcon {
                            anchors.centerIn: parent
                            name: "plus"
                            size: 13
                            color: addBtnHov.hovered ? Theme.textPrimary : Theme.textMuted
                        }

                        ToolTip.visible: addBtnHov.hovered
                        ToolTip.text: "Add task"
                        ToolTip.delay: 350

                        HoverHandler { id: addBtnHov; cursorShape: Qt.PointingHandCursor }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: kanbanRoot.addRequested()
                        }
                    }
                }
            }

            // Scrollable Column Cards
            ListView {
                id: colListView
                visible: colRoot.visibleCount > 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 8
                model: activityModel

                delegate: Item {
                    id: cardItemRoot
                    width: colListView.width
                    required property int index
                    required property string name
                    required property string category
                    required property int durationMinutes
                    required property bool done
                    required property string status
                    required property string priority
                    required property int extensionCount
                    required property var createdAt
                    required property var scheduledStartTime
                    required property var scheduledEndTime
                    required property bool reminderEnabled
                    required property bool isOverdue

                    readonly property int modelIndex: index
                    readonly property string itemStatus: (status && status.length > 0) ? status : (done ? "Done" : "Created")

                    // Live Countdown / Elapsed Calculator
                    readonly property int remainingSeconds: {
                        const _tick = activityService.currentTimestamp
                        if (!scheduledEndTime || scheduledEndTime.toString().length === 0) return 0
                        const endMs = new Date(scheduledEndTime).getTime()
                        const nowMs = new Date().getTime()
                        return Math.floor((endMs - nowMs) / 1000)
                    }
                    readonly property bool isOverdueTimer: remainingSeconds < 0
                    readonly property bool isUrgentCountdown: remainingSeconds >= 0 && remainingSeconds <= 300
                    readonly property string liveTimerText: {
                        if (!scheduledEndTime || scheduledEndTime.toString().length === 0) return ""
                        const absSec = Math.abs(remainingSeconds)
                        const mins = Math.floor(absSec / 60)
                        const secs = absSec % 60
                        const pad = (n) => n < 10 ? "0" + n : "" + n
                        if (isOverdueTimer) {
                            return "+" + pad(mins) + ":" + pad(secs) + " OT"
                        } else {
                            return pad(mins) + ":" + pad(secs) + " left"
                        }
                    }

                    // Filter matching
                    readonly property bool matchesStatus: {
                        const _ver = kanbanRoot.modelVersion;
                        if (colRoot.columnStatus === "Done") return done;
                        if (colRoot.columnStatus === "In Progress") return !done && itemStatus === "In Progress";
                        return !done && itemStatus !== "In Progress";
                    }

                    readonly property bool matchesCategory: {
                        if (kanbanRoot.filterCategory === "All") return true;
                        return category === kanbanRoot.filterCategory;
                    }

                    readonly property bool matchesPriority: {
                        if (kanbanRoot.filterPriority === "All") return true;
                        return (priority || "Medium") === kanbanRoot.filterPriority;
                    }

                    readonly property bool matchesSearch: {
                        if (kanbanRoot.filterText.trim().length === 0) return true;
                        const clean = name.replace(/(\s*\(Extension\))+$/gi, "").trim();
                        return clean.toLowerCase().includes(kanbanRoot.filterText.trim().toLowerCase());
                    }

                    readonly property bool isVisibleInColumn: matchesStatus && matchesCategory && matchesPriority && matchesSearch

                    visible: isVisibleInColumn
                    height: isVisibleInColumn ? 104 : 0

                    // Drag Container Card
                    Rectangle {
                        id: cardBox
                        width: parent.width
                        height: 96
                        radius: 10
                        color: kHover.hovered ? Theme.surfaceCardHover : Theme.surfaceCard
                        border.color: kHover.hovered ? (done ? Theme.accentGreen : Theme.accentBlue) : Theme.borderDefault
                        border.width: 1
                        opacity: (dragProxy.visible && dragProxy.currentItemRoot === cardItemRoot) ? 0.35 : (done ? 0.78 : 1.0)

                        layer.enabled: !Theme.isDark
                        layer.effect: MultiEffect {
                            shadowEnabled: !Theme.isDark
                            shadowColor: "#0A000000"
                            shadowBlur: 0.3
                            shadowVerticalOffset: 1
                        }

                        HoverHandler { id: kHover }

                        MouseArea {
                            id: dragArea
                            anchors.fill: parent
                            drag.target: dragProxy
                            drag.axis: Drag.XAndYAxis
                            drag.threshold: 8

                            onDoubleClicked: {
                                kanbanRoot.editRequested(cardItemRoot.modelIndex)
                            }

                            onPressed: {
                                let p = cardBox.mapToItem(kanbanRoot, 0, 0);
                                dragProxy.width = cardBox.width;
                                dragProxy.height = cardBox.height;
                                dragProxy.x = p.x;
                                dragProxy.y = p.y;
                                dragProxy.titleText = name.replace(/(\s*\(Extension\))+$/gi, "").trim();
                                dragProxy.categoryText = category;
                                dragProxy.priorityText = priority || "Medium";
                                dragProxy.durationText = kanbanRoot.formatDurationBoth(durationMinutes);
                                dragProxy.currentItemRoot = cardItemRoot;
                            }

                            onPositionChanged: {
                                if (drag.active && !dragProxy.visible) {
                                    dragProxy.visible = true;
                                }
                            }

                            onReleased: {
                                if (dragProxy.visible) {
                                    dragProxy.Drag.drop();
                                    dragProxy.visible = false;
                                }
                            }
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 6

                            // Card Name + Category Tag + Priority Dot
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Text {
                                    Layout.fillWidth: true
                                    text: name.replace(/(\s*\(Extension\))+$/gi, "").trim()
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: titleHov.hovered ? Theme.accentBlue : (done ? Theme.textMuted : Theme.textPrimary)
                                    elide: Text.ElideRight
                                    font.strikeout: done

                                    ToolTip.visible: titleHov.hovered && truncated
                                    ToolTip.text: text
                                    ToolTip.delay: 400

                                    HoverHandler { id: titleHov; cursorShape: Qt.PointingHandCursor }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        preventStealing: true
                                        onClicked: kanbanRoot.editRequested(cardItemRoot.modelIndex)
                                    }
                                }

                                // Priority Code Indicator: Clean Micro-Dot + Code
                                RowLayout {
                                    spacing: 3
                                    Rectangle {
                                        implicitWidth: 6
                                        implicitHeight: 6
                                        radius: 3
                                        color: Theme.priorityColor(priority)
                                    }
                                    Text {
                                        id: prioCardTxt
                                        text: Theme.priorityCode(priority)
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: Theme.priorityColor(priority)
                                    }
                                }

                                Text {
                                    text: "•"
                                    font.pixelSize: 10
                                    color: Theme.textMuted
                                }

                                // Category Label
                                Text {
                                    id: catLabel
                                    text: category
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: Theme.textSecondary
                                }
                            }

                            // Schedule / Timestamp context (fills empty void in card)
                            RowLayout {
                                visible: (scheduledStartTime && scheduledStartTime.toString().length > 0) || isOverdue
                                Layout.fillWidth: true
                                spacing: 4

                                Components.LucideIcon {
                                    name: "calendar"
                                    size: 10
                                    color: isOverdue ? Theme.accentRose : Theme.textMuted
                                }
                                Text {
                                    text: {
                                        if (!scheduledStartTime) return ""
                                        const s = new Date(scheduledStartTime)
                                        const fmt = (d) => {
                                            const h = d.getHours() % 12 || 12
                                            const m = d.getMinutes() < 10 ? '0' + d.getMinutes() : d.getMinutes()
                                            const ampm = d.getHours() >= 12 ? 'PM' : 'AM'
                                            return h + ":" + m + " " + ampm
                                        }
                                        if (!scheduledEndTime) return fmt(s)
                                        const e = new Date(scheduledEndTime)
                                        return fmt(s) + " – " + fmt(e)
                                    }
                                    font.pixelSize: 10
                                    font.bold: isOverdue
                                    color: isOverdue ? Theme.accentRose : Theme.textMuted
                                }
                            }

                            // Duration + Quick Actions Row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                // Duration & Telemetry Badges
                                RowLayout {
                                    spacing: 5
                                    Layout.alignment: Qt.AlignVCenter

                                    // Live Focus Countdown Ticker (When In Progress)
                                    Rectangle {
                                        visible: !done && itemStatus === "In Progress" && cardItemRoot.liveTimerText.length > 0
                                        radius: 4
                                        implicitHeight: 20
                                        implicitWidth: liveTimerKbRow.implicitWidth + 10
                                        color: cardItemRoot.isOverdueTimer ? Theme.accentRoseBg : (cardItemRoot.isUrgentCountdown ? Theme.accentAmberBg : Theme.accentBlueBg)
                                        border.color: cardItemRoot.isOverdueTimer ? Theme.accentRoseBorder : (cardItemRoot.isUrgentCountdown ? Theme.accentAmberBorder : Theme.accentBlueBorder)
                                        border.width: 1

                                        RowLayout {
                                            id: liveTimerKbRow
                                            anchors.centerIn: parent
                                            spacing: 3
                                            Components.LucideIcon {
                                                name: cardItemRoot.isOverdueTimer ? "alert-triangle" : "zap"
                                                size: 9
                                                color: cardItemRoot.isOverdueTimer ? Theme.accentRose : (cardItemRoot.isUrgentCountdown ? Theme.accentAmber : Theme.accentBlue)
                                            }
                                            Text {
                                                text: cardItemRoot.liveTimerText
                                                font.pixelSize: 9
                                                font.bold: true
                                                color: cardItemRoot.isOverdueTimer ? Theme.accentRose : (cardItemRoot.isUrgentCountdown ? Theme.accentAmber : Theme.accentBlue)
                                            }
                                        }

                                        ToolTip.visible: liveTimerKbHov.hovered
                                        ToolTip.text: cardItemRoot.isOverdueTimer ? "Session exceeded schedule window" : "Focus time remaining"
                                        ToolTip.delay: 250
                                        HoverHandler { id: liveTimerKbHov }
                                    }

                                    // Base/Total Tracked Duration Pill
                                    Rectangle {
                                        radius: 4
                                        implicitHeight: 20
                                        implicitWidth: durKbRow.implicitWidth + 12
                                        color: extensionCount > 0 ? (Theme.isDark ? "#241530" : "#FAF5FF") : Theme.surfaceBadge
                                        border.color: extensionCount > 0 ? (Theme.isDark ? "#4A1A68" : "#E9D5FF") : Theme.borderDefault
                                        border.width: 1

                                        RowLayout {
                                            id: durKbRow
                                            anchors.centerIn: parent
                                            spacing: 4
                                            Components.LucideIcon {
                                                name: "clock"
                                                size: 10
                                                color: extensionCount > 0 ? Theme.accentPurple : Theme.textSecondary
                                            }
                                            Text {
                                                text: kanbanRoot.formatDurationBoth(durationMinutes)
                                                font.pixelSize: 9
                                                font.bold: true
                                                color: extensionCount > 0 ? (Theme.isDark ? "#F3E8FF" : "#6B21A8") : Theme.textSecondary
                                            }
                                        }

                                        ToolTip.visible: durKbHov.hovered
                                        ToolTip.text: {
                                            if (extensionCount > 0) {
                                                const extra = extensionCount * 15
                                                const base = Math.max(0, durationMinutes - extra)
                                                return "Total Duration: " + kanbanRoot.formatDurationBoth(durationMinutes) +
                                                       "\n• Scheduled Base: " + kanbanRoot.formatDurationBoth(base) +
                                                       "\n• Overtime Added: +" + extra + "m (" + extensionCount + " extensions)"
                                            }
                                            return "Total Duration: " + kanbanRoot.formatDurationBoth(durationMinutes)
                                        }
                                        ToolTip.delay: 300
                                        HoverHandler { id: durKbHov }
                                    }

                                    // Extra time indicator (Non-clipped, perfectly padded)
                                    Rectangle {
                                        visible: extensionCount > 0
                                        radius: 4
                                        implicitHeight: 20
                                        implicitWidth: extKbRow.implicitWidth + 12
                                        color: Theme.accentPurpleBg
                                        border.color: Theme.accentPurpleBorder
                                        border.width: 1

                                        RowLayout {
                                            id: extKbRow
                                            anchors.centerIn: parent
                                            spacing: 3
                                            Components.LucideIcon {
                                                name: "sparkles"
                                                size: 9
                                                color: Theme.accentPurple
                                            }
                                            Text {
                                                id: extKbTxt
                                                text: "+" + (extensionCount * 15) + "m OT"
                                                font.pixelSize: 9
                                                font.bold: true
                                                color: Theme.accentPurple
                                            }
                                        }

                                        ToolTip.visible: extKbHover.hovered
                                        ToolTip.text: "+" + (extensionCount * 15) + "m overtime added"
                                        ToolTip.delay: 300
                                        HoverHandler { id: extKbHover }
                                    }

                                    // Overdue badge (if past deadline)
                                    Rectangle {
                                        visible: !done && isOverdue
                                        radius: 4
                                        implicitHeight: 20
                                        implicitWidth: overdueKbRow.implicitWidth + 12
                                        color: Theme.accentRoseBg
                                        border.color: Theme.accentRoseBorder
                                        border.width: 1

                                        RowLayout {
                                            id: overdueKbRow
                                            anchors.centerIn: parent
                                            spacing: 3
                                            Components.LucideIcon {
                                                name: "alert-triangle"
                                                size: 9
                                                color: Theme.accentRose
                                            }
                                            Text {
                                                id: overdueKbTxt
                                                text: "Overdue"
                                                font.pixelSize: 9
                                                font.bold: true
                                                color: Theme.accentRose
                                            }
                                        }

                                        ToolTip.visible: overdueKbHover.hovered
                                        ToolTip.text: "Task is past its scheduled deadline"
                                        ToolTip.delay: 300
                                        HoverHandler { id: overdueKbHover }
                                    }

                                    // Bell icon (if reminder enabled)
                                    Rectangle {
                                        visible: !done && reminderEnabled
                                        radius: 4
                                        implicitHeight: 20
                                        implicitWidth: 18
                                        color: "transparent"

                                        Components.LucideIcon {
                                            anchors.centerIn: parent
                                            name: "bell"
                                            size: 10
                                            color: Theme.accentBlue
                                        }

                                        ToolTip.visible: bellKbHover.hovered
                                        ToolTip.text: "Reminders active for this activity"
                                        ToolTip.delay: 300
                                        HoverHandler { id: bellKbHover }
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                // Quick Status Move Buttons
                                // If Todo -> Show "Start" button
                                Rectangle {
                                    visible: !done && itemStatus === "Created"
                                    implicitHeight: 26
                                    implicitWidth: startRow.implicitWidth + 14
                                    radius: 6
                                    color: startHov.hovered ? Theme.accentBlue : Theme.accentBlueBg
                                    border.color: Theme.accentBlueBorder
                                    border.width: 1

                                    RowLayout {
                                        id: startRow
                                        anchors.centerIn: parent
                                        spacing: 4
                                        Components.LucideIcon {
                                            name: "zap"
                                            size: 11
                                            color: startHov.hovered ? "#FFFFFF" : Theme.accentBlue
                                        }
                                        Text {
                                            text: "Start"
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: startHov.hovered ? "#FFFFFF" : Theme.accentBlue
                                        }
                                    }

                                    HoverHandler { id: startHov; cursorShape: Qt.PointingHandCursor }
                                    TapHandler {
                                        onTapped: activityService.setActivityStatus(cardItemRoot.modelIndex, "In Progress")
                                    }
                                }

                                // If In Progress -> Show "+15m" and "Done" buttons
                                RowLayout {
                                    visible: !done && itemStatus === "In Progress"
                                    spacing: 4

                                    Rectangle {
                                        implicitHeight: 26
                                        implicitWidth: extRow.implicitWidth + 14
                                        radius: 6
                                        color: extHov.hovered ? Theme.accentPurpleBg : Theme.surfaceBadge
                                        border.color: extHov.hovered ? Theme.accentPurple : Theme.borderDefault
                                        border.width: 1

                                        RowLayout {
                                            id: extRow
                                            anchors.centerIn: parent
                                            spacing: 3
                                            Components.LucideIcon {
                                                name: "plus"
                                                size: 10
                                                color: Theme.accentPurple
                                            }
                                            Text {
                                                text: "15m"
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: Theme.accentPurple
                                            }
                                        }

                                        ToolTip.visible: extHov.hovered
                                        ToolTip.text: "Add 15m overtime"
                                        ToolTip.delay: 250
                                        HoverHandler { id: extHov; cursorShape: Qt.PointingHandCursor }
                                        TapHandler {
                                            onTapped: activityService.extendActivity(cardItemRoot.modelIndex, 15)
                                        }
                                    }

                                    Rectangle {
                                        implicitHeight: 26
                                        implicitWidth: doneRow.implicitWidth + 14
                                        radius: 6
                                        color: doneHov.hovered ? Theme.accentGreen : Theme.accentGreenBg
                                        border.color: Theme.accentGreenBorder
                                        border.width: 1

                                        RowLayout {
                                            id: doneRow
                                            anchors.centerIn: parent
                                            spacing: 4
                                            Components.LucideIcon {
                                                name: "check"
                                                size: 11
                                                color: doneHov.hovered ? "#FFFFFF" : Theme.accentGreen
                                            }
                                            Text {
                                                text: "Done"
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: doneHov.hovered ? "#FFFFFF" : Theme.accentGreen
                                            }
                                        }

                                        ToolTip.visible: doneHov.hovered
                                        ToolTip.text: "Mark complete"
                                        ToolTip.delay: 250
                                        HoverHandler { id: doneHov; cursorShape: Qt.PointingHandCursor }
                                        TapHandler {
                                            onTapped: activityService.markComplete(cardItemRoot.modelIndex)
                                        }
                                    }
                                }

                                // If Done -> Show "Reopen" button
                                Rectangle {
                                    visible: done
                                    implicitHeight: 26
                                    implicitWidth: reopenRow.implicitWidth + 14
                                    radius: 6
                                    color: reopenHov.hovered ? Theme.accentGreenBg : Theme.surfaceBadge
                                    border.color: reopenHov.hovered ? Theme.accentGreen : Theme.borderDefault
                                    border.width: 1

                                    RowLayout {
                                        id: reopenRow
                                        anchors.centerIn: parent
                                        spacing: 4
                                        Components.LucideIcon {
                                            name: "rotate-ccw"
                                            size: 11
                                            color: Theme.accentGreen
                                        }
                                        Text {
                                            text: "Reopen"
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: Theme.accentGreen
                                        }
                                    }

                                    ToolTip.visible: reopenHov.hovered
                                    ToolTip.text: "Reopen activity"
                                    ToolTip.delay: 250
                                    HoverHandler { id: reopenHov; cursorShape: Qt.PointingHandCursor }
                                    TapHandler {
                                        onTapped: activityService.reopenActivity(cardItemRoot.modelIndex)
                                    }
                                }

                                // Dedicated Edit Task Button (Available across ALL statuses: Todo, In Progress, Done)
                                Rectangle {
                                    implicitWidth: 26
                                    implicitHeight: 26
                                    radius: 6
                                    color: editBtnHov.hovered ? Theme.accentBlueBg : Theme.surfaceBadge
                                    border.color: editBtnHov.hovered ? Theme.accentBlue : Theme.borderDefault
                                    border.width: 1

                                    Components.LucideIcon {
                                        anchors.centerIn: parent
                                        name: "edit-3"
                                        size: 11
                                        color: editBtnHov.hovered ? Theme.accentBlue : Theme.textSecondary
                                    }

                                    ToolTip.visible: editBtnHov.hovered
                                    ToolTip.text: "Edit task details"
                                    ToolTip.delay: 250

                                    HoverHandler { id: editBtnHov; cursorShape: Qt.PointingHandCursor }
                                    TapHandler {
                                        onTapped: kanbanRoot.editRequested(cardItemRoot.modelIndex)
                                    }
                                }

                                // Dedicated Delete Task Button on Kanban card
                                Rectangle {
                                    implicitWidth: 26
                                    implicitHeight: 26
                                    radius: 6
                                    color: delBtnHov.hovered ? Theme.accentRedBg : Theme.surfaceBadge
                                    border.color: delBtnHov.hovered ? Theme.accentRed : Theme.borderDefault
                                    border.width: 1

                                    Components.LucideIcon {
                                        anchors.centerIn: parent
                                        name: "trash-2"
                                        size: 11
                                        color: delBtnHov.hovered ? Theme.accentRed : Theme.textMuted
                                    }

                                    ToolTip.visible: delBtnHov.hovered
                                    ToolTip.text: "Delete task"
                                    ToolTip.delay: 250

                                    HoverHandler { id: delBtnHov; cursorShape: Qt.PointingHandCursor }
                                    TapHandler {
                                        onTapped: activityService.removeActivity(cardItemRoot.modelIndex)
                                    }
                                }
                            }
                        }
                    }
                }

                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff }
            }

            // Column Empty State (when 0 cards match)
            Item {
                visible: colRoot.visibleCount === 0
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    opacity: 0.65

                    Components.LucideIcon {
                        Layout.alignment: Qt.AlignHCenter
                        name: colRoot.iconName
                        size: 20
                        color: Theme.textMuted
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: colRoot.columnStatus === "Created" ? "No tasks in backlog" :
                              (colRoot.columnStatus === "In Progress" ? "No active tasks" : "No completed tasks")
                        font.pixelSize: 12
                        font.bold: true
                        color: Theme.textSecondary
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: colRoot.columnStatus === "Created" ? "Click + to add a task" : "Drag tasks here to change status"
                        font.pixelSize: 11
                        color: Theme.textMuted
                    }
                }
            }
        }
    }
}

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
            statusColor: Theme.textSecondary
            statusBgColor: Theme.surfaceBadge
            statusBorderColor: Theme.borderDefault
            iconName: "list-todo"
        }

        // ── Column 2: IN PROGRESS ─────────────────────────────────────────────
        KanbanColumn {
            id: colInProgress
            Layout.fillWidth: true
            Layout.fillHeight: true
            columnTitle: "In Progress"
            columnStatus: "In Progress"
            statusColor: Theme.accentBlue
            statusBgColor: Theme.accentBlueBg
            statusBorderColor: Theme.accentBlueBorder
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
            statusBgColor: Theme.accentGreenBg
            statusBorderColor: Theme.accentGreenBorder
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
                    implicitWidth: 16
                    implicitHeight: 18
                    color: Theme.priorityBg(dragProxy.priorityText)
                    border.color: Theme.priorityBorder(dragProxy.priorityText)
                    border.width: 1

                    Rectangle {
                        anchors.centerIn: parent
                        implicitWidth: 6
                        implicitHeight: 6
                        radius: 3
                        color: Theme.priorityColor(dragProxy.priorityText)
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
        required property color  statusBgColor
        required property color  statusBorderColor
        required property string iconName

        radius: 14
        color: colDropArea.containsDrag ? Theme.surfaceCardHover : Theme.surfaceSidebar
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

                if (kanbanRoot.filterCategory === "Done") {
                    if (!item.done) continue;
                } else if (kanbanRoot.filterCategory === "In Progress") {
                    if (itemStatus !== "In Progress") continue;
                } else if (kanbanRoot.filterCategory !== "All") {
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
                } else {
                    activityService.setActivityStatus(itemIndex, colRoot.columnStatus)
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
                radius: 10
                color: colRoot.statusBgColor
                border.color: colRoot.statusBorderColor
                border.width: 1

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 12
                        rightMargin: 12
                    }
                    spacing: 8

                    Components.LucideIcon {
                        name: colRoot.iconName
                        size: 14
                        color: colRoot.statusColor
                    }

                    Text {
                        text: colRoot.columnTitle
                        font.pixelSize: 13
                        font.bold: true
                        color: colRoot.statusColor
                    }

                    Item { Layout.fillWidth: true }

                    // Count Badge
                    Rectangle {
                        radius: 8
                        implicitWidth: countText.implicitWidth + 12
                        implicitHeight: 20
                        color: Qt.rgba(colRoot.statusColor.r, colRoot.statusColor.g, colRoot.statusColor.b, 0.2)
                        Text {
                            id: countText
                            anchors.centerIn: parent
                            text: colRoot.visibleCount.toString()
                            font.pixelSize: 11
                            font.bold: true
                            color: colRoot.statusColor
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
                    readonly property int modelIndex: index
                    readonly property string itemStatus: (status && status.length > 0) ? status : (done ? "Done" : "Created")

                    // Filter matching
                    readonly property bool matchesStatus: {
                        const _ver = kanbanRoot.modelVersion;
                        if (colRoot.columnStatus === "Done") return done;
                        if (colRoot.columnStatus === "In Progress") return !done && itemStatus === "In Progress";
                        return !done && itemStatus !== "In Progress";
                    }

                    readonly property bool matchesCategory: {
                        if (kanbanRoot.filterCategory === "All") return true;
                        if (kanbanRoot.filterCategory === "Done") return done;
                        if (kanbanRoot.filterCategory === "In Progress") return itemStatus === "In Progress";
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
                        color: done ? Theme.accentGreenBg : (kHover.hovered ? Theme.surfaceCardHover : Theme.surfaceCard)
                        border.color: done ? Theme.accentGreenBorder : (kHover.hovered ? Theme.accentBlue : Theme.borderDefault)
                        border.width: 1
                        opacity: (dragProxy.visible && dragProxy.currentItemRoot === cardItemRoot) ? 0.35 : 1.0

                        HoverHandler { id: kHover }

                        MouseArea {
                            id: dragArea
                            anchors.fill: parent
                            drag.target: dragProxy
                            drag.axis: Drag.XAndYAxis

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
                                dragProxy.visible = true;
                            }

                            onReleased: {
                                dragProxy.Drag.drop();
                                dragProxy.visible = false;
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

                                    ToolTip.visible: titleHov.hovered
                                    ToolTip.text: "Click or double-click to edit details"
                                    ToolTip.delay: 300

                                    HoverHandler { id: titleHov; cursorShape: Qt.PointingHandCursor }
                                    TapHandler { onTapped: kanbanRoot.editRequested(cardItemRoot.modelIndex) }
                                }

                                // Priority Indicator Dot
                                Rectangle {
                                    radius: 4
                                    implicitWidth: 16
                                    implicitHeight: 18
                                    color: Theme.priorityBg(priority)
                                    border.color: Theme.priorityBorder(priority)
                                    border.width: 1

                                    Rectangle {
                                        anchors.centerIn: parent
                                        implicitWidth: 6
                                        implicitHeight: 6
                                        radius: 3
                                        color: Theme.priorityColor(priority)
                                    }

                                    ToolTip.visible: prioCardHover.hovered
                                    ToolTip.text: "Priority: " + (priority || "Medium")
                                    ToolTip.delay: 250
                                    HoverHandler { id: prioCardHover }
                                }

                                // Category Badge
                                Rectangle {
                                    radius: 6
                                    implicitWidth: catLabel.implicitWidth + 10
                                    implicitHeight: 18
                                    color: Theme.surfaceBadge
                                    border.color: Theme.borderDefault
                                    border.width: 1
                                    Text {
                                        id: catLabel
                                        anchors.centerIn: parent
                                        text: category
                                        font.pixelSize: 9
                                        font.bold: true
                                        color: Theme.textSecondary
                                    }
                                }
                            }

                            // Duration + Quick Actions Row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                // Duration pill
                                RowLayout {
                                    spacing: 4
                                    Components.LucideIcon { name: "clock"; size: 10; color: Theme.textMuted }
                                    Text {
                                        text: kanbanRoot.formatDurationBoth(durationMinutes)
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: Theme.textMuted
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                // Quick Status Move Buttons
                                // If Todo -> Show "Start" button
                                Rectangle {
                                    visible: !done && itemStatus === "Created"
                                    implicitWidth: 54; implicitHeight: 22; radius: 6
                                    color: Theme.accentBlueBg; border.color: Theme.accentBlueBorder; border.width: 1
                                    RowLayout {
                                        anchors.centerIn: parent; spacing: 3
                                        Components.LucideIcon { name: "zap"; size: 10; color: Theme.accentBlue }
                                        Text { text: "Start"; font.pixelSize: 10; font.bold: true; color: Theme.accentBlue }
                                    }
                                    TapHandler { onTapped: activityService.setActivityStatus(index, "In Progress") }
                                }

                                // If In Progress -> Show "+15m" and "Done" buttons
                                RowLayout {
                                    visible: !done && itemStatus === "In Progress"
                                    spacing: 4
                                    Rectangle {
                                        implicitWidth: 42; implicitHeight: 22; radius: 6
                                        color: Theme.surfaceBadge; border.color: Theme.borderDefault; border.width: 1
                                        Text { anchors.centerIn: parent; text: "+15m"; font.pixelSize: 9; font.bold: true; color: Theme.accentBlue }
                                        TapHandler { onTapped: activityService.extendActivity(index, 15) }
                                    }
                                    Rectangle {
                                        implicitWidth: 46; implicitHeight: 22; radius: 6
                                        color: Theme.accentGreenBg; border.color: Theme.accentGreenBorder; border.width: 1
                                        RowLayout {
                                            anchors.centerIn: parent; spacing: 2
                                            Components.LucideIcon { name: "check"; size: 10; color: Theme.accentGreen }
                                            Text { text: "Done"; font.pixelSize: 10; font.bold: true; color: Theme.accentGreen }
                                        }
                                        TapHandler { onTapped: activityService.markComplete(index) }
                                    }
                                }

                                // If Done -> Show "Reopen" button
                                Rectangle {
                                    visible: done
                                    implicitWidth: 62; implicitHeight: 22; radius: 6
                                    color: Theme.surfaceBadge; border.color: Theme.borderDefault; border.width: 1
                                    RowLayout {
                                        anchors.centerIn: parent; spacing: 3
                                        Components.LucideIcon { name: "rotate-ccw"; size: 10; color: Theme.accentGreen }
                                        Text { text: "Reopen"; font.pixelSize: 10; font.bold: true; color: Theme.accentGreen }
                                    }
                                    TapHandler { onTapped: activityService.reopenActivity(index) }
                                }

                                // Dedicated Edit Task Button (Available across ALL statuses: Todo, In Progress, Done)
                                Rectangle {
                                    implicitWidth: 24
                                    implicitHeight: 22
                                    radius: 6
                                    color: editBtnHov.hovered ? Theme.surfaceBadge : "transparent"
                                    border.color: editBtnHov.hovered ? Theme.borderDefault : "transparent"
                                    border.width: 1

                                    Components.LucideIcon {
                                        anchors.centerIn: parent
                                        name: "edit-3"
                                        size: 11
                                        color: editBtnHov.hovered ? Theme.accentBlue : Theme.textMuted
                                    }

                                    ToolTip.visible: editBtnHov.hovered
                                    ToolTip.text: "Edit task details"
                                    ToolTip.delay: 250

                                    HoverHandler { id: editBtnHov; cursorShape: Qt.PointingHandCursor }
                                    TapHandler { onTapped: kanbanRoot.editRequested(cardItemRoot.modelIndex) }
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

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: 12
                    color: Theme.isDark ? "#080D1A" : "#F8FAFC"
                    border.color: Theme.borderSubtle
                    border.width: 1

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Components.LucideIcon {
                            Layout.alignment: Qt.AlignHCenter
                            name: colRoot.iconName
                            size: 24
                            color: Theme.textMuted
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "No activities in " + colRoot.columnTitle
                            font.pixelSize: 12
                            font.bold: true
                            color: Theme.textSecondary
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Drop activities here or change filters"
                            font.pixelSize: 10
                            color: Theme.textMuted
                        }
                    }
                }
            }
        }
    }
}

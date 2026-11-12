// ActivityListView.qml — scrollable list with live instant search, category filtering, and filter empty state
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components" as Components
import ActivityTracker 1.0

ListView {
    id: listView
    clip: true
    spacing: 8

    property string filterCategory: "All"
    property string filterPriority: "All"
    property string filterText: ""
    property string filterTimeframe: "All Time"

    signal editRequested(int index)

    // Reactive model version counter — updates when activity state mutates
    property int modelVersion: 0

    Connections {
        target: activityService
        function onStatsChanged() { listView.modelVersion++ }
        function onTotalDurationTodayChanged() { listView.modelVersion++ }
        function onDataRefreshed() { listView.modelVersion++ }
    }

    Connections {
        target: activityModel
        function onDataChanged() { listView.modelVersion++ }
        function onRowsInserted() { listView.modelVersion++ }
        function onRowsRemoved() { listView.modelVersion++ }
        function onModelReset() { listView.modelVersion++ }
    }

    model: activityModel

    topMargin:    0
    bottomMargin: 10
    leftMargin:   0
    rightMargin:  0

    // Reactive count of visible activities
    function getVisibleCount() {
        const _trigger = listView.modelVersion; // makes it reactive to model mutations!
        let count = 0;
        for (let i = 0; i < activityModel.count; ++i) {
            const item = activityModel.get(i);
            if (!item) continue;
            const itemStatus = (item.status && item.status.length > 0) ? item.status : (item.done ? "Done" : "Created");

            if (listView.filterCategory === "Done") {
                if (!item.done) continue;
            } else if (listView.filterCategory === "In Progress") {
                if (item.done || itemStatus !== "In Progress") continue;
            } else if (listView.filterCategory === "Todo") {
                if (item.done || itemStatus !== "Created") continue;
            } else if (listView.filterCategory !== "All") {
                if (item.category !== listView.filterCategory) continue;
            }

            if (listView.filterPriority !== "All" && (item.priority || "Medium") !== listView.filterPriority) continue;

            if (listView.filterText.trim().length > 0) {
                const clean = item.name.replace(/(\s*\(Extension\))+$/gi, "").trim();
                if (!clean.toLowerCase().includes(listView.filterText.trim().toLowerCase())) continue;
            }

            count++;
        }
        return count;
    }

    readonly property int visibleCount: getVisibleCount()

    // Smooth list item entry & removal transitions
    add: Transition {
        NumberAnimation { properties: "opacity,scale"; from: 0.8; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
    }
    remove: Transition {
        NumberAnimation { properties: "opacity"; to: 0; duration: 120; easing.type: Easing.InCubic }
    }

    delegate: Components.ActivityCard {
        id: cardDelegate
        // Leave margin if scrollbar is visible so cards and action buttons never overlap
        width: listView.width - (vBar.visible ? 14 : 0)

        // ── Filter Evaluation ─────────────────────────────────────────────────
        readonly property bool matchesCategory: {
            if (listView.filterCategory === "All") return true;
            if (listView.filterCategory === "Done") return cardDelegate.done;
            if (listView.filterCategory === "In Progress") return cardDelegate.activeStatus === "In Progress";
            if (listView.filterCategory === "Todo") return cardDelegate.activeStatus === "Created";
            return cardDelegate.category === listView.filterCategory;
        }

        readonly property bool matchesPriority: {
            if (listView.filterPriority === "All") return true;
            return cardDelegate.activePriority === listView.filterPriority;
        }

        readonly property bool matchesSearch: {
            if (listView.filterText.trim().length === 0) return true;
            return cardDelegate.cleanDisplayName(cardDelegate.name).toLowerCase().includes(listView.filterText.trim().toLowerCase());
        }

        readonly property bool matchesTimeframe: {
            if (listView.filterTimeframe === "All Time") return true;
            const itemDate = cardDelegate.createdAt;
            if (!itemDate) return true;
            const now = new Date();
            const created = (itemDate instanceof Date) ? itemDate : new Date(itemDate);
            if (isNaN(created.getTime())) return true;

            if (listView.filterTimeframe === "Today") {
                return created.toDateString() === now.toDateString();
            } else if (listView.filterTimeframe === "Last 7 Days") {
                return (now - created) <= 7 * 24 * 3600 * 1000;
            } else if (listView.filterTimeframe === "Last 30 Days") {
                return (now - created) <= 30 * 24 * 3600 * 1000;
            }
            return true;
        }

        readonly property bool isVisibleInFilter: matchesCategory && matchesPriority && matchesSearch && matchesTimeframe

        visible: isVisibleInFilter
        height: isVisibleInFilter ? 76 : 0

        onEditRequested: listView.editRequested(cardDelegate.index)
        onRemoveRequested: activityService.removeActivity(cardDelegate.index)
        onCompleteRequested: activityService.markComplete(cardDelegate.index)
        onReopenRequested: activityService.reopenActivity(cardDelegate.index)
        onStatusChangeRequested: function(newStatus) {
            activityService.setActivityStatus(cardDelegate.index, newStatus)
        }
        onPriorityChangeRequested: function(newPriority) {
            activityService.setActivityPriority(cardDelegate.index, newPriority)
        }
        onExtendRequested: function(additionalMinutes) {
            activityService.extendActivity(cardDelegate.index, additionalMinutes)
        }
        onCreateExtensionRequested: function(minutes) {
            activityService.extendActivity(cardDelegate.index, minutes)
        }
    }

    // Scrollbar hidden by default (mouse wheel & touchpad flicking work 100% smoothly without overlap)
    ScrollBar.vertical: ScrollBar {
        id: vBar
        policy: ScrollBar.AlwaysOff
    }

    // ── Filter Empty State (Shown when activities exist but none match active filters) ──
    Item {
        anchors.centerIn: parent
        visible: listView.visibleCount === 0 && activityModel.count > 0
        width: Math.min(listView.width - 40, 480)
        implicitHeight: filterEmptyCol.implicitHeight

        ColumnLayout {
            id: filterEmptyCol
            anchors.centerIn: parent
            spacing: 14

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 60
                implicitHeight: 60
                radius: 30
                color: Theme.accentBlueBg
                border.color: Theme.accentBlueBorder
                border.width: 1

                Components.LucideIcon {
                    anchors.centerIn: parent
                    name: "filter"
                    size: 26
                    color: Theme.accentBlue
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: listView.filterCategory !== "All" ? ("No " + listView.filterCategory + " Activities") : "No Matching Activities"
                font.pixelSize: 16
                font.bold: true
                color: Theme.textPrimary
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: parent.width
                text: "No tasks found matching your active filter criteria. Try clearing the filter or logging a new activity."
                font.pixelSize: 12
                color: Theme.textSecondary
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 140
                implicitHeight: 34
                radius: 8
                color: resetFilterHover.hovered ? Theme.accentBlue : Theme.surfaceBadge
                border.color: Theme.borderDefault
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    Components.LucideIcon {
                        name: "rotate-ccw"
                        size: 13
                        color: resetFilterHover.hovered ? "#FFFFFF" : Theme.textPrimary
                    }
                    Text {
                        text: "Show All Tasks"
                        font.pixelSize: 12
                        font.bold: true
                        color: resetFilterHover.hovered ? "#FFFFFF" : Theme.textPrimary
                    }
                }

                HoverHandler { id: resetFilterHover; cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    onTapped: {
                        root.activeCategoryFilter = "All";
                        root.activePriorityFilter = "All";
                        root.activeSearchQuery = "";
                    }
                }
            }
        }
    }
}

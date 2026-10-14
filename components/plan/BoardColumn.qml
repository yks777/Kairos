import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Commons
import ".."
import "logic/Model.js" as Model

ColumnLayout {
    id: root

    property string panelId: ""
    property var service: null
    property bool editorOpen: false
    property string menuTaskId: ""
    property bool dropHighlight: false
    property bool listFrozen: false
    property string draggedTaskId: "" // For tracking drag source

    signal cardMenu(string taskId)

    spacing: Style.space(6)
    Layout.fillWidth: true
    Layout.fillHeight: true

    // Get the panel object from panelId
    readonly property var panel: {
        if (!service || !panelId) return null
        var panels = service.panelsForBoard(service.activeBoardId)
        for (var i = 0; i < panels.length; i++) {
            if (panels[i].id === panelId) {
                return panels[i]
            }
        }
        return null
    }

    // Get panel's boardId
    readonly property string boardId: panel ? panel.boardId : ""

    // Get panel index in board for columnId calculation
    readonly property int panelIndex: {
        if (!service || !panelId) return -1
        var panels = service.panelsForBoard(service.activeBoardId)
        for (var i = 0; i < panels.length; i++) {
            if (panels[i].id === panelId) {
                return i
            }
        }
        return -1
    }

    // Get columnId for backward compatibility (based on panel index)
    readonly property string columnId: {
        if (panelIndex < 0) return "q1"
        if (panelIndex < Model.COLUMNS.length) {
            return Model.COLUMNS[panelIndex]
        }
        return "q" + (panelIndex + 1)
    }

    // Get tasks for this panel in correct order
    readonly property var panelTasks: {
        if (!service || !boardId) return []
        
        // Get all incomplete tasks for this board
        var allTasks = []
        for (var i = 0; i < service.tasks.length; i++) {
            var task = service.tasks[i]
            if (task.boardId === boardId && !task.completedAt) {
                allTasks.push(task)
            }
        }
        
        // If no taskIds ordering specified, sort by creation date
        if (!panel || !panel.taskIds || panel.taskIds.length === 0) {
            allTasks.sort(function(a, b) {
                return a.createdAt - b.createdAt || String(a.id).localeCompare(String(b.id))
            })
            return allTasks
        }
        
        // Separate ordered and unordered tasks
        var orderedTasks = [] // Tasks in panel.taskIds, in that order
        var taskIdsMap = {} // For quick lookup
        for (var i = 0; i < panel.taskIds.length; i++) {
            taskIdsMap[panel.taskIds[i]] = true
        }
        
        // First pass: add tasks that are in taskIds, in order
        for (var i = 0; i < panel.taskIds.length; i++) {
            var taskId = panel.taskIds[i]
            for (var j = 0; j < allTasks.length; j++) {
                if (allTasks[j].id === taskId) {
                    orderedTasks.push(allTasks[j])
                    break
                }
            }
        }
        
        // Second pass: add remaining tasks (not in taskIds) sorted by creation date
        var remainingTasks = []
        for (var i = 0; i < allTasks.length; i++) {
            if (!taskIdsMap[allTasks[i].id]) {
                remainingTasks.push(allTasks[i])
            }
        }
        remainingTasks.sort(function(a, b) {
            return a.createdAt - b.createdAt || String(a.id).localeCompare(String(b.id))
        })
        
        return orderedTasks.concat(remainingTasks)
    }

    ColumnLayout {
        spacing: 0
        Layout.fillWidth: true

        RowLayout {
            spacing: Style.space(6)
            Layout.alignment: Qt.AlignHCenter

            Text {
                textFormat: Text.PlainText
                text: panel ? panel.title : "Column"
                color: Color.popups.text
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                font.letterSpacing: 1
                elide: Text.ElideRight
            }

            Text {
                textFormat: Text.PlainText
                text: String(panelTasks.length)
                color: Color.muted
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
            }
        }

        Text {
            textFormat: Text.PlainText
            text: panel ? "" : "" // Subtitle not used in board view for now
            color: Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            visible: false // No subtitle in board view
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }

    Rectangle {
        height: Math.max(1, Style.space(1))
        color: root.dropHighlight ? Color.accent : Color.popups.border
        opacity: root.dropHighlight ? 1.0 : 0.5
        Layout.fillWidth: true
    }

    ListView {
        id: list
        model: panelTasks
        spacing: Style.space(6)
        clip: true
        interactive: !root.listFrozen
        boundsBehavior: Flickable.StopAtBounds
        Layout.fillWidth: true
        Layout.fillHeight: true

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            visible: list.contentHeight > list.height + 1
            background: Item { implicitWidth: Style.space(6) }
            contentItem: Rectangle {
                implicitWidth: Style.space(6)
                radius: width / 2
                color: Color.muted
            }
        }

        DropArea {
            anchors.fill: parent
            onEntered: root.dropHighlight = true
            onExited: root.dropHighlight = false
            onDropped: function(drop) {
                root.dropHighlight = false
                if (!drop || !drop.source) return
                var source = drop.source
                if (typeof source.endDrag === "function") source.endDrag()
                if (!root.service || !source.task) return
                
                var taskId = String(source.task.id || "")
                if (taskId === "") return
                
                // Get source panel info from the dragged task
                var sourceBoardId = source.task.boardId
                var sourcePanelId = ""
                var sourcePanelIndex = -1
                
                // Find which panel this task came from
                if (root.service && sourceBoardId) {
                    var sourcePanels = root.service.panelsForBoard(sourceBoardId)
                    for (var i = 0; i < sourcePanels.length; i++) {
                        var panel = sourcePanels[i]
                        // Check if task is in this panel's taskIds or matches columnId
                        var inPanel = false
                        if (panel.taskIds && panel.taskIds.indexOf(taskId) !== -1) {
                            inPanel = true
                        } else {
                            // Fallback: check if task's columnId matches panel's expected columnId
                            var expectedColId = ""
                            if (i < Model.COLUMNS.length) {
                                expectedColId = Model.COLUMNS[i]
                            } else {
                                expectedColId = "q" + (i + 1)
                            }
                            if (source.task.columnId === expectedColId) {
                                inPanel = true
                            }
                        }
                        if (inPanel) {
                            sourcePanelId = panel.id
                            sourcePanelIndex = i
                            break
                        }
                    }
                }
                
                // If dragging from same panel, reorder within panel
                if (sourcePanelId === root.panelId && sourcePanelId !== "") {
                    // Reorder tasks within the same panel
                    var newTaskIds = [...root.panel.taskIds] // Copy current taskIds
                    var oldIndex = newTaskIds.indexOf(taskId)
                    if (oldIndex !== -1) {
                        newTaskIds.splice(oldIndex, 1) // Remove task from old position
                        
                        // Estimate new index based on drop position
                        // Simple approach: insert at end for now
                        // TODO: Improve drop position detection
                        newTaskIds.push(taskId) // Insert at end
                        
                        root.service.reorderPanelTasks(root.panelId, newTaskIds)
                    }
                } 
                // If dragging from different panel or from nowhere (new task), move to this panel
                else if (root.service && taskId !== "") {
                    root.service.moveTaskToPanel(taskId, root.panelId)
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: Style.cornerRadius
            color: Color.accent
            opacity: root.dropHighlight ? 0.10 : 0.0
        }

        delegate: TaskCard {
            required property var modelData
            task: modelData
            width: list.width
            isActive: root.service ? root.service.activeTaskId === modelData.id : false
            menuOpen: root.menuTaskId === modelData.id
            timerLive: root.service ? (root.service.timer.phase === "running"
                || root.service.timer.phase === "paused"
                || root.service.timer.phase === "break") : false
            timerTaskId: root.service ? String(root.service.timer.taskId || "") : ""
            timerMode: root.service ? String(root.service.timer.mode || "") : ""
            focusAction: root.service && root.service.settings && root.service.settings.focus
                ? String(root.service.settings.focus.focusAction || root.service.settings.focus.action || "pomodoro") : "pomodoro"

            onToggleMenu: root.cardMenu(String(modelData.id))
            onStartFocus: {
                if (!root.service) return
                var timer = root.service.timer
                var focus = root.service.settings && root.service.settings.focus ? root.service.settings.focus : {}
                var action = focus.focusAction === "flowtime" || focus.action === "flowtime" ? "flowtime" : "pomodoro"
                var active = timer.phase === "running" || timer.phase === "paused" || timer.phase === "break"
                if (active && timer.taskId === modelData.id && timer.mode === action) {
                    root.service.setActiveTask(modelData.id)
                    return
                }
                if (active) root.service.stopTimer()
                root.service.setActiveTask(modelData.id)
                if (action === "flowtime") root.service.startFlowtime(modelData.id)
                else root.service.startPomodoro(modelData.id)
            }
            onDone: {
                if (root.service) root.service.completeTask(modelData.id)
            }
            onEditSave: function(title) {
                if (root.service) root.service.updateTask(modelData.id, { title: title })
            }
            onRemove: {
                if (root.service) root.service.deleteTask(modelData.id)
            }
            onDragStarted: {
                root.listFrozen = true
                root.draggedTaskId = String(modelData.id)
            }
            onDragFinished: {
                root.listFrozen = false
                root.draggedTaskId = ""
            }
        }

        Text {
            anchors.centerIn: parent
            textFormat: Text.PlainText
            text: "Empty"
            color: Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            visible: root.panelTasks.length === 0 && !root.editorOpen
        }
    }

    TaskEditor {
        id: editor
        visible: root.editorOpen
        Layout.fillWidth: true
        onSaved: function(title) {
            if (root.service) {
                // Create task with columnId based on panel index
                var taskId = root.service.createTask(title, root.columnId)
                // Add task to end of panel's taskIds for proper ordering
                if (root.panel && root.panel.taskIds) {
                    var newTaskIds = [...root.panel.taskIds, taskId]
                    root.service.reorderPanelTasks(root.panelId, newTaskIds)
                }
            }
            root.editorOpen = false
        }
        onCancelled: root.editorOpen = false
    }

    FlowButton {
        text: "+ Add task"
        visible: !root.editorOpen
        Layout.fillWidth: true
        onClicked: {
            root.editorOpen = true
            Qt.callLater(function() { editor.focusInput(); })
        }
    }
}
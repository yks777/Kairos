import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Commons
import ".."
import "../plan"
import "../../logic/Model.js" as Model

ColumnLayout {
  id: root

  property var service: null
  property var panelCfg: null
  property bool editorOpen: false
  property string menuTaskId: ""
  property bool dropHighlight: false
  property bool listFrozen: false

  signal cardMenu(string taskId)
  signal taskMoved(string taskId, string targetPanelId)

  spacing: Style.space(6)
  Layout.fillWidth: true
  Layout.fillHeight: true
  Layout.minimumWidth: Style.space(200)

  readonly property var columnTasks: {
    if (!root.service || !root.panelCfg) return [];
    var revision = root.service.revision;
    revision;
    var panelId = root.panelCfg.id;
    var boardId = root.panelCfg.boardId;
    var output = [];
    var taskOrder = new Map();
    var panelTaskIds = root.panelCfg.taskIds || [];
    for (var i = 0; i < panelTaskIds.length; i++) {
      if (!taskOrder.has(panelTaskIds[i])) taskOrder.set(panelTaskIds[i], i);
    }

    var allTasks = root.service.tasks || [];
    for (var t = 0; t < allTasks.length; t++) {
      var task = allTasks[t];
      if (task.boardId !== boardId || task.completedAt) continue;
      // Check if task matches panel filters
      if (!root.matchesPanelFilters(task)) continue;
      output.push(task);
    }

    // Sort by manual order first (taskIds), then by sortBy if configured
    var orderedTasks = [];
    var nonOrderedTasks = [];
    output.forEach(function(task) {
      var index = taskOrder.get(task.id);
      if (index !== undefined) {
        orderedTasks[index] = task;
      } else {
        nonOrderedTasks.push(task);
      }
    });

    var merged = [];
    for (var i = 0; i < orderedTasks.length; i++) if (orderedTasks[i]) merged.push(orderedTasks[i]);
    merged = merged.concat(nonOrderedTasks);

    // Apply sortBy if configured
    var sortBy = root.panelCfg.sortBy;
    var sortDir = root.panelCfg.sortDir || "asc";
    if (sortBy) {
      var dir = sortDir === "desc" ? -1 : 1;
      merged.sort(function(a, b) {
        var cmp = 0;
        if (sortBy === "dueDate") {
          var ad = a.dueDay ? new Date(a.dueDay).getTime() : (a.dueWithTime || 0);
          var bd = b.dueDay ? new Date(b.dueDay).getTime() : (b.dueWithTime || 0);
          cmp = (ad || 0) - (bd || 0);
        } else if (sortBy === "created") {
          cmp = (a.createdAt || 0) - (b.createdAt || 0);
        } else if (sortBy === "title") {
          cmp = String(a.title || "").localeCompare(String(b.title || ""));
        } else if (sortBy === "timeEstimate") {
          cmp = (a.timeEstimate || 0) - (b.timeEstimate || 0);
        }
        return dir * cmp;
      });
    }
    return merged;
  }

  function matchesPanelFilters(task) {
    var cfg = root.panelCfg;
    // taskDoneState filter
    if (cfg.taskDoneState === Model.PANEL_TASK_DONE_STATE.Done && !task.completedAt) return false;
    if (cfg.taskDoneState === Model.PANEL_TASK_DONE_STATE.UnDone && task.completedAt) return false;
    // scheduledState filter (simplified - check dueDay/dueWithTime)
    if (cfg.scheduledState === Model.PANEL_SCHEDULED_STATE.Scheduled && !task.dueDay && !task.dueWithTime) return false;
    if (cfg.scheduledState === Model.PANEL_SCHEDULED_STATE.NotScheduled && (task.dueDay || task.dueWithTime)) return false;
    // includedTagIds filter (all must match by default)
    if (cfg.includedTagIds && cfg.includedTagIds.length > 0) {
      var taskTagIds = task.tagIds || [];
      var match = true;
      for (var i = 0; i < cfg.includedTagIds.length; i++) {
        if (taskTagIds.indexOf(cfg.includedTagIds[i]) === -1) { match = false; break; }
      }
      if (!match) return false;
    }
    // excludedTagIds filter (any match excludes)
    if (cfg.excludedTagIds && cfg.excludedTagIds.length > 0) {
      var taskTagIds = task.tagIds || [];
      for (var i = 0; i < cfg.excludedTagIds.length; i++) {
        if (taskTagIds.indexOf(cfg.excludedTagIds[i]) !== -1) return false;
      }
    }
    return true;
  }

  ColumnLayout {
    spacing: 0
    Layout.fillWidth: true

    RowLayout {
      spacing: Style.space(6)
      Layout.alignment: Qt.AlignHCenter

      Text {
        textFormat: Text.PlainText
        text: root.panelCfg ? root.panelCfg.title : "Column"
        color: Color.popups.text
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        font.letterSpacing: 1
        elide: Text.ElideRight
      }

      Text {
        textFormat: Text.PlainText
        text: String(root.columnTasks.length)
        color: Color.muted
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
      }
    }

    Rectangle {
      height: Math.max(1, Style.space(1))
      color: root.dropHighlight ? Color.accent : Color.popups.border
      opacity: root.dropHighlight ? 1.0 : 0.5
      Layout.fillWidth: true
    }
  }

  ListView {
    id: list
    model: root.columnTasks
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
        root.dropHighlight = false;
        if (!drop || !drop.source) return;
        var source = drop.source;
        if (typeof source.endDrag === "function") source.endDrag();
        if (!root.service || !source.task) return;
        var taskId = String(source.task.id || "");
        var fromPanelId = String(source.task._panelId || "");
        if (taskId !== "" && fromPanelId !== root.panelCfg.id) {
          root.taskMoved(taskId, root.panelCfg.id);
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
      _panelId: root.panelCfg.id

      onToggleMenu: root.cardMenu(String(modelData.id))
      onStartFocus: {
        if (!root.service) return;
        var timer = root.service.timer;
        var focus = root.service.settings && root.service.settings.focus ? root.service.settings.focus : {};
        var action = focus.focusAction === "flowtime" || focus.action === "flowtime" ? "flowtime" : "pomodoro";
        var active = timer.phase === "running" || timer.phase === "paused" || timer.phase === "break";
        if (active && timer.taskId === modelData.id && timer.mode === action) {
          root.service.setActiveTask(modelData.id);
          return;
        }
        if (active) root.service.stopTimer();
        root.service.setActiveTask(modelData.id);
        if (action === "flowtime") root.service.startFlowtime(modelData.id);
        else root.service.startPomodoro(modelData.id);
      }
      onDone: {
        if (root.service) root.service.completeTask(modelData.id);
      }
      onEditSave: function(title) {
        if (root.service) root.service.updateTask(modelData.id, { title: title });
      }
      onRemove: {
        if (root.service) root.service.deleteTask(modelData.id);
      }
      onDragStarted: root.listFrozen = true
      onDragFinished: root.listFrozen = false
    }

    Text {
      anchors.centerIn: parent
      textFormat: Text.PlainText
      text: "Empty"
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      visible: root.columnTasks.length === 0 && !root.editorOpen
    }
  }

  TaskEditor {
    id: editor
    visible: root.editorOpen
    Layout.fillWidth: true
    onSaved: function(title) {
      if (root.service) {
        var taskId = root.service.createTask(title, "q1"); // columnId will be updated by moveTaskToPanel
        if (taskId) root.service.moveTaskToPanel(taskId, root.panelCfg.id);
      }
      root.editorOpen = false;
    }
    onCancelled: root.editorOpen = false
  }

  FlowButton {
    text: "+ Add task"
    visible: !root.editorOpen
    Layout.fillWidth: true
    onClicked: {
      root.editorOpen = true;
      Qt.callLater(function() { editor.focusInput(); });
    }
  }
}
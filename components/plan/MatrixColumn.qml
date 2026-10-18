import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Commons
import ".."

ColumnLayout {
  id: root

  property var service: null
  property string columnId: "q1"
  property string title: "Q1 · DO"
  property string subtitle: ""
  property bool editorOpen: false
  property string menuTaskId: ""
  property bool dropHighlight: false
  property bool listFrozen: false

  signal cardMenu(string taskId)

  spacing: Style.space(6)
  Layout.fillWidth: true
  Layout.fillHeight: true

  readonly property var columnTasks: {
    if (!root.service) return [];
    root.service.revision;
    return root.service.tasksForColumn(root.columnId);
  }

  ColumnLayout {
    spacing: 0
    Layout.fillWidth: true

    RowLayout {
      spacing: Style.space(6)
      Layout.alignment: Qt.AlignHCenter

      Text {
        textFormat: Text.PlainText
        text: root.title
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

    Text {
      textFormat: Text.PlainText
      text: root.subtitle
      color: Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      visible: root.subtitle !== ""
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
        var fromColumn = String(source.task.columnId || "");
        if (taskId !== "" && fromColumn !== root.columnId) root.service.moveTask(taskId, root.columnId);
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
        if (!root.service) return;
        root.service.setActiveTask(modelData.id);
        var focus = root.service.settings && root.service.settings.focus ? root.service.settings.focus : {};
        var action = focus.focusAction === "flowtime" || focus.action === "flowtime" ? "flowtime" : "pomodoro";
        if (root.service.timer.phase === "running" || root.service.timer.phase === "paused" || root.service.timer.phase === "break") {
          if (root.service.timer.taskId === modelData.id && root.service.timer.mode === action) {
            return;
          }
          root.service.stopTimer();
          root.service.setActiveTask(modelData.id);
          if (action === "flowtime") root.service.startFlowtime(modelData.id);
          else root.service.startPomodoro(modelData.id);
        }
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
      onDragStarted: root.listFrozen = true;
      onDragFinished: root.listFrozen = false;
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
      if (root.service) root.service.createTask(title, root.columnId);
      root.editorOpen = false;
    }
    onCancelled: root.editorOpen = false
  }

  onEditorOpenChanged: {
    if (root.editorOpen) Qt.callLater(function() { editor.focusInput(); });
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

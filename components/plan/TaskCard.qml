import QtQuick
import QtQuick.Layouts
import qs.Commons
import ".."
import "../../logic/Model.js" as Model

Rectangle {
  id: root

  property var task: null
  property bool isActive: false
  property bool menuOpen: false
  property bool timerLive: false
  property string timerTaskId: ""
  property string timerMode: ""
  property string focusAction: "pomodoro"
  property bool confirmingDelete: false
  property bool confirmingSwitch: false
  property bool editing: false
  property bool dragging: false
  property bool dragPerformed: false
  property string dragImage: ""

  signal toggleMenu()
  signal startFocus()
  signal done()
  signal editSave(string title)
  signal remove()
  signal dragStarted()
  signal dragFinished()

  implicitWidth: Style.space(200)
  implicitHeight: main.implicitHeight + Style.space(16)
  Layout.fillWidth: true
  radius: Style.cornerRadius
  color: "transparent"
  border.color: root.dragging ? Color.accent
    : (root.menuOpen ? Color.accent : (hoverArea.containsMouse ? Color.popups.border : "transparent"))
  border.width: Math.max(1, Style.space(1))
  opacity: root.dragging ? 0.7 : 1.0

  Drag.active: root.dragging
  Drag.source: root
  Drag.imageSource: root.dragImage
  Drag.hotSpot.x: width / 2
  Drag.hotSpot.y: Style.space(16)
  Drag.supportedActions: Qt.MoveAction

  function beginDrag() {
    if (root.editing || root.dragging || !root.task) return;
    root.dragPerformed = true;
    if (root.menuOpen) root.toggleMenu();
    root.dragging = true;
    root.dragStarted();
    try {
      root.grabToImage(function(result) {
        if (root.dragging && result && result.url) root.dragImage = String(result.url);
      });
    } catch (error) {
      root.dragImage = "";
    }
  }

  function endDrag() {
    if (!root.dragging) return;
    root.dragging = false;
    root.dragImage = "";
    root.dragFinished();
  }

  function startEditing() {
    root.confirmingSwitch = false;
    root.confirmingDelete = false;
    titleEditor.text = root.task ? String(root.task.title || "") : "";
    root.editing = true;
    Qt.callLater(function() { titleEditor.focusInput(); });
  }

  Rectangle {
    anchors.fill: parent
    radius: parent.radius
    color: Color.accent
    opacity: root.isActive ? 0.10 : 0.0
  }

  MouseArea {
    id: clickCatcher
    anchors.fill: parent
    pressAndHoldInterval: 350
    preventStealing: true
    cursorShape: root.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
    onPressed: root.dragPerformed = false
    onClicked: {
      if (root.editing || root.dragging) return;
      if (root.dragPerformed) { root.dragPerformed = false; return; }
      root.confirmingDelete = false;
      root.confirmingSwitch = false;
      root.toggleMenu();
    }
    onPressAndHold: root.beginDrag()
    onReleased: root.endDrag()
    onCanceled: root.endDrag()
  }

  ColumnLayout {
    id: main
    anchors.fill: parent
    anchors.margins: Style.space(8)
    spacing: Style.space(6)

    RowLayout {
      spacing: Style.space(6)
      Layout.fillWidth: true

      Rectangle {
        width: Style.space(8)
        height: width
        radius: width / 2
        color: !root.task ? Color.muted
          : root.task.priority === "high" ? Color.urgent
          : root.task.priority === "low" ? Color.muted : Color.accent
        Layout.alignment: Qt.AlignVCenter
      }

      Text {
        textFormat: Text.PlainText
        text: root.task ? String(root.task.title || "") : ""
        color: Color.popups.text
        font.family: Style.font.family
        font.pixelSize: Style.font.bodySmall
        elide: Text.ElideRight
        maximumLineCount: 2
        wrapMode: Text.Wrap
        Layout.fillWidth: true
        visible: !root.editing
      }

      FlowInput {
        id: titleEditor
        text: root.task ? String(root.task.title || "") : ""
        placeholder: "Task title..."
        visible: root.editing
        Layout.fillWidth: true
        onAccepted: {
          root.editing = false;
          root.editSave(String(titleEditor.text || "").trim());
        }
        onCancelled: root.editing = false
      }

      Text {
        textFormat: Text.PlainText
        text: root.task ? Model.formatDur(root.task.totalFocusSeconds) : ""
        color: Color.muted
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        visible: root.task && Number(root.task.totalFocusSeconds) > 0 && !root.editing
      }

      Rectangle {
        width: Style.space(7)
        height: width
        radius: width / 2
        color: Color.accent
        visible: root.isActive
      }
    }

    ColumnLayout {
      spacing: Style.space(4)
      Layout.fillWidth: true
      visible: (hoverArea.containsMouse || root.menuOpen) && !root.editing

      RowLayout {
        spacing: Style.space(4)
        Layout.alignment: Qt.AlignHCenter

        MiniAction {
          label: root.confirmingSwitch ? "Switch?" : "Focus"
          accent: true
          onClicked: {
            var switching = root.timerLive
              && (root.timerTaskId !== String(root.task ? root.task.id : "") || root.timerMode !== root.focusAction);
            if (switching && !root.confirmingSwitch) root.confirmingSwitch = true;
            else {
              root.confirmingSwitch = false;
              root.startFocus();
            }
          }
        }

        MiniAction {
          label: "Done"
          onClicked: {
            root.confirmingSwitch = false;
            root.confirmingDelete = false;
            root.done();
          }
        }
      }

      RowLayout {
        spacing: Style.space(4)
        Layout.alignment: Qt.AlignHCenter

        MiniAction {
          label: "Edit"
          onClicked: root.startEditing()
        }

        MiniAction {
          label: root.confirmingDelete ? "Confirm delete" : "Delete"
          danger: true
          onClicked: {
            root.confirmingSwitch = false;
            if (root.confirmingDelete) {
              root.confirmingDelete = false;
              root.remove();
            } else root.confirmingDelete = true;
          }
        }
      }
    }
  }

  component MiniAction: Item {
    id: mini
    property string label: ""
    property bool accent: false
    property bool danger: false
    signal clicked()

    implicitWidth: Math.max(Style.space(56), miniLabel.implicitWidth + Style.space(16))
    implicitHeight: Style.space(28)

    Rectangle {
      anchors.fill: parent
      radius: Style.cornerRadius
      color: mini.danger ? Color.urgent : Color.accent
      opacity: hoverMini.containsMouse ? 0.25 : 0.10
    }

    Text {
      id: miniLabel
      anchors.centerIn: parent
      textFormat: Text.PlainText
      text: mini.label
      color: mini.danger ? Color.urgent : (mini.accent ? Color.accent : Color.popups.text)
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }

    MouseArea {
      id: hoverMini
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: mini.clicked()
    }
  }

  MouseArea {
    id: hoverArea
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.NoButton
  }
}

import QtQuick
import QtQuick.Layouts
import qs.Commons
import ".."

ColumnLayout {
  id: root

  property var tasks: []
  property bool obsidianEnabled: false
  property bool busy: false
  signal taskToggled(int lineIndex)
  signal addRequested()

  spacing: Style.space(6)
  Layout.fillWidth: true

  Repeater {
    model: root.tasks || []
    delegate: RowLayout {
      id: taskRow
      required property var modelData
      property var task: modelData
      spacing: Style.space(8)
      Layout.fillWidth: true

      FlowIconButton {
        glyph: taskRow.task.checked ? "\uDB80\uDD35" : "\uDB80\uDD31"
        tip: taskRow.task.checked ? "Mark task incomplete" : "Mark task complete"
        boxSize: Style.space(26)
        onClicked: root.taskToggled(taskRow.task.lineIndex)
      }

      Text {
        textFormat: Text.PlainText
        text: String(taskRow.task.text || "")
        color: taskRow.task.checked ? Color.muted : Color.popups.text
        font.family: Style.font.family
        font.pixelSize: Style.font.bodySmall
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
      }
    }
  }

  Text {
    visible: root.obsidianEnabled && root.busy
    textFormat: Text.PlainText
    text: root.tasks && root.tasks.length > 0 ? "Saving daily note..." : "Loading daily note..."
    color: Color.muted
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
    Layout.fillWidth: true
    Layout.leftMargin: Style.space(4)
  }

  Text {
    visible: root.obsidianEnabled && !root.busy && (!root.tasks || root.tasks.length === 0)
    textFormat: Text.PlainText
    text: "No tasks in this daily note."
    color: Color.muted
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
    Layout.fillWidth: true
    Layout.leftMargin: Style.space(4)
  }

  RowLayout {
    visible: root.obsidianEnabled
    Layout.fillWidth: true
    spacing: Style.space(8)

    FlowButton {
      text: "+ Add"
      primary: true
      enabledButton: root.obsidianEnabled && !root.busy
      onClicked: root.addRequested()
    }

    Item { Layout.fillWidth: true }
  }

  Text {
    visible: !root.obsidianEnabled
    textFormat: Text.PlainText
    text: "Enable Obsidian in Settings to use daily notes."
    color: Color.muted
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
    wrapMode: Text.WordWrap
    Layout.fillWidth: true
    Layout.leftMargin: Style.space(4)
  }
}

import QtQuick
import QtQuick.Layouts
import qs.Commons
import ".."

ColumnLayout {
  id: root

  property var events: []
  property var service: null
  property string statusText: ""
  property string emptyText: "Nothing scheduled."

  spacing: Style.space(6)
  Layout.fillWidth: true

  Repeater {
    model: root.events || []
    delegate: EventCard {
      required property var modelData
      event: modelData
      service: root.service
      Layout.fillWidth: true
    }
  }

  Text {
    visible: !root.events || root.events.length === 0
    textFormat: Text.PlainText
    text: root.statusText !== "" ? root.statusText : root.emptyText
    color: root.statusText !== "" ? Color.urgent : Color.muted
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
    wrapMode: Text.WordWrap
    Layout.fillWidth: true
    Layout.leftMargin: Style.space(4)
  }
}

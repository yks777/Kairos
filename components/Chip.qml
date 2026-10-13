import QtQuick
import qs.Commons

Item {
  id: root
  property string label: ""
  property bool active: false
  signal clicked()

  implicitWidth: Math.max(Style.space(72), chipLabel.implicitWidth + Style.space(16))
  implicitHeight: Style.space(26)

  Rectangle {
    anchors.fill: parent
    radius: Style.cornerRadius
    color: Color.accent
    opacity: root.active ? 0.22 : (hitArea.containsMouse ? 0.12 : 0.0)
    border.color: root.active ? Color.accent : Color.popups.border
    border.width: Math.max(1, Style.space(1))
  }

  Text {
    id: chipLabel
    anchors.centerIn: parent
    textFormat: Text.PlainText
    text: root.label
    color: root.active ? Color.accent : Color.muted
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
  }

  MouseArea {
    id: hitArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}

import QtQuick
import qs.Commons

Rectangle {
  id: root
  property string text: ""
  property bool primary: false
  property bool enabledButton: true
  property string tip: ""
  signal clicked()

  implicitWidth: Math.max(Style.space(64), label.implicitWidth + Style.space(24))
  implicitHeight: Style.space(32)
  radius: Style.cornerRadius
  opacity: root.enabledButton ? 1.0 : 0.45
  color: "transparent"
  border.color: root.primary ? Color.accent : Color.popups.border
  border.width: Math.max(1, Style.space(1))

  Rectangle {
    anchors.fill: parent
    anchors.margins: parent.border.width
    radius: Math.max(0, parent.radius - parent.border.width)
    color: Color.accent
    opacity: root.primary ? 0.22 : (hitArea.containsMouse ? 0.12 : 0.0)
  }

  Text {
    id: label
    anchors.centerIn: parent
    textFormat: Text.PlainText
    text: root.text
    color: root.primary ? Color.accent : Color.popups.text
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
  }

  MouseArea {
    id: hitArea
    anchors.fill: parent
    enabled: root.enabledButton
    hoverEnabled: true
    cursorShape: root.enabledButton ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: root.clicked()
  }
}

import QtQuick
import qs.Commons

Item {
  id: root
  property string glyph: ""
  property int boxSize: Style.space(32)
  property bool highlighted: false
  property string tip: ""
  signal clicked()

  implicitWidth: boxSize
  implicitHeight: boxSize

  Rectangle {
    anchors.fill: parent
    radius: Style.cornerRadius
    color: Color.accent
    opacity: (hitArea.containsMouse || root.highlighted) ? 0.18 : 0.0
  }

  Text {
    anchors.centerIn: parent
    textFormat: Text.PlainText
    text: root.glyph
    color: root.highlighted ? Color.accent : Color.popups.text
    font.family: Style.font.family
    font.pixelSize: Style.font.title
  }

  MouseArea {
    id: hitArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}

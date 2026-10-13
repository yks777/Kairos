import QtQuick
import QtQuick.Layouts
import qs.Commons

ColumnLayout {
  id: section
  property string title: ""
  spacing: Style.space(8)
  Layout.fillWidth: true
  Layout.leftMargin: Style.space(4)
  Layout.rightMargin: Style.space(4)

  Text {
    textFormat: Text.PlainText
    text: section.title.toUpperCase()
    color: Color.muted
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    font.letterSpacing: 1
    horizontalAlignment: Text.AlignHCenter
    Layout.fillWidth: true
  }

  Rectangle {
    height: Math.max(1, Style.space(1))
    color: Color.popups.border
    opacity: 0.5
    Layout.fillWidth: true
  }
}

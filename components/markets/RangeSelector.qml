import QtQuick
import QtQuick.Layouts
import qs.Commons

RowLayout {
  id: root
  property string currentRange: "1d"
  signal rangeSelected(string range)

  spacing: Style.space(2)
  Layout.fillWidth: true

  readonly property var ranges: [
    { id: "1h", label: "1H" },
    { id: "4h", label: "4H" },
    { id: "1d", label: "1D" },
    { id: "5d", label: "5D" },
    { id: "1mo", label: "1M" },
    { id: "3mo", label: "3M" },
    { id: "6mo", label: "6M" },
    { id: "ytd", label: "YTD" },
    { id: "1y", label: "1Y" },
    { id: "5y", label: "5Y" },
    { id: "max", label: "MAX" }
  ]

  Repeater {
    model: root.ranges
    delegate: Item {
      required property var modelData
      implicitWidth: rangeLabel.implicitWidth + Style.space(8)
      implicitHeight: Style.space(24)

      Rectangle {
        anchors.fill: parent
        radius: Style.cornerRadius
        color: Color.accent
        opacity: root.currentRange === modelData.id ? 0.20 : (hitArea.containsMouse ? 0.10 : 0.0)
      }
      Text {
        id: rangeLabel
        anchors.centerIn: parent
        textFormat: Text.PlainText
        text: modelData.label
        color: root.currentRange === modelData.id ? Color.accent : Color.muted
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
      }
      MouseArea {
        id: hitArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.rangeSelected(modelData.id)
      }
    }
  }
}

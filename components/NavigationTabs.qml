import QtQuick
import QtQuick.Layouts
import qs.Commons

RowLayout {
  id: root
  property string currentView: "day"
  signal selectView(string view)

  spacing: Style.space(4)
  Layout.fillWidth: true

  Repeater {
   model: [
     { id: "day", label: "Day" },
     { id: "focus", label: "Focus" },
     { id: "plan", label: "Plan" },
     { id: "stats", label: "Stats" },
     { id: "markets", label: "Markets" }
   ]

    delegate: Item {
      id: tab
      required property var modelData
      Layout.fillWidth: true
      implicitHeight: Style.space(32)

      Rectangle {
        anchors.fill: parent
        radius: Style.cornerRadius
        color: Color.accent
        opacity: root.currentView === tab.modelData.id ? 0.20 : (hitArea.containsMouse ? 0.12 : 0.0)
      }

      Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: Math.max(1, Style.space(2))
        color: Color.accent
        visible: root.currentView === tab.modelData.id
      }

      Text {
        anchors.centerIn: parent
        textFormat: Text.PlainText
        text: tab.modelData.label
        color: root.currentView === tab.modelData.id ? Color.accent : Color.muted
        font.family: Style.font.family
        font.pixelSize: Style.font.bodySmall
      }

      MouseArea {
        id: hitArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.selectView(tab.modelData.id)
      }
    }
  }
}

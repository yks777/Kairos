import QtQuick
import qs.Commons

Rectangle {
  id: root
  property var service: null

  implicitWidth: chipLabel.implicitWidth + Style.space(16)
  implicitHeight: Style.space(26)
  radius: Style.cornerRadius
  color: "transparent"
  border.color: Color.popups.border
  border.width: Math.max(1, Style.space(1))

  Text {
    id: chipLabel
    anchors.centerIn: parent
    textFormat: Text.PlainText
    text: (root.service ? String(root.service.currency || "USD") : "USD") + "  \uDB82\uDE0A"
    color: Color.popups.text
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: function(mouse) {
      if (root.service && typeof root.service.cycleCurrency === "function")
        root.service.cycleCurrency(mouse.button === Qt.RightButton ? -1 : 1);
    }
  }
}

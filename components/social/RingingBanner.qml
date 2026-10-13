import QtQuick
import QtQuick.Layouts
import qs.Commons
import ".."

Rectangle {
  id: root
  property var call: null
  property var service: null
  implicitHeight: banner.implicitHeight + Style.space(16)
  radius: Style.cornerRadius
  color: Util.alpha(Color.accent, 0.15)
  border.color: Color.accent
  border.width: Math.max(1, Style.space(1))
  Layout.fillWidth: true
  ColumnLayout {
    id: banner
    anchors.fill: parent
    anchors.margins: Style.space(8)
    spacing: Style.space(8)
    RowLayout {
      spacing: Style.space(8)
      Layout.fillWidth: true
      Text { textFormat: Text.PlainText; text: "\uf095"; color: Color.accent; font.family: Style.font.family; font.pixelSize: Style.font.title }
      Text { textFormat: Text.PlainText; text: root.call ? ("Now ringing · " + root.call.name + " (" + root.call.accountName + ")") : ""; color: Color.popups.text; font.family: Style.font.family; font.pixelSize: Style.font.bodySmall; Layout.fillWidth: true; elide: Text.ElideRight }
    }
    RowLayout {
      spacing: Style.space(8)
      Layout.alignment: Qt.AlignHCenter
      FlowButton { text: "Answer"; primary: true; onClicked: if (root.service && root.call) root.service.socialAnswerCall(root.call) }
      FlowButton { text: "Decline"; onClicked: if (root.service && root.call) root.service.socialDeclineCall(root.call) }
    }
  }
}
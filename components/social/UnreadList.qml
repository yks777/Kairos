import QtQuick
import QtQuick.Layouts
import qs.Commons

ListView {
  id: root
  property var items: []
  property var service: null
  property string emptyText: "No unread messages."
  signal itemSelected(var item)
  model: root.items
  spacing: Style.space(3)
  clip: true
  boundsBehavior: Flickable.StopAtBounds
  Layout.fillWidth: true
  Layout.fillHeight: true
  delegate: Rectangle {
    required property var modelData
    width: root.width
    implicitHeight: Math.max(Style.space(34), row.implicitHeight + Style.space(10))
    radius: Style.cornerRadius
    color: hover.containsMouse ? Util.alpha(Color.muted, 0.08) : "transparent"
    RowLayout { id: row; anchors.fill: parent; anchors.leftMargin: Style.space(8); anchors.rightMargin: Style.space(8); spacing: Style.space(7); Rectangle { width: Style.space(8); height: width; radius: width / 2; color: Color.accent; Layout.alignment: Qt.AlignVCenter } Text { textFormat: Text.PlainText; text: modelData.name + " (" + modelData.accountName + ")"; color: Color.popups.text; font.family: Style.font.family; font.pixelSize: Style.font.bodySmall; Layout.preferredWidth: Style.space(160); elide: Text.ElideRight } Text { textFormat: Text.PlainText; text: modelData.preview || (modelData.kind === "email" ? "New email" : "New message"); color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; elide: Text.ElideRight; Layout.fillWidth: true } Text { textFormat: Text.PlainText; text: modelData.unread > 1 ? String(modelData.unread) + " · " + (modelData.timeLabel || "") : (modelData.timeLabel || ""); color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption } }
    MouseArea { id: hover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.itemSelected(modelData) }
  }
  Text { anchors.centerIn: parent; width: parent.width - Style.space(20); visible: root.items.length === 0; textFormat: Text.PlainText; text: root.emptyText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; font.italic: true; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap }
}
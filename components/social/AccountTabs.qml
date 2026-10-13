import QtQuick
import QtQuick.Layouts
import qs.Commons
import ".."

Flickable {
  id: root
  property var accounts: []
  property string activeId: "all"
  signal accountSelected(string id)
  Layout.fillWidth: true
  implicitHeight: Style.space(32)
  contentWidth: tabs.implicitWidth
  contentHeight: height
  clip: true
  flickableDirection: Flickable.HorizontalFlick
  boundsBehavior: Flickable.StopAtBounds
  RowLayout { id: tabs; spacing: Style.space(4); height: root.height; Chip { label: "All"; active: root.activeId === "all"; onClicked: root.accountSelected("all") } Repeater { model: root.accounts; delegate: Chip { required property var modelData; label: (modelData.glyph ? modelData.glyph + " " : "") + modelData.name; active: root.activeId === modelData.id; onClicked: root.accountSelected(modelData.id) } } }
}
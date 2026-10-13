import QtQuick
import QtQuick.Layouts
import qs.Commons

ColumnLayout {
  id: root
  property var calls: []
  spacing: Style.space(3)
  Layout.fillWidth: true
  Repeater { model: root.calls; delegate: RowLayout { required property var modelData; spacing: Style.space(8); Layout.fillWidth: true; Text { textFormat: Text.PlainText; text: modelData.glyph || ""; color: modelData.kind === "missed" ? Color.urgent : (modelData.kind === "outgoing" ? Color.accent : Color.muted); font.family: Style.font.family; font.pixelSize: Style.font.bodySmall } Text { textFormat: Text.PlainText; text: modelData.kindLabel + " · " + modelData.name + " (" + modelData.accountName + ")"; color: Color.popups.text; font.family: Style.font.family; font.pixelSize: Style.font.bodySmall; Layout.fillWidth: true; elide: Text.ElideRight } Text { textFormat: Text.PlainText; text: modelData.timeLabel || ""; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption } } }
}
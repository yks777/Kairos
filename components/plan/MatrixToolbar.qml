import QtQuick
import QtQuick.Layouts
import qs.Commons
import ".."

RowLayout {
  id: root

  property var service: null
  signal openCompleted()

  spacing: Style.space(8)
  Layout.fillWidth: true

  readonly property int doneCount: {
    if (!root.service) return 0;
    var revision = root.service.revision;
    revision;
    return root.service.completedCount();
  }

  Text {
    textFormat: Text.PlainText
    text: "MATRIX"
    color: Color.popups.text
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    font.letterSpacing: 1
  }

  Item { Layout.fillWidth: true }

  FlowButton {
    text: "Completed (" + root.doneCount + ")"
    onClicked: root.openCompleted()
  }
}

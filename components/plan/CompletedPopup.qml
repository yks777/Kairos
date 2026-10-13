import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Commons
import ".."

Item {
  id: root

  property string query: ""
  property var items: []
  property var service: null
  signal queryInputChanged(string value)
  signal close()

  anchors.fill: parent
  z: 30

  Rectangle {
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.55)

    MouseArea {
      anchors.fill: parent
      onClicked: root.close()
    }
  }

  Rectangle {
    id: card
    anchors.centerIn: parent
    width: Math.max(0, Math.min(parent.width - Style.space(24), Style.space(420)))
    height: Math.max(0, Math.min(parent.height - Style.space(24), Style.space(380)))
    radius: Style.cornerRadius
    color: Color.popups.background
    border.color: Color.popups.border
    border.width: Math.max(1, Style.space(1))

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.space(12)
      spacing: Style.space(8)

      RowLayout {
        spacing: Style.space(8)
        Layout.fillWidth: true

        Text {
          textFormat: Text.PlainText
          text: "COMPLETED (" + root.items.length + ")"
          color: Color.popups.text
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          font.letterSpacing: 1
          Layout.fillWidth: true
        }

        FlowIconButton {
          glyph: "×"
          tip: "Close completed tasks"
          onClicked: root.close()
        }
      }

      FlowInput {
        id: search
        placeholder: "Search completed..."
        text: root.query
        Layout.fillWidth: true
        onTextChanged: root.queryInputChanged(text)
      }

      ListView {
        id: list
        model: root.items
        spacing: Style.space(6)
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        Layout.fillWidth: true
        Layout.fillHeight: true

        ScrollBar.vertical: ScrollBar {
          policy: ScrollBar.AsNeeded
          visible: list.contentHeight > list.height + 1
          background: Item { implicitWidth: Style.space(6) }
          contentItem: Rectangle {
            implicitWidth: Style.space(6)
            radius: width / 2
            color: Color.muted
          }
        }

        delegate: Rectangle {
          required property var modelData
          width: list.width
          implicitHeight: row.implicitHeight + Style.space(12)
          radius: Style.cornerRadius
          color: "transparent"
          border.color: Color.popups.border
          border.width: Math.max(1, Style.space(1))

          RowLayout {
            id: row
            anchors.fill: parent
            anchors.margins: Style.space(8)
            spacing: Style.space(8)

            Text {
              textFormat: Text.PlainText
              text: String(modelData.title || "")
              color: Color.popups.text
              font.family: Style.font.family
              font.pixelSize: Style.font.bodySmall
              elide: Text.ElideRight
              Layout.fillWidth: true
            }

            FlowButton {
              text: "Restore"
              onClicked: {
                if (root.service) root.service.reopenTask(modelData.id);
                root.close();
              }
            }

            FlowIconButton {
              glyph: "×"
              tip: "Delete completed task"
              onClicked: if (root.service) root.service.deleteTask(modelData.id)
            }
          }
        }

        Text {
          anchors.centerIn: parent
          textFormat: Text.PlainText
          text: root.query !== "" ? "No matches" : "Nothing completed yet"
          color: Color.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          visible: root.items.length === 0
        }
      }
    }
  }

  onQueryChanged: {
    if (search.text !== root.query) search.text = root.query;
  }
}

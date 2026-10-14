import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Commons
import ".."

RowLayout {
  id: root
  property var boards: []
  property string activeBoardId: ""
  property var service: null
  property bool addBoardHovered: false

  signal selectBoard(string boardId)
  signal createBoard()
  signal editBoard(string boardId)
  signal deleteBoard(string boardId)

  spacing: Style.space(2)
  Layout.fillWidth: true
  Layout.maximumHeight: Style.space(36)

  Repeater {
    model: root.boards
    delegate: Item {
      id: tab
      required property var modelData
      Layout.fillWidth: true
      implicitHeight: Style.space(32)

      Rectangle {
        id: tabBg
        anchors.fill: parent
        radius: Style.cornerRadius
        color: Color.accent
        opacity: root.activeBoardId === tab.modelData.id ? 0.20 : (hitArea.containsMouse ? 0.12 : 0.0)
      }

      Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: Math.max(1, Style.space(2))
        color: Color.accent
        visible: root.activeBoardId === tab.modelData.id
      }

      RowLayout {
        anchors.fill: parent
        anchors.margins: Style.space(8)
        spacing: Style.space(6)

        Text {
          textFormat: Text.PlainText
          text: tab.modelData.title
          color: root.activeBoardId === tab.modelData.id ? Color.accent : Color.popups.text
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
          elide: Text.ElideRight
          Layout.fillWidth: true
        }

        FlowIconButton {
          glyph: "⋮"
          tip: "Board options"
          visible: hitArea.containsMouse || root.activeBoardId === tab.modelData.id
          onClicked: {
            contextMenu.popup();
          }
        }
      }

      MouseArea {
        id: hitArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.selectBoard(tab.modelData.id)
      }

      Menu {
        id: contextMenu
        MenuItem {
          text: "Rename"
          onTriggered: root.editBoard(tab.modelData.id)
        }
        MenuItem {
          text: "Delete"
          enabled: root.boards.length > 1
          onTriggered: root.deleteBoard(tab.modelData.id)
        }
      }
    }
  }

  // Add board button
  Item {
    id: addTab
    Layout.fillWidth: true
    implicitHeight: Style.space(32)
    Layout.maximumWidth: Style.space(36)

    Rectangle {
      id: addBg
      anchors.fill: parent
      anchors.margins: Style.space(4)
      radius: Style.cornerRadius
      color: Color.accent
      opacity: addArea.containsMouse ? 0.12 : 0.0
    }

    Rectangle {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      anchors.margins: Style.space(4)
      height: Math.max(1, Style.space(2))
      color: Color.accent
      opacity: 0.5
    }

    Text {
      anchors.centerIn: parent
      textFormat: Text.PlainText
      text: "+"
      color: addArea.containsMouse ? Color.accent : Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.body
    }

    MouseArea {
      id: addArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.createBoard()
      onEntered: addBoardHovered = true
      onExited: addBoardHovered = false
    }
  }
}
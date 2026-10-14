import QtQuick
import QtQuick.Layouts
import qs.Commons
import "."
import ".."

Item {
  id: root

  property var service: null
  property string menuTaskId: ""
  property bool configDialogOpen: false
  property var configPanelId: null

  Layout.fillWidth: true
  Layout.fillHeight: true

  function toggleCardMenu(taskId) {
    root.menuTaskId = root.menuTaskId === taskId ? "" : taskId;
  }

  function openPanelConfig(panelId) {
    root.configPanelId = panelId;
    root.configDialogOpen = true;
  }

  ColumnLayout {
    anchors.fill: parent
    spacing: Style.space(8)

    // Board tabs
    BoardTabs {
      id: boardTabs
      boards: root.service ? root.service.boards : []
      activeBoardId: root.service ? root.service.activeBoardId : ""
      service: root.service
      onSelectBoard: function(boardId) {
        if (root.service) root.service.setActiveBoard(boardId);
      }
      onCreateBoard: function() {
        if (root.service) root.service.createBoard("");
      }
      onEditBoard: function(boardId) {
        // Could open a dialog to rename
        console.log("Edit board:", boardId);
      }
      onDeleteBoard: function(boardId) {
        if (root.service) root.service.deleteBoard(boardId);
      }
      Layout.fillWidth: true
    }

    // Board columns
    Item {
      id: boardContent
      Layout.fillWidth: true
      Layout.fillHeight: true
      visible: root.service && root.service.activeBoardId

      readonly property var activePanels: {
        if (!root.service) return [];
        var revision = root.service.revision;
        revision;
        return root.service.panelsForBoard(root.service.activeBoardId);
      }

      RowLayout {
        id: columnsRow
        spacing: Style.space(8)
        Layout.fillWidth: true
        Layout.fillHeight: true

        Repeater {
          model: boardContent.activePanels
          delegate: BoardColumn {
            required property var modelData
            service: root.service
            panelCfg: modelData
            menuTaskId: root.menuTaskId
            onCardMenu: function(taskId) { root.toggleCardMenu(taskId); }
            onTaskMoved: function(taskId, targetPanelId) {
              if (root.service) root.service.moveTaskToPanel(taskId, targetPanelId);
            }
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: Style.space(200)
            Layout.maximumWidth: Style.space(400)
          }
        }

        // Drop area for creating new column (shown when no panels or at end)
        DropArea {
          id: newColumnDropArea
          Layout.fillWidth: true
          Layout.fillHeight: true
          Layout.minimumWidth: Style.space(120)
          Layout.maximumWidth: Style.space(120)
          visible: boardContent.activePanels.length === 0
          onEntered: { }
          onExited: { }
          onDropped: function(drop) {
            // Not used for now
          }

          Rectangle {
            anchors.fill: parent
            anchors.margins: Style.space(8)
            radius: Style.cornerRadius
            border.color: Color.accent
            border.width: Style.space(2)
            color: "transparent"

            ColumnLayout {
              anchors.centerIn: parent
              spacing: Style.space(8)

              Text {
                textFormat: Text.PlainText
                text: "+ Add Column"
                color: Color.accent
                font.family: Style.font.family
                font.pixelSize: Style.font.bodySmall
              }

              FlowButton {
                text: "Create Column"
                onClicked: {
                  if (root.service) root.service.createPanel(root.service.activeBoardId, "");
                }
              }
            }
          }
        }
      }
    }

    // Empty state when no boards
    Item {
      Layout.fillWidth: true
      Layout.fillHeight: true
      visible: !root.service || !root.service.activeBoardId

      ColumnLayout {
        anchors.centerIn: parent
        spacing: Style.space(16)

        Text {
          textFormat: Text.PlainText
          text: "No boards yet"
          color: Color.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.body
        }

        FlowButton {
          text: "Create First Board"
          onClicked: {
            if (root.service) root.service.createBoard("");
          }
        }
      }
    }
  }

  // Panel config dialog (simplified - just shows panel title for now)
  Rectangle {
    id: configOverlay
    visible: root.configDialogOpen
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.55)
    z: 20

    MouseArea {
      anchors.fill: parent
      onClicked: { root.configDialogOpen = false; root.configPanelId = null; }
    }

    Rectangle {
      id: configCard
      anchors.centerIn: parent
      width: Math.max(0, Math.min(parent.width - Style.space(24), Style.space(360)))
      radius: Style.cornerRadius
      color: Color.popups.background
      border.color: Color.popups.border
      border.width: Math.max(1, Style.space(1))

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.space(16)
        spacing: Style.space(12)

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(8)

          Text {
            textFormat: Text.PlainText
            text: "COLUMN SETTINGS"
            color: Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.letterSpacing: 1
            Layout.fillWidth: true
          }

          FlowIconButton {
            glyph: "×"
            tip: "Close"
            onClicked: { root.configDialogOpen = false; root.configPanelId = null; }
          }
        }

        Text {
          textFormat: Text.PlainText
          text: root.configPanelId ? "Panel: " + root.configPanelId : "No panel selected"
          color: Color.popups.text
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
          Layout.fillWidth: true
        }

        FlowButton {
          text: "Close"
          onClicked: { root.configDialogOpen = false; root.configPanelId = null; }
        }
      }
    }
  }
}
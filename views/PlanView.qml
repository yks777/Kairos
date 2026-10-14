import QtQuick
import QtQuick.Layouts
import qs.Commons
import "../components/plan"

Item {
  id: root

  property var service: null
  property string menuTaskId: ""
  property bool completedOpen: false
  property string completedQuery: ""

  Layout.fillWidth: true
  Layout.fillHeight: true

  function toggleCardMenu(taskId) {
    root.menuTaskId = root.menuTaskId === taskId ? "" : taskId;
  }

  readonly property var doneList: {
    if (!root.completedOpen || !root.service) return [];
    var revision = root.service.revision;
    revision;
    return root.service.completedTasks(root.completedQuery);
  }

  ColumnLayout {
    anchors.fill: parent
    spacing: Style.space(8)

    MatrixToolbar {
      service: root.service
      onOpenCompleted: {
        root.completedQuery = "";
        root.completedOpen = true;
      }
    }

    RowLayout {
      spacing: Style.space(8)
      Layout.fillWidth: true
      Layout.fillHeight: true

      // Dynamic board columns based on panels
      Repeater {
        model: service.panelsForBoard(service.activeBoardId)
        BoardColumn {
          panelId: modelData.id
          service: root.service
          onCardMenu: function(taskId) { root.toggleCardMenu(taskId); }
        }
      }
    }
  }

  CompletedPopup {
    visible: root.completedOpen
    query: root.completedQuery
    items: root.doneList
    service: root.service
    onQueryInputChanged: function(value) { root.completedQuery = value; }
    onClose: root.completedOpen = false
  }
}

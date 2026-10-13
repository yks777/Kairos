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

      MatrixColumn {
        service: root.service
        columnId: "q1"
        title: "Q1 · DO"
        subtitle: "Urgent + Important"
        menuTaskId: root.menuTaskId
        onCardMenu: function(taskId) { root.toggleCardMenu(taskId); }
      }

      MatrixColumn {
        service: root.service
        columnId: "q2"
        title: "Q2 · SCHEDULE"
        subtitle: "Important, not urgent"
        menuTaskId: root.menuTaskId
        onCardMenu: function(taskId) { root.toggleCardMenu(taskId); }
      }

      MatrixColumn {
        service: root.service
        columnId: "q3"
        title: "Q3 · DELEGATE"
        subtitle: "Urgent, not important"
        menuTaskId: root.menuTaskId
        onCardMenu: function(taskId) { root.toggleCardMenu(taskId); }
      }

      MatrixColumn {
        service: root.service
        columnId: "q4"
        title: "Q4 · DELETE"
        subtitle: "Neither"
        menuTaskId: root.menuTaskId
        onCardMenu: function(taskId) { root.toggleCardMenu(taskId); }
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

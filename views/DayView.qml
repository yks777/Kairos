import QtQuick
import QtQuick.Layouts
import qs.Commons
import "../components"
import "../components/day"
import "../logic/ClockModel.js" as ClockModel

Item {
  id: root

  property var service: null
  property var selectedDate: new Date()
  property int displayedYear: selectedDate.getFullYear()
  property int displayedMonth: selectedDate.getMonth()
  property int weekStart: 1
  property string todayKey: ClockModel.localDateKey(new Date())
  property bool addingTask: false

  readonly property var dayEvents: {
    var calendarRevision = root.service ? root.service.calendarRevision : 0;
    calendarRevision;
    return root.service && typeof root.service.eventsForDate === "function"
      ? root.service.eventsForDate(root.selectedDate) : [];
  }
  readonly property var dayTasks: {
    var revision = root.service ? root.service.revision : 0;
    revision;
    return root.service && typeof root.service.tasksForDate === "function"
      ? root.service.tasksForDate(root.selectedDate) : [];
  }

  function selectDay(date) {
    var chosen = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 12, 0, 0, 0);
    root.selectedDate = chosen;
    root.displayedYear = chosen.getFullYear();
    root.displayedMonth = chosen.getMonth();
    if (root.service && typeof root.service.calendarLoadMonth === "function")
      root.service.calendarLoadMonth(root.displayedYear, root.displayedMonth);
    monthGrid.flashSelected();
    // Opening a daily note is intentionally tied to an explicit day selection.
    if (root.service && typeof root.service.obsidianOpenOrCreate === "function")
      root.service.obsidianOpenOrCreate(chosen);
  }

  function shiftMonth(offset) {
    var shifted = new Date(root.displayedYear, root.displayedMonth + offset, 1);
    root.displayedYear = shifted.getFullYear();
    root.displayedMonth = shifted.getMonth();
    if (root.service && typeof root.service.calendarLoadMonth === "function")
      root.service.calendarLoadMonth(root.displayedYear, root.displayedMonth);
  }

  function shiftYear(offset) {
    root.displayedYear += offset;
    if (root.service && typeof root.service.calendarLoadMonth === "function")
      root.service.calendarLoadMonth(root.displayedYear, root.displayedMonth);
  }

  function goToday() {
    var now = new Date();
    root.selectDay(new Date(now.getFullYear(), now.getMonth(), now.getDate(), 12, 0, 0, 0));
  }

  function beginAddTask() {
    root.addingTask = true;
    taskInput.text = "";
    Qt.callLater(taskInput.focusInput);
  }

  function commitTask() {
    var value = String(taskInput.text || "").trim();
    if (value && root.service && typeof root.service.obsidianAddTask === "function")
      root.service.obsidianAddTask(root.selectedDate, value);
    root.addingTask = false;
    taskInput.text = "";
  }

  function cancelAddTask() {
    root.addingTask = false;
    taskInput.text = "";
  }

  Flickable {
    id: scroll
    anchors.fill: parent
    clip: true
    contentWidth: width
    contentHeight: contentColumn.implicitHeight
    boundsBehavior: Flickable.StopAtBounds
    flickableDirection: Flickable.VerticalFlick

    ColumnLayout {
      id: contentColumn
      width: scroll.width
      spacing: Style.space(12)

      MonthGrid {
        id: monthGrid
        displayedYear: root.displayedYear
        displayedMonth: root.displayedMonth
        selectedDate: root.selectedDate
        weekStart: root.weekStart
        todayKey: root.todayKey
        eventsByDay: root.service ? root.service.eventsByDay : ({})
        Layout.fillWidth: true
        onDayChosen: function(date) { root.selectDay(date); }
        onPreviousMonthRequested: root.shiftMonth(-1)
        onNextMonthRequested: root.shiftMonth(1)
        onPreviousYearRequested: root.shiftYear(-1)
        onNextYearRequested: root.shiftYear(1)
        onTodayRequested: root.goToday()
        onWeekStartToggled: root.weekStart = root.weekStart === 1 ? 0 : 1
      }

      Text {
        textFormat: Text.PlainText
        text: {
          var today = root.todayKey;
          return ClockModel.dayHeading(root.selectedDate, new Date(today + "T12:00:00"));
        }
        color: Color.popups.text
        font.family: Style.font.family
        font.pixelSize: Style.font.title
        font.weight: Font.DemiBold
        Layout.fillWidth: true
        Layout.leftMargin: Style.space(4)
      }

      Section { title: "Events" }

      DayEvents {
        events: root.dayEvents
        service: root.service
        statusText: root.service && root.service.calendarStatusText
          ? String(root.service.calendarStatusText) : ""
        Layout.fillWidth: true
      }

      Section { title: "Tasks" }

      DayTasks {
        tasks: root.dayTasks
        obsidianEnabled: root.service ? root.service.obsidianEnabled : false
        busy: root.service ? root.service.obsidianBusy : false
        Layout.fillWidth: true
        onTaskToggled: function(lineIndex) {
          if (root.service && typeof root.service.obsidianToggleTask === "function")
            root.service.obsidianToggleTask(root.selectedDate, lineIndex);
        }
        onAddRequested: root.beginAddTask()
      }

      RowLayout {
        visible: root.addingTask
        Layout.fillWidth: true
        spacing: Style.space(6)

        FlowInput {
          id: taskInput
          placeholder: "Task name"
          Layout.fillWidth: true
          onAccepted: root.commitTask()
          onCancelled: root.cancelAddTask()
        }

        FlowButton {
          text: "Add"
          primary: true
          onClicked: root.commitTask()
        }

        FlowButton {
          text: "Cancel"
          onClicked: root.cancelAddTask()
        }
      }

      Item { Layout.preferredHeight: Style.space(8) }
    }
  }

  Rectangle {
    id: errorToast
    visible: root.service && String(root.service.obsidianError || "") !== ""
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Style.space(12)
    width: Math.max(0, Math.min(root.width - Style.space(24), errorToastText.implicitWidth + Style.space(24)))
    height: errorToastText.implicitHeight + Style.space(16)
    radius: Style.cornerRadius
    color: Color.popups.background
    border.width: Math.max(1, Style.space(1))
    border.color: Color.urgent
    z: 10

    Text {
      id: errorToastText
      anchors.fill: parent
      anchors.margins: Style.space(8)
      textFormat: Text.PlainText
      text: root.service ? String(root.service.obsidianError || "") : ""
      color: Color.urgent
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
    }
  }

  Timer {
    interval: 30000
    running: true
    repeat: true
    onTriggered: root.todayKey = ClockModel.localDateKey(new Date());
  }

  Component.onCompleted: {
    root.todayKey = ClockModel.localDateKey(new Date());
    if (root.service && typeof root.service.calendarLoadMonth === "function")
      root.service.calendarLoadMonth(root.displayedYear, root.displayedMonth);
    if (root.service && typeof root.service.tasksForDate === "function")
      root.service.tasksForDate(root.selectedDate);
  }
}

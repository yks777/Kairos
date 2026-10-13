import QtQuick
import QtQuick.Layouts
import qs.Commons
import "../../logic/ClockModel.js" as ClockModel
import ".."

ColumnLayout {
  id: root

  property int displayedYear: new Date().getFullYear()
  property int displayedMonth: new Date().getMonth()
  property var selectedDate: new Date()
  property int weekStart: 1
  property string todayKey: ClockModel.localDateKey(new Date())
  property var eventsByDay: ({})
  property bool flashActive: false

  signal dayChosen(var date)
  signal previousMonthRequested()
  signal nextMonthRequested()
  signal previousYearRequested()
  signal nextYearRequested()
  signal todayRequested()
  signal weekStartToggled()

  spacing: Style.space(8)
  Layout.fillWidth: true
  focus: true
  activeFocusOnTab: true

  readonly property var weeks: ClockModel.monthGrid(
    root.displayedYear, root.displayedMonth, root.weekStart, root.todayKey
  )
  readonly property var cells: {
    var output = [];
    var grid = root.weeks;
    for (var week = 0; week < grid.length; week++) {
      for (var day = 0; day < grid[week].days.length; day++) output.push(grid[week].days[day]);
    }
    return output;
  }

  function chooseCell(cell) {
    if (!cell) return;
    root.dayChosen(new Date(cell.year, cell.month, cell.day, 12, 0, 0, 0));
  }

  function flashSelected() {
    root.flashActive = true;
    flashTimer.restart();
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.space(6)

    FlowIconButton {
      glyph: "\uDB80\uDD41"
      tip: "Previous month"
      boxSize: Style.space(30)
      onClicked: root.previousMonthRequested()
    }

    Text {
      textFormat: Text.PlainText
      text: ClockModel.monthTitle(root.displayedYear, root.displayedMonth)
      color: Color.popups.text
      font.family: Style.font.family
      font.pixelSize: Style.font.body
      font.weight: Font.DemiBold
      horizontalAlignment: Text.AlignHCenter
      Layout.fillWidth: true
    }

    FlowIconButton {
      glyph: "\uDB80\uDD42"
      tip: "Next month"
      boxSize: Style.space(30)
      onClicked: root.nextMonthRequested()
    }

    FlowButton {
      text: "Today"
      onClicked: root.todayRequested()
    }
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.space(2)
    Repeater {
      model: ClockModel.weekdayLabels(root.weekStart)
      delegate: Text {
        required property string modelData
        textFormat: Text.PlainText
        text: modelData
        color: Color.muted
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        horizontalAlignment: Text.AlignHCenter
        Layout.fillWidth: true
        Layout.preferredHeight: Style.space(20)
      }
    }
  }

  GridLayout {
    id: monthCells
    columns: 7
    rowSpacing: Style.space(2)
    columnSpacing: Style.space(2)
    Layout.fillWidth: true
    Layout.alignment: Qt.AlignHCenter

    Repeater {
      model: root.cells
      delegate: Item {
        id: cell
        property var info: modelData
        readonly property bool isSelected: ClockModel.localDateKey(root.selectedDate) === info.dateKey
        readonly property bool isToday: info.today
        readonly property var dayColors: root.eventsByDay && root.eventsByDay[info.dateKey]
          ? root.eventsByDay[info.dateKey] : []

        Layout.fillWidth: true
        Layout.preferredWidth: Style.space(52)
        Layout.preferredHeight: Style.space(38)

        Rectangle {
          anchors.fill: parent
          radius: Style.cornerRadius
          color: cell.isSelected ? Color.accent : Color.popups.background
          opacity: cell.isSelected ? 0.22 : 0
          border.width: cell.isSelected || cell.isToday ? Math.max(1, Style.space(1)) : 0
          border.color: cell.isSelected ? Color.accent : Color.accent
        }

        Rectangle {
          anchors.fill: parent
          radius: Style.cornerRadius
          color: Color.accent
          opacity: root.flashActive && cell.isSelected ? 0.26 : 0
          Behavior on opacity { NumberAnimation { duration: 180 } }
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: parent.top
          anchors.topMargin: Style.space(3)
          textFormat: Text.PlainText
          text: String(cell.info.day)
          color: cell.isSelected || cell.isToday ? Color.accent
            : (cell.info.inMonth ? Color.popups.text : Color.muted)
          opacity: cell.info.inMonth ? 1 : 0.56
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
          font.weight: cell.isSelected || cell.isToday ? Font.DemiBold : Font.Normal
        }

        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottom: parent.bottom
          anchors.bottomMargin: Style.space(3)
          spacing: Style.space(2)
          Repeater {
            model: cell.dayColors.slice(0, 3)
            delegate: Rectangle {
              required property var modelData
              width: Style.space(4)
              height: Style.space(4)
              radius: Style.space(2)
              color: modelData && String(modelData.color || "") !== "" ? modelData.color : Color.accent
            }
          }
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            cell.forceActiveFocus();
            root.chooseCell(cell.info);
          }
        }
      }
    }
  }

  Timer {
    id: flashTimer
    interval: 1200
    repeat: false
    onTriggered: root.flashActive = false
  }

  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_BracketLeft) root.previousMonthRequested();
    else if (event.key === Qt.Key_BracketRight) root.nextMonthRequested();
    else if (event.text === "{") root.previousYearRequested();
    else if (event.text === "}") root.nextYearRequested();
    else if (event.text.toLowerCase() === "t") root.todayRequested();
    else return;
    event.accepted = true;
  }
}

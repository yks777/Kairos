import QtQuick
import QtQuick.Layouts
import qs.Commons
import "../components"
import "../components/plan"
import "../logic/Model.js" as Model

Item {
  id: root

  property var service: null
  property bool pickerOpen: false

  Layout.fillWidth: true
  Layout.fillHeight: true

  readonly property string technique: {
    if (!root.service) return "pomodoro";
    var revision = root.service.revision;
    revision;
    var timer = root.service.timer;
    if (timer && (timer.phase === "running" || timer.phase === "paused" || timer.phase === "break")
        && (timer.mode === "pomodoro" || timer.mode === "flowtime")) return timer.mode;
    var focus = root.service.settings && root.service.settings.focus ? root.service.settings.focus : {};
    return focus.focusAction === "flowtime" || focus.action === "flowtime" ? "flowtime" : "pomodoro";
  }

  readonly property var todaySessions: {
    if (!root.service) return [];
    var revision = root.service.revision;
    revision;
    return root.service.history("today", "both").slice(0, 30);
  }

  readonly property var noteTasks: {
    if (!root.pickerOpen || !root.service) return [];
    var revision = root.service.revision;
    revision;
    var rows = typeof root.service.obsidianTasksForToday === "function"
      ? (root.service.obsidianTasksForToday() || []) : [];
    return rows.filter(function(task) { return task && !task.checked; });
  }

  readonly property var matrixTasks: {
    if (!root.pickerOpen || !root.service) return [];
    var revision = root.service.revision;
    revision;
    return root.service.allOpenTasks();
  }

  function activeTaskTitle() {
    if (!root.service) return "No active task";
    var revision = root.service.revision;
    revision;
    var task = root.service.activeTask();
    return task && String(task.title || "") !== "" ? String(task.title) : "No active task";
  }

  function closePicker() {
    root.pickerOpen = false;
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
      spacing: Style.space(10)

      Text {
        textFormat: Text.PlainText
        text: "TECHNIQUE"
        color: Color.muted
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        font.letterSpacing: 1
        Layout.fillWidth: true
      }

      RowLayout {
        spacing: Style.space(6)
        Layout.alignment: Qt.AlignHCenter

        Chip {
          label: "Pomodoro"
          active: root.technique === "pomodoro"
          onClicked: if (root.service) root.service.updateFocusAction("pomodoro")
        }

        Chip {
          label: "Flowtime"
          active: root.technique === "flowtime"
          onClicked: if (root.service) root.service.updateFocusAction("flowtime")
        }
      }

      PomodoroView {
        service: root.service
        visible: root.technique === "pomodoro"
        Layout.fillWidth: true
      }

      FlowtimeView {
        service: root.service
        visible: root.technique === "flowtime"
        Layout.fillWidth: true
      }

      RowLayout {
        spacing: Style.space(8)
        Layout.fillWidth: true
        Layout.topMargin: Style.space(4)

        Text {
          textFormat: Text.PlainText
          text: "Working on: " + root.activeTaskTitle()
          color: Color.popups.text
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
          elide: Text.ElideRight
          Layout.fillWidth: true
        }

        FlowButton {
          text: "Change"
          onClicked: root.pickerOpen = true
        }
      }

      Rectangle {
        height: Math.max(1, Style.space(1))
        color: Color.popups.border
        opacity: 0.5
        Layout.fillWidth: true
        Layout.topMargin: Style.space(6)
      }

      Text {
        textFormat: Text.PlainText
        text: "TODAY'S SESSIONS"
        color: Color.muted
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        font.letterSpacing: 1
        Layout.fillWidth: true
      }

      ColumnLayout {
        spacing: Style.space(3)
        Layout.fillWidth: true

        Repeater {
          model: root.todaySessions
          delegate: RowLayout {
            required property var modelData
            spacing: Style.space(8)
            Layout.fillWidth: true

            Rectangle {
              width: Style.space(8)
              height: width
              radius: width / 2
              color: modelData.kind === "pomo" ? Color.accent : Color.muted
              Layout.alignment: Qt.AlignVCenter
            }

            Text {
              textFormat: Text.PlainText
              text: (modelData.kind === "pomo" ? "Pomodoro" : "Flowtime")
                + " · " + Model.formatDur(modelData.durationSec)
              color: Color.popups.text
              font.family: Style.font.family
              font.pixelSize: Style.font.bodySmall
              Layout.fillWidth: true
              elide: Text.ElideRight
            }

            Text {
              textFormat: Text.PlainText
              text: Qt.formatDateTime(new Date(modelData.startedAt), "HH:mm")
              color: Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
            }
          }
        }

        Text {
          visible: root.todaySessions.length === 0
          textFormat: Text.PlainText
          text: "No sessions yet today."
          color: Color.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          font.italic: true
          Layout.fillWidth: true
        }
      }

      Item { Layout.preferredHeight: Style.space(8) }
    }
  }

  Rectangle {
    id: taskPickerOverlay
    visible: root.pickerOpen
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.55)
    z: 20

    MouseArea {
      anchors.fill: parent
      onClicked: root.closePicker()
    }

    Rectangle {
      id: taskPickerCard
      anchors.centerIn: parent
      width: Math.max(0, Math.min(parent.width - Style.space(24), Style.space(440)))
      height: Math.max(0, Math.min(parent.height - Style.space(24), Style.space(460)))
      radius: Style.cornerRadius
      color: Color.popups.background
      border.color: Color.popups.border
      border.width: Math.max(1, Style.space(1))

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.space(12)
        spacing: Style.space(8)

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(8)

          Text {
            textFormat: Text.PlainText
            text: "CHANGE ACTIVE TASK"
            color: Color.popups.text
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.letterSpacing: 1
            Layout.fillWidth: true
          }

          FlowButton {
            text: "Clear"
            onClicked: {
              if (root.service) root.service.setActiveTask("");
              root.closePicker();
            }
          }

          FlowIconButton {
            glyph: "×"
            tip: "Close task picker"
            onClicked: root.closePicker()
          }
        }

        Flickable {
          id: pickerScroll
          clip: true
          contentWidth: width
          contentHeight: pickerSections.implicitHeight
          boundsBehavior: Flickable.StopAtBounds
          Layout.fillWidth: true
          Layout.fillHeight: true

          ColumnLayout {
            id: pickerSections
            width: pickerScroll.width
            spacing: Style.space(8)

            Text {
              textFormat: Text.PlainText
              text: "FROM TODAY'S NOTE"
              color: Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              font.letterSpacing: 1
              Layout.fillWidth: true
            }

            Text {
              visible: root.noteTasks.length === 0
              textFormat: Text.PlainText
              text: root.service && root.service.obsidianTodayTasksBusy ? "Loading today's note..." : "No open tasks in today's note."
              color: Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              Layout.fillWidth: true
            }

            Repeater {
              model: root.noteTasks
              delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: Style.space(6)

                Text {
                  textFormat: Text.PlainText
                  text: String(modelData.text || "")
                  color: Color.popups.text
                  font.family: Style.font.family
                  font.pixelSize: Style.font.bodySmall
                  elide: Text.ElideRight
                  Layout.fillWidth: true
                }

                FlowButton {
                  text: "Use"
                  onClicked: {
                    if (root.service) root.service.setActiveTaskFromObsidian(String(modelData.text || ""));
                    root.closePicker();
                  }
                }
              }
            }

            Rectangle {
              height: Math.max(1, Style.space(1))
              color: Color.popups.border
              opacity: 0.5
              Layout.fillWidth: true
              Layout.topMargin: Style.space(3)
            }

            Text {
              textFormat: Text.PlainText
              text: "FROM MATRIX"
              color: Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              font.letterSpacing: 1
              Layout.fillWidth: true
            }

            Text {
              visible: root.matrixTasks.length === 0
              textFormat: Text.PlainText
              text: "No open matrix tasks."
              color: Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              Layout.fillWidth: true
            }

            Repeater {
              model: root.matrixTasks
              delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: Style.space(6)

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
                  text: "Use"
                  onClicked: {
                    if (root.service) root.service.setActiveTask(modelData.id);
                    root.closePicker();
                  }
                }
              }
            }
          }
        }
      }
    }
  }

}

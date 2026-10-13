import QtQuick
import QtQuick.Layouts
import qs.Commons
import "../components"
import "../logic/TimerEngine.js" as TimerEngine

ColumnLayout {
  id: root

  property var service: null

  spacing: Style.space(10)
  Layout.fillWidth: true

  readonly property string phase: root.service ? String(root.service.timer.phase || "stopped") : "stopped"
  readonly property bool isBreak: root.phase === "break"
    || (root.phase === "paused" && root.service && root.service.timer.pausedPhase === "break")

  function timeText() {
    if (!root.service) return TimerEngine.formatTimerClock(25 * 60);
    var tick = root.service.tickVersion;
    tick;
    if (root.phase === "running" || root.phase === "paused" || root.phase === "break")
      return TimerEngine.formatTimerClock(Math.floor(root.service.timerRemainingMs() / 1000));
    var focus = root.service.settings && root.service.settings.focus ? root.service.settings.focus : {};
    return TimerEngine.formatTimerClock(focus.focusSec || 25 * 60);
  }

  function stateLabel() {
    if (!root.service) return "READY";
    if (root.isBreak) return root.service.timer.breakKind === "long" ? "LONG BREAK" : "SHORT BREAK";
    if (root.phase === "running") return "FOCUS";
    if (root.phase === "paused") return "PAUSED";
    return "READY";
  }

  function cycleLabel() {
    if (!root.service) return "Session 1 of 4";
    var focus = root.service.settings && root.service.settings.focus ? root.service.settings.focus : {};
    var every = Math.max(1, Number(focus.longBreakInterval) || 4);
    var done = Math.max(0, Number(root.service.timer.pomodorosDone) || 0);
    return "Session " + ((done % every) + 1) + " of " + every;
  }

  Text {
    textFormat: Text.PlainText
    text: root.timeText()
    color: root.phase === "paused" ? Color.muted : (root.isBreak ? Color.accent : Color.popups.text)
    font.family: Style.font.family
    font.pixelSize: Style.font.displayLarge
    horizontalAlignment: Text.AlignHCenter
    Layout.fillWidth: true
    Layout.topMargin: Style.space(6)
  }

  Text {
    textFormat: Text.PlainText
    text: root.stateLabel() + " · " + root.cycleLabel()
    color: Color.muted
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    font.letterSpacing: 1
    horizontalAlignment: Text.AlignHCenter
    Layout.fillWidth: true
  }

  RowLayout {
    spacing: Style.space(8)
    Layout.alignment: Qt.AlignHCenter
    visible: root.phase === "stopped" || root.phase === "idle"

    FlowButton {
      text: "Start"
      primary: true
      onClicked: if (root.service) root.service.startPomodoro()
    }
  }

  RowLayout {
    spacing: Style.space(8)
    Layout.alignment: Qt.AlignHCenter
    visible: root.phase === "running" && !root.isBreak

    FlowButton {
      text: "Pause"
      onClicked: if (root.service) root.service.pauseTimer()
    }
    FlowButton {
      text: "Stop"
      onClicked: if (root.service) root.service.stopTimer()
    }
  }

  RowLayout {
    spacing: Style.space(8)
    Layout.alignment: Qt.AlignHCenter
    visible: root.phase === "paused" && !root.isBreak

    FlowButton {
      text: "Resume"
      primary: true
      onClicked: if (root.service) root.service.resumeTimer()
    }
    FlowButton {
      text: "Stop"
      onClicked: if (root.service) root.service.stopTimer()
    }
  }

  RowLayout {
    spacing: Style.space(8)
    Layout.alignment: Qt.AlignHCenter
    visible: root.isBreak

    FlowButton {
      text: root.phase === "paused" ? "Resume break" : "Pause break"
      onClicked: {
        if (!root.service) return;
        if (root.phase === "paused") root.service.resumeTimer();
        else root.service.pauseTimer();
      }
    }
    FlowButton {
      text: "Skip break"
      primary: true
      onClicked: if (root.service) root.service.skipBreak()
    }
  }
}

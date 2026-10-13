import QtQuick
import QtQuick.Layouts
import qs.Commons
import "../components"
import "../logic/Model.js" as Model
import "../logic/TimerEngine.js" as TimerEngine

ColumnLayout {
  id: root

  property var service: null

  spacing: Style.space(10)
  Layout.fillWidth: true

  readonly property string phase: root.service ? String(root.service.timer.phase || "stopped") : "stopped"
  readonly property bool isBreak: root.phase === "break"
    || (root.phase === "paused" && root.service && root.service.timer.pausedPhase === "break")
  readonly property bool live: root.phase === "running" || (root.phase === "paused" && !root.isBreak)

  function elapsedText() {
    if (!root.service) return TimerEngine.formatTimerClock(0);
    var tick = root.service.tickVersion;
    tick;
    if (root.isBreak) return TimerEngine.formatTimerClock(Math.floor(root.service.timerRemainingMs() / 1000));
    if (root.live) return TimerEngine.formatTimerClock(Math.floor(root.service.flowElapsedMs() / 1000));
    return TimerEngine.formatTimerClock(0);
  }

  function breakHint() {
    if (!root.service || !root.live) return "";
    var elapsed = Math.floor(root.service.flowElapsedMs() / 1000);
    var flowSettings = root.service.settings && root.service.settings.flowtime ? root.service.settings.flowtime : {};
    var suggested = TimerEngine.suggestedBreakSec(elapsed, flowSettings);
    return "Suggested break: " + Model.formatDur(suggested);
  }

  function interruptionsText() {
    if (!root.service) return "0 interruptions";
    var count = Math.max(0, Number(root.service.timer.interruptions) || 0);
    return count === 1 ? "1 interruption" : count + " interruptions";
  }

  function stateLabel() {
    if (root.isBreak) return root.phase === "paused" ? "BREAK PAUSED" : "BREAK";
    if (root.phase === "paused") return "PAUSED · " + root.interruptionsText();
    if (root.phase === "running") return "FLOWTIME · " + root.interruptionsText() + " · " + root.breakHint();
    return "Count up. Finish when focus ends.";
  }

  Text {
    textFormat: Text.PlainText
    text: root.elapsedText()
    color: root.phase === "paused" ? Color.muted : (root.isBreak ? Color.accent : Color.popups.text)
    font.family: Style.font.family
    font.pixelSize: Style.font.displayLarge
    horizontalAlignment: Text.AlignHCenter
    Layout.fillWidth: true
    Layout.topMargin: Style.space(6)
  }

  Text {
    textFormat: Text.PlainText
    text: root.stateLabel()
    color: Color.muted
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    horizontalAlignment: Text.AlignHCenter
    wrapMode: Text.WordWrap
    Layout.fillWidth: true
  }

  RowLayout {
    spacing: Style.space(8)
    Layout.alignment: Qt.AlignHCenter
    visible: root.phase === "stopped" || root.phase === "idle"

    FlowButton {
      text: "Start"
      primary: true
      onClicked: if (root.service) root.service.startFlowtime()
    }
  }

  RowLayout {
    spacing: Style.space(8)
    Layout.alignment: Qt.AlignHCenter
    visible: root.phase === "running"

    FlowButton {
      text: "Pause"
      onClicked: if (root.service) root.service.pauseTimer()
    }
    FlowButton {
      text: "+ Interruption"
      onClicked: if (root.service) root.service.addInterruption()
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
    visible: root.live

    FlowButton {
      text: "Finish focus"
      primary: true
      onClicked: if (root.service) root.service.finishFlowtime("focus")
    }
    FlowButton {
      text: "Finish + break"
      onClicked: if (root.service) root.service.finishFlowtime("break")
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

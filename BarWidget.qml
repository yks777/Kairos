import QtQuick
import Quickshell
import qs.Commons
import qs.Ui
import "logic/ClockModel.js" as ClockModel
import "logic/TimerEngine.js" as TimerEngine

// Compact clock widget. Loads Panel.qml internally via Loader;
// this follows the Omarchy bar-widget with panel pattern.
BarWidget {
  id: root
  moduleName: "io.github.yks777.kairos"

  readonly property var kairosService: {
    try {
      if (root.bar && root.bar.shell && typeof root.bar.shell.serviceFor === "function")
        return root.bar.shell.serviceFor(root.moduleName);
    } catch (error) {}
    return null;
  }

  property int nowTick: 0
  property bool stopConfirmArmed: false

  Timer {
    interval: 1000
    repeat: true
    running: true
    onTriggered: root.nowTick++
  }

  Timer {
    id: stopConfirmTimeout
    interval: 3000
    repeat: false
    onTriggered: root.stopConfirmArmed = false
  }

  readonly property string clockText: {
    var date = new Date();
    void root.nowTick;
    var format = root.vertical
      ? root.setting("verticalFormat", ClockModel.DEFAULT_VERTICAL_FORMAT)
      : root.setting("format", ClockModel.DEFAULT_FORMAT);
    return Qt.formatDateTime(date, ClockModel.substituteIsoWeek(format, date));
  }

  readonly property bool timerActive: {
    var service = root.kairosService;
    if (!service || !service.timer) return false;
    if (service.settings && service.settings.bar && service.settings.bar.showFocusTimer === false) return false;
    return service.timer.phase === "running"
      || service.timer.phase === "break"
      || service.timer.phase === "paused";
  }

  readonly property string timerText: {
    if (!root.timerActive) return "";
    var service = root.kairosService;
    void root.nowTick;
    try { void service.tickVersion; } catch (error) {}
    var timer = service.timer;
    var milliseconds = 0;
    if (timer.phase === "running" || timer.phase === "break") {
      if (timer.mode === "flowtime" && timer.phase === "running")
        milliseconds = service.flowElapsedMs();
      else
        milliseconds = service.timerRemainingMs();
    } else if (timer.phase === "paused") {
      if (timer.pausedPhase === "break")
        milliseconds = Math.max(0, timer.pausedRemainingMs || 0);
      else if (timer.mode === "flowtime")
        milliseconds = service.flowElapsedMs();
      else
        milliseconds = Math.max(0, timer.pausedRemainingMs || 0);
    }
    return TimerEngine.formatTimerClock(Math.floor(milliseconds / 1000));
  }

  readonly property string verticalTimerText: {
    if (!root.timerActive) return "";
    var parts = root.timerText.split(":");
    if (parts.length === 1) return "00\n" + parts[0];
    return parts.join("\n");
  }

  readonly property string timerGlyph: {
    if (!root.timerActive) return "";
    var timer = root.kairosService.timer;
    if (timer.phase === "paused") return "\uDB86\uDEDE"; // nf-md-timer-pause, U+F1ADE
    if (timer.phase === "break") return "\uDB80\uDD76"; // nf-md-coffee, U+F0176
    if (timer.phase === "running") return "\uDB86\uDEE0"; // nf-md-timer-play, U+F1AE0
    return "\uDB84\uDFAB"; // nf-md-timer, U+F13AB
  }

  readonly property color timerColor: {
    if (!root.timerActive) return Color.accent;
    if (root.stopConfirmArmed) return Color.urgent;
    return root.kairosService.timer.phase === "paused" ? Color.muted : Color.accent;
  }

  readonly property string timerTooltip: {
    if (!root.timerActive) return "Open Kairos";
    if (root.stopConfirmArmed) return "Right-click again to stop the timer";
    if (root.kairosService.timer.phase === "paused") return "Timer paused — middle-click to resume";
    if (root.kairosService.timer.phase === "break") return "Break — middle-click to pause";
    return "Focus timer — right-click twice to stop, middle-click to pause";
  }

  function verticalLineCount(text) {
    return String(text || "").split("\n").length;
  }

  // ---- Panel lifecycle (forwarded to internally loaded Panel.qml) ----
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  function open(payloadJson) {
    if (panelLoader.item) panelLoader.item.open(payloadJson);
  }

  function close() {
    if (panelLoader.item) panelLoader.item.close();
  }

  function toggle() {
    if (panelLoader.item) panelLoader.item.toggle();
  }

  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch();
  }

  function injectPanel() {
    if (!panelLoader.item) return;
    panelLoader.item.bar = root.bar;
    panelLoader.item.anchorItem = horizontalClockButton;
    panelLoader.item.hostWidget = root;
    panelLoader.item.service = root.kairosService;
  }

  // ---- Bar widget lifecycle ----
  implicitWidth: root.vertical ? verticalStack.implicitWidth : horizontalRow.implicitWidth
  implicitHeight: root.vertical ? verticalStack.implicitHeight : horizontalRow.implicitHeight

  onBarChanged: injectPanel()

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel();
      Qt.callLater(root.injectPanel);
    }
  }

  Row {
    id: horizontalRow
    visible: !root.vertical
    spacing: Style.space(6)

    WidgetButton {
      id: horizontalClockButton
      bar: root.bar
      text: root.clockText
      labelVisible: true
      tooltipText: "Left-click: Day · Right-click: change format · Middle-click: timezone"
      onPressed: function(buttonCode) {
        if (buttonCode === Qt.RightButton) root.cycleFormat();
        else if (buttonCode === Qt.MiddleButton) {
          if (root.bar) root.bar.run("omarchy-menu-timezone");
        } else root.toggle();
      }
    }

    WidgetButton {
      id: horizontalTimerButton
      visible: root.timerActive
      bar: root.bar
      text: root.timerGlyph + " " + root.timerText
      foreground: root.timerColor
      tooltipText: root.timerTooltip
      onPressed: function(buttonCode) {
        if (buttonCode === Qt.RightButton) root.requestStopTimer();
        else if (buttonCode === Qt.MiddleButton) root.toggleTimer();
        else root.openPanelOn("focus");
      }
    }
  }

  Column {
    id: verticalStack
    visible: root.vertical
    spacing: Style.space(6)

    WidgetButton {
      id: verticalClockButton
      bar: root.bar
      text: ""
      labelVisible: false
      hasVisualContent: true
      fixedHeight: root.verticalLineCount(root.clockText) * Style.bar.iconSlot
      tooltipText: "Left-click: Day · Right-click: change format · Middle-click: timezone"
      onPressed: function(buttonCode) {
        if (buttonCode === Qt.RightButton) root.cycleFormat();
        else if (buttonCode === Qt.MiddleButton) {
          if (root.bar) root.bar.run("omarchy-menu-timezone");
        } else root.toggle();
      }

      Text {
        anchors.fill: parent
        textFormat: Text.PlainText
        text: root.clockText
        color: verticalClockButton.foreground
        font.family: verticalClockButton.fontFamily
        font.pixelSize: verticalClockButton.fontSize
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
      }
    }

    WidgetButton {
      id: verticalTimerButton
      visible: root.timerActive
      bar: root.bar
      text: ""
      labelVisible: false
      hasVisualContent: true
      fixedHeight: root.verticalLineCount(root.verticalTimerText) * Style.bar.iconSlot
      foreground: root.timerColor
      tooltipText: root.timerTooltip
      onPressed: function(buttonCode) {
        if (buttonCode === Qt.RightButton) root.requestStopTimer();
        else if (buttonCode === Qt.MiddleButton) root.toggleTimer();
        else root.openPanelOn("focus");
      }

      Text {
        anchors.fill: parent
        textFormat: Text.PlainText
        text: root.verticalTimerText
        color: verticalTimerButton.foreground
        font.family: verticalTimerButton.fontFamily
        font.pixelSize: verticalTimerButton.fontSize
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
      }
    }
  }

  // ---- Helper functions (unchanged) ----
  function cycleFormat() {
    var settingName = root.vertical ? "verticalFormat" : "format";
    var fallback = root.vertical ? ClockModel.DEFAULT_VERTICAL_FORMAT : ClockModel.DEFAULT_FORMAT;
    var current = String(root.setting(settingName, fallback));
    var alternate = root.vertical ? "" : root.setting("formatAlt", ClockModel.DEFAULT_FORMAT_ALT);
    var next = ClockModel.nextFormat(current, root.vertical, alternate);
    if (next === "" || next === current) return;

    var entry = { id: root.moduleName };
    if (root.settings) {
      for (var key in root.settings) {
        if (key !== "id" && Object.prototype.hasOwnProperty.call(root.settings, key))
          entry[key] = root.settings[key];
      }
    }
    entry[settingName] = next;
    root.settings = entry;
    if (root.bar && root.bar.shell && typeof root.bar.shell.updateEntryInline === "function")
      root.bar.shell.updateEntryInline(root.moduleName, entry);
  }

  function toggleTimer() {
    var service = root.kairosService;
    if (!service || !service.timer) return;
    if (service.timer.phase === "paused") service.resumeTimer();
    else if (service.timer.phase === "running" || service.timer.phase === "break") service.pauseTimer();
  }

  function requestStopTimer() {
    var service = root.kairosService;
    if (!service || !service.timer) return;
    if (service.timer.phase === "running" && !root.stopConfirmArmed) {
      root.stopConfirmArmed = true;
      stopConfirmTimeout.restart();
      return;
    }
    root.stopConfirmArmed = false;
    stopConfirmTimeout.stop();
    service.stopTimer();
  }

  function openPanelOn(view) {
    var payload = JSON.stringify({ view: String(view || "day") });
    try {
      if (root.bar && root.bar.shell && typeof root.bar.shell.summon === "function") {
        root.bar.shell.summon(root.moduleName, payload);
        return;
      }
    } catch (error) {}
    Quickshell.execDetached(["omarchy-shell", "shell", "summon", root.moduleName, payload]);
  }
}
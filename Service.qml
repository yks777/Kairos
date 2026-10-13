import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "logic/Model.js" as Model
import "logic/TimerEngine.js" as TimerEngine
import "logic/StatsEngine.js" as StatsEngine
import "logic/MarketsModel.js" as MarketsModel
import "logic/ConverterModel.js" as ConverterModel
import "logic/Storage.js" as Storage
import "logic/CalendarModel.js" as CalendarModel
import "logic/SocialModel.js" as SocialModel
import "connectors"
import "services"

// Kairos Service: the single owner of mutable plugin state.
Item {
  id: root

  // Injected by the shell when the service is loaded.
  property var shell: null
  property var manifest: null
  property string omarchyPath: ""
  readonly property string pluginId: "io.github.yks777.kairos"
  readonly property string notificationSoundScript: {
    var url = String(Qt.resolvedUrl("scripts/notification-sound"));
    if (url.indexOf("file://") === 0) url = url.substring(7);
    try { return decodeURIComponent(url); } catch (error) { return url; }
  }

  // ---- Canonical state (replace values; do not mutate them in place) ----
  property var settings: Model.defaultSettings()
  property var boards: Model.defaultBoards()
  property var tasks: []
  property var sessions: []
  property string activeBoardId: "board-life"
  property string activeTaskId: ""
  property string activeTaskSource: "matrix"
  property string activeTaskText: ""
  property var timer: Model.blankTimer()

  readonly property var eventsByDay: calendarData.eventsByDay
  readonly property string calendarStatusText: calendarData.statusText
  readonly property bool khalAvailable: calendarData.khalAvailable
  readonly property bool obsidianEnabled: obsidianData.obsidianEnabled
  readonly property bool obsidianBusy: obsidianData.obsidianEnabled && (!obsidianData.noteLoaded || obsidianData.writeBusy)
  readonly property bool obsidianTodayTasksBusy: obsidianData.obsidianEnabled && obsidianData.todayTasksBusy
  readonly property string obsidianError: obsidianData.lastError
  readonly property var quotes: marketsData.displayQuotes
  readonly property var watchlist: marketsData.watchlist
  readonly property var currencyRates: converterData.currencyRates
  readonly property var cryptoPrices: converterData.cryptoPrices
  readonly property var searchResults: marketsData.searchResults
  readonly property bool searchBusy: marketsData.searchBusy
  readonly property string searchError: marketsData.searchError
  readonly property string marketsError: marketsData.lastError
  readonly property string currency: root.settings && root.settings.markets
    ? String(root.settings.markets.currency || "USD") : "USD"
  readonly property string socialStatus: socialData.statusText
  readonly property string socialEmptyMessage: socialData.bridgeAvailable || emailData.accounts.length > 0
    ? "No unread messages from enabled accounts." : socialData.statusText
  readonly property string emailStatusText: emailConnector.statusText
  readonly property string obsidianTestStatus: obsidianData.testStatus
  readonly property string dataStatus: root.dataStatusMessage !== "" ? root.dataStatusMessage
    : root.stateLoaded
      ? "State is saved automatically. Email secrets use the system Secret Service and are not stored in state.json."
      : "Waiting for the Kairos state file to load."

  // ---- Binding invalidation ----
  property int revision: 0
  property int calendarRevision: 0
  property int tickVersion: 0

  // ---- Persistence lifecycle ----
  property bool stateLoaded: false
  property bool persistenceBlocked: false
  property string stateFilePath: ""
  property string stateDirPath: ""
  property string dataStatusMessage: ""
  property string pendingView: ""
  property var appliedShortcutChords: []

  function nowMs() {
    return Date.now();
  }

  function timerRemainingMs() {
    return TimerEngine.pomodoroRemainingMs(root.timer, root.nowMs());
  }

  function flowElapsedMs() {
    return TimerEngine.flowElapsedMs(root.timer, root.nowMs());
  }

  function eventsForDate(date) {
    var source = CalendarModel.eventsForDate(calendarData.allEvents, date);
    var result = [];
    for (var i = 0; i < source.length; i++) {
      var displayed = CalendarModel.enrichEvent(source[i], null, calendarData.use24h);
      var details = calendarData.detailsForEvent(source[i]);
      displayed.details = details;
      displayed.meetingUrl = details.meeting ? details.meeting.url : "";
      displayed.serviceName = details.meeting ? details.meeting.label : "";
      displayed.directionsUrl = details.directions;
      result.push(displayed);
    }
    return result;
  }

  function tasksForDate(date) {
    return obsidianData.tasksForDate(date);
  }

  function obsidianTasksForToday() {
    return obsidianData.tasksForToday();
  }

  function calendarLoadMonth(year, month) { calendarData.loadMonth(year, month); }
  function calendarLoadDetails(uid) { calendarData.loadDetails(uid); }
  function calendarEventDetails(event) { return calendarData.detailsForEvent(event); }
  function calendarRefresh() { calendarData.reload(); }
  function calendarSync() { calendarData.sync(); }

  function obsidianLoad(date) { obsidianData.loadNote(date); }
  function obsidianOpenOrCreate(date) { obsidianData.openOrCreate(date); }
  function obsidianToggleTask(date, lineIndex) { obsidianData.toggleTask(date, lineIndex); }
  function obsidianAddTask(date, text) { obsidianData.addTask(date, text); }

  function openUrl(url) {
    var value = String(url || "").trim();
    if (!CalendarModel.isOpenableUrl(value)) return false;
    Quickshell.execDetached(["xdg-open", value]);
    return true;
  }

  function notify(category, title, body) {
    if (root.settings && root.settings.notifications && root.settings.notifications.enabled === false) return false;
    var safeTitle = String(title || "Kairos").replace(/[\r\n\u0000]+/g, " ").trim();
    if (safeTitle === "") safeTitle = "Kairos";
    if (/^-/.test(safeTitle)) safeTitle = "Event: " + safeTitle;
    var safeBody = String(body || "").replace(/\u0000/g, "");
    var glyph = "\uDB82\uDF67";
    var appName = category === "calendar" ? "Kairos Calendar" : "Kairos";
    Quickshell.execDetached([
      "omarchy-notification-send", "--app-name", appName, "-g", glyph, "-u", "normal", safeTitle, safeBody
    ]);
    if (!(root.settings && root.settings.notifications && root.settings.notifications.sound === false))
      Quickshell.execDetached(["python3", root.notificationSoundScript]);
    return true;
  }

  function updateSettings(section, patch) {
    var defaults = Model.defaultSettings();
    if (!Object.prototype.hasOwnProperty.call(defaults, section)
        || !patch || typeof patch !== "object" || Array.isArray(patch)) return false;
    try {
      var source = root.settings || defaults;
      var current = source[section] || defaults[section];
      var merged = {};
      for (var key in current) if (Object.prototype.hasOwnProperty.call(current, key)) merged[key] = current[key];
      for (var field in patch) if (Object.prototype.hasOwnProperty.call(patch, field)) merged[field] = patch[field];
      var normalized = Model.sanitizeSettingsSection(section, merged);
      if (JSON.stringify(normalized) === JSON.stringify(current)) return true;
      var next = {};
      for (var sectionKey in source) if (Object.prototype.hasOwnProperty.call(source, sectionKey)) next[sectionKey] = source[sectionKey];
      next[section] = normalized;
      root.settings = next;
      root.bump();
      root.saveSoon();
      return true;
    } catch (error) {
      console.warn("Kairos could not update settings section " + section + ": " + error);
      return false;
    }
  }

  function isTicking() {
    return root.timer.phase === "running" || root.timer.phase === "break";
  }

  function bump() {
    root.revision++;
  }

  function calendarChanged() {
    root.calendarRevision++;
    root.bump();
  }

  function cloneTimer(source) {
    var copy = {};
    if (!source || typeof source !== "object") return Model.blankTimer();
    for (var key in source) {
      if (Object.prototype.hasOwnProperty.call(source, key)) copy[key] = source[key];
    }
    return copy;
  }

  // ---- Timer state transitions ----
  function timerCanStart() {
    return root.timer.phase === "stopped" || root.timer.phase === "idle";
  }

  function resolveTimerTask(taskId) {
    if (taskId !== undefined && taskId !== null && String(taskId) !== "") {
      var wanted = String(taskId);
      for (var i = 0; i < root.tasks.length; i++) {
        var task = root.tasks[i];
        if (task.id === wanted && task.boardId === root.activeBoardId && !task.completedAt)
          return { id: task.id, title: task.title, source: "matrix" };
      }
      return null;
    }
    return root.activeTask();
  }

  function startPomodoro(taskId) {
    if (!root.timerCanStart()) return false;
    var now = root.nowMs();
    var focus = root.settings && root.settings.focus ? root.settings.focus : {};
    var durationSec = Math.max(60, Math.min(28800, Number(focus.focusSec) || 1500));
    var selected = root.resolveTimerTask(taskId);
    var next = Model.blankTimer();
    next.mode = "pomodoro";
    next.phase = "running";
    next.technique = "pomodoro";
    next.taskId = selected && selected.source === "matrix" ? selected.id : null;
    next.taskTitle = selected ? String(selected.title || "") : "";
    next.startedAtMs = now;
    next.sessionStartedAtMs = now;
    next.deadlineMs = now + durationSec * 1000;
    next.pomodorosDone = Math.max(0, Number(root.timer.pomodorosDone) || 0);
    root.timer = next;
    root.bump();
    root.saveSoon();
    return true;
  }

  function startFlowtime(taskId) {
    if (!root.timerCanStart()) return false;
    var now = root.nowMs();
    var selected = root.resolveTimerTask(taskId);
    var next = Model.blankTimer();
    next.mode = "flowtime";
    next.phase = "running";
    next.technique = "flowtime";
    next.taskId = selected && selected.source === "matrix" ? selected.id : null;
    next.taskTitle = selected ? String(selected.title || "") : "";
    next.startedAtMs = now;
    next.sessionStartedAtMs = now;
    next.accumulatedMs = 0;
    next.interruptions = 0;
    next.pomodorosDone = Math.max(0, Number(root.timer.pomodorosDone) || 0);
    root.timer = next;
    root.bump();
    root.saveSoon();
    return true;
  }

  function startTimer() {
    if (root.timer.phase === "paused") {
      root.resumeTimer();
      return;
    }
    if (!root.timerCanStart()) return;
    var focus = root.settings && root.settings.focus ? root.settings.focus : {};
    if (focus.focusAction === "flowtime") root.startFlowtime();
    else root.startPomodoro();
  }

  function pauseTimer() {
    var current = root.timer;
    if (current.phase !== "running" && current.phase !== "break") return false;
    var now = root.nowMs();
    if ((current.mode === "pomodoro" && current.phase === "running" || current.phase === "break")
        && (Number(current.deadlineMs) || 0) <= now) {
      if (current.phase === "break") root.completeBreak();
      else root.completePomodoro();
      return true;
    }
    var next = root.cloneTimer(current);
    if (current.phase === "break") {
      next.pausedRemainingMs = TimerEngine.pomodoroRemainingMs(current, now);
      next.pausedPhase = "break";
    } else if (current.mode === "pomodoro") {
      next.pausedRemainingMs = TimerEngine.pomodoroRemainingMs(current, now);
      next.pausedPhase = "";
    } else {
      next.accumulatedMs = TimerEngine.flowElapsedMs(current, now);
      next.pausedPhase = "";
    }
    next.phase = "paused";
    root.timer = next;
    root.bump();
    root.saveSoon();
    return true;
  }

  function resumeTimer() {
    var current = root.timer;
    if (current.phase !== "paused") return false;
    var now = root.nowMs();
    var next = root.cloneTimer(current);
    if (current.pausedPhase === "break") {
      next.deadlineMs = now + Math.max(0, Number(current.pausedRemainingMs || 0));
      next.phase = "break";
    } else if (current.mode === "pomodoro") {
      next.deadlineMs = now + Math.max(0, Number(current.pausedRemainingMs || 0));
      next.pausedRemainingMs = 0;
      next.phase = "running";
    } else {
      next.startedAtMs = now;
      next.phase = "running";
    }
    next.pausedPhase = "";
    root.timer = next;
    root.bump();
    root.saveSoon();
    return true;
  }

  function stopTimer() {
    var done = Math.max(0, Number(root.timer.pomodorosDone) || 0);
    var focus = root.settings && root.settings.focus ? root.settings.focus : {};
    var next = Model.blankTimer();
    next.technique = focus.focusAction === "flowtime" ? "flowtime" : "pomodoro";
    next.pomodorosDone = done;
    root.timer = next;
    root.bump();
    root.saveSoon();
    return true;
  }

  function skipBreak() {
    if (root.timer.phase !== "break" && !(root.timer.phase === "paused" && root.timer.pausedPhase === "break"))
      return false;
    var done = Math.max(0, Number(root.timer.pomodorosDone) || 0);
    var technique = root.timer.technique || root.timer.mode;
    var next = Model.blankTimer();
    next.technique = technique === "flowtime" ? "flowtime" : "pomodoro";
    next.pomodorosDone = done;
    root.timer = next;
    root.bump();
    root.saveSoon();
    return true;
  }

  function addInterruption() {
    var current = root.timer;
    if (current.mode !== "flowtime" || (current.phase !== "running" && current.phase !== "paused")) return false;
    var next = root.cloneTimer(current);
    next.interruptions = Math.max(0, Number(next.interruptions) || 0) + 1;
    root.timer = next;
    root.bump();
    root.saveSoon();
    return true;
  }

  function recordSession(kind, taskId, taskTitle, durationSec, interruptions, startedAt) {
    var duration = Math.floor(Number(durationSec) || 0);
    if (duration < 1) return false;
    var now = root.nowMs();
    var session = {
      id: Model.uid("session"),
      kind: kind === "flow" ? "flow" : "pomo",
      taskId: taskId ? String(taskId) : null,
      taskTitle: String(taskTitle || "").slice(0, 200),
      boardId: root.activeBoardId,
      startedAt: Math.max(0, Number(startedAt) || (now - duration * 1000)),
      endedAt: now,
      durationSec: duration,
      interruptions: Math.max(0, Math.floor(Number(interruptions) || 0))
    };
    var sessions = root.sessions.concat([session]);
    if (sessions.length > 2000) sessions = sessions.slice(sessions.length - 2000);
    root.sessions = sessions;

    if (taskId) {
      var tasks = root.tasks.map(function(task) {
        if (task.id !== taskId) return task;
        var copy = {};
        for (var key in task) if (Object.prototype.hasOwnProperty.call(task, key)) copy[key] = task[key];
        copy.totalFocusSeconds = (Number(copy.totalFocusSeconds) || 0) + duration;
        if (session.kind === "pomo") copy.pomodoroSessions = (Number(copy.pomodoroSessions) || 0) + 1;
        else copy.flowtimeSessions = (Number(copy.flowtimeSessions) || 0) + 1;
        copy.interruptions = (Number(copy.interruptions) || 0) + session.interruptions;
        copy.updatedAt = now;
        return copy;
      });
      root.tasks = tasks;
    }
    return true;
  }

  function completePomodoro() {
    var current = root.timer;
    if (current.mode !== "pomodoro" || current.phase !== "running") return false;
    var focus = root.settings && root.settings.focus ? root.settings.focus : {};
    var focusSec = Math.max(60, Math.min(28800, Number(focus.focusSec) || 1500));
    var taskId = current.taskId;
    var taskTitle = current.taskTitle;
    root.recordSession("pomo", taskId, taskTitle, focusSec, 0,
      current.sessionStartedAtMs || current.startedAtMs);
    var done = (Number(current.pomodorosDone) || 0) + 1;
    var every = Math.max(1, Number(focus.longBreakInterval) || 4);
    var isLong = done % every === 0;
    var breakSec = isLong ? Number(focus.longBreakSec) || 0 : Number(focus.shortBreakSec) || 0;
    var next = Model.blankTimer();
    next.technique = "pomodoro";
    next.pomodorosDone = done;
    if (breakSec > 0) {
      var now = root.nowMs();
      next.mode = "pomodoro";
      next.phase = "break";
      next.taskId = taskId;
      next.taskTitle = taskTitle;
      next.breakKind = isLong ? "long" : "short";
      next.breakTotalMs = breakSec * 1000;
      next.startedAtMs = now;
      next.deadlineMs = now + breakSec * 1000;
      root.notify("timer", "Pomodoro complete",
        isLong ? "Focus phase complete. Your long break has started." : "Focus phase complete. Take a short break.");
    } else {
      root.notify("timer", "Pomodoro complete", "Well done. You are ready for the next session.");
    }
    root.timer = next;
    root.bump();
    root.saveNow();
    return true;
  }

  function completeBreak() {
    var current = root.timer;
    if (current.phase !== "break") return false;
    var next = Model.blankTimer();
    next.technique = current.technique === "flowtime" ? "flowtime" : "pomodoro";
    next.pomodorosDone = Math.max(0, Number(current.pomodorosDone) || 0);
    root.timer = next;
    root.notify("timer", "Break complete", "Time to get back into focus.");
    root.bump();
    root.saveNow();
    return true;
  }

  function finishFlowtime(finishKind) {
    var current = root.timer;
    if (current.mode !== "flowtime" || (current.phase !== "running" && current.phase !== "paused")) return false;
    var elapsedSec = Math.floor(TimerEngine.flowElapsedMs(current, root.nowMs()) / 1000);
    var taskId = current.taskId;
    var taskTitle = current.taskTitle;
    var interruptions = Math.max(0, Number(current.interruptions) || 0);
    if (elapsedSec >= 10) {
      root.recordSession("flow", taskId, taskTitle, elapsedSec, interruptions,
        current.sessionStartedAtMs || current.startedAtMs);
    }

    var next = Model.blankTimer();
    next.technique = "flowtime";
    next.pomodorosDone = Math.max(0, Number(current.pomodorosDone) || 0);
    if (finishKind === "break" && elapsedSec >= 10) {
      var flowSettings = root.settings && root.settings.flowtime ? root.settings.flowtime : {};
      var suggested = TimerEngine.suggestedBreakSec(elapsedSec, flowSettings);
      var now = root.nowMs();
      next.mode = "flowtime";
      next.phase = "break";
      next.taskId = taskId;
      next.taskTitle = taskTitle;
      next.breakKind = "flow";
      next.breakTotalMs = suggested * 1000;
      next.startedAtMs = now;
      next.deadlineMs = now + suggested * 1000;
      root.notify("timer", "Flowtime complete", "Focus saved. Take a " + Model.formatDur(suggested) + " break.");
    } else {
      root.notify("timer", "Flowtime complete", elapsedSec >= 10
        ? "Your focus session has been saved." : "Focus ended before a session could be recorded.");
    }
    root.timer = next;
    root.bump();
    root.saveNow();
    return true;
  }

  function updateFocusAction(action) {
    var focusAction = action === "flowtime" ? "flowtime" : "pomodoro";
    var nextSettings = {};
    for (var key in root.settings) {
      if (Object.prototype.hasOwnProperty.call(root.settings, key)) nextSettings[key] = root.settings[key];
    }
    var focusSettings = {};
    var source = root.settings && root.settings.focus ? root.settings.focus : {};
    for (var field in source) if (Object.prototype.hasOwnProperty.call(source, field)) focusSettings[field] = source[field];
    focusSettings.focusAction = focusAction;
    focusSettings.action = focusAction;
    nextSettings.focus = focusSettings;
    root.settings = nextSettings;
    if (root.timer.phase === "stopped" || root.timer.phase === "idle") {
      var timer = root.cloneTimer(root.timer);
      timer.technique = focusAction;
      root.timer = timer;
    }
    root.bump();
    root.saveSoon();
    return focusAction;
  }

  // ---- Eisenhower task board ----
  function tasksForColumn(columnId) {
    if (Model.COLUMNS.indexOf(String(columnId || "")) === -1) return [];
    var output = [];
    for (var i = 0; i < root.tasks.length; i++) {
      var task = root.tasks[i];
      if (task.boardId !== root.activeBoardId || task.columnId !== columnId || task.completedAt) continue;
      output.push(task);
    }
    output.sort(function(a, b) { return a.createdAt - b.createdAt || String(a.id).localeCompare(String(b.id)); });
    return output;
  }

  function allOpenTasks() {
    var output = [];
    for (var i = 0; i < Model.COLUMNS.length; i++) output = output.concat(root.tasksForColumn(Model.COLUMNS[i]));
    return output;
  }

  function completedTasks(query) {
    var search = String(query || "").trim().toLowerCase();
    var output = [];
    for (var i = 0; i < root.tasks.length; i++) {
      var task = root.tasks[i];
      if (task.boardId !== root.activeBoardId || !task.completedAt) continue;
      if (search !== "" && String(task.title || "").toLowerCase().indexOf(search) === -1) continue;
      output.push(task);
    }
    output.sort(function(a, b) { return (Number(b.completedAt) || 0) - (Number(a.completedAt) || 0); });
    return output;
  }

  function completedCount() {
    var count = 0;
    for (var i = 0; i < root.tasks.length; i++)
      if (root.tasks[i].boardId === root.activeBoardId && root.tasks[i].completedAt) count++;
    return count;
  }

  function activeTask() {
    if (root.activeTaskSource === "obsidian") {
      return root.activeTaskText ? { id: "", title: root.activeTaskText, source: "obsidian" } : null;
    }
    if (!root.activeTaskId) return null;
    for (var i = 0; i < root.tasks.length; i++) {
      var task = root.tasks[i];
      if (task.id === root.activeTaskId && task.boardId === root.activeBoardId && !task.completedAt) return task;
    }
    return null;
  }

  function setActiveTask(taskId) {
    var id = String(taskId === undefined || taskId === null ? "" : taskId);
    if (id !== "") {
      var exists = root.tasks.some(function(task) {
        return task.id === id && task.boardId === root.activeBoardId && !task.completedAt;
      });
      if (!exists) return false;
    }
    if (root.activeTaskSource === "matrix" && root.activeTaskId === id && root.activeTaskText === "") return true;
    root.activeTaskId = id;
    root.activeTaskSource = "matrix";
    root.activeTaskText = "";
    root.bump();
    root.saveSoon();
    return true;
  }

  function setActiveTaskFromObsidian(text) {
    var title = String(text || "").replace(/\s+/g, " ").trim().slice(0, 200);
    if (title === "") return root.setActiveTask("");
    if (root.activeTaskSource === "obsidian" && root.activeTaskText === title) return true;
    root.activeTaskId = "";
    root.activeTaskSource = "obsidian";
    root.activeTaskText = title;
    root.bump();
    root.saveSoon();
    return true;
  }

  function createTask(title, columnId) {
    var name = String(title || "").replace(/\s+/g, " ").trim().slice(0, 200);
    if (name === "") return "";
    var column = String(columnId || "q1");
    if (Model.COLUMNS.indexOf(column) === -1) column = "q1";
    var now = root.nowMs();
    var task = {
      id: Model.uid("task"),
      boardId: root.activeBoardId,
      columnId: column,
      title: name,
      description: "",
      priority: "normal",
      createdAt: now,
      updatedAt: now,
      completedAt: null,
      totalFocusSeconds: 0,
      pomodoroSessions: 0,
      flowtimeSessions: 0,
      interruptions: 0
    };
    root.tasks = root.tasks.concat([task]);
    root.bump();
    root.saveNow();
    return task.id;
  }

  function updateTask(taskId, fields) {
    var id = String(taskId || "");
    var patch = fields && typeof fields === "object" ? fields : {};
    var now = root.nowMs();
    var found = false;
    var nextTasks = root.tasks.map(function(task) {
      if (task.id !== id) return task;
      found = true;
      var copy = {};
      for (var key in task) if (Object.prototype.hasOwnProperty.call(task, key)) copy[key] = task[key];
      if (patch.title !== undefined) {
        var title = String(patch.title || "").replace(/\s+/g, " ").trim().slice(0, 200);
        if (title !== "") copy.title = title;
      }
      if (patch.description !== undefined) copy.description = String(patch.description || "").slice(0, 2000);
      if (patch.priority !== undefined && ["low", "normal", "high"].indexOf(patch.priority) !== -1)
        copy.priority = patch.priority;
      copy.updatedAt = now;
      return copy;
    });
    if (!found) return false;
    root.tasks = nextTasks;
    root.bump();
    root.saveNow();
    return true;
  }

  function moveTask(taskId, columnId) {
    var id = String(taskId || "");
    var column = String(columnId || "");
    if (Model.COLUMNS.indexOf(column) === -1) return false;
    var now = root.nowMs();
    var found = false;
    root.tasks = root.tasks.map(function(task) {
      if (task.id !== id || task.boardId !== root.activeBoardId) return task;
      found = true;
      var copy = {};
      for (var key in task) if (Object.prototype.hasOwnProperty.call(task, key)) copy[key] = task[key];
      copy.columnId = column;
      copy.completedAt = null;
      copy.updatedAt = now;
      return copy;
    });
    if (!found) return false;
    root.bump();
    root.saveNow();
    return true;
  }

  function completeTask(taskId) {
    var id = String(taskId || "");
    var now = root.nowMs();
    var found = false;
    root.tasks = root.tasks.map(function(task) {
      if (task.id !== id || task.boardId !== root.activeBoardId) return task;
      found = true;
      if (task.completedAt) return task;
      var copy = {};
      for (var key in task) if (Object.prototype.hasOwnProperty.call(task, key)) copy[key] = task[key];
      copy.completedAt = now;
      copy.updatedAt = now;
      return copy;
    });
    if (!found) return false;
    if (root.activeTaskSource === "matrix" && root.activeTaskId === id) {
      root.activeTaskId = "";
      root.activeTaskText = "";
    }
    root.bump();
    root.saveNow();
    return true;
  }

  function reopenTask(taskId) {
    var id = String(taskId || "");
    var now = root.nowMs();
    var found = false;
    root.tasks = root.tasks.map(function(task) {
      if (task.id !== id || task.boardId !== root.activeBoardId) return task;
      found = true;
      if (!task.completedAt) return task;
      var copy = {};
      for (var key in task) if (Object.prototype.hasOwnProperty.call(task, key)) copy[key] = task[key];
      if (Model.COLUMNS.indexOf(copy.columnId) === -1) copy.columnId = "q1";
      copy.completedAt = null;
      copy.updatedAt = now;
      return copy;
    });
    if (!found) return false;
    root.bump();
    root.saveNow();
    return true;
  }

  function deleteTask(taskId) {
    var id = String(taskId || "");
    var before = root.tasks.length;
    root.tasks = root.tasks.filter(function(task) { return task.id !== id; });
    if (root.tasks.length === before) return false;
    if (root.activeTaskSource === "matrix" && root.activeTaskId === id) {
      root.activeTaskId = "";
      root.activeTaskText = "";
    }
    if (root.timer.taskId === id) {
      var timer = root.cloneTimer(root.timer);
      timer.taskId = null;
      root.timer = timer;
    }
    root.bump();
    root.saveNow();
    return true;
  }

  function history(range, kind) {
    return StatsEngine.filterSessions(root.sessions, range || "today", kind || "both", root.nowMs());
  }

  function sessionSummary(range, kind) {
    return StatsEngine.summarize(root.history(range || "all", kind || "both"));
  }

  function focusStreak(minimumSeconds) {
    return StatsEngine.streak(root.sessions, minimumSeconds, root.nowMs());
  }

  function lastWeekSessions() {
    return StatsEngine.lastWeek(root.sessions, root.nowMs());
  }

  // ---- Statistics and history ----
  function liveExtraSec() {
    var current = root.timer;
    if (current.phase !== "running") return 0;
    if (current.mode === "pomodoro") {
      var focus = root.settings && root.settings.focus ? root.settings.focus : {};
      var totalMs = Math.max(60, Number(focus.focusSec) || 1500) * 1000;
      return Math.max(0, Math.floor((totalMs - TimerEngine.pomodoroRemainingMs(current, root.nowMs())) / 1000));
    }
    if (current.mode === "flowtime") return Math.floor(TimerEngine.flowElapsedMs(current, root.nowMs()) / 1000);
    return 0;
  }

  function todaySummary() {
    var rows = StatsEngine.filterSessions(root.sessions, "today", "both", root.nowMs());
    var summary = StatsEngine.summarize(rows);
    summary.focusSec += root.liveExtraSec();
    summary.tasksDone = StatsEngine.tasksDoneOnDay(root.tasks, root.nowMs());
    var statsSettings = root.settings && root.settings.stats ? root.settings.stats : {};
    summary.streak = StatsEngine.streak(root.sessions, statsSettings.streakMinSec, root.nowMs());
    summary.pomoCount = summary.pomodoroSessions;
    summary.flowCount = summary.flowtimeSessions;
    return summary;
  }

  function weekData() {
    return StatsEngine.thisWeek(root.sessions, root.nowMs());
  }

  function heatmapData(weeks) {
    return StatsEngine.heatmap(root.sessions, weeks || 12, root.nowMs());
  }

  // ---- Markets and converter API ----
  function marketsRefresh() { marketsData.refresh(); }
  function marketsFetchSeries(symbol, range) { marketsData.fetchSeries(symbol, range); }
  function marketsSeries(symbol, range) {
    return marketsData.seriesFor(symbol, range);
  }
  function marketsSeriesStatus() { return marketsData.seriesError; }
  function marketsAgeLabel() {
    return MarketsModel.ageLabel(marketsData.lastFetch, root.nowMs());
  }
  function quoteFor(symbol) {
    var value = MarketsModel.normalizeSymbol(symbol);
    for (var i = 0; i < root.quotes.length; i++)
      if (root.quotes[i].symbol === value) return root.quotes[i];
    return null;
  }
  function binanceTradeUrl(symbol) {
    var ids = root.settings && root.settings.markets && root.settings.markets.watchlist
      ? root.settings.markets.watchlist.coinIds : {};
    return MarketsModel.binanceTradeUrlFor(symbol, ids);
  }
  function searchSymbols(query) { marketsData.searchSymbols(query); }

  function socialPlatformStatus(platform) {
    var key = String(platform || "").toLowerCase();
    var connectors = [telegramConnector, whatsappConnector, signalConnector, discordConnector, matrixConnector];
    for (var i = 0; i < connectors.length; i++)
      if (connectors[i].platform === key) return connectors[i].statusText;
    return "No compatible local adapter is available.";
  }

  function combinedSocialEvents() {
    var output = [];
    var enabled = root.settings && root.settings.social ? root.settings.social : {};
    var socialEvents = Array.isArray(socialData.events) ? socialData.events : [];
    for (var i = 0; i < socialEvents.length; i++)
      if (enabled[socialEvents[i].platform] === true) output.push(socialEvents[i]);
    var emailEvents = Array.isArray(emailData.events) ? emailData.events : [];
    for (var j = 0; j < emailEvents.length; j++) output.push(emailEvents[j]);
    return SocialModel.mergeEvents([output]);
  }

  function socialAccounts() {
    var output = [];
    var enabled = root.settings && root.settings.social ? root.settings.social : {};
    var localAccounts = Array.isArray(socialData.accounts) ? socialData.accounts : [];
    for (var i = 0; i < localAccounts.length; i++) {
      var platform = localAccounts[i].platform;
      if (enabled[platform] !== true) continue;
      var localAccount = {};
      for (var key in localAccounts[i]) if (Object.prototype.hasOwnProperty.call(localAccounts[i], key)) localAccount[key] = localAccounts[i][key];
      output.push(localAccount);
    }
    var mailAccounts = Array.isArray(emailData.accounts) ? emailData.accounts : [];
    for (var j = 0; j < mailAccounts.length; j++) {
      var account = mailAccounts[j];
      output.push({
        id: account.id,
        platform: "email",
        glyph: SocialModel.accountGlyph("email"),
        name: account.name || account.email || "Email account",
        accountName: account.name || account.email || "Email account",
        email: account.email || "",
        status: emailData.statusForAccount(account.id)
      });
    }
    return output;
  }

  function socialUnread(accountId) {
    var now = root.nowMs();
    var rows = SocialModel.unreadConversations(root.combinedSocialEvents(), accountId, now);
    for (var i = 0; i < rows.length; i++) {
      rows[i].glyph = SocialModel.accountGlyph(rows[i].platform);
      rows[i].timeLabel = SocialModel.timeLabel(rows[i].timestamp, now);
    }
    return rows;
  }

  function socialRecentCalls(accountId) {
    var now = root.nowMs();
    var rows = SocialModel.recentCalls(root.combinedSocialEvents(), accountId, now);
    var output = [];
    for (var i = 0; i < rows.length; i++) {
      var event = rows[i];
      var state = event.callState;
      output.push({
        id: event.id,
        accountId: event.accountId,
        platform: event.platform,
        glyph: SocialModel.callGlyph(state),
        name: event.chat.name || event.sender.name,
        accountName: event.accountName,
        kind: state,
        kindLabel: state === "missed" ? "Missed call" : state === "outgoing" ? "Outgoing call" : "Incoming call",
        timeLabel: SocialModel.timeLabel(event.timestamp, now)
      });
    }
    return output;
  }

  function socialRinging() {
    var event = SocialModel.ringingCall(root.combinedSocialEvents());
    if (!event) return null;
    return {
      id: event.id,
      callId: event.id,
      accountId: event.accountId,
      platform: event.platform,
      name: event.chat.name || event.sender.name,
      accountName: event.accountName,
      timestamp: event.timestamp
    };
  }

  function socialThread(accountId, chatId) {
    var rows = SocialModel.threadEvents(root.combinedSocialEvents(), accountId, chatId);
    var output = [];
    for (var i = 0; i < rows.length; i++) {
      var event = rows[i];
      output.push({
        id: event.id,
        messageId: event.messageId,
        uid: event.uid,
        platform: event.platform,
        accountId: event.accountId,
        chatId: event.chat.id,
        subject: event.subject,
        sender: event.sender.name,
        senderName: event.sender.name,
        from: event.from || event.sender.name,
        fromEmail: event.sender.email,
        to: event.to,
        cc: event.cc,
        body: event.body,
        timestamp: event.timestamp,
        timeLabel: SocialModel.timeLabel(event.timestamp, root.nowMs()),
        unread: event.chat.unread,
        hasAttachments: event.hasAttachments,
        attachmentNames: event.attachmentNames,
        inReplyTo: event.inReplyTo,
        references: event.references,
        threadId: event.chat.id,
        accountName: event.accountName
      });
    }
    return output;
  }

  function socialMarkRead(accountId, chatId, platform) {
    if (String(platform || "") === "email") return emailData.markThreadRead(accountId, chatId);
    return socialData.markRead(String(platform || ""), String(accountId || ""), String(chatId || ""));
  }

  function socialSend(platform, accountId, chatId, text) {
    if (String(platform || "") === "email") return false;
    return socialData.send(String(platform || ""), String(accountId || ""), String(chatId || ""), String(text || ""));
  }

  function socialAnswerCall(call) {
    return call ? socialData.callAction("answer", call.platform, call.id || call.callId) : false;
  }

  function socialDeclineCall(call) {
    return call ? socialData.callAction("decline", call.platform, call.id || call.callId) : false;
  }

  function emailAccountById(accountId) { return emailData.accountById(accountId); }
  function emailAccountStatus(accountId) { return emailData.statusForAccount(accountId); }
  function emailSend(accountId, payload) { return emailData.send(accountId, payload); }
  function emailStoreCredential(accountId, secret) { return emailData.storeCredential(accountId, secret); }
  function emailClearCredential(accountId) { return emailData.clearCredential(accountId); }
  function emailRefresh() { return emailData.restartWatcher(); }

  function emailAddAccount(initialValues) {
    var accounts = root.settings && root.settings.email && Array.isArray(root.settings.email.accounts)
      ? root.settings.email.accounts.slice() : [];
    if (accounts.length >= 32) return "";
    var supplied = initialValues && typeof initialValues === "object" ? initialValues : {};
    var account = {
      id: Model.uid("mail"),
      name: String(supplied.name || "Email account"),
      email: String(supplied.email || ""),
      username: String(supplied.username || ""),
      imapHost: String(supplied.imapHost || ""),
      imapPort: Number(supplied.imapPort) || 993,
      smtpHost: String(supplied.smtpHost || ""),
      smtpPort: Number(supplied.smtpPort) || 587,
      tls: true
    };
    accounts.push(account);
    return root.updateSettings("email", { accounts: accounts }) ? account.id : "";
  }

  function emailUpdateAccount(accountId, patch) {
    var accounts = root.settings && root.settings.email && Array.isArray(root.settings.email.accounts)
      ? root.settings.email.accounts.slice() : [];
    var id = String(accountId || "");
    var allowed = ["name", "email", "username", "imapHost", "imapPort", "smtpHost", "smtpPort"];
    var changed = false;
    for (var i = 0; i < accounts.length; i++) {
      if (accounts[i].id !== id) continue;
      var nextAccount = {};
      for (var key in accounts[i]) if (Object.prototype.hasOwnProperty.call(accounts[i], key)) nextAccount[key] = accounts[i][key];
      for (var j = 0; j < allowed.length; j++) {
        var field = allowed[j];
        if (patch && Object.prototype.hasOwnProperty.call(patch, field)) nextAccount[field] = patch[field];
      }
      accounts[i] = nextAccount;
      changed = true;
      break;
    }
    return changed && root.updateSettings("email", { accounts: accounts });
  }

  function emailRemoveAccount(accountId) {
    var id = String(accountId || "");
    var accounts = root.settings && root.settings.email && Array.isArray(root.settings.email.accounts)
      ? root.settings.email.accounts.slice() : [];
    var nextAccounts = accounts.filter(function(account) { return account.id !== id; });
    if (nextAccounts.length === accounts.length) return false;
    if (!root.updateSettings("email", { accounts: nextAccounts })) return false;
    emailData.clearAccount(id);
    return true;
  }

  function obsidianTestConnection() { obsidianData.testConnection(); }

  function resetAll() {
    var existingAccounts = root.settings && root.settings.email && Array.isArray(root.settings.email.accounts)
      ? root.settings.email.accounts.slice() : [];
    for (var i = 0; i < existingAccounts.length; i++) emailData.clearCredential(existingAccounts[i].id);
    root.persistenceBlocked = false;
    var blank = Model.blankState();
    root.settings = blank.settings;
    root.boards = blank.boards;
    root.tasks = blank.tasks;
    root.sessions = blank.sessions;
    root.activeBoardId = blank.activeBoardId;
    root.activeTaskId = "";
    root.activeTaskSource = blank.activeTaskSource;
    root.activeTaskText = "";
    root.timer = blank.timer;
    root.dataStatusMessage = "Kairos data reset. Email keyring removal was requested; completion depends on Secret Service availability.";
    root.bump();
    root.saveSoon();
    return true;
  }

  function updateMarketsSettings(nextMarkets) {
    var settings = {};
    var source = root.settings || {};
    for (var key in source) if (Object.prototype.hasOwnProperty.call(source, key)) settings[key] = source[key];
    var markets = {};
    var oldMarkets = source.markets || {};
    for (var field in oldMarkets) if (Object.prototype.hasOwnProperty.call(oldMarkets, field)) markets[field] = oldMarkets[field];
    for (var nextField in nextMarkets) if (Object.prototype.hasOwnProperty.call(nextMarkets, nextField)) markets[nextField] = nextMarkets[nextField];
    settings.markets = markets;
    root.settings = settings;
    root.bump();
    root.saveSoon();
  }

  function watchlistAdd(symbol, coinId) {
    var current = root.settings && root.settings.markets ? root.settings.markets.watchlist : null;
    var next = MarketsModel.addSymbol(current, symbol, coinId);
    if (JSON.stringify(next) === JSON.stringify(current || MarketsModel.defaultWatchlist())) return false;
    root.updateMarketsSettings({ watchlist: next });
    return true;
  }

  function watchlistRemove(symbol) {
    var current = root.settings && root.settings.markets ? root.settings.markets.watchlist : null;
    var next = MarketsModel.removeSymbol(current, symbol);
    if (current && next.symbols.length === current.symbols.length
        && JSON.stringify(next.coinIds) === JSON.stringify(current.coinIds || {})) return false;
    root.updateMarketsSettings({ watchlist: next });
    return true;
  }

  function watchlistMove(fromIndex, toIndex) {
    var current = root.settings && root.settings.markets ? root.settings.markets.watchlist : null;
    var next = MarketsModel.moveSymbol(current, fromIndex, toIndex);
    if (JSON.stringify(next) === JSON.stringify(current || MarketsModel.defaultWatchlist())) return false;
    root.updateMarketsSettings({ watchlist: next });
    return true;
  }

  function cycleCurrency(step) {
    var markets = root.settings && root.settings.markets ? root.settings.markets : {};
    var ring = Array.isArray(markets.currencies) && markets.currencies.length > 0
      ? markets.currencies : ["USD", "EUR", "BRL"];
    var current = String(markets.currency || "USD");
    var index = ring.indexOf(current);
    if (index < 0) index = 0;
    var direction = Number(step) < 0 ? -1 : 1;
    var nextIndex = (index + direction + ring.length) % ring.length;
    var currencyCode = String(ring[nextIndex] || "USD");
    if (currencyCode === current) return current;
    root.updateMarketsSettings({ currency: currencyCode });
    return currencyCode;
  }

  function converterStatus(mode) {
    if (mode === "units") return "Local conversion · no network needed";
    if (mode === "crypto") {
      if (converterData.cryptoError !== "" && converterData.cryptoFetchedAt === 0) return converterData.cryptoError;
      var cryptoAge = MarketsModel.ageLabel(converterData.cryptoFetchedAt, root.nowMs());
      return "Crypto rates " + cryptoAge + (converterData.cryptoStale ? " · cached" : "");
    }
    if (converterData.ratesError !== "" && converterData.ratesFetchedAt === 0) return converterData.ratesError;
    var ratesAge = MarketsModel.ageLabel(converterData.ratesFetchedAt, root.nowMs());
    return "Fiat rates " + ratesAge + (converterData.ratesStale ? " · cached" : "");
  }

  function convertCurrency(amount, from, to) {
    return ConverterModel.convertCross(amount, from, to, converterData.currencyRates, converterData.cryptoPrices);
  }

  function convertUnit(amount, category, from, to) {
    return ConverterModel.convertUnit(amount, category, from, to);
  }

  function converterRefresh(force) { converterData.refresh(force === true); }

  CalendarService {
    id: calendarData
    service: root
  }

  ObsidianService {
    id: obsidianData
    service: root
  }

  MarketsService {
    id: marketsData
    service: root
  }

  ConverterService {
    id: converterData
    service: root
  }

  SocialService {
    id: socialData
    service: root
  }

  EmailService {
    id: emailData
    service: root
  }

  TelegramConnector { id: telegramConnector; service: socialData }
  WhatsAppConnector { id: whatsappConnector; service: socialData }
  SignalConnector { id: signalConnector; service: socialData }
  DiscordConnector { id: discordConnector; service: socialData }
  MatrixConnector { id: matrixConnector; service: socialData }
  EmailConnector { id: emailConnector; service: emailData }

  // ---- Persistence ----
  FileView {
    id: stateFile
    watchChanges: false
    atomicWrites: true
    printErrors: false
    onLoaded: root.applyLoadedText(text())
    onLoadFailed: function(error) {
      if (error === FileViewError.FileNotFound) {
        root.applyBlank();
        return;
      }
      console.warn("Kairos: state load failed; backing up and starting fresh: " + error);
      root.backupThenBlank();
    }
    onSaveFailed: function(error) {
      console.warn("Kairos: state save failed: " + error);
    }
  }

  Timer {
    id: saveDebounce
    interval: 800
    repeat: false
    onTriggered: root.saveNow()
  }

  Process {
    id: mkdirProc
    onExited: function(exitCode) {
      if (exitCode !== 0)
        console.warn("Kairos: could not create the state directory (exit " + exitCode + ")");
      stateFile.path = root.stateFilePath;
    }
  }

  Process {
    id: backupProc
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        console.warn("Kairos: state backup failed (exit " + exitCode + "); the existing state file will not be overwritten.");
        saveDebounce.stop();
        root.persistenceBlocked = true;
        root.dataStatusMessage = "Corrupt state backup failed. The original file was left untouched; reset data explicitly to replace it.";
        root.applyState(Model.blankState());
        root.stateLoaded = true;
        return;
      }
      root.dataStatusMessage = "Corrupt state was backed up before a fresh state was created.";
      root.applyBlank();
    }
  }

  function saveSoon() {
    if (!root.stateLoaded || root.persistenceBlocked) return;
    saveDebounce.restart();
  }

  function saveNow() {
    if (!root.stateLoaded || root.persistenceBlocked || root.stateFilePath === "") return;
    try {
      stateFile.setText(root.serializeState());
    } catch (error) {
      console.warn("Kairos: save failed: " + error);
    }
  }

  function serializeState() {
    return JSON.stringify({
      schemaVersion: Model.SCHEMA_VERSION,
      settings: root.settings,
      boards: root.boards,
      tasks: root.tasks,
      sessions: root.sessions,
      activeBoardId: root.activeBoardId,
      activeTaskId: root.activeTaskId === "" ? null : root.activeTaskId,
      activeTaskSource: root.activeTaskSource,
      activeTaskText: root.activeTaskText,
      timer: root.timer
    }, null, 2) + "\n";
  }

  function applyBlank() {
    var clean = Model.blankState();
    root.applyState(clean);
    root.stateLoaded = true;
    root.saveNow();
  }

  function backupThenBlank() {
    if (root.stateFilePath === "") {
      root.applyBlank();
      return;
    }
    backupProc.command = ["cp", "--", root.stateFilePath, root.stateFilePath + ".corrupt-" + String(Date.now())];
    backupProc.running = true;
  }

  function applyLoadedText(text) {
    var raw = null;
    try {
      raw = JSON.parse(text);
    } catch (error) {
      console.warn("Kairos: corrupt state; backing up and starting fresh");
      root.backupThenBlank();
      return;
    }
    var result = Model.sanitizeState(raw);
    root.applyState(result.state);
    root.stateLoaded = true;
    if (result.repaired) root.saveNow();
  }

  function applyState(state) {
    root.settings = state.settings;
    root.boards = state.boards;
    root.tasks = state.tasks;
    root.sessions = state.sessions;
    root.activeBoardId = state.activeBoardId;
    root.activeTaskId = state.activeTaskId || "";
    root.activeTaskSource = state.activeTaskSource || "matrix";
    root.activeTaskText = String(state.activeTaskText || "");
    root.timer = state.timer;
    root.bump();
  }

  Timer {
    id: tick
    interval: 1000
    repeat: true
    running: root.isTicking()
    onTriggered: root.onTick()
  }

  function onTick() {
    root.tickVersion++;
    var current = root.timer;
    if (current.phase !== "running" && current.phase !== "break") return;
    if (current.mode === "flowtime" && current.phase === "running") return;
    if ((Number(current.deadlineMs) || 0) > root.nowMs()) return;
    if (current.mode === "pomodoro" && current.phase === "running") root.completePomodoro();
    else if (current.phase === "break") root.completeBreak();
  }

  // ---- Panel routing ----
  function openView(view) {
    root.pendingView = String(view || "day");
    var payload = JSON.stringify({ view: root.pendingView });
    if (root.shell && typeof root.shell.summon === "function") {
      root.shell.summon(root.pluginId, payload);
      return;
    }
    Quickshell.execDetached(["omarchy-shell", "shell", "summon", root.pluginId, payload]);
  }

  function consumePendingView() {
    var view = root.pendingView;
    root.pendingView = "";
    return view;
  }

  function togglePanel() {
    if (root.shell && typeof root.shell.toggle === "function") {
      root.shell.toggle(root.pluginId, "{}");
      return;
    }
    Quickshell.execDetached(["omarchy-shell", "shell", "toggle", root.pluginId, "{}"]);
  }

  // ---- Global Hyprland shortcuts ----
  function shortcutChordOf(id) {
    var parts = String(id || "").split("+");
    if (parts.length === 0) return "";
    var normalized = [];
    for (var i = 0; i < parts.length; i++) {
      var key = parts[i].trim().toUpperCase();
      if (!/^[A-Z0-9_]+$/.test(key)) return "";
      normalized.push(key);
    }
    return normalized.join(" + ");
  }

  function applyShortcuts() {
    var lines = [];
    var chords = [];
    for (var i = 0; i < root.appliedShortcutChords.length; i++) {
      var oldChord = root.appliedShortcutChords[i];
      lines.push('pcall(function() hl.unbind("' + oldChord + '") end)');
    }

    var shortcutSettings = root.settings && root.settings.shortcuts ? root.settings.shortcuts : {};
    var binds = [
      { id: shortcutSettings.toggleShortcut, command: "omarchy-shell io.github.yks777.kairos togglePanel" },
      { id: shortcutSettings.focusShortcut, command: "omarchy-shell io.github.yks777.kairos start" },
      { id: shortcutSettings.flowtimeShortcut, command: "omarchy-shell io.github.yks777.kairos startFlowtime" }
    ];
    for (var j = 0; j < binds.length; j++) {
      var chord = root.shortcutChordOf(binds[j].id);
      if (chord === "") continue;
      chords.push(chord);
      lines.push('pcall(function() hl.unbind("' + chord + '") end)');
      lines.push('hl.bind("' + chord + '", hl.dsp.exec_cmd("' + binds[j].command
        + '"), { description = "Kairos" })');
    }
    root.appliedShortcutChords = chords;
    if (lines.length > 0) Quickshell.execDetached(["hyprctl", "eval", lines.join("; ")]);
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (event && event.name === "configreloaded") shortcutReload.restart();
    }
  }

  Timer {
    id: shortcutReload
    interval: 300
    repeat: false
    onTriggered: {
      root.appliedShortcutChords = [];
      root.applyShortcuts();
    }
  }

  onSettingsChanged: {
    root.applyShortcuts();
    root.calendarChanged();
  }

  IpcHandler {
    target: "io.github.yks777.kairos"

    function ping(): string { return "ok"; }
    function isOpen(): string {
      if (root.shell && typeof root.shell.isPluginOpen === "function")
        return root.shell.isPluginOpen(root.pluginId) ? "true" : "false";
      return "unknown";
    }
    function togglePanel(): string { root.togglePanel(); return "ok"; }
    function day(): string { root.openView("day"); return "ok"; }
    function focus(): string { root.openView("focus"); return "ok"; }
    function plan(): string { root.openView("plan"); return "ok"; }
    function stats(): string { root.openView("stats"); return "ok"; }
    function markets(): string { root.openView("markets"); return "ok"; }
    function social(): string { root.openView("social"); return "ok"; }
    function email(): string { root.openView("social"); return "ok"; }
    function settings(): string { root.openView("settings"); return "ok"; }
    function refreshSocial(): string { socialData.refresh(); return "ok"; }
    function refreshEmail(): string { emailData.restartWatcher(); return "ok"; }
    function sendEmail(accountId: string, payloadJson: string): string {
      var payload = null;
      try { payload = JSON.parse(payloadJson); } catch (error) { return "invalid-payload"; }
      return emailData.send(accountId, payload) ? "queued" : "not-queued";
    }
    function start(): string { root.startTimer(); return "ok"; }
    function startFlowtime(): string { root.startFlowtime(); return "ok"; }
    function pause(): string { root.pauseTimer(); return "ok"; }
    function resume(): string { root.resumeTimer(); return "ok"; }
    function stop(): string { root.stopTimer(); return "ok"; }
    function finish(kind: string): string {
      var onBreak = root.timer.phase === "break"
        || (root.timer.phase === "paused" && root.timer.pausedPhase === "break");
      if (onBreak) root.skipBreak();
      else if (root.timer.mode === "flowtime") root.finishFlowtime(kind === "break" ? "break" : "focus");
      else if (root.timer.phase === "running") root.completePomodoro();
      return "ok";
    }
    function interrupt(): string { root.addInterruption(); return "ok"; }
    function status(): string {
      return JSON.stringify({
        timer: {
          mode: root.timer.mode,
          phase: root.timer.phase,
          technique: root.timer.technique,
          taskId: root.timer.taskId,
          taskTitle: root.timer.taskTitle,
          remainingMs: root.timerRemainingMs(),
          elapsedMs: root.flowElapsedMs(),
          interruptions: root.timer.interruptions,
          pomodorosDone: root.timer.pomodorosDone
        },
        calendar: {
          khal: calendarData.khalAvailable,
          events: calendarData.events.length,
          lastRefresh: calendarData.lastRefresh,
          error: calendarData.lastError,
          syncing: calendarData.syncing,
          syncError: calendarData.syncError
        },
        obsidian: { enabled: obsidianData.obsidianEnabled, noteLoaded: obsidianData.noteLoaded, error: obsidianData.lastError },
        social: { bridgeAvailable: socialData.bridgeAvailable, accounts: socialData.accounts.length, events: socialData.events.length, status: socialData.statusText },
        email: { available: emailData.available, accounts: emailData.accounts.length, status: emailData.statusText },
        revision: root.revision,
        stateLoaded: root.stateLoaded
      });
    }
  }

  Component.onCompleted: {
    root.stateDirPath = Storage.dataDir(Quickshell.env);
    root.stateFilePath = Storage.statePath(Quickshell.env);
    mkdirProc.command = ["mkdir", "-p", root.stateDirPath];
    mkdirProc.running = true;
    root.applyShortcuts();
  }

  Component.onDestruction: {
    var lines = [];
    for (var i = 0; i < root.appliedShortcutChords.length; i++) {
      lines.push('pcall(function() hl.unbind("' + root.appliedShortcutChords[i] + '") end)');
    }
    if (lines.length > 0) Quickshell.execDetached(["hyprctl", "eval", lines.join("; ")]);
  }
}

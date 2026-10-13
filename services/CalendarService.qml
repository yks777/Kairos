import QtQuick
import Quickshell
import Quickshell.Io
import "../logic/CalendarModel.js" as CalendarModel
import "../logic/Storage.js" as Storage

Item {
  id: root

  property var service: null
  property bool settled: false
  property bool khalAvailable: true
  property bool syncAvailable: true
  property bool syncing: false
  property bool notificationsEnabled: true
  property int agendaDays: 7
  property int leadMinutes: 10
  property int syncIntervalMinutes: 15
  property string syncCommand: "vdirsyncer sync"
  property string timeFormat: "Match khal"
  property string mapsProvider: "Google Maps"
  property string lastError: ""
  property string syncError: ""
  property double lastRefresh: 0
  property double lastSync: 0
  property var formats: null
  property var events: []
  property var monthEvents: ({})
  property var icsDetails: ({})
  property var notified: ({})
  property bool notifiedReady: false
  property int rangeGeneration: 0
  property bool refreshPending: false
  property string pendingRangeKey: ""
  property int pendingRangeYear: 0
  property int pendingRangeMonth: 0
  property var lastRequestedMonth: null
  property string cacheDirPath: ""
  property string monthCachePath: ""
  property string notifiedPath: ""
  property string observedCalendarConfig: ""

  readonly property string statusText: !root.khalAvailable
    ? "khal is not installed."
    : root.lastError
  readonly property bool use24h: root.timeFormat === "12-hour" ? false
    : root.timeFormat === "24-hour" ? true : !root.formats || root.formats.use24h !== false

  readonly property var allEvents: {
    var result = [];
    var seen = {};
    function append(event) {
      if (!event) return;
      var key = String(event.key || (String(event.uid || "") + "|" + String(event.start || "")));
      if (seen[key]) return;
      seen[key] = true;
      result.push(event);
    }
    var current = root.events || [];
    for (var i = 0; i < current.length; i++) append(current[i]);
    var months = root.monthEvents || {};
    for (var monthKey in months) {
      if (!Object.prototype.hasOwnProperty.call(months, monthKey)) continue;
      var item = months[monthKey];
      var rows = item && item.events ? item.events : [];
      for (var j = 0; j < rows.length; j++) append(rows[j]);
    }
    result.sort(function(a, b) { return a.start - b.start || String(a.title).localeCompare(String(b.title)); });
    return result;
  }
  readonly property var eventsByDay: CalendarModel.eventsByDay(root.allEvents)

  function env(name) {
    try { return Quickshell.env(name); } catch (error) { return ""; }
  }

  function parentPath(path) {
    var value = String(path || "");
    var slash = value.lastIndexOf("/");
    return slash <= 0 ? "/" : value.slice(0, slash);
  }

  function bumpService() {
    if (root.service && typeof root.service.bump === "function") root.service.bump();
  }

  function bumpEvents() {
    if (root.service && typeof root.service.calendarChanged === "function") root.service.calendarChanged();
    else root.bumpService();
  }

  function configure() {
    var settings = root.service && root.service.settings ? root.service.settings : {};
    var calendar = settings.calendar || {};
    var configKey = "";
    try {
      configKey = JSON.stringify({
        calendar: calendar,
        notificationsEnabled: !(settings.notifications && settings.notifications.enabled === false)
      });
    } catch (error) { configKey = "{}"; }
    var changed = configKey !== root.observedCalendarConfig;
    if (changed) root.observedCalendarConfig = configKey;
    if (root.service && root.service.stateLoaded) root.settled = true;
    if (!changed) {
      root.checkNotifications();
      return;
    }
    root.agendaDays = Math.max(1, Math.min(60, Math.floor(Number(calendar.agendaDays) || 7)));
    root.leadMinutes = Math.max(0, Math.min(120, Math.floor(Number(calendar.leadMinutes) || 0)));
    root.notificationsEnabled = calendar.notifications !== false
      && !(settings.notifications && settings.notifications.enabled === false);
    root.syncIntervalMinutes = Math.max(0, Math.min(1440, Math.floor(Number(calendar.syncIntervalMinutes) || 0)));
    root.syncCommand = String(calendar.syncCommand === undefined ? "vdirsyncer sync" : calendar.syncCommand);
    root.timeFormat = String(calendar.timeFormat || "Match khal");
    root.mapsProvider = String(calendar.mapsProvider || "Google Maps");
    if (root.settled && root.formats && root.formats.ok && !listProc.running) root.refresh();
    root.checkNotifications();
  }

  function refresh() {
    if (!root.khalAvailable) return;
    if (root.formats && root.formats.ok === false) return;
    if (formatsProc.running) {
      root.refreshPending = true;
      return;
    }
    if (!root.formats || !root.formats.ok) {
      if (!formatsProc.running) formatsProc.running = true;
      root.refreshPending = true;
      return;
    }
    if (listProc.running) {
      root.refreshPending = true;
      return;
    }
    var args = CalendarModel.khalListArgs(root.agendaDays, Date.now(), root.formats);
    if (!args.length) {
      root.lastError = CalendarModel.SAMPLE_ERROR;
      root.bumpService();
      return;
    }
    listProc.output = "";
    listProc.command = args;
    listProc.running = true;
  }

  function reload() {
    root.formats = null;
    root.khalAvailable = true;
    root.lastError = "";
    root.invalidateMonths();
    if (!formatsProc.running) formatsProc.running = true;
  }

  function loadMonth(year, month) {
    if (!root.khalAvailable || (root.formats && root.formats.ok === false)) return;
    var y = Math.floor(Number(year));
    var m = Math.floor(Number(month));
    if (!isFinite(y) || !isFinite(m) || m < 0 || m > 11) return;
    var key = CalendarModel.monthKey(y, m);
    root.lastRequestedMonth = { year: y, month: m, key: key };
    var cached = root.monthEvents[key];
    if (cached && cached.generation === root.rangeGeneration) return;
    if (!root.formats || !root.formats.ok) {
      root.pendingRangeKey = key;
      root.pendingRangeYear = y;
      root.pendingRangeMonth = m;
      if (!formatsProc.running) formatsProc.running = true;
      return;
    }
    if (rangeProc.running) {
      root.pendingRangeKey = key;
      root.pendingRangeYear = y;
      root.pendingRangeMonth = m;
      return;
    }
    root.startRange(y, m, key);
  }

  function startRange(year, month, key) {
    if (rangeProc.running || !root.formats || !root.formats.ok) return;
    var range = CalendarModel.monthRange(year, month);
    var args = CalendarModel.khalRangeArgs(range.start, range.days, root.formats);
    if (!args.length) {
      root.lastError = CalendarModel.SAMPLE_ERROR;
      root.bumpService();
      return;
    }
    rangeProc.key = String(key || CalendarModel.monthKey(year, month));
    rangeProc.year = Number(year);
    rangeProc.month = Number(month);
    rangeProc.generation = root.rangeGeneration;
    rangeProc.output = "";
    rangeProc.command = args;
    rangeProc.running = true;
  }

  function startPendingRange() {
    if (rangeProc.running || root.pendingRangeKey === "" || !root.formats || !root.formats.ok) return;
    var key = root.pendingRangeKey;
    var year = root.pendingRangeYear;
    var month = root.pendingRangeMonth;
    root.pendingRangeKey = "";
    root.startRange(year, month, key);
  }

  function invalidateMonths() {
    root.rangeGeneration++;
    root.icsDetails = ({ });
    if (root.lastRequestedMonth) {
      root.pendingRangeKey = root.lastRequestedMonth.key;
      root.pendingRangeYear = root.lastRequestedMonth.year;
      root.pendingRangeMonth = root.lastRequestedMonth.month;
    }
    if (!rangeProc.running) Qt.callLater(root.startPendingRange);
  }

  function requestSync() {
    root.sync();
  }

  function sync() {
    if (root.syncing || !root.syncAvailable) return;
    var args = CalendarModel.safeCommandArgs(root.syncCommand);
    if (!args.length) {
      root.syncError = "Sync command contains unsupported shell syntax.";
      root.bumpService();
      return;
    }
    syncProc.command = args;
    root.syncing = true;
    syncWatchdog.fired = false;
    syncProc.running = true;
  }

  function detailsForEvent(event) {
    var ics = null;
    var uid = String(event && event.uid || "");
    if (uid && Object.prototype.hasOwnProperty.call(root.icsDetails, uid)) ics = root.icsDetails[uid];
    return CalendarModel.eventDetails(event, ics, root.mapsProvider);
  }

  function loadDetails(uid) {
    var value = String(uid || "");
    if (!value || Object.prototype.hasOwnProperty.call(root.icsDetails, value)) return;
    if (root.detailQueue.indexOf(value) !== -1) return;
    var next = root.detailQueue.slice();
    next.push(value);
    root.detailQueue = next;
    root.startNextDetail();
  }

  function startNextDetail() {
    if (detailProc.running || root.detailQueue.length === 0) return;
    var queue = root.detailQueue.slice();
    var uid = queue.shift();
    root.detailQueue = queue;
    detailProc.uid = uid;
    detailProc.output = "";
    detailProc.command = ["bash", "-c", CalendarModel.ICS_LOOKUP_SCRIPT, "kairos-ics-lookup", uid];
    detailProc.running = true;
  }

  function checkNotifications() {
    if (!root.notifiedReady || !root.settled || !root.notificationsEnabled || !root.service) return;
    var now = Date.now();
    var next = CalendarModel.pruneNotified(root.notified, now);
    var due = CalendarModel.dueNotifications(root.events, now, root.leadMinutes, next);
    var changed = Object.keys(next).length !== Object.keys(root.notified || {}).length;
    for (var i = 0; i < due.length; i++) {
      var event = due[i];
      next[event.key] = event.start;
      changed = true;
      if (typeof root.service.notify === "function") {
        root.service.notify(
          "calendar",
          CalendarModel.notificationTitle(event),
          CalendarModel.notificationBody(event, now, root.use24h)
        );
      }
    }
    root.notified = next;
    if (changed) root.saveNotified();
  }

  function saveNotified() {
    if (!root.notifiedReady || !notifiedFile.path) return;
    try { notifiedFile.setText(JSON.stringify({ version: 1, events: root.notified }, null, 2) + "\n"); }
    catch (error) { console.warn("Kairos: could not save calendar notification history: " + error); }
  }

  function loadNotified(text) {
    var next = {};
    try {
      var parsed = JSON.parse(String(text || "{}"));
      if (parsed && parsed.version === 1 && parsed.events && typeof parsed.events === "object")
        next = CalendarModel.pruneNotified(parsed.events, Date.now());
    } catch (error) { next = {}; }
    root.notified = next;
    root.notifiedReady = true;
    root.checkNotifications();
  }

  function serializeMonthCache() {
    var stored = {};
    for (var key in root.monthEvents) {
      if (!Object.prototype.hasOwnProperty.call(root.monthEvents, key) || !/^\d{4}-\d{2}$/.test(key)) continue;
      var item = root.monthEvents[key];
      stored[key] = { events: item && Array.isArray(item.events) ? item.events : [] };
    }
    return JSON.stringify({ version: 1, months: stored }, null, 2) + "\n";
  }

  function loadMonthCache(text) {
    var next = {};
    try {
      var parsed = JSON.parse(String(text || "{}"));
      if (parsed && parsed.version === 1 && parsed.months && typeof parsed.months === "object") {
        for (var key in parsed.months) {
          if (!Object.prototype.hasOwnProperty.call(parsed.months, key) || !/^\d{4}-(0[1-9]|1[0-2])$/.test(key)) continue;
          var rows = parsed.months[key] && parsed.months[key].events;
          if (!Array.isArray(rows) || rows.length > 10000) continue;
          var valid = [];
          for (var i = 0; i < rows.length; i++) {
            var row = rows[i];
            if (!row || !isFinite(Number(row.start)) || !isFinite(Number(row.end)) || typeof row.title !== "string") continue;
            var copy = {};
            for (var field in row) if (Object.prototype.hasOwnProperty.call(row, field)) copy[field] = row[field];
            copy.color = CalendarModel.qmlColor(copy.color, true);
            valid.push(copy);
          }
          next[key] = { generation: root.rangeGeneration, events: valid };
        }
      }
    } catch (error) { next = {}; }
    var live = root.monthEvents || {};
    for (var liveKey in live)
      if (Object.prototype.hasOwnProperty.call(live, liveKey)) next[liveKey] = live[liveKey];
    root.monthEvents = next;
    root.bumpEvents();
  }

  function saveMonthCache() {
    if (!monthCacheFile.path || !root.cacheLoaded) {
      root.cacheDirty = true;
      return;
    }
    try {
      monthCacheFile.setText(root.serializeMonthCache());
      root.cacheDirty = false;
    } catch (error) {
      root.cacheDirty = true;
      console.warn("Kairos: could not save calendar month cache: " + error);
    }
  }

  FileView {
    id: monthCacheFile
    watchChanges: false
    atomicWrites: true
    printErrors: false
    onLoaded: {
      root.cacheLoaded = true;
      root.loadMonthCache(text());
      if (root.cacheDirty) monthCacheDebounce.restart();
    }
    onLoadFailed: function(error) {
      root.cacheLoaded = true;
      if (error !== FileViewError.FileNotFound) console.warn("Kairos: calendar month cache load failed: " + error);
      if (root.cacheDirty) monthCacheDebounce.restart();
    }
    onSaveFailed: function(error) { console.warn("Kairos: calendar month cache save failed: " + error); }
  }

  FileView {
    id: notifiedFile
    watchChanges: false
    atomicWrites: true
    printErrors: false
    onLoaded: root.loadNotified(text())
    onLoadFailed: function(error) {
      if (error === FileViewError.FileNotFound) root.loadNotified("{}");
      else {
        root.notifiedReady = true;
        console.warn("Kairos: calendar notification history load failed: " + error);
      }
    }
    onSaveFailed: function(error) { console.warn("Kairos: calendar notification history save failed: " + error); }
  }

  Timer {
    id: monthCacheDebounce
    interval: 800
    repeat: false
    onTriggered: root.saveMonthCache()
  }

  Process {
    id: cacheDirectoryProc
    onExited: function(exitCode) {
      if (exitCode === 0) monthCacheFile.path = root.monthCachePath;
      else {
        root.cacheLoaded = true;
        console.warn("Kairos: could not create the calendar cache directory.");
      }
    }
  }

  Process {
    id: notifiedDirectoryProc
    onExited: function(exitCode) {
      if (exitCode === 0) notifiedFile.path = root.notifiedPath;
      else {
        root.notifiedReady = true;
        console.warn("Kairos: could not create the calendar state directory.");
      }
    }
  }

  Process {
    id: formatsProc
    property string output: ""
    command: CalendarModel.khalArgs(["printformats"])
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: formatsProc.output = text
    }
    onExited: function(exitCode) {
      var output = formatsProc.output;
      formatsProc.output = "";
      if (exitCode === 127) {
        root.khalAvailable = false;
        root.formats = null;
        root.refreshPending = false;
        root.lastError = "";
        root.events = [];
        root.bumpEvents();
        return;
      }
      if (exitCode !== 0) {
        root.formats = { ok: false, error: "khal printformats failed (exit " + exitCode + ")." };
        root.refreshPending = false;
        root.lastError = root.formats.error;
        root.bumpService();
        return;
      }
      var parsed = CalendarModel.parseFormats(output);
      root.formats = parsed;
      root.khalAvailable = true;
      if (!parsed.ok) {
        root.refreshPending = false;
        root.lastError = parsed.error;
        root.events = [];
        root.bumpEvents();
        return;
      }
      root.lastError = "";
      root.refreshPending = false;
      root.refresh();
      if (root.pendingRangeKey !== "") Qt.callLater(root.startPendingRange);
    }
  }

  Process {
    id: listProc
    property string output: ""
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: listProc.output = text
    }
    onExited: function(exitCode) {
      var output = listProc.output;
      listProc.output = "";
      if (exitCode === 127) {
        root.khalAvailable = false;
        root.refreshPending = false;
        root.lastError = "";
        root.events = [];
        root.bumpEvents();
        return;
      }
      if (exitCode !== 0) {
        root.lastError = "khal list failed (exit " + exitCode + ").";
        root.bumpService();
      } else {
        if (typeof Date.timeZoneUpdated === "function") Date.timeZoneUpdated();
        root.khalAvailable = true;
        root.events = CalendarModel.parseEvents(output, root.formats);
        root.lastRefresh = Date.now();
        root.lastError = "";
        root.checkNotifications();
        root.bumpEvents();
      }
      if (root.refreshPending) {
        root.refreshPending = false;
        Qt.callLater(root.refresh);
      }
    }
  }

  Process {
    id: rangeProc
    property string key: ""
    property int year: 0
    property int month: 0
    property int generation: 0
    property string output: ""
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: rangeProc.output = text
    }
    onExited: function(exitCode) {
      var output = rangeProc.output;
      var key = rangeProc.key;
      var generation = rangeProc.generation;
      rangeProc.output = "";
      if (exitCode === 0 && generation === root.rangeGeneration) {
        if (typeof Date.timeZoneUpdated === "function") Date.timeZoneUpdated();
        var next = {};
        for (var oldKey in root.monthEvents)
          if (Object.prototype.hasOwnProperty.call(root.monthEvents, oldKey)) next[oldKey] = root.monthEvents[oldKey];
        next[key] = { generation: generation, events: CalendarModel.parseEvents(output, root.formats) };
        root.monthEvents = next;
        monthCacheDebounce.restart();
        root.bumpEvents();
      } else if (exitCode === 127) {
        root.khalAvailable = false;
        root.pendingRangeKey = "";
        root.bumpService();
      } else if (exitCode !== 0 && generation === root.rangeGeneration) {
        root.lastError = "khal month query failed (exit " + exitCode + ").";
        root.bumpService();
      }
      if (root.pendingRangeKey !== "") Qt.callLater(root.startPendingRange);
    }
  }

  Process {
    id: detailProc
    property string uid: ""
    property string output: ""
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: detailProc.output = text
    }
    onExited: function(exitCode) {
      var uid = detailProc.uid;
      var output = detailProc.output;
      detailProc.output = "";
      var details = exitCode === 0 ? CalendarModel.parseIcsDetails(output, uid) : null;
      var next = {};
      for (var key in root.icsDetails) if (Object.prototype.hasOwnProperty.call(root.icsDetails, key)) next[key] = root.icsDetails[key];
      next[uid] = details;
      root.icsDetails = next;
      root.bumpService();
      Qt.callLater(root.startNextDetail);
    }
  }

  Process {
    id: syncProc
    onExited: function(exitCode) {
      syncWatchdog.stop();
      root.syncing = false;
      if (syncWatchdog.fired) {
        root.syncError = "Sync timed out.";
        syncWatchdog.fired = false;
        root.bumpService();
        return;
      }
      if (exitCode === 127) {
        root.syncAvailable = false;
        root.syncError = "Sync tool is not installed.";
        root.bumpService();
        return;
      }
      root.syncAvailable = true;
      if (exitCode !== 0) {
        root.syncError = "Sync failed (exit " + exitCode + ").";
        root.bumpService();
        return;
      }
      root.syncError = "";
      root.lastSync = Date.now();
      root.formats = null;
      root.invalidateMonths();
      if (!formatsProc.running) formatsProc.running = true;
      root.bumpService();
    }
  }

  Timer {
    id: syncWatchdog
    property bool fired: false
    interval: 5 * 60000
    running: root.syncing
    onTriggered: {
      fired = true;
      syncProc.running = false;
    }
  }

  Timer {
    id: minuteTimer
    interval: 60000 - (Date.now() % 60000) + 1000
    running: true
    repeat: true
    onTriggered: {
      interval = 60000 - (Date.now() % 60000) + 1000;
      root.refresh();
    }
  }

  Timer {
    id: settleTimer
    interval: 30000
    running: !root.settled
    onTriggered: {
      root.settled = true;
      root.checkNotifications();
    }
  }

  Timer {
    id: syncTimer
    interval: Math.max(1, root.syncIntervalMinutes) * 60000
    running: root.settled && root.syncIntervalMinutes > 0 && root.syncAvailable && root.syncCommand.trim() !== ""
    repeat: true
    triggeredOnStart: true
    onTriggered: root.sync()
  }

  property var detailQueue: []
  property bool cacheLoaded: false
  property bool cacheDirty: false

  onSyncCommandChanged: {
    root.syncAvailable = true;
    root.syncError = "";
  }

  Connections {
    target: root.service
    function onSettingsChanged() { root.configure(); }
    function onStateLoadedChanged() { root.configure(); }
  }

  Component.onCompleted: {
    root.cacheDirPath = Storage.calendarCacheDir(Quickshell.env);
    root.monthCachePath = root.cacheDirPath + "/months.json";
    root.notifiedPath = Storage.calendarNotificationsPath(Quickshell.env);
    cacheDirectoryProc.command = ["mkdir", "-p", root.cacheDirPath];
    cacheDirectoryProc.running = true;
    notifiedDirectoryProc.command = ["mkdir", "-p", root.parentPath(root.notifiedPath)];
    notifiedDirectoryProc.running = true;
    root.configure();
    formatsProc.running = true;
  }
}

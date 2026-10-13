.pragma library

var SCHEMA_VERSION = 3;
var MAX_SAFE_INTEGER = 9007199254740991;
var COLUMNS = ["q1", "q2", "q3", "q4"];
var DEFAULT_COLUMN_LABELS = {
  q1: "Do",
  q2: "Schedule",
  q3: "Delegate",
  q4: "Delete"
};
var MARKET_CURRENCIES = ["USD", "EUR", "BRL", "GBP", "JPY", "CAD", "AUD", "CHF", "CNY", "INR", "MXN", "NZD", "SGD", "KRW", "ZAR"];
var DEFAULT_MARKET_CURRENCIES = ["USD", "EUR", "BRL"];
var DEFAULT_WATCHLIST_SYMBOLS = ["AAPL", "NVDA", "BTC"];

function defaultSettings() {
  return {
    focus: {
      focusAction: "pomodoro",
      action: "pomodoro",
      focusSec: 1500,
      shortBreakSec: 300,
      longBreakSec: 900,
      longBreakInterval: 4
    },
    flowtime: {
      breakMode: "traditional",
      breakRatio: 0.2,
      minBreakSec: 300,
      maxBreakSec: 900
    },
    calendar: {
      agendaDays: 7,
      leadMinutes: 10,
      notifications: true,
      syncIntervalMinutes: 15,
      syncCommand: "vdirsyncer sync",
      timeFormat: "Match khal",
      mapsProvider: "Google Maps"
    },
    obsidian: {
      enabled: false,
      vaultPath: "",
      vaultName: "",
      dailyNotesFolder: "Daily Notes",
      templatePath: ""
    },
    markets: {
      currency: "USD",
      currencies: ["USD", "EUR", "BRL"],
      refreshMinutes: 5,
      watchlist: { symbols: ["AAPL", "NVDA", "BTC"], coinIds: {} }
    },
    stats: { streakMinSec: 900 },
    social: {
      telegram: false,
      whatsapp: false,
      signal: false,
      discord: false,
      matrix: false,
      notifyMessages: true,
      notifyCalls: true,
      showPreview: false
    },
    email: {
      accounts: [],
      notifyNew: true,
      showPreview: false
    },
    bar: { showFocusTimer: true },
    shortcuts: {
      toggleShortcut: "Super+H",
      focusShortcut: "Super+Shift+H",
      flowtimeShortcut: "Super+Alt+H"
    },
    notifications: {
      enabled: true,
      sound: true
    }
  };
}

function uid(prefix) {
  return String(prefix || "id") + "-" + Math.floor(Date.now()).toString(36)
    + "-" + Math.floor(Math.random() * 0xffffff).toString(36);
}

function defaultBoards() {
  var now = Date.now();
  return [{ id: "board-life", title: "Stay Hard", createdAt: now, updatedAt: now }];
}

function blankTimer() {
  return {
    mode: "idle",
    phase: "stopped",
    taskId: null,
    startedAtMs: 0,
    deadlineMs: 0,
    pausedRemainingMs: 0,
    pausedPhase: "",
    accumulatedMs: 0,
    interruptions: 0,
    pomodorosDone: 0,
    taskTitle: "",
    sessionStartedAtMs: 0,
    breakKind: "",
    breakTotalMs: 0,
    technique: "pomodoro"
  };
}

function blankState() {
  return {
    schemaVersion: SCHEMA_VERSION,
    settings: defaultSettings(),
    boards: defaultBoards(),
    tasks: [],
    sessions: [],
    activeBoardId: "board-life",
    activeTaskId: null,
    activeTaskSource: "matrix",
    activeTaskText: "",
    timer: blankTimer()
  };
}

function isPlainObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function boundedInteger(value, fallback, minimum, maximum) {
  var number = Number(value);
  if (!isFinite(number)) return fallback;
  number = Math.floor(number);
  if (minimum !== undefined) number = Math.max(minimum, number);
  if (maximum !== undefined) number = Math.min(maximum, number);
  return number;
}

function boundedString(value, fallback, maximum) {
  var text = typeof value === "string" ? value.trim() : "";
  if (text === "") text = fallback;
  return text.slice(0, maximum);
}

function sanitizeEmailHost(value) {
  var host = boundedString(value, "", 253).toLowerCase();
  if (host === "" || !/^[a-z0-9.:-]+$/.test(host) || host.indexOf("..") !== -1) return "";
  return host;
}

function mergeKnownSection(defaults, raw) {
  var result = {};
  var key;
  var source = isPlainObject(raw) ? raw : {};
  for (key in defaults) {
    if (!Object.prototype.hasOwnProperty.call(defaults, key)) continue;
    result[key] = Object.prototype.hasOwnProperty.call(source, key) ? source[key] : defaults[key];
  }
  return result;
}

function structurallyEqual(left, right) {
  if (left === right) return true;
  if (left === null || right === null || typeof left !== "object" || typeof right !== "object")
    return false;
  var leftArray = Array.isArray(left);
  if (leftArray !== Array.isArray(right)) return false;
  if (leftArray) {
    if (left.length !== right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (!structurallyEqual(left[index], right[index])) return false;
    }
    return true;
  }
  var leftKeys = Object.keys(left);
  var rightKeys = Object.keys(right);
  if (leftKeys.length !== rightKeys.length) return false;
  for (var keyIndex = 0; keyIndex < leftKeys.length; keyIndex++) {
    var key = leftKeys[keyIndex];
    if (!Object.prototype.hasOwnProperty.call(right, key) || !structurallyEqual(left[key], right[key]))
      return false;
  }
  return true;
}

function migrate(raw) {
  if (!isPlainObject(raw)) return raw;
  var version = Number(raw.schemaVersion);
  if (version === 2) {
    return {
      schemaVersion: SCHEMA_VERSION,
      settings: raw.settings,
      boards: raw.boards,
      tasks: raw.tasks,
      sessions: raw.sessions,
      activeBoardId: raw.activeBoardId,
      activeTaskId: raw.activeTaskId,
      activeTaskSource: "matrix",
      activeTaskText: "",
      timer: raw.timer
    };
  }
  if (version !== 1) return raw;

  var oldSettings = isPlainObject(raw.settings) ? raw.settings : {};
  var settings = defaultSettings();
  settings.focus.focusAction = oldSettings.focusAction === "flowtime" ? "flowtime" : "pomodoro";
  settings.focus.action = settings.focus.focusAction;
  settings.focus.focusSec = oldSettings.focusSec;
  settings.focus.shortBreakSec = oldSettings.shortBreakSec;
  settings.focus.longBreakSec = oldSettings.longBreakSec;
  settings.focus.longBreakInterval = oldSettings.longBreakInterval;
  settings.flowtime.breakMode = oldSettings.flowBreakMode;
  settings.flowtime.breakRatio = oldSettings.flowBreakPct;
  settings.flowtime.minBreakSec = oldSettings.flowBreakMinSec;
  settings.flowtime.maxBreakSec = oldSettings.flowBreakMaxSec;
  settings.shortcuts.toggleShortcut = oldSettings.toggleShortcut || settings.shortcuts.toggleShortcut;
  settings.shortcuts.focusShortcut = oldSettings.focusShortcut || settings.shortcuts.focusShortcut;
  settings.shortcuts.flowtimeShortcut = oldSettings.flowtimeShortcut || settings.shortcuts.flowtimeShortcut;
  settings.notifications.enabled = oldSettings.notificationsEnabled !== false;
  settings.notifications.sound = oldSettings.soundEnabled !== false;

  return {
    schemaVersion: SCHEMA_VERSION,
    settings: settings,
    boards: raw.boards,
    tasks: raw.tasks,
    sessions: raw.sessions,
    activeBoardId: raw.activeBoardId,
    activeTaskId: raw.activeTaskId,
    activeTaskSource: "matrix",
    activeTaskText: "",
    timer: raw.timer
  };
}

function sanitizeSettings(raw) {
  var defaults = defaultSettings();
  if (!isPlainObject(raw)) return defaults;

  var settings = {};
  var sectionNames = ["focus", "flowtime", "calendar", "obsidian", "markets", "stats", "social", "email", "bar", "shortcuts", "notifications"];
  for (var i = 0; i < sectionNames.length; i++) {
    var name = sectionNames[i];
    settings[name] = mergeKnownSection(defaults[name], raw[name]);
  }

  var rawFocus = isPlainObject(raw.focus) ? raw.focus : {};
  var focusAction = rawFocus.focusAction === "flowtime" || rawFocus.focusAction === "pomodoro"
    ? rawFocus.focusAction
    : (rawFocus.action === "flowtime" ? "flowtime" : defaults.focus.focusAction);
  settings.focus.focusAction = focusAction;
  settings.focus.action = focusAction;
  settings.focus.focusSec = boundedInteger(settings.focus.focusSec, defaults.focus.focusSec, 60, 28800);
  settings.focus.shortBreakSec = boundedInteger(settings.focus.shortBreakSec, defaults.focus.shortBreakSec, 0, 7200);
  settings.focus.longBreakSec = boundedInteger(settings.focus.longBreakSec, defaults.focus.longBreakSec, 0, 14400);
  settings.focus.longBreakInterval = boundedInteger(settings.focus.longBreakInterval, defaults.focus.longBreakInterval, 1, 24);

  settings.flowtime.breakMode = settings.flowtime.breakMode === "proportional" ? "proportional" : "traditional";
  var ratio = Number(settings.flowtime.breakRatio);
  settings.flowtime.breakRatio = isFinite(ratio) && ratio >= 0 && ratio <= 1 ? ratio : defaults.flowtime.breakRatio;
  settings.flowtime.minBreakSec = boundedInteger(settings.flowtime.minBreakSec, defaults.flowtime.minBreakSec, 0, 7200);
  settings.flowtime.maxBreakSec = boundedInteger(settings.flowtime.maxBreakSec, defaults.flowtime.maxBreakSec, 60, 14400);
  if (settings.flowtime.maxBreakSec < settings.flowtime.minBreakSec)
    settings.flowtime.maxBreakSec = settings.flowtime.minBreakSec;

  settings.calendar.agendaDays = boundedInteger(settings.calendar.agendaDays, defaults.calendar.agendaDays, 1, 60);
  settings.calendar.leadMinutes = boundedInteger(settings.calendar.leadMinutes, defaults.calendar.leadMinutes, 0, 120);
  settings.calendar.notifications = settings.calendar.notifications !== false;
  settings.calendar.syncIntervalMinutes = boundedInteger(settings.calendar.syncIntervalMinutes, defaults.calendar.syncIntervalMinutes, 0, 1440);
  settings.calendar.syncCommand = boundedString(settings.calendar.syncCommand, defaults.calendar.syncCommand, 256);
  settings.calendar.timeFormat = ["Match khal", "12-hour", "24-hour"].indexOf(settings.calendar.timeFormat) !== -1
    ? settings.calendar.timeFormat : defaults.calendar.timeFormat;
  settings.calendar.mapsProvider = ["Google Maps", "OpenStreetMap", "Apple Maps"].indexOf(settings.calendar.mapsProvider) !== -1
    ? settings.calendar.mapsProvider : defaults.calendar.mapsProvider;

  settings.obsidian.enabled = settings.obsidian.enabled === true;
  settings.obsidian.vaultPath = boundedString(settings.obsidian.vaultPath, "", 1024);
  settings.obsidian.vaultName = boundedString(settings.obsidian.vaultName, "", 128);
  settings.obsidian.dailyNotesFolder = boundedString(settings.obsidian.dailyNotesFolder, defaults.obsidian.dailyNotesFolder, 256);
  settings.obsidian.templatePath = boundedString(settings.obsidian.templatePath, "", 1024);

  var currencyList = [];
  var rawCurrencyList = Array.isArray(settings.markets.currencies) ? settings.markets.currencies : DEFAULT_MARKET_CURRENCIES;
  for (var currencyIndex = 0; currencyIndex < rawCurrencyList.length && currencyList.length < 8; currencyIndex++) {
    var currencyCode = String(rawCurrencyList[currencyIndex] || "").trim().toUpperCase();
    if (MARKET_CURRENCIES.indexOf(currencyCode) !== -1 && currencyList.indexOf(currencyCode) === -1)
      currencyList.push(currencyCode);
  }
  if (currencyList.length === 0) currencyList = DEFAULT_MARKET_CURRENCIES.slice();
  settings.markets.currency = String(settings.markets.currency || "USD").trim().toUpperCase();
  if (MARKET_CURRENCIES.indexOf(settings.markets.currency) === -1) settings.markets.currency = "USD";
  if (currencyList.indexOf(settings.markets.currency) === -1) currencyList.unshift(settings.markets.currency);
  currencyList = currencyList.slice(0, 8);
  settings.markets.currencies = currencyList;
  settings.markets.refreshMinutes = boundedInteger(settings.markets.refreshMinutes, defaults.markets.refreshMinutes, 1, 60);

  var rawWatchlist = isPlainObject(settings.markets.watchlist) ? settings.markets.watchlist : {};
  var watchlistSymbols = Array.isArray(rawWatchlist.symbols) ? rawWatchlist.symbols : DEFAULT_WATCHLIST_SYMBOLS;
  var safeSymbols = [];
  for (var symbolIndex = 0; symbolIndex < watchlistSymbols.length && safeSymbols.length < 50; symbolIndex++) {
    var marketSymbol = String(watchlistSymbols[symbolIndex] || "").trim().toUpperCase().replace(/\\s+/g, "");
    if (/^([A-Z0-9]{2,16})-(USD|USDT)$/.test(marketSymbol)) marketSymbol = marketSymbol.replace(/-(USD|USDT)$/, "");
    if (!/^[A-Z0-9][A-Z0-9.^/_=-]{0,23}$/.test(marketSymbol) || safeSymbols.indexOf(marketSymbol) !== -1) continue;
    safeSymbols.push(marketSymbol);
  }
  var safeCoinIds = {};
  var rawCoinIds = isPlainObject(rawWatchlist.coinIds) ? rawWatchlist.coinIds : {};
  for (var coinSymbol in rawCoinIds) {
    if (!Object.prototype.hasOwnProperty.call(rawCoinIds, coinSymbol)) continue;
    var normalizedCoinSymbol = String(coinSymbol || "").trim().toUpperCase();
    var coinId = String(rawCoinIds[coinSymbol] || "").trim();
    if (safeSymbols.indexOf(normalizedCoinSymbol) !== -1 && /^[a-z0-9-]{1,64}$/.test(coinId))
      safeCoinIds[normalizedCoinSymbol] = coinId;
  }
  settings.markets.watchlist = { symbols: safeSymbols, coinIds: safeCoinIds };

  settings.stats.streakMinSec = boundedInteger(settings.stats.streakMinSec, defaults.stats.streakMinSec, 60, 86400);

  var socialPlatforms = ["telegram", "whatsapp", "signal", "discord", "matrix"];
  for (var platformIndex = 0; platformIndex < socialPlatforms.length; platformIndex++) {
    var platformName = socialPlatforms[platformIndex];
    settings.social[platformName] = settings.social[platformName] === true;
  }
  settings.social.notifyMessages = settings.social.notifyMessages !== false;
  settings.social.notifyCalls = settings.social.notifyCalls !== false;
  settings.social.showPreview = settings.social.showPreview === true;

  var rawEmailAccounts = Array.isArray(settings.email.accounts) ? settings.email.accounts : [];
  var emailAccounts = [];
  var seenAccountIds = {};
  for (var accountIndex = 0; accountIndex < rawEmailAccounts.length && emailAccounts.length < 32; accountIndex++) {
    var rawAccount = rawEmailAccounts[accountIndex];
    if (!isPlainObject(rawAccount)) continue;
    var accountId = boundedString(rawAccount.id, uid("email"), 80);
    if (!/^[A-Za-z0-9_-]{1,80}$/.test(accountId) || seenAccountIds[accountId]) continue;
    seenAccountIds[accountId] = true;
    var accountEmail = boundedString(rawAccount.email, "", 254).toLowerCase();
    if (accountEmail !== "" && !/^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$/.test(accountEmail)) accountEmail = "";
    emailAccounts.push({
      id: accountId,
      name: boundedString(rawAccount.name, accountEmail || "Email account", 80),
      email: accountEmail,
      imapHost: sanitizeEmailHost(rawAccount.imapHost),
      imapPort: boundedInteger(rawAccount.imapPort, 993, 1, 65535),
      smtpHost: sanitizeEmailHost(rawAccount.smtpHost),
      smtpPort: boundedInteger(rawAccount.smtpPort, 587, 1, 65535),
      username: boundedString(rawAccount.username, "", 254),
      tls: true
    });
  }
  settings.email.accounts = emailAccounts;
  settings.email.notifyNew = settings.email.notifyNew !== false;
  settings.email.showPreview = settings.email.showPreview === true;

  settings.bar.showFocusTimer = settings.bar.showFocusTimer !== false;

  settings.shortcuts.toggleShortcut = boundedString(settings.shortcuts.toggleShortcut, defaults.shortcuts.toggleShortcut, 64);
  settings.shortcuts.focusShortcut = boundedString(settings.shortcuts.focusShortcut, defaults.shortcuts.focusShortcut, 64);
  settings.shortcuts.flowtimeShortcut = boundedString(settings.shortcuts.flowtimeShortcut, defaults.shortcuts.flowtimeShortcut, 64);
  settings.notifications.enabled = settings.notifications.enabled !== false;
  settings.notifications.sound = settings.notifications.sound !== false;
  settings.email.accounts = Array.isArray(settings.email.accounts) ? settings.email.accounts.slice(0, 32) : [];
  settings.email.notifyNew = settings.email.notifyNew !== false;
  settings.email.showPreview = settings.email.showPreview === true;
  return settings;
}

function sanitizeSettingsSection(section, raw) {
  var defaults = defaultSettings();
  if (!Object.prototype.hasOwnProperty.call(defaults, section)) return null;
  var combined = defaultSettings();
  combined[section] = raw;
  return sanitizeSettings(combined)[section];
}

function sanitizeBoard(raw) {
  if (!isPlainObject(raw)) return null;
  var now = Date.now();
  return {
    id: boundedString(raw.id, uid("board"), 80),
    title: boundedString(raw.title, "Untitled", 48),
    createdAt: boundedInteger(raw.createdAt, now, 0, MAX_SAFE_INTEGER),
    updatedAt: boundedInteger(raw.updatedAt, now, 0, MAX_SAFE_INTEGER)
  };
}

function sanitizeTask(raw, boardIds) {
  if (!isPlainObject(raw) || typeof raw.title !== "string" || raw.title.trim() === "") return null;
  var now = Date.now();
  var columnId = String(raw.columnId || "q1");
  if (columnId === "ready") columnId = "q1";
  else if (columnId === "inbox") columnId = "q2";
  else if (columnId === "focus") columnId = "q3";
  else if (columnId === "done") columnId = "q1";
  if (COLUMNS.indexOf(columnId) === -1) columnId = "q1";

  var boardId = String(raw.boardId || (boardIds.length ? boardIds[0] : "board-life"));
  if (boardIds.indexOf(boardId) === -1) boardId = boardIds[0] || "board-life";
  var priority = ["low", "normal", "high"].indexOf(raw.priority) !== -1 ? raw.priority : "normal";
  return {
    id: boundedString(raw.id, uid("task"), 80),
    boardId: boardId,
    columnId: columnId,
    title: raw.title.trim().slice(0, 200),
    description: String(raw.description || "").slice(0, 2000),
    priority: priority,
    createdAt: boundedInteger(raw.createdAt, now, 0, MAX_SAFE_INTEGER),
    updatedAt: boundedInteger(raw.updatedAt, now, 0, MAX_SAFE_INTEGER),
    completedAt: raw.completedAt ? boundedInteger(raw.completedAt, now, 0, MAX_SAFE_INTEGER) : null,
    totalFocusSeconds: boundedInteger(raw.totalFocusSeconds, 0, 0, MAX_SAFE_INTEGER),
    pomodoroSessions: boundedInteger(raw.pomodoroSessions, 0, 0, MAX_SAFE_INTEGER),
    flowtimeSessions: boundedInteger(raw.flowtimeSessions, 0, 0, MAX_SAFE_INTEGER),
    interruptions: boundedInteger(raw.interruptions, 0, 0, MAX_SAFE_INTEGER)
  };
}

function sanitizeSession(raw) {
  if (!isPlainObject(raw)) return null;
  var kind = String(raw.kind || "");
  if (kind !== "pomo" && kind !== "flow") return null;
  var duration = boundedInteger(raw.durationSec, 0, 1, 57600);
  if (duration < 1) return null;
  var now = Date.now();
  return {
    id: boundedString(raw.id, uid("session"), 80),
    kind: kind,
    taskId: raw.taskId ? String(raw.taskId).slice(0, 80) : null,
    taskTitle: boundedString(raw.taskTitle, "", 200),
    boardId: raw.boardId ? String(raw.boardId).slice(0, 80) : null,
    startedAt: boundedInteger(raw.startedAt, now, 0, MAX_SAFE_INTEGER),
    endedAt: boundedInteger(raw.endedAt, now, 0, MAX_SAFE_INTEGER),
    durationSec: duration,
    interruptions: boundedInteger(raw.interruptions, 0, 0, 1000000)
  };
}

function sanitizeTimer(raw) {
  if (!isPlainObject(raw)) return blankTimer();
  var timer = blankTimer();
  var mode = String(raw.mode || "idle");
  var phase = String(raw.phase || "stopped");
  if (["idle", "pomodoro", "flowtime"].indexOf(mode) === -1) mode = "idle";
  if (["stopped", "running", "paused", "break", "idle"].indexOf(phase) === -1) phase = "stopped";
  if (mode === "idle" && (phase === "running" || phase === "paused" || phase === "break")) {
    mode = "pomodoro";
  }

  timer.mode = mode;
  timer.phase = phase;
  timer.taskId = raw.taskId ? String(raw.taskId).slice(0, 80) : null;
  timer.startedAtMs = boundedInteger(raw.startedAtMs, 0, 0, MAX_SAFE_INTEGER);
  timer.deadlineMs = boundedInteger(raw.deadlineMs, 0, 0, MAX_SAFE_INTEGER);
  timer.pausedRemainingMs = boundedInteger(raw.pausedRemainingMs, 0, 0, 604800000);
  timer.pausedPhase = raw.pausedPhase === "break" ? "break" : "";
  timer.accumulatedMs = boundedInteger(raw.accumulatedMs, 0, 0, 604800000);
  timer.interruptions = boundedInteger(raw.interruptions, 0, 0, 1000000);
  timer.pomodorosDone = boundedInteger(raw.pomodorosDone, 0, 0, 1000000);
  timer.taskTitle = boundedString(raw.taskTitle, "", 200);
  timer.sessionStartedAtMs = boundedInteger(raw.sessionStartedAtMs, timer.startedAtMs, 0, MAX_SAFE_INTEGER);
  timer.breakKind = ["short", "long", "flow"].indexOf(raw.breakKind) !== -1 ? raw.breakKind : "";
  timer.breakTotalMs = boundedInteger(raw.breakTotalMs, 0, 0, 604800000);
  timer.technique = raw.technique === "flowtime" ? "flowtime" : "pomodoro";

  if (timer.phase === "stopped" || timer.phase === "idle") {
    timer.mode = "idle";
    timer.deadlineMs = 0;
    timer.pausedRemainingMs = 0;
    timer.pausedPhase = "";
  }
  return timer;
}

function sanitizeState(raw) {
  try {
    if (!isPlainObject(raw)) return { state: blankState(), repaired: true };
    var originalVersion = boundedInteger(raw.schemaVersion, 0, 0, 1000000);
    var source = raw;
    var repaired = originalVersion !== SCHEMA_VERSION;
    if (originalVersion === 1 || originalVersion === 2) source = migrate(raw);
    else if (originalVersion !== SCHEMA_VERSION) return { state: blankState(), repaired: true };

    var state = blankState();
    state.settings = sanitizeSettings(source.settings);
    if (!structurallyEqual(source.settings, state.settings)) repaired = true;

    var boards = [];
    if (Array.isArray(source.boards)) {
      if (source.boards.length > 100) repaired = true;
      for (var i = 0; i < Math.min(source.boards.length, 100); i++) {
        var board = sanitizeBoard(source.boards[i]);
        if (board) boards.push(board);
        else repaired = true;
      }
    } else {
      repaired = true;
    }
    if (boards.length === 0) {
      boards = defaultBoards();
      repaired = true;
    }
    if (!structurallyEqual(source.boards, boards)) repaired = true;
    var boardIds = boards.map(function(item) { return item.id; });

    var tasks = [];
    if (Array.isArray(source.tasks)) {
      if (source.tasks.length > 10000) repaired = true;
      for (var taskIndex = 0; taskIndex < Math.min(source.tasks.length, 10000); taskIndex++) {
        var task = sanitizeTask(source.tasks[taskIndex], boardIds);
        if (task) tasks.push(task);
        else repaired = true;
      }
    } else {
      repaired = true;
    }
    if (!structurallyEqual(source.tasks, tasks)) repaired = true;

    var sessions = [];
    if (Array.isArray(source.sessions)) {
      if (source.sessions.length > 2000) repaired = true;
      var firstSession = Math.max(0, source.sessions.length - 2000);
      for (var sessionIndex = firstSession; sessionIndex < source.sessions.length; sessionIndex++) {
        var session = sanitizeSession(source.sessions[sessionIndex]);
        if (session) sessions.push(session);
        else repaired = true;
      }
    } else {
      repaired = true;
    }
    if (!structurallyEqual(source.sessions, sessions)) repaired = true;

    var activeBoardId = String(source.activeBoardId || boardIds[0]);
    if (boardIds.indexOf(activeBoardId) === -1) {
      activeBoardId = boardIds[0];
      repaired = true;
    }
    if (String(source.activeBoardId || "") !== activeBoardId) repaired = true;

    var activeTaskSource = source.activeTaskSource === "obsidian" ? "obsidian" : "matrix";
    var activeTaskText = boundedString(source.activeTaskText, "", 200);
    var activeTaskId = source.activeTaskId ? String(source.activeTaskId) : "";
    if (activeTaskSource === "obsidian") {
      activeTaskId = "";
      if (activeTaskText === "") activeTaskSource = "matrix";
    } else {
      activeTaskText = "";
      var activeTaskExists = tasks.some(function(item) {
        return item.id === activeTaskId && item.boardId === activeBoardId && !item.completedAt;
      });
      if (activeTaskId && !activeTaskExists) activeTaskId = "";
    }
    if (String(source.activeTaskId || "") !== activeTaskId
        || source.activeTaskSource !== activeTaskSource
        || String(source.activeTaskText || "") !== activeTaskText) repaired = true;

    state.boards = boards;
    state.tasks = tasks;
    state.sessions = sessions;
    state.activeBoardId = activeBoardId;
    state.activeTaskId = activeTaskId || null;
    state.activeTaskSource = activeTaskSource;
    state.activeTaskText = activeTaskText;
    state.timer = sanitizeTimer(source.timer);
    if (!structurallyEqual(source.timer, state.timer)) repaired = true;
    state.schemaVersion = SCHEMA_VERSION;
    return { state: state, repaired: repaired };
  } catch (error) {
    return { state: blankState(), repaired: true };
  }
}

function formatClock(totalSeconds) {
  var seconds = Math.max(0, Math.floor(Number(totalSeconds) || 0));
  var hours = Math.floor(seconds / 3600);
  var minutes = Math.floor((seconds % 3600) / 60);
  var remainder = seconds % 60;
  function pad(value) { return value < 10 ? "0" + value : String(value); }
  if (seconds < 60) return pad(remainder);
  if (seconds < 3600) return pad(minutes) + ":" + pad(remainder);
  return pad(hours) + ":" + pad(minutes) + ":" + pad(remainder);
}

function formatDur(totalSeconds) {
  var seconds = Math.max(0, Math.floor(Number(totalSeconds) || 0));
  var minutes = Math.floor(seconds / 60);
  if (minutes < 1) return "<1m";
  var hours = Math.floor(minutes / 60);
  var remainingMinutes = minutes % 60;
  if (hours === 0) return minutes + "m";
  return hours + "h" + (remainingMinutes > 0 ? " " + remainingMinutes + "m" : "");
}

if (typeof module !== "undefined") {
  module.exports = {
    SCHEMA_VERSION: SCHEMA_VERSION,
    COLUMNS: COLUMNS,
    DEFAULT_COLUMN_LABELS: DEFAULT_COLUMN_LABELS,
    defaultSettings: defaultSettings,
    sanitizeSettings: sanitizeSettings,
    sanitizeSettingsSection: sanitizeSettingsSection,
    defaultBoards: defaultBoards,
    blankTimer: blankTimer,
    blankState: blankState,
    migrate: migrate,
    sanitizeSettings: sanitizeSettings,
    sanitizeTimer: sanitizeTimer,
    sanitizeState: sanitizeState,
    formatClock: formatClock,
    formatDur: formatDur,
    uid: uid
  };
}

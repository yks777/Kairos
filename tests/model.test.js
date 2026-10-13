const test = require("node:test");
const assert = require("node:assert/strict");
const { loadQmlLibrary } = require("./helpers/loadQmlLibrary.js");
const Model = loadQmlLibrary("logic/Model.js");

test("blank state has the canonical schema and a default board", () => {
  const state = Model.blankState();
  assert.equal(state.schemaVersion, 3);
  assert.equal(state.boards[0].id, "board-life");
  assert.equal(state.timer.phase, "stopped");
  assert.equal(state.settings.shortcuts.toggleShortcut, "Super+H");
  assert.equal(state.settings.calendar.syncIntervalMinutes, 15);
  assert.equal(state.settings.obsidian.enabled, false);
});

test("a valid blank state does not need repair", () => {
  const result = Model.sanitizeState(Model.blankState());
  assert.equal(result.repaired, false);
});

test("schema version 1 state migrates into nested Kairos settings", () => {
  const result = Model.sanitizeState({
    schemaVersion: 1,
    settings: {
      focusAction: "flowtime",
      focusSec: 1800,
      toggleShortcut: "Super+J"
    },
    boards: [{ id: "board-life", title: "Stay Hard", createdAt: 1, updatedAt: 2 }],
    tasks: [],
    sessions: [],
    activeBoardId: "board-life",
    activeTaskId: null,
    timer: Model.blankTimer()
  });
  assert.equal(result.repaired, true);
  assert.equal(result.state.schemaVersion, 3);
  assert.equal(result.state.settings.focus.action, "flowtime");
  assert.equal(result.state.settings.focus.focusAction, "flowtime");
  assert.equal(result.state.settings.focus.focusSec, 1800);
  assert.equal(result.state.settings.shortcuts.toggleShortcut, "Super+J");
});

test("schema version 2 migrates to version 3 without losing tasks or focus preferences", () => {
  const state = Model.blankState();
  state.schemaVersion = 2;
  state.settings.focus.action = "flowtime";
  delete state.settings.focus.focusAction;
  state.tasks = [{
    id: "task-1", boardId: "board-life", columnId: "q2", title: "Write plan",
    createdAt: 1, updatedAt: 1, completedAt: null
  }];
  state.activeTaskId = "task-1";
  const result = Model.sanitizeState(state);
  assert.equal(result.repaired, true);
  assert.equal(result.state.schemaVersion, 3);
  assert.equal(result.state.settings.focus.focusAction, "flowtime");
  assert.equal(result.state.tasks[0].title, "Write plan");
  assert.equal(result.state.activeTaskId, "task-1");
  assert.equal(result.state.activeTaskSource, "matrix");
});

test("sanitizing invalid input never throws and returns a safe blank state", () => {
  assert.doesNotThrow(() => Model.sanitizeState(null));
  const result = Model.sanitizeState(null);
  assert.equal(result.repaired, true);
  assert.equal(result.state.schemaVersion, 3);
  assert.equal(result.state.timer.phase, "stopped");
});

test("state sanitization bounds settings and repairs active references", () => {
  const result = Model.sanitizeState({
    schemaVersion: 2,
    settings: { focus: { focusSec: -5 } },
    boards: [{ id: "board-life", title: "Stay Hard" }],
    tasks: [],
    sessions: [],
    activeBoardId: "missing-board",
    activeTaskId: "missing-task",
    timer: { mode: "invalid", phase: "running" }
  });
  assert.equal(result.state.settings.focus.focusSec, 60);
  assert.equal(result.state.activeBoardId, "board-life");
  assert.equal(result.state.activeTaskId, null);
  assert.equal(result.state.timer.mode, "pomodoro");
});

test("formatClock and formatDur are available from the shared model", () => {
  assert.equal(Model.formatClock(59), "59");
  assert.equal(Model.formatClock(60), "01:00");
  assert.equal(Model.formatClock(3600), "01:00:00");
  assert.equal(Model.formatDur(25 * 60), "25m");
  assert.equal(Model.formatDur(65 * 60), "1h 5m");
});

test("legacy focus action is normalized to the canonical focusAction field", () => {
  const settings = Model.sanitizeSettings({ focus: { action: "flowtime" } });
  assert.equal(settings.focus.focusAction, "flowtime");
  assert.equal(settings.focus.action, "flowtime");
});

test("Obsidian task labels persist separately from matrix task IDs", () => {
  const state = Model.blankState();
  state.activeTaskSource = "obsidian";
  state.activeTaskText = "Write daily notes";
  const result = Model.sanitizeState(state);
  assert.equal(result.state.activeTaskId, null);
  assert.equal(result.state.activeTaskSource, "obsidian");
  assert.equal(result.state.activeTaskText, "Write daily notes");
});

test("market and stats settings get bounded defaults and a persistent starter watchlist", () => {
  const settings = Model.sanitizeSettings({});
  assert.deepEqual(settings.markets.watchlist.symbols, ["AAPL", "NVDA", "BTC"]);
  assert.deepEqual(settings.markets.currencies, ["USD", "EUR", "BRL"]);
  assert.equal(settings.markets.currency, "USD");
  assert.equal(settings.stats.streakMinSec, 900);

  const custom = Model.sanitizeSettings({
    markets: {
      currency: "BRL",
      currencies: ["BRL", "BRL", "invalid", "USD"],
      refreshMinutes: 999,
      watchlist: { symbols: ["btc-usd", "AAPL", "AAPL", "bad symbol"], coinIds: { BTC: "bitcoin", AAPL: "not a coin" } }
    },
    stats: { streakMinSec: 20 }
  });
  assert.equal(custom.markets.currency, "BRL");
  assert.deepEqual(custom.markets.currencies, ["BRL", "USD"]);
  assert.equal(custom.markets.refreshMinutes, 60);
  assert.deepEqual(custom.markets.watchlist.symbols, ["BTC", "AAPL"]);
  assert.equal(custom.markets.watchlist.coinIds.BTC, "bitcoin");
  assert.equal(custom.markets.watchlist.coinIds.AAPL, undefined);
  assert.equal(custom.stats.streakMinSec, 60);
});

test("calendar and Obsidian settings are bounded and use safe defaults", () => {
  const settings = Model.sanitizeSettings({
    calendar: { agendaDays: 999, leadMinutes: -1, timeFormat: "arbitrary", mapsProvider: "file://" },
    obsidian: { enabled: "yes", vaultPath: "/home/test/vault", dailyNotesFolder: "Daily" }
  });
  assert.equal(settings.calendar.agendaDays, 60);
  assert.equal(settings.calendar.leadMinutes, 0);
  assert.equal(settings.calendar.timeFormat, "Match khal");
  assert.equal(settings.calendar.mapsProvider, "Google Maps");
  assert.equal(settings.obsidian.enabled, false);
  assert.equal(settings.obsidian.vaultPath, "/home/test/vault");
  assert.equal(settings.obsidian.dailyNotesFolder, "Daily");
});

const test = require("node:test");
const assert = require("node:assert/strict");
const { loadQmlLibrary } = require("./helpers/loadQmlLibrary.js");
const StatsEngine = loadQmlLibrary("logic/StatsEngine.js");

function localDayOffset(now, offset, hour = 12) {
  const date = new Date(now);
  return new Date(date.getFullYear(), date.getMonth(), date.getDate() + offset, hour, 0, 0, 0).getTime();
}

function session(startedAt, kind, durationSec, interruptions = 0) {
  return { startedAt, endedAt: startedAt + durationSec * 1000, kind, durationSec, interruptions };
}

test("filterSessions today includes only today's sessions and can filter by technique", () => {
  const now = new Date(2026, 5, 12, 15, 0, 0).getTime();
  const rows = [
    session(localDayOffset(now, -1), "pomo", 1500),
    session(localDayOffset(now, 0, 9), "pomo", 1500),
    session(localDayOffset(now, 0, 13), "flow", 2400)
  ];
  assert.equal(StatsEngine.filterSessions(rows, "today", "both", now).length, 2);
  assert.equal(StatsEngine.filterSessions(rows, "today", "pomo", now).length, 1);
});

test("summarize counts Pomodoro, Flowtime, interruptions, and focus seconds", () => {
  const result = StatsEngine.summarize([
    session(1, "pomo", 1500),
    session(2, "flow", 2400, 2),
    session(3, "flow", 600, 1)
  ]);
  assert.equal(result.pomodoroSessions, 1);
  assert.equal(result.flowtimeSessions, 2);
  assert.equal(result.sessionCount, 3);
  assert.equal(result.interruptions, 3);
  assert.equal(result.focusSec, 4500);
});

test("streak counts consecutive local days meeting the minimum focus duration", () => {
  const now = new Date(2026, 5, 12, 15, 0, 0).getTime();
  const rows = [
    session(localDayOffset(now, 0), "pomo", 1800),
    session(localDayOffset(now, -1), "flow", 1200),
    session(localDayOffset(now, -2), "pomo", 300)
  ];
  assert.equal(StatsEngine.streak(rows, 900, now), 2);
});

test("history supports a bounded yesterday filter", () => {
  const now = new Date(2026, 5, 12, 15, 0, 0).getTime();
  const rows = [
    session(localDayOffset(now, -1, 9), "pomo", 1500),
    session(localDayOffset(now, 0, 9), "flow", 2400)
  ];
  const result = StatsEngine.filterSessions(rows, "yesterday", "both", now);
  assert.equal(result.length, 1);
  assert.equal(result[0].kind, "pomo");
});

test("tasksDoneOnDay counts only tasks completed today", () => {
  const now = new Date(2026, 5, 12, 15, 0, 0).getTime();
  const tasks = [
    { completedAt: localDayOffset(now, -1) },
    { completedAt: localDayOffset(now, 0, 10) },
    { completedAt: localDayOffset(now, 0, 16) },
    { completedAt: null }
  ];
  assert.equal(StatsEngine.tasksDoneOnDay(tasks, now), 1);
});

test("heatmap returns a seven-row grid with a fixed number of chronological weeks", () => {
  const now = new Date(2026, 5, 12, 15, 0, 0).getTime();
  const rows = [session(localDayOffset(now, 0), "pomo", 1800)];
  const grid = StatsEngine.heatmap(rows, 12, now);
  assert.equal(grid.length, 7);
  assert.ok(grid.every((dayRow) => dayRow.length === 12));
  assert.equal(grid[new Date(now).getDay()][11].focusSec, 1800);
  assert.equal(grid[new Date(now).getDay()][11].level, 4);
});

test("thisWeek starts on Monday and returns the calendar week through Sunday", () => {
  const now = new Date(2026, 5, 12, 15, 0, 0).getTime(); // Friday
  const rows = [session(localDayOffset(now, -3), "flow", 1800, 1)];
  const result = StatsEngine.thisWeek(rows, now);
  assert.equal(result.length, 7);
  assert.deepEqual(result.map((day) => day.dayLabel), ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]);
  assert.equal(result[0].dateKey, "2026-06-08");
  assert.equal(result[6].dateKey, "2026-06-14");
  assert.equal(result[1].focusSec, 1800);
  assert.equal(result[5].focusSec, 0);
});

test("lastWeek returns seven days in chronological order", () => {  
  const now = new Date(2026, 5, 12, 15, 0, 0).getTime();
  const rows = [session(localDayOffset(now, -3), "flow", 1800, 1)];
  const result = StatsEngine.lastWeek(rows, now);
  assert.equal(result.length, 7);
  assert.deepEqual(result.map((day) => day.dateKey), [
    "2026-06-06", "2026-06-07", "2026-06-08", "2026-06-09", "2026-06-10", "2026-06-11", "2026-06-12"
  ]);
  assert.equal(result[3].flowtimeSessions, 1);
  assert.equal(result[3].focusSec, 1800);
});

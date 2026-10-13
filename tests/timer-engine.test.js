const test = require("node:test");
const assert = require("node:assert/strict");
const { loadQmlLibrary } = require("./helpers/loadQmlLibrary.js");
const TimerEngine = loadQmlLibrary("logic/TimerEngine.js");

test("Pomodoro remaining time derives from the wall-clock deadline", () => {
  const timer = { phase: "running", deadlineMs: 15000 };
  assert.equal(TimerEngine.pomodoroRemainingMs(timer, 5000), 10000);
  assert.equal(TimerEngine.pomodoroRemainingMs(timer, 20000), 0);
  assert.equal(TimerEngine.pomodoroRemainingMs({ phase: "stopped", deadlineMs: 50000 }, 5000), 0);
});

test("paused countdown uses its stored remaining duration", () => {
  const timer = { phase: "paused", deadlineMs: 0, pausedRemainingMs: 42000 };
  assert.equal(TimerEngine.pomodoroRemainingMs(timer, 90000), 42000);
});

test("Flowtime elapsed time is accumulated from timestamps", () => {
  const timer = { phase: "running", startedAtMs: 5000, accumulatedMs: 2000 };
  assert.equal(TimerEngine.flowElapsedMs(timer, 10000), 7000);
  assert.equal(TimerEngine.flowElapsedMs({ ...timer, phase: "paused" }, 10000), 2000);
});

test("traditional break suggestions use the configured duration bands", () => {
  assert.equal(TimerEngine.suggestedBreakSec(25 * 60, { breakMode: "traditional" }), 5 * 60);
  assert.equal(TimerEngine.suggestedBreakSec(50 * 60, { breakMode: "traditional" }), 8 * 60);
  assert.equal(TimerEngine.suggestedBreakSec(90 * 60, { breakMode: "traditional" }), 10 * 60);
  assert.equal(TimerEngine.suggestedBreakSec(91 * 60, { breakMode: "traditional" }), 15 * 60);
});

test("proportional break suggestions are clamped between minimum and maximum", () => {
  const config = { breakMode: "proportional", breakRatio: 0.2, minBreakSec: 300, maxBreakSec: 900 };
  assert.equal(TimerEngine.suggestedBreakSec(20 * 60, config), 300);
  assert.equal(TimerEngine.suggestedBreakSec(60 * 60, config), 720);
  assert.equal(TimerEngine.suggestedBreakSec(2 * 60 * 60, config), 900);
});

test("clock formatting adapts to seconds, minutes, and hours", () => {
  assert.equal(TimerEngine.formatClock(9), "09");
  assert.equal(TimerEngine.formatClock(1104), "18:24");
  assert.equal(TimerEngine.formatClock(3723), "01:02:03");
  assert.equal(TimerEngine.formatClock(-1), "00");
});

test("timer display keeps a minute and second field below one hour", () => {
  assert.equal(TimerEngine.formatTimerClock(0), "00:00");
  assert.equal(TimerEngine.formatTimerClock(9), "00:09");
  assert.equal(TimerEngine.formatTimerClock(1104), "18:24");
  assert.equal(TimerEngine.formatTimerClock(3723), "01:02:03");
});

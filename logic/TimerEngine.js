.pragma library

function finiteNumber(value, fallback) {
  var number = Number(value);
  return isFinite(number) ? number : fallback;
}

function pomodoroRemainingMs(timer, nowMs) {
  if (!timer || typeof timer !== "object") return 0;
  var phase = String(timer.phase || "");
  if (phase === "paused")
    return Math.max(0, finiteNumber(timer.pausedRemainingMs, 0));
  if (phase !== "running" && phase !== "break") return 0;
  var now = finiteNumber(nowMs, Date.now());
  return Math.max(0, finiteNumber(timer.deadlineMs, 0) - now);
}

function flowElapsedMs(timer, nowMs) {
  if (!timer || typeof timer !== "object") return 0;
  var accumulated = Math.max(0, finiteNumber(timer.accumulatedMs, 0));
  if (timer.phase === "paused" && timer.pausedPhase !== "break") return accumulated;
  if (timer.phase !== "running") return accumulated;
  var now = finiteNumber(nowMs, Date.now());
  var startedAt = finiteNumber(timer.startedAtMs, now);
  return accumulated + Math.max(0, now - startedAt);
}

function formatClock(totalSeconds) {
  var seconds = Math.max(0, Math.floor(finiteNumber(totalSeconds, 0)));
  var hours = Math.floor(seconds / 3600);
  var minutes = Math.floor((seconds % 3600) / 60);
  var remainder = seconds % 60;
  function pad(value) { return value < 10 ? "0" + value : String(value); }
  if (seconds < 60) return pad(remainder);
  if (seconds < 3600) return pad(minutes) + ":" + pad(remainder);
  return pad(hours) + ":" + pad(minutes) + ":" + pad(remainder);
}

function formatTimerClock(totalSeconds) {
  var seconds = Math.max(0, Math.floor(finiteNumber(totalSeconds, 0)));
  var hours = Math.floor(seconds / 3600);
  var minutes = Math.floor((seconds % 3600) / 60);
  var remainder = seconds % 60;
  function pad(value) { return value < 10 ? "0" + value : String(value); }
  if (hours > 0) return pad(hours) + ":" + pad(minutes) + ":" + pad(remainder);
  return pad(minutes) + ":" + pad(remainder);
}

function suggestedBreakSec(elapsedSec, settings) {
  var elapsed = Math.max(0, finiteNumber(elapsedSec, 0));
  var config = settings && typeof settings === "object" ? settings : {};
  if (config.breakMode === "proportional") {
    var ratio = finiteNumber(config.breakRatio, 0.2);
    ratio = Math.max(0, Math.min(1, ratio));
    var minimum = Math.max(0, finiteNumber(config.minBreakSec, 300));
    var maximum = Math.max(minimum, finiteNumber(config.maxBreakSec, 900));
    return Math.round(Math.max(minimum, Math.min(maximum, elapsed * ratio)));
  }
  if (elapsed <= 25 * 60) return 5 * 60;
  if (elapsed <= 50 * 60) return 8 * 60;
  if (elapsed <= 90 * 60) return 10 * 60;
  return 15 * 60;
}

if (typeof module !== "undefined") {
  module.exports = {
    pomodoroRemainingMs: pomodoroRemainingMs,
    flowElapsedMs: flowElapsedMs,
    formatClock: formatClock,
    formatTimerClock: formatTimerClock,
    suggestedBreakSec: suggestedBreakSec
  };
}

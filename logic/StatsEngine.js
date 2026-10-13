.pragma library

function finiteNumber(value, fallback) {
  if (value === null || value === undefined || value === "") return fallback;
  var number = Number(value);
  return isFinite(number) ? number : fallback;
}

function localStartOfDay(timestamp) {
  var date = timestamp instanceof Date ? new Date(timestamp.getTime()) : new Date(finiteNumber(timestamp, Date.now()));
  if (!isFinite(date.getTime())) date = new Date();
  return new Date(date.getFullYear(), date.getMonth(), date.getDate()).getTime();
}

function dayKey(timestamp) {
  var date = new Date(timestamp);
  if (!isFinite(date.getTime())) return "";
  function pad(value) { return value < 10 ? "0" + value : String(value); }
  return date.getFullYear() + "-" + pad(date.getMonth() + 1) + "-" + pad(date.getDate());
}

function addLocalDays(timestamp, amount) {
  var date = new Date(timestamp);
  return new Date(date.getFullYear(), date.getMonth(), date.getDate() + amount).getTime();
}

function sessionKindMatches(session, kind) {
  if (!kind || kind === "both" || kind === "all") return true;
  var value = String(session && session.kind || "");
  if (kind === "pomo" || kind === "pomodoro") return value === "pomo";
  if (kind === "flow" || kind === "flowtime") return value === "flow";
  return value === kind;
}

function rangeStart(range, nowMs) {
  var key = String(range || "all");
  var today = localStartOfDay(nowMs);
  if (key === "today") return today;
  if (key === "yesterday") return addLocalDays(today, -1);
  if (key === "week" || key === "lastWeek" || key === "last7Days") return addLocalDays(today, -6);
  if (key === "month") {
    var date = new Date(today);
    return new Date(date.getFullYear(), date.getMonth(), 1).getTime();
  }
  return 0;
}

function rangeEnd(range, nowMs) {
  var key = String(range || "all");
  var today = localStartOfDay(nowMs);
  if (key === "today") return addLocalDays(today, 1);
  if (key === "yesterday") return today;
  return finiteNumber(nowMs, Date.now()) + 1;
}

function filterSessions(sessions, range, kind, nowMs) {
  var rows = Array.isArray(sessions) ? sessions : [];
  var now = finiteNumber(nowMs, Date.now());
  var key = String(range || "all");
  var start = rangeStart(key, now);
  var end = rangeEnd(key, now);
  var output = [];
  for (var i = 0; i < rows.length; i++) {
    var session = rows[i];
    if (!session || typeof session !== "object" || !sessionKindMatches(session, kind)) continue;
    var startedAt = finiteNumber(session.startedAt, NaN);
    if (!isFinite(startedAt) || startedAt < start || startedAt >= end || startedAt > now) continue;
    output.push(session);
  }
  output.sort(function(a, b) {
    return finiteNumber(b.startedAt, 0) - finiteNumber(a.startedAt, 0)
      || finiteNumber(b.endedAt, 0) - finiteNumber(a.endedAt, 0);
  });
  return output;
}

function summarize(sessions) {
  var rows = Array.isArray(sessions) ? sessions : [];
  var pomodoroSessions = 0;
  var flowtimeSessions = 0;
  var interruptions = 0;
  var focusSec = 0;
  for (var i = 0; i < rows.length; i++) {
    var session = rows[i];
    if (!session || typeof session !== "object") continue;
    var duration = Math.max(0, Math.floor(finiteNumber(session.durationSec, 0)));
    var kind = String(session.kind || "");
    if (kind === "pomo") pomodoroSessions++;
    else if (kind === "flow") flowtimeSessions++;
    else continue;
    focusSec += duration;
    interruptions += Math.max(0, Math.floor(finiteNumber(session.interruptions, 0)));
  }
  return {
    pomodoroSessions: pomodoroSessions,
    flowtimeSessions: flowtimeSessions,
    pomodoroCount: pomodoroSessions,
    flowtimeCount: flowtimeSessions,
    sessionCount: pomodoroSessions + flowtimeSessions,
    interruptions: interruptions,
    interruptionCount: interruptions,
    focusSec: focusSec
  };
}

function tasksDoneOnDay(tasks, nowMs) {
  var rows = Array.isArray(tasks) ? tasks : [];
  var now = finiteNumber(nowMs, Date.now());
  var start = localStartOfDay(now);
  var end = addLocalDays(start, 1);
  var count = 0;
  for (var i = 0; i < rows.length; i++) {
    var completedAt = finiteNumber(rows[i] && rows[i].completedAt, NaN);
    if (isFinite(completedAt) && completedAt >= start && completedAt < end && completedAt <= now) count++;
  }
  return count;
}

function streak(sessions, minSec, nowMs) {
  var threshold = Math.max(1, finiteNumber(minSec, 1));
  var today = localStartOfDay(finiteNumber(nowMs, Date.now()));
  var totals = {};
  var rows = Array.isArray(sessions) ? sessions : [];
  for (var i = 0; i < rows.length; i++) {
    var session = rows[i];
    if (!session || typeof session !== "object") continue;
    var startedAt = finiteNumber(session.startedAt, NaN);
    var duration = finiteNumber(session.durationSec, 0);
    if (!isFinite(startedAt) || duration <= 0) continue;
    var key = dayKey(startedAt);
    totals[key] = (totals[key] || 0) + duration;
  }
  var count = 0;
  var cursor = today;
  while ((totals[dayKey(cursor)] || 0) >= threshold) {
    count++;
    cursor = addLocalDays(cursor, -1);
  }
  return count;
}

function daySummaries(sessions, start, dayCount, now) {
  var rows = Array.isArray(sessions) ? sessions : [];
  var days = [];
  var labels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
  for (var offset = 0; offset < dayCount; offset++) {
    var startMs = addLocalDays(start, offset);
    var endMs = addLocalDays(startMs, 1);
    var daySessions = [];
    for (var i = 0; i < rows.length; i++) {
      var session = rows[i];
      var startedAt = finiteNumber(session && session.startedAt, NaN);
      if (isFinite(startedAt) && startedAt >= startMs && startedAt < endMs && startedAt <= now)
        daySessions.push(session);
    }
    var summary = summarize(daySessions);
    var date = new Date(startMs);
    days.push({
      dateKey: dayKey(startMs),
      startMs: startMs,
      dayLabel: labels[date.getDay()],
      focusSec: summary.focusSec,
      pomodoroSessions: summary.pomodoroSessions,
      flowtimeSessions: summary.flowtimeSessions,
      sessionCount: summary.sessionCount,
      interruptions: summary.interruptions
    });
  }
  return days;
}

function lastWeek(sessions, nowMs) {
  var now = finiteNumber(nowMs, Date.now());
  var today = localStartOfDay(now);
  return daySummaries(sessions, addLocalDays(today, -6), 7, now);
}

function thisWeek(sessions, nowMs) {
  var now = finiteNumber(nowMs, Date.now());
  var today = localStartOfDay(now);
  var day = new Date(today).getDay();
  var mondayOffset = (day + 6) % 7;
  return daySummaries(sessions, addLocalDays(today, -mondayOffset), 7, now);
}

function heatmap(sessions, weeks, nowMs) {
  var count = Math.floor(finiteNumber(weeks, 12));
  count = Math.max(1, Math.min(52, count));
  var now = finiteNumber(nowMs, Date.now());
  var today = localStartOfDay(now);
  var todayDow = new Date(today).getDay();
  var startDay = addLocalDays(today, -todayDow - (count - 1) * 7);
  var byDay = {};
  var rows = Array.isArray(sessions) ? sessions : [];
  for (var i = 0; i < rows.length; i++) {
    var startedAt = finiteNumber(rows[i] && rows[i].startedAt, NaN);
    var duration = Math.max(0, Math.floor(finiteNumber(rows[i] && rows[i].durationSec, 0)));
    if (!isFinite(startedAt) || duration <= 0 || startedAt > now) continue;
    var key = dayKey(startedAt);
    byDay[key] = (byDay[key] || 0) + duration;
  }

  var max = 0;
  for (var dayIndex = 0; dayIndex < count * 7; dayIndex++) {
    var maxKey = dayKey(addLocalDays(startDay, dayIndex));
    if ((byDay[maxKey] || 0) > max) max = byDay[maxKey];
  }

  var grid = [[], [], [], [], [], [], []];
  for (var weekIndex = 0; weekIndex < count; weekIndex++) {
    for (var weekday = 0; weekday < 7; weekday++) {
      var timestamp = addLocalDays(startDay, weekIndex * 7 + weekday);
      var seconds = byDay[dayKey(timestamp)] || 0;
      var level = max === 0 || seconds === 0 ? 0
        : Math.min(4, Math.max(1, Math.ceil((seconds / max) * 4)));
      grid[weekday].push({ date: timestamp, focusSec: seconds, level: level });
    }
  }
  return grid;
}

if (typeof module !== "undefined") {
  module.exports = {
    filterSessions: filterSessions,
    summarize: summarize,
    tasksDoneOnDay: tasksDoneOnDay,
    streak: streak,
    lastWeek: lastWeek,
    thisWeek: thisWeek,
    heatmap: heatmap,
    localStartOfDay: localStartOfDay,
    dayKey: dayKey,
    addLocalDays: addLocalDays
  };
}

.pragma library

var DEFAULT_FORMAT = "dddd HH:mm";
var DEFAULT_FORMAT_ALT = "d MMMM 'W'ww yyyy";
var DEFAULT_VERTICAL_FORMAT = "HH\n—\nmm";

var FORMATS = [
  "dddd HH:mm",
  "dddd h:mm AP",
  "HH:mm",
  "h:mm AP",
  "ddd d MMM HH:mm",
  "ddd d MMM h:mm AP",
  "d MMMM 'W'ww yyyy",
  "yyyy-MM-dd HH:mm"
];

var VERTICAL_FORMATS = [
  "HH\n—\nmm",
  "h\n—\nmm\nAP",
  "dd\nMMM\n'W'ww\n''yy",
  "HH\nmm"
];

function formats(vertical) {
  return vertical ? VERTICAL_FORMATS.slice() : FORMATS.slice();
}

function nextFormat(current, vertical, alternate) {
  var ring = vertical === undefined
    ? FORMATS.concat(VERTICAL_FORMATS)
    : formats(!!vertical);
  var alternateFormat = String(alternate || "");
  if (vertical === false && alternateFormat !== "" && ring.indexOf(alternateFormat) === -1)
    ring.splice(1, 0, alternateFormat);
  var index = ring.indexOf(String(current || ""));
  if (index === -1) return ring[0];
  return ring[(index + 1) % ring.length];
}

function pad2(value) {
  var number = Math.floor(Number(value) || 0);
  return (number < 10 ? "0" : "") + number;
}

function isoWeek(year, month, day) {
  var date = new Date(Date.UTC(year, month, day));
  var weekday = date.getUTCDay() || 7;
  date.setUTCDate(date.getUTCDate() + 4 - weekday);
  var yearStart = new Date(Date.UTC(date.getUTCFullYear(), 0, 1));
  return Math.ceil((((date - yearStart) / 86400000) + 1) / 7);
}

function isoWeekLiteral(year, month, day) {
  return pad2(isoWeek(year, month, day));
}

function substituteIsoWeek(format, date) {
  var input = date instanceof Date ? date : new Date(date);
  if (isNaN(input.getTime())) return String(format || "");
  var week = isoWeekLiteral(input.getFullYear(), input.getMonth(), input.getDate());
  return String(format || "").replace(/ww/g, week);
}

var WEEKDAY_SHORT = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"];
var WEEKDAY_FULL = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
var MONTH_SHORT = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
var MONTH_FULL = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];

function normalizeWeekStart(value) {
  var start = Math.floor(Number(value));
  return start === 0 ? 0 : 1;
}

function dateKey(year, month, day) {
  var y = Math.floor(Number(year));
  var m = Math.floor(Number(month));
  var d = Math.floor(Number(day));
  return String(y) + "-" + pad2(m + 1) + "-" + pad2(d);
}

function localDateKey(date) {
  var input = date instanceof Date ? date : new Date(date);
  if (isNaN(input.getTime())) return "";
  return dateKey(input.getFullYear(), input.getMonth(), input.getDate());
}

function weekdayLabels(weekStart) {
  var start = normalizeWeekStart(weekStart);
  var labels = [];
  for (var i = 0; i < 7; i++) labels.push(WEEKDAY_SHORT[(start + i) % 7]);
  return labels;
}

// Build each civil date in UTC so local DST transitions cannot skip a grid cell.
function monthGrid(year, month, weekStart, todayKey) {
  var y = Math.floor(Number(year));
  var m = Math.floor(Number(month));
  var start = normalizeWeekStart(weekStart);
  var firstWeekday = new Date(Date.UTC(y, m, 1)).getUTCDay();
  var leading = (firstWeekday - start + 7) % 7;
  var firstDayUtc = Date.UTC(y, m, 1 - leading);
  var currentKey = String(todayKey || localDateKey(new Date()));
  var weeks = [];

  for (var week = 0; week < 6; week++) {
    var days = [];
    for (var day = 0; day < 7; day++) {
      var date = new Date(firstDayUtc + (week * 7 + day) * 86400000);
      var dateYear = date.getUTCFullYear();
      var dateMonth = date.getUTCMonth();
      var dateDay = date.getUTCDate();
      var key = dateKey(dateYear, dateMonth, dateDay);
      days.push({
        year: dateYear,
        month: dateMonth,
        day: dateDay,
        weekday: date.getUTCDay(),
        dateKey: key,
        inMonth: dateYear === y && dateMonth === m,
        today: key === currentKey
      });
    }
    weeks.push({ index: week, days: days });
  }
  return weeks;
}

function monthTitle(year, month) {
  var index = Math.floor(Number(month));
  if (index < 0 || index > 11) return "";
  return MONTH_FULL[index] + " " + String(Math.floor(Number(year)));
}

function dayHeading(date, now) {
  var input = date instanceof Date ? date : new Date(date);
  if (isNaN(input.getTime())) return "";
  var current = now instanceof Date ? now : new Date(now === undefined ? Date.now() : now);
  var key = localDateKey(input);
  var today = localDateKey(current);
  var tomorrow = new Date(current.getFullYear(), current.getMonth(), current.getDate() + 1);
  var prefix = key === today ? "Today · " : key === localDateKey(tomorrow) ? "Tomorrow · " : "";
  return prefix + WEEKDAY_FULL[input.getDay()] + ", " + MONTH_SHORT[input.getMonth()] + " " + input.getDate();
}

if (typeof module !== "undefined") {
  module.exports = {
    DEFAULT_FORMAT: DEFAULT_FORMAT,
    DEFAULT_FORMAT_ALT: DEFAULT_FORMAT_ALT,
    DEFAULT_VERTICAL_FORMAT: DEFAULT_VERTICAL_FORMAT,
    FORMATS: FORMATS,
    VERTICAL_FORMATS: VERTICAL_FORMATS,
    formats: formats,
    nextFormat: nextFormat,
    pad2: pad2,
    isoWeek: isoWeek,
    isoWeekLiteral: isoWeekLiteral,
    substituteIsoWeek: substituteIsoWeek,
    WEEKDAY_SHORT: WEEKDAY_SHORT,
    WEEKDAY_FULL: WEEKDAY_FULL,
    MONTH_SHORT: MONTH_SHORT,
    MONTH_FULL: MONTH_FULL,
    normalizeWeekStart: normalizeWeekStart,
    dateKey: dateKey,
    localDateKey: localDateKey,
    weekdayLabels: weekdayLabels,
    monthGrid: monthGrid,
    monthTitle: monthTitle,
    dayHeading: dayHeading
  };
}

const test = require("node:test");
const assert = require("node:assert/strict");
const { loadQmlLibrary } = require("./helpers/loadQmlLibrary.js");
const ClockModel = loadQmlLibrary("logic/ClockModel.js");

test("clock presets cycle within the selected orientation", () => {
  assert.equal(ClockModel.nextFormat("dddd HH:mm", false), "dddd h:mm AP");
  assert.equal(ClockModel.nextFormat("HH\n—\nmm", true), "h\n—\nmm\nAP");
  assert.equal(ClockModel.nextFormat("unknown", true), ClockModel.VERTICAL_FORMATS[0]);
  assert.equal(ClockModel.nextFormat("dddd HH:mm", false, "custom format"), "custom format");
});

test("clock preset lists are returned as independent arrays", () => {
  const formats = ClockModel.formats(false);
  formats.push("custom");
  assert.equal(ClockModel.FORMATS.includes("custom"), false);
});

test("ISO week calculation handles year boundaries", () => {
  assert.equal(ClockModel.isoWeek(2021, 0, 1), 53);
  assert.equal(ClockModel.isoWeek(2021, 0, 4), 1);
  assert.equal(ClockModel.isoWeek(2024, 11, 30), 1);
});

test("ISO week tokens are replaced with a two-digit literal", () => {
  const date = new Date(2021, 0, 4);
  assert.equal(ClockModel.substituteIsoWeek("'W'ww yyyy", date), "'W'01 yyyy");
});

test("month grids always contain 42 consecutive civil dates without local DST arithmetic", () => {
  const grid = ClockModel.monthGrid(2026, 9, 1, "2026-10-12");
  assert.equal(grid.length, 6);
  assert.ok(grid.every((week) => week.days.length === 7));
  assert.equal(grid[0].days[0].dateKey, "2026-09-28");
  assert.equal(grid[2].days[0].dateKey, "2026-10-12");
  assert.equal(grid[2].days[0].today, true);
  assert.equal(grid.flatMap((week) => week.days).length, 42);
});

test("weekday labels, month titles, and day headings stay in English", () => {
  assert.deepEqual(ClockModel.weekdayLabels(1), ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]);
  assert.equal(ClockModel.monthTitle(2026, 9), "October 2026");
  assert.equal(ClockModel.dayHeading(new Date(2026, 9, 12), new Date(2026, 9, 12)), "Today · Monday, Oct 12");
});

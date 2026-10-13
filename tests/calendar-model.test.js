const test = require("node:test");
const assert = require("node:assert/strict");
const { loadQmlLibrary } = require("./helpers/loadQmlLibrary.js");
const CalendarModel = loadQmlLibrary("logic/CalendarModel.js");

const printFormats = [
  "dateformat: 2013-12-21",
  "longdateformat: Saturday, December 21, 2013",
  "timeformat: 21:45"
].join("\n");
const formats = CalendarModel.parseFormats(printFormats);

test("parsePrintFormats can round-trip khal's required sample", () => {
  assert.equal(formats.ok, true);
  assert.deepEqual(CalendarModel.parseDate(formats.longdate, formats.datePattern), {
    year: 2013,
    month: 12,
    day: 21
  });
  assert.deepEqual(CalendarModel.parseTime(formats.time, formats.timePattern), {
    hour: 21,
    minute: 45
  });
  assert.equal(CalendarModel.formatKhalDate(new Date(2026, 9, 12), formats.datePattern), "Monday, October 12, 2026");
});

test("unsupported khal samples return explicit configuration guidance", () => {
  const result = CalendarModel.parseFormats("longdateformat: samedi 21 décembre 2013\ntimeformat: 21h45");
  assert.equal(result.ok, false);
  assert.match(result.error, /longdateformat = %Y-%m-%d/);
  assert.match(result.error, /timeformat = %H:%M/);
});

test("khal event JSON is normalized, sorted, and multi-day duplicates use UID plus start", () => {
  const timed = {
    uid: "event-1",
    calendar: "Work",
    title: "Planning",
    "all-day": "False",
    "start-date-long": "Saturday, December 21, 2013",
    "start-time": "21:45",
    "end-date-long": "Saturday, December 21, 2013",
    "end-time": "22:15",
    "calendar-color": "#123456",
    location: "Room A",
    description: "Bring notes",
    organizer: "Ada Lovelace (ada@example.com)",
    status: "CONFIRMED",
    url: "https://meet.google.com/abc-defg-hij"
  };
  const repeated = { ...timed };
  const allDay = {
    uid: "event-2",
    calendar: "Personal",
    title: "Holiday",
    "all-day": "True",
    "start-date-long": "Saturday, December 21, 2013",
    "end-date-long": "Sunday, December 22, 2013",
    "calendar-color": "#AABBCC80"
  };
  const events = CalendarModel.parseEvents(
    [JSON.stringify([timed, allDay]), JSON.stringify([repeated])].join("\n"),
    formats
  );
  assert.equal(events.length, 2);
  assert.equal(events[0].title, "Holiday");
  assert.equal(events[0].allDay, true);
  assert.equal(events[0].end, new Date(2013, 11, 23).getTime());
  assert.equal(events[0].color, "#80AABBCC");
  assert.equal(CalendarModel.qmlColor(events[0].color, true), "#80AABBCC");
  assert.equal(events[1].title, "Planning");
  assert.equal(events[1].serviceName, "Google Meet");
  assert.equal(events[1].meetingUrl, "https://meet.google.com/abc-defg-hij");
  assert.equal(events[1].organizer.email, "ada@example.com");
  assert.ok(events[1].start > events[0].start);
});

test("ICS parsing extracts conference, organizer, attendees, and unfolded plain description", () => {
  const ics = [
    "BEGIN:VCALENDAR",
    "BEGIN:VEVENT",
    "UID:meeting-42@example.com",
    "X-GOOGLE-CONFERENCE:https://meet.google.com/abc-defg-hij",
    "ORGANIZER;CN=Grace Hopper:mailto:grace@example.com",
    "ATTENDEE;CN=Grace Hopper;PARTSTAT=ACCEPTED:mailto:grace@example.com",
    "ATTENDEE;CN=Linus Torvalds;PARTSTAT=TENTATIVE:mailto:linus@example.com",
    "DESCRIPTION:First line\\nSecond line\\, with detail",
    "END:VEVENT",
    "END:VCALENDAR"
  ].join("\r\n");
  const details = CalendarModel.parseIcsDetails(ics, "meeting-42@example.com");
  assert.equal(details.conference, "https://meet.google.com/abc-defg-hij");
  assert.equal(details.description, "First line\nSecond line, with detail");
  assert.deepEqual(details.organizer, { name: "Grace Hopper", email: "grace@example.com" });
  assert.equal(details.attendees.length, 2);
  assert.equal(details.attendees[0].organizer, true);
  assert.equal(details.attendees[1].status, "TENTATIVE");
  assert.equal(CalendarModel.parseIcsDetails(ics, "missing"), null);
});

test("event detail links only expose allowed web and meeting schemes", () => {
  const safe = CalendarModel.eventDetails({
    location: "https://zoom.us/j/123",
    description: "Join at https://teams.microsoft.com/l/meetup-join/abc and see javascript:alert(1)"
  });
  assert.equal(safe.meeting.label, "Zoom");
  assert.equal(safe.meeting.url, "https://zoom.us/j/123");
  assert.equal(safe.location, "");
  assert.ok(safe.links.every((link) => /^https?:\/\//.test(link.url)));
  assert.equal(CalendarModel.isOpenableUrl("file:///etc/passwd"), false);
  assert.equal(CalendarModel.meetingService("msteams://l/meetup-join/abc"), "Microsoft Teams");
});

test("event dots mark every touched day without marking a midnight end date", () => {
  const start = new Date(2026, 9, 11, 22, 0).getTime();
  const midnight = new Date(2026, 9, 12, 0, 0).getTime();
  const map = CalendarModel.eventsByDay([
    { start, end: midnight, color: "#123456" },
    { start: midnight, end: midnight + 3600000, color: "#ABCDEF" }
  ]);
  assert.deepEqual(map["2026-10-11"].map((dot) => dot.color), ["#123456"]);
  assert.deepEqual(map["2026-10-12"].map((dot) => dot.color), ["#ABCDEF"]);
  const sameColor = CalendarModel.eventsByDay([
    { key: "a", calendar: "Work", start, end: midnight, color: "#123456" },
    { key: "b", calendar: "Personal", start, end: midnight, color: "#123456" }
  ]);
  assert.equal(sameColor["2026-10-11"].length, 2);
});

test("due notifications honor lead time, grace, cancellation, and prior delivery", () => {
  const now = 1000000;
  const events = [
    { key: "soon", start: now + 60000, allDay: false, status: "CONFIRMED" },
    { key: "grace", start: now - 60000, allDay: false, status: "CONFIRMED" },
    { key: "far", start: now + 900000, allDay: false, status: "CONFIRMED" },
    { key: "day", start: now, allDay: true, status: "CONFIRMED" },
    { key: "cancelled", start: now, allDay: false, status: "CANCELLED" }
  ];
  assert.deepEqual(CalendarModel.dueNotifications(events, now, 2, { soon: now }), [events[1]]);
  assert.deepEqual(CalendarModel.pruneNotified({ old: now - CalendarModel.DAY_MS - 1, keep: now }, now), { keep: now });
});

test("agenda helpers group upcoming events by local day", () => {
  const now = new Date(2026, 9, 12, 10, 0).getTime();
  const events = [
    { title: "Earlier", start: now - 7200000, end: now - 3600000, allDay: false },
    { title: "Later", start: now + 3600000, end: now + 7200000, allDay: false }
  ];
  const rows = CalendarModel.agendaRows(events, now);
  assert.deepEqual(rows.map((row) => row.kind), ["day", "event"]);
  assert.equal(rows[0].label, "Today · Monday, Oct 12");
  assert.equal(CalendarModel.eventsForDate(events, new Date(now - 86400000)).length, 0);
  assert.equal(CalendarModel.eventsForDate(events, new Date(now)).length, 2);
});

test("command parsing avoids shell interpretation and month cache uses YYYY-MM keys", () => {
  assert.deepEqual(CalendarModel.safeCommandArgs("vdirsyncer sync"), ["vdirsyncer", "sync"]);
  assert.deepEqual(CalendarModel.safeCommandArgs("vdirsyncer sync; rm -rf ~"), []);
  assert.equal(CalendarModel.monthKey(2026, 9), "2026-10");
  const agendaArgs = CalendarModel.khalListArgs(7);
  assert.ok(agendaArgs.includes("--json"));
  assert.ok(agendaArgs.includes("--day-format"));
  assert.ok(agendaArgs.includes("today"));
  assert.ok(agendaArgs.includes("7d"));
  const args = CalendarModel.khalRangeArgs(new Date(2026, 9, 1).getTime(), 48, formats);
  assert.ok(args.includes("list"));
  assert.ok(args.includes("48d"));
});

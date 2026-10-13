.pragma library

var DAY_MS = 86400000;
var SAMPLE_ERROR = "khal date/time formats cannot be parsed; set longdateformat = %Y-%m-%d and timeformat = %H:%M in the [locale] section of khal's config.";
var MONTH_FULL = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
var MONTH_SHORT = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
var WEEKDAY_FULL = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
var WEEKDAY_SHORT = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

var DATE_SAMPLE_TOKENS = [
  { text: "2013", kind: "year4" },
  { text: "December", kind: "monthFull" },
  { text: "Saturday", kind: "weekdayFull" },
  { text: "Dec", kind: "monthShort" },
  { text: "Sat", kind: "weekdayShort" },
  { text: "12", kind: "month" },
  { text: "21", kind: "day" },
  { text: "13", kind: "year2" }
];

var TIME_SAMPLE_TOKENS = [
  { text: "21", kind: "hour" },
  { text: "09", kind: "hour" },
  { text: "9", kind: "hour" },
  { text: "45", kind: "minute" },
  { text: "00", kind: "second" },
  { text: "PM", kind: "ampm" },
  { text: "pm", kind: "ampm" }
];

function escapeRegExp(text) {
  return String(text).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function sortedTokens(tokens) {
  var copy = tokens.slice();
  copy.sort(function(a, b) { return b.text.length - a.text.length; });
  return copy;
}

function compileSample(sample, tokens, ignoreCase) {
  var source = String(sample || "").trim();
  if (source === "") return null;
  var ordered = sortedTokens(tokens);
  var parts = [];
  var fields = [];
  var expression = "^";
  var literal = "";
  var index = 0;
  while (index < source.length) {
    var found = null;
    for (var tokenIndex = 0; tokenIndex < ordered.length; tokenIndex++) {
      var token = ordered[tokenIndex];
      var candidate = source.substr(index, token.text.length);
      if (ignoreCase ? candidate.toLowerCase() === token.text.toLowerCase() : candidate === token.text) {
        found = token;
        break;
      }
    }
    if (found) {
      if (literal !== "") {
        parts.push({ kind: "literal", text: literal });
        expression += escapeRegExp(literal);
        literal = "";
      }
      var capture = "([0-9]{1,4})";
      if (found.kind === "monthFull") capture = "([A-Za-z]+)";
      else if (found.kind === "monthShort") capture = "([A-Za-z]{3})";
      else if (found.kind === "weekdayFull") capture = "([A-Za-z]+)";
      else if (found.kind === "weekdayShort") capture = "([A-Za-z]{3})";
      else if (found.kind === "ampm") capture = "(AM|PM|am|pm)";
      parts.push({ kind: "field", field: found.kind, sample: found.text });
      fields.push(found.kind);
      expression += capture;
      index += found.text.length;
    } else {
      literal += source.charAt(index);
      index++;
    }
  }
  if (literal !== "") {
    parts.push({ kind: "literal", text: literal });
    expression += escapeRegExp(literal);
  }
  expression += "$";
  try {
    return { source: source, regex: new RegExp(expression, ignoreCase ? "i" : ""), parts: parts, fields: fields };
  } catch (error) {
    return null;
  }
}

function parsePrintFormats(text) {
  var source = String(text || "");
  function sample(name) {
    var regex = new RegExp("^\\s*" + name + "\\s*:\\s*(.*?)\\s*$", "im");
    var match = regex.exec(source);
    return match ? String(match[1] || "").trim() : "";
  }
  var longdate = sample("longdateformat");
  var time = sample("timeformat");
  if (longdate === "") longdate = sample("longdate");
  if (time === "") time = sample("time");
  var datePattern = compileSample(longdate, DATE_SAMPLE_TOKENS, true);
  var timePattern = compileSample(time, TIME_SAMPLE_TOKENS, true);
  if (!datePattern || !timePattern) return { ok: false, error: SAMPLE_ERROR };
  var dateValue = parseDate(longdate, datePattern);
  var timeValue = parseTime(time, timePattern);
  if (!dateValue || !timeValue || dateValue.year !== 2013 || dateValue.month !== 12 || dateValue.day !== 21
      || timeValue.hour !== 21 || timeValue.minute !== 45) {
    return { ok: false, error: SAMPLE_ERROR };
  }
  var use24h = !/(AM|PM)/i.test(time);
  return {
    ok: true,
    error: "",
    longdate: longdate,
    time: time,
    datePattern: datePattern,
    timePattern: timePattern,
    use24h: use24h
  };
}

function parseFormats(text) { return parsePrintFormats(text); }

function parseDate(text, pattern) {
  if (!pattern || !pattern.regex) return null;
  var match = pattern.regex.exec(String(text || "").trim());
  if (!match) return null;
  var values = {};
  var capture = 1;
  for (var i = 0; i < pattern.parts.length; i++) {
    var part = pattern.parts[i];
    if (part.kind !== "field") continue;
    var value = String(match[capture++] || "");
    if (part.field === "monthFull" || part.field === "monthShort") {
      var monthIndex = monthIndexOf(value);
      if (monthIndex >= 0) values.month = monthIndex + 1;
    } else if (part.field === "day") values.day = parseInt(value, 10);
    else if (part.field === "month") values.month = parseInt(value, 10);
    else if (part.field === "monthOrDay") {
      if (values.month === undefined) values.month = parseInt(value, 10);
      else if (values.day === undefined) values.day = parseInt(value, 10);
    } else if (part.field === "year4") values.year = parseInt(value, 10);
    else if (part.field === "year2") values.year = 2000 + parseInt(value, 10);
  }
  var year = values.year;
  var month = values.month;
  var day = values.day;
  if (!isFinite(year) || !isFinite(month) || !isFinite(day)) return null;
  if (year < 100) year += 2000;
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  var check = new Date(year, month - 1, day);
  if (check.getFullYear() !== year || check.getMonth() !== month - 1 || check.getDate() !== day) return null;
  return { year: year, month: month, day: day };
}

function monthIndexOf(value) {
  var text = String(value || "").toLowerCase();
  for (var i = 0; i < MONTH_FULL.length; i++) {
    if (MONTH_FULL[i].toLowerCase() === text || MONTH_SHORT[i].toLowerCase() === text) return i;
  }
  return -1;
}

function parseTime(text, pattern) {
  if (!pattern || !pattern.regex) return null;
  var match = pattern.regex.exec(String(text || "").trim());
  if (!match) return null;
  var values = {};
  var capture = 1;
  for (var i = 0; i < pattern.parts.length; i++) {
    var part = pattern.parts[i];
    if (part.kind !== "field") continue;
    var value = String(match[capture++] || "");
    if (part.field === "hour") values.hour = parseInt(value, 10);
    else if (part.field === "minute") values.minute = parseInt(value, 10);
    else if (part.field === "ampm") values.ampm = value.toUpperCase();
  }
  var hour = values.hour;
  var minute = values.minute;
  if (!isFinite(hour) || !isFinite(minute) || minute < 0 || minute > 59) return null;
  if (values.ampm) {
    if (hour < 1 || hour > 12) return null;
    if (values.ampm === "AM" && hour === 12) hour = 0;
    else if (values.ampm === "PM" && hour !== 12) hour += 12;
  } else if (hour < 0 || hour > 23) return null;
  return { hour: hour, minute: minute };
}

function pad2(value) { return Number(value) < 10 ? "0" + Number(value) : String(value); }

function formatKhalDate(date, pattern) {
  var input = date instanceof Date ? date : new Date(date);
  if (isNaN(input.getTime()) || !pattern || !pattern.parts) return "";
  var result = "";
  for (var i = 0; i < pattern.parts.length; i++) {
    var part = pattern.parts[i];
    if (part.kind === "literal") {
      result += part.text;
      continue;
    }
    var field = part.field;
    var sample = part.sample;
    if (field === "year4") result += String(input.getFullYear());
    else if (field === "year2") result += pad2(input.getFullYear() % 100);
    else if (field === "monthFull") result += MONTH_FULL[input.getMonth()];
    else if (field === "monthShort") result += MONTH_SHORT[input.getMonth()];
    else if (field === "month") result += sample.length > 1 ? pad2(input.getMonth() + 1) : String(input.getMonth() + 1);
    else if (field === "day") result += sample.length > 1 ? pad2(input.getDate()) : String(input.getDate());
    else if (field === "weekdayFull") result += WEEKDAY_FULL[input.getDay()];
    else if (field === "weekdayShort") result += WEEKDAY_SHORT[input.getDay()];
  }
  return result;
}

function dateKey(date) {
  var input = date instanceof Date ? date : new Date(date);
  if (isNaN(input.getTime())) return "";
  return input.getFullYear() + "-" + pad2(input.getMonth() + 1) + "-" + pad2(input.getDate());
}

function khalArgs(args) {
  var command = ["sh", "-c", "command -v khal >/dev/null 2>&1 || exit 127; exec khal \"$@\"", "kairos-khal"];
  var supplied = Array.isArray(args) ? args : [];
  for (var i = 0; i < supplied.length; i++) command.push(String(supplied[i]));
  return command;
}

var JSON_FIELDS = ["uid", "title", "calendar", "calendar-color", "location",
  "all-day", "start-date-long", "start-time", "end-date-long", "end-time",
  "description", "url", "organizer", "status", "repeat-pattern"];

function listJsonArgs(start, days) {
  var args = ["list"];
  for (var i = 0; i < JSON_FIELDS.length; i++) args.push("--json", JSON_FIELDS[i]);
  args.push("--day-format", "", String(start), String(Math.max(1, Math.floor(Number(days) || 7))) + "d");
  return khalArgs(args);
}

function khalListArgs(days) {
  return listJsonArgs("today", days);
}

function monthRange(year, month) {
  // Begin five civil days before the first, leaving room for a six-week grid.
  var start = new Date(Number(year), Number(month), -5);
  start.setHours(0, 0, 0, 0);
  return { start: start.getTime(), days: 48 };
}

function khalRangeArgs(startMs, days, formats) {
  var parsed = formats || null;
  if (!parsed || !parsed.datePattern) return [];
  var start = formatKhalDate(startMs, parsed.datePattern);
  if (!start) return [];
  return listJsonArgs(start, days || 48);
}

// A deliberately small argv grammar: a configured sync command is executed
// directly, never through a shell. Shell operators and expansions are rejected.
function safeCommandArgs(command) {
  var text = String(command || "").trim();
  if (text === "" || /[\u0000-\u001f\u007f;&|$<>`'"\\]/.test(text)) return [];
  var parts = text.split(/\s+/);
  for (var i = 0; i < parts.length; i++) {
    if (!/^[A-Za-z0-9_./:@%+=,-]+$/.test(parts[i])) return [];
  }
  if (parts[0].charAt(0) === "-") return [];
  return parts;
}

function parseEvents(text, formats) {
  if (!formats || formats.ok === false) return [];
  var out = [];
  var seen = {};
  var lines = String(text || "").split("\n");
  for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
    var line = lines[lineIndex].trim();
    if (line.charAt(0) !== "[") continue;
    var rows;
    try { rows = JSON.parse(line); } catch (error) { continue; }
    if (!Array.isArray(rows)) continue;
    for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      var event = normalizeEvent(rows[rowIndex], formats);
      if (!event || seen[event.key]) continue;
      seen[event.key] = true;
      out.push(event);
    }
  }
  out.sort(function(a, b) {
    return a.start - b.start || (a.allDay === b.allDay ? 0 : a.allDay ? -1 : 1)
      || String(a.title).localeCompare(String(b.title));
  });
  return out;
}

function normalizeEvent(row, formats) {
  if (!row || typeof row !== "object") return null;
  var allDay = row["all-day"] === true || String(row["all-day"]).toLowerCase() === "true";
  var startDate = parseDate(row["start-date-long"], formats.datePattern);
  if (!startDate) return null;
  var startTime = allDay ? null : parseTime(row["start-time"], formats.timePattern);
  if (!allDay && !startTime) return null;
  var endDate = parseDate(row["end-date-long"], formats.datePattern) || startDate;
  var endTime = allDay ? null : parseTime(row["end-time"], formats.timePattern);
  var start = new Date(startDate.year, startDate.month - 1, startDate.day,
    startTime ? startTime.hour : 0, startTime ? startTime.minute : 0, 0, 0).getTime();
  var end = allDay
    ? new Date(endDate.year, endDate.month - 1, endDate.day + 1).getTime()
    : (endTime ? new Date(endDate.year, endDate.month - 1, endDate.day, endTime.hour, endTime.minute, 0, 0).getTime() : start);
  if (end < start) end = start;
  var uid = String(row.uid || "").trim();
  var calendar = String(row.calendar || "").trim();
  var title = String(row.title || "(untitled)").replace(/[\r\n]+/g, " ").trim();
  if (title === "") title = "(untitled)";
  var key = uid
    ? uid + "|" + start
    : calendar + "|" + title + "|" + start + "|" + end;
  var event = {
    key: key,
    uid: uid,
    title: title,
    calendar: calendar,
    color: qmlColor(row["calendar-color"]),
    location: cleanDescription(row.location),
    description: cleanDescription(row.description),
    url: String(row.url || "").trim(),
    organizer: parseOrganizer(row.organizer),
    status: String(row.status || "").toUpperCase(),
    repeating: String(row["repeat-pattern"] || "").trim() !== "",
    allDay: allDay,
    start: start,
    end: end
  };
  return enrichEvent(event, null, formats.use24h !== false);
}

function qmlColor(value, alreadyQml) {
  var color = String(value || "").trim();
  if (/^#[0-9a-f]{6}$/i.test(color)) return color;
  if (/^#[0-9a-f]{8}$/i.test(color))
    return alreadyQml ? color : "#" + color.substr(7, 2) + color.substr(1, 6);
  return "";
}

function cleanDescription(value) {
  var text = String(value || "").replace(/\r\n?/g, "\n").replace(/\\n/g, "\n").replace(/\\,/g, ",");
  if (/<\/?[a-z][^>]*>/i.test(text)) {
    text = text
      .replace(/<a\b[^>]*href\s*=\s*["']([^"']+)["'][^>]*>([\s\S]*?)<\/a>/gi, function(_, href, label) {
        var plain = label.replace(/<[^>]+>/g, "").trim();
        return !plain || decodeEntities(plain) === decodeEntities(href) ? href : plain + " (" + href + ")";
      })
      .replace(/<br\s*\/?>/gi, "\n")
      .replace(/<\/(p|div|li|h[1-6]|tr)>/gi, "\n")
      .replace(/<li[^>]*>/gi, "- ")
      .replace(/<[^>]+>/g, "");
    text = decodeEntities(text);
  }
  return text.replace(/[ \t]+\n/g, "\n").replace(/\n{3,}/g, "\n\n").trim();
}

function decodeEntities(text) {
  return String(text)
    .replace(/&nbsp;/gi, " ")
    .replace(/&lt;/gi, "<")
    .replace(/&gt;/gi, ">")
    .replace(/&quot;/gi, "\"")
    .replace(/&#39;|&apos;/gi, "'")
    .replace(/&#(\d+);/g, function(_, number) { return String.fromCharCode(parseInt(number, 10)); })
    .replace(/&amp;/gi, "&");
}

var URL_PATTERN = /\b(?:https?:\/\/|zoommtg:\/\/|zoomus:\/\/|msteams:\/\/)[^\s<>"'`]+/gi;

function trimUrl(value) {
  var url = String(value || "").replace(/[.,;:!?]+$/, "");
  while (/[)\]]$/.test(url)) {
    var close = url.charAt(url.length - 1);
    var open = close === ")" ? "(" : "[";
    if (url.split(open).length >= url.split(close).length) break;
    url = url.slice(0, -1);
  }
  return url;
}

function extractUrls(text) {
  var found = String(text || "").match(URL_PATTERN) || [];
  var urls = [];
  for (var i = 0; i < found.length; i++) {
    var url = trimUrl(found[i]);
    if (url && urls.indexOf(url) === -1) urls.push(url);
  }
  return urls;
}

var MEETING_SERVICES = [
  { label: "Google Meet", pattern: /^https:\/\/meet\.google\.com\/[a-z0-9-]+/i },
  { label: "Zoom", pattern: /^(?:https:\/\/(?:[\w-]+\.)?zoom\.us\/(?:j|s|w|wc\/join|my)\/|zoom(?:mtg|us):\/\/)/i },
  { label: "Microsoft Teams", pattern: /^(?:https:\/\/teams\.(?:microsoft|live)\.com\/(?:l\/meetup-join|meet)\/|msteams:\/\/)/i },
  { label: "Jitsi", pattern: /^https:\/\/meet\.jit\.si\/[^\/?#]+/i },
  { label: "Webex", pattern: /^https:\/\/[\w-]+\.webex\.com\/(?:meet|join|[\w-]+\/j\.php)/i },
  { label: "Whereby", pattern: /^https:\/\/whereby\.com\/[^\/?#]+/i },
  { label: "Signal", pattern: /^https:\/\/signal\.group\/call\//i },
  { label: "Discord", pattern: /^https:\/\/discord\.(?:gg|com\/invite)\//i }
];

function meetingService(url) {
  var text = String(url || "");
  for (var i = 0; i < MEETING_SERVICES.length; i++) {
    if (MEETING_SERVICES[i].pattern.test(text)) return MEETING_SERVICES[i].label;
  }
  return "";
}

function isOpenableUrl(url) {
  return /^(?:https?:\/\/[^\s]+|zoommtg:\/\/[^\s]+|zoomus:\/\/[^\s]+|msteams:\/\/[^\s]+)$/i.test(String(url || ""));
}

function parseOrganizer(value) {
  var text = String(value || "").trim();
  if (!text) return null;
  var match = text.match(/^(.*?)\s*\(([^()]+@[^()]+)\)$/);
  var person = match ? { name: match[1].trim(), email: match[2].trim() } : { name: "", email: text };
  if (person.name === person.email) person.name = "";
  return person;
}

function parseIcsLine(line) {
  var index = 0;
  var quoted = false;
  for (; index < line.length; index++) {
    var character = line.charAt(index);
    if (character === "\"") quoted = !quoted;
    else if (character === ":" && !quoted) break;
  }
  var head = line.substr(0, index);
  var value = line.substr(index + 1);
  var parts = [];
  var part = "";
  quoted = false;
  for (var i = 0; i < head.length; i++) {
    var current = head.charAt(i);
    if (current === "\"") quoted = !quoted;
    if (current === ";" && !quoted) {
      parts.push(part);
      part = "";
    } else part += current;
  }
  parts.push(part);
  var params = {};
  for (var p = 1; p < parts.length; p++) {
    var eq = parts[p].indexOf("=");
    if (eq > 0) params[parts[p].substr(0, eq).toUpperCase()] = parts[p].substr(eq + 1).replace(/^"|"$/g, "");
  }
  return { name: String(parts[0] || "").toUpperCase(), params: params, value: value };
}

function unfoldIcs(text) {
  return String(text || "").replace(/\r\n?/g, "\n").replace(/\n[ \t]/g, "").split("\n");
}

function unescapeIcsValue(value) {
  return String(value || "").replace(/\\([\\;,nN])/g, function(_, escaped) {
    if (escaped === "n" || escaped === "N") return "\n";
    return escaped;
  });
}

function parseIcsDetails(text, uid) {
  var lines = unfoldIcs(text);
  var best = null;
  var current = null;
  var depth = 0;
  var target = String(uid || "");
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i];
    if (/^BEGIN:VEVENT$/i.test(line)) {
      current = { props: [], uid: "", override: false };
      depth = 1;
      continue;
    }
    if (!current) continue;
    if (/^BEGIN:/i.test(line)) { depth++; continue; }
    if (/^END:/i.test(line)) {
      depth--;
      if (depth === 0) {
        if (current.uid === target && (!best || (best.override && !current.override))) best = current;
        current = null;
      }
      continue;
    }
    if (depth !== 1) continue;
    var property = parseIcsLine(line);
    if (property.name === "UID") current.uid = property.value.trim();
    if (property.name === "RECURRENCE-ID") current.override = true;
    current.props.push(property);
  }
  if (!best) return null;

  var result = { conference: "", url: "", description: "", organizer: null, attendees: [] };
  for (var propertyIndex = 0; propertyIndex < best.props.length; propertyIndex++) {
    var item = best.props[propertyIndex];
    if (item.name === "X-GOOGLE-CONFERENCE" || item.name === "X-MICROSOFT-SKYPETEAMSMEETINGURL") {
      if (!result.conference) result.conference = unescapeIcsValue(item.value).trim();
    } else if (item.name === "URL") result.url = unescapeIcsValue(item.value).trim();
    else if (item.name === "DESCRIPTION") result.description = cleanDescription(unescapeIcsValue(item.value));
    else if (item.name === "ORGANIZER") {
      result.organizer = {
        name: item.params.CN || "",
        email: String(item.value || "").replace(/^mailto:/i, "").trim()
      };
    } else if (item.name === "ATTENDEE") {
      if (String(item.params.CUTYPE || "INDIVIDUAL").toUpperCase() !== "INDIVIDUAL") continue;
      result.attendees.push({
        name: item.params.CN || "",
        email: String(item.value || "").replace(/^mailto:/i, "").trim(),
        status: String(item.params.PARTSTAT || "NEEDS-ACTION").toUpperCase(),
        organizer: false
      });
    }
  }
  if (result.organizer) {
    for (var attendeeIndex = 0; attendeeIndex < result.attendees.length; attendeeIndex++) {
      if (result.attendees[attendeeIndex].email.toLowerCase() === result.organizer.email.toLowerCase())
        result.attendees[attendeeIndex].organizer = true;
    }
  }
  if (!isOpenableUrl(result.conference)) result.conference = "";
  if (!isOpenableUrl(result.url)) result.url = "";
  return result;
}

function isPlaceholderOrganizer(person) {
  return !person || /^unknownorganizer@|@group\.calendar\.google\.com$|@group\.v\.calendar\.google\.com$|@virtual$/i.test(String(person.email || ""));
}

function personLabel(person) {
  if (!person) return "";
  return person.name && person.name !== person.email ? person.name : person.email;
}

function directionsUrl(location, provider) {
  var place = String(location || "").trim();
  if (!place) return "";
  var urls = extractUrls(place);
  if (urls.length > 0 && place === urls[0] && isOpenableUrl(urls[0])) return urls[0];
  var prefix = "https://www.google.com/maps/search/?api=1&query=";
  if (provider === "OpenStreetMap") prefix = "https://www.openstreetmap.org/search?query=";
  else if (provider === "Apple Maps") prefix = "https://maps.apple.com/?q=";
  return prefix + encodeURIComponent(place);
}

function eventDetails(event, ics, mapsProvider) {
  var ev = event || {};
  var details = ics || null;
  var description = ev.description || (details ? details.description : "");
  var candidates = [];
  function add(url) {
    var value = trimUrl(String(url || "").trim());
    if (isOpenableUrl(value) && candidates.indexOf(value) === -1) candidates.push(value);
  }
  if (details && details.conference) add(details.conference);
  add(ev.url);
  if (details) add(details.url);
  var locationUrls = extractUrls(ev.location);
  for (var locationIndex = 0; locationIndex < locationUrls.length; locationIndex++) add(locationUrls[locationIndex]);
  var descriptionUrls = extractUrls(description);
  for (var descriptionIndex = 0; descriptionIndex < descriptionUrls.length; descriptionIndex++) add(descriptionUrls[descriptionIndex]);

  var meeting = null;
  var links = [];
  for (var candidateIndex = 0; candidateIndex < candidates.length; candidateIndex++) {
    var service = meetingService(candidates[candidateIndex]);
    if (service && !meeting) meeting = { label: service, url: candidates[candidateIndex] };
    else links.push({ label: linkLabel(candidates[candidateIndex]), url: candidates[candidateIndex] });
  }
  var locationIsLink = locationUrls.length > 0 && String(ev.location || "").trim() === locationUrls[0];
  var location = locationIsLink ? "" : String(ev.location || "");
  var organizer = details && details.organizer ? details.organizer : ev.organizer;
  if (isPlaceholderOrganizer(organizer)) organizer = null;
  return {
    meeting: meeting,
    links: links,
    location: location,
    directions: locationIsLink ? "" : directionsUrl(location, mapsProvider),
    description: description,
    organizer: organizer || null,
    attendees: details ? details.attendees || [] : [],
    repeating: !!ev.repeating,
    status: String(ev.status || "")
  };
}

function linkLabel(url) {
  var match = String(url || "").match(/^([a-z]+):\/\/(?:www\.)?([^\/?#]+)/i);
  if (!match) return String(url || "");
  return /^https?$/i.test(match[1]) ? match[2] : match[1].toLowerCase() + "://" + match[2];
}

function enrichEvent(event, ics, use24h) {
  var ev = {};
  var source = event || {};
  for (var key in source) if (Object.prototype.hasOwnProperty.call(source, key)) ev[key] = source[key];
  var details = eventDetails(ev, ics, "Google Maps");
  var candidate = details.meeting;
  var use24 = use24h !== false;
  ev.timeRange = timeRange(ev, use24);
  ev.meetingUrl = candidate ? candidate.url : "";
  ev.serviceName = candidate ? candidate.label : "";
  ev.directionsUrl = details.directions;
  ev.details = details;
  return ev;
}

function timeRange(event, use24h) {
  var ev = event || {};
  if (ev.allDay) return "All day";
  if (ev.end <= ev.start) return formatClock(ev.start, use24h);
  return formatClock(ev.start, use24h) + " – " + formatClock(ev.end, use24h);
}

function formatClock(milliseconds, use24h) {
  var date = new Date(Number(milliseconds));
  if (isNaN(date.getTime())) return "";
  if (use24h !== false) return pad2(date.getHours()) + ":" + pad2(date.getMinutes());
  var hour = date.getHours() % 12 || 12;
  return hour + ":" + pad2(date.getMinutes()) + (date.getHours() < 12 ? " AM" : " PM");
}

function formatUntil(milliseconds, now) {
  var minutes = Math.ceil((Number(milliseconds) - Number(now)) / 60000);
  if (minutes <= 0) return "now";
  if (minutes < 60) return "in " + minutes + "m";
  var hours = Math.floor(minutes / 60);
  var remainder = minutes % 60;
  return "in " + hours + "h" + (remainder ? " " + remainder + "m" : "");
}

function notificationTitle(event) {
  var title = String(event && event.title || "Event").replace(/[\r\n]+/g, " ").trim();
  return /^-/.test(title) ? "Event: " + title : title;
}

function escapeHtml(text) {
  return String(text).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}

function notificationBody(event, now, use24h) {
  var ev = event || {};
  var body = "Starts at " + formatClock(ev.start, use24h) + " (" + formatUntil(ev.start, now) + ")";
  if (ev.location) body += "\n" + escapeHtml(ev.location);
  return body;
}

function dueNotifications(events, now, leadMinutes, notified) {
  var horizon = Number(now) + Math.max(0, Number(leadMinutes) || 0) * 60000;
  var due = [];
  var already = notified || {};
  for (var i = 0; i < (events || []).length; i++) {
    var event = events[i];
    if (event.allDay || String(event.status || "").toUpperCase() === "CANCELLED") continue;
    if (event.start < Number(now) - 120000 || event.start > horizon) continue;
    if (Object.prototype.hasOwnProperty.call(already, event.key)) continue;
    due.push(event);
  }
  return due;
}

function pruneNotified(notified, now) {
  var next = {};
  var source = notified || {};
  for (var key in source) {
    if (Object.prototype.hasOwnProperty.call(source, key) && Number(source[key]) >= Number(now) - DAY_MS)
      next[key] = Number(source[key]);
  }
  return next;
}

function localDayStart(date) {
  var input = date instanceof Date ? new Date(date.getTime()) : new Date(date);
  if (isNaN(input.getTime())) return 0;
  input.setHours(0, 0, 0, 0);
  return input.getTime();
}

function isSameDay(left, right) {
  var a = left instanceof Date ? left : new Date(left);
  var b = right instanceof Date ? right : new Date(right);
  return !isNaN(a.getTime()) && !isNaN(b.getTime())
    && a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
}

function dayHeading(milliseconds, now) {
  var date = new Date(milliseconds);
  var current = new Date(now === undefined ? Date.now() : now);
  var label = WEEKDAY_FULL[date.getDay()] + ", " + MONTH_SHORT[date.getMonth()] + " " + date.getDate();
  if (isSameDay(date, current)) return "Today · " + label;
  var tomorrow = new Date(current.getFullYear(), current.getMonth(), current.getDate() + 1);
  if (isSameDay(date, tomorrow)) return "Tomorrow · " + label;
  return label;
}

function agendaRows(events, now) {
  var rows = [];
  var lastDay = "";
  var current = Number(now);
  for (var i = 0; i < (events || []).length; i++) {
    var event = events[i];
    if (event.end <= current) continue;
    var anchor = Math.max(event.start, localDayStart(current));
    var key = dateKey(anchor);
    if (key !== lastDay) {
      rows.push({ kind: "day", label: dayHeading(anchor, current) });
      lastDay = key;
    }
    rows.push({ kind: "event", event: event });
  }
  return rows;
}

function dayAgendaRows(events, dayMilliseconds, now) {
  var from = localDayStart(dayMilliseconds);
  var day = new Date(from);
  var to = new Date(day.getFullYear(), day.getMonth(), day.getDate() + 1).getTime();
  var rows = [{ kind: "day", label: dayHeading(from, now === undefined ? Date.now() : now) }];
  for (var i = 0; i < (events || []).length; i++) {
    var event = events[i];
    if (event.start < to && Math.max(event.end, event.start + 1) > from)
      rows.push({ kind: "event", event: event });
  }
  return rows;
}

// Calendar-colored dots keyed by YYYY-MM-DD, with at most three distinct calendars per day.
function eventsByDay(events) {
  var out = {};
  for (var i = 0; i < (events || []).length; i++) {
    var event = events[i];
    if (!event || !isFinite(Number(event.start))) continue;
    var first = new Date(event.start);
    var lastInstant = Number(event.end) > Number(event.start) ? Number(event.end) - 1 : Number(event.start);
    var last = new Date(lastInstant);
    var firstUtc = Date.UTC(first.getFullYear(), first.getMonth(), first.getDate());
    var lastUtc = Date.UTC(last.getFullYear(), last.getMonth(), last.getDate());
    var count = Math.floor((lastUtc - firstUtc) / DAY_MS);
    if (count < 0) count = 0;
    if (count > 61) count = 61;
    for (var day = 0; day <= count; day++) {
      var civil = new Date(firstUtc + day * DAY_MS);
      var key = civil.getUTCFullYear() + "-" + pad2(civil.getUTCMonth() + 1) + "-" + pad2(civil.getUTCDate());
      var dots = out[key] || (out[key] = []);
      var color = qmlColor(event.color);
      var calendar = String(event.calendar || "");
      var dotKey = calendar || color || String(event.key || event.title || "event-" + i);
      var seenCalendar = false;
      for (var dotIndex = 0; dotIndex < dots.length; dotIndex++) {
        if (dots[dotIndex].key === dotKey) { seenCalendar = true; break; }
      }
      if (!seenCalendar && dots.length < 3) dots.push({ key: dotKey, calendar: calendar, color: color });
    }
  }
  return out;
}

function eventsForDate(events, date) {
  var start = localDayStart(date);
  var day = new Date(start);
  var end = new Date(day.getFullYear(), day.getMonth(), day.getDate() + 1).getTime();
  var out = [];
  for (var i = 0; i < (events || []).length; i++) {
    var event = events[i];
    if (event.start < end && Math.max(event.end, event.start + 1) > start) out.push(event);
  }
  return out;
}

function monthKey(year, month) {
  return String(Number(year)) + "-" + pad2(Number(month) + 1);
}

// Only the UID is supplied as argv; it is never interpolated into shell source.
var ICS_LOOKUP_SCRIPT = [
  "set -u",
  "uid=\"${1-}\"",
  "[ -n \"$uid\" ] && [ ${#uid} -le 512 ] || exit 2",
  "case \"$uid\" in *$'\\n'*|*$'\\r'*) exit 2 ;; esac",
  "cfg=\"${XDG_CONFIG_HOME:-$HOME/.config}/khal/config\"",
  "[ -f \"$cfg\" ] || cfg=\"$HOME/.khal/khal.conf\"",
  "[ -r \"$cfg\" ] || exit 3",
  "while IFS= read -r raw; do",
  "  raw=\"${raw%%#*}\"",
  "  raw=\"${raw#\"${raw%%[![:space:]]*}\"}\"",
  "  raw=\"${raw%\"${raw##*[![:space:]]}\"}\"",
  "  raw=\"${raw%\\\"}\"; raw=\"${raw#\\\"}\"",
  "  raw=\"${raw%\\'}\"; raw=\"${raw#\\'}\"",
  "  case \"$raw\" in ~/*) raw=\"$HOME/${raw#~/}\" ;; esac",
  "  [ -d \"$raw\" ] && [ ! -L \"$raw\" ] || continue",
  "  while IFS= read -r -d '' file; do",
  "    [ -f \"$file\" ] && [ ! -L \"$file\" ] || continue",
  "    size=$(stat -c %s -- \"$file\" 2>/dev/null) || continue",
  "    [ \"$size\" -le 262144 ] || continue",
  "    if grep -F -q -- \"UID:$uid\" \"$file\" 2>/dev/null; then cat -- \"$file\"; exit 0; fi",
  "  done < <(find \"$raw\" -type f -name '*.ics' -print0 2>/dev/null)",
  "done < <(sed -n 's/^[[:space:]]*path[[:space:]]*=[[:space:]]*//p' \"$cfg\")",
  "exit 0"
].join("\n");

if (typeof module !== "undefined") {
  module.exports = {
    DAY_MS: DAY_MS,
    SAMPLE_ERROR: SAMPLE_ERROR,
    parsePrintFormats: parsePrintFormats,
    parseFormats: parseFormats,
    compileSample: compileSample,
    parseDate: parseDate,
    parseTime: parseTime,
    formatKhalDate: formatKhalDate,
    dateKey: dateKey,
    khalArgs: khalArgs,
    JSON_FIELDS: JSON_FIELDS,
    khalListArgs: khalListArgs,
    monthRange: monthRange,
    khalRangeArgs: khalRangeArgs,
    safeCommandArgs: safeCommandArgs,
    parseEvents: parseEvents,
    normalizeEvent: normalizeEvent,
    qmlColor: qmlColor,
    cleanDescription: cleanDescription,
    extractUrls: extractUrls,
    meetingService: meetingService,
    isOpenableUrl: isOpenableUrl,
    parseOrganizer: parseOrganizer,
    parseIcsDetails: parseIcsDetails,
    eventDetails: eventDetails,
    enrichEvent: enrichEvent,
    directionsUrl: directionsUrl,
    formatClock: formatClock,
    formatUntil: formatUntil,
    notificationTitle: notificationTitle,
    notificationBody: notificationBody,
    dueNotifications: dueNotifications,
    pruneNotified: pruneNotified,
    localDayStart: localDayStart,
    isSameDay: isSameDay,
    dayHeading: dayHeading,
    agendaRows: agendaRows,
    dayAgendaRows: dayAgendaRows,
    eventsByDay: eventsByDay,
    eventsForDate: eventsForDate,
    monthKey: monthKey,
    linkLabel: linkLabel,
    ICS_LOOKUP_SCRIPT: ICS_LOOKUP_SCRIPT
  };
}

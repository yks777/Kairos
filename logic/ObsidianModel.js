.pragma library

var DEFAULT_DAILY_NOTES_FOLDER = "Daily Notes";
var MAX_TEMPLATE_LENGTH = 262144;

function pad2(value) { return Number(value) < 10 ? "0" + Number(value) : String(value); }

function dateKey(date) {
  var input = date instanceof Date ? date : new Date(date);
  if (isNaN(input.getTime())) return "";
  return input.getFullYear() + "-" + pad2(input.getMonth() + 1) + "-" + pad2(input.getDate());
}

function formatDateTime(date) {
  var input = date instanceof Date ? date : new Date(date);
  if (isNaN(input.getTime())) return "";
  return dateKey(input) + " " + pad2(input.getHours()) + ":" + pad2(input.getMinutes());
}

function cleanAbsolutePath(value) {
  var path = String(value || "").trim();
  if (path === "" || path.indexOf("\u0000") !== -1 || path.charAt(0) !== "/") return "";
  var parts = path.split("/");
  var clean = [];
  for (var i = 0; i < parts.length; i++) {
    var part = parts[i];
    if (part === "" || part === ".") continue;
    if (part === "..") return "";
    clean.push(part);
  }
  return "/" + clean.join("/");
}

function cleanRelativeFolder(value) {
  var folder = String(value === undefined || value === null ? DEFAULT_DAILY_NOTES_FOLDER : value).trim();
  if (folder.indexOf("\u0000") !== -1 || folder.indexOf("\\") !== -1) return null;
  while (folder.charAt(0) === "/") folder = folder.slice(1);
  while (folder.charAt(folder.length - 1) === "/") folder = folder.slice(0, -1);
  if (folder === "") return "";
  var parts = folder.split("/");
  var clean = [];
  for (var i = 0; i < parts.length; i++) {
    if (parts[i] === "" || parts[i] === ".") continue;
    if (parts[i] === "..") return null;
    clean.push(parts[i]);
  }
  return clean.join("/");
}

function resolveDailyNotePath(settings, date) {
  var config = settings || {};
  var vault = cleanAbsolutePath(config.vaultPath);
  var folder = cleanRelativeFolder(config.dailyNotesFolder);
  var input = date instanceof Date ? date : new Date(date);
  if (!vault || folder === null || isNaN(input.getTime())) return "";
  var relative = folder ? folder + "/" : "";
  relative += String(input.getFullYear()) + "/" + pad2(input.getMonth() + 1) + "/" + dateKey(input) + ".md";
  return (vault === "/" ? "" : vault) + "/" + relative;
}

function relativeDailyNotePath(settings, date) {
  var config = settings || {};
  var folder = cleanRelativeFolder(config.dailyNotesFolder);
  var input = date instanceof Date ? date : new Date(date);
  if (folder === null || isNaN(input.getTime())) return "";
  return (folder ? folder + "/" : "") + String(input.getFullYear()) + "/" + pad2(input.getMonth() + 1)
    + "/" + dateKey(input) + ".md";
}

function parentPath(path) {
  var value = cleanAbsolutePath(path);
  if (!value || value === "/") return "";
  var slash = value.lastIndexOf("/");
  return slash <= 0 ? "/" : value.slice(0, slash);
}

function vaultName(vaultPath, configuredName) {
  var explicit = String(configuredName || "").trim();
  if (explicit) return explicit;
  var path = cleanAbsolutePath(vaultPath);
  if (!path || path === "/") return "";
  return path.slice(path.lastIndexOf("/") + 1);
}

function safeRelativePath(path) {
  var value = String(path || "").trim();
  if (!value || value.charAt(0) === "/" || value.indexOf("\\") !== -1 || value.indexOf("\u0000") !== -1) return false;
  var parts = value.split("/");
  for (var i = 0; i < parts.length; i++) if (parts[i] === "..") return false;
  return true;
}

function obsidianUri(vault, relativePath) {
  var vaultValue = String(vault || "").trim();
  var pathValue = String(relativePath || "").trim();
  if (!vaultValue || !safeRelativePath(pathValue)) return "";
  return "obsidian://open?vault=" + encodeURIComponent(vaultValue) + "&file=" + encodeURIComponent(pathValue);
}

function renderTemplate(dateTime) {
  var timestamp = String(dateTime || "").trim();
  return "---\ndata e hora: " + timestamp + "\ntags:\n  - Diario\n---\n-\n";
}

function renderConfiguredTemplate(source, dateTime) {
  var template = String(source || "").replace(/\r\n?/g, "\n");
  if (template === "" || template.length > MAX_TEMPLATE_LENGTH || /<%[\s\S]*?%>/.test(template))
    return renderTemplate(dateTime);
  var timestamp = String(dateTime || "").trim();
  var linePattern = /^([ \t]*data e hora[ \t]*:[ \t]*).*$/m;
  if (!linePattern.test(template)) return renderTemplate(timestamp);
  return template.replace(linePattern, "$1" + timestamp);
}

function taskFromLine(line, lineIndex) {
  var match = String(line || "").match(/^(\s*)-\s+\[([ xX])\]\s+(.*?)\s*$/);
  if (!match || !match[3]) return null;
  return {
    lineIndex: lineIndex,
    indent: match[1].length,
    checked: match[2].toLowerCase() === "x",
    text: match[3]
  };
}

function parseTasks(content) {
  var lines = String(content || "").replace(/\r\n?/g, "\n").split("\n");
  var tasks = [];
  var inFence = false;
  var fenceMarker = "";
  for (var i = 0; i < lines.length; i++) {
    var fence = lines[i].match(/^\s*(```+|~~~+)/);
    if (fence) {
      var marker = fence[1].substr(0, 3);
      if (!inFence) { inFence = true; fenceMarker = marker; }
      else if (marker === fenceMarker) { inFence = false; fenceMarker = ""; }
      continue;
    }
    if (inFence) continue;
    var task = taskFromLine(lines[i], i);
    if (task) tasks.push(task);
  }
  return tasks;
}

function toggleTask(content, lineIndex) {
  var source = String(content || "").replace(/\r\n?/g, "\n");
  var lines = source.split("\n");
  var index = Math.floor(Number(lineIndex));
  if (index < 0 || index >= lines.length) return source;
  var match = lines[index].match(/^(\s*-\s+\[)([ xX])(\]\s+.*)$/);
  if (!match) return source;
  var checked = match[2].toLowerCase() === "x";
  lines[index] = match[1] + (checked ? " " : "x") + match[3];
  return lines.join("\n");
}

function lineIsFence(line) { return /^\s*(```+|~~~+)/.test(String(line || "")); }

function addTask(content, taskText) {
  var source = String(content || "").replace(/\r\n?/g, "\n");
  var text = String(taskText === undefined || taskText === null ? "" : taskText)
    .replace(/[\r\n]+/g, " ").replace(/[\u0000-\u001f\u007f]/g, " ").trim().slice(0, 500);
  if (!text) return source;
  var lines = source.split("\n");
  var sections = [];
  var start = 0;
  for (var i = 0; i < lines.length; i++) {
    if (/^\s*#{1,6}\s+/.test(lines[i])) {
      sections.push({ start: start, end: i });
      start = i + 1;
    }
  }
  sections.push({ start: start, end: lines.length });

  var insertion = -1;
  for (var sectionIndex = 0; sectionIndex < sections.length; sectionIndex++) {
    var section = sections[sectionIndex];
    var inFence = false;
    var fenceMarker = "";
    var lastTask = -1;
    for (var lineIndex = section.start; lineIndex < section.end; lineIndex++) {
      var fence = lines[lineIndex].match(/^\s*(```+|~~~+)/);
      if (fence) {
        var marker = fence[1].substr(0, 3);
        if (!inFence) { inFence = true; fenceMarker = marker; }
        else if (marker === fenceMarker) { inFence = false; fenceMarker = ""; }
        continue;
      }
      if (!inFence && taskFromLine(lines[lineIndex], lineIndex)) lastTask = lineIndex;
    }
    if (lastTask >= 0) {
      insertion = lastTask + 1;
      break;
    }
  }
  if (insertion < 0) {
    insertion = lines.length;
    if (lines.length && lines[lines.length - 1] === "") insertion = lines.length - 1;
  }
  lines.splice(insertion, 0, "- [ ] " + text);
  return lines.join("\n");
}

if (typeof module !== "undefined") {
  module.exports = {
    DEFAULT_DAILY_NOTES_FOLDER: DEFAULT_DAILY_NOTES_FOLDER,
    dateKey: dateKey,
    formatDateTime: formatDateTime,
    cleanAbsolutePath: cleanAbsolutePath,
    cleanRelativeFolder: cleanRelativeFolder,
    resolveDailyNotePath: resolveDailyNotePath,
    relativeDailyNotePath: relativeDailyNotePath,
    parentPath: parentPath,
    vaultName: vaultName,
    safeRelativePath: safeRelativePath,
    obsidianUri: obsidianUri,
    renderTemplate: renderTemplate,
    renderConfiguredTemplate: renderConfiguredTemplate,
    parseTasks: parseTasks,
    toggleTask: toggleTask,
    addTask: addTask
  };
}

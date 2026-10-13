.pragma library

function cleanAbsolutePath(value) {
  var path = String(value || "").trim();
  if (path === "" || path.indexOf("\u0000") !== -1 || path.charAt(0) !== "/") return "";
  while (path.length > 1 && path.charAt(path.length - 1) === "/")
    path = path.slice(0, -1);
  return path;
}

function dataDir(env) {
  var xdg = "";
  var home = "";
  try {
    if (typeof env === "function") {
      xdg = cleanAbsolutePath(env("XDG_DATA_HOME"));
      home = cleanAbsolutePath(env("HOME"));
    }
  } catch (e) {
    xdg = "";
    home = "";
  }

  if (xdg !== "") return (xdg === "/" ? "" : xdg) + "/kairos";
  if (home !== "") return (home === "/" ? "" : home) + "/.local/share/kairos";
  return "/.local/share/kairos";
}

function statePath(env) {
  return dataDir(env) + "/state.json";
}

function calendarCacheDir(env) {
  var home = "";
  var xdg = "";
  try {
    if (typeof env === "function") {
      home = cleanAbsolutePath(env("HOME"));
      xdg = cleanAbsolutePath(env("XDG_CACHE_HOME"));
    }
  } catch (e) {
    home = "";
    xdg = "";
  }
  var base = xdg || (home ? (home === "/" ? "" : home) + "/.cache" : "/.cache");
  return base + "/omarchy/kairos/calendar";
}

function calendarNotificationsPath(env) {
  var home = "";
  var xdg = "";
  try {
    if (typeof env === "function") {
      home = cleanAbsolutePath(env("HOME"));
      xdg = cleanAbsolutePath(env("XDG_STATE_HOME"));
    }
  } catch (e) {
    home = "";
    xdg = "";
  }
  var base = xdg || (home ? (home === "/" ? "" : home) + "/.local/state" : "/.local/state");
  return base + "/omarchy/kairos/notified.json";
}

if (typeof module !== "undefined") {
  module.exports = {
    cleanAbsolutePath: cleanAbsolutePath,
    dataDir: dataDir,
    statePath: statePath,
    calendarCacheDir: calendarCacheDir,
    calendarNotificationsPath: calendarNotificationsPath
  };
}

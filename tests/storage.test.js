const test = require("node:test");
const assert = require("node:assert/strict");
const { loadQmlLibrary } = require("./helpers/loadQmlLibrary.js");
const Storage = loadQmlLibrary("logic/Storage.js");

test("storage paths prefer an absolute XDG data directory", () => {
  const env = (name) => ({ XDG_DATA_HOME: "/home/test/.data/", HOME: "/home/test" })[name] || "";
  assert.equal(Storage.dataDir(env), "/home/test/.data/kairos");
  assert.equal(Storage.statePath(env), "/home/test/.data/kairos/state.json");
});

test("storage paths fall back to HOME for missing or relative XDG values", () => {
  const env = (name) => ({ XDG_DATA_HOME: "relative/data", HOME: "/home/test/" })[name] || "";
  assert.equal(Storage.dataDir(env), "/home/test/.local/share/kairos");
});

test("storage path input rejects non-absolute and NUL-containing values", () => {
  assert.equal(Storage.cleanAbsolutePath("relative/path"), "");
  assert.equal(Storage.cleanAbsolutePath("/home/test\u0000/escape"), "");
  assert.equal(Storage.cleanAbsolutePath("/home/test///"), "/home/test");
});

test("calendar cache and notification paths honor XDG locations", () => {
  const env = (name) => ({
    HOME: "/home/tester",
    XDG_CACHE_HOME: "/mnt/cache",
    XDG_STATE_HOME: "/mnt/state"
  })[name] || "";
  assert.equal(Storage.calendarCacheDir(env), "/mnt/cache/omarchy/kairos/calendar");
  assert.equal(Storage.calendarNotificationsPath(env), "/mnt/state/omarchy/kairos/notified.json");
  const fallback = (name) => name === "HOME" ? "/home/tester" : "";
  assert.equal(Storage.calendarCacheDir(fallback), "/home/tester/.cache/omarchy/kairos/calendar");
  assert.equal(Storage.calendarNotificationsPath(fallback), "/home/tester/.local/state/omarchy/kairos/notified.json");
});

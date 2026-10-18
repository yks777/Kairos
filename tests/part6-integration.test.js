const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const root = path.resolve(__dirname, "..");
const read = (name) => fs.readFileSync(path.join(root, name), "utf8");

test("the panel hosts the main views and is loaded standalone by the shell", () => {
  const panel = read("Panel.qml");
  const widget = read("BarWidget.qml");
  assert.match(panel, /DayView\s*\{/);
  assert.match(panel, /FocusView\s*\{/);
  assert.match(panel, /MatrixView\s*\{/);
  assert.match(panel, /StatsView\s*\{/);
  assert.match(panel, /MarketsView\s*\{/);
  assert.match(panel, /SettingsView\s*\{/);
  assert.match(panel, /root\.currentView\s*===\s*"settings"/);
  // Panel.qml is loaded standalone by the shell panel-loader, not via BarWidget Loader.
  assert.equal(/\bLoader\s*\{/.test(widget), false);
  assert.match(panel, /barShim/);
  assert.match(panel, /KeyboardPanel\s*\{/);
});

test("Settings contains the expected sections and service integrations", () => {
  const settings = read("views/SettingsView.qml");
  const expected = ["Focus", "Flowtime", "Calendar", "Obsidian", "Markets", "Bar", "Stats", "Shortcuts", "Notifications", "Data"];
  for (const section of expected) assert.match(settings, new RegExp(`title: "${section}"`));

  const service = read("Service.qml");
  assert.match(service, /CalendarService\s*\{/);
  assert.match(service, /ObsidianService\s*\{/);
  assert.match(service, /MarketsService\s*\{/);
  assert.match(service, /ConverterService\s*\{/);
  for (const method of ["updateSettings", "resetAll"])
    assert.match(service, new RegExp(`function ${method}\\s*\\(`));
});

test("the notification sound setting gates the local system-theme sound helper", () => {
  const service = read("Service.qml");
  const helper = read("scripts/notification-sound");
  assert.match(service, /function notify\(category, title, body\)[\s\S]*?settings\.notifications\.sound === false/);
  assert.match(service, /Quickshell\.execDetached\(\["python3", root\.notificationSoundScript\]\)/);
  assert.match(helper, /\("pw-play", "paplay"\)/);
  assert.match(helper, /canberra-gtk-play/);
  assert.match(helper, /subprocess\.Popen\(/);
});

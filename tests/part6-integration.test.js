const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const root = path.resolve(__dirname, "..");
const read = (name) => fs.readFileSync(path.join(root, name), "utf8");

test("the panel hosts the Social and Settings views and is loaded standalone by the shell", () => {
  const panel = read("Panel.qml");
  const widget = read("BarWidget.qml");
  assert.match(panel, /SocialView\s*\{/);
  assert.match(panel, /SettingsView\s*\{/);
  assert.match(panel, /root\.currentView\s*===\s*"social"/);
  assert.match(panel, /root\.currentView\s*===\s*"settings"/);
  // Panel.qml is loaded standalone by the shell panel-loader, not via BarWidget Loader.
  assert.equal(/\bLoader\s*\{/.test(widget), false);
  assert.match(panel, /barShim/);
  assert.match(panel, /KeyboardPanel\s*\{/);
});

test("Settings contains the requested twelve sections and service integrations", () => {
  const settings = read("views/SettingsView.qml");
  const expected = ["Focus", "Flowtime", "Calendar", "Obsidian", "Markets", "Social", "Email", "Bar", "Stats", "Shortcuts", "Notifications", "Data"];
  for (const section of expected) assert.match(settings, new RegExp(`title: "${section}"`));
  assert.equal((settings.match(/title:\s*"(?:Focus|Flowtime|Calendar|Obsidian|Markets|Social|Email|Bar|Stats|Shortcuts|Notifications|Data)"/g) || []).length, 12);

  const service = read("Service.qml");
  assert.match(service, /SocialService\s*\{/);
  assert.match(service, /EmailService\s*\{/);
  for (const connector of ["Telegram", "WhatsApp", "Signal", "Discord", "Matrix", "Email"])
    assert.match(service, new RegExp(`${connector}Connector\\s*\\{`));
  for (const method of ["updateSettings", "socialUnread", "socialRecentCalls", "socialThread", "emailAddAccount", "emailUpdateAccount", "emailRemoveAccount", "emailSend", "resetAll"])
    assert.match(service, new RegExp(`function ${method}\\s*\\(`));
  assert.match(service, /function refreshSocial\(\)/);
  assert.match(service, /function refreshEmail\(\)/);
});

test("email availability reflects authenticated, live accounts and resets on failure or watcher restart", () => {
  const email = read("services/EmailService.qml");
  assert.match(email, /property var connectedAccounts: \(\{\}\)/);
  assert.match(email, /readonly property bool available:\s*\{[\s\S]*?watcherProc\.running/);
  assert.match(email, /root\.connectedAccounts\[root\.accounts\[i\]\.id\]\s*===\s*true/);
  assert.match(email, /function setConnected\(accountId, connected\)[\s\S]*?root\.connectedAccounts = next/);
  assert.match(email, /if \(data\.ok !== true\) \{[\s\S]*?root\.setConnected\(account\.id, false\)/);
  assert.match(email, /root\.setConnected\(account\.id, true\);/);
  assert.match(email, /function startWatcher\(\) \{[\s\S]*?root\.connectedAccounts = \(\{\}\)/);
  assert.match(email, /function clearAccount\(accountId\)[\s\S]*?delete connected\[id\]/);
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

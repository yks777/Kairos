const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const projectRoot = path.resolve(__dirname, "..");
const manifest = JSON.parse(fs.readFileSync(path.join(projectRoot, "manifest.json"), "utf8"));

test("manifest declares service, bar-widget, and panel kinds with correct entry points", () => {
  assert.deepEqual(manifest.kinds, ["service", "bar-widget", "panel"]);
  assert.equal(manifest.keepLoaded, true);
  assert.equal(manifest.entryPoints.service, "Service.qml");
  assert.equal(manifest.entryPoints.barWidget, "BarWidget.qml");
  assert.equal(manifest.entryPoints.panel, "Panel.qml");
  for (const entryPoint of Object.values(manifest.entryPoints)) {
    assert.equal(path.isAbsolute(entryPoint), false);
    assert.equal(fs.existsSync(path.join(projectRoot, entryPoint)), true);
  }
});

test("plugin tree contains no symlinks and Panel.qml is a standalone panel entry", () => {
  const pending = [projectRoot];
  while (pending.length > 0) {
    const directory = pending.pop();
    for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
      const entryPath = path.join(directory, entry.name);
      assert.equal(entry.isSymbolicLink(), false, `${entryPath} must not be a symlink`);
      if (entry.isDirectory()) pending.push(entryPath);
    }
  }
  // Panel.qml is loaded standalone by the shell panel-loader, not via a BarWidget Loader.
  assert.equal(fs.existsSync(path.join(projectRoot, "Panel.qml")), true);
  const barWidget = fs.readFileSync(path.join(projectRoot, "BarWidget.qml"), "utf8");
  assert.equal(/\bLoader\s*\{/.test(barWidget), false);
  const panel = fs.readFileSync(path.join(projectRoot, "Panel.qml"), "utf8");
  assert.match(panel, /^import QtQuick/);
  assert.match(panel, /Panel\s*\{/);
});

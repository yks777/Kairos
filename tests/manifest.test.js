const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const projectRoot = path.resolve(__dirname, "..");
const manifest = JSON.parse(fs.readFileSync(path.join(projectRoot, "manifest.json"), "utf8"));

test("manifest declares service and bar-widget kinds with correct entry points", () => {
  assert.deepEqual(manifest.kinds, ["service", "bar-widget"]);
  assert.equal(manifest.keepLoaded, true);
  assert.equal(manifest.entryPoints.service, "Service.qml");
  assert.equal(manifest.entryPoints.barWidget, "BarWidget.qml");
  // panel is loaded internally by BarWidget.qml, not declared as a separate kind
  assert.equal(manifest.entryPoints.panel, undefined);
  for (const entryPoint of Object.values(manifest.entryPoints)) {
    assert.equal(path.isAbsolute(entryPoint), false);
    assert.equal(fs.existsSync(path.join(projectRoot, entryPoint)), true);
  }
});

test("plugin tree contains no symlinks and BarWidget loads Panel.qml via Loader", () => {
  const pending = [projectRoot];
  while (pending.length > 0) {
    const directory = pending.pop();
    for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
      const entryPath = path.join(directory, entry.name);
      assert.equal(entry.isSymbolicLink(), false, `${entryPath} must not be a symlink`);
      if (entry.isDirectory()) pending.push(entryPath);
    }
  }
  const barWidget = fs.readFileSync(path.join(projectRoot, "BarWidget.qml"), "utf8");
  // BarWidget should load Panel.qml internally via Loader (per Omarchy documentation)
  assert.equal(/\bLoader\s*\{/.test(barWidget), true);
  assert.equal(/source:\s*Qt\.resolvedUrl\(["']Panel\.qml["']\)/.test(barWidget), true);
});

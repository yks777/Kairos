# Kairos Panel Not Opening — Fix Plan

## Root Cause

The Kairos plugin uses the **nested-panel pattern**: `BarWidget.qml` loads `Panel.qml`
via an internal `Loader` (with `visible: false`), and `manifest.json` is missing the
`"panel"` kind and entry point. The shell's panel-loader therefore has no panel to
discover, so `Super+H` (which triggers `omarchy-shell shell toggle`) opens nothing.
Clicking the bar widget calls `root.toggle()` which forwards to the ghost panel inside
the Loader; that panel lacks a shell-injected `controller`, so `root.controller.show()`
fails silently.

This is the exact anti-pattern documented in `prompts.md` line 173:
> "BarWidget.qml não deve conter um Loader para Panel.qml. Isso cria um painel fantasma sem service."

The correct pattern is the one used by the reference plugin **Flowdeck** (`Flowdeck/Panel.qml`,
`Flowdeck/BarWidget.qml`, `Flowdeck/manifest.json`): the shell's panel-loader loads
`Panel.qml` standalone; `BarWidget.qml` is a thin button that calls `shell.toggle()` /
`shell.summon()`; `Panel.qml` uses a `barShim` when the shell doesn't inject `bar`.

## Changes

### 1. `manifest.json` — add panel kind + entry point

```diff
   "kinds": ["service", "bar-widget"],
+  "kinds": ["service", "bar-widget", "panel"],
   "keepLoaded": true,
   "entryPoints": {
     "service": "Service.qml",
     "barWidget": "BarWidget.qml",
+    "panel": "Panel.qml"
   },
```

### 2. `BarWidget.qml` — remove ghost-panel Loader, delegate to shell

**Remove:**
- `Loader { id: panelLoader; ... }` block (lines 148–157)
- `injectPanel()` function (lines 134–140)
- `onBarChanged: injectPanel()` (line 146)
- Ghost-panel forwarding in `open()`, `close()`, `toggle()`, `closeForPopoutSwitch()` (lines 118–132)

**Replace `opened`/`popoutSwitchClosing` properties** (lines 115–116) with shell-based versions:
```qml
readonly property bool opened: root.bar && root.bar.shell && typeof root.bar.shell.isPluginOpen === "function"
  ? root.bar.shell.isPluginOpen(root.moduleName) : false
readonly property bool popoutSwitchClosing: false
```

**Replace `open()`, `close()`, `toggle()`**, `closeForPopoutSwitch()`:
```qml
function open(payloadJson) {
  if (root.bar && root.bar.shell && typeof root.bar.shell.summon === "function")
    root.bar.shell.summon(root.moduleName, payloadJson || "{}");
  else
    Quickshell.execDetached(["omarchy-shell", "shell", "summon", root.moduleName, payloadJson || "{}"]);
}

function close() {
  if (root.bar && root.bar.shell && typeof root.bar.shell.hide === "function")
    root.bar.shell.hide(root.moduleName);
  else
    Quickshell.execDetached(["omarchy-shell", "shell", "hide", root.moduleName]);
}

function toggle() {
  if (root.bar && root.bar.shell && typeof root.bar.shell.toggle === "function")
    root.bar.shell.toggle(root.moduleName, "{}");
  else
    Quickshell.execDetached(["omarchy-shell", "shell", "toggle", root.moduleName, "{}"]);
}

function closeForPopoutSwitch() { root.close(); }
```

**Update click handlers** — they already call `root.toggle()` (clock) and `root.openPanelOn("focus")`
(timer button). The `openPanelOn` function (lines 296–305) already calls `shell.summon` —
keep it as-is. `root.toggle()` now delegates to `shell.toggle`.

### 3. `Panel.qml` — standalone shell-loaded panel

**Add shell-injected properties** (after `moduleName`/`manageIpc`):
```qml
// Injected by the shell panel-loader.
property var shell: null
property var manifest: null
property var service: null
property string omarchyPath: ""
```

**Add `barIdentity`** and **`barShim`** (Flowdeck pattern):
```qml
property var anchorItem: null
property var hostWidget: null
readonly property var barIdentity: hostWidget || root

readonly property QtObject barShim: QtObject {
  property string position: "bottom"
  property int barSize: 0
  property var activePopout: null
  function requestPopout(owner) {}
  function releasePopout(owner) {}
}
```

**Add `centerAnchor` Item** inside `KeyboardPanel` (before `PanelKeyCatcher`):
```qml
Item {
  id: centerAnchor
  anchors.fill: parent
}
```

**Fix `KeyboardPanel` bindings:**
```diff
-    anchorItem: root.anchorItem
-    owner: root.hostWidget || root
-    bar: root.bar
+    anchorItem: centerAnchor
+    owner: root.barIdentity
+    bar: root.barShim
```

**Fix `switchPanel`** (line 56–60) — `root.bar` may be null when shell-loaded; use
`root.barShim` fallback:
```qml
function switchPanel(direction) {
  if (root.bar && typeof root.bar.switchPanelFrom === "function")
    return root.bar.switchPanelFrom(root.barIdentity, direction);
  return false;
}
```

## Verification

1. `omarchy plugin validate "$PLUGIN_DIR"` — must exit 0
2. `node --test tests/` — all existing JS tests must still pass
3. `python3 -m unittest discover -s tests -p 'test_*.py'` — all Python tests pass
4. On an Omarchy machine:
   - `omarchy-shell shell summon io.github.yks777.kairos '{"view":"day"}'` — panel opens
   - `omarchy-shell shell hide io.github.yks777.kairos` — panel closes
   - `Super+H` — panel toggles
   - Left-click bar widget — panel opens on Day tab
   - Left-click timer button — panel opens on Focus tab

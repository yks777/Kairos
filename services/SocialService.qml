import QtQuick
import Quickshell
import Quickshell.Io
import "../logic/SocialModel.js" as SocialModel

Item {
  id: root
  property var service: null
  property var events: []
  property var accounts: []
  property var capabilities: ({})
  property bool bridgeAvailable: false
  property bool busy: false
  property string statusText: "Checking for a local social bridge…"
  property string actionError: ""
  property string pendingPayload: ""
  property string pendingOperation: ""
  property string pendingPlatform: ""
  property string pendingAccountId: ""
  property string pendingTargetId: ""
  property bool initializedSnapshot: false

  readonly property string bridgeScript: localPath(Qt.resolvedUrl("../scripts/social-bridge"))

  function localPath(url) {
    var value = String(url || "");
    if (value.indexOf("file://") === 0) value = value.substring(7);
    try { return decodeURIComponent(value); } catch (error) { return value; }
  }

  function bumpService() {
    if (root.service && typeof root.service.bump === "function") root.service.bump();
  }

  function checkBridge() {
    if (capabilitiesProc.running) return;
    capabilitiesProc.output = "";
    capabilitiesProc.command = ["python3", root.bridgeScript, "capabilities"];
    capabilitiesProc.running = true;
  }

  function refresh() {
    if (!root.bridgeAvailable) {
      root.checkBridge();
      return;
    }
    if (snapshotProc.running) return;
    snapshotProc.output = "";
    snapshotProc.command = ["python3", root.bridgeScript, "snapshot"];
    snapshotProc.running = true;
  }

  function normalizedAccounts(rows) {
    var output = [];
    var seen = {};
    var values = Array.isArray(rows) ? rows : [];
    for (var i = 0; i < values.length && output.length < 100; i++) {
      var item = values[i] || {};
      var platform = String(item.platform || "").toLowerCase();
      var id = String(item.id || "").trim().slice(0, 80);
      if (SocialModel.PLATFORMS.indexOf(platform) < 0 || platform === "email"
          || !/^[A-Za-z0-9_-]{1,80}$/.test(id) || id === "all") continue;
      var key = platform + "|" + id;
      if (seen[key]) continue;
      seen[key] = true;
      output.push({
        id: id,
        platform: platform,
        glyph: SocialModel.accountGlyph(platform),
        name: SocialModel.safeText(item.name || item.displayName || platform, 100),
        accountName: SocialModel.safeText(item.accountName || item.name || platform, 100)
      });
    }
    return output;
  }

  function platformAvailable(platform) {
    var item = root.capabilities[String(platform || "").toLowerCase()];
    return root.bridgeAvailable && !!(item && item.available === true);
  }

  function platformStatus(platform) {
    var key = String(platform || "").toLowerCase();
    if (!root.bridgeAvailable) return root.statusText;
    if (!root.platformAvailable(key)) return "No compatible " + key + " adapter is available.";
    var accountsForPlatform = root.accountsForPlatform(key);
    return accountsForPlatform.length > 0 ? "Connected" : "No " + key + " account is configured in the local bridge.";
  }

  function accountsForPlatform(platform) {
    var key = String(platform || "").toLowerCase();
    var output = [];
    for (var i = 0; i < root.accounts.length; i++)
      if (root.accounts[i].platform === key) output.push(root.accounts[i]);
    return output;
  }

  function eventsForPlatform(platform) {
    var key = String(platform || "").toLowerCase();
    return root.events.filter(function(event) { return event.platform === key; });
  }

  function runAction(operation, platform, accountId, targetId, payload) {
    if (actionProc.running) {
      root.actionError = "Another social action is still running.";
      root.bumpService();
      return false;
    }
    root.pendingOperation = operation;
    root.pendingPlatform = String(platform || "");
    root.pendingAccountId = String(accountId || "");
    root.pendingTargetId = String(targetId || "");
    root.pendingPayload = payload ? JSON.stringify(payload) : "";
    root.actionError = "";
    actionProc.output = "";
    actionProc.stdinEnabled = !!payload;
    if (operation === "send")
      actionProc.command = ["python3", root.bridgeScript, "send", platform, accountId, targetId];
    else if (operation === "call")
      actionProc.command = ["python3", root.bridgeScript, "call", platform, accountId, targetId];
    else
      actionProc.command = ["python3", root.bridgeScript, "mark-read", platform, accountId, targetId];
    actionProc.running = true;
    return true;
  }

  function send(platform, accountId, chatId, text) {
    var value = String(text || "").trim();
    if (value === "" || value.length > 20000) return false;
    return root.runAction("send", platform, accountId, chatId, { text: value });
  }

  function callAction(action, platform, callId) {
    if (["answer", "decline"].indexOf(action) < 0) return false;
    return root.runAction("call", action, platform, callId, null);
  }

  function markRead(platform, accountId, chatId) {
    return root.runAction("mark-read", platform, accountId, chatId, null);
  }

  function applyCapabilities(raw, exitCode) {
    var data = null;
    try { data = JSON.parse(String(raw || "")); } catch (error) {}
    if (exitCode !== 0 || !data || data.ok !== true || data.available !== true) {
      root.bridgeAvailable = false;
      root.capabilities = ({});
      root.accounts = [];
      root.events = [];
      root.initializedSnapshot = false;
      root.statusText = String(data && data.error || "No compatible local social bridge is installed.");
      root.bumpService();
      return;
    }
    root.bridgeAvailable = true;
    root.capabilities = data.platforms && typeof data.platforms === "object" ? data.platforms : ({});
    root.accounts = root.normalizedAccounts(data.accounts);
    root.statusText = "Local social bridge connected.";
    root.bumpService();
    Qt.callLater(root.refresh);
  }

  function applySnapshot(raw, exitCode) {
    var data = null;
    try { data = JSON.parse(String(raw || "")); } catch (error) {}
    if (exitCode !== 0 || !data || data.ok !== true || !Array.isArray(data.events)) {
      root.statusText = String(data && data.error || "Could not load social activity from the local bridge.");
      root.bumpService();
      return;
    }
    var previous = root.events;
    var nextEvents = SocialModel.mergeEvents([data.events]);
    if (root.initializedSnapshot && root.service && root.service.settings) {
      var settings = root.service.settings.social || {};
      var priorIds = {};
      for (var priorIndex = 0; priorIndex < previous.length; priorIndex++) {
        var prior = previous[priorIndex];
        priorIds[prior.platform + "|" + prior.accountId + "|" + prior.id] = true;
      }
      for (var eventIndex = 0; eventIndex < nextEvents.length; eventIndex++) {
        var event = nextEvents[eventIndex];
        var eventKey = event.platform + "|" + event.accountId + "|" + event.id;
        if (priorIds[eventKey] || settings[event.platform] !== true) continue;
        if (event.kind === "message" && event.chat.unread > 0 && settings.notifyMessages !== false) {
          var messageBody = settings.showPreview === true
            ? (event.preview || event.body || "New message received.") : "New message received.";
          root.service.notify("social", "New message · " + event.accountName, messageBody);
        } else if (event.kind === "call" && event.callState === "ringing" && settings.notifyCalls !== false) {
          root.service.notify("social", "Incoming call · " + event.accountName, event.chat.name || "Call received.");
        }
      }
    }
    root.events = nextEvents;
    root.initializedSnapshot = true;
    if (Array.isArray(data.accounts)) root.accounts = root.normalizedAccounts(data.accounts);
    root.statusText = root.accounts.length > 0 ? "Connected to the local social bridge." : "No social accounts are configured in the local bridge.";
    root.bumpService();
  }

  function applyAction(raw, exitCode) {
    var data = null;
    try { data = JSON.parse(String(raw || "")); } catch (error) {}
    if (exitCode !== 0 || !data || data.ok !== true) {
      root.actionError = String(data && data.error || "The social action could not be completed.");
      root.statusText = root.actionError;
    } else {
      root.actionError = "";
      root.statusText = "Social action completed.";
      Qt.callLater(root.refresh);
    }
    root.pendingPayload = "";
    root.pendingOperation = "";
    root.bumpService();
  }

  Process {
    id: capabilitiesProc
    property string output: ""
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: capabilitiesProc.output = text
    }
    onExited: function(exitCode) {
      var output = capabilitiesProc.output;
      capabilitiesProc.output = "";
      root.applyCapabilities(output, exitCode);
    }
  }

  Process {
    id: snapshotProc
    property string output: ""
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: snapshotProc.output = text
    }
    onExited: function(exitCode) {
      var output = snapshotProc.output;
      snapshotProc.output = "";
      root.applySnapshot(output, exitCode);
    }
  }

  Process {
    id: actionProc
    property string output: ""
    stdinEnabled: false
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: actionProc.output = text
    }
    onStarted: {
      if (root.pendingPayload !== "") {
        actionProc.write(root.pendingPayload);
        actionProc.stdinEnabled = false;
      }
    }
    onExited: function(exitCode) {
      var output = actionProc.output;
      actionProc.output = "";
      actionProc.stdinEnabled = false;
      root.applyAction(output, exitCode);
    }
  }

  Timer {
    interval: 30000
    running: root.bridgeAvailable
    repeat: true
    onTriggered: root.refresh()
  }

  Component.onCompleted: root.checkBridge()
}
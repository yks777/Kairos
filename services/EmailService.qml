import QtQuick
import Quickshell
import Quickshell.Io
import "../logic/EmailModel.js" as EmailModel

Item {
  id: root
  property var service: null
  property var accounts: []
  property var messages: ({})
  property var accountStatuses: ({})
  property var connectedAccounts: ({})
  property var initializedAccounts: ({})
  property var seenMessageIds: ({})
  property string statusText: "Add an email account to connect an inbox."
  property string pendingSecret: ""
  property string pendingCredentialAction: ""
  property string pendingCredentialAccount: ""
  property string pendingSendAccount: ""
  property string pendingSendPayload: ""
  property string pendingMarkReadAccount: ""
  property var pendingMarkReadIds: []
  property string pendingMarkReadPayload: ""
  property var credentialQueue: []
  property string pendingWatcherConfig: ""
  property string observedAccountsKey: ""
  property bool restartPending: false
  property bool operationBusy: false

  readonly property string emailScript: localPath(Qt.resolvedUrl("../scripts/email-fetch"))
  readonly property var events: {
    var output = [];
    for (var i = 0; i < root.accounts.length; i++) {
      var account = root.accounts[i];
      var rows = root.messages[account.id] || [];
      var converted = EmailModel.toSocialEvents(rows, account);
      for (var j = 0; j < converted.length; j++) output.push(converted[j]);
    }
    return output;
  }
  readonly property bool available: {
    if (root.accounts.length === 0 || !watcherProc.running) return false;
    for (var i = 0; i < root.accounts.length; i++)
      if (root.connectedAccounts[root.accounts[i].id] === true) return true;
    return false;
  }

  function localPath(url) {
    var value = String(url || "");
    if (value.indexOf("file://") === 0) value = value.substring(7);
    try { return decodeURIComponent(value); } catch (error) { return value; }
  }

  function bumpService() {
    if (root.service && typeof root.service.bump === "function") root.service.bump();
  }

  function safeCopy(value) {
    var output = {};
    if (value && typeof value === "object")
      for (var key in value) if (Object.prototype.hasOwnProperty.call(value, key)) output[key] = value[key];
    return output;
  }

  function currentAccounts() {
    var settings = root.service && root.service.settings ? root.service.settings.email : null;
    return settings && Array.isArray(settings.accounts) ? settings.accounts.slice(0, 32) : [];
  }

  function accountsKey(accounts) {
    try { return JSON.stringify(accounts); } catch (error) { return "[]"; }
  }

  function accountById(accountId) {
    var id = String(accountId || "");
    for (var i = 0; i < root.accounts.length; i++) if (root.accounts[i].id === id) return root.accounts[i];
    return null;
  }

  function accountComplete(account) {
    return !!(account && account.id && account.email && account.username
      && account.imapHost && account.imapPort && account.smtpHost && account.smtpPort);
  }

  function statusForAccount(accountId) {
    return String(root.accountStatuses[String(accountId || "")] || root.statusText);
  }

  function setAccountStatus(accountId, status) {
    var next = root.safeCopy(root.accountStatuses);
    next[String(accountId || "")] = String(status || "");
    root.accountStatuses = next;
    root.bumpService();
  }

  function setConnected(accountId, connected) {
    var next = root.safeCopy(root.connectedAccounts);
    var id = String(accountId || "");
    if (id === "") return;
    if (connected === true) next[id] = true;
    else delete next[id];
    root.connectedAccounts = next;
    root.bumpService();
  }

  function handleSettingsChanged() {
    var rows = root.currentAccounts();
    var key = root.accountsKey(rows);
    if (key === root.observedAccountsKey) return;
    root.observedAccountsKey = key;
    root.accounts = rows;
    root.restartWatcher();
  }

  function restartWatcher() {
    if (watcherProc.running) {
      root.restartPending = true;
      watcherProc.running = false;
      return;
    }
    root.startWatcher();
  }

  function startWatcher() {
    if (watcherProc.running) return;
    root.connectedAccounts = ({});
    var complete = [];
    var nextStatuses = root.safeCopy(root.accountStatuses);
    for (var i = 0; i < root.accounts.length; i++) {
      if (root.accountComplete(root.accounts[i])) {
        complete.push(root.accounts[i]);
        nextStatuses[root.accounts[i].id] = "Connecting through the system keyring…";
      } else nextStatuses[root.accounts[i].id] = "Complete the email address, username, IMAP and SMTP server fields.";
    }
    root.accountStatuses = nextStatuses;
    if (complete.length === 0) {
      root.statusText = root.accounts.length === 0
        ? "Add an email account to connect an inbox."
        : "Complete the account settings to start secure IMAP access.";
      root.messages = ({});
      root.bumpService();
      return;
    }
    root.statusText = "Connecting to email accounts through the system keyring…";
    root.pendingWatcherConfig = JSON.stringify({ accounts: complete });
    watcherProc.output = "";
    watcherProc.stdinEnabled = true;
    watcherProc.command = ["python3", root.emailScript, "watch"];
    watcherProc.running = true;
    root.bumpService();
  }

  function handleWatchLine(line) {
    var data = null;
    try { data = JSON.parse(String(line || "").trim()); } catch (error) { return; }
    if (!data || typeof data !== "object") return;
    if (data.type === "fatal") {
      root.statusText = String(data.error || "The email watcher could not start.");
      root.bumpService();
      return;
    }
    var account = root.accountById(data.accountId);
    if (!account) return;
    if (data.ok !== true) {
      var errorText = String(data.error || "Could not load this inbox.");
      root.setConnected(account.id, false);
      root.setAccountStatus(account.id, errorText);
      root.statusText = "Email account unavailable: " + errorText;
      root.bumpService();
      return;
    }
    root.setConnected(account.id, true);
    var parsed = EmailModel.parseMessages(data.messages || []);
    for (var i = 0; i < parsed.length; i++) parsed[i].accountId = account.id;
    var nextMessages = root.safeCopy(root.messages);
    var oldRows = Array.isArray(nextMessages[account.id]) ? nextMessages[account.id] : [];
    var seen = root.safeCopy(root.seenMessageIds);
    var accountSeen = seen[account.id] && typeof seen[account.id] === "object" ? root.safeCopy(seen[account.id]) : ({});
    var notifyNew = !!(root.service && root.service.settings && root.service.settings.email
      && root.service.settings.email.notifyNew !== false);
    var showPreview = !!(root.service && root.service.settings && root.service.settings.email
      && root.service.settings.email.showPreview === true);
    var initialized = root.initializedAccounts[account.id] === true;
    var newlyUnread = [];
    for (var j = 0; j < parsed.length; j++) {
      if (!accountSeen[parsed[j].id] && initialized && parsed[j].unread > 0) newlyUnread.push(parsed[j]);
      accountSeen[parsed[j].id] = true;
    }
    var oldById = {};
    for (var k = 0; k < oldRows.length; k++) oldById[oldRows[k].id] = oldRows[k];
    var receivedIds = {};
    for (var k = 0; k < parsed.length; k++) {
      receivedIds[parsed[k].id] = true;
      if (oldById[parsed[k].id] && oldById[parsed[k].id].unread === 0) parsed[k].unread = 0;
    }
    for (var oldIndex = 0; oldIndex < oldRows.length; oldIndex++) {
      var oldRow = oldRows[oldIndex];
      if (receivedIds[oldRow.id]) continue;
      var retained = root.safeCopy(oldRow);
      retained.unread = 0;
      parsed.push(retained);
    }
    parsed.sort(function(a, b) { return b.timestamp - a.timestamp; });
    parsed = parsed.slice(0, 100);
    var seenKeys = Object.keys(accountSeen);
    for (var trimIndex = 0; seenKeys.length > 2000 && trimIndex < seenKeys.length - 2000; trimIndex++)
      delete accountSeen[seenKeys[trimIndex]];
    nextMessages[account.id] = parsed;
    seen[account.id] = accountSeen;
    root.messages = nextMessages;
    root.seenMessageIds = seen;
    var initializedNext = root.safeCopy(root.initializedAccounts);
    initializedNext[account.id] = true;
    root.initializedAccounts = initializedNext;
    var unreadCount = parsed.filter(function(item) { return item.unread > 0; }).length;
    root.setAccountStatus(account.id, "Inbox connected · " + unreadCount + " unread message" + (unreadCount === 1 ? "" : "s"));
    root.statusText = "Email watcher connected to configured accounts.";
    if (notifyNew && root.service && typeof root.service.notify === "function") {
      for (var notifyIndex = 0; notifyIndex < newlyUnread.length; notifyIndex++) {
        var item = newlyUnread[notifyIndex];
        root.service.notify("social", "New email", showPreview ? item.subject : "New message received.");
      }
    }
    root.bumpService();
  }

  function send(accountId, payload) {
    var account = root.accountById(accountId);
    if (!root.accountComplete(account) || sendProc.running) {
      root.setAccountStatus(accountId, sendProc.running ? "Another email operation is in progress." : "Complete the account settings before sending.");
      return false;
    }
    root.pendingSendAccount = String(accountId);
    root.pendingSendPayload = JSON.stringify(payload || {});
    sendProc.output = "";
    sendProc.stdinEnabled = true;
    sendProc.command = ["python3", root.emailScript, "send", account.id, account.smtpHost,
      String(account.smtpPort), account.username, account.email];
    sendProc.running = true;
    return true;
  }

  function markThreadRead(accountId, threadId) {
    var account = root.accountById(accountId);
    var thread = String(threadId || "");
    if (!root.accountComplete(account) || markReadProc.running) return false;
    var rows = Array.isArray(root.messages[account.id]) ? root.messages[account.id] : [];
    var ids = [];
    for (var i = 0; i < rows.length && ids.length < 100; i++) {
      if (rows[i].threadId !== thread || rows[i].unread <= 0) continue;
      var uid = String(rows[i].uid || "");
      if (/^[0-9]{1,20}$/.test(uid) && ids.indexOf(uid) === -1) ids.push(uid);
    }
    if (ids.length === 0) return true;
    root.pendingMarkReadAccount = account.id;
    root.pendingMarkReadIds = ids;
    root.pendingMarkReadPayload = JSON.stringify({ uids: ids });
    markReadProc.output = "";
    markReadProc.stdinEnabled = true;
    markReadProc.command = ["python3", root.emailScript, "mark-read", account.id,
      account.imapHost, String(account.imapPort), account.username];
    markReadProc.running = true;
    return true;
  }

  function startCredential(action, accountId, secret) {
    if (credentialProc.running) return false;
    root.pendingCredentialAction = action;
    root.pendingCredentialAccount = String(accountId || "");
    root.pendingSecret = String(secret || "");
    credentialProc.output = "";
    credentialProc.stdinEnabled = action === "store";
    credentialProc.command = ["python3", root.emailScript, action, root.pendingCredentialAccount];
    credentialProc.running = true;
    return true;
  }

  function startQueuedCredential() {
    if (credentialProc.running || root.credentialQueue.length === 0) return;
    var queue = root.credentialQueue.slice();
    var next = queue.shift();
    root.credentialQueue = queue;
    root.startCredential(next.action, next.accountId, next.secret || "");
  }

  function storeCredential(accountId, secret) {
    var account = root.accountById(accountId);
    var value = String(secret || "");
    if (!account || !value || value.length > 4096 || value.indexOf("\u0000") !== -1) {
      root.setAccountStatus(accountId, "Enter a password of 1–4096 characters.");
      return false;
    }
    if (credentialProc.running || root.credentialQueue.length > 0) {
      root.setAccountStatus(accountId, "Another keyring operation is in progress.");
      return false;
    }
    return root.startCredential("store", String(accountId), value);
  }

  function clearCredential(accountId) {
    var id = String(accountId || "");
    if (!id) return false;
    if (!credentialProc.running && root.credentialQueue.length === 0)
      return root.startCredential("clear", id, "");
    var queue = root.credentialQueue.slice();
    queue.push({ action: "clear", accountId: id });
    root.credentialQueue = queue;
    return true;
  }

  function clearAccount(accountId) {
    var id = String(accountId || "");
    root.clearCredential(id);
    var next = root.safeCopy(root.messages);
    delete next[id];
    root.messages = next;
    var initialized = root.safeCopy(root.initializedAccounts);
    delete initialized[id];
    root.initializedAccounts = initialized;
    var seen = root.safeCopy(root.seenMessageIds);
    delete seen[id];
    root.seenMessageIds = seen;
    var statuses = root.safeCopy(root.accountStatuses);
    delete statuses[id];
    root.accountStatuses = statuses;
    var connected = root.safeCopy(root.connectedAccounts);
    delete connected[id];
    root.connectedAccounts = connected;
    root.bumpService();
  }

  Process {
    id: watcherProc
    property string output: ""
    stdinEnabled: false
    stdout: SplitParser {
      onRead: function(data) { root.handleWatchLine(data); }
    }
    stderr: StdioCollector {}
    onStarted: {
      watcherProc.write(root.pendingWatcherConfig || "{}");
      watcherProc.stdinEnabled = false;
    }
    onExited: function(exitCode) {
      watcherProc.stdinEnabled = false;
      if (root.restartPending) {
        root.restartPending = false;
        Qt.callLater(root.startWatcher);
        return;
      }
      if (root.accounts.length > 0) {
        root.statusText = exitCode === 0 ? "Email watcher stopped." : "Email watcher stopped unexpectedly; retrying shortly.";
        root.bumpService();
        watcherRestart.restart();
      }
    }
  }

  Process {
    id: sendProc
    property string output: ""
    stdinEnabled: false
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: sendProc.output = text
    }
    stderr: StdioCollector {}
    onStarted: {
      sendProc.write(root.pendingSendPayload || "{}");
      sendProc.stdinEnabled = false;
      root.pendingSendPayload = "";
    }
    onExited: function(exitCode) {
      var output = sendProc.output;
      sendProc.output = "";
      sendProc.stdinEnabled = false;
      var data = null;
      try { data = JSON.parse(String(output || "")); } catch (error) {}
      var accountId = root.pendingSendAccount;
      root.pendingSendAccount = "";
      if (exitCode === 0 && data && data.ok === true) root.setAccountStatus(accountId, "Email sent successfully.");
      else root.setAccountStatus(accountId, String(data && data.error || "Email could not be sent."));
    }
  }

  Process {
    id: markReadProc
    property string output: ""
    stdinEnabled: false
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: markReadProc.output = text
    }
    stderr: StdioCollector {}
    onStarted: {
      markReadProc.write(root.pendingMarkReadPayload || "{}");
      markReadProc.stdinEnabled = false;
      root.pendingMarkReadPayload = "";
    }
    onExited: function(exitCode) {
      var output = markReadProc.output;
      markReadProc.output = "";
      markReadProc.stdinEnabled = false;
      var data = null;
      try { data = JSON.parse(String(output || "")); } catch (error) {}
      var accountId = root.pendingMarkReadAccount;
      var markedUids = data && Array.isArray(data.uids) ? data.uids : root.pendingMarkReadIds;
      if (exitCode === 0 && data && data.ok === true) {
        var next = root.safeCopy(root.messages);
        var rows = Array.isArray(next[accountId]) ? next[accountId].slice() : [];
        for (var i = 0; i < rows.length; i++) {
          if (markedUids.indexOf(String(rows[i].uid || "")) !== -1) {
            var message = root.safeCopy(rows[i]);
            message.unread = 0;
            rows[i] = message;
          }
        }
        next[accountId] = rows;
        root.messages = next;
        var unreadCount = rows.filter(function(item) { return item.unread > 0; }).length;
        root.setAccountStatus(accountId, "Inbox connected · " + unreadCount + " unread message" + (unreadCount === 1 ? "" : "s"));
      } else {
        root.setAccountStatus(accountId, String(data && data.error || "Could not mark the email thread as read."));
      }
      root.pendingMarkReadAccount = "";
      root.pendingMarkReadIds = [];
      root.bumpService();
    }
  }

  Process {
    id: credentialProc
    property string output: ""
    stdinEnabled: false
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: credentialProc.output = text
    }
    stderr: StdioCollector {}
    onStarted: {
      if (root.pendingCredentialAction === "store") {
        credentialProc.write(root.pendingSecret);
        credentialProc.stdinEnabled = false;
        root.pendingSecret = "";
      }
    }
    onExited: function(exitCode) {
      var output = credentialProc.output;
      credentialProc.output = "";
      credentialProc.stdinEnabled = false;
      var data = null;
      try { data = JSON.parse(String(output || "")); } catch (error) {}
      var accountId = root.pendingCredentialAccount;
      if (root.accountById(accountId)) {
        if (exitCode === 0 && data && data.ok === true) {
          root.setAccountStatus(accountId, root.pendingCredentialAction === "store"
            ? "Password saved in the system keyring." : "Keyring item removed.");
          root.restartWatcher();
        } else root.setAccountStatus(accountId, String(data && data.error || "The keyring operation failed."));
      }
      root.pendingCredentialAction = "";
      root.pendingCredentialAccount = "";
      root.pendingSecret = "";
      Qt.callLater(root.startQueuedCredential);
    }
  }

  Timer {
    id: watcherRestart
    interval: 30000
    repeat: false
    onTriggered: root.restartWatcher()
  }

  Connections {
    target: root.service
    function onSettingsChanged() { root.handleSettingsChanged(); }
    function onStateLoadedChanged() { root.handleSettingsChanged(); }
  }

  Component.onCompleted: {
    root.accounts = root.currentAccounts();
    root.observedAccountsKey = root.accountsKey(root.accounts);
    root.startWatcher();
  }
}

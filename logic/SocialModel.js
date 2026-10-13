.pragma library

var PLATFORMS = ["telegram", "whatsapp", "signal", "discord", "matrix", "email"];

function finiteNumber(value, fallback) {
  if (value === null || value === undefined || value === "") return fallback;
  var number = Number(value);
  return isFinite(number) ? number : fallback;
}

function safeText(value, maximum) {
  return String(value === null || value === undefined ? "" : value)
    .replace(/[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f]/g, " ")
    .trim().slice(0, maximum || 500);
}

function normalizedTimestamp(value) {
  var timestamp = finiteNumber(value, 0);
  if (timestamp > 0 && timestamp < 100000000000) timestamp *= 1000;
  return timestamp;
}

function normalizeEvent(raw) {
  if (!raw || typeof raw !== "object") return null;
  var platform = safeText(raw.platform, 24).toLowerCase();
  if (PLATFORMS.indexOf(platform) === -1) return null;
  var id = safeText(raw.id || raw.messageId, 160);
  var accountId = safeText(raw.accountId, 80);
  var kind = safeText(raw.kind, 24).toLowerCase();
  var missedCall = kind === "missed_call";
  if (missedCall) kind = "call";
  if (platform === "email" && kind === "message") kind = "email";
  if (["message", "email", "call"].indexOf(kind) === -1 || id === "" || accountId === "") return null;

  var chatSource = raw.chat && typeof raw.chat === "object" ? raw.chat : {};
  var senderSource = raw.sender && typeof raw.sender === "object" ? raw.sender : {};
  var chatId = safeText(chatSource.id || raw.chatId || (platform === "email" ? raw.threadId : ""), 160);
  if (chatId === "") chatId = id;
  var senderName = safeText(senderSource.name || raw.senderName || raw.from || "Unknown sender", 160);
  var timestamp = normalizedTimestamp(raw.timestamp || raw.date);
  var unread = Math.max(0, Math.min(100000, Math.floor(finiteNumber(chatSource.unread, finiteNumber(raw.unread, 0)))));
  var callState = safeText(raw.callState || (missedCall ? "missed" : ""), 24).toLowerCase();
  if (["ringing", "missed", "incoming", "outgoing", "ended"].indexOf(callState) === -1) callState = "";
  if (kind === "call" && callState === "") callState = "ended";

  return {
    id: id,
    platform: platform,
    kind: kind,
    accountId: accountId,
    accountName: safeText(raw.accountName || raw.account || platform, 100),
    chat: {
      id: chatId,
      name: safeText(chatSource.name || raw.chatName || senderName, 160),
      unread: unread
    },
    sender: {
      id: safeText(senderSource.id || raw.senderId, 160),
      name: senderName,
      email: safeText(senderSource.email || raw.fromEmail, 254)
    },
    subject: safeText(raw.subject, 300),
    body: safeText(raw.body || raw.preview, 20000),
    preview: safeText(raw.preview || raw.body || raw.subject, 400),
    timestamp: timestamp,
    callState: callState,
    hasAttachments: raw.hasAttachments === true,
    attachmentNames: Array.isArray(raw.attachmentNames)
      ? raw.attachmentNames.slice(0, 16).map(function(name) { return safeText(name, 200); }) : [],
    messageId: safeText(raw.messageId || raw.id, 300),
    uid: safeText(raw.uid, 32),
    inReplyTo: safeText(raw.inReplyTo, 300),
    references: safeText(raw.references, 1000),
    to: safeText(raw.to, 1000),
    cc: safeText(raw.cc, 1000),
    openUrl: safeText(raw.openUrl, 2048),
    canReply: raw.canReply !== false
  };
}

function mergeEvents(sources) {
  var out = [];
  var seen = {};
  var lists = Array.isArray(sources) ? sources : [];
  for (var i = 0; i < lists.length; i++) {
    var list = Array.isArray(lists[i]) ? lists[i] : [];
    for (var j = 0; j < list.length; j++) {
      var event = normalizeEvent(list[j]);
      if (!event) continue;
      var key = event.platform + "|" + event.accountId + "|" + event.id;
      if (seen[key]) continue;
      seen[key] = true;
      out.push(event);
    }
  }
  out.sort(function(a, b) { return b.timestamp - a.timestamp || a.id.localeCompare(b.id); });
  return out.slice(0, 2000);
}

function accountMatches(event, accountId) {
  var filter = String(accountId || "all");
  if (filter === "" || filter === "all") return true;
  if (filter.indexOf("platform:") === 0) return event.platform === filter.substring(9);
  return event.accountId === filter;
}

function unreadConversations(events, accountId, now) {
  var rows = Array.isArray(events) ? events : [];
  var grouped = {};
  for (var i = 0; i < rows.length; i++) {
    var event = normalizeEvent(rows[i]);
    if (!event || !accountMatches(event, accountId)) continue;
    if (event.kind !== "message" && event.kind !== "email") continue;
    if (event.kind === "email" ? event.chat.unread <= 0 : event.chat.unread <= 0) continue;
    var key = event.platform + "|" + event.accountId + "|" + event.chat.id;
    if (!Object.prototype.hasOwnProperty.call(grouped, key)) {
      grouped[key] = {
        id: key,
        accountId: event.accountId,
        chatId: event.chat.id,
        platform: event.platform,
        name: event.chat.name,
        accountName: event.accountName,
        preview: event.subject || event.preview || event.body,
        subject: event.subject,
        timestamp: event.timestamp,
        unread: event.kind === "email" ? 1 : event.chat.unread,
        kind: event.kind,
        messageId: event.messageId,
        event: event
      };
    } else {
      var groupedItem = grouped[key];
      if (event.kind === "email") groupedItem.unread++;
      else groupedItem.unread = Math.max(groupedItem.unread, event.chat.unread);
      if (event.timestamp > groupedItem.timestamp) {
        groupedItem.name = event.chat.name;
        groupedItem.preview = event.subject || event.preview || event.body;
        groupedItem.subject = event.subject;
        groupedItem.timestamp = event.timestamp;
        groupedItem.messageId = event.messageId;
        groupedItem.event = event;
      }
    }
  }
  var output = Object.keys(grouped).map(function(key) { return grouped[key]; });
  output.sort(function(a, b) { return b.timestamp - a.timestamp; });
  return output.slice(0, 200);
}

function unreadCount(events, accountId) {
  var rows = unreadConversations(events, accountId);
  var total = 0;
  for (var i = 0; i < rows.length; i++) total += rows[i].unread;
  return total;
}

function recentCalls(events, accountId, now) {
  var current = finiteNumber(now, Date.now());
  var cutoff = current - 24 * 60 * 60 * 1000;
  var rows = Array.isArray(events) ? events : [];
  var output = [];
  for (var i = 0; i < rows.length; i++) {
    var event = normalizeEvent(rows[i]);
    if (!event || event.kind !== "call" || !accountMatches(event, accountId)) continue;
    if (event.timestamp >= cutoff && event.timestamp <= current) output.push(event);
  }
  output.sort(function(a, b) { return b.timestamp - a.timestamp; });
  return output.slice(0, 50);
}

function ringingCall(events) {
  var rows = Array.isArray(events) ? events : [];
  for (var i = 0; i < rows.length; i++) {
    var event = normalizeEvent(rows[i]);
    if (event && event.kind === "call" && event.callState === "ringing") return event;
  }
  return null;
}

function threadEvents(events, accountId, chatId) {
  var rows = Array.isArray(events) ? events : [];
  var output = [];
  for (var i = 0; i < rows.length; i++) {
    var event = normalizeEvent(rows[i]);
    if (!event || event.accountId !== String(accountId || "") || event.chat.id !== String(chatId || "")) continue;
    if (event.kind === "message" || event.kind === "email") output.push(event);
  }
  output.sort(function(a, b) { return a.timestamp - b.timestamp; });
  return output.slice(-200);
}

function timeLabel(timestamp, now) {
  var current = finiteNumber(now, Date.now());
  var when = normalizedTimestamp(timestamp);
  if (when <= 0) return "";
  var diff = Math.max(0, current - when);
  var minutes = Math.floor(diff / 60000);
  if (minutes < 1) return "now";
  if (minutes < 60) return minutes + "m";
  var hours = Math.floor(minutes / 60);
  if (hours < 24) return hours + "h";
  var days = Math.floor(hours / 24);
  return days < 7 ? days + "d" : new Date(when).toLocaleDateString();
}

function accountGlyph(platform) {
  switch (String(platform || "").toLowerCase()) {
    case "telegram": return "\uf2c6";
    case "whatsapp": return "\uf232";
    case "signal": return "\uf012";
    case "discord": return "\uf392";
    case "matrix": return "\uf0e0";
    case "email": return "\uf0e0";
    default: return "\uf2bd";
  }
}

function callGlyph(kind) {
  if (kind === "missed") return "\uf095";
  if (kind === "outgoing") return "\uf064";
  return "\uf095";
}

if (typeof module !== "undefined") {
  module.exports = {
    PLATFORMS: PLATFORMS,
    safeText: safeText,
    normalizeEvent: normalizeEvent,
    mergeEvents: mergeEvents,
    accountMatches: accountMatches,
    unreadConversations: unreadConversations,
    unreadCount: unreadCount,
    recentCalls: recentCalls,
    ringingCall: ringingCall,
    threadEvents: threadEvents,
    timeLabel: timeLabel,
    accountGlyph: accountGlyph,
    callGlyph: callGlyph
  };
}

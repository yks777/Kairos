.pragma library

function safeText(value, maximum) {
  return String(value === null || value === undefined ? "" : value)
    .replace(/[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f]/g, " ")
    .trim().slice(0, maximum || 20000);
}

function finiteNumber(value, fallback) {
  if (value === null || value === undefined || value === "") return fallback;
  var number = Number(value);
  return isFinite(number) ? number : fallback;
}

function decodeEntities(text) {
  return String(text || "")
    .replace(/&nbsp;/gi, " ")
    .replace(/&amp;/gi, "&")
    .replace(/&lt;/gi, "<")
    .replace(/&gt;/gi, ">")
    .replace(/&quot;/gi, "\"")
    .replace(/&#39;|&apos;/gi, "'")
    .replace(/&#(\d+);/g, function(match, code) {
      var value = Number(code);
      return value >= 0 && value <= 0x10ffff ? String.fromCharCode(value) : "";
    })
    .replace(/&#x([0-9a-f]+);/gi, function(match, code) {
      var value = parseInt(code, 16);
      return value >= 0 && value <= 0x10ffff ? String.fromCharCode(value) : "";
    });
}

function sanitizeBody(text) {
  var value = String(text || "").replace(/\r\n?/g, "\n");
  value = value.replace(/<(script|style)[^>]*>[\s\S]*?<\/\1\s*>/gi, " ");
  value = value.replace(/<(br|hr)\s*\/?>/gi, "\n").replace(/<\/p\s*>/gi, "\n\n").replace(/<\/div\s*>/gi, "\n");
  value = value.replace(/<[^>]+>/g, " ");
  value = decodeEntities(value).replace(/[ \t]+/g, " ").replace(/\n[ \t]+/g, "\n");
  return value.trim().slice(0, 20000);
}

function formatAddress(address) {
  if (!address) return "";
  if (typeof address === "string") return safeText(address, 500);
  var name = safeText(address.name, 200);
  var email = safeText(address.email, 254);
  if (!email) return name;
  return name && name !== email ? name + " <" + email + ">" : email;
}

function parseAddressList(value) {
  var text = safeText(value, 2000);
  var candidates = text.match(/(?:[^,;]+<[^>]+>|[^,;\s]+@[^,;\s]+\.[^,;\s]+)/g) || [];
  var output = [];
  var seen = {};
  for (var i = 0; i < candidates.length; i++) {
    var candidate = candidates[i].trim();
    var match = candidate.match(/<([^<>]+)>/);
    var email = (match ? match[1] : candidate).trim();
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) continue;
    var key = email.toLowerCase();
    if (seen[key]) continue;
    seen[key] = true;
    output.push(candidate);
  }
  return output;
}

function parseMessages(value) {
  var payload = value;
  if (typeof payload === "string") {
    try { payload = JSON.parse(payload); } catch (error) { return []; }
  }
  if (payload && !Array.isArray(payload) && Array.isArray(payload.messages)) payload = payload.messages;
  if (!Array.isArray(payload)) return [];
  var output = [];
  var seen = {};
  for (var i = 0; i < payload.length && output.length < 100; i++) {
    var raw = payload[i];
    if (!raw || typeof raw !== "object") continue;
    var id = safeText(raw.id || raw.messageId, 300);
    if (!id || seen[id]) continue;
    seen[id] = true;
    var timestamp = finiteNumber(raw.timestamp, 0);
    if (timestamp > 0 && timestamp < 100000000000) timestamp *= 1000;
    var to = safeText(raw.to, 1000);
    var cc = safeText(raw.cc, 1000);
    var attachments = Array.isArray(raw.attachmentNames)
      ? raw.attachmentNames.slice(0, 16).map(function(item) { return safeText(item, 200); }) : [];
    output.push({
      id: id,
      messageId: safeText(raw.messageId || id, 300),
      uid: safeText(raw.uid, 32),
      accountId: safeText(raw.accountId, 80),
      from: safeText(raw.from, 500),
      fromEmail: safeText(raw.fromEmail, 254),
      to: to,
      cc: cc,
      subject: safeText(raw.subject || "(no subject)", 300),
      body: sanitizeBody(raw.body),
      timestamp: timestamp,
      unread: Math.max(0, Math.min(1, Math.floor(finiteNumber(raw.unread, 1)))),
      hasAttachments: raw.hasAttachments === true || attachments.length > 0,
      attachmentNames: attachments,
      threadId: safeText(raw.threadId || raw.inReplyTo || id, 300),
      inReplyTo: safeText(raw.inReplyTo, 300),
      references: safeText(raw.references, 1000),
      accountName: safeText(raw.accountName, 100)
    });
  }
  output.sort(function(a, b) { return b.timestamp - a.timestamp; });
  return output;
}

function toSocialEvents(messages, account) {
  var rows = Array.isArray(messages) ? messages : [];
  var acc = account && typeof account === "object" ? account : {};
  var output = [];
  for (var i = 0; i < rows.length; i++) {
    var message = rows[i] || {};
    output.push({
      id: message.id,
      messageId: message.messageId || message.id,
      uid: message.uid || "",
      platform: "email",
      kind: "email",
      accountId: String(acc.id || message.accountId || ""),
      accountName: String(acc.name || message.accountName || acc.email || "Email"),
      chat: {
        id: String(message.threadId || message.id || ""),
        name: String(message.from || message.fromEmail || "Unknown sender"),
        unread: Number(message.unread) > 0 ? 1 : 0
      },
      sender: { name: String(message.from || message.fromEmail || "Unknown sender"), email: String(message.fromEmail || "") },
      from: String(message.from || ""),
      to: String(message.to || ""),
      cc: String(message.cc || ""),
      subject: String(message.subject || ""),
      body: String(message.body || ""),
      preview: String(message.subject || message.body || ""),
      timestamp: Number(message.timestamp) || 0,
      hasAttachments: message.hasAttachments === true,
      attachmentNames: Array.isArray(message.attachmentNames) ? message.attachmentNames : [],
      inReplyTo: String(message.inReplyTo || ""),
      references: String(message.references || ""),
      canReply: true
    });
  }
  return output;
}

function replyDraft(message, account, mode) {
  var source = message && typeof message === "object" ? message : {};
  var ownEmail = String(account && account.email || "").toLowerCase();
  var sender = parseAddressList(source.from || source.fromEmail || "");
  var recipients = mode === "replyAll"
    ? parseAddressList(String(source.to || "") + ", " + String(source.cc || ""))
    : [];
  var combined = [];
  var seen = {};
  var candidates = mode === "forward" ? [] : (mode === "replyAll" ? sender.concat(recipients) : sender);
  for (var i = 0; i < candidates.length; i++) {
    var match = candidates[i].match(/<([^<>]+)>/);
    var address = (match ? match[1] : candidates[i]).trim();
    if (!address || address.toLowerCase() === ownEmail || seen[address.toLowerCase()]) continue;
    seen[address.toLowerCase()] = true;
    combined.push(candidates[i]);
  }
  var subject = String(source.subject || "").trim();
  if (mode === "forward") {
    if (!/^fwd?:/i.test(subject)) subject = "Fwd: " + subject;
  } else if (!/^re:/i.test(subject)) subject = "Re: " + subject;
  var body = "";
  if (mode === "forward") {
    body = "\n\n---------- Forwarded message ----------\nFrom: " + String(source.from || "")
      + "\nDate: " + new Date(Number(source.timestamp) || Date.now()).toLocaleString()
      + "\nSubject: " + String(source.subject || "")
      + "\n\n" + String(source.body || "");
  } else if (mode === "reply" || mode === "replyAll") {
    body = "\n\nOn " + new Date(Number(source.timestamp) || Date.now()).toLocaleString()
      + ", " + String(source.from || "the sender") + " wrote:\n"
      + String(source.body || "").split("\n").map(function(line) { return "> " + line; }).join("\n");
  }
  return {
    mode: mode,
    to: combined.join(", "),
    subject: subject,
    body: body,
    originalId: String(source.messageId || source.id || ""),
    references: String(source.references || source.messageId || source.id || "")
  };
}

if (typeof module !== "undefined") {
  module.exports = {
    sanitizeBody: sanitizeBody,
    formatAddress: formatAddress,
    parseAddressList: parseAddressList,
    parseMessages: parseMessages,
    toSocialEvents: toSocialEvents,
    replyDraft: replyDraft
  };
}

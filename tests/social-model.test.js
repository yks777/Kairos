const test = require("node:test");
const assert = require("node:assert/strict");
const { loadQmlLibrary } = require("./helpers/loadQmlLibrary.js");
const SocialModel = loadQmlLibrary("logic/SocialModel.js");

const now = Date.UTC(2026, 9, 13, 12, 0, 0);

test("social events are normalized, bounded, and deduplicated", () => {
  const rows = SocialModel.mergeEvents([[
    { id: "m-1", platform: "telegram", kind: "message", accountId: "tg-main", timestamp: now / 1000, chat: { id: "chat-1", unread: 2 }, sender: { name: "Ada\u0000 Lovelace" }, body: "Hello" },
    { id: "m-1", platform: "telegram", kind: "message", accountId: "tg-main", timestamp: now, chat: { id: "chat-1", unread: 2 } },
    { id: "bad", platform: "unknown", kind: "message", accountId: "tg-main" }
  ]]);

  assert.equal(rows.length, 1);
  assert.equal(rows[0].timestamp, now);
  assert.equal(rows[0].sender.name, "Ada  Lovelace");
  assert.equal(rows[0].chat.unread, 2);
});

test("unread conversations group by account and chat and preserve the latest preview", () => {
  const events = SocialModel.mergeEvents([[
    { id: "old", platform: "matrix", kind: "message", accountId: "mx-a", accountName: "Work", timestamp: now - 60000, chat: { id: "room-a", name: "Team", unread: 1 }, body: "Earlier" },
    { id: "new", platform: "matrix", kind: "message", accountId: "mx-a", accountName: "Work", timestamp: now - 1000, chat: { id: "room-a", name: "Team", unread: 3 }, body: "Latest" },
    { id: "other", platform: "matrix", kind: "message", accountId: "mx-b", accountName: "Personal", timestamp: now, chat: { id: "room-a", name: "Team", unread: 1 }, body: "Other account" }
  ]]);
  const all = SocialModel.unreadConversations(events, "all", now);
  const one = SocialModel.unreadConversations(events, "mx-a", now);

  assert.equal(all.length, 2);
  assert.equal(one.length, 1);
  assert.equal(one[0].preview, "Latest");
  assert.equal(one[0].unread, 3);
  assert.equal(one[0].chatId, "room-a");
});

test("email threads use unread messages and call views exclude expired events", () => {
  const events = SocialModel.mergeEvents([[
    { id: "mail-1", platform: "email", kind: "email", accountId: "mail-a", timestamp: now - 5000, chat: { id: "thread-a", name: "sender@example.test", unread: 1 }, subject: "Review" },
    { id: "mail-read", platform: "email", kind: "email", accountId: "mail-a", timestamp: now - 4000, chat: { id: "thread-a", unread: 0 }, subject: "Review" },
    { id: "call-old", platform: "signal", kind: "call", accountId: "sig-a", timestamp: now - 25 * 60 * 60 * 1000, callState: "missed" },
    { id: "call-new", platform: "signal", kind: "missed_call", accountId: "sig-a", timestamp: now - 1000 }
  ]]);

  const unread = SocialModel.unreadConversations(events, "mail-a", now);
  const calls = SocialModel.recentCalls(events, "all", now);
  assert.equal(unread.length, 1);
  assert.equal(unread[0].kind, "email");
  assert.deepEqual(calls.map((item) => item.id), ["call-new"]);
  assert.equal(calls[0].callState, "missed");
});

test("ringing lookup, account filter, thread history and glyph helpers are stable", () => {
  const events = SocialModel.mergeEvents([[
    { id: "a", platform: "discord", kind: "message", accountId: "d-1", timestamp: now - 1000, chat: { id: "dm-1", unread: 1 }, body: "One" },
    { id: "b", platform: "discord", kind: "message", accountId: "d-1", timestamp: now, chat: { id: "dm-1", unread: 1 }, body: "Two" },
    { id: "ring", platform: "whatsapp", kind: "call", accountId: "wa-1", timestamp: now, callState: "ringing", chat: { id: "call-1", name: "Contact" } }
  ]]);
  assert.equal(SocialModel.ringingCall(events).id, "ring");
  assert.deepEqual(SocialModel.threadEvents(events, "d-1", "dm-1").map((item) => item.id), ["a", "b"]);
  assert.notEqual(SocialModel.accountGlyph("telegram"), "");
  assert.equal(SocialModel.accountMatches(events.find((item) => item.platform === "discord"), "platform:discord"), true);
});

const test = require("node:test");
const assert = require("node:assert/strict");
const { loadQmlLibrary } = require("./helpers/loadQmlLibrary.js");
const EmailModel = loadQmlLibrary("logic/EmailModel.js");

const timestamp = Date.UTC(2026, 9, 13, 9, 30, 0);

test("email parsing keeps bounded metadata and strips HTML markup", () => {
  const rows = EmailModel.parseMessages([{
    id: "<message-1@example.test>", messageId: "<message-1@example.test>", uid: "42",
    accountId: "mail-a", from: "Ada Lovelace <ada@example.test>", fromEmail: "ada@example.test",
    to: "me@example.test", subject: "A &amp; B", body: "<p>Hello <b>world</b></p><script>ignore()</script>",
    timestamp: timestamp / 1000, unread: 1, hasAttachments: true, attachmentNames: ["agenda.pdf"],
    threadId: "thread-1", references: "<root@example.test>"
  }]);

  assert.equal(rows.length, 1);
  assert.equal(rows[0].uid, "42");
  assert.equal(rows[0].timestamp, timestamp);
  assert.equal(rows[0].body, "Hello world");
  assert.equal(rows[0].hasAttachments, true);
  assert.equal(rows[0].threadId, "thread-1");
});

test("email event conversion preserves per-account thread identity and unread state", () => {
  const parsed = EmailModel.parseMessages([
    { id: "m-1", uid: "7", accountId: "mail-a", from: "Ada <ada@example.test>", fromEmail: "ada@example.test", subject: "Review", body: "Please review", timestamp, unread: 1, threadId: "thread-1" },
    { id: "m-2", uid: "8", accountId: "mail-a", from: "Ada <ada@example.test>", fromEmail: "ada@example.test", subject: "Re: Review", body: "Thanks", timestamp: timestamp + 1000, unread: 0, threadId: "thread-1" }
  ]);
  const events = EmailModel.toSocialEvents(parsed, { id: "mail-a", name: "Work", email: "me@example.test" });

  const unreadEvent = events.find((event) => event.id === "m-1");
  assert.equal(unreadEvent.platform, "email");
  assert.equal(unreadEvent.chat.id, "thread-1");
  assert.equal(unreadEvent.chat.unread, 1);
  assert.equal(unreadEvent.uid, "7");
  assert.equal(unreadEvent.accountName, "Work");
});

test("reply, reply-all, and forward drafts use recipients and safe subject prefixes", () => {
  const original = {
    id: "id-1", messageId: "<id-1@example.test>", from: "Ada Lovelace <ada@example.test>",
    to: "Me <me@example.test>, Bob <bob@example.test>", cc: "Carol <carol@example.test>",
    subject: "Quarterly review", body: "Please see the attached report.", timestamp,
    references: "<root@example.test> <id-1@example.test>"
  };
  const account = { email: "me@example.test" };
  const reply = EmailModel.replyDraft(original, account, "reply");
  const all = EmailModel.replyDraft(original, account, "replyAll");
  const forward = EmailModel.replyDraft(original, account, "forward");

  assert.equal(reply.to, "Ada Lovelace <ada@example.test>");
  assert.equal(reply.subject, "Re: Quarterly review");
  assert.match(reply.body, /> Please see the attached report\./);
  assert.equal(all.to.includes("me@example.test"), false);
  assert.equal(all.to.includes("bob@example.test"), true);
  assert.equal(all.to.includes("carol@example.test"), true);
  assert.equal(forward.to, "");
  assert.equal(forward.subject, "Fwd: Quarterly review");
  assert.equal(forward.originalId, "<id-1@example.test>");
});

test("malformed email payloads and addresses are handled without exceptions", () => {
  assert.deepEqual(EmailModel.parseMessages("not json"), []);
  assert.deepEqual(EmailModel.parseAddressList("nobody"), []);
  assert.deepEqual(EmailModel.parseAddressList("A <a@example.test>, a@example.test"), ["A <a@example.test>"]);
});

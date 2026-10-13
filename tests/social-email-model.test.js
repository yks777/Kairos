const test = require("node:test");
const assert = require("node:assert/strict");
const { loadQmlLibrary } = require("./helpers/loadQmlLibrary.js");
const Model = loadQmlLibrary("logic/Model.js");

test("email account hosts sanitize through the existing helper and secrets are never state fields", () => {
  const settings = Model.sanitizeSettings({
    email: {
      password: "top-level-secret",
      credentials: { refreshToken: "nested-secret" },
      accounts: [{
        id: "mail-test",
        name: "Work",
        email: "user@example.test",
        username: "user@example.test",
        imapHost: "IMAP.Example.test",
        imapPort: 993,
        smtpHost: "SMTP.Example.test",
        smtpPort: 465,
        password: "must-not-persist",
        secret: "must-not-persist-either"
      }]
    }
  });

  assert.equal(settings.email.accounts[0].imapHost, "imap.example.test");
  assert.equal(settings.email.accounts[0].smtpHost, "smtp.example.test");
  assert.equal(Object.hasOwn(settings.email.accounts[0], "password"), false);
  assert.equal(Object.hasOwn(settings.email.accounts[0], "secret"), false);
  assert.equal(Object.hasOwn(settings.email, "password"), false);
  assert.equal(Object.hasOwn(settings.email, "credentials"), false);
});

test("generic settings section sanitization handles valid and invalid section names", () => {
  const social = Model.sanitizeSettingsSection("social", { telegram: true, notifyMessages: false, showPreview: true });
  assert.equal(social.telegram, true);
  assert.equal(social.notifyMessages, false);
  assert.equal(social.showPreview, true);
  assert.equal(Model.sanitizeSettingsSection("not-a-section", {}), null);
});

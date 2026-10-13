import contextlib
import email.message
import importlib.machinery
import importlib.util
import io
import json
import pathlib
import sys
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "email-fetch"
LOADER = importlib.machinery.SourceFileLoader("kairos_email_fetch", str(SCRIPT))
SPEC = importlib.util.spec_from_loader("kairos_email_fetch", LOADER)
assert SPEC and SPEC.loader
EMAIL_FETCH = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(EMAIL_FETCH)


class FakeImap:
    def __init__(self):
        self.selected = []
        self.operations = []

    def select(self, mailbox, readonly=False):
        self.selected.append((mailbox, readonly))
        return "OK", [b"2"]

    def uid(self, operation, uid, *args):
        self.operations.append((operation, uid, args))
        return "OK", [b"1"]

    def logout(self):
        return "BYE", [b"logout"]


class EmailFetchTests(unittest.TestCase):
    def test_thread_key_groups_replies_by_references_not_subject_alone(self):
        root = {"Message-ID": "<root@example.test>", "Subject": "Same subject"}
        reply = {
            "Message-ID": "<reply@example.test>",
            "References": "<root@example.test> <parent@example.test>",
            "Subject": "Re: Same subject",
        }
        unrelated = {"Message-ID": "<other@example.test>", "Subject": "Same subject"}
        self.assertEqual(EMAIL_FETCH.thread_key(root), EMAIL_FETCH.thread_key(reply))
        self.assertNotEqual(EMAIL_FETCH.thread_key(root), EMAIL_FETCH.thread_key(unrelated))

    def test_parse_message_preserves_uid_and_attachment_metadata(self):
        message = email.message.EmailMessage()
        message["Message-ID"] = "<mail-1@example.test>"
        message["From"] = "Ada Lovelace <ada@example.test>"
        message["To"] = "me@example.test"
        message["Subject"] = "Daily note"
        message["Date"] = "Tue, 13 Oct 2026 09:30:00 +0000"
        message.set_content("Plain text body")
        message.add_attachment(b"sample", maintype="text", subtype="plain", filename="note.txt")

        parsed = EMAIL_FETCH.parse_message(
            message.as_bytes(), {"id": "mail-a", "name": "Work"}, "52"
        )
        self.assertIsNotNone(parsed)
        self.assertEqual(parsed["uid"], "52")
        self.assertEqual(parsed["accountId"], "mail-a")
        self.assertTrue(parsed["hasAttachments"])
        self.assertEqual(parsed["attachmentNames"], ["note.txt"])

    def test_mark_read_only_stores_validated_uids(self):
        fake = FakeImap()
        old_stdin = sys.stdin
        output = io.StringIO()
        original_keyring = EMAIL_FETCH.keyring_secret
        original_connect = EMAIL_FETCH.connect_imap
        try:
            sys.stdin = io.StringIO(json.dumps({"uids": ["12", "abc", "12", "13"]}))
            EMAIL_FETCH.keyring_secret = lambda account_id: "secret"
            EMAIL_FETCH.connect_imap = lambda account, secret: fake
            with contextlib.redirect_stdout(output):
                result = EMAIL_FETCH.mark_read([
                    "mark-read", "mail-a", "imap.example.test", "993", "me@example.test"
                ])
        finally:
            sys.stdin = old_stdin
            EMAIL_FETCH.keyring_secret = original_keyring
            EMAIL_FETCH.connect_imap = original_connect

        self.assertEqual(result, 0)
        self.assertEqual(fake.selected, [("INBOX", False)])
        self.assertEqual([op[1] for op in fake.operations], ["12", "13"])
        self.assertEqual(fake.operations[0][0], "store")
        self.assertIn("+FLAGS.SILENT", fake.operations[0][2])
        self.assertEqual(json.loads(output.getvalue()), {"ok": True, "uids": ["12", "13"]})

    def test_mark_read_rejects_invalid_account_before_connecting(self):
        output = io.StringIO()
        old_stdin = sys.stdin
        try:
            sys.stdin = io.StringIO('{"uids":["1"]}')
            with contextlib.redirect_stdout(output):
                result = EMAIL_FETCH.mark_read([
                    "mark-read", "bad/id", "imap.example.test", "993", "me@example.test"
                ])
        finally:
            sys.stdin = old_stdin
        self.assertEqual(result, 2)
        self.assertFalse(json.loads(output.getvalue())["ok"])


if __name__ == "__main__":
    unittest.main()

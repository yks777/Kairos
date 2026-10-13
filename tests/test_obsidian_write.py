import json
import os
import pathlib
import subprocess
import sys
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "obsidian-write"


class ObsidianWriteTests(unittest.TestCase):
    def run_writer(self, path, content):
        return subprocess.run(
            [sys.executable, str(SCRIPT), str(path)],
            input=content,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=False,
        )

    def test_creates_and_atomically_replaces_note_content(self):
        with tempfile.TemporaryDirectory() as temporary:
            target = pathlib.Path(temporary) / "Daily Notes" / "2026-10-13.md"
            first = self.run_writer(target, "# First note\n\n- [ ] One task\n")
            self.assertEqual(first.returncode, 0)
            self.assertEqual(json.loads(first.stdout), {"ok": True, "error": ""})
            self.assertEqual(target.read_text(), "# First note\n\n- [ ] One task\n")
            self.assertEqual(target.stat().st_mode & 0o777, 0o600)

            second = self.run_writer(target, "# Updated\n")
            self.assertEqual(second.returncode, 0)
            self.assertEqual(target.read_text(), "# Updated\n")

    def test_preserves_existing_file_permissions(self):
        with tempfile.TemporaryDirectory() as temporary:
            target = pathlib.Path(temporary) / "note.md"
            target.write_text("old")
            os.chmod(target, 0o640)
            result = self.run_writer(target, "new")
            self.assertEqual(result.returncode, 0)
            self.assertEqual(target.stat().st_mode & 0o777, 0o640)

    def test_rejects_relative_path_and_oversized_content(self):
        relative = self.run_writer(pathlib.Path("relative.md"), "content")
        self.assertNotEqual(relative.returncode, 0)
        self.assertFalse(json.loads(relative.stdout)["ok"])

        with tempfile.TemporaryDirectory() as temporary:
            target = pathlib.Path(temporary) / "large.md"
            oversized = self.run_writer(target, "x" * (2 * 1024 * 1024 + 1))
            self.assertNotEqual(oversized.returncode, 0)
            self.assertFalse(json.loads(oversized.stdout)["ok"])
            self.assertFalse(target.exists())


if __name__ == "__main__":
    unittest.main()

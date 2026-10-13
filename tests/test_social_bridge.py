import contextlib
import importlib.machinery
import importlib.util
import io
import json
import pathlib
import unittest
from unittest import mock

ROOT = pathlib.Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "social-bridge"
LOADER = importlib.machinery.SourceFileLoader("kairos_social_bridge", str(SCRIPT))
SPEC = importlib.util.spec_from_loader("kairos_social_bridge", LOADER)
assert SPEC and SPEC.loader
SOCIAL_BRIDGE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(SOCIAL_BRIDGE)


class SocialBridgeTests(unittest.TestCase):
    def test_missing_local_adapter_reports_unavailable_without_synthetic_events(self):
        output = io.StringIO()
        with mock.patch.object(SOCIAL_BRIDGE.shutil, "which", return_value=None):
            with contextlib.redirect_stdout(output):
                result = SOCIAL_BRIDGE.main(["capabilities"])

        payload = json.loads(output.getvalue())
        self.assertEqual(result, 0)
        self.assertFalse(payload["ok"])
        self.assertFalse(payload["available"])
        self.assertEqual(payload["accounts"], [])
        self.assertEqual(payload["platforms"], {})
        self.assertIn("No compatible", payload["error"])


if __name__ == "__main__":
    unittest.main()

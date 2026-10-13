import importlib.machinery
import importlib.util
import pathlib
import unittest
from unittest import mock


ROOT = pathlib.Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "notification-sound"
LOADER = importlib.machinery.SourceFileLoader("kairos_notification_sound", str(SCRIPT))
SPEC = importlib.util.spec_from_loader("kairos_notification_sound", LOADER)
assert SPEC and SPEC.loader
SOUND = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(SOUND)


class NotificationSoundTests(unittest.TestCase):
    def test_prefers_pipewire_and_first_available_freedesktop_sound(self):
        paths = iter(SOUND.SOUND_FILES)
        existing = next(paths)
        which = {"pw-play": "/usr/bin/pw-play", "paplay": "/usr/bin/paplay"}
        with mock.patch.object(SOUND.shutil, "which", side_effect=which.get), mock.patch.object(
            SOUND.os.path, "isfile", side_effect=lambda path: path == existing
        ):
            self.assertEqual(SOUND.sound_command(), ["/usr/bin/pw-play", existing])

    def test_uses_paplay_when_pipewire_player_is_missing(self):
        sound_file = SOUND.SOUND_FILES[1]
        with mock.patch.object(
            SOUND.shutil, "which", side_effect=lambda name: "/usr/bin/paplay" if name == "paplay" else None
        ), mock.patch.object(SOUND.os.path, "isfile", side_effect=lambda path: path == sound_file):
            self.assertEqual(SOUND.sound_command(), ["/usr/bin/paplay", sound_file])

    def test_falls_back_to_canberra_theme_event_without_audio_file(self):
        with mock.patch.object(
            SOUND.shutil,
            "which",
            side_effect=lambda name: "/usr/bin/canberra-gtk-play" if name == "canberra-gtk-play" else None,
        ), mock.patch.object(SOUND.os.path, "isfile", return_value=False):
            self.assertEqual(
                SOUND.sound_command(),
                ["/usr/bin/canberra-gtk-play", "-i", SOUND.SOUND_EVENT],
            )

    def test_returns_unavailable_when_no_supported_player_exists(self):
        with mock.patch.object(SOUND.shutil, "which", return_value=None), mock.patch.object(
            SOUND.os.path, "isfile", return_value=False
        ):
            self.assertIsNone(SOUND.sound_command())
            self.assertFalse(SOUND.play_sound())

    def test_starts_the_player_with_argv_and_no_shell(self):
        command = ["/usr/bin/pw-play", SOUND.SOUND_FILES[0]]
        with mock.patch.object(SOUND, "sound_command", return_value=command), mock.patch.object(
            SOUND.subprocess, "Popen"
        ) as popen:
            self.assertTrue(SOUND.play_sound())
        args, kwargs = popen.call_args
        self.assertEqual(args, (command,))
        self.assertNotIn("shell", kwargs)
        self.assertEqual(kwargs["stdin"], SOUND.subprocess.DEVNULL)
        self.assertTrue(kwargs["start_new_session"])

    def test_reports_player_start_failure(self):
        with mock.patch.object(SOUND, "sound_command", return_value=["/usr/bin/pw-play", "sound.oga"]), mock.patch.object(
            SOUND.subprocess, "Popen", side_effect=OSError("unavailable")
        ):
            self.assertFalse(SOUND.play_sound())


if __name__ == "__main__":
    unittest.main()

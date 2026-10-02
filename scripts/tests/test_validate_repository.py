from __future__ import annotations

import importlib.util
import json
import plistlib
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

MODULE_PATH = Path(__file__).resolve().parents[1] / "validate_repository.py"
SPEC = importlib.util.spec_from_file_location("validate_repository", MODULE_PATH)
assert SPEC and SPEC.loader
VALIDATOR = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(VALIDATOR)


class ExpeditionResourceTests(unittest.TestCase):
    def test_missing_offline_movie_and_planet_are_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            resources = root / "Sources/AstroContent/Resources"
            resources.mkdir(parents=True)
            images = root / "Sources/AstroUI/Resources/DiscoveryImages"
            images.mkdir(parents=True)
            (images / "example.jpg").write_bytes(b"test image")
            planets = ["mercury", "venus", "earth", "mars", "jupiter", "saturn", "uranus", "neptune"]
            missions = [
                {"id": f"{planet}-{index}", "destinationID": planet,
                 "cards": [{"imageName": "example"}],
                 "deepDive": {"imageName": "example"}}
                for planet in planets for index in range(3)
            ]
            movies = [
                {"id": planet, "destinationID": planet,
                 "resourceName": f"{planet}-lesson", "segments": [], "fallbackCards": []}
                for planet in planets
            ]
            movie_directory = root / "Sources/AstroUI/Resources/LearningVideos"
            movie_directory.mkdir(parents=True)
            for planet in planets[:-1]:
                (movie_directory / f"{planet}-lesson.mp4").write_bytes(b"test movie")
            (resources / "planet-missions.json").write_text(json.dumps(missions), encoding="utf-8")
            (resources / "video-lessons.json").write_text(json.dumps(movies), encoding="utf-8")
            errors: list[str] = []
            with patch.object(VALIDATOR, "ROOT", root):
                VALIDATOR.validate_expedition_resources(errors)
            self.assertEqual(errors, ["Video lesson neptune requires a bundled offline MP4"])
            (movie_directory / "neptune-lesson.mp4").write_bytes(b"test movie")
            (resources / "planet-missions.json").write_text(json.dumps(missions[:-1]), encoding="utf-8")
            errors = []
            with patch.object(VALIDATOR, "ROOT", root):
                VALIDATOR.validate_expedition_resources(errors)
            self.assertEqual(errors, ["Planet expeditions require three missions for each of the eight planets"])


class RepositorySecurityControlTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary_directory.name)

    def tearDown(self) -> None:
        self.temporary_directory.cleanup()

    def test_generated_and_signing_artifacts_are_rejected(self) -> None:
        generated = self.root / "DerivedData/build.log"
        signing_key = self.root / "AuthKey_EXAMPLE.p8"
        generated.parent.mkdir()
        generated.write_text("build output", encoding="utf-8")
        signing_key.write_text("placeholder", encoding="utf-8")
        errors: list[str] = []

        with patch.object(VALIDATOR, "ROOT", self.root):
            VALIDATOR.validate_paths([generated, signing_key], errors)

        self.assertEqual(len(errors), 2)
        self.assertTrue(any("Generated or local directory" in error for error in errors))
        self.assertTrue(any("App Store Connect private key" in error for error in errors))

    def test_credential_patterns_are_rejected(self) -> None:
        source = self.root / "Sources/example.swift"
        source.parent.mkdir()
        fake_token = "gh" + "p_" + ("A" * 36)
        source.write_text(f'let token = "{fake_token}"', encoding="utf-8")
        errors: list[str] = []

        with patch.object(VALIDATOR, "ROOT", self.root):
            VALIDATOR.validate_secrets([source], errors)

        self.assertEqual(len(errors), 1)
        self.assertIn("Credential-like content", errors[0])

    def test_unpinned_action_is_rejected(self) -> None:
        workflow_directory = self.root / ".github/workflows"
        workflow_directory.mkdir(parents=True)
        workflow = workflow_directory / "unsafe.yml"
        workflow.write_text(
            """
name: Unsafe
on: push
permissions:
  contents: read
jobs:
  test:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v6
""",
            encoding="utf-8",
        )
        errors: list[str] = []

        with patch.object(VALIDATOR, "ROOT", self.root):
            VALIDATOR.validate_workflows(errors)

        self.assertEqual(len(errors), 1)
        self.assertIn("full commit SHA", errors[0])

    def test_privileged_pull_request_trigger_is_rejected(self) -> None:
        workflow_directory = self.root / ".github/workflows"
        workflow_directory.mkdir(parents=True)
        workflow = workflow_directory / "unsafe.yml"
        workflow.write_text(
            """
name: Unsafe
on:
  pull_request_target:
permissions:
  contents: read
jobs: {}
""",
            encoding="utf-8",
        )
        errors: list[str] = []

        with patch.object(VALIDATOR, "ROOT", self.root):
            VALIDATOR.validate_workflows(errors)

        self.assertEqual(len(errors), 1)
        self.assertIn("pull_request_target", errors[0])

    def validate_privacy(self, accessed_apis: object, **overrides: object) -> list[str]:
        path = self.root / "Apps/Shared/PrivacyInfo.xcprivacy"
        path.parent.mkdir(parents=True, exist_ok=True)
        manifest = {
            "NSPrivacyTracking": False,
            "NSPrivacyCollectedDataTypes": [],
            "NSPrivacyAccessedAPITypes": accessed_apis,
        }
        manifest.update(overrides)
        path.write_bytes(plistlib.dumps(manifest))
        errors: list[str] = []
        with patch.object(VALIDATOR, "ROOT", self.root):
            VALIDATOR.validate_privacy_manifest(errors)
        return errors

    def test_privacy_requires_user_defaults_reason(self) -> None:
        for accessed_apis in (
            [],
            [{"NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategoryUserDefaults"}],
            [{
                "NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategoryUserDefaults",
                "NSPrivacyAccessedAPITypeReasons": ["1C8F.1"],
            }],
            [{
                "NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategoryFileTimestamp",
                "NSPrivacyAccessedAPITypeReasons": ["CA92.1"],
            }],
            "NSPrivacyAccessedAPICategoryUserDefaults",
        ):
            with self.subTest(accessed_apis=accessed_apis):
                errors = self.validate_privacy(accessed_apis)
                self.assertEqual(len(errors), 1)
                self.assertIn("UserDefaults API access with reason CA92.1", errors[0])

    def test_privacy_accepts_app_local_user_defaults_declaration(self) -> None:
        errors = self.validate_privacy([{
            "NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategoryUserDefaults",
            "NSPrivacyAccessedAPITypeReasons": ["CA92.1"],
        }])
        self.assertEqual(errors, [])

    def test_required_api_reason_does_not_permit_tracking_or_collection(self) -> None:
        errors = self.validate_privacy(
            [{
                "NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategoryUserDefaults",
                "NSPrivacyAccessedAPITypeReasons": ["CA92.1"],
            }],
            NSPrivacyTracking=True,
            NSPrivacyCollectedDataTypes=[{"NSPrivacyCollectedDataType": "Location"}],
        )
        self.assertEqual(len(errors), 2)
        self.assertTrue(any("tracking disabled" in error for error in errors))
        self.assertTrue(any("collected data types" in error for error in errors))

    def test_apple_metadata_rejects_invalid_controller_and_ipad_values(self) -> None:
        ios_plist = self.root / "Apps/iOS/Info.plist"
        tvos_plist = self.root / "Apps/tvOS/Info.plist"
        ios_plist.parent.mkdir(parents=True)
        tvos_plist.parent.mkdir(parents=True)
        ios_plist.write_text(
            """
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
  <key>GCRequiresControllerUserInteraction</key>
  <false/>
  <key>UISupportedInterfaceOrientations</key>
  <array>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
  </array>
</dict>
</plist>
""".strip(),
            encoding="utf-8",
        )
        tvos_plist.write_text(
            """
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
  <key>GCSupportsControllerUserInteraction</key>
  <true/>
  <key>TVTopShelfImage</key>
  <dict>
    <key>TVTopShelfPrimaryImage</key>
    <string>Top Shelf Image</string>
    <key>TVTopShelfPrimaryImageWide</key>
    <string>Top Shelf Image Wide</string>
  </dict>
</dict>
</plist>
""".strip(),
            encoding="utf-8",
        )
        errors: list[str] = []

        with patch.object(VALIDATOR, "ROOT", self.root):
            VALIDATOR.validate_apple_metadata(errors)

        self.assertEqual(len(errors), 2)
        self.assertTrue(
            any("must be a dictionary" in error for error in errors)
        )
        self.assertTrue(
            any("iPad multitasking orientations" in error for error in errors)
        )

    def test_apple_metadata_accepts_platform_specific_valid_values(self) -> None:
        ios_plist = self.root / "Apps/iOS/Info.plist"
        tvos_plist = self.root / "Apps/tvOS/Info.plist"
        ios_plist.parent.mkdir(parents=True)
        tvos_plist.parent.mkdir(parents=True)
        valid_orientations = "\n".join(
            f"    <string>{orientation}</string>"
            for orientation in sorted(VALIDATOR.REQUIRED_IPAD_ORIENTATIONS)
        )
        ios_plist.write_text(
            f"""
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
  <key>UISupportedInterfaceOrientations~ipad</key>
  <array>
{valid_orientations}
  </array>
</dict>
</plist>
""".strip(),
            encoding="utf-8",
        )
        tvos_plist.write_text(
            """
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
  <key>GCSupportsControllerUserInteraction</key>
  <true/>
  <key>TVTopShelfImage</key>
  <dict>
    <key>TVTopShelfPrimaryImage</key>
    <string>Top Shelf Image</string>
    <key>TVTopShelfPrimaryImageWide</key>
    <string>Top Shelf Image Wide</string>
  </dict>
</dict>
</plist>
""".strip(),
            encoding="utf-8",
        )
        errors: list[str] = []

        with patch.object(VALIDATOR, "ROOT", self.root):
            VALIDATOR.validate_apple_metadata(errors)

        self.assertEqual(errors, [])

    def test_apple_metadata_requires_tvos_top_shelf_images(self) -> None:
        ios_plist = self.root / "Apps/iOS/Info.plist"
        tvos_plist = self.root / "Apps/tvOS/Info.plist"
        ios_plist.parent.mkdir(parents=True)
        tvos_plist.parent.mkdir(parents=True)
        valid_orientations = "\n".join(
            f"    <string>{orientation}</string>"
            for orientation in sorted(VALIDATOR.REQUIRED_IPAD_ORIENTATIONS)
        )
        ios_plist.write_text(
            f"""
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
  <key>UISupportedInterfaceOrientations~ipad</key>
  <array>
{valid_orientations}
  </array>
</dict>
</plist>
""".strip(),
            encoding="utf-8",
        )
        tvos_plist.write_text(
            """
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
  <key>GCSupportsControllerUserInteraction</key>
  <true/>
</dict>
</plist>
""".strip(),
            encoding="utf-8",
        )
        errors: list[str] = []

        with patch.object(VALIDATOR, "ROOT", self.root):
            VALIDATOR.validate_apple_metadata(errors)

        self.assertEqual(len(errors), 1)
        self.assertIn("Top Shelf image assets", errors[0])


if __name__ == "__main__":
    unittest.main()

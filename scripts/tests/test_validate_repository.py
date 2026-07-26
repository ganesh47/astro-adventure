from __future__ import annotations

import importlib.util
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

MODULE_PATH = Path(__file__).resolve().parents[1] / "validate_repository.py"
SPEC = importlib.util.spec_from_file_location("validate_repository", MODULE_PATH)
assert SPEC and SPEC.loader
VALIDATOR = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(VALIDATOR)


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

#!/usr/bin/env python3
"""Validate the public, buildable Astro Adventure repository."""

from __future__ import annotations

import csv
import json
import plistlib
import re
import subprocess
import sys
from pathlib import Path
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_PATHS = (
    ".github/workflows/ci.yml",
    ".github/workflows/codeql.yml",
    ".github/workflows/dependency-review.yml",
    ".github/workflows/pr-hygiene.yml",
    ".github/workflows/security.yml",
    "Package.swift",
    "project.yml",
    "AstroAdventure.xcodeproj/project.pbxproj",
    "Apps/iOS/AstroAdventureIOSApp.swift",
    "Apps/tvOS/AstroAdventureTVApp.swift",
    "Apps/Shared/PrivacyInfo.xcprivacy",
    (
        "Apps/Shared/Assets.xcassets/App Icon & Top Shelf Image.brandassets/"
        "Top Shelf Image.imageset/Top Shelf Image.png"
    ),
    (
        "Apps/Shared/Assets.xcassets/App Icon & Top Shelf Image.brandassets/"
        "Top Shelf Image.imageset/Top Shelf Image@2x.png"
    ),
    (
        "Apps/Shared/Assets.xcassets/App Icon & Top Shelf Image.brandassets/"
        "Top Shelf Image Wide.imageset/Top Shelf Image Wide.png"
    ),
    (
        "Apps/Shared/Assets.xcassets/App Icon & Top Shelf Image.brandassets/"
        "Top Shelf Image Wide.imageset/Top Shelf Image Wide@2x.png"
    ),
    "Sources/AstroGameCore/MissionSession.swift",
    "Sources/AstroContent/Resources/lessons.json",
    "assets/manifest/assets.csv",
    "docs/architecture.md",
    "docs/ROADMAP.md",
)

FORBIDDEN_PARTS = {
    ".build",
    "DerivedData",
    "xcuserdata",
    "artifacts",
    "Releases",
}

FORBIDDEN_SUFFIXES = {
    ".app",
    ".ipa",
    ".xcarchive",
    ".dSYM",
    ".mobileprovision",
    ".provisionprofile",
    ".p12",
    ".p8",
    ".pem",
    ".key",
    ".xcresult",
}

SECRET_PATTERNS = (
    re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"),
    re.compile(r"\bgh[oprsu]_[A-Za-z0-9_]{30,}\b"),
    re.compile(r"\bAKIA[0-9A-Z]{16}\b"),
)

ACTION_USE_PATTERN = re.compile(
    r"^\s*(?:-\s+)?uses:\s*(?P<action>[^@\s]+)@(?P<ref>[^\s#]+)",
    re.MULTILINE,
)

MANIFEST_COLUMNS = (
    "id",
    "title",
    "type",
    "repository_path",
    "source_url",
    "license",
    "author",
    "ai_generated",
    "tool",
    "notes",
    "approved_for_public_repo",
    "approved_for_apple_build",
    "review_status",
    "rejection_reason",
)

ASSET_TYPES = {
    "image",
    "audio",
    "model",
    "material",
    "font",
    "video",
    "text",
    "package",
    "other",
}

LICENSES = {
    "public-domain",
    "cc0",
    "cc-by-4.0",
    "mit",
    "apache-2.0",
    "bsd-3-clause",
    "original-project-owned",
    "ai-generated-project-owned",
    "proprietary-private-only",
    "unknown",
}

REQUIRED_IPAD_ORIENTATIONS = {
    "UIInterfaceOrientationPortrait",
    "UIInterfaceOrientationPortraitUpsideDown",
    "UIInterfaceOrientationLandscapeLeft",
    "UIInterfaceOrientationLandscapeRight",
}


def tracked_and_untracked_files() -> list[Path]:
    result = subprocess.run(
        [
            "git",
            "ls-files",
            "--cached",
            "--others",
            "--exclude-standard",
            "-z",
        ],
        cwd=ROOT,
        check=True,
        capture_output=True,
    )
    return [
        ROOT / path.decode()
        for path in result.stdout.split(b"\0")
        if path and (ROOT / path.decode()).is_file()
    ]


def validate_required_paths(errors: list[str]) -> None:
    for relative_path in REQUIRED_PATHS:
        if not (ROOT / relative_path).is_file():
            errors.append(f"Missing required file: {relative_path}")


def validate_paths(files: list[Path], errors: list[str]) -> None:
    for path in files:
        relative = path.relative_to(ROOT)
        if any(part in FORBIDDEN_PARTS for part in relative.parts):
            errors.append(f"Generated or local directory is tracked: {relative}")
        if path.name.startswith("AuthKey_") and path.suffix == ".p8":
            errors.append(f"App Store Connect private key is tracked: {relative}")
        elif any(path.name.endswith(suffix) for suffix in FORBIDDEN_SUFFIXES):
            errors.append(f"Private or generated artifact is tracked: {relative}")


def validate_secrets(files: list[Path], errors: list[str]) -> None:
    text_suffixes = {
        ".csv",
        ".json",
        ".md",
        ".pbxproj",
        ".plist",
        ".py",
        ".sh",
        ".swift",
        ".xcprivacy",
        ".xcscheme",
        ".yml",
        ".yaml",
    }
    for path in files:
        if path.suffix not in text_suffixes or path.stat().st_size > 2_000_000:
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        for pattern in SECRET_PATTERNS:
            if pattern.search(text):
                errors.append(
                    f"Credential-like content found in {path.relative_to(ROOT)}"
                )


def validate_workflows(errors: list[str]) -> None:
    workflow_directory = ROOT / ".github/workflows"
    for workflow_path in sorted(workflow_directory.glob("*.y*ml")):
        text = workflow_path.read_text(encoding="utf-8")
        relative_path = workflow_path.relative_to(ROOT)

        if re.search(r"^\s*pull_request_target\s*:", text, re.MULTILINE):
            errors.append(
                f"Privileged pull_request_target trigger is not allowed: {relative_path}"
            )
        if not re.search(r"^permissions\s*:", text, re.MULTILINE):
            errors.append(f"Workflow must declare top-level permissions: {relative_path}")

        for match in ACTION_USE_PATTERN.finditer(text):
            action = match.group("action")
            reference = match.group("ref")
            if action.startswith("./"):
                continue
            if not re.fullmatch(r"[0-9a-f]{40}", reference):
                errors.append(
                    f"Third-party action must use a full commit SHA in "
                    f"{relative_path}: {action}@{reference}"
                )


def validate_manifest(errors: list[str]) -> None:
    manifest_path = ROOT / "assets/manifest/assets.csv"
    with manifest_path.open(newline="", encoding="utf-8") as manifest_file:
        reader = csv.DictReader(manifest_file)
        if tuple(reader.fieldnames or ()) != MANIFEST_COLUMNS:
            errors.append("Asset manifest columns do not match the required schema")
            return

        seen_ids: set[str] = set()
        for line_number, row in enumerate(reader, start=2):
            asset_id = row["id"]
            prefix = f"Asset manifest line {line_number} ({asset_id or 'missing id'})"

            if not re.fullmatch(r"[a-z0-9_]+", asset_id):
                errors.append(f"{prefix}: id must use lowercase letters, numbers, underscores")
            if asset_id in seen_ids:
                errors.append(f"{prefix}: duplicate id")
            seen_ids.add(asset_id)

            if row["type"] not in ASSET_TYPES:
                errors.append(f"{prefix}: unsupported type {row['type']!r}")
            if row["license"] not in LICENSES:
                errors.append(f"{prefix}: unsupported license {row['license']!r}")
            if row["ai_generated"] not in {"yes", "no"}:
                errors.append(f"{prefix}: ai_generated must be yes or no")
            if row["approved_for_public_repo"] not in {"yes", "no", "needs-review"}:
                errors.append(f"{prefix}: invalid public approval")
            if row["approved_for_apple_build"] not in {"yes", "no", "not-reviewed"}:
                errors.append(f"{prefix}: invalid Apple build approval")
            if row["review_status"] not in {"accepted", "needs-review", "rejected"}:
                errors.append(f"{prefix}: invalid review status")

            repository_path = row["repository_path"]
            if repository_path:
                asset_path = ROOT / repository_path
                if not asset_path.is_file():
                    errors.append(f"{prefix}: repository_path does not exist")
                if row["approved_for_public_repo"] != "yes":
                    errors.append(f"{prefix}: committed assets require public approval")
                if row["review_status"] != "accepted":
                    errors.append(f"{prefix}: committed assets require accepted review")

            if row["review_status"] == "rejected":
                if repository_path:
                    errors.append(f"{prefix}: rejected assets cannot have a repository path")
                if row["approved_for_public_repo"] != "no":
                    errors.append(f"{prefix}: rejected assets must have public approval no")
                if not row["rejection_reason"]:
                    errors.append(f"{prefix}: rejected assets require a rejection reason")


def validate_lessons(errors: list[str]) -> None:
    lesson_path = ROOT / "Sources/AstroContent/Resources/lessons.json"
    try:
        lessons = json.loads(lesson_path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError) as error:
        errors.append(f"Lesson catalog is not valid JSON: {error}")
        return

    if not isinstance(lessons, list) or not lessons:
        errors.append("Lesson catalog must be a non-empty array")
        return

    seen_ids: set[str] = set()
    expected_choices = {"ages4To6": 2, "ages7To9": 3, "ages10To12": 3}
    for lesson in lessons:
        lesson_id = lesson.get("id", "")
        if lesson_id in seen_ids:
            errors.append(f"Lesson catalog has duplicate id: {lesson_id}")
        seen_ids.add(lesson_id)

        source = lesson.get("source", {})
        if source.get("reviewStatus") != "reviewed":
            errors.append(f"Lesson {lesson_id} does not have a reviewed source")
        if not str(source.get("url", "")).startswith("https://"):
            errors.append(f"Lesson {lesson_id} source must use HTTPS")

        content = lesson.get("content", {})
        for age_band, choice_count in expected_choices.items():
            quiz = content.get(age_band, {}).get("quiz", {})
            choices = quiz.get("choices", [])
            if len(choices) != choice_count:
                errors.append(
                    f"Lesson {lesson_id} {age_band} must have {choice_count} choices"
                )
            choice_ids = {choice.get("id") for choice in choices}
            if quiz.get("correctChoiceID") not in choice_ids:
                errors.append(
                    f"Lesson {lesson_id} {age_band} correct choice is missing"
                )


def validate_privacy_manifest(errors: list[str]) -> None:
    path = ROOT / "Apps/Shared/PrivacyInfo.xcprivacy"
    try:
        with path.open("rb") as privacy_file:
            manifest = plistlib.load(privacy_file)
    except (OSError, plistlib.InvalidFileException) as error:
        errors.append(f"Privacy manifest is invalid: {error}")
        return

    if manifest.get("NSPrivacyTracking") is not False:
        errors.append("Privacy manifest must declare tracking disabled")
    if manifest.get("NSPrivacyCollectedDataTypes") != []:
        errors.append("M0 must not declare collected data types")


def validate_apple_metadata(errors: list[str]) -> None:
    plist_paths = (
        ROOT / "Apps/iOS/Info.plist",
        ROOT / "Apps/tvOS/Info.plist",
    )
    plists: dict[Path, dict[str, object]] = {}
    for path in plist_paths:
        try:
            with path.open("rb") as plist_file:
                plist = plistlib.load(plist_file)
        except (OSError, plistlib.InvalidFileException) as error:
            errors.append(
                f"{path.relative_to(ROOT)} is not a valid property list: {error}"
            )
            continue

        plists[path] = plist
        controller_requirement = plist.get("GCRequiresControllerUserInteraction")
        if controller_requirement is not None and not isinstance(
            controller_requirement, dict
        ):
            errors.append(
                f"{path.relative_to(ROOT)} "
                "GCRequiresControllerUserInteraction must be a dictionary"
            )

    ios_path = ROOT / "Apps/iOS/Info.plist"
    ios_plist = plists.get(ios_path)
    if ios_plist is None:
        return

    ipad_orientations = set(
        ios_plist.get(
            "UISupportedInterfaceOrientations~ipad",
            ios_plist.get("UISupportedInterfaceOrientations", []),
        )
    )
    missing_orientations = REQUIRED_IPAD_ORIENTATIONS - ipad_orientations
    if missing_orientations:
        errors.append(
            "Apps/iOS/Info.plist must support all iPad multitasking orientations; "
            f"missing: {', '.join(sorted(missing_orientations))}"
        )

    tvos_path = ROOT / "Apps/tvOS/Info.plist"
    tvos_plist = plists.get(tvos_path)
    if tvos_plist is None:
        return

    top_shelf = tvos_plist.get("TVTopShelfImage")
    expected_top_shelf = {
        "TVTopShelfPrimaryImage": "Top Shelf Image",
        "TVTopShelfPrimaryImageWide": "Top Shelf Image Wide",
    }
    if top_shelf != expected_top_shelf:
        errors.append(
            "Apps/tvOS/Info.plist must declare standard and wide Top Shelf "
            "image assets"
        )


def validate_markdown_links(errors: list[str]) -> None:
    link_pattern = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")
    for markdown_path in ROOT.rglob("*.md"):
        if any(part in {".build", ".git"} for part in markdown_path.parts):
            continue
        text = markdown_path.read_text(encoding="utf-8")
        for raw_target in link_pattern.findall(text):
            target = raw_target.strip().split(maxsplit=1)[0].strip("<>")
            if (
                not target
                or target.startswith(("#", "http://", "https://", "mailto:"))
            ):
                continue

            relative_target = unquote(target.split("#", maxsplit=1)[0])
            resolved = (markdown_path.parent / relative_target).resolve()
            if resolved.exists():
                continue
            if not resolved.suffix and resolved.with_suffix(".md").exists():
                continue
            errors.append(
                f"Broken local Markdown link in "
                f"{markdown_path.relative_to(ROOT)}: {target}"
            )


def main() -> int:
    errors: list[str] = []
    files = tracked_and_untracked_files()

    validate_required_paths(errors)
    validate_paths(files, errors)
    validate_secrets(files, errors)
    validate_workflows(errors)
    validate_manifest(errors)
    validate_lessons(errors)
    validate_privacy_manifest(errors)
    validate_apple_metadata(errors)
    validate_markdown_links(errors)

    if errors:
        print("Repository validation failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print(
        "Repository validation passed: structure, public boundaries, lessons, "
        "privacy, and asset manifest are valid."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())

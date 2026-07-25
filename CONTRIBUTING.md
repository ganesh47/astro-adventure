# Contributing

Astro Adventure uses issue-first development. Please open or reference a GitHub issue before starting meaningful gameplay, curriculum, asset, or platform work.

## Workflow

1. Find or open an issue describing the proposed work.
2. Keep changes scoped to that issue.
3. Update docs or specs when behavior changes.
4. Track every new asset in `assets/manifest/assets.csv`.
5. Add or update tests for gameplay rules and lesson data.
6. Run the same public validation used by GitHub Actions.

## Local checks

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
swift test
swift format lint --recursive --strict Sources Tests Apps
python3 -m unittest discover -s scripts/tests -p 'test_*.py' --verbose
python3 scripts/validate_repository.py
xcodebuild -project AstroAdventure.xcodeproj -scheme AstroAdventure-iOS \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project AstroAdventure.xcodeproj -scheme AstroAdventure-tvOS \
  -destination 'generic/platform=tvOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

If `project.yml` changes, regenerate `AstroAdventure.xcodeproj` with XcodeGen 2.45 or later and commit both changes.

## Asset Rules

Only add assets that are original, public-domain, permissively licensed, or otherwise approved for public redistribution. Paid marketplace assets and generated builds with restricted dependencies belong outside this repository.

Manifest candidates may be reviewed before files are added. Use `assets/manifest/assets.csv` to record the repository path, source, license, author, AI status, approval flags, review status, and public notes. Rejected or private-only candidates must be marked `approved_for_public_repo=no` and `review_status=rejected`; do not commit their files or previews.

Apple asset catalogs, USD/USDZ files, media, Git LFS, and public redistribution rules are covered in `docs/specs/apple-asset-hygiene.md`.

## Kid Safety

Content must be appropriate for ages 4–12 through the documented age bands, avoid manipulative reward loops, use encouraging explanations, and support accessibility from the start.

- Do not collect a birthdate when an Explorer Mode selection is sufficient.
- Do not add advertising, third-party child analytics, chat, location tracking, or external child-facing links.
- Keep science sources in public content metadata and parent/educator contexts.
- Every player-facing science claim needs a reviewable source and curriculum status.

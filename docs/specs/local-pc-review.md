# Local PC Review Checklist

## Purpose

This checklist verifies that a local Windows PC can package and smoke test the Astro Adventure Unreal build without committing machine-specific paths, screenshots, packaged binaries, or private device identifiers.

## Scope

- Project: `AstroAdventureUE/AstroAdventureUE.uproject`.
- Engine: Unreal Engine `5.7.x`, with `5.7.4` preferred for issue #22 evidence.
- Package target: Win64 Development.
- Package output: ignored local folder `PackagedBuilds/Win64-Development`.

## Preflight

| Check | Expected Result | Reviewer Notes |
| --- | --- | --- |
| Git branch | `feature/solar-passport-playable` is checked out. | Record branch name only. |
| Git status | Working tree state is understood before packaging. | Do not revert unrelated changes. |
| Unreal path | `UNREAL_ENGINE_ROOT` points to the local UE 5.7 install root. | Do not paste personal paths into committed files. |
| RunUAT | `%UNREAL_ENGINE_ROOT%\Engine\Build\BatchFiles\RunUAT.bat` exists. | Pass/fail only. |
| Output folder | `PackagedBuilds/Win64-Development` is ignored by git. | `git check-ignore PackagedBuilds/Win64-Development` should return the path. |

## Package Command

Run from the repository root in PowerShell:

```powershell
$env:UNREAL_ENGINE_ROOT = "<local UE 5.7 root>"
.\scripts\package-win64-development.ps1
```

Optional explicit form:

```powershell
.\scripts\package-win64-development.ps1 -UnrealEngineRoot "<local UE 5.7 root>"
```

## Package Review

| Check | Expected Result | Reviewer Notes |
| --- | --- | --- |
| Script result | Script exits successfully and prints `Package complete`. | Record pass/fail and date. |
| Archive location | Build output is under `PackagedBuilds/Win64-Development`. | Do not commit packaged files. |
| Executable | A Win64 executable is present in the package output. | Record executable filename only. |
| Git safety | `git status --short` does not show packaged output. | Investigate before sharing evidence. |

## Smoke Test

| Area | Expected Result | Reviewer Notes |
| --- | --- | --- |
| Launch | Packaged executable starts on the review PC. | Record pass/fail. |
| Home menu | Home shows New Expedition, Continue, Reset, and Quit with clear default focus. | Record pass/fail. |
| New Expedition | New starts the first expedition from an empty passport state. | Record pass/fail. |
| Continue | Continue resumes current in-session destination and stamp progress when progress exists. | Record pass/fail, or note not available before progress. |
| Reset | Reset clears the current in-session expedition and keeps the selected age band. | Record pass/fail. |
| Quit | Quit exits or requests exit confirmation without trapping focus. | Record pass/fail. |
| Input | Keyboard and Xbox-style controller input can navigate Home, Mission View, Atlas View, discovery, and review. | Record device class only. |
| Mission View | Mission View presents the current objective, stamp progress, and next action without dense text. | Record pass/fail. |
| Atlas View | Atlas View lets Mercury, Mars, and Europa each receive focus and shows completed/incomplete status. | Record pass/fail. |
| View switching | Switching between Mission View and Atlas View preserves focus, camera framing, and earned stamp state. | Record pass/fail. |
| Camera stability | Camera framing stays stable while navigating, scanning, opening cards, awarding stamps, pausing, and switching views. | Record any jitter, drift, snap, clipping, or motion issue. |
| Kid-friendly HUD | HUD uses short labels, large readable targets, non-color-only status, and no grades, streaks, currency, or pressure timers. | Record pass/fail. |
| Scan action | Focused destination opens scan feedback, then the discovery card and quiz panel. | Record pass/fail. |
| Scan feedback | Scan communicates progress and success with readable text plus icon, shape, animation, or sound fallback. | Record pass/fail. |
| Quiz loop | Correct and retry feedback are visible. | Record pass/fail. |
| Stamp feedback | Completing a destination awards exactly one obvious stamp and confirms which destination was stamped. | Record pass/fail. |
| Completion | Completing all three destinations reaches the mission completion state. | Record pass/fail. |
| Stability | No crash, hang, or blocking error occurs during the review pass. | Record any public-safe error summary. |

## Evidence Template

```text
Review date:
Reviewer:
Windows version:
Unreal Engine version:
Script command: scripts/package-win64-development.ps1
Package result:
Executable filename:
Keyboard input:
Controller input:
Home New/Continue/Reset/Quit:
Mission View:
Atlas View:
Camera stability:
Kid-friendly HUD:
Mercury scan/quiz:
Mars scan/quiz:
Europa scan/quiz:
Scan/stamp feedback:
Completion state:
Git status after package:
Notes:
```

## Public Boundary

Keep the following local-only:

- Full local filesystem paths.
- Windows username or machine name.
- Packaged binaries and generated Unreal folders.
- Screenshots or logs containing private account, machine, or device identifiers.
- Xbox console serial numbers, tokens, certificates, or partner-only documentation.

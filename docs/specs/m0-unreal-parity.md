# M0 Unreal Parity

## Purpose

M0 proves that Astro Adventure's first Mercury, Mars, and Europa interaction loop can run as an Unreal Engine `5.7.4` project. It is the first active implementation milestone after the platform pivot.

## Scope

The proof is intentionally small:

- One Unreal map: `M0_DeploymentProof`.
- One explorer ship pawn.
- Three destinations: Mercury, Mars, Europa.
- Keyboard and Xbox-style controller input.
- Focus cycle, scan action, discovery card, quiz panel, and mission completion state.
- Local/manual validation that confirms required project assets and gameplay contracts.

## Non-Goals

- Final art.
- Full campaign structure.
- Accurate orbital simulation.
- Xbox deployment.
- Store packaging.
- Restricted Xbox SDK/GDK features.

## Gameplay Contract

The player starts focused on Mercury. The player can move the explorer ship, cycle focus across Mercury, Mars, and Europa, scan a focused destination, read a short sourced discovery card, answer one three-choice quiz, and repeat until all three destinations are complete.

Completion copy should name the learning concept: "Different worlds have different clues."

## Data Contract

M0 content must include public reviewable data for:

- Destination id.
- Display name.
- Discovery fact.
- Kid-friendly explanation.
- Source URL.
- Quiz prompt.
- Three answer choices.
- Correct answer.
- Correct, retry, and hint feedback.

The initial facts and quiz copy come from `first-mission-loop.md` and `first-quiz-loop.md`.

## Validation Contract

Local Unreal validation must verify:

- `AstroAdventureUE.uproject` targets Unreal 5.7.
- Enhanced Input and CommonUI are enabled.
- The editor target compiles.
- `M0_DeploymentProof` exists.
- Required destination actors exist and have stable ids.
- Input bindings exist for move, focus next/previous, scan/confirm, back/cancel, and hint.
- Quiz data exists for Mercury, Mars, and Europa.
- The mission can reach completion without timers, monetized rewards, or punitive failure.

Until binary Unreal assets are created, public CI validates the text project shell and local validation records whether UE 5.7.4 build and automation checks passed.

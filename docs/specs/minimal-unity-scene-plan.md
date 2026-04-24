# Minimal Unity Scene Plan

## Status

Prepared implementation plan. No Unity-generated files are committed yet.

## Covers

- Prepares issue #4: Create minimal Unity scene for deployment proof
- Prepares issue #12: Prototype solar system navigation
- Uses issue #3 input decisions from `docs/specs/controller-input-spike.md`
- Uses issue #17 hygiene decisions from `docs/specs/unity-binary-asset-hygiene.md`

## Why No Scene Files Yet

This workspace does not include a Unity project scaffold, `Packages/`, or `ProjectSettings/`, and there is no full Unity editor install available in this environment. Creating `.unity`, `.prefab`, `.asset`, or `.meta` files by hand would be fragile and could add misleading engine-generated noise.

The safe next step is to document the exact minimal scene so it can be created in Unity and committed with only stable project files.

## Unity Assumptions

- Unity LTS version: choose the current Unity LTS installed by the project owner for M0 and record the exact version in `ProjectSettings/ProjectVersion.txt`.
- Input package: Unity Input System.
- Render path: built-in renderer or URP is acceptable for M0; prefer the default template that produces the least setup noise.
- Target first run: PC build or editor play mode.
- Xbox Dev Mode packaging notes stay public only at the high level; private package, certificate, and device details stay in the private repo.

## Scene Shape

Scene name: `M0_DeploymentProof`

Core objects:

- A simple starfield or dark solid background.
- Three selectable celestial destinations: Moon, Mars, and Jupiter.
- A small ship marker or focus cursor.
- Readable title/status text: `Astro Adventure`.
- Destination label and one-line fact panel.
- A status text area for controller input feedback.

Interaction loop:

1. Player starts with focus on Moon.
2. Left stick or bumpers move focus between Moon, Mars, and Jupiter.
3. South face button confirms the focused destination.
4. West face button scans the destination and shows a short fact.
5. East face button returns to destination selection.
6. Right trigger shows a boost/thrust feedback state.
7. Optional haptics pulse during scan or boost only when enabled.

## Destination Data

| Destination | Short fact | Prototype feedback |
| --- | --- | --- |
| Moon | Earth's Moon has weaker gravity than Earth. | Silver focus ring and landing status |
| Mars | Mars is called the Red Planet because of iron-rich dust. | Red-orange focus ring and scan pulse |
| Jupiter | Jupiter is the largest planet in our solar system. | Large focus ring and gravity warning text |

Facts should stay short enough for ages 8-12 and readable from couch distance.

## Controller-First Navigation Model

Use selection navigation for M0 rather than free-flight physics. This keeps the scene small, deterministic, and useful for deployment debugging.

Controls:

- Left stick horizontal: move focus to previous or next destination.
- Bumpers: cycle destinations one step at a time.
- South face button: arrive at selected destination.
- East face button: return from destination info.
- West face button: scan selected or arrived destination.
- Right trigger: show thrust feedback and optional haptics.
- Menu button: pause/help placeholder.

Back/cancel behavior:

- From destination info, back returns to destination selection.
- From selection, back clears scan/status text.
- From pause/help, back closes pause/help.

## Readability and Accessibility

- Use large, high-contrast labels suitable for couch play.
- Keep all interaction states untimed.
- Do not rely on color alone; combine focus rings with scale, text, or icon changes.
- Pair all optional vibration with visible feedback.
- Avoid flicker and repeated rapid pulse effects.
- Keep the camera fixed unless right-stick camera preview is intentionally added.

## Public Asset Rules

The scene can use Unity primitives, simple materials, and original text without new manifest entries. Any imported texture, model, font, audio file, generated image, or third-party asset requires an `assets/manifest/assets.csv` entry before commit.

Do not import paid marketplace packs, restricted SDK samples, private packages, or deployment artifacts into this public repo.

## Safe Commit Set After Creating the Scene

When Unity creates the project, commit only stable source/project files such as:

- `Assets/Scenes/M0_DeploymentProof.unity`
- `Assets/Input/AstroAdventureControls.inputactions`
- `Assets/Scripts/*.cs`
- `Assets/Materials/*.mat`
- Required `.meta` files
- `Packages/manifest.json`
- `Packages/packages-lock.json`
- `ProjectSettings/ProjectVersion.txt`
- Required `ProjectSettings/*.asset`

Inspect `git status --short` before committing and leave generated folders ignored.

## Implementation Steps

1. Create/open the Unity project with the agreed LTS editor.
2. Install or enable Unity Input System if the template does not include it.
3. Add `AstroAdventureControls.inputactions` using the mapping in `controller-input-spike.md`.
4. Create `M0_DeploymentProof` scene.
5. Add three primitive destination objects with labels and focus feedback.
6. Add a controller navigation script for focus, confirm, cancel, scan, and thrust feedback.
7. Add optional haptic pulse behind a runtime setting or serialized toggle.
8. Test in editor on PC with keyboard fallback.
9. Test with an Xbox-style controller on PC.
10. Commit only stable Unity source/project files and no generated output.

## Blockers

- Exact Unity LTS version is not yet recorded in the repo.
- Controller hardware testing requires local device access.
- Xbox Dev Mode package/deploy validation requires private device and signing details outside this public repo.


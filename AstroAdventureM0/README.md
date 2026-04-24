# AstroAdventureM0

Minimal Unity proof project for `M0: Xbox Dev Mode Proof`.

## Open

Open this folder in Unity Hub or directly with Unity `6000.4.4f1`:

```text
C:\Users\vaunz\projects\Astro-Adventure\astro-adventure\AstroAdventureM0
```

## Scene

Open and run:

```text
Assets/Scenes/M0_DeploymentProof.unity
```

## Controls

- Left stick or WASD/arrow keys: move the explorer ship.
- Left/right bumper or Q/E: cycle destination focus.
- A or Enter/Space: scan focused destination.
- B or Escape: cancel/back proof.

## Expected Result

The scene should show three destinations, a small explorer ship, focus text, and status text. Controller input should move the ship, cycle focus, scan a destination, and briefly pulse haptics when supported.

## Notes

- Generated folders such as `Library/`, `Logs/`, `Temp/`, `Obj/`, and `UserSettings/` are ignored.
- The project uses Unity Input System `1.19.0`.
- Keep Xbox deployment packages, certificates, and private evidence out of this public repo.

# AstroAdventureM0

Minimal Unity proof project for `M0: Xbox Dev Mode Proof`.

## Open

Open this folder in Unity Hub or directly with Unity `6000.4.2f1`:

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

## Automated Validation

From the public repo root, run:

```bash
tools/validate-m0-scene.sh
```

The validator opens Unity in batch mode, checks the scene structure and camera framing, captures focus/scan screenshots, and creates a short MP4 when `ffmpeg` is available. Output is local-only:

```text
artifacts/scene-validation/
```

The GitHub Actions workflow `.github/workflows/m0-scene-validation.yml` runs repository hygiene immediately. Full Unity scene validation runs in a matching GameCI Unity editor Docker image after this repository secret is configured:

```text
UNITY_LICENSE
```

For GitHub-hosted Docker validation, use the full contents of a legacy `.ulf` license file. Local Unity entitlement XML files are machine-bound; the workflow detects them and skips full Unity validation with a notice instead of failing the whole CI run.

Setup references:

- GitHub repository secrets: <https://docs.github.com/actions/security-guides/encrypted-secrets>
- GameCI Unity activation: <https://game.ci/docs/github/activation/>
- GameCI Unity Docker images: <https://game.ci/docs/docker/docker-images/>

## Notes

- Generated folders such as `Library/`, `Logs/`, `Temp/`, `Obj/`, and `UserSettings/` are ignored.
- The project uses Unity Input System `1.19.0`.
- Keep Xbox deployment packages, certificates, and private evidence out of this public repo.

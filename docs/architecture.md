# Architecture

Astro Adventure is now Unreal-first, with Unreal Engine `5.7.4` as the locked target for the active game project.

## Direction

- Use `AstroAdventureUE/` as the primary game project.
- Build a small C++ shell so project compilation, automation, and self-hosted CI are deterministic.
- Keep gameplay iteration Blueprint-first for the ship, focus/scan loop, mission flow, UI, and quiz panels.
- Use Enhanced Input for keyboard and Xbox-style controller input.
- Use UMG/CommonUI-style patterns for controller-first UI.
- Keep game logic, curriculum content, input mapping, and asset manifests public when licenses allow.
- Keep Xbox certificates, restricted SDK/GDK material, store artifacts, private package outputs, and publishing workflows private.

## First Technical Risk

`M0: Unreal Parity` must prove that the current Mercury, Mars, and Europa proof can be rebuilt in Unreal before deeper gameplay production. It does not yet prove Xbox deployment.

`M3: Xbox Dev Mode Proof` later proves local Xbox deployment using private evidence and public-safe status notes.

## CI Shape

Public pull request checks run on GitHub-hosted runners and validate repository hygiene, public/private boundaries, asset manifest rows, and Unreal project metadata.

Full Unreal validation runs only on a trusted self-hosted Windows runner labeled `self-hosted`, `Windows`, `Unreal`, and `AstroAdventure`. The self-hosted runner must use Unreal Engine `5.7.4`; the existing local UE 5.4 install is not an accepted fallback.

# Architecture

Astro Adventure starts as a Unity-first project with a PC prototype and an early Xbox Dev Mode deployment proof.

## Direction

- Use Unity for the first playable prototype.
- Keep game logic, curriculum content, input mapping, and asset manifests public when licenses allow.
- Keep Xbox certificates, restricted SDK material, store artifacts, and publishing workflows private.
- Validate controller-first gameplay early so the PC build and Xbox build share the same interaction model.

## First Technical Risk

`M0: Xbox Dev Mode Proof` must show that a minimal Unity project can be built on the PC and deployed to an Xbox on the local network before deep gameplay production begins.

The public proof plan is tracked in `docs/specs/m0-xbox-dev-mode-proof.md`. The reproducible PC setup checklist is tracked in `docs/specs/pc-toolchain-checklist.md`. Current public status is blocked pending physical verification, not yet proven.

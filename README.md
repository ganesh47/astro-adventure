# Astro Adventure

Astro Adventure is an open-source, Unreal-first educational game for kids ages 4-12. The project teaches astronomy, space, planets, moons, and related physics ideas through age-banded, controller-friendly missions, discovery cards, quizzes, and playful exploration.

## Current Status

This repository is pivoting to Unreal Engine `5.7.4`. The first milestone is `M0: Unreal Parity`, which rebuilds the original Mercury, Mars, and Europa proof as an Unreal project before deeper gameplay production. The current prerelease line starts at `v0.1.0-alpha.1`.

Xbox remains the primary long-term target. Windows desktop is the first validation target, and full Unreal validation runs on a trusted self-hosted Windows runner rather than on untrusted public pull request jobs.

## Repository Split

- `ganesh47/astro-adventure`: public Unreal game source, open educational content, approved assets, specs, issues, research outcomes, and community collaboration.
- `ganesh47/astro-adventure-private`: private Xbox release artifacts, certificates, Partner Center notes, restricted SDK/GDK notes, store metadata drafts, and non-redistributable materials.

## Documentation

- Stable specs, accepted decisions, contribution rules, and manifests live under `docs/` and `assets/manifest/`.
- Every asset considered for the public repo must be tracked in `assets/manifest/assets.csv`.
- Unreal project setup starts in `AstroAdventureUE/README.md`.

## Licensing

- Code is licensed under MIT. See `LICENSE`.
- Original educational content and approved public assets default to CC BY 4.0. See `CONTENT_LICENSE.md`.

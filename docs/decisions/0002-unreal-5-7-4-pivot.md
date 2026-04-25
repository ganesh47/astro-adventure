# Decision 0002: Unreal 5.7.4 Pivot

## Status

Accepted.

## Decision

Astro Adventure will pivot fully to Unreal Engine `5.7.4`. The active public game project is `AstroAdventureUE/`.

## Rationale

Xbox is the primary long-term target. Unreal offers a stronger console-oriented path than the prior Unity Personal setup and avoids relying on Unity hosted CI license activation. The project will use GitHub-hosted public checks for safe PR guardrails and a trusted self-hosted Windows runner for full Unreal validation.

## Consequences

- Unity project files, Unity CI, and Unity validation scripts are removed from the active public repo.
- Existing local UE 5.4 is ignored; UE 5.7.4 must be installed before project validation.
- M0 is redefined as Unreal parity: Mercury, Mars, Europa navigation, scan, discovery, quiz, and completion.
- Xbox package artifacts, certificates, restricted SDK/GDK details, Partner Center notes, and private validation evidence stay private.

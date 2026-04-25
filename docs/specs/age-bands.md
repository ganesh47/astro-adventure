# Age Bands

## Goal

Astro Adventure targets kids ages 4-12 while staying playable with families, classrooms, and mixed reading levels. Age bands guide copy, concept depth, UI density, privacy defaults, and accessibility expectations.

## Bands

| Band | Player needs | Design implications |
| --- | --- | --- |
| 4-6 | Pre-reader and early reader players, co-play, audio-first prompts, icon-heavy recognition | Two-choice recognition, minimal reading, no scoring pressure, adult-friendly read-aloud text |
| 7-9 | Concrete clues, short prompts, visible goals, frequent reassurance | One instruction at a time, simple comparisons, no timed learning gates |
| 10-12 | More independence, stronger comparison skills, early evidence reasoning | Add data cards, scale comparisons, optional deeper facts, more mission choice |
| Adult support | Parent, caregiver, teacher, or reviewer may read context | Keep source links, review status, and learning goals outside fast play screens |

## Science Fit

- Grade 5 NGSS includes "Space Systems: Stars and the Solar System", including the Sun as a star and observable patterns. NGSS topic overview: https://www.nextgenscience.org/overview-topics
- Middle school NGSS MS-ESS1-3 emphasizes analyzing data from instruments, telescopes, and spacecraft to compare solar system objects, while avoiding pure recall-only assessment. NGSS MS-ESS1-3: https://www.nextgenscience.org/pe/ms-ess1-3-earths-place-universe
- NASA Space Place provides kid-facing planet material suitable for early drafts and source review: https://spaceplace.nasa.gov/en/kid/planets/

## Accessibility and Privacy

- Use CAST UDL as the design frame: provide multiple ways to engage, perceive information, and respond. https://www.cast.org/what-we-do/universal-design-for-learning/
- Use W3C WCAG 2.2 as a reference for readable, operable UI patterns even when the first prototype is Unreal rather than web. https://www.w3.org/TR/WCAG22/
- Treat under-13 privacy as a default constraint. Do not collect names, emails, voice, chat, precise location, analytics identifiers, or persistent child profiles in public prototypes. FTC COPPA guidance: https://www.ftc.gov/business-guidance/resources/childrens-online-privacy-protection-rule-not-just-kids-sites

## Requirements

- Default copy is short, concrete, and couch-readable, with read-aloud-ready variants for ages 4-6.
- Hints and retries are always available in learning checks.
- No account, chat, leaderboard, or telemetry requirement for M0/M1 learning validation.
- Any future persistence must document data fields, retention, parental consent needs, and public/private handling before implementation.

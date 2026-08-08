# Changelog

All notable public changes to Astro Adventure are tracked here.

## v0.2.0 - 2026-08-08

- Pivoted the active game from Unreal/Xbox to native iOS, iPadOS, and tvOS.
- Added Swift 6 packages for gameplay, content, services, RealityKit presentation, and SwiftUI.
- Added separate iOS and tvOS app targets generated from `project.yml`.
- Expanded the learning journey to 13 Solar System destinations, from the Sun to Pluto and Ceres.
- Added seven NASA-powered flashcards and seven quiz questions for every destination and age band.
- Added kid-friendly lessons about colors, shapes, gravity, astronomical units, sunlight travel time, rotation, orbits, and signature planetary features.
- Added distinct content and quiz complexity for ages 4–6, 7–9, and 10–12.
- Added a focus-aware tvOS destination rail, colorful Solar System presentation, improved welcome flow, and remote-friendly navigation.
- Added TestFlight delivery through GitHub Actions and Xcode Cloud for iOS and tvOS.
- Added public GitHub Actions automation for Swift tests, formatting, app builds, repository hygiene, dependency review, and CodeQL.
- Replaced platform-private repository planning with a public-by-default contribution and automation model.

## v0.1.0-alpha.1 - 2026-04-25

- Pivoted the public project to Unreal Engine 5.7.4 under `AstroAdventureUE/`.
- Added a source-only first playable loop for Mercury, Mars, and Europa with scanning, discovery cards, quiz feedback, progress tracking, and local save state.
- Added age-banded learning data for ages 4-6, 7-9, and 10-12.
- Added spaced repetition and mastery helper logic with Unreal automation tests.
- Added public-safe learning, age band, educational progression, DevSecOps, and Unreal/Xbox path specs.
- Strengthened public/private boundary, asset manifest, and Unreal generated-file guardrails.

Known limitations:

- This is an alpha source release, not a final packaged Windows build.
- Full Unreal validation requires a trusted Windows machine with Unreal Engine 5.7.4.
- Xbox deployment remains deferred and private-evidence-only.

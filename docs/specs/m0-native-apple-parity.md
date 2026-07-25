# M0 Native Apple Parity

## Goal

Prove that the Mercury, Mars, and Europa learning loop runs from shared Swift source on iPhone, iPad, and Apple TV.

## Required experience

- Mission prompt introduces Signal Sweep.
- The player focuses Mercury, Mars, or Europa.
- Scan reveals an age-appropriate discovery card.
- A discovery check provides encouraging correct, retry, and hint states.
- Completing all three cards enters a mission-complete state.
- Progress models are versioned and ready for local persistence.

## Age coverage

- Ages 4–6: audio-ready wording and exactly two visually distinct choices.
- Ages 7–9: short concrete explanation and exactly three choices.
- Ages 10–12: evidence-oriented explanation and exactly three richer choices.

The player chooses an Explorer Mode. The app does not request an exact age or birthdate.

## Platform requirements

- iPhone and iPad support touch without requiring a controller.
- Apple TV supports Siri Remote navigation without requiring a controller.
- SwiftUI focus is visible without relying on color alone.
- RealityKit renders the same destinations from shared code.
- The layout remains readable on a phone, tablet, and television.

## Validation

- `swift test` passes all gameplay and content tests.
- Swift Format lint passes.
- Repository validation passes.
- Unsigned iOS Simulator and tvOS Simulator builds pass.
- No signing credentials or personal data are needed for public CI.

## Non-goals

- Final production art or audio.
- Accurate orbital simulation.
- Account creation.
- iCloud synchronization.
- Game Center achievements.
- Apple Arcade acceptance or App Store release.

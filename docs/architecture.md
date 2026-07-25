# Architecture

Astro Adventure is a native Apple multiplatform game built with Swift 6, SwiftUI, and RealityKit.

## Module boundaries

| Module | Responsibility | May depend on |
| --- | --- | --- |
| `AstroGameCore` | Mission state, learning rules, age bands, and progress models | Foundation and Observation |
| `AstroContent` | Bundled, sourced, validated lesson data | `AstroGameCore` |
| `AstroServices` | Local persistence and future Game Center/iCloud adapters | `AstroGameCore` |
| `AstroWorld` | RealityKit entities, camera, scene systems, and spatial presentation | `AstroGameCore` |
| `AstroUI` | Shared SwiftUI experience and platform adaptation | All shared modules |
| `Apps/iOS` | iPhone/iPad lifecycle and metadata | `AstroUI` |
| `Apps/tvOS` | Apple TV lifecycle and metadata | `AstroUI` |

Gameplay rules must remain testable without launching a simulator or rendering RealityKit. UI and world modules consume state from `AstroGameCore`; they do not own curriculum truth.

## Data flow

1. `AstroContent` decodes and validates bundled lesson JSON.
2. `MissionSession` owns the active mission state and age band.
3. `AstroUI` sends semantic actions such as focus, scan, answer, hint, and back.
4. `AstroWorld` renders the current world without changing learning progress directly.
5. A `ProgressStoring` implementation saves versioned `GameProgress`.
6. Future iCloud synchronization wraps the offline save rather than becoming a gameplay dependency.

## Platform strategy

- iOS/iPadOS deployment target: 18 or later.
- tvOS deployment target: 26 or later because the active 3D implementation uses RealityKit on Apple TV.
- Xcode 26 and the Swift 6 language mode are the reproducible build baseline.
- Touch is the default input on iPhone and iPad.
- Siri Remote focus/select is the default fallback on Apple TV.
- Game Controller support augments, but does not replace, platform-default input.

## Content and privacy

- Lessons contain separate 4–6, 7–9, and 10–12 variants.
- Science sources live in data and public review records, not as unrestricted child-facing web links.
- No exact birthdate is required; players select an Explorer Mode.
- No account, advertising SDK, third-party child analytics, chat, or location data is required.
- All persistence is local and offline-first before optional private iCloud sync.

## Project generation

`project.yml` is the source definition for `AstroAdventure.xcodeproj`. The generated project is committed so contributors can clone and build immediately. Changes to either file must be accompanied by regeneration with the documented XcodeGen version.

## Validation

- `swift test` validates mission behavior, learning rules, save models, and lesson data.
- Swift Format validates first-party Swift style.
- Unsigned simulator builds validate the iOS and tvOS applications.
- The public repository validator checks required structure, manifest values, generated artifacts, accidental secrets, workflow privileges, and immutable action references.
- Guardrail unit tests prove that representative secrets, signing artifacts, privileged pull-request triggers, and unpinned actions are rejected.
- CodeQL, dependency review, and full-history Gitleaks scanning run through GitHub Actions.
- Signed device, TestFlight, and App Store builds remain intentional release operations.

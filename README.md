# Astro Adventure

[![Continuous Integration](https://github.com/ganesh47/astro-adventure/actions/workflows/ci.yml/badge.svg)](https://github.com/ganesh47/astro-adventure/actions/workflows/ci.yml)
[![Repository Hygiene](https://github.com/ganesh47/astro-adventure/actions/workflows/pr-hygiene.yml/badge.svg)](https://github.com/ganesh47/astro-adventure/actions/workflows/pr-hygiene.yml)
[![DevSecOps Security](https://github.com/ganesh47/astro-adventure/actions/workflows/security.yml/badge.svg)](https://github.com/ganesh47/astro-adventure/actions/workflows/security.yml)
[![CodeQL](https://github.com/ganesh47/astro-adventure/actions/workflows/codeql.yml/badge.svg)](https://github.com/ganesh47/astro-adventure/actions/workflows/codeql.yml)
[![Xcode Cloud TestFlight](https://github.com/ganesh47/astro-adventure/actions/workflows/testflight.yml/badge.svg)](https://github.com/ganesh47/astro-adventure/actions/workflows/testflight.yml)

Astro Adventure is an open-source, native Apple astronomy game for kids ages 4–12. Players explore planets and moons, scan distinctive clues, collect discovery cards, and reinforce what they find through encouraging age-banded challenges.

The active targets are iPhone, iPad, and Apple TV. The game uses Swift 6, SwiftUI, and RealityKit, with a shared gameplay core and platform-appropriate touch, Siri Remote, and physical-controller input.

> [!NOTE]
> Astro Adventure is being designed as an Apple Arcade candidate. The project is not affiliated with, funded by, accepted into, or endorsed by Apple or Apple Arcade.

## Current milestone

`M0: Native Apple Parity` rebuilds the Mercury, Mars, and Europa proof as a native Apple game:

- Three age modes: Junior Explorer (4–6), Space Explorer (7–9), and Mission Scientist (10–12).
- Shared mission flow: prompt, navigation, scan, discovery card, quiz, feedback, and completion.
- RealityKit scene rendered from source-controlled primitives.
- SwiftUI interface for iOS, iPadOS, and tvOS.
- Local, versioned progress with an offline-first service boundary.
- Unit-tested learning rules and validated lesson data.

The current development version is `0.2.0-alpha.0`.

## Technology

- Swift 6.3 and Xcode 26
- SwiftUI for app and learning interfaces
- RealityKit for the 3D world
- Swift Package Manager for shared modules
- XcodeGen for reproducible project generation
- XCTest, Swift Format, GitHub Actions, CodeQL, dependency review, and Gitleaks

## Repository layout

```text
Apps/                       iOS, tvOS, and shared app resources
Sources/
  AstroGameCore/            mission state, learning rules, and progress models
  AstroContent/             reviewed age-banded lesson data
  AstroServices/            persistence and future Apple service boundaries
  AstroWorld/               RealityKit scene and gameplay presentation
  AstroUI/                  shared SwiftUI experience
Tests/                      unit and content validation tests
assets/manifest/            provenance and license review for every asset
docs/                       architecture, decisions, roadmap, and stable specs
scripts/                    public repository validation
project.yml                 source definition for the generated Xcode project
AstroAdventure.xcodeproj/   committed project for immediate contributor use
```

## Build locally

Requirements:

- macOS with Xcode 26 or later
- Optional: XcodeGen 2.45 or later when changing `project.yml`
- Git LFS before adding tracked art, audio, or 3D binary assets

Open `AstroAdventure.xcodeproj` and run either the `AstroAdventure-iOS` or `AstroAdventure-tvOS` scheme.

Command-line validation:

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
swift test
swift format lint --recursive --strict Sources Tests Apps
python3 -m unittest discover -s scripts/tests -p 'test_*.py' --verbose
python3 scripts/validate_repository.py
xcodebuild -project AstroAdventure.xcodeproj -scheme AstroAdventure-iOS \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project AstroAdventure.xcodeproj -scheme AstroAdventure-tvOS \
  -destination 'generic/platform=tvOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

After changing `project.yml`, regenerate the committed project:

```bash
xcodegen generate --spec project.yml
```

Successful CI runs on `main` are promoted through Xcode Cloud to TestFlight.
See [docs/testflight.md](docs/testflight.md) for the delivery architecture,
required GitHub configuration, and manual operations.

## Public-by-default development

Everything needed to understand, build, test, and contribute to the game belongs in this public repository: source, lesson data, approved redistributable assets, build automation, architecture decisions, research outcomes, and release notes.

Never commit signing certificates, provisioning profiles, App Store Connect credentials, API private keys, personal player data, TestFlight exports, or licensed assets without public redistribution rights. Those are operational secrets or external records, not missing source. CI scans the working tree and Git history, while workflow dependencies are pinned to immutable commit SHAs.

See [CONTRIBUTING.md](CONTRIBUTING.md), [SECURITY.md](SECURITY.md), [docs/ROADMAP.md](docs/ROADMAP.md), and [docs/specs/devsecops-validation.md](docs/specs/devsecops-validation.md).

## Licensing

- Code is licensed under the MIT License. See [LICENSE](LICENSE).
- Original educational content and approved public assets default to CC BY 4.0. See [CONTENT_LICENSE.md](CONTENT_LICENSE.md).

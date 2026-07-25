# Decision 0003: Native Apple Pivot

Status: accepted
Date: 2026-07-25

## Decision

Astro Adventure will use Swift 6, SwiftUI, and RealityKit as its active implementation. The supported product targets are iPhone, iPad, and Apple TV. The repository will remain public and contain everything required to build and test the game except credentials, personal data, signed distribution artifacts, and assets without public redistribution rights.

The prior Unreal/Xbox implementation is removed from the active tree and remains available through Git history and the `v0.1.0-alpha.1` release.

## Context

The Unreal proof contained a small, source-only mission loop and no committed production maps or binary art. A native rewrite therefore costs less than maintaining a general-purpose engine while offering direct access to Apple input, accessibility, Game Center, iCloud, and television frameworks.

RealityKit is the supported Apple 3D direction for new work, including tvOS. SwiftUI provides a shared interface layer while allowing touch and focus-based platform adaptation.

## Consequences

- `AstroGameCore` owns portable, renderer-independent gameplay and learning rules.
- RealityKit owns 3D presentation; SwiftUI owns learning panels and navigation UI.
- Lesson content is data-driven and includes all three age bands.
- GitHub Actions compile and test both Apple app targets on public macOS runners.
- Xbox, Windows, Unreal, C++, Blueprint, GDK, and Partner Center plans are no longer active scope.
- Apple Arcade remains a product aspiration and does not change the open-source license or guarantee distribution.

# Unreal Xbox Path

## Goal

Define the public-safe path from Unreal prototype to Xbox validation while preserving the boundary between open planning and private console program material.

## Public Path

1. Build and validate gameplay first on Windows with Unreal.
2. Keep controller-first play, couch-readable UI, and source-reviewed learning loops platform-neutral.
3. Use Xbox Developer Mode only for public-safe local deployment research when the milestone is ready. Microsoft UWP Xbox Developer Mode FAQ: https://learn.microsoft.com/windows/uwp/xbox-apps/frequently-asked-questions
4. Track public publishing concepts through Microsoft public game publishing guidance, including ID@Xbox or managed creator paths, without copying private account or certification artifacts into the repo. Xbox game publishing overview: https://learn.microsoft.com/gaming/game-publishing/publishing-processes/managed-creators/overview
5. Request and use Epic console platform access only through the official private process when qualified. Epic notes that Unreal Xbox documentation requires confirmed Xbox developer status and the console access request path. Epic Unreal Xbox docs landing page: https://dev.epicgames.com/documentation/en-us/unreal-engine/xbox-development-in-unreal-engine

## Public/Private Boundary

Public-safe:

- High-level milestones, public documentation links, public tool names, public version numbers, controller UX notes, and sanitized pass/fail status.

Private-only:

- Xbox GDK packages, restricted Unreal platform source/plugins, Partner Center data, console identifiers, access request details, certificates, signing material, package artifacts, private screenshots, certification reports, and NDA-covered instructions.

## Engineering Requirements

- Do not make gameplay depend on Xbox-only APIs before the Windows Unreal prototype proves the mission loop.
- Keep platform integration behind clear interfaces so PC validation remains useful.
- Treat Xbox deployment as a later proof, not as the first definition of done for learning or mission design.
- Record blockers in public language: for example, "platform access pending" rather than naming private portal state or account details.

## Acceptance

- M0/M1 can be reviewed from public Unreal source and docs.
- Xbox proof work has a private evidence location and a public-safe summary.
- No private SDK, package, credential, account, or certification material appears in public commits.

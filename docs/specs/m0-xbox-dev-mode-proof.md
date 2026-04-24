# M0 Xbox Dev Mode Proof

## Purpose

M0 proves whether a minimal Unity build can be built on a Windows PC, deployed to an Xbox running Developer Mode on the same local network, launched, and controlled with an Xbox controller. This document is public-safe by design: it records repeatable process, assumptions, blockers, and final status without publishing account details, console identifiers, package artifacts, certificates, restricted SDK/GDK material, or screenshots that reveal private information.

## Current Status

Status: blocked pending physical verification.

The public path is documented and source-backed. M0 is not proven until a contributor runs the checklist on the target PC and Xbox, records the exact Unity/Visual Studio/Windows SDK versions, deploys the minimal build, and confirms launch plus controller input. Private proof, if captured, belongs in `ganesh47/astro-adventure-private`.

## Public Sources

- Microsoft Learn: [Xbox One Developer Mode Activation Program](https://learn.microsoft.com/en-us/legal/windows/agreements/xbox-one-developer-mode-activation)
- Microsoft Learn: [Windows Device Portal overview](https://learn.microsoft.com/en-us/windows/uwp/debug-test-perf/device-portal)
- Microsoft Learn: [Xbox UWP FAQ](https://learn.microsoft.com/en-us/windows/uwp/xbox-apps/frequently-asked-questions)
- Microsoft Learn: [UWP games getting started](https://learn.microsoft.com/en-us/windows/uwp/gaming/getting-started)
- Unity: [Unity 6 release support](https://unity.com/releases/unity-6/support)
- Unity Manual: [Set up your environment for UWP](https://docs.unity3d.com/2022.3/Documentation/Manual/uwp-environment-setup.html)
- Unity Manual: [UWP requirements and compatibility](https://docs.unity3d.com/2022.3/Documentation/Manual/uwp-requirements-and-compatibility.html)
- Unity Manual: [Deploy a Windows or UWP app with the Windows Device Portal](https://docs.unity3d.com/2023.1/Documentation/Manual/windowsstore-deviceportal.html)

## Proof Scope

The proof build should be intentionally small:

- One Unity scene with a clear on-screen label, a moving object, and one controller-driven interaction.
- No Xbox Live, store, achievements, multiplayer, restricted SDK/GDK features, or Partner Center publishing workflow.
- UWP or Windows Device Portal deployment path only, using public Unity, Visual Studio, Windows SDK, and Xbox Developer Mode documentation.

## Public/Private Boundary

Safe for the public repo:

- Tool names, public version numbers, public links, high-level setup steps, non-sensitive error messages, and pass/fail status.
- Sanitized notes such as "Device Portal reachable over HTTPS on the expected port" or "deployment failed until a user was signed in".

Keep private:

- Microsoft account details, Partner Center tenant/app identifiers, console serial numbers, console IP addresses in screenshots, access tokens, certificates, package artifacts, restricted SDK/GDK documentation, and unpublished store workflow notes.
- Screenshots or videos that show account names, device IDs, local network details, package signing material, or private repository URLs.

## M0 Procedure

1. Prepare the PC using [pc-toolchain-checklist.md](pc-toolchain-checklist.md).
2. Install the current chosen Unity 6 LTS editor through Unity Hub and add UWP Build Support.
3. Confirm Visual Studio 2022 has UWP tooling and a supported Windows SDK installed.
4. Create or open the minimal Unity proof project.
5. Switch the Unity build target to UWP and generate a Visual Studio project, or configure Unity's Device Portal deployment path for remote build-and-run.
6. Put the Xbox in Developer Mode and enable Device Portal from Dev Home.
7. Keep the PC and Xbox on the same LAN. Prefer wired Ethernet for the console when available; Microsoft recommends wired for best deployment performance.
8. Confirm the PC can reach the Xbox Device Portal over HTTPS. Microsoft documents Xbox Device Portal as HTTPS-only on port `11443`.
9. Deploy the package by Visual Studio or Windows Device Portal.
10. Launch the proof build on the Xbox.
11. Verify that the scene renders, the moving object updates, and Xbox controller input changes the scene.
12. Record the public result in this document or the wiki seed. Record private evidence only in the private repository.

## Verification Record Template

Use this template after a real run:

```text
Date:
Tester:
Public issue:
PC OS/version:
Unity editor version:
Unity modules:
Visual Studio version:
Windows SDK version:
Xbox console family:
Xbox mode:
Network:
Deployment path:
Package type:
Launch result:
Controller result:
Public-safe errors:
Private evidence location:
M0 status: proven / partially proven / blocked
Follow-up issues:
```

## Known Blockers And Checks

- Xbox must be in Developer Mode, not Retail Mode, before Visual Studio or Device Portal deployment can connect.
- A user must be signed in on the Xbox for deployment, per Microsoft's Xbox UWP FAQ.
- PC and Xbox must be reachable on the same local network; verify basic connectivity before debugging Unity.
- Device Portal HTTPS certificate warnings are expected during local development, but do not commit certificates or credentials.
- Unity UWP support requires UWP Build Support, Visual Studio, and Windows SDK tooling.
- UWP store submission is not the same as this local proof. Public Microsoft FAQ notes UWP games are no longer accepted in the Xbox Store and points publishing toward ID@Xbox or Xbox Live Creators Program paths.

## Issue Coverage

- Supports #2 by defining the local deployment process and the public-safe verification record.
- Supports #5 by depending on the concrete PC checklist.
- Supports #6 by turning public research into M0 assumptions, boundaries, and blockers.

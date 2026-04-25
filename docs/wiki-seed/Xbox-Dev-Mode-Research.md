# Xbox Dev Mode Research

## Goal

Document the public-safe path for deploying an Astro Adventure proof build from the development PC to an Xbox on the same network.

## Stable Specs

- `docs/specs/m0-xbox-dev-mode-proof.md`
- `docs/specs/pc-toolchain-checklist.md`

## Public Sources

- Microsoft Learn: [Xbox One Developer Mode Activation Program](https://learn.microsoft.com/en-us/legal/windows/agreements/xbox-one-developer-mode-activation)
- Microsoft Learn: [Windows Device Portal overview](https://learn.microsoft.com/en-us/windows/uwp/debug-test-perf/device-portal)
- Microsoft Learn: [Xbox UWP FAQ](https://learn.microsoft.com/en-us/windows/uwp/xbox-apps/frequently-asked-questions)
- Microsoft Learn: [UWP games getting started](https://learn.microsoft.com/en-us/windows/uwp/gaming/getting-started)

## Findings

- Xbox Developer Mode is a public activation path for testing development applications on a retail Xbox console. Do not publish account, Partner Center, or console activation details.
- Windows Device Portal is the public local management surface for deployment and diagnostics. Microsoft's Device Portal overview lists Xbox as HTTPS-only on port `11443`.
- Device Portal can sideload app packages and manage installed/running apps during development.
- Unreal packaging and Xbox deployment details must be verified through public Microsoft/Epic documentation and private platform-program material only when access is approved.
- Microsoft Xbox UWP FAQ says deployment requires a signed-in user on the Xbox, and wired networking is recommended for best deployment performance.
- Public local Dev Mode proof is separate from official Xbox game publishing. The public FAQ points game publishing toward ID@Xbox or Xbox Live Creators Program paths and should not be treated as an M0 dependency.

## Public-Safe Boundary

Safe to document:

- Tool names and public versions.
- High-level activation, Device Portal, UWP build, and deployment steps.
- Sanitized error messages and pass/fail status.
- Links to public Microsoft and Epic documentation.

Keep private:

- Console identifiers, local IP screenshots, account names, Partner Center records, package signing material, private repo URLs, restricted SDK/GDK notes, and unpublished store details.

## M0 Assumptions

- The PC and Xbox are on the same LAN.
- The Xbox is in Developer Mode and Device Portal is enabled.
- A user is signed in on the Xbox before deployment.
- The PC has Unreal Engine 5.7.4, Visual Studio 2022, and Windows SDK tooling installed.
- The proof build contains only public-safe prototype content and no restricted Xbox services.

## M0 Blockers To Track

- Device Portal cannot be reached from the PC.
- Visual Studio, Unreal packaging, or Device Portal cannot deploy to the remote device.
- Unreal Engine version, Visual Studio, or Windows SDK tooling is mismatched.
- Windows SDK components are missing.
- Xbox is in Retail Mode or lacks a signed-in user.
- Controller input works on PC but not in the deployed Xbox proof.

## Research Threads

- Xbox Dev Mode activation and account requirements
- Local network connectivity and device discovery
- Xbox Device Portal setup
- Visual Studio, Unreal, Windows packaging, or package deployment requirements
- Public-safe notes versus private-only release details

## Linked Issues

- #6 Research Xbox Dev Mode setup path
- #5 Define PC toolchain checklist for Unreal and Xbox Dev Mode
- #2 Document local Xbox deployment notes

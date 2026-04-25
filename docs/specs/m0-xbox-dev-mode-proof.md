# Xbox Dev Mode Proof

## Purpose

This later milestone proves whether an Unreal build can be packaged on a trusted Windows PC, deployed to an Xbox running Developer Mode on the same local network, launched, and controlled with an Xbox controller.

The document is public-safe by design. It records process, assumptions, blockers, and final status without publishing account details, console identifiers, package artifacts, certificates, restricted SDK/GDK material, or screenshots that reveal private information.

## Current Status

Status: deferred until `M0 Unreal Parity` is complete.

The active first milestone is `docs/specs/m0-unreal-parity.md`. Xbox deployment is not proven until a contributor runs this checklist on the target PC and Xbox, records public-safe tool versions, deploys the minimal Unreal build, and confirms launch plus controller input. Private proof belongs in `ganesh47/astro-adventure-private`.

## Proof Scope

- One Unreal build produced from `AstroAdventureUE`.
- No Xbox Live, achievements, multiplayer, restricted SDK/GDK features, or Partner Center publishing workflow.
- Local Xbox Developer Mode deployment only.

## Public/Private Boundary

Safe for the public repo:

- Tool names, public version numbers, public links, high-level setup steps, non-sensitive error messages, and pass/fail status.
- Sanitized notes such as "Device Portal reachable over HTTPS on the expected port" or "deployment failed until a user was signed in".

Keep private:

- Microsoft account details, Partner Center tenant/app identifiers, console serial numbers, console IP addresses in screenshots, access tokens, certificates, package artifacts, restricted SDK/GDK documentation, and unpublished store workflow notes.
- Screenshots or videos that show account names, device IDs, local network details, package signing material, or private repository URLs.

## Verification Record Template

```text
Date:
Tester:
Public issue:
PC OS/version:
Unreal Engine version:
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
Status: proven / partially proven / blocked
Follow-up issues:
```

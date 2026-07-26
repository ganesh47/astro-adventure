# TestFlight delivery

Astro Adventure uses GitHub Actions as the validation gate and Xcode Cloud as
the Apple signing, archive, and TestFlight delivery service.

## Delivery flow

1. A commit lands on `main`.
2. `Continuous Integration` runs package tests, formatting checks, repository
   validation, and unsigned iOS and tvOS simulator builds.
3. After CI succeeds, `Xcode Cloud TestFlight` calls the App Store Connect API
   to start the configured Xcode Cloud workflow.
4. Xcode Cloud runs device builds and analysis for iOS and tvOS, then archives
   the iOS app using Apple-managed signing.
5. The iOS TestFlight post-action assigns the archive to the
   `Astro Adventure Internal` testing group.
6. GitHub Actions polls the Xcode Cloud build and reports its final result.

The workflow can also be started manually from GitHub Actions. Manual runs
default to the `main` branch.

## Repository configuration

The public repository contains:

- `.github/workflows/testflight.yml`, which starts and monitors Xcode Cloud.
- `ci_scripts/xcode_cloud.py`, the App Store Connect API client.
- `ci_scripts/ci_post_clone.sh`, which regenerates the Xcode project and stamps
  Xcode Cloud's unique build number.
- `project.yml`, including automatic signing and the Apple development team.

The repository never stores Apple API private keys, signing certificates, or
provisioning profiles.

## GitHub configuration

The `testflight-release` environment uses these encrypted secrets:

- `APP_STORE_CONNECT_KEY_ID`
- `APP_STORE_CONNECT_PRIVATE_KEY`
- `APP_STORE_CONNECT_ISSUER_ID` for a team API key; omit it for an individual
  API key.

It also uses this repository variable:

- `XCODE_CLOUD_WORKFLOW_ID`

The App Store Connect app ID is `6794763212`, and the bundle identifier is
`com.ganesh47.astroadventure`.

## Xcode Cloud configuration

The workflow is associated with `ganesh47/astro-adventure` and
`AstroAdventure.xcodeproj`. It is named `Astro Adventure - TestFlight` and
contains:

- Build and Analyze actions for `AstroAdventure-iOS`.
- Build and Analyze actions for `AstroAdventure-tvOS`.
- An Archive action for `AstroAdventure-iOS` with an internal TestFlight
  post-action targeting `Astro Adventure Internal`.

GitHub is the automatic start condition. The Xcode Cloud workflow is started
through the App Store Connect API only after GitHub CI succeeds, preventing a
failed commit from being promoted to TestFlight.

## Current delivery status

The GitHub credentials, repository access, CI gate, App Store Connect API
trigger, Xcode Cloud checkout, build, analysis, signing configuration, and
internal testing group have all been verified.

The iOS archive currently stops during **Prepare Build for App Store Connect**
inside Apple's Xcode Cloud service:

```text
Unable to authenticate with App Store Connect
Failed to find an account with App Store Connect access for the configured team
```

The failure originates from Xcode Cloud's `Session Proxy Provider`. The same App
Store Connect API key successfully starts and monitors the build, and Xcode
Cloud successfully checks out and builds the repository before the failure.
This isolates the remaining iOS delivery problem to Apple's hosted
App Store Connect session rather than the repository, GitHub secrets, or app
signing configuration.

Open an [Apple Developer Support request][apple-support] for Xcode Cloud and
include the app Apple ID, team ID, Xcode Cloud workflow ID, failed build number,
timestamp, and the complete `Prepare Build for App Store Connect` log. Never
attach the `.p8` private key.

## tvOS TestFlight prerequisite

tvOS Build and Analyze actions are active. The tvOS Archive and TestFlight
post-action are intentionally not active yet because this Apple Developer team
has no registered Apple TV device. Xcode Cloud attempts development and ad hoc
tvOS exports alongside the App Store export, and those exports fail without a
real device registered to the team.

Register a physical Apple TV's UDID in Certificates, Identifiers & Profiles.
After Apple has refreshed the managed provisioning profiles, add an Archive
action for `AstroAdventure-tvOS` with internal distribution and a tvOS
TestFlight post-action targeting `Astro Adventure Internal`. Do not register a
placeholder or fabricated device identifier.

## Operations

To trigger a build manually:

```bash
gh workflow run testflight.yml \
  --repo ganesh47/astro-adventure \
  --field source_branch=main
```

To inspect recent runs:

```bash
gh run list \
  --repo ganesh47/astro-adventure \
  --workflow testflight.yml
```

Rotate the App Store Connect API key immediately if GitHub reports a secret
exposure or if anyone commits a private key to repository history.

Apple references:

- [Configure an Xcode Cloud workflow][workflow-setup]
- [Distribute Xcode Cloud builds through TestFlight][testflight-distribution]
- [Automate Xcode Cloud workflows and builds][api-automation]

[apple-support]: https://developer.apple.com/help/app-store-connect/
[workflow-setup]: https://developer.apple.com/documentation/xcode/configuring-your-first-xcode-cloud-workflow/
[testflight-distribution]: https://developer.apple.com/documentation/xcode/distributing-your-xcode-cloud-builds-through-testflight
[api-automation]: https://developer.apple.com/documentation/appstoreconnectapi/xcode-cloud-workflows-and-builds

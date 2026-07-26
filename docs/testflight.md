# TestFlight delivery

Astro Adventure uses GitHub Actions as the validation gate and Xcode Cloud as
the Apple signing, archive, and TestFlight delivery service.

## Delivery flow

1. A commit lands on `main`.
2. `Continuous Integration` runs package tests, formatting checks, repository
   validation, and unsigned iOS and tvOS simulator builds.
3. After CI succeeds, `Xcode Cloud TestFlight` calls the App Store Connect API
   to start the configured Xcode Cloud workflow.
4. Xcode Cloud runs its device builds, analysis, and iOS/tvOS archives using
   Apple-managed signing.
5. Successful archives appear in TestFlight for internal testing.
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
`AstroAdventure.xcodeproj`. Its archive actions use the shared schemes:

- `AstroAdventure-iOS`
- `AstroAdventure-tvOS`

GitHub is the automatic start condition. The Xcode Cloud workflow is started
through the App Store Connect API only after GitHub CI succeeds, preventing a
failed commit from being promoted to TestFlight.

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

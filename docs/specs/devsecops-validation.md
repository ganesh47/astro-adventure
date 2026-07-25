# DevSecOps Validation

## Goal

Make a public clone sufficient to inspect, build, test, and contribute safely without exposing signing material or personal data.

## Pull request checks

- Validate required repository structure and manifest fields.
- Reject generated output, signed packages, Xcode user state, credentials, and suspicious secret filenames.
- Prove the guardrails reject representative credentials, signing artifacts, privileged pull-request triggers, and mutable action references.
- Run Swift Format in strict lint mode.
- Run all Swift package tests.
- Build the iOS and tvOS app targets without code signing.
- Review dependency changes for known vulnerabilities.
- Run CodeQL analysis for Swift.
- Scan the complete Git history with Gitleaks.

## GitHub Actions coverage

| Control | Workflow | Trigger | Failure policy |
| --- | --- | --- | --- |
| Swift format, tests, coverage, iOS build, tvOS build | `ci.yml` | Push to `main`, pull request, manual | Any failure blocks the check |
| Public boundary, lesson, privacy, asset, and workflow policy | `pr-hygiene.yml` | Push to `main`, pull request, manual | Any violation blocks the check |
| Guardrail unit tests and full-history secret scan | `security.yml` | Push to `main`, pull request, weekly, manual | Any failed control or detected secret blocks the check |
| Swift static application security testing | `codeql.yml` | Push to `main`, pull request, weekly, manual | Analysis uploads to GitHub code scanning |
| New vulnerable or incompatible dependencies | `dependency-review.yml` | Pull request | Moderate-or-higher findings block the check |

Dependabot checks GitHub Actions and Swift dependencies weekly. Every third-party action is pinned to a full commit SHA, and the repository validator rejects mutable tags such as `@main` or `@v4`. Version comments remain beside each SHA so automated updates stay reviewable.

## Permissions

Workflows use read-only repository permissions unless CodeQL requires the narrowly scoped `security-events: write` permission. Checkout credentials are not persisted. Pull request workflows do not receive release credentials. The privileged `pull_request_target` trigger is prohibited. No public CI workflow signs, uploads, publishes, or deploys an app.

## Release boundary

Public:

- Source, tests, project generation input, generated Xcode project, automation, lesson data, reviewed assets, unsigned build logs, and sanitized release notes.

Never committed:

- Certificates, provisioning profiles, App Store Connect private keys, API tokens, personal player data, device identifiers, signed archives, TestFlight exports, or non-redistributable assets.

## Acceptance

- A clean public clone can run `swift test`.
- GitHub-hosted macOS runners can build both app schemes without signing.
- Repository guardrail tests fail on representative forbidden artifacts, credentials, privileged triggers, and unpinned actions.
- Lesson validation fails on duplicate IDs, missing correct choices, invalid age-band choice counts, and unreviewed sources.
- A branch protection rule should require the CI, hygiene, security, CodeQL, and dependency-review checks before pull-request merges.

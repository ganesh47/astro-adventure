# DevSecOps Validation

## Goal

Validation should keep the public repository safe, reproducible, and useful without exposing secrets, Xbox private program material, generated packages, or restricted assets.

## Public Validation Scope

- Docs lint and link review for specs, decisions, research, and public Wiki seed material.
- Asset manifest validation for source URL, license, author, public repo approval, Xbox review status, and notes.
- Unreal source hygiene checks that reject build outputs, caches, packages, secrets, and non-redistributable binaries.
- Public-safe smoke validation for local Unreal project structure and automation scripts.

## Security Requirements

- Follow GitHub Actions hardening guidance: least-privilege `GITHUB_TOKEN`, pinned trusted actions where practical, no untrusted script execution with secrets, and careful handling of pull request events. GitHub Docs: https://docs.github.com/actions/learn-github-actions/security-hardening-for-github-actions
- Use GitHub secret scanning, code scanning, and dependency review where available for the repository tier. GitHub security features: https://docs.github.com/code-security
- Do not store long-lived cloud or store credentials in workflows. Prefer short-lived identity patterns such as GitHub OIDC if cloud deployment is ever introduced. GitHub OIDC guidance: https://docs.github.com/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect

## Xbox Boundary

Safe to validate publicly:

- File presence, docs links, source formatting, manifest fields, and public tool version notes.

Private-only:

- Partner Center identifiers, console IDs, console IP screenshots, certificates, signing keys, access tokens, package artifacts, restricted SDK/GDK logs, certification evidence, and NDA-covered platform steps.

## Required Checks

- A docs-only change should pass Markdown/link review or include a clear note for any intentionally deferred URL.
- An asset change should fail if approval fields are missing or license/source data is incomplete.
- An Unreal change should fail if generated build artifacts, DerivedDataCache, intermediate files, package outputs, private SDK content, or credential-like strings are added.
- An Xbox validation note should fail review if it contains private identifiers or restricted program details.

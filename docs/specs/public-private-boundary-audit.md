# Public/Private Boundary Audit

Supports public issue #1.

## Goal

Keep the public `ganesh47/astro-adventure` repository safe for open-source collaboration while moving private Xbox release material, restricted platform details, and non-redistributable assets to the private workspace.

## Repository Boundary

Public-safe material belongs in this repository when it is source-reviewable and redistribution-safe:

- Game source that does not include secrets, certificates, private service identifiers, or restricted SDK code.
- Open educational content, curriculum notes, and public-safe research summaries.
- Specs, accepted decisions, issue references, and contributor workflow docs.
- Asset metadata and approved assets with clear source, license, author, and attribution requirements.
- Public-safe Xbox Dev Mode notes that do not reveal private account, publishing, certification, or restricted program information.

Private-only material belongs outside this repository:

- Secrets, tokens, keys, certificates, signing material, provisioning files, and credential-like placeholders.
- Partner Center identifiers, private account details, unpublished store data, release plans, and certification artifacts.
- Xbox GDK, NDA-covered, restricted SDK, or console program details.
- Paid marketplace source assets, license-unclear assets, and files that cannot be redistributed publicly.
- Generated builds, packages, logs, or screenshots that expose restricted dependencies or private environment details.

## Audit Checklist

Use this checklist before opening M0/M1 pull requests, initializing public Wiki pages, or adding assets.

- Search docs, manifests, source, and configuration files for credential-like text such as `secret`, `token`, `key`, `cert`, `password`, `client_id`, `tenant`, `publisher`, `partner`, and `store`.
- Confirm Xbox notes stay at public Dev Mode workflow level and do not include restricted SDK instructions, account identifiers, unpublished screenshots, or private publishing steps.
- Confirm asset candidates have manifest entries before commit, including source URL, license, author, approval flags, and notes.
- Confirm generated files are intentional source artifacts, not build outputs, packages, caches, logs, or restricted dependencies.
- Confirm Wiki seed content is public-safe before copying it to the GitHub Wiki.
- Move ambiguous details to the private workspace or replace them with a public-safe rationale.

## Current Baseline Findings

As of this spec, the public docs already state the intended split in `README.md`, `CONTRIBUTING.md`, `SECURITY.md`, and `docs/architecture.md`. The asset manifest also has approval fields for public repository and Xbox build review.

The remaining risk is procedural: contributors need to apply the boundary before adding Unity project files, Xbox Dev Mode notes, Wiki pages, and asset examples. Future audit comments should summarize public-safe findings without quoting sensitive evidence.

## Follow-up Triggers

Open a follow-up issue when:

- A file is useful but not clearly redistributable.
- An Xbox note may depend on restricted program material.
- A manifest field is insufficient for attribution or approval status.
- A build, package, screenshot, or generated artifact appears in a public pull request.

## Issue Links

- #1: This spec is the audit baseline and public-safe checklist.
- #15: Asset manifest validation should use this boundary before accepting examples.
- #16: Wiki initialization should copy only public-safe seed content.

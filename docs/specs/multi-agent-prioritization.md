# Multi-Agent Prioritization

## Goal

Use four distinct work threads organized by risk area, with `M0: Xbox Dev Mode Proof` as the first priority. Deep M1 gameplay work should wait until the platform path, public/private boundaries, and repository hygiene are stable.

## Agent Threads

| Thread | Owns | Primary issues |
| --- | --- | --- |
| Platform proof | Xbox Dev Mode research, PC toolchain, local deployment notes | #2, #5, #6 |
| Unity prototype and hygiene | Unity ignore policy, controller input, minimal scene prep | #3, #4, #12, #17 |
| Docs and design system | Wiki, boundary audit, accessibility, controller-first UI, early specs | #1, #8, #13, #16 |
| Private release guardrails | Secrets, artifacts, release records, private boundaries | private #1-#4 |

## Wave Order

1. Guardrails before artifacts: complete private release policies, public/private audit, and Unity binary hygiene.
2. Prove the platform path: document Xbox Dev Mode research, PC toolchain, deployment notes, Wiki setup, and controller input.
3. Build the minimal M0 proof: create the smallest Unity scene only after hygiene and input decisions are clear.
4. Prepare M1: accessibility, controller-first UI, first mission, first quiz, solar navigation, and asset workflow.

## Current Status

- Guardrail docs are in place for public repo boundaries, Unity asset hygiene, private secrets, private artifacts, and release records.
- M0 platform path is documented but blocked pending physical PC/Xbox verification.
- The minimal Unity scene is planned but not created because this workspace does not include a Unity project or editor-generated baseline.
- M1 design groundwork is started through accessibility and controller-first UI baselines, without beginning deep gameplay production.

## Coordination Rules

- Public issues and docs must not quote private Xbox publishing details.
- Stable decisions belong in `docs/specs/`; living research begins in the GitHub Wiki.
- Cross-thread handoffs should be issue comments with links to specs or private docs.
- Private evidence, packages, credentials, certificates, and restricted platform material stay outside the public repo.

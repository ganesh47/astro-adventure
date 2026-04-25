# Multi-Agent Prioritization

## Goal

Use concurrent agent work while keeping public CI safe and Unreal validation trustworthy. `M0: Unreal Parity` is the first priority.

## Agent Threads

| Thread | Owns |
| --- | --- |
| Platform and validation | UE 5.7.4 local validation, GitHub DevSecOps workflows, Xbox Dev Mode research |
| Unreal prototype | C++ shell, Blueprint map, input, focus/scan loop, validation contracts |
| Curriculum and gameplay | Mercury/Mars/Europa facts, discovery cards, quiz copy, kid-safe feedback |
| Asset and boundary QA | Manifest rows, licenses, public/private boundary, private release guardrails |

## Wave Order

1. Pivot guardrails: Unreal docs, ignore/LFS rules, public/private boundaries, CI split.
2. Unreal M0 shell: project compiles and validates locally with sanitized release evidence.
3. M0 parity: map, ship, destinations, scan, quiz, completion.
4. Xbox proof prep: private release records, package/evidence workflow, Dev Mode verification.
5. M1 gameplay: polished first mission loop after M0 is stable.

## Coordination Rules

- Public PRs run only hosted hygiene checks.
- Self-hosted Unreal jobs run only on `main` or maintainer-triggered workflows.
- Public issues and docs must not quote private Xbox publishing details.
- Stable decisions belong in `docs/specs/`; living research begins in the GitHub Wiki.
- Private evidence, packages, credentials, certificates, and restricted platform material stay outside the public repo.

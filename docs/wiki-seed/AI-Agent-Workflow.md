# AI Agent Workflow

## Goal

Use AI assistants to accelerate research, specs, curriculum, and asset curation while keeping final repo content reviewable and license-clean.

## Agent Roles

- Curriculum agent: turns astronomy topics into kid-friendly mission ideas.
- Gameplay agent: turns lessons into mechanics and quiz loops.
- Asset curator agent: finds sources, checks licenses, and updates manifest proposals.
- QA agent: checks docs, issue clarity, public/private boundaries, and broken references.
- Docs/design system agent: converts accepted issue decisions into public specs for accessibility, controller-first UI, repo boundaries, and Wiki readiness.

## Ground Rules

- AI-generated content is draft until reviewed.
- Asset sources and licenses must be recorded.
- Public docs must avoid private Xbox publishing details.
- Agents should work from issue scope, keep edits narrow, and avoid overwriting unrelated in-progress work.
- Stable project baselines belong in `docs/specs/`; research drafts and source-gathering notes can begin in the Wiki.
- Gameplay, quiz, and asset work should link back to the accessibility, controller-first UI, and public/private boundary baselines before implementation.

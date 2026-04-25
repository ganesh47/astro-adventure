# First Mission Loop

Supports public issue #7. Connects to #12 for the current Mercury, Mars, and Europa navigation scene and to #14 for the quiz/reflection loop.

## Goal

Define the first playable astronomy mission for kids ages 8-12 using the Unreal `M0_DeploymentProof` map. The loop should prove that Astro Adventure teaches through controller-first exploration, not by stopping play for a lecture.

## Audience Assumptions

- Target learners: ages 8-12.
- Reading: short sentences, familiar words, one new science term at a time.
- Play setting: couch, PC monitor, classroom display, or TV with an Xbox-style controller.
- Adult support may be nearby, but the mission should be understandable without adult narration.
- Player-facing facts must be either sourced in this spec or marked `source needed` before implementation.

## Mission Premise

Mission title: `Signal Sweep`

The player pilots a small explorer ship through a simple solar system training map. Mission Control asks the player to scan three destinations and choose which discovery card belongs to each one.

Current destination set from #12:

- Mercury
- Mars
- Europa

The mission uses selection navigation and scan interactions from the current `M0_DeploymentProof` scene. It does not require accurate orbital simulation, free-flight physics, landing, combat, hazards, or timed challenges.

## Learning Goal

Players learn that different worlds can be recognized by observable traits:

- Mercury is closest to the Sun and is the smallest planet in our solar system. Source: NASA Mercury facts, https://science.nasa.gov/mercury/facts/
- Mars looks red because iron in its rocks, dust, and soil has rusted. Source: NASA Mars facts, https://science.nasa.gov/mars/facts/
- Europa is an icy moon of Jupiter, and evidence points to a salty ocean beneath its ice. Source: NASA Europa facts, https://science.nasa.gov/jupiter/jupiter-moons/europa/europa-facts/

Player-facing copy should stay concrete:

- "Mercury is the closest planet to the Sun." sourced.
- "Mars looks red because rusty iron is mixed into its dust." sourced.
- "Europa is an icy moon that may hide an ocean under the ice." sourced.

Avoid implying confirmed life on Europa. Use "may", "could", or "scientists are investigating" for habitability language.

## Core Loop

1. Start with focus on Mercury and show the mission prompt.
2. Player cycles focus between Mercury, Mars, and Europa with controller navigation.
3. Player confirms arrival at the focused destination.
4. Player scans the destination.
5. The scene gives visible and readable feedback. Haptics stay disabled in M0 until a visible setting exists.
6. A short discovery card appears with one fact and one kid-friendly explanation.
7. The player answers one quiz/reflection prompt from `docs/specs/first-quiz-loop.md`.
8. Correct or completed retry returns the player to navigation with that destination marked discovered.
9. After all three destinations are discovered, show a completion state and offer replay or continue.

## Player Goal

Scan all three destinations and complete one discovery check for each destination.

Completion criteria:

- Mercury scanned and reflected.
- Mars scanned and reflected.
- Europa scanned and reflected.
- Completion screen names the concept: "Different worlds have different clues."

The first prototype may persist progress only in scene memory. No account, profile, cloud save, or achievement system is required.

## Controller Interaction

Use the controller-first UI baseline in `docs/specs/controller-first-ui-baseline.md`.

- Directional navigation or bumpers: move focus between destinations.
- Confirm: arrive at the focused destination or continue from feedback.
- Scan: reveal the focused or arrived destination's discovery fact.
- Cancel/back: close discovery card or return from quiz feedback to the destination view without losing mission progress.
- Help/hint: show one age-appropriate nudge for the current destination or quiz.
- Pause/menu: pause or open help/settings placeholder.

Focus requirements:

- Exactly one destination is focused at a time.
- Focus is shown through outline, scale, label, and status text, not color alone.
- Focus order should be Mercury, Mars, Europa unless the visual layout changes and a new order is documented.
- Losing focus after scan, quiz, retry, or completion is a bug.

## Mission States

| State | Purpose | Required player action | Exit |
| --- | --- | --- | --- |
| Mission prompt | Explain the goal in one short screen | Confirm starts | Navigation |
| Navigation | Choose a destination | Move focus, confirm scan | Scan feedback |
| Scan feedback | Make the scan feel responsive | Confirm continues | Discovery card |
| Discovery card | Show one sourced fact | Confirm opens quiz, back returns | Quiz loop or navigation |
| Quiz loop | Reinforce the fact through play | Choose answer, retry, or hint | Navigation |
| Destination complete | Mark discovery without pressure | Confirm continues | Navigation or completion |
| Mission complete | Celebrate all discoveries | Confirm replay/continue | End or restart |

## Feedback Design

Success:

- Use a clear animation, label update, and sound cue if available.
- Show "Discovery saved" or equivalent short text.
- Pair every sound cue with visible text or animation. Do not add vibration until a visible runtime setting exists.

Retry:

- Wrong quiz answers do not remove scan progress.
- The player can retry the same question or ask for a hint.
- Use gentle language such as "Try that clue again" rather than "wrong" or "failed".

Hint:

- First hint points to the visible clue.
- Second hint may narrow the answer choices in the quiz loop.
- Hints never shame the player or reduce reward.

Completion:

- After three destinations, show: "Mission complete: you matched three space clues."
- Reward should be a curiosity badge or discovery card set, not a streak, currency, loot box, or timed ranking.

## Accessibility Baseline

This mission must satisfy `docs/specs/accessibility-baseline.md`.

- No required timers.
- No required simultaneous inputs.
- All text readable from couch distance.
- Important information is not conveyed by color, audio, vibration, or motion alone.
- Haptics are deferred for M0 and must have visible alternatives when introduced later.
- Quiz retry is non-punitive.
- Pause, back, and help are available during learning states.
- Destination labels, cards, and answers use short lines and avoid dense paragraphs.

## Asset Workflow

This mission can ship in the first Unreal prototype using primitives, simple materials, text labels, UMG widgets, and Blueprint-authored scene objects.

Any new art, texture, model, font, audio, generated image, or third-party asset must follow `docs/specs/unreal-asset-hygiene.md`:

- Add an entry to `assets/manifest/assets.csv` before committing the asset.
- Include source URL or `original`.
- Include license, author, AI-generated flag, and approval flags.
- Reject assets that are private, restricted, paid without redistribution rights, or unclear for public use.

The first mission does not require imported planet textures. If textures are added later, they need source review before becoming player-facing.

## Public-Safe Boundary

This spec is public-safe. It intentionally excludes Xbox validation details, private device identifiers, certificates, package signing, store metadata, private build evidence, and restricted SDK material.

Implementation may mention PC and Xbox-style couch play at a high level only.

## Implementation Notes

- Rebuild the Mercury, Mars, and Europa scene in Unreal under `AstroAdventureUE`.
- Keep navigation deterministic for early testing.
- Keep facts in data so curriculum review can update copy without rewriting mission flow.
- Keep the quiz loop modular so #14 can attach one prompt per destination.
- Log or expose debug state for local validation: focused destination, scanned destinations, current mission state, and completion flag.

## Non-Goals

- Full campaign structure.
- Accurate orbital physics.
- Adaptive learning.
- Account/profile persistence.
- Final art direction.
- Store-ready Xbox certification or deployment proof.
- Private validation evidence.

## Open Questions

- Should the discovery card use first-person Mission Control voice or neutral narrator voice?
- What minimum text size should Unreal enforce for TV-readable destination labels?
- Should the first badge be named by the player, by the destination set, or by the science concept?
- Which exact curriculum reviewer signs off on source wording before M1 implementation?

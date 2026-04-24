# Accessibility Baseline

Supports public issue #8.

## Goal

Astro Adventure should be playable, readable, and emotionally safe for kids ages 8-12 from a couch with a controller. Accessibility is a baseline design constraint for prototypes, not a polish pass.

## Audience Assumptions

- Primary players are ages 8-12, with parents, caregivers, teachers, or siblings nearby.
- Play may happen on a TV from couch distance, a desktop monitor, or a classroom display.
- Players may rely on controller-only navigation, captions, readable visuals, reduced pressure, or non-vibration feedback.

## Readability

- Use short sentences and concrete words for mission prompts, hints, and quiz feedback.
- Keep science vocabulary, but explain it in context the first time it appears.
- Prefer one primary instruction at a time.
- Avoid dense paragraphs during active play.
- UI text must be large enough to read from couch distance and must not depend on tiny helper labels.
- Parent/classroom-facing text can be more detailed, but should remain skimmable.

## Controller and Focus

- Every interactive element must be reachable with a controller.
- The focused element must be visually obvious without relying on color alone.
- Focus movement should be predictable in menus, quiz answers, pause screens, and mission prompts.
- Confirm, cancel/back, pause, and help behavior should match the controller-first UI baseline.
- Avoid requiring simultaneous inputs for core learning interactions unless an accessible alternative exists.

## Feedback Alternatives

- Do not communicate required information through color alone.
- Do not communicate required information through vibration alone.
- Do not communicate required information through audio alone.
- Pair important feedback with at least one additional channel: text, icon, animation, contrast, sound, or haptic cue.
- Provide a non-vibration route for gravity, thrust, warning, and success cues.

## Pressure and Safety

- No time pressure by default.
- Timed challenges need an explicit learning or gameplay reason and a non-timed alternative.
- Incorrect answers should invite retry, hint, or exploration instead of punishment.
- Avoid streak pressure, loss framing, manipulative rewards, or shame language.
- Pause and retry should be available during learning moments.
- Rewards should encourage curiosity, discovery, and completion rather than compulsion.

## Prototype Test Checklist

Run this checklist for first playable menus, mission prompts, and quiz loops.

- Can the screen be completed with only a controller?
- Is the current focus visible at a glance?
- Can a player recover from a wrong answer without losing progress?
- Is every vibration, color, and audio cue backed by another cue?
- Can a parent or teacher understand the learning goal from the screen context?
- Does the UI avoid time pressure unless the prototype explicitly needs it?
- Are all facts, terms, and quiz prompts understandable for ages 8-12 or marked for curriculum review?

## Design Hooks

- #7 first mission loop: include target reading assumptions, retry behavior, hint behavior, and required cue alternatives.
- #13 controller-first UI baseline: define focus, navigation, and screen layout patterns that satisfy this baseline.
- #14 first quiz loop: use encouraging feedback, non-punitive retry, and sourced explanations.
- #15 asset workflow: reject or revise assets that make required information unreadable, color-only, or inaccessible.

## Open Questions

- What minimum on-screen text size should the Unity prototype enforce for TV play?
- Should reduced-motion and vibration toggles exist in M1 or be simulated through documented defaults first?
- Which reading-level check should curriculum review use for player-facing copy?

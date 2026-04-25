# Controller-First UI Baseline

Supports public issue #13.

## Goal

Define the first shared UI rules for couch play on PC and Xbox so menus, mission prompts, quizzes, and retry flows feel consistent before deep gameplay production begins.

This spec depends on `docs/specs/accessibility-baseline.md`.

## Input Conventions

- Confirm: advance, select, accept, or continue.
- Cancel/back: return to the previous screen or close the current panel without losing progress.
- Pause/menu: open pause options from gameplay and learning screens.
- Help/hint: reveal age-appropriate guidance when the current screen supports it.
- Directional navigation: move focus between selectable elements in predictable screen order.

Final button glyphs should be assigned during Unreal input implementation and kept consistent across PC and Xbox builds.

## Focus Behavior

- Exactly one primary element should be focused when a menu or quiz screen opens.
- Focus must be visible through shape, outline, scale, icon, or contrast, not color alone.
- Focus order should follow visual order: top to bottom, left to right, or radial order when intentionally designed.
- Disabled items should explain why they are unavailable when focused or selected.
- Losing focus after a state change is a bug.

## Layout and Readability

- Prioritize one task per screen: choose a mission, read a prompt, answer a quiz, retry, or continue.
- Keep important controls away from screen edges so they remain comfortable on TVs.
- Avoid tiny persistent hints; show only the controls relevant to the current state.
- Do not require reading long text during active piloting or timing-sensitive actions.
- Quiz answers should be large, separated, and easy to compare from couch distance.

## Feedback States

- Success: acknowledge the action, connect it to the science idea, and offer continue.
- Incorrect answer: explain gently, offer retry or hint, and avoid progress loss by default.
- Error: describe the recoverable action in plain language.
- Hint: provide one useful next step, not the full solution unless the player asks again.
- Completion: celebrate discovery and name the learned concept.

All states must satisfy the accessibility baseline for color, vibration, audio, motion, and pressure.

## Quiz Selection Pattern

- Multiple-choice answers are focusable items.
- Moving focus previews the answer without committing it.
- Confirm submits the focused answer.
- Feedback appears after submit and keeps a clear route to continue, retry, or request a hint.
- True/false and matching questions should reuse the same focus and submit model.
- Interaction-based questions may use gameplay controls, but must still expose clear confirm, retry, and hint states.

## Prototype Test Cases

- Navigate from a mission prompt to gameplay, pause, resume, and return using only a controller.
- Move through a four-answer quiz and submit each answer position without focus skipping.
- Trigger incorrect feedback, request a hint, retry, and continue after a correct answer.
- Disable vibration and confirm the gravity/thrust cue remains understandable.
- View the same menu on a monitor and TV-scale layout without relying on tiny labels.
- Confirm no public docs or screenshots expose private Xbox publishing details.

## Non-goals

- Full visual design language.
- Final controller glyph art.
- Complete settings menu.
- Platform certification requirements.
- Deep gameplay mechanics for the first mission.

## Issue Links

- #8: Accessibility baseline for readability, pressure, and feedback alternatives.
- #7: First mission loop should consume these input and feedback conventions.
- #14: First quiz loop should consume the quiz selection pattern.
- #16: Wiki pages may summarize these rules, while this file remains the stable spec.

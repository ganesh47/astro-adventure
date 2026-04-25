# Controller Input Spike

## Status

Accepted planning spec for the M0 Unreal prototype.

## Goal

Define the first controller-first input contract for Astro Adventure in Unreal Engine `5.7.4`.

## Recommended Unreal Input Approach

Use Unreal Enhanced Input with one public mapping context:

- Move: left stick and WASD/arrow fallback.
- Focus next/previous: bumpers and Q/E fallback.
- Confirm/scan: face button south and Enter/Space fallback.
- Cancel/back: face button east and Escape fallback.
- Help/hint: controller menu/view button or H fallback.
- Pause/menu: start/menu button and P fallback.

## M0 Validation Requirements

- Keyboard fallback works without a gamepad.
- Xbox-style controller input can navigate focus and submit scan/quiz actions.
- Exactly one destination or answer is focused at a time.
- Input state is visible through UI text and focus treatment, not color alone.
- Haptics remain deferred until a visible setting exists.

## Implementation Notes

Create the Enhanced Input mapping context in Unreal under `/Game/Input/IMC_AstroAdventure`. The C++ shell only guarantees the project compiles; Blueprint assets own the first playable input graph until the flow stabilizes.

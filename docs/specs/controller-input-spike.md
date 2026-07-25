# Apple Input Spike

## Status

Accepted planning spec for native Apple parity.

## Goal

Define one semantic input contract with touch, Siri Remote, keyboard development fallback, and physical controllers.

## Semantic actions

- Move: two-axis ship motion.
- Focus next/previous: cycle destinations or quiz choices.
- Confirm/scan: activate the focused action.
- Cancel/back: return without losing discovery progress.
- Help/hint: reveal age-appropriate guidance.
- Pause/menu: suspend gameplay and open settings.

`AstroUI` and `AstroWorld` consume semantic actions rather than controller brand button names.

## Platform mapping

| Action | iPhone/iPad | Apple TV | Physical controller |
| --- | --- | --- | --- |
| Move | Virtual thumbstick or direct gesture | Directional remote input | Left stick |
| Focus | Tap or swipe | Directional focus | D-pad, stick, or shoulders |
| Confirm/scan | Tap action | Select | Primary face button |
| Back | Visible back action | Menu/back | Secondary face button |
| Hint | Visible hint action | Focusable hint action | Configured auxiliary button |
| Pause | Visible pause action | Play/pause or menu | Menu button |

## M0 validation

- Touch completes the iOS mission without a gamepad.
- Siri Remote completes the tvOS mission without a gamepad.
- A connected Xbox, PlayStation, or MFi controller can navigate and submit actions.
- Exactly one destination or answer is focused at a time.
- Input state is visible through UI text and focus treatment, not color alone.
- Disconnecting a controller leaves a usable platform-default input path.
- Haptics remain disabled until a visible setting and non-haptic alternative exist.

## Implementation notes

Use SwiftUI actions for menus and learning panels, Game Controller for physical devices, and an input router for RealityKit movement. Display glyphs derived from the connected controller rather than hard-coding one brand.

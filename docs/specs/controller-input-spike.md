# Controller Input Spike

## Status

Accepted planning spec for the M0 Unity prototype.

## Covers

- Issue #3: Spike controller input and vibration lesson hooks
- Prepares issue #4: Create minimal Unity scene for deployment proof
- Prepares issue #12: Prototype solar system navigation

## Recommended Unity Input Approach

Use Unity's Input System package for the prototype instead of the legacy input manager.

Reasons:

- It has first-class gamepad bindings for Xbox-style controllers on PC.
- The same action map can support keyboard fallback for development.
- It keeps gameplay code independent from device-specific button names.
- It supports haptics through `Gamepad.current.SetMotorSpeeds`, with graceful fallback when unavailable.

The M0 scene should define one `PlayerInput` action asset with separate action maps for `Navigate`, `Interact`, and `System`. Keep bindings public-safe and platform-neutral. Do not commit private Xbox SDK notes or restricted package material.

## Public Input Mapping

| Player intent | Gamepad binding | Keyboard fallback | M0 use |
| --- | --- | --- | --- |
| Move or orbit cursor | Left stick | WASD or arrow keys | Move ship marker or destination focus |
| Camera/look preview | Right stick | Mouse or IJKL | Pan view or rotate astronomy object |
| Confirm/interact | South face button | Enter or Space | Select destination, scan object, answer quiz |
| Back/cancel | East face button | Escape or Backspace | Return from info state or cancel selection |
| Scan/ping | West face button | E | Trigger planet scan and reveal fact |
| Boost/thrust | Right trigger | Shift | Demonstrate force/thrust interaction |
| Brake/reverse thrust | Left trigger | Ctrl | Slow navigation or compare opposing force |
| Cycle destination | Left/right bumper | Q/E | Move focus between celestial targets |
| Pause/help | Menu button | Escape | Open pause/help shell |
| Mission log | View button | Tab | Toggle current objective or discovery notes |

## Lesson-Friendly Interaction Hooks

| Lesson hook | Input | Feedback |
| --- | --- | --- |
| Thrust and inertia | Right trigger boosts, left trigger brakes | Speed indicator, engine glow, optional low rumble |
| Gravity well awareness | Left stick steers near a planet | Orbit guide brightens as player approaches |
| Planet scanning | West face button scans focused destination | Fact panel appears with a short age-appropriate astronomy note |
| Scale comparison | Bumpers cycle among planets | Destination label shows relative size or distance phrase |
| Quiz confirmation | Face buttons select answers | Clear success/try-again status text, no time pressure |

## Haptics and Accessibility

Haptics are optional feedback, never the only signal. Vibration can reinforce thrust, scan pulses, and gravity wells, but every haptic cue needs a visible and/or audio equivalent.

Prototype rules:

- Default vibration intensity should be subtle.
- Provide a `Haptics Enabled` setting before using vibration in a kid-facing build.
- Show visual alternatives such as glow, pulse rings, progress bars, or status text.
- Avoid forced timers and sudden repeated vibration.
- Ensure keyboard fallback remains usable for development and accessibility testing.

## M0 Validation Tasks

- Confirm an Xbox-style controller is detected by Unity Input System on PC.
- Verify left stick, right stick, triggers, bumpers, face buttons, menu, and view inputs.
- Verify keyboard fallback for movement, confirm, cancel, scan, and pause.
- If haptics are available, test a short low-intensity pulse and confirm the no-haptics path still communicates the event.
- Record any platform-specific or private Xbox findings in the private repo.

## Done Means

A developer can create the minimal M0 scene with a single action asset, a controller-first movement or selection flow, clear no-vibration alternatives, and no new product decisions.


# Solar Passport: First Expedition

Supports public issue #22. This spec defines the first child-friendly implementation slice for the Solar Passport feature. It depends on `docs/specs/accessibility-baseline.md`, `docs/specs/controller-first-ui-baseline.md`, `docs/specs/first-mission-loop.md`, and `docs/specs/first-quiz-loop.md`.

## Goal

Solar Passport is a lightweight mission wrapper that lets kids start, complete, review, and replay the first expedition without needing accounts, open-ended menus, or adult setup.

The first expedition should feel like:

- Start from Home with New, Continue, Reset, and Quit choices.
- Pick up the current mission.
- Visit three space destinations.
- Collect one passport stamp per completed discovery.
- Review what was found in Mission View or Atlas View.
- Reset, replay, return home, or quit safely.

## Audience

- Primary players: ages 8-12.
- Secondary players: younger co-players with adult help.
- Play setting: couch, PC monitor, classroom display, or TV with an Xbox-style controller.
- Reading load: one instruction per screen, short labels, and no dense paragraphs during active play.

## First Expedition Scope

The first expedition reuses the `Signal Sweep` mission from `docs/specs/first-mission-loop.md`.

Destinations:

- Mercury.
- Mars.
- Europa.

Passport rewards:

- One stamp per destination after its scan and discovery check are complete.
- One expedition-complete mark after all three stamps are earned.
- Stamps are curiosity markers, not currency, streaks, loot, grades, or competitive scores.

Persistence:

- M1 may store passport progress in scene/session memory only.
- No child profile, account, name entry, cloud save, telemetry, leaderboard, or chat is required.
- Any future persistence needs a separate privacy and data-retention spec.

## Child-Friendly Flow

| Step | Screen | Player action | UX requirement |
| --- | --- | --- | --- |
| 1 | Home | Confirm `New Expedition` or `Continue` | Default focus starts on the safest useful action. |
| 2 | Mission View | Confirm the current objective | Shows the goal, stamp count, and next action in short text. |
| 3 | Atlas View | Choose Mercury, Mars, or Europa | One destination focused at a time with stable camera framing. |
| 4 | Discovery | Scan, read card, answer check | Uses first mission and quiz loop behavior. |
| 5 | Stamp Award | Confirm to continue | Shows the earned stamp with text plus icon or shape. |
| 6 | Mission View | Choose next destination, open Atlas View, or review progress | Completed and remaining stamps are obvious without color alone. |
| 7 | Expedition Complete | Replay, reset, return home, or quit | Celebrates completion and names the learning concept. |

Required completion copy concept:

- "First Expedition complete: you matched three space clues."

## Menus

Home menu:

- New Expedition.
- Continue, only when in-session progress exists.
- Reset, only when there is current in-session progress or completed expedition progress to clear.
- Quit.
- Settings placeholder.

Home behavior:

- `New Expedition` starts the first expedition with no earned stamps.
- `Continue` resumes the current in-session destination, Mission View, and earned stamp state.
- `Reset` clears current in-session expedition progress and keeps the selected age band.
- `Quit` exits the local build or opens a platform-safe exit confirmation.
- Home never asks for profile names, accounts, telemetry consent, or online setup.

Pause menu:

- Resume.
- Help.
- Restart Expedition.
- Return Home.
- Settings placeholder.

Passport review:

- Shows Mercury, Mars, and Europa stamp slots.
- Shows each completed stamp with destination name and one short clue.
- Shows incomplete slots as "Not discovered yet" rather than mystery pressure.
- Offers `Next Destination` when any destination remains.
- Offers `Replay Expedition`, `Reset`, `Return Home`, and `Quit` after completion.

## Mission View And Atlas View

Mission View is the kid-friendly objective screen for the current expedition.

- Shows the current objective, earned stamp count, next suggested destination, and a short progress message.
- Uses short labels and large readable controls.
- Avoids dense fact lists, grades, timers, currency, streaks, and competitive language.
- Provides routes to Atlas View, Passport Review, Help, Home, and Pause.

Atlas View is the destination selection screen.

- Shows Mercury, Mars, and Europa as focusable destinations.
- Shows completed and incomplete status through text plus icon, shape, or stamp silhouette, not color alone.
- Keeps destination focus visible during directional navigation.
- Allows returning to Mission View without losing progress.
- Camera framing must stay stable while focus changes, scan starts, scan ends, stamp feedback opens, and the player switches back to Mission View.

Camera stability:

- No focus change should cause disorienting camera snaps, drift, clipping, or target loss.
- Any zoom or pan should be brief, readable, and never required to identify the focused destination.
- Returning from pause, help, discovery, quiz feedback, or stamp award restores a useful view and focused element.

Kid-friendly HUD:

- HUD copy uses short action labels such as `Scan`, `Next`, `Back`, `Help`, and destination names.
- Stamp progress is shown as destination names plus icons or shapes.
- HUD elements stay readable from couch distance and avoid tiny persistent control text.
- HUD never depends on audio, vibration, color, or motion alone.
- HUD must not show grades, score pressure, streaks, currency, leaderboards, ads, chat, or monetized rewards.

Scan and stamp feedback:

- Starting a scan gives immediate visible feedback that the focused destination is being scanned.
- Successful scan feedback names the destination and opens the discovery card without losing focus.
- Completing the discovery check awards exactly one stamp for that destination.
- Stamp award feedback names the destination, shows the stamp in the passport slot, and gives a clear continue action.
- Re-scanning a completed destination may review its discovery, but must not duplicate stamps.

Settings placeholder:

- May expose read-only placeholders for captions, vibration, and motion until implementation exists.
- Must not show non-functional toggles as if they work.
- Haptics stay off unless a visible runtime setting and non-vibration alternative exist.

## Progressive Disclosure

Default screens show only the next useful action.

- Home explains no science content.
- Mission brief gives the goal, not all facts.
- Mission View shows the current objective, stamp progress, and next action.
- Atlas View reveals destination names and completion status.
- Discovery card reveals one sourced fact after scan.
- Quiz feedback explains one idea after answer submission.
- Passport review summarizes completed discoveries after stamps are earned.
- Help gives one nudge at a time. A second hint may be more direct.

Do not show:

- Full fact lists before scanning.
- Multi-step instructions on one screen.
- Locked feature grids that make the prototype feel incomplete.
- Timers, grades, streaks, currency, or reward pressure.

## Controller-First UX

Use `docs/specs/controller-first-ui-baseline.md`.

Input contract:

- Directional navigation: move focus through menus, destinations, answers, and review slots.
- Confirm: select, continue, scan, submit, or accept the focused action.
- Cancel/back: return to the previous safe screen without erasing earned stamps.
- Pause/menu: open pause options from mission, quiz, stamp, and review screens.
- Help/hint: reveal one contextual nudge.
- View switch: move safely between Mission View and Atlas View without resetting focus, camera, or stamp state.

Focus rules:

- Exactly one primary element is focused when a screen opens.
- Focus remains visible through outline, scale, shape, label, or icon plus contrast.
- Focus order follows visual order.
- Returning from pause, help, quiz feedback, or stamp award restores a useful focused element.
- Losing focus after state changes is a bug.

Layout rules:

- Keep controls readable from couch distance.
- Keep primary actions away from screen edges.
- Avoid tiny persistent control text.
- Do not require simultaneous inputs for core learning flow.
- Every screen in the flow must be completable without a mouse or keyboard.

## Local Review Checklist

Run this checklist before marking the feature slice done:

- Start a new expedition from Home using only a controller.
- Confirm Home exposes New, Continue when progress exists, Reset, and Quit or quit confirmation.
- Confirm Continue restores current Mission View, Atlas View destination focus, and earned stamps.
- Confirm Reset clears only the current expedition progress and keeps the selected age band.
- Navigate to each destination and complete scan, discovery card, quiz, and stamp award.
- Switch between Mission View and Atlas View before and after earning a stamp.
- Confirm camera framing remains stable during destination focus changes, scans, stamp awards, pause, and view switching.
- Confirm the HUD is readable, short, kid-friendly, and free of grades, timers, streaks, currency, and competitive pressure.
- Confirm scan feedback and stamp feedback are visible, specific to the destination, and not color-only.
- Make one incorrect quiz choice, request a hint, retry, and continue without losing progress.
- Pause during navigation, discovery, quiz, stamp award, and passport review; resume safely each time.
- Use back/cancel from discovery and review screens without erasing earned stamps.
- Confirm Mercury, Mars, and Europa stamps can be distinguished without color alone.
- Confirm all player-facing science facts are sourced or marked for curriculum review.
- Confirm no screen depends on audio, vibration, motion, or color alone.
- Confirm no public screen or doc exposes private Xbox deployment, signing, device, store, or certification details.

## Acceptance Criteria

- Home provides `New Expedition`, `Continue`, `Reset`, and `Quit` behavior with controller focus visible on every screen.
- `New Expedition` launches the first expedition from a clear passport state.
- `Continue` restores current in-session destination and stamp progress when progress exists.
- `Reset` clears only in-session expedition progress and keeps the selected age band.
- `Quit` exits or confirms exit without trapping focus.
- The first expedition includes Mercury, Mars, and Europa and uses the mission and quiz behavior defined in the existing first mission and first quiz specs.
- Mission View and Atlas View are distinct, reachable, and preserve progress, focus, and camera stability when switching.
- Completing a destination awards exactly one passport stamp and preserves that stamp through the current session.
- Scan and stamp feedback clearly name the destination and use text plus non-color-only visual support.
- Passport review shows completed and incomplete destination slots in readable, non-color-only form.
- The HUD remains short, readable, kid-friendly, and free of grades, timers, streaks, currency, and competitive pressure.
- Incorrect quiz answers offer retry and hint without removing scan or stamp progress.
- Pause, back, and help work from all learning states without trapping focus.
- The flow contains no required timers, account creation, profile naming, telemetry, leaderboards, monetized rewards, or competitive scoring.
- The feature can be locally reviewed with the checklist above using only an Xbox-style controller.
- The spec remains public-safe and contains no private platform validation evidence or restricted SDK details.

## Non-Goals

- Full campaign map.
- Permanent save system.
- User accounts or child profiles.
- Final art, animation, audio, or controller glyphs.
- Store-ready platform certification.
- Additional expeditions beyond the first Mercury, Mars, and Europa route.

## Open Questions

- Should the passport stamp style be destination-shaped, badge-shaped, or mission-control themed?
- Should `Continue` be hidden until progress exists, or visible in a disabled state with an empty-state explanation?
- What is the final owner for curriculum review sign-off on passport summary copy?

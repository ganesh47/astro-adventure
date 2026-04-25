# Solar Passport: First Expedition

Supports public issue #22. This spec defines the first child-friendly implementation slice for the Solar Passport feature. It depends on `docs/specs/accessibility-baseline.md`, `docs/specs/controller-first-ui-baseline.md`, `docs/specs/first-mission-loop.md`, and `docs/specs/first-quiz-loop.md`.

## Goal

Solar Passport is a lightweight mission wrapper that lets kids start, complete, review, and replay the first expedition without needing accounts, open-ended menus, or adult setup.

The first expedition should feel like:

- Pick a mission.
- Visit three space destinations.
- Collect one passport stamp per completed discovery.
- Review what was found.
- Replay or return home.

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
| 1 | Title/Home | Confirm `Start Expedition` | Default focus starts on the primary action. |
| 2 | Expedition Select | Confirm `First Expedition` | Locked future expeditions explain they are coming later. |
| 3 | Mission Brief | Confirm to launch | Shows the goal in one short sentence. |
| 4 | Navigation | Choose Mercury, Mars, or Europa | One destination focused at a time. |
| 5 | Discovery | Scan, read card, answer check | Uses first mission and quiz loop behavior. |
| 6 | Stamp Award | Confirm to continue | Shows the earned stamp with text plus icon or shape. |
| 7 | Passport Review | Choose next destination or finish | Completed and remaining stamps are obvious without color alone. |
| 8 | Expedition Complete | Replay or return home | Celebrates completion and names the learning concept. |

Required completion copy concept:

- "First Expedition complete: you matched three space clues."

## Menus

Main menu:

- Start Expedition.
- Continue Expedition, only when in-session progress exists.
- Passport Review.
- Settings placeholder.

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
- Offers `Replay Expedition` and `Return Home` after completion.

Settings placeholder:

- May expose read-only placeholders for captions, vibration, and motion until implementation exists.
- Must not show non-functional toggles as if they work.
- Haptics stay off unless a visible runtime setting and non-vibration alternative exist.

## Progressive Disclosure

Default screens show only the next useful action.

- Home explains no science content.
- Mission brief gives the goal, not all facts.
- Navigation reveals destination names and completion status.
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
- Navigate to each destination and complete scan, discovery card, quiz, and stamp award.
- Make one incorrect quiz choice, request a hint, retry, and continue without losing progress.
- Pause during navigation, discovery, quiz, stamp award, and passport review; resume safely each time.
- Use back/cancel from discovery and review screens without erasing earned stamps.
- Confirm Mercury, Mars, and Europa stamps can be distinguished without color alone.
- Confirm all player-facing science facts are sourced or marked for curriculum review.
- Confirm no screen depends on audio, vibration, motion, or color alone.
- Confirm no public screen or doc exposes private Xbox deployment, signing, device, store, or certification details.

## Acceptance Criteria

- `Start Expedition` launches the first expedition flow with controller focus visible on every screen.
- The first expedition includes Mercury, Mars, and Europa and uses the mission and quiz behavior defined in the existing first mission and first quiz specs.
- Completing a destination awards exactly one passport stamp and preserves that stamp through the current session.
- Passport review shows completed and incomplete destination slots in readable, non-color-only form.
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
- Should `Continue Expedition` appear only after progress exists, or stay visible with an empty-state explanation?
- What is the final owner for curriculum review sign-off on passport summary copy?

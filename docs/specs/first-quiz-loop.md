# First Quiz Loop

Supports public issue #14. Plugs into the first mission loop from `docs/specs/first-mission-loop.md` and the Mercury, Mars, and Europa navigation prototype from #12.

## Goal

Define a small quiz loop that reinforces discovery without feeling like a school test pasted onto the game. The first implementation should be controller-first, accessible, kid-safe, source-aware, and easy to connect to one scanned destination at a time.

## Design Principles

- A quiz is a discovery check, not a penalty gate.
- The player should answer from clues they just saw or interacted with.
- Incorrect answers lead to hints and retry, not lost progress.
- Facts must be sourced or marked `source needed`.
- Rewards should encourage curiosity and completion, not compulsion.

## Source Workflow

Question data should include:

- Destination id.
- Player-facing prompt.
- Answer choices.
- Correct answer.
- Feedback for correct, incorrect, and hint states.
- Source status: `sourced` or `source needed`.
- Source URL when sourced.
- Curriculum review status.

Preferred sources match `docs/wiki-seed/Planet-And-Solar-System-Facts.md`:

- NASA.
- ESA.
- NOAA or other public science agencies when relevant.
- Museum or university education resources.
- Public-domain or permissively licensed media for images.

Do not ship a player-facing fact as final unless it has a source URL or has been intentionally marked for source review in the question data.

## Question Format

The first loop uses multiple choice with three answers.

Why:

- Easy to navigate with a controller.
- Readable from couch distance.
- Simple to retry.
- Enough challenge for ages 8-12 without making scanning feel like homework.

Allowed later formats:

- True/false using the same focus and submit pattern.
- Matching if all options remain readable.
- Interaction-based questions after the mission loop is stable.

Non-goal for M1: free text entry.

## Controller Flow

Use `docs/specs/controller-first-ui-baseline.md`.

1. Quiz opens after the destination discovery card.
2. First answer choice is focused by default.
3. Directional navigation moves between answer choices.
4. Moving focus previews only the choice; it does not submit.
5. Confirm submits the focused choice.
6. Correct feedback offers continue.
7. Incorrect feedback offers retry and hint.
8. Cancel/back returns to the discovery card or destination info state without erasing mission progress.
9. Help/hint reveals one clue and returns focus to the answer list or retry button.
10. Continue marks the destination discovery check complete and returns to mission navigation.

Focus rules:

- Exactly one answer or feedback action is focused.
- Focus remains visible through outline, shape, scale, or icon plus contrast.
- Focus order follows visual order.
- Losing focus after submit, hint, retry, or continue is a bug.

## Quiz States

| State | Purpose | Player options | Exit |
| --- | --- | --- | --- |
| Question | Ask one clear prompt | Choose answer, back, hint | Submit or card |
| Correct feedback | Explain why the answer fits | Continue | Mission navigation |
| Incorrect feedback | Encourage retry | Retry, hint, back | Question or card |
| Hint | Give one useful clue | Return to choices | Question |
| Complete | Mark destination reflected | Continue | Mission navigation |

The quiz loop should avoid modal stacking. Feedback replaces or expands the question panel, then returns to a stable focused action.

## Feedback Copy Rules

Correct:

- Start with encouragement.
- Explain the science in one short sentence.
- Name the destination clue.

Incorrect:

- Avoid "wrong", "failed", "bad", or shame language.
- Point back to the clue.
- Offer retry and hint.

Hint:

- First hint references the scan card.
- Second hint may remove one clearly unrelated answer.
- Hints do not lower completion or reward.

Completion:

- Reward copy should be brief: "Discovery card complete" or "Clue matched".
- Avoid streaks, countdowns, leaderboards, currency, loot, or pressure loops.

## Example Questions

These are draft M1 examples for implementation and curriculum review.

### Mercury

- Prompt: "Which clue helps identify Mercury?"
- Choices:
  - "It is the closest planet to the Sun."
  - "It is famous for red rusty dust."
  - "It is an icy moon of Jupiter."
- Correct answer: "It is the closest planet to the Sun."
- Correct feedback: "Yes. Mercury orbits closest to the Sun."
- Incorrect feedback: "Try the clue about where Mercury travels."
- Hint: "Look for the clue that mentions the Sun."
- Source status: sourced.
- Source: NASA Mercury facts, https://science.nasa.gov/mercury/facts/

### Mars

- Prompt: "Why does Mars look red from far away?"
- Choices:
  - "Rusty iron is mixed into its dust."
  - "It is covered in red plants."
  - "Jupiter shines red light on it."
- Correct answer: "Rusty iron is mixed into its dust."
- Correct feedback: "Yes. Iron in Mars rocks and dust has rusted, which makes Mars look red."
- Incorrect feedback: "Try the answer that matches the dust clue."
- Hint: "Rust can turn iron reddish."
- Source status: sourced.
- Source: NASA Mars facts, https://science.nasa.gov/mars/facts/

### Europa

- Prompt: "What kind of world is Europa?"
- Choices:
  - "An icy moon of Jupiter."
  - "The smallest planet near the Sun."
  - "A red planet with rusty dust."
- Correct answer: "An icy moon of Jupiter."
- Correct feedback: "Yes. Europa is an icy moon, and scientists study its hidden ocean clues."
- Incorrect feedback: "Try the clue that says Europa is a moon, not a planet."
- Hint: "Europa travels around Jupiter."
- Source status: sourced.
- Source: NASA Europa facts, https://science.nasa.gov/jupiter/jupiter-moons/europa/europa-facts/

### Source Needed Placeholder

- Prompt: "Which destination has the strongest gravity tug in this prototype?"
- Choices:
  - "Mercury"
  - "Mars"
  - "Europa"
- Correct answer: source needed.
- Feedback: source needed.
- Source status: source needed.
- Note: Do not implement as a science fact until gravity values and age-appropriate wording are sourced and reviewed. If used as a gameplay-only question, label it as prototype behavior rather than astronomy fact.

## Accessibility Baseline

This quiz must satisfy `docs/specs/accessibility-baseline.md`.

- No timer by default.
- All answer choices are reachable with controller-only input.
- Answers are large, separated, and readable from couch distance.
- Feedback does not rely on color, sound, vibration, or animation alone.
- Haptic pulses are deferred for M0; if introduced later, they must be optional and paired with visible feedback.
- Incorrect answers preserve progress and offer retry.
- Help/hint remains available.
- Copy is short enough for ages 8-12 and avoids dense paragraphs.

## Mission Integration

The first mission loop calls one quiz after each scanned discovery card:

- Mercury scan opens the Mercury question.
- Mars scan opens the Mars question.
- Europa scan opens the Europa question.

On correct answer or completed retry:

- Mark that destination as reflected.
- Return to navigation.
- Show discovered state through icon/label/text plus visual treatment.
- If all three destinations are reflected, enter mission complete.

The quiz should expose simple events or state outputs for Unreal Blueprint/C++ implementation:

- `QuestionOpened(destinationId)`
- `AnswerSubmitted(destinationId, answerId, isCorrect)`
- `HintRequested(destinationId)`
- `QuizCompleted(destinationId)`
- `QuizExited(destinationId)`

## Asset Workflow

The first quiz can use text panels, simple icons, existing primitive scene elements, and UI materials. New images, icons, fonts, audio, generated art, Unreal binary assets, or third-party packages must follow `docs/specs/unreal-asset-hygiene.md` and be listed in `assets/manifest/assets.csv` before commit.

If answer cards use destination images, the image source and license must be public-safe and reviewed before player-facing use.

## Public-Safe Boundary

This spec is public-safe. It contains no Xbox validation steps, private device data, signing material, restricted SDK information, store metadata, or private build evidence. Keep implementation notes at the level of controller-first PC and Xbox-style couch play.

## Non-Goals

- Full question bank.
- Adaptive learning system.
- Account/profile persistence.
- Monetized rewards.
- Leaderboards, streaks, or competitive rankings.
- Free-text answer input.
- Final visual design language.

## Open Questions

- Should each destination always ask the same first question, or should future builds rotate between sourced variants?
- Should the hint button appear immediately or only after one incorrect attempt?
- What data format should hold sourced question metadata in Unreal?
- Who performs final curriculum approval for each player-facing fact?

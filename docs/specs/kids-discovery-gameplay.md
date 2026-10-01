# Kids Discovery Gameplay

Tracks issue #85 and extends the first mission and quiz loops across the current Solar System and Technology Lab catalog.

## Adventure loop

1. Mission Control invites the player to begin or continue exploring.
2. The player chooses a destination. A ship and beacon respond on a stylized training map; positions are not a scientific model of orbital distances.
3. Existing sourced photo cards introduce destination clues, with optional narration.
4. Picture questions let the player retrieve those clues, retry freely, and request help.
5. Completing the destination adds a Discovery Passport stamp and suggests another unexplored adventure.

There is no countdown, streak target, or player-facing ranking. Every correct clue earns the same internal discovery points regardless of attempts or hints. All completed rounds earn the same celebration. Internal score and history fields remain for compatibility with existing saves.

## State and recovery

- Each round keeps the age band and question set with which it started. Explorer Mode changes are unavailable during a round.
- The final correct answer records completion and rewards immediately and exactly once. Back, repeated select, or leaving feedback cannot discard or duplicate the reward.
- Back from mission completion returns to destination selection. Back at the welcome screen follows the tvOS system exit path.
- Siri Remote Play/Pause opens Resume and Return to Worlds controls. Returning to worlds keeps discoveries already recorded; an unfinished round starts again when reentered.
- Hints and retries never reduce the passport reward. Feedback explains the clue and invites another attempt.

## Accessibility and audio

- Controls keep visible focus and open with a primary action selected. Destination focus changes do not submit quizzes.
- Narration preference persists across stories. Junior Explorer quizzes speak the prompt, choices, and requested hint when narration is enabled.
- VoiceOver suppresses automatic app speech to avoid competing voices. Pause stops narration, and resume restarts the current content when enabled.
- Reduce Motion replaces custom movement and image/card transitions with immediate changes. Text and symbols explain discoveries without requiring motion, sound, or color alone.
- The science catalog and image provenance are unchanged by this gameplay update.

## Local progress

tvOS stores a bounded encoded log in device preferences and migrates a legacy file when available. iPhone and iPad retain atomic JSON storage. Saves are serialized and can be retried when storage fails. Load failures offer Retry or Begin a new space log; a new log is immediately queued for storage. Cloud synchronization remains future work.

## Validation

- Unit regressions cover earned rewards before Continue, duplicate and invalid actions, locked rounds, penalty-free help, safe destination focus, pause exit, completion Back, and next-adventure selection.
- Storage tests cover round trips, migration, chronological bounds, size limits, recovery, and coalescing ordered saves.
- Apple TV UI tests run with an isolated debug-only preference suite and exercise remote navigation, story cards, help/retry, pause/resume, completion, and persistence across relaunch.
- Both iOS and tvOS simulator builds, formatting, content validation, and repository/security checks remain release gates.

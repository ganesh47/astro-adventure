# Simple playground discoveries on Apple TV

> Historical implementation: [Photo Safari](photo-safari.md) now replaces this default play route. Saved playground postcards remain available in the passport.

## Scope and decision

Review date: 2026-10-18. Reviewed the native Mercury, Mars, and Saturn playgrounds from entry through all nine discoveries, pause, help, film, restoration, journal, and postcards. Fresh Siri Remote UI tests supplied the screenshots; source review supplied the dependency and persistence analysis.

Keep three discoveries per world. On TV, show only the one or two actions that can advance the current discovery. Each action names its effect and destination. Fetching a reusable tool is automatic. Retain the native diorama, scientific prerequisites, age-specific explanations, optional films, saved progress, and free play.

This follows Apple's guidance for legible content across the room and predictable native focus: [Designing for tvOS](https://developer.apple.com/design/human-interface-guidelines/designing-for-tvos/) and [Focus and selection](https://developer.apple.com/design/human-interface-guidelines/focus-and-selection/).

## Findings from the original flow

The original flow was completable with a remote, but understanding the next useful interaction required too much work. The most costly issues were structural:

1. **Entry — overloaded.** Mercury begins with three scene buttons although only the two impact sites advance the first goal. The sensor attracts focus before it is useful. Progress appears as small unnamed symbols, and the goal heading is only 20 pt. Evidence: Mercury entry (`artifacts/tvos-goals-review/before/01-mercury-start.png`).
2. **Acting — duplicated.** A scene target and the separate footer button perform the same action. Directions navigate a spatial target graph and also jump to utility controls at its boundaries. Children must learn both navigation and tool state. Evidence: Mercury entry (`artifacts/tvos-goals-review/before/01-mercury-start.png`).
3. **Advancing — unclear.** After brushing Mars's rock, the brush stays selected and the prominent button still says “Brush rock.” The instruction still asks for brushing and photographing together. The camera is a different target and earlier landmarks remain selectable. Evidence: Mars after brushing (`artifacts/tvos-goals-review/before/03-mars-brush.png`).
4. **Comparisons — too much tool bookkeeping.** Mercury requires pickup → sunny site → pickup → polar site. Saturn requires the same loop with an ice kit. Mercury can say the sensor is being carried while its primary button still says “Pick up sensor.” After Saturn's first discovery, the action can still say “Place ice” while the goal asks for motion. Evidence: Mercury sensor (`artifacts/tvos-goals-review/before/02-mercury-sensor.png`), Saturn ice (`artifacts/tvos-goals-review/before/04-saturn-ice.png`).
5. **Recovery — useful but indirect.** Help suggests a fixed first target even if the child has already used it. Small Help, Journal, and Pause controls compete with gameplay. Restoration correctly pauses progress, but selection and tool ownership still need to be reconstructed by the player. Evidence: Mercury sensor capture plus the recorded restore and help test actions.
6. **Completion — strong.** A postcard, saved journal, and explicit Keep playing / Worlds choices provide a clear stopping point. Preserve this behavior. Evidence: Postcard (`artifacts/tvos-goals-review/before/05-postcard.png`), Journal (`artifacts/tvos-goals-review/before/06-journal.png`).

## Implemented TV flow

1. **Enter — clear.** A short welcome explains choosing and pressing. The current discovery has a large title and explicit “Discovery 1 of 3” and “0 of 2 tried” progress. The first useful action receives focus.
2. **Try — clear.** One horizontal row contains one or two large native buttons. Left/right changes focus; Select performs the named action. Focus alone never records an observation. Completed actions disappear from the guided row.
3. **Discover — explicit.** An intermediate discovery shows its explanation and one focused Next discovery button. The child controls when the next goal appears. The model stays visible and active so Saturn's orbital motion can be watched before continuing; there is no timer. Options still pauses the world.
4. **Compare — direct.** Test sunny ground / Test polar shadow and Add ice near Saturn / Add ice farther out move the same reusable kit automatically. Each location still requires a separate deliberate action and the original observation predicates.
5. **Recover — predictable.** Options and Back open pause controls. Help returns to the next unfinished action. Films, journal, narration, reset, and Worlds remain available. Save restoration resumes only after an explicit choice and offers the unfinished action. Closing pause on the postcard restores Keep playing focus.
6. **Keep — preserved.** The original postcard and once-only reward ledger remain. Keep playing exposes the repeatable tool row, including placements without fetching a kit. Using a free-play tool retains its focus and scrolls it fully into view. Touch retains its existing spatial playground controls.

## Every discovery

| World / discovery | TV actions |
| --- | --- |
| Mercury: crater patterns | Drop small rock; Drop big rock, in either order |
| Mercury: scattered rock | Follow bright trail |
| Mercury: sunlight and shadow | Test sunny ground; Test polar shadow, in either order |
| Mars: rover route | Visit crater; Visit big rock, in either order |
| Mars: rock layers | Brush dusty rock → Take rock photo |
| Mars: ancient water | Run ancient river → Compare sand and photo |
| Saturn: ring particles | Add ice near Saturn; Add ice farther out, in either order |
| Saturn: orbital motion | Watch icy pieces move |
| Saturn: viewing angle | Look from the side |

Mercury requires five model actions instead of seven, Saturn four instead of six, and Mars six as before. Each world also has two consistent Next discovery confirmations. These counts exclude arrival, navigation, pause, and completion choices; no measured claim about total completion time is made.

## Implementation contracts

- `ExplorationSession.guidedTargets` projects currently available targets onto missing observations of the first incomplete goal. It excludes pickup targets. After all goals, it returns repeatable available tools.
- `performGuidedAction` rejects unrelated, unavailable, repeated guided, paused, and non-playing actions. For a placement it retrieves the authored kit and places the same item atomically before persisting. Existing observations, model settings, prerequisites, reward authority, and postcard snapshots remain authoritative.
- Guidance copy is optional content metadata. It changes no save schema, adventure revision, goal ID, target ID, concept ID, or observation ID. Older partially completed saves remain valid.
- Active TV text uses 22–36 pt type and native focusable action buttons. High-contrast labels and visible native focus supplement color. A dark backdrop supports feedback, while the scene remains visible between the controls.
- The intermediate acknowledgement is presentation state. Relaunch goes through the existing paused cursor, retains the earned discovery, and offers the next unfinished action; explanations remain in the journal.

## Evidence and verification

Fresh captures and exported test attachments are in `artifacts/tvos-goals-review/` in the local workspace. Before captures came from `/tmp/astro-tv-goals-before.xcresult` (all three original playgrounds completed). The local `review.html` places before/after captures and findings together in flow order. These diagnostic artifacts are intentionally excluded from the repository; the source and behavior contracts in this spec are permanent.

Automated coverage includes every guided journey in every age mode, one/two-action bounds, selection without activation, invalid and repeated actions, paused input, original carried-item saves, partial comparison restoration, free play, and once-only postcards. Existing touch journeys remain covered separately.

Screenshots establish layout and visible focus, and UI tests establish remote reachability. They do not establish physical Siri Remote comfort, reading at an actual couch distance, VoiceOver output, or Reduce Motion behavior on hardware. Those require a device pass; this review does not claim full accessibility compliance.

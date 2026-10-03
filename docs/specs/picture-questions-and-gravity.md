# Picture Questions and Gravity Playground

Supports issue #97. This extends the learning design, accessibility baseline, and controller-first UI baseline.

## Answer pictures

Each bundled lesson, picture round, mission, review question, and film checkpoint authors a `QuizPicture` on every choice. The descriptor contains a scene, a readable label, optional explanatory detail, and explicitly authored color or fraction where needed. The native vector renderer reads these fields; it never reads correctness, choice position, score, answer IDs, or semantic substrings.

Pictures represent proposals, including distractors. A rocky world, a moon, and a star have different forms. Gas and ice giants have clouded atmospheres rather than rocky craters. Spin direction, orbital center, axis tilt, surface and subsurface water, particulate rings, and actual vehicle structures have their own scenes. Coverage diagrams use the authored fraction. Earth diameter comparisons use an explicit ratio table and a common diameter unit. Other shapes are illustrative rather than scale models. Quantities remain readable as text with their units.

The reviewed catalogs fail on an unmapped authored proposal instead of assigning a generic moon image. Optional picture decoding remains compatible with older saved questions. Such a legacy choice retains its readable answer text until a new reviewed round supplies a picture. The mission authoring script preserves descriptors by prompt and exact choice identity/text, rejects changed proposals, and never infers pictures from the correct answer.

Select a proposal, then choose Check Answer. Selection and focus use marks and outlines. Correctness appears only after submission. Explanatory feedback offers retry, hint, Story, or film replay where the source supports it. Prompts, progress, answer cards, and controls scroll at large text sizes; text is not truncated or scaled down. Motion is limited to short entrances, selection, and focus; Reduce Motion removes these transitions. Narration is optional and VoiceOver reads the same proposals without duplicate speech.

Background imagery does not determine foreground safe areas or intercept controls. The bottom Pause bar reserves its space. Story cards and the pause panel scroll when text grows, and Story returns to the new card's top on Next or Previous. Controls stack at accessibility text sizes.

## Optional challenge

Practice is the default. Players may choose a 90-second challenge and return to calm practice at any point. This clock uses monotonic active time. Independent pause reasons cover inactivity, the pause panel, speech, visible help, Story, feedback, and restoration. Removing one reason cannot remove another. Spoken content pauses before speech begins and resumes only for the matching completed or cancelled utterance. Countdown changes do not repeatedly announce through VoiceOver or write a save every tick.

Expiry preserves the selected answer, question, attempts, discoveries, and rewards. It never submits an answer. More Time restores at least the generous allowance; Continue in Practice removes time pressure. A restored challenge keeps its saved budget and starts paused until Resume Challenge. Interaction tokens reject stale answers, old callbacks, and duplicate feedback actions after a transition.

The challenge adds no speed score or mastery advantage. Answer evidence records attempts, assistance, and whether challenge mode was used. Help and incorrect retries remain assisted evidence. Existing mission, film, concept, checkpoint, and reward rules continue to apply.

## Saved progress

Schema 5 adds the locked bonus question set, its age band, cursor, attempts, assistance, selected proposal, remaining challenge budget, and up to 64 recent evidence rows. Story, Worlds, and relaunch preserve this round. Fresh content cannot replace locked questions mid-round. Starting another learning activity clears the old bonus round deliberately; fresh activities start in calm practice.

Schemas 1–4 and missing legacy versions migrate with their earned ledgers intact. Unknown future versions and malformed data fail visibly. Both file and preferences stores validate existing bytes before a save, including a save performed without a prior load. Failed loads cannot fall back over an incompatible preferences payload or replace it with a fresh space log. The recovery screen offers Retry and preserves the original data. The existing save queue coalesces and retries the newest complete progress snapshot atomically.

## Gravity experiment

The separate, ungraded Gravity Playground compares Earth, the Moon, and Mars. The Moon is named as a moon. The same ball keeps its mass, initial speed, and launch angle when worlds change. Angle is measured from horizontal; speed uses metres per second, distance uses metres, time uses seconds, mass uses kilograms, and weight is gravitational force in newtons. Weight is `mass × gravity`; changing mass alone cannot change the no-drag flight path.

| World | Local gravity used | Definition and source |
| --- | --- | --- |
| Earth | 9.82 m/s² | [NASA Earth fact sheet](https://nssdc.gsfc.nasa.gov/planetary/factsheet/earthfact.html), mean surface gravity |
| Moon | 1.62 m/s² | [NASA Moon fact sheet](https://nssdc.gsfc.nasa.gov/planetary/factsheet/moonfact.html), surface gravity |
| Mars | 3.73 m/s² | [NASA Mars fact sheet](https://nssdc.gsfc.nasa.gov/planetary/factsheet/marsfact.html), mean surface gravity |

These quantities are distinct from effective acceleration including rotation and Earth's defined standard gravity of 9.80665 m/s². [NASA's parameter notes](https://nssdc.gsfc.nasa.gov/planetary/factsheet/fact_notes.html) describe the distinction.

The analytic model uses `x = v cos(angle) t` and `y = v sin(angle) t − g t²/2`, following [NASA's ballistic flight equations](https://www1.grc.nasa.gov/beginners-guide-to-aeronautics/ballistic-flight-equations/). The ball starts and lands at the same elevation on flat local ground, with constant gravity and no air resistance, wind, thrust, rotation, or curvature. These are short-distance educational trajectories, not real-world landing predictions. The screen cannot make the player's body feel lighter.

Every world and the dashed Earth comparison use one isotropic metres-to-screen scale and the same seconds of playback. The renderer does not stretch each flight to the same height, range, or duration. Positions come from elapsed active time, not accumulated frame deltas; ground contact clamps once at the analytic landing time. Lower gravity produces a longer, higher, farther flight under the same launch conditions.

Launch settings are locked during a flight. Pausing or entering the background freezes the current flight; returning requires explicit resume. Relaunch creates a fresh generation, cancelling old sampling callbacks. Reduce Motion shows a static trajectory and equivalent readable metrics. Predictions, launches, and landings do not award quiz mastery or modify the learning ledger. No Sun or gas-giant ground landing is offered.

## Validation gates

- Full core, content, service, and Python regressions, including catalog coverage and generator preservation.
- Schema 1–4 migration, future/corrupt byte preservation, complete schema 5 round trip below 256 KB, and atomic failed-save retry.
- Question retry, hint, Story, Worlds, Back through the start menu, relaunch, selected-answer preservation, nested challenge pauses, expiry, and stale input tests. Mission questions and video replay retain selection and elapsed challenge budget through menus and relaunch during replay.
- Analytic physics, shared projection and clock, mass/weight distinction, bounds, pause, relaunch, and one-time landing tests.
- Phone, iPad portrait/landscape, TV 1080p and 4K captures at normal and large text sizes; remote focus, touch, audio-off, Reduce Motion, and accessible labels reviewed from actual app output.
- Reviewed scientific captures load the actual catalog's durable mission, film, and bonus cursors through the existing debug progress fixture. They cover Saturn's ring centers, Earth illumination and sunlight angle, Titan liquids, Uranus polar illumination, Triton capture, river deltas, Mars's red-liquid proposal, and DSN rotation.
- Independent review and current checks on the exact candidate head before any authorized merge or release.

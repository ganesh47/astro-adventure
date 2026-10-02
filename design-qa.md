# Living planet playgrounds — design and interaction QA

Issue: https://github.com/ganesh47/astro-adventure/issues/91

## Source and comparison scope

Source visual truth: [selected Rover Expedition concept](assets/design/living-playgrounds-reference.png), 1672 × 941 pixels, unframed landscape artwork. It establishes the warm terrain, ivory/cyan/yellow helper, persistent world, upper-left invitation, upper-right utilities, directional aiming, and yellow contextual action. The approved implementation is a native fixed-camera toy diorama, not a raster replica of its cinematic terrain. Procedural manipulable 3D models, SF Rounded typography, native focus effects, and a brush/photo investigation replace the concept's fictional X-ray. Those are intentional game and science constraints.

This comparison does not claim identical camera framing, photorealistic geometry, or a pixel match. The source's imagined scanner state is compared with the implemented brush/photo state. Film, passport, and portrait layouts have no separate source mock; they are reviewed against the approved flow and the same design language.

Full-view evidence was opened together with the source in the same comparison inputs. The final screenshots below are actual XCTest captures, not generated mockups. Phone EXIF orientation 8 was normalized without modifying content. No browser, device bezel, or canvas surrounds the captures. Native point sizes replace CSS dimensions.

| Evidence | Pixels / native viewport / density | State and capture provenance |
| --- | --- | --- |
| [Apple TV Mars](assets/design/qa/01-mars-tv.png) | 1920 × 1080 / 1920 × 1080 pt / 1× | Brushed model rock, goal 2, focused brush. `/tmp/astro-playgrounds-tv-acceptance-6.xcresult` |
| [iPhone Mars](assets/design/qa/02-mars-touch.png) | 2622 × 1206 / 874 × 402 pt / 3× | Rock photographed, goal 3 invitation, water tool visible below HUD. `/tmp/astro-playgrounds-ios-layout-final.xcresult` |
| [iPad portrait Mars](assets/design/qa/03-mars-ipad.png) | 1488 × 2266 / 744 × 1133 pt / 2× | First goal; entire rover, helper, rock, landmarks and controls fit. `/tmp/astro-playgrounds-ipad-framing.xcresult` |
| [Optional Mercury film](assets/design/qa/04-mercury-film.png) | 2622 × 1206 / 874 × 402 pt / 3× | First pending observation; preceding NASA frame, caption, credit, Try/Continue/Replay. `/tmp/astro-playgrounds-ios-film-frame-final.xcresult` |
| [Unavailable film](assets/design/qa/05-unavailable-film.png) | 2622 × 1206 / 874 × 402 pt / 3× | Deliberately missing movie resource; NASA illustration and explicit return. `/tmp/astro-playgrounds-ios-missing-media-final.xcresult` |
| [TV film transport](assets/design/qa/06-tv-film-transport.png) | 1920 × 1080 / 1920 × 1080 pt / 1× | Complete vertical seek labels and sticky title/Back. `/tmp/astro-playgrounds-tv-transport-final.xcresult` |
| [TV film invitation](assets/design/qa/07-tv-film-checkpoint.png) | 1920 × 1080 / 1920 × 1080 pt / 1× | Preceding globe frame retained with prompt and every explicit action. Same targeted result bundle. |
| [Saved Mercury creation](assets/design/qa/08-mercury-passport.png) | 2622 × 1206 / 874 × 402 pt / 3× | Actual one-small/one-large impact snapshot, ejecta and sensor placed in shadow. `/tmp/astro-playgrounds-ios-postcards-scroll-final.xcresult` |
| [Saved Mars creation](assets/design/qa/09-mars-passport.png) | 2622 × 1206 / 874 × 402 pt / 3× | Full photographed strata, rover route, ancient river and compared deposits. Same result bundle. |
| [Saved Saturn creation](assets/design/qa/10-saturn-passport.png) | 2622 × 1206 / 874 × 402 pt / 3× | Full separate ice populations and the saved edge-view/motion setting. Same result bundle. |

TV and concept have approximately matching 16:9 aspect ratios. Phone and tablet evidence is evaluated as responsive adaptation; their differing aspect ratios are not classified as density or camera defects. Images are stored at native pixel density and displayed proportionally. The upper invitation/helper, focused target, lower contextual action, film prompt and transport labels were also examined at readable image resolution. Separate cropped substitutes were unnecessary because these regions were legible in the full captures.

## Required fidelity surfaces

- **Fonts and typography:** SF Rounded heavy display titles and bold yellow goal titles preserve the source's playful hierarchy. Native rounded fonts replace the concept's unspecified display face. Phone titles remain readable at 19 pt; TV titles use 36 pt. Body instructions wrap into complete sentences. Film titles remain above scrolling content. TV seek controls now stack vertically at 24 pt without split words or truncation. No observed truncation of required instructions or persistent controls remains in the accepted captures.
- **Spacing and layout rhythm:** Invitation and tools retain the source's corner grouping; the yellow action stays at lower right with aiming at lower left. Compact touch hotspots now use the measured HUD bottom and deterministic separation rather than intersecting the invitation. Portrait projection preserves scene width. Film uses a side-by-side frame and controls on landscape/TV, with a sticky Back action. Passport layout uses a compact fixed header on short screens.
- **Colors and tokens:** Warm rust/ochre terrain, ivory helper/rover, bright cyan tool outlines, yellow selected actions, white text and dark scrims follow the selected palette. Native TV focus adds a white elevated plate; selection also has a label and semantic state. The higher saturation of the toy material is an accepted stylized choice; subtle lighting refinement remains optional polish.
- **Image quality and assets:** The actual generated transparent helper cutout appears in invitations, with no missing image or halo. Generated, reviewed regolith material supplies tactile detail on irregular terrain and outcrop meshes. Cream strata become visible after brushing, and rover/shadow/photo/water changes are visible. The native procedural models are interactive science toys; they intentionally differ from cinematic reference geometry. NASA frames retain aspect ratio and credits; missing media displays credited imagery. Multiple RealityKit passport thumbnails were rejected after a blank capture and replaced with lightweight science-model illustrations derived from saved state. The accepted saved-Mercury capture shows the child's recorded craters and sensor; spoken model descriptions accompany these diagrams.
- **Copy and content:** Main instructions ask children to make, brush, photograph, carry, compare and change things. The original mandatory answer gate is absent from these adventures. The optional film button says “Watch a planet film”; pauses refer to the preceding segment rather than promising a clue for the current tool. Captions disclose enhanced color, exaggerated terrain, historical comparisons and simplified models. Ancient water is explicitly an imagined past model, and Mercury's permanent polar shadow is distinguished from temporary shade. Existing lessons remain under More missions and films.

## Comparison and fix history

| Finding | Initial evidence and impact | Fix and post-fix evidence |
| --- | --- | --- |
| P0: touch controls failed after dismissing overlays | Earlier isolated phone runs showed visible controls that could not activate after pause/celebration. | Remove underlying HUD/hotspot trees while overlays own input; use explicit layer order and keep the world non-interactive. Final full iPhone suite and all-three targeted tests require ordinary hittable Button taps and pass. |
| P1: missing illustrated helper and flat primitive terrain | Initial native captures lost the expressive asset and terrain/layer detail present in the source. | Load the real cutout from the bundle; add reviewed texture, irregular mesas, pebbles, exposed cream strata, rover detail and shadows. Final TV/touch Mars captures show these fixes. Procedural toy camera/model differences remain intentional. |
| P1: celebration thumbnail was blank | A second RealityView in the overlay obscured the child's completed creation. | Celebrate over the existing frozen world. All three touch and remote postcard captures show the creation behind the completion actions. |
| P2: compact hotspots intersected the goal card | `/tmp/astro-ios-isolated-v6-shots/DAE88E5F-E07B-4771-A624-CCD323BC4880.png` showed the water icon partly under the invitation. | Measure actual top HUD height, clamp hotspot bounds below it, separate neighboring targets. Final iPhone Mars capture and all-three button test confirm the water tool is visible and hittable. |
| P2: portrait camera cropped the rover and rock | `/tmp/astro-ipad-final-shots/B0011FDF-8860-47AF-BA00-F35629379FF0.png` clipped important scene subjects at both edges. | Widen vertical FOV only on portrait viewports, preserving landscape 44° projection. Final iPad capture shows the full scene; help/aim/action test passes with the expected observation. |
| P2: film title scrolled away and seek label split inside a word | Earlier TV clip capture hid the title; the next capture wrapped “Ahead” as “Ahea / d”. A smaller single-line font still truncated it. | Make header/Back persistent and use TV side-by-side layout; stack the seek buttons vertically at 24 pt. Final TV transport capture shows both full labels. The final targeted remote film test passes. |
| P2: checkpoint could show the following segment's first frame | Exact-boundary seeking could disagree with the preceding-segment invitation and caption. | Keep semantic checkpoint time exact but display the frame 0.05 s before the cut. Final Mercury film capture shows the preceding surface view and matching prompt. |
| P1: passport model thumbnails were blank | `/tmp/astro-playgrounds-ios-passport-layout-final-shots/9F0DC4BF-A2FF-49D5-9F59-4AA804297E31.png` shows a full but blank model thumbnail. | Keep the compact fixed header and replace concurrent GPU views with lightweight saved-state science illustrations. Fresh accepted Mercury capture is nonblank, shows the saved counts and shadow sensor, and the all-three completion/passport test passes. Spoken descriptions expose model details to VoiceOver. |

## Interaction and acceptance evidence

1. Choose a world and enter play — all three redesigned worlds open directly; all older destinations remain available.
2. Aim and manipulate — ordinary touch buttons and Siri Remote direction/Select complete all nine goals. Hints can aim a useful tool. Focus alone never activates it.
3. Pause and restore — carried Mercury sensor and discoveries restore with explicit Resume; backgrounding pauses movies and narration. Reset preserves earned rewards.
4. Observe films — forward seeking stops at the earliest pending invitation, Continue/Replay/Back remain explicit, and watching never awards a discovery. Missing media returns to playable illustrated material; the forced missing-resource test completes Mercury.
5. Celebrate and collect — completed worlds remain visible during celebration. Stamp/postcard/cursor commit together. Full saved creation illustrations render for all three worlds in the passport, which retains old stamps and keeps Back reachable while scrolling. The final all-three journey passes in 97.744 seconds.
6. Earlier learning flows — iPhone legacy missions, models, retries and videos pass. Full Apple TV suite passes all six tests, including all nine new goals; the final layout-only clip check also passes.

Package acceptance: 98 tests pass, including all ages, linked concepts/sources, goal prerequisites, migrations, invalid cursors, once-only rewards, clip state, bounded 256 KiB TV progress, and save failures. Python repository and release-verifier checks (26 tests), strict formatting, validation and both Release simulator builds pass. The read-only release verifier checks the validated source, exact build number, both platforms, processing, internal testing state and group assignment. Latest targeted iPhone all-three and film tests pass; portrait iPad semantic action test passes.

Accessibility evidence is limited to labeled semantic controls, focus/button completion, captions, code coordination that suppresses app narration with VoiceOver, and reduced-motion alternatives. No physical iPhone or Apple TV was connected, so physical VoiceOver operation, remote comfort and device rendering performance are not claimed. AVPlayer error UI is tested by missing media; reordered native status/seek/end callbacks are guarded but not deterministically injected.

## Implementation checklist

- [x] Native tool journeys, all ages, source review and legacy retention.
- [x] Compact touch HUD separation, portrait scene framing and real helper/material assets.
- [x] Optional observation films, paused restoration and missing-media completion.
- [x] Save migration, atomic postcards/stamps, duplicate prevention and bounded TV payloads.
- [x] Fresh TV transport capture and full remote regression.
- [x] Fresh nonblank passport illustration capture.
- Delivery is tracked in [PR #92](https://github.com/ganesh47/astro-adventure/pull/92): green public CI precedes merge, signed archives and read-only TestFlight verification.

## Follow-up polish

P3: richer native character rigging and more cinematic terrain lighting could bring the 3D toy further toward the artwork. Keep responsive framing, visible layers, button alternatives and model accuracy intact.

final result: passed

No actionable P0/P1/P2 visual findings remain in the accepted simulator states. Public CI and TestFlight are the subsequent delivery gates; physical-device accessibility and comfort remain the stated evidence limits.

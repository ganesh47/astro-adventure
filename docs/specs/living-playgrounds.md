# Living planet playgrounds

Implementation issue: https://github.com/ganesh47/astro-adventure/issues/91

## Experience

Mercury, Mars, and Saturn open directly into a fixed-camera living diorama. Each is one continuous adventure with three connected goals. An expressive companion invites an action, reacts to its consequence, and then lets the child explore further. No answer correctness, timer, life count, or video participation gates a reward. The other planets and bonus destinations retain their current content; More missions and films retains the original lessons on the three redesigned worlds.

Primary audience is ages 4–9. Ages 4–6 receive concrete spoken suggestions; ages 7–9 connect observations; ages 10–12 receive optional evidence and model limitations in the field guide. Measurements and spacecraft vocabulary belong in that optional material. Science models simplify time and scale explicitly. Mercury permanent polar shadows are distinguished from temporary shade. Ancient Martian water is a reconstruction, not a present-day river. Saturn is not a walkable world and its rings are separate icy particles.

## Native contracts

ExplorationSession owns semantic input, logical target selection, carried tools, placements, stepped model settings, observations, and deterministic goal predicates. RealityKit renders their consequences and cosmetic motion, with no direct reward authority. Stable adventure, goal, target, concept, and source IDs connect content, rendering, accessibility, persistence, and tests. Age and revision are captured at entry.

Touch targets and Siri Remote directions/Select operate the same actions. Focus changes alone never activate tools. Every manipulation has a button alternative. World/HUD input ownership prevents one direction from moving two selections. Optional clips suspend the world and retain their paused frame during two action invitations; explicit Continue film or Try it in the playground replaces multiple-choice questions. Boundary and periodic events pass through pure ObservationPlaybackState. Duplicate/stale callbacks cannot bypass pending invitations or award progress.

Pause, backgrounding, interruptions, and leaving stop world motion, narration, and films. Restoration is paused and resumption is explicit. Native transport uses generation and seek tokens to reject stale work.

## Save schema 4

All historical destination stamps, mission/video completions, scores, and concept review records remain. Playground completions use a separate stable-ID ledger with a logical postcard snapshot; unfinished lessons for a redesigned planet restart at arrival when its playground opens without inventing discoveries. Other unfinished lessons remain resumable. One bounded exploration cursor stores targets, carried item, placements, model settings, observations, goals, and optional clip time/invitation IDs. Invalid revisions restart safely while earned ledger entries remain. Completion, stamp, postcard, and terminal cursor enter one snapshot through the existing save queue. No entities, frame history, or postcard bitmap is serialized. TV storage remains bounded to 256 KiB.

The passport renders lightweight illustrated science-model postcards from each saved cursor. Crater counts, ejecta, sensor sites, exposed layers, photo/water/deposit state, and icy ring placements/view reflect that child's saved creation. These are model diagrams, not photographs. This avoids simultaneous RealityKit thumbnail surfaces, which produced blank previews during simulator visual QA. The live playground and its frozen completion scene retain the native 3D renderer.

## Art and credits

The selected Option 1 concept is [the checked-in visual reference](../../assets/design/living-playgrounds-reference.png). Its warm Mars terrain, expressive ivory/cyan/yellow companion, uncluttered world, and contextual tool action guide the native composition. The production game uses a camera and brush rather than claiming fictional rock X-ray capabilities.

The new explorer-companion.png sprite was created with the built-in OpenAI image generation tool using that concept as the reference. Prompt: “Create a transparent-background game sprite matching the hovering helper robot in the attached Astro Adventure design. One friendly small white rounded robot, warm yellow antenna and side discs, black face screen with bright cyan smiling eyes, subtle blue hover glow below. Premium soft 3D toy/clay materials, 3/4 frontal pose with one small arm waving. Centered isolated character only, 1024x1024 square, clean silhouette readable at small size, no landscape, no text, no UI, no frame. Preserve cheerful safe companion personality and cyan/yellow/ivory colors from reference. Actual alpha transparent background.” The returned transparent cutout was visually inspected and registered in assets/manifest/assets.csv. Existing NASA photographs and films retain their registered provenance and visible credits.

The original mars-regolith.png material was generated against the same reference and visually inspected before inclusion. Prompt: “Create a production game material texture: seamless tileable Mars regolith albedo texture, top-down flat orthographic diffuse surface only. Warm terracotta rust-orange sand with fine varied mineral speckles and tiny scattered irregular ochre pebbles embedded in the surface. Premium stylized soft 3D clay/toy art direction, subtly tactile and detailed, realistic-enough mineral grain with gentle color variation. Uniform surface detail across entire square; no large boulders, no horizon, no landscapes, no objects, no interface, no writing, no frame. No directional lighting, cast shadows, gradients or perspective. 1024 by 1024 square flat color texture suitable to tile on native 3D ground and rock meshes. Use the attached selected Mars scene as the warm palette and material-quality reference, but render only the seamless surface material.” This is an illustrative material, not a scientific photograph or measurement.

## Acceptance

Complete all nine goals in every age mode using core semantic actions, touch and Siri Remote UI. Check free hints, retry/reset, narration disabled, VoiceOver action alternatives, Reduce Motion, captions, offline resources, relaunch in each phase, carried-item restoration, clip invitation restoration, invalid revisions, storage failures, bounded payloads, and reward idempotency. Run package tests, format lint, Python repository checks, iOS/tvOS simulator builds, and UI regression tests. Fresh platform screenshots must be inspected against the selected concept. Physical-device rendering and remote comfort require actual hardware; simulator checks do not establish them. Follow the existing gated TestFlight pipeline.

# Real space Photo Safari

## Product decision

Mercury, Mars, and Saturn now open Photo Safari in the native iOS and tvOS game. This replaces the living playground as the default play experience. The goal is something a child can recognise immediately: spot a robot, a crater, ice, rings, or home in actual space imagery.

Each world has three short stops. A stop shows one spoken visual clue and two large photos. Choose the matching photo to open a discovery, or choose Show me for the same discovery and collection. Choosing the other photo gives a gentle visual hint. There are no lives, points, timers, or penalties. The child chooses Next photo after reading or listening. After three discoveries, a saved collection offers all three photos to reopen and a clear Explore another world action.

## TV and touch interaction

On Apple TV, native card focus starts on the first photo. Left/right chooses a photo; Select opens it. Focus alone records nothing. The next action receives focus after a reveal. Options, Back, and Play/Pause pause the activity. Back closes an album photo before opening pause. Resume restores the current photo or clue. Utility controls stay out of the photo row. Touch uses the same content and state machine, with a compact landscape layout.

Clues and facts can be narrated. The narration preference persists and app narration stops while VoiceOver is active, on pause, on backgrounding, or on departure. Photos have spoken labels, and every action is a standard button. Layout respects safe areas and uses high contrast on a dark background. No activity requires motion or timed input.

## Real images

The activity reuses nine offline images already credited in [image credits](../IMAGE_CREDITS.md) and registered in the [asset manifest](../../assets/manifest/assets.csv). No generated image stands in for spacecraft observations. Images fit their containers without cropping away evidence. Each discovery and passport photo displays its credit and caption. Captions explicitly identify annotated or stitched mosaics, projections, the Blue Marble composite, and missing panorama data.

| World | Things to spot | Source imagery |
| --- | --- | --- |
| Mercury | Round crater marks; the annotated Caloris outline; bright patches near hollows | MESSENGER PIA10176, PIA10383, PIA19425 |
| Mars | A wheeled robot; rocky surroundings; a white polar cap | Perseverance PIA24542, rover panorama PIA18409, Hubble PIA01247 |
| Saturn | Rings; backlit rings around a dark planet; Earth as a familiar comparison | Cassini PIA06193, PIA17172, Suomi NPP Blue Marble |

Facts have independently authored versions for all three age modes. Shared visual clues stay simple. Technical terms, processing explanations, and uncertainty appear in the discovery rather than being prerequisites for play. The Earth comparison is explicitly Earth, not an image taken from Saturn.

## State and compatibility

`PhotoSafariSession` wraps the existing bounded exploration cursor and completion ledger. Each safari has a new adventure ID, distinct from the historical playground IDs. One observation completes one photo stop. A selected completed stop represents its reveal; selecting the next unfinished stop acknowledges that reveal. The final playing phase represents the collection. These boundaries survive a save/relaunch with no schema change, followed by explicit resume.

Existing playground postcards, stamps, badges, and other mission progress remain in the passport. A historical in-progress cursor offers the new safari for that destination; its tool state is retired on entry. Historical playground UI remains available only to debug regression tests through `--legacy-playgrounds`. More missions and films keeps the existing lesson routes.

Collections award once, including when Show me is used. Looking again or replaying never adds another reward. Saved photo collections reopen in the passport with the fact, processing caption, and credit.

## Verification

Content and state tests cover every world and age, bundled image existence, credits, two unique choices, hints without penalties, assisted collection, paused input, reveal acknowledgement, restoration at each stop, the final album, once-only awards, bounded payloads, and preservation of historical postcards. Native TV remote and touch UI tests cover the new journey, focus, safe areas, restoration, album viewing, narration preferences, and passport viewing.

Simulator screenshots establish visible layout and remote reachability. Physical Apple TV reading distance, Siri Remote comfort, and spoken VoiceOver output still need a hardware pass.

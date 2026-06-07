# Solar System Art Direction

Supports public issue #22. This plan defines a public-safe source and style direction for stylized Solar System visuals. It does not approve, download, generate, or commit binary asset files.

## Status

Accepted as an art direction and source-reference plan for public repository review.

## Goals

- Establish a consistent, child-friendly visual language for Solar Passport destinations and stamps.
- Use NASA/public-safe media as factual reference, not as final copied textures.
- Keep all future asset work traceable through `assets/manifest/assets.csv` before files are committed.
- Prioritize Mercury, Mars, and Europa for the first Solar Passport expedition while leaving room for the full Solar System set.

## Public-Safe Source Rules

NASA media is a strong starting point because NASA says its content is generally not subject to copyright in the United States and may be used for educational or informational purposes. Before any production asset is made, contributors must still re-check the source page and NASA media guidance:

- Credit NASA and any listed partner credit exactly enough for later review.
- Do not use the NASA insignia, logotype, seal, mission patches, identifiers, or altered versions of them as game branding.
- Do not imply NASA approval, endorsement, sponsorship, or partnership.
- Avoid images with identifiable people, third-party copyright markings, private creator processing credits, or unclear redistribution terms.
- Treat Hubble, Webb, ESA, CSA, JAXA, citizen-science, and university-processed imagery as separate license-review cases, even when hosted by NASA.
- Do not commit downloaded reference files, thumbnails, intermediate exports, texture crops, or generated binaries until a manifest row and asset review explicitly approve them.

Source guidance:

- NASA media usage guidelines: https://www.nasa.gov/multimedia/guidelines/index.html
- Current manifest workflow: `docs/specs/asset-manifest-workflow-validation.md`
- Public/private boundary: `docs/specs/public-private-boundary-audit.md`

## Visual Pillars

- **Readable from the couch:** Each planet or moon should be identifiable by silhouette, scale cue, and one or two strong surface motifs before color is considered.
- **Stylized over photoreal:** Use simplified bands, cracks, caps, craters, rings, glow, and cloud shapes. Do not use NASA imagery as direct texture wraps unless a future review explicitly approves that use.
- **Educational but warm:** Surface details should suggest real science features without making the UI feel like a textbook or a satellite archive.
- **Passport-ready:** Each destination needs a stamp version that works at small size in monochrome, high contrast, and color.
- **Calm motion:** Idle animation can use slow rotation, drifting bands, twinkling stars, or soft scan pulses. Avoid rapid flashes, camera shake, or particle clutter.

## Palette And Shape Direction

| Destination | Core read | Stylized cues | Stamp silhouette |
| --- | --- | --- | --- |
| Sun | Warm glowing disk | Soft corona edge, looping surface arcs, amber-to-gold rim | Circle with short radial rays |
| Mercury | Small rocky world | Charcoal-gray craters, scarps, rough terminator | Pitted circle |
| Venus | Cloud-veiled world | Golden cloud bands, soft haze, radar-inspired contour lines | Smooth circle with swirl bands |
| Earth | Living blue world | Ocean blue, white cloud curls, green/brown land masses | Circle with cloud ribbon |
| Moon | Familiar gray companion | Basalt maria patches, crater clusters, quiet rim light | Cratered circle |
| Mars | Rust desert planet | Red-orange surface, polar cap, canyon slash, dust haze | Circle with cap and canyon mark |
| Jupiter | Giant banded planet | Cream/tan/brown bands, oval storm, wide scale | Large striped circle |
| Saturn | Ringed giant | Pale gold disk, clean ring ellipse, subtle banding | Ringed oval |
| Uranus | Tilted ice giant | Pale cyan disk, minimal clouds, tilted ring hint | Tilted circle/ring mark |
| Neptune | Deep blue ice giant | Rich blue disk, small storm mark, subtle bright streak | Blue circle with storm dot |
| Europa | Icy cracked moon | Pale ice, reddish-brown cracks, smooth low-crater surface | Cracked ice circle |

## First Expedition Priority

For issue #22, the first production pass should target:

1. Mercury destination card, navigation icon, and passport stamp.
2. Mars destination card, navigation icon, and passport stamp.
3. Europa destination card, navigation icon, and passport stamp.

These three should share a common stamp frame and differ by internal silhouette, texture motif, and label. They must remain distinguishable if viewed in grayscale or by a player who cannot rely on red/green/blue differences.

## Candidate Source References

The following references are listed as candidate rows in `assets/manifest/assets.csv`. They are source references only; no source image or derived binary asset is committed by this plan.

| Manifest id | Reference | Use |
| --- | --- | --- |
| `candidate_nasa_sun_sdo_reference` | NASA SDO Sun image | Color and corona reference for stylized Sun glow |
| `candidate_nasa_mercury_global_mosaic_reference` | NASA Mercury global mosaic | Crater density and gray-rock value reference |
| `candidate_nasa_venus_global_reference` | NASA/JPL Venus simulated global view | Hazy gold palette and contour/radar motif reference |
| `candidate_nasa_earth_blue_marble_reference` | NASA Blue Marble Earth | Cloud, ocean, and land color reference |
| `candidate_nasa_moon_mosaic_reference` | NASA/JPL Moon mosaic | Lunar maria and crater placement reference |
| `candidate_nasa_mars_global_color_reference` | NASA/JPL/USGS Mars global color views | Rust palette, polar cap, and canyon reference |
| `candidate_nasa_jupiter_global_reference` | NASA/JPL/USGS Jupiter view | Banded atmosphere and storm reference |
| `candidate_nasa_saturn_farewell_reference` | NASA Cassini Saturn mosaic | Ring silhouette and pale-gold banding reference |
| `candidate_nasa_uranus_voyager_reference` | NASA/JPL Uranus view | Minimal ice-giant disk and pale cyan reference |
| `candidate_nasa_neptune_voyager_reference` | NASA/JPL Neptune view | Deep-blue disk and storm reference |
| `candidate_nasa_europa_mosaic_reference` | NASA/JPL Europa mosaic | Icy crack pattern reference for first expedition |

## Production Plan

1. Confirm the manifest row and source page still match before any asset work begins.
2. Create original stylized sketches from multiple observations rather than tracing or texture-wrapping a single source image.
3. Keep source notes with the asset review issue or pull request, including the source URL, listed credit, modification summary, and whether AI assistance was used.
4. Export final art only after public repo and Xbox build review fields are updated appropriately.
5. Verify passport stamps at small UI size, grayscale, high contrast, and TV-distance scale.

## Acceptance Checklist

- Every visual candidate has a manifest row before asset files are committed.
- NASA-derived references include source URL, listed credit, and public-safe usage notes.
- No NASA logos, mission patches, people, private platform details, paid marketplace assets, or redistribution-unclear files enter the public repo.
- Mercury, Mars, and Europa can be recognized by shape and motif without relying on color alone.
- Final visuals remain friendly and stylized rather than photoreal texture copies.

## Non-Goals

- Committing binary assets, generated images, textures, models, or thumbnails.
- Finalizing a full asset pipeline or rendering implementation.
- Approving Xbox build use for any candidate source.
- Replacing curriculum review for science facts or labels.

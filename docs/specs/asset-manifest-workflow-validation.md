# Asset Manifest Workflow Validation

## Status

Accepted for public repository asset review.

## Covers

- Issue #15: Validate the asset manifest with representative candidate records.

## Goal

Keep asset review public-safe before any art, audio, model, texture, package, or generated placeholder enters the repository. The manifest may list candidates without committing the asset files, which lets contributors review provenance, license, AI involvement, and rejection decisions first.

## Candidate Validation

`assets/manifest/assets.csv` contains three candidate records and no corresponding asset files:

- `candidate_public_domain_starfield`: accepted NASA public-domain style candidate.
- `candidate_original_ai_planet_icon`: accepted original project-owned, AI-assisted candidate.
- `candidate_private_marketplace_ship`: rejected private-only or redistribution-unclear candidate.

These rows validate the workflow shape only. Review source metadata, attribution expectations, and usage guidelines before using an accepted candidate in game content, documentation, screenshots, or release materials.

For NASA-sourced media, check NASA's current media usage guidance before use: https://www.nasa.gov/multimedia/guidelines/index.html

## Required Fields

Every manifest row must include:

- `id`: stable lowercase identifier using letters, numbers, and underscores.
- `title`: human-readable asset title.
- `type`: one of `image`, `audio`, `model`, `material`, `font`, `video`, `text`, `package`, or `other`.
- `source_url`: a public URL, `original`, or `private-only`.
- `license`: one of `public-domain`, `cc0`, `cc-by-4.0`, `mit`, `apache-2.0`, `bsd-3-clause`, `original-project-owned`, `ai-generated-project-owned`, `proprietary-private-only`, or `unknown`.
- `author`: creator, source organization, or `Astro Adventure contributors`.
- `ai_generated`: `yes` or `no`.
- `tool`: tool name for AI-generated assets, otherwise `none`.
- `notes`: public-safe attribution, modification, or review notes.
- `approved_for_public_repo`: `yes`, `no`, or `needs-review`.
- `approved_for_xbox_build`: `yes`, `no`, or `not-reviewed`.
- `review_status`: `accepted`, `needs-review`, or `rejected`.
- `rejection_reason`: empty unless `review_status` is `rejected`.

## Approval Rules

Use `approved_for_public_repo=yes` only when the asset is original, public-domain, or permissively licensed for public redistribution, and the row has enough attribution to review later.

Use `approved_for_public_repo=needs-review` for candidates that look promising but still need source, author, license, AI, or attribution checks.

Use `approved_for_public_repo=no` for private-only, paid marketplace, restricted SDK, license-unclear, or redistribution-unclear material. Rejected rows may stay in the manifest as public-safe decision records, but the asset files must not be committed.

`approved_for_xbox_build` is a public-safe readiness flag for project planning only. It must not contain or imply private platform validation, certification status, account details, device details, restricted SDK details, or unpublished release information.

## AI-Generated Assets

AI-assisted or AI-generated assets must use `ai_generated=yes`, name the tool or workflow in `tool`, and use `license=original-project-owned` or `license=ai-generated-project-owned` only when the contributor can document that the project may redistribute the output publicly.

Do not use AI output that copies a living artist's style, recreates protected characters, depends on private prompts containing restricted material, or has unclear redistribution terms.

## Rejected and Private-Only Handling

Rejected/private-only candidates must use:

- `source_url=private-only`
- `license=proprietary-private-only` or `license=unknown`
- `approved_for_public_repo=no`
- `review_status=rejected`
- A public-safe `rejection_reason`

Do not add the underlying files, thumbnails, exports, previews, package contents, prompt logs, private URLs, account identifiers, or purchase details to this public repository. Keep any needed private records outside the public repo.

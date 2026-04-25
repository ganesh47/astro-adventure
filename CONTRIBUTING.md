# Contributing

Astro Adventure uses issue-first development. Please open or reference a GitHub issue before starting meaningful gameplay, curriculum, asset, or platform work.

## Workflow

1. Find or open an issue describing the proposed work.
2. Keep changes scoped to that issue.
3. Update docs or specs when behavior changes.
4. Track every new asset in `assets/manifest/assets.csv`.
5. Keep Xbox-private material out of this public repo.

## Asset Rules

Only add assets that are original, public-domain, permissively licensed, or otherwise approved for public redistribution. Paid marketplace assets, restricted SDK samples, and generated builds with restricted dependencies belong outside this repository.

Manifest candidates may be reviewed before asset files are added. Use `assets/manifest/assets.csv` to record source, license, author, AI status, approval flags, review status, and public-safe notes. Rejected or private-only candidates must be marked `approved_for_public_repo=no` and `review_status=rejected`; do not commit the asset files, thumbnails, exports, private URLs, purchase details, or other private evidence.

Unreal-generated files, binary assets, Git LFS timing, and public/private artifact boundaries are covered in `docs/specs/unreal-asset-hygiene.md`.

Allowed manifest values and candidate validation examples are covered in `docs/specs/asset-manifest-workflow-validation.md`.

## Kid Safety

Content should be age-appropriate for kids ages 4-12 through the documented age bands, avoid manipulative reward loops, use encouraging explanations, and support accessibility from the start.

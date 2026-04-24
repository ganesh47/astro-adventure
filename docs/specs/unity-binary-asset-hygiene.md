# Unity Binary Asset Hygiene

## Status

Accepted for M0 repository hygiene.

## Covers

- Issue #17: Add Unity gitignore and binary asset hygiene

## Goals

- Keep Unity-generated folders, local build outputs, caches, IDE files, and OS files out of commits.
- Keep public asset provenance clear before art, audio, models, textures, or packages enter the repo.
- Avoid leaking restricted Xbox material, certificates, private packages, paid source assets, or generated deployment artifacts.

## Git Ignore Policy

The root `.gitignore` excludes common Unity outputs such as `Library/`, `Temp/`, `Obj/`, `Build/`, `Builds/`, `Logs/`, `UserSettings/`, generated solution files, local IDE folders, platform packages, profiler captures, and local secrets.

Commit Unity source files that define the project or playable prototype, including:

- `Assets/**/*.cs`
- `Assets/**/*.unity`
- `Assets/**/*.prefab`
- `Assets/**/*.asset`
- `Assets/**/*.mat`
- `Assets/**/*.meta`
- `Packages/manifest.json`
- `Packages/packages-lock.json`
- `ProjectSettings/*.asset`

Do not commit generated build folders, exported packages, local player builds, crash dumps, profiler captures, or editor cache directories.

## Binary Asset Policy

Binary assets are allowed only when they are needed for the public prototype and are approved for redistribution. Every committed art, audio, model, texture, font, video, or third-party source asset must have an entry in `assets/manifest/assets.csv` before it is used in a scene or documentation.

Manifest entries should include:

- Stable asset id
- Human-readable title
- Asset type
- Source URL or `original`
- License
- Author or creator
- AI-generated flag and tool, when applicable
- Notes for attribution, modification, or usage constraints
- Approval flags for the public repo and Xbox build

Prefer small, source-friendly prototype assets while M0 is proving deployment. Large source files, layered art files, high-resolution textures, generated audio batches, and marketplace packs should stay out of the public repo until there is an explicit asset review issue.

## Git LFS Decision

Git LFS is not enabled yet.

Reason: the repository does not currently contain large binary Unity assets, and M0 should stay small enough to review without extra tooling. Revisit Git LFS when the repo needs to commit large original assets that are approved for redistribution, such as `.psd`, `.blend`, `.fbx`, `.wav`, `.mp4`, or high-resolution texture files.

If Git LFS is adopted later, add `.gitattributes` rules in the same change that introduces the first large approved asset family.

## Public and Private Boundary

Never commit the following to this public repository:

- Xbox certificates, keys, signing material, account tokens, or Partner Center exports
- Restricted SDK samples, headers, libraries, documentation, or generated packages
- Paid marketplace source assets unless the license explicitly allows public redistribution
- Private package feeds, package credentials, or generated builds with restricted dependencies
- Store metadata drafts that contain private business or release information

Public-safe notes about the Xbox Dev Mode proof may live in this repo. Private commands, credentials, device identifiers, certificates, and restricted workflow details belong in `ganesh47/astro-adventure-private`.

## Contributor Checklist

Before committing Unity or asset work:

- Confirm `.gitignore` is excluding only generated or private local files.
- Run `git status --short` and inspect each binary file deliberately.
- Add or update `assets/manifest/assets.csv` for every committed asset.
- Keep `.meta` files with their corresponding Unity assets.
- Move restricted or private-only artifacts to the private repo instead of adding ignore exceptions.


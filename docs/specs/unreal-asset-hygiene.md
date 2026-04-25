# Unreal Asset Hygiene

## Status

Accepted for the Unreal pivot.

## Goals

- Keep Unreal-generated folders, local builds, caches, IDE files, and packaged output out of commits.
- Keep public asset provenance clear before art, audio, models, textures, maps, or Marketplace assets enter the repo.
- Avoid leaking Xbox material, certificates, private packages, paid source assets, or generated deployment artifacts.

## Git Ignore Policy

The root `.gitignore` excludes Unreal generated output such as `Binaries/`, `Build/`, `DerivedDataCache/`, `Intermediate/`, `Saved/`, packaged builds, local IDE files, local validation artifacts, and private signing material.

Commit Unreal source/config files that define the public project:

- `AstroAdventureUE/*.uproject`
- `AstroAdventureUE/Config/**/*.ini`
- `AstroAdventureUE/Source/**/*`
- approved public `Content/**/*.uasset`
- approved public `Content/**/*.umap`

Do not commit packaged output, local editor caches, crash dumps, private packages, or restricted platform artifacts.

## Git LFS Policy

Git LFS rules are enabled for Unreal binary assets and common large media. Every committed `.uasset`, `.umap`, model, texture, audio file, or video must also have an asset manifest entry before review.

If Git LFS is unavailable locally, install it before adding binary Unreal assets.

## Asset Manifest Policy

Every committed art, audio, model, texture, font, video, Marketplace asset, generated image, `.uasset`, or `.umap` must have a row in `assets/manifest/assets.csv` with source URL or `original`, license, author, AI flag, review status, and public/Xbox approval flags.

Paid Marketplace source assets must stay out of the public repo unless their license explicitly allows redistribution.

## Public And Private Boundary

Never commit the following to this public repository:

- Xbox certificates, keys, signing material, account tokens, or Partner Center exports.
- Restricted SDK/GDK samples, headers, libraries, documentation, or generated packages.
- Paid Marketplace source assets without public redistribution rights.
- Private package feeds, package credentials, or generated builds with restricted dependencies.
- Store metadata drafts that contain private business or release information.

Public-safe notes about Xbox Dev Mode may live here. Private commands, credentials, device identifiers, certificates, and restricted workflow details belong in `ganesh47/astro-adventure-private`.

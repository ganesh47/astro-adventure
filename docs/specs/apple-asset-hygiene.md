# Apple Asset Hygiene

## Goal

Keep every committed visual, 3D, audio, video, font, and generated asset reviewable, redistributable, and suitable for a public native Apple build.

## Source-controlled assets

- Asset catalog metadata and small project-owned interface assets.
- USD text, shaders, configuration, and source art when redistribution is permitted.
- Binary USDZ/USDC, images, audio, video, and 3D source files through Git LFS.
- Original narration scripts and educational copy as text.
- Every asset listed in `assets/manifest/assets.csv`.

## Generated files

Do not commit:

- `DerivedData`, `.build`, archives, app bundles, IPAs, dSYMs, result bundles, or simulator data.
- Signed builds, provisioning profiles, certificates, App Store Connect keys, or TestFlight exports.
- Xcode user data or machine-local workspace state.
- Outputs that can be regenerated from a committed source asset unless review explicitly requires them.

## Licensing

An asset may enter the public repository only when its source, author, license, AI involvement, modifications, and redistribution rights are clear. Paid or proprietary assets without public redistribution rights may be evaluated as rejected manifest candidates, but their files and previews must not be committed.

NASA media still requires item-level review and appropriate attribution; a government source does not eliminate the manifest requirement.

## AI-assisted assets

Record the tool and workflow. Do not request protected characters or imitation of a living artist's style. Only commit output when contributors can document the project's right to redistribute it and the result has passed human visual and curriculum review.

## Git LFS

Install Git LFS before adding file types configured with an LFS filter in `.gitattributes`. Confirm the file appears in `git lfs ls-files` and has an accepted manifest row before opening a pull request.

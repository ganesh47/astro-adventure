# PC Toolchain Checklist

## Purpose

This checklist prepares a Windows development PC for Unreal-first Astro Adventure work and later Xbox Dev Mode proof runs. It uses public tooling and public documentation only, and it avoids publishing machine-specific paths or runner identities.

## Chosen Baseline

- Unreal Engine: `5.7.4`.
- Existing local UE 5.4 install: ignored, not an accepted fallback.
- IDE: Visual Studio 2022 with C++ game development tooling.
- First build target: Windows editor/development.
- Long-term target: Xbox through the appropriate public onboarding path and private release guardrails.

## Checklist

| Area | Requirement | Validation |
| --- | --- | --- |
| Windows | Windows 10 or Windows 11 with current updates. | Run `winver` and record edition/version/build. |
| Unreal Engine | Unreal Engine `5.7.4` installed through Epic Launcher. | `UnrealEditor-Cmd.exe -version` reports 5.7.4. |
| Engine Path | Local shell can find UE 5.7.4. | Set `UNREAL_ENGINE_ROOT` to the local engine root before running build commands. Do not commit or publish personal filesystem paths. |
| Visual Studio | Visual Studio 2022 installed. | Help > About shows exact version. |
| C++ Tooling | C++ game development workload installed. | Visual Studio Installer lists C++ tools, MSVC, and Windows SDK. |
| C++ Standard Library | MSVC standard headers installed. | `Test-Path "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\<version>\include\type_traits"` returns true. |
| Git LFS | Git LFS installed before binary assets are added. | `git lfs version` succeeds. |
| Project | `AstroAdventureUE.uproject` opens in UE 5.7.4. | Editor opens without converting to another engine version. |
| Build | Editor and game targets compile locally. | Local build commands complete and produce a sanitized pass/fail summary. |
| Xbox Dev Mode | Xbox is activated for Developer Mode when M3 begins. | Private evidence only; do not commit screenshots or identifiers. |

## Version Record Template

```text
PC:
Windows:
Unreal Engine:
Unreal path: local-only; do not publish personal path
Visual Studio:
Installed Windows SDKs:
Git LFS:
Xbox model/family:
Deployment route:
```

## Issue Coverage

Supports M0 Unreal parity, self-hosted validation, and the later Xbox Dev Mode proof.

## Troubleshooting

If Unreal fails with `fatal error C1083: Cannot open include file: 'type_traits'`, Visual Studio has detected an MSVC toolchain folder but the C++ standard library headers are missing. Open Visual Studio Installer and add or repair `Game development with C++`, including MSVC x64/x86 build tools and a current Windows SDK.

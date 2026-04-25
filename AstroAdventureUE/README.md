# AstroAdventureUE

Primary Unreal Engine project for Astro Adventure.

## Engine

Target engine: Unreal Engine `5.7.4`.

Do not scaffold, compile, or validate this project with the locally installed UE 5.4. Install UE 5.7.4 first and point the self-hosted runner to that engine path.

Expected local command path after install:

```text
G:\Unreal\UE_5.7\Engine\Binaries\Win64\UnrealEditor-Cmd.exe
```

If Epic Launcher installs UE 5.7.4 elsewhere, set `UNREAL_ENGINE_ROOT` for the self-hosted runner.

## M0 Parity Target

`M0_DeploymentProof` rebuilds the prior proof in Unreal:

- Explorer ship pawn.
- Mercury, Mars, and Europa destinations.
- Keyboard and Xbox-style controller movement.
- Focus cycle, scan action, discovery card, quiz, completion state.
- Automated validation through the self-hosted Unreal workflow.

Binary assets are intentionally not committed yet. The first Unreal editor pass should create the map, input mapping context, UI, and data assets named in `Content/README.md`.

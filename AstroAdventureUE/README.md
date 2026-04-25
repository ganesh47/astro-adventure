# AstroAdventureUE

Primary Unreal Engine project for Astro Adventure.

## Engine

Target engine: Unreal Engine `5.7.4`.

Do not scaffold, compile, or validate this project with older Unreal installs. Install Unreal Engine 5.7.4 first and keep build validation local unless the project later adds an explicitly approved scheduled runner.

Local examples use a caller-provided engine root:

```powershell
$env:UNREAL_ENGINE_ROOT = "<path-to-UE_5.7>"
& "$env:UNREAL_ENGINE_ROOT\Engine\Build\BatchFiles\Build.bat" AstroAdventureUEEditor Win64 Development "$PWD\AstroAdventureUE.uproject" -WaitMutex -NoHotReload
```

## M0 Parity Target

`M0_DeploymentProof` rebuilds the prior proof in Unreal:

- Explorer ship pawn.
- Mercury, Mars, and Europa destinations.
- Keyboard and Xbox-style controller movement.
- Focus cycle, scan action, discovery card, quiz, completion state.
- Local Unreal build and automation validation.

Binary assets are intentionally not committed yet. The first Unreal editor pass should create the map, input mapping context, UI, and data assets named in `Content/README.md`.

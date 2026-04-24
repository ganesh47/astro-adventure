# Unity Xbox Path

## Goal

Track what we learn about using Unity for a PC-first prototype and later Xbox Dev Mode or official Xbox release path.

## Current Direction

- Use Unity 6.3 LTS for new M0 setup unless the project later pins a different editor version in Unity project metadata.
- Install UWP Build Support through Unity Hub for the selected editor.
- Use Visual Studio 2022 and Windows SDK tooling for the first UWP deployment proof.
- Treat Xbox Dev Mode deployment as a local technical proof only. Official Xbox game publishing is outside M0 and must avoid restricted SDK/GDK or Partner Center details in public docs.

## Public Sources

- Unity: [Unity 6 release support](https://unity.com/releases/unity-6/support)
- Unity Manual: [Set up your environment for UWP](https://docs.unity3d.com/2022.3/Documentation/Manual/uwp-environment-setup.html)
- Unity Manual: [UWP requirements and compatibility](https://docs.unity3d.com/2022.3/Documentation/Manual/uwp-requirements-and-compatibility.html)
- Unity Manual: [Deploy a Windows or UWP app with the Windows Device Portal](https://docs.unity3d.com/2023.1/Documentation/Manual/windowsstore-deviceportal.html)
- Microsoft Learn: [Create your first UWP app in Visual Studio](https://learn.microsoft.com/en-us/visualstudio/get-started/csharp/tutorial-uwp)

## M0 Build Path

1. Build and test the minimal Unity scene on PC first.
2. Switch to UWP after UWP Build Support is installed.
3. Generate a Visual Studio project or use Unity Device Portal deployment, depending on which route succeeds first.
4. Deploy only a minimal scene and controller input proof to Xbox Dev Mode.
5. Promote the successful route into `docs/specs/m0-xbox-dev-mode-proof.md`.

## Open Decisions

- Exact Unity 6.3 LTS patch to pin once the first proof machine is configured.
- Whether the project should prefer Unity Device Portal deployment or Visual Studio deployment for repeatable M0 runs.
- Whether M0 should use the Unity Input System package before or after the first Xbox launch proof.

## Notes To Collect

- Recommended Unity editor version
- Required modules and Visual Studio workloads
- Controller input package decisions
- Build target options for local testing
- Known limitations between PC prototype, Dev Mode deployment, and official Xbox publishing

## Promotion Target

Accepted technical direction should be summarized in `docs/architecture.md` and `docs/decisions/`.

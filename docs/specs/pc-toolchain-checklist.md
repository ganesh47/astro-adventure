# PC Toolchain Checklist

## Purpose

This checklist prepares a Windows development PC for `M0: Xbox Dev Mode Proof`. It uses public tooling and public documentation only. Record exact installed versions during setup so another contributor can reproduce the machine state without relying on chat history.

## Chosen Baseline

- Unity editor: Unity 6.3 LTS through Unity Hub, because Unity documents Unity 6.3 LTS as the latest LTS release supported until December 2027.
- Unity modules: UWP Build Support.
- IDE: Visual Studio 2022.
- Windows SDK: Windows SDK `10.0.26100.0` or newer stable SDK available through the Visual Studio Installer. Microsoft currently documents newer Windows SDK releases, but Visual Studio UWP guidance names Windows 11 SDK `10.0.26100.0` as a UWP component option.
- Deployment route: Unity UWP build plus Visual Studio deployment, or Unity/Windows Device Portal deployment to the Xbox over the local network.

If a specific Unity 6.3 patch is selected in the project, record it here and in Unity project metadata. Until then, the setup target is "latest Unity 6.3 LTS patch available in Unity Hub on setup day."

## Public Sources

- Unity: [Unity 6 release support](https://unity.com/releases/unity-6/support)
- Unity: [Unity 6 download page](https://unity.com/releases/unity-6)
- Unity Manual: [Set up your environment for UWP](https://docs.unity3d.com/2022.3/Documentation/Manual/uwp-environment-setup.html)
- Unity Manual: [UWP requirements and compatibility](https://docs.unity3d.com/2022.3/Documentation/Manual/uwp-requirements-and-compatibility.html)
- Microsoft Learn: [Create your first UWP app in Visual Studio](https://learn.microsoft.com/en-us/visualstudio/get-started/csharp/tutorial-uwp)
- Microsoft Learn: [Windows SDK](https://learn.microsoft.com/en-us/windows/apps/windows-sdk/)
- Microsoft Learn: [Windows Device Portal overview](https://learn.microsoft.com/en-us/windows/uwp/debug-test-perf/device-portal)

## Checklist

| Area | Requirement | Validation |
| --- | --- | --- |
| Windows | Windows 10 or Windows 11 with current updates. | Run `winver` and record edition/version/build. |
| Windows Developer Mode | Developer Mode enabled on the PC for UWP development. | Settings > System > For developers shows Developer Mode enabled. |
| Unity Hub | Unity Hub installed. | Unity Hub opens and shows the chosen editor under Installs. |
| Unity Editor | Unity 6.3 LTS installed. | Unity Hub shows the exact `6000.x` patch; record it in the verification record. |
| Unity Module | UWP Build Support installed for the chosen editor. | Unity Hub > Installs > chosen editor > modules includes UWP Build Support. |
| Visual Studio | Visual Studio 2022 installed. | Visual Studio opens; Help > About shows exact version. |
| Visual Studio UWP Tooling | UWP workload/components installed. | Visual Studio Installer shows the UWP/WinUI app development components and UWP tools installed. |
| Windows SDK | Windows SDK `10.0.26100.0` or newer stable SDK installed. | Visual Studio Installer Individual components lists the SDK; `dir "C:\Program Files (x86)\Windows Kits\10\bin"` shows installed SDK folders. |
| Unity Project | Minimal proof project opens without package errors. | Unity Console is clear after opening the project. |
| Unity Build Target | UWP build target is available. | Unity build profiles/build settings list UWP after module installation. |
| Xbox Dev Mode | Xbox is activated for Developer Mode and currently in Dev Home. | Pressing Home returns Dev Home, not the retail Home experience. |
| Xbox User Session | A user is signed in on the Xbox. | Dev Home shows an active signed-in user before deployment. |
| Xbox Device Portal | Device Portal enabled in Dev Home. | Dev Home shows Device Portal address/settings; do not commit screenshots. |
| Local Network | PC and Xbox are on the same LAN. | PC can ping the console IP, or Device Portal is reachable by browser. |
| Firewall | Local firewall permits Visual Studio/Device Portal deployment traffic. | Browser reaches Device Portal; Visual Studio can see or connect to the remote device. |

## Setup Notes

- Unity says UWP support is added through the UWP Build Support module in Unity Hub.
- Unity's UWP requirements include Windows 10+ SDK and Visual Studio 2019 or later; this project standardizes on Visual Studio 2022.
- Microsoft documents Windows Device Portal as the management and app deployment surface for Windows device families. For Xbox, the Device Portal table lists HTTPS port `11443` and HTTP disabled.
- Microsoft Xbox UWP FAQ says a user must be signed in to deploy an app and recommends wired console networking for best deployment performance.

## Unknowns To Resolve During M0

- Exact Unity 6.3 LTS patch used by the proof machine.
- Whether direct Unity Device Portal build-and-run is sufficient for the Xbox target, or whether Visual Studio deployment is the reliable route for M0.
- Whether the minimal proof should use a D3D UWP project, executable-only iteration, or a Visual Studio package deployment for the first successful run.
- Any console-specific failures discovered during real deployment.

## Version Record Template

```text
PC:
Windows:
Unity Hub:
Unity editor:
Unity modules:
Visual Studio:
Installed Windows SDKs:
Xbox model/family:
Network type:
Deployment route:
```

## Issue Coverage

- Satisfies #5 by defining the PC toolchain, concrete baseline, network assumptions, and validation checks.
- Supports #2 and #6 by feeding the M0 proof and research pages with repeatable setup data.

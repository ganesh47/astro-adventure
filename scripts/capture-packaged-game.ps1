param(
    [string]$PackageRoot = "PackagedBuilds/Win64-Development",
    [string]$OutputRoot = "artifacts",
    [int]$InitialDelaySeconds = 4,
    [int]$StepDelayMilliseconds = 850,
    [string[]]$Keys = @("{ENTER}", "{ENTER}", "{ENTER}", "{ENTER}", "m", "{ENTER}", "{ENTER}"),
    [switch]$ResetSaveBeforeCapture
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$ResolvedPackageRoot = Resolve-Path -LiteralPath (Join-Path $RepoRoot $PackageRoot)
$Exe = Get-ChildItem -LiteralPath $ResolvedPackageRoot -Recurse -Filter "AstroAdventureUE.exe" | Select-Object -First 1
if (-not $Exe) {
    throw "Could not find AstroAdventureUE.exe under packaged build output. Run the local package script first."
}

if ($ResetSaveBeforeCapture) {
    $SaveRoots = @(
        (Join-Path $env:LOCALAPPDATA "AstroAdventureUE\Saved\SaveGames"),
        (Join-Path $Exe.DirectoryName "AstroAdventureUE\Saved\SaveGames")
    )
    foreach ($SaveRoot in $SaveRoots) {
        $SaveFile = Join-Path $SaveRoot "AstroAdventureM0Progress.sav"
        if (Test-Path -LiteralPath $SaveFile) {
            Remove-Item -LiteralPath $SaveFile -Force
        }
    }
}

$Stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$OutputDir = Join-Path (Join-Path $RepoRoot $OutputRoot) "packaged-review-$Stamp"
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class AstroWindowTools {
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
    [DllImport("user32.dll")]
    public static extern bool PrintWindow(IntPtr hWnd, IntPtr hdcBlt, uint nFlags);
    [DllImport("user32.dll")]
    public static extern void keybd_event(byte bVk, byte bScan, int dwFlags, int dwExtraInfo);
    [DllImport("user32.dll")]
    public static extern bool SetCursorPos(int X, int Y);
    [DllImport("user32.dll")]
    public static extern void mouse_event(int dwFlags, int dx, int dy, int dwData, int dwExtraInfo);
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }
}
"@

function Send-GameKey {
    param(
        [string]$Key
    )

    $Vk = switch ($Key.ToLowerInvariant()) {
        "{enter}" { 0x0D; break }
        "{esc}" { 0x1B; break }
        "{down}" { 0x28; break }
        "{up}" { 0x26; break }
        "{left}" { 0x25; break }
        "{right}" { 0x27; break }
        "m" { 0x4D; break }
        "p" { 0x50; break }
        default { throw "Unsupported capture key: $Key" }
    }

    [AstroWindowTools]::keybd_event([byte]$Vk, 0, 0, 0)
    Start-Sleep -Milliseconds 80
    [AstroWindowTools]::keybd_event([byte]$Vk, 0, 2, 0)
}

function Focus-GameWindow {
    param(
        [System.Diagnostics.Process]$GameProcess,
        [switch]$ClickIntoWindow
    )

    $GameProcess.Refresh()
    $Handle = $GameProcess.MainWindowHandle
    $WaitUntil = (Get-Date).AddSeconds(8)
    while ($Handle -eq [IntPtr]::Zero -and (Get-Date) -lt $WaitUntil) {
        Start-Sleep -Milliseconds 250
        $GameProcess.Refresh()
        $Handle = $GameProcess.MainWindowHandle
    }

    if ($Handle -eq [IntPtr]::Zero) {
        $VisibleGame = Get-Process AstroAdventureUE -ErrorAction SilentlyContinue |
            Where-Object { $_.MainWindowHandle -ne [IntPtr]::Zero } |
            Select-Object -First 1
        if ($VisibleGame) {
            $Handle = $VisibleGame.MainWindowHandle
        }
    }

    if ($Handle -eq [IntPtr]::Zero) {
        throw "Could not find the packaged game window."
    }

    [AstroWindowTools]::ShowWindow($Handle, 3) | Out-Null
    Start-Sleep -Milliseconds 250
    [AstroWindowTools]::SetForegroundWindow($Handle) | Out-Null
    Start-Sleep -Milliseconds 250

    if ($ClickIntoWindow) {
        $Rect = New-Object AstroWindowTools+RECT
        if ([AstroWindowTools]::GetWindowRect($Handle, [ref]$Rect)) {
            $ClickX = [int](($Rect.Left + $Rect.Right) / 2)
            $ClickY = [int](($Rect.Top + $Rect.Bottom) / 2)
            [AstroWindowTools]::SetCursorPos($ClickX, $ClickY) | Out-Null
            Start-Sleep -Milliseconds 80
            [AstroWindowTools]::mouse_event(2, 0, 0, 0, 0)
            Start-Sleep -Milliseconds 40
            [AstroWindowTools]::mouse_event(4, 0, 0, 0, 0)
            Start-Sleep -Milliseconds 160
        }
    }

    return $Handle
}

function Save-ScreenCapture {
    param(
        [string]$Path,
        [IntPtr]$WindowHandle
    )

    $Rect = New-Object AstroWindowTools+RECT
    if (-not [AstroWindowTools]::GetWindowRect($WindowHandle, [ref]$Rect)) {
        throw "Could not read packaged game window bounds."
    }

    $Width = [Math]::Max(1, $Rect.Right - $Rect.Left)
    $Height = [Math]::Max(1, $Rect.Bottom - $Rect.Top)
    $Bitmap = New-Object System.Drawing.Bitmap $Width, $Height
    $Graphics = [System.Drawing.Graphics]::FromImage($Bitmap)
    try {
        $Hdc = $Graphics.GetHdc()
        try {
            $Printed = [AstroWindowTools]::PrintWindow($WindowHandle, $Hdc, 2)
        }
        finally {
            $Graphics.ReleaseHdc($Hdc)
        }
        if (-not $Printed) {
            $Graphics.CopyFromScreen($Rect.Left, $Rect.Top, 0, 0, (New-Object System.Drawing.Size $Width, $Height))
        }
        $Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        $Graphics.Dispose()
        $Bitmap.Dispose()
    }
}

$Process = Start-Process -FilePath $Exe.FullName -WorkingDirectory $Exe.DirectoryName -PassThru
try {
    Start-Sleep -Seconds $InitialDelaySeconds
    $GameWindow = Focus-GameWindow -GameProcess $Process

    Save-ScreenCapture -Path (Join-Path $OutputDir "00-home.png") -WindowHandle $GameWindow

    $Index = 1
    foreach ($Key in $Keys) {
        $GameWindow = Focus-GameWindow -GameProcess $Process -ClickIntoWindow
        Send-GameKey -Key $Key
        Start-Sleep -Milliseconds $StepDelayMilliseconds
        Save-ScreenCapture -Path (Join-Path $OutputDir ("{0:D2}-after-key.png" -f $Index)) -WindowHandle $GameWindow
        $Index += 1
    }

    Focus-GameWindow -GameProcess $Process -ClickIntoWindow | Out-Null
    Send-GameKey -Key "{ESC}"
    Start-Sleep -Milliseconds 400
    Send-GameKey -Key "{DOWN}"
    Start-Sleep -Milliseconds 200
    Send-GameKey -Key "{DOWN}"
    Start-Sleep -Milliseconds 200
    Send-GameKey -Key "{DOWN}"
    Start-Sleep -Milliseconds 200
    Send-GameKey -Key "{ENTER}"
    Start-Sleep -Milliseconds 700
}
finally {
    if (-not $Process.HasExited) {
        $Process.CloseMainWindow() | Out-Null
        Start-Sleep -Seconds 2
    }
    if (-not $Process.HasExited) {
        $Process.Kill()
    }
    Get-Process AstroAdventureUE -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}

Write-Host "Local packaged capture complete: $OutputDir"

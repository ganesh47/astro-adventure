[CmdletBinding()]
param(
    [string] $UnrealEngineRoot = $env:UNREAL_ENGINE_ROOT,
    [string] $Configuration = "Development"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Fail($message) {
    throw "[win64-package] $message"
}

if ([string]::IsNullOrWhiteSpace($UnrealEngineRoot)) {
    Fail "Set UNREAL_ENGINE_ROOT to the local Unreal Engine root, or pass -UnrealEngineRoot."
}

$allowedConfigurations = @("DebugGame", "Development", "Shipping")
if ($allowedConfigurations -notcontains $Configuration) {
    Fail "Unsupported configuration '$Configuration'. Use one of: $($allowedConfigurations -join ', ')."
}

$engineRoot = (Resolve-Path -LiteralPath $UnrealEngineRoot -ErrorAction Stop).Path
$runUat = Join-Path $engineRoot "Engine\Build\BatchFiles\RunUAT.bat"
if (-not (Test-Path -LiteralPath $runUat)) {
    Fail "RunUAT.bat was not found under '$engineRoot'. Check UNREAL_ENGINE_ROOT."
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$projectPath = Join-Path $repoRoot "AstroAdventureUE\AstroAdventureUE.uproject"
if (-not (Test-Path -LiteralPath $projectPath)) {
    Fail "Project file not found: $projectPath"
}

$packageRoot = Join-Path $repoRoot "PackagedBuilds\Win64-Development"
New-Item -ItemType Directory -Force -Path $packageRoot | Out-Null

$ignoredCheck = git -C $repoRoot check-ignore "PackagedBuilds/Win64-Development" 2>$null
if (-not $ignoredCheck) {
    Fail "PackagedBuilds/Win64-Development is not ignored by git. Refusing to write package output."
}

Write-Host "[win64-package] Unreal Engine root: $engineRoot"
Write-Host "[win64-package] Project: $projectPath"
Write-Host "[win64-package] Output: $packageRoot"

& $runUat BuildCookRun `
    "-project=$projectPath" `
    -noP4 `
    -platform=Win64 `
    "-clientconfig=$Configuration" `
    "-serverconfig=$Configuration" `
    -build `
    -cook `
    -stage `
    -pak `
    -archive `
    "-archivedirectory=$packageRoot" `
    -utf8output

if ($LASTEXITCODE -ne 0) {
    Fail "RunUAT BuildCookRun failed with exit code $LASTEXITCODE."
}

Write-Host "[win64-package] Package complete: $packageRoot"

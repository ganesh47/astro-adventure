param(
    [string]$PackageRoot = "PackagedBuilds/Win64-Development"
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$resolvedPackageRoot = Join-Path $repoRoot $PackageRoot

if (-not (Test-Path $resolvedPackageRoot)) {
    throw "Package root not found: $PackageRoot"
}

$log = Get-ChildItem -Path $resolvedPackageRoot -Recurse -Filter "*.log" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if (-not $log) {
    throw "No packaged runtime log found under $PackageRoot"
}

$content = Get-Content -LiteralPath $log.FullName -Raw

$requiredAssets = @(
    "/Game/Art/AstroAdventureOwned/MaterialInstances/MI_Sun_Surface",
    "/Game/Art/AstroAdventureOwned/MaterialInstances/MI_Sun_Corona",
    "/Game/Art/AstroAdventureOwned/MaterialInstances/MI_Focus_Ring",
    "/Game/Art/AstroAdventureOwned/MaterialInstances/MI_Scanner_Beam",
    "/Game/Art/AstroAdventureOwned/MaterialInstances/MI_Sky_Backdrop",
    "/Game/Art/AstroAdventureOwned/MaterialInstances/MI_Mercury_Surface",
    "/Game/Art/AstroAdventureOwned/MaterialInstances/MI_Venus_Surface",
    "/Game/Art/AstroAdventureOwned/MaterialInstances/MI_Europa_Surface",
    "/Game/Art/AstroAdventureOwned/MaterialInstances/MI_Saturn_Surface",
    "/Game/Art/AstroAdventureOwned/MaterialInstances/MI_Uranus_Surface",
    "/Game/Art/AstroAdventureOwned/MaterialInstances/MI_Neptune_Surface",
    "/Game/Art/AstroAdventureOwned/Textures/Planets/T_Sun_Surface_Stylized",
    "/Game/Art/AstroAdventureOwned/Textures/Planets/T_Mercury_Craters_Stylized"
)

$failures = New-Object System.Collections.Generic.List[string]

foreach ($asset in $requiredAssets) {
    $escaped = [regex]::Escape($asset)
    if ($content -match "SkipPackage:\s+$escaped" -or
        $content -match "Failed to find object '[^']*\s+$escaped" -or
        $content -match "Can't find file.*$escaped") {
        $failures.Add($asset)
    }
}

if ($content -match "SkipPackage:\s+/Game/Art/AstroAdventureOwned" -or
    $content -match "Failed to find object '[^']*\s+/Game/Art/AstroAdventureOwned") {
    $failures.Add("One or more /Game/Art/AstroAdventureOwned assets failed to load.")
}

if ($failures.Count -gt 0) {
    $uniqueFailures = $failures | Select-Object -Unique
    throw "Packaged art asset validation failed in $($log.FullName):`n$($uniqueFailures -join "`n")"
}

Write-Host "Packaged art asset validation passed: $($log.FullName)"

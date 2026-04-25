Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $repoRoot

function Fail($message) {
    throw "[public-repo-validation] $message"
}

$tracked = git ls-files --cached --others --exclude-standard

$blockedPathPattern = '(^|/)(Binaries|Build|DerivedDataCache|Intermediate|Saved|PackagedBuilds|StagedBuilds|Releases|artifacts|private-packages|certificates)/'
$blockedExtensionPattern = '\.(pfx|p12|cer|cert|key|pem|publishsettings|appx|appxbundle|msix|msixbundle|pak|utoc|ucas)$'

$blockedPaths = $tracked | Where-Object { $_ -match $blockedPathPattern -or $_ -match $blockedExtensionPattern }
if ($blockedPaths) {
    Fail "Generated, package, or private artifact paths are tracked: $($blockedPaths -join ', ')"
}

$ignoredTracked = git ls-files -ci --exclude-standard
if ($ignoredTracked) {
    Fail "Ignored files are tracked: $($ignoredTracked -join ', ')"
}

$privatePatterns = @(
    'SecurityToken\s*=',
    'client_secret',
    'password\s*=',
    'BEGIN (RSA |DSA |EC |OPENSSH |)PRIVATE KEY',
    'PRIVATE KEY-----',
    'ConsoleSerial\s*=',
    'CertificateThumbprint\s*='
)

$textExtensions = @('.cs', '.cpp', '.csv', '.h', '.ini', '.json', '.md', '.ps1', '.sh', '.txt', '.uproject', '.uplugin', '.yml', '.yaml')
foreach ($path in $tracked) {
    if ($path -eq "scripts/validate-public-repo.ps1") {
        continue
    }

    $extension = [System.IO.Path]::GetExtension($path)
    if ($textExtensions -notcontains $extension -and [System.IO.Path]::GetFileName($path) -notin @('README', 'LICENSE', 'VERSION')) {
        continue
    }

    $content = Get-Content -LiteralPath $path -Raw -ErrorAction SilentlyContinue
    foreach ($pattern in $privatePatterns) {
        if ($content -match $pattern) {
            Fail "Credential-like or private-boundary pattern '$pattern' found in $path"
        }
    }
}

$project = Get-Content AstroAdventureUE/AstroAdventureUE.uproject -Raw | ConvertFrom-Json
if ($project.EngineAssociation -ne "5.7") {
    Fail "AstroAdventureUE must target Unreal Engine 5.7.x."
}
if (-not ($project.Modules | Where-Object { $_.Name -eq "AstroAdventureUE" -and $_.Type -eq "Runtime" })) {
    Fail "AstroAdventureUE runtime module is missing."
}
$plugins = @($project.Plugins | ForEach-Object { $_.Name })
foreach ($required in @("EnhancedInput", "CommonUI")) {
    if ($plugins -notcontains $required) {
        Fail "Required Unreal plugin missing: $required"
    }
}

foreach ($requiredPath in @(
    "AstroAdventureUE/Source/AstroAdventureUE.Target.cs",
    "AstroAdventureUE/Source/AstroAdventureUEEditor.Target.cs",
    "AstroAdventureUE/Source/AstroAdventureUE/AstroAdventureUE.Build.cs",
    "AstroAdventureUE/Source/AstroAdventureUE/Private/AstroAdventureUE.cpp",
    "AstroAdventureUE/Config/DefaultEngine.ini",
    "AstroAdventureUE/Config/DefaultGame.ini",
    "AstroAdventureUE/Config/DefaultInput.ini"
)) {
    if (-not (Test-Path $requiredPath)) {
        Fail "Required Unreal project file missing: $requiredPath"
    }
}

$allowedTypes = @("image", "audio", "model", "material", "font", "video", "text", "package", "other")
$allowedLicenses = @("public-domain", "cc0", "cc-by-4.0", "mit", "apache-2.0", "bsd-3-clause", "original-project-owned", "ai-generated-project-owned", "proprietary-private-only", "unknown")
$allowedTriState = @("yes", "no", "needs-review")
$allowedXboxState = @("yes", "no", "not-reviewed")
$allowedReview = @("accepted", "needs-review", "rejected")

$rows = Import-Csv assets/manifest/assets.csv
foreach ($row in $rows) {
    foreach ($field in @("id", "title", "type", "source_url", "license", "author", "ai_generated", "tool", "notes", "approved_for_public_repo", "approved_for_xbox_build", "review_status")) {
        if ([string]::IsNullOrWhiteSpace($row.$field)) {
            Fail "Asset manifest row '$($row.id)' is missing '$field'."
        }
    }
    if ($row.id -notmatch '^[a-z0-9_]+$') { Fail "Asset id '$($row.id)' must be lowercase snake_case." }
    if ($allowedTypes -notcontains $row.type) { Fail "Asset '$($row.id)' has unsupported type '$($row.type)'." }
    if ($allowedLicenses -notcontains $row.license) { Fail "Asset '$($row.id)' has unsupported license '$($row.license)'." }
    if ($row.ai_generated -notin @("yes", "no")) { Fail "Asset '$($row.id)' has invalid ai_generated value." }
    if ($row.ai_generated -eq "no" -and $row.tool -ne "none") { Fail "Asset '$($row.id)' is non-AI and must use tool=none." }
    if ($allowedTriState -notcontains $row.approved_for_public_repo) { Fail "Asset '$($row.id)' has invalid public approval value." }
    if ($allowedXboxState -notcontains $row.approved_for_xbox_build) { Fail "Asset '$($row.id)' has invalid Xbox approval value." }
    if ($allowedReview -notcontains $row.review_status) { Fail "Asset '$($row.id)' has invalid review status." }
    if ($row.review_status -eq "rejected" -and [string]::IsNullOrWhiteSpace($row.rejection_reason)) { Fail "Rejected asset '$($row.id)' needs a public-safe rejection reason." }
    if ($row.review_status -ne "rejected" -and -not [string]::IsNullOrWhiteSpace($row.rejection_reason)) { Fail "Non-rejected asset '$($row.id)' should not have a rejection reason." }
    if ($row.source_url -eq "private-only" -and $row.approved_for_public_repo -ne "no") { Fail "Private-only asset '$($row.id)' cannot be public-approved." }
}

$binaryAssetPattern = '\.(uasset|umap|fbx|blend|png|jpg|jpeg|wav|mp3|mp4|ttf|otf)$'
$binaryAssets = $tracked | Where-Object { $_ -match $binaryAssetPattern }
foreach ($assetPath in $binaryAssets) {
    $attr = git check-attr filter -- $assetPath
    if ($attr -notmatch 'filter: lfs') {
        Fail "Binary/media asset '$assetPath' must use Git LFS."
    }
}

$unityActivePaths = $tracked | Where-Object { $_ -match '(^|/)AstroAdventureM0/|unity-binary-asset-hygiene|minimal-unity-scene-plan|validate-m0-scene' }
if ($unityActivePaths) {
    Fail "Unity active project files or Unity-specific active specs are still tracked: $($unityActivePaths -join ', ')"
}

Write-Host "Public repo validation passed."

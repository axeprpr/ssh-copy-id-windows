param(
  [Parameter(Mandatory=$true)][string]$Version,
  [string]$GitHubRepo = "axeprpr/ssh-copy-id-windows",
  [switch]$SkipBuild,
  [switch]$DryRun,
  [string]$OutputRoot = "out",
  [string]$ReleaseDate = (Get-Date).ToString('yyyy-MM-dd')
)

$ErrorActionPreference = 'Stop'

function Write-Step($t){ Write-Host "[STEP] $t" -ForegroundColor Cyan }
function Write-Info($t){ Write-Host "[INFO] $t" -ForegroundColor Gray }
function Write-Warn($t){ Write-Host "[WARN] $t" -ForegroundColor Yellow }
function Write-Ok($t){ Write-Host "[OK] $t" -ForegroundColor Green }

# 1. Ensure source version is aligned
Write-Step "Version alignment"
$mainGo = "main.go"
$mainGoContent = Get-Content $mainGo -Raw
$updatedMainGoContent = [regex]::Replace($mainGoContent, 'const version = ".*"', "const version = `"$Version`"")
if($updatedMainGoContent -ne $mainGoContent){
  Set-Content -Path $mainGo -Value $updatedMainGoContent -NoNewline
  Write-Ok "Updated main.go version to $Version"
} else {
  Write-Info "main.go already uses version $Version"
}

# 2. Build
if(-not $SkipBuild){
  Write-Step "Windows resource"
  .\scripts\generate-windows-resource.ps1 -Version $Version
  if(-not (Test-Path rsrc_windows_amd64.syso)){ throw 'Windows resource generation failed' }
  Write-Ok "Windows resource generated"

  Write-Step "Build"
  go build -trimpath -ldflags "-s -w" -o ssh-copy-id.exe .
  if(-not (Test-Path ssh-copy-id.exe)){ throw 'Build failed' }
  Write-Ok "Binary built"
}else{ Write-Warn "Skip build" }

# 3. Hash
Write-Step "Hash"
$hash = (Get-FileHash -Path ssh-copy-id.exe -Algorithm SHA256).Hash
Write-Info "SHA256=$hash"

# 4. Update manifests
Write-Step "Update winget manifests"
$installer = Join-Path winget-manifests 'axeprpr.SSHCopyID.installer.yaml'
$installerContent = @"
# Created with komac v2.14.0
# yaml-language-server: `$schema=https://aka.ms/winget-manifest.installer.1.10.0.schema.json

PackageIdentifier: axeprpr.SSHCopyID
PackageVersion: $Version
InstallerType: portable
Scope: user
InstallModes:
- interactive
- silent
- silentWithProgress
UpgradeBehavior: install
Commands:
- ssh-copy-id
Protocols:
- ssh
FileExtensions:
- pub
ReleaseDate: $ReleaseDate
Installers:
- Architecture: x64
  InstallerUrl: https://github.com/$GitHubRepo/releases/download/v$Version/ssh-copy-id.exe
  InstallerSha256: $hash
ManifestType: installer
ManifestVersion: 1.10.0
"@
$installerContent | Set-Content $installer

$versionFile = Join-Path winget-manifests 'axeprpr.SSHCopyID.yaml'
$versionContent = @"
# Created with komac v2.14.0
# yaml-language-server: `$schema=https://aka.ms/winget-manifest.version.1.10.0.schema.json

PackageIdentifier: axeprpr.SSHCopyID
PackageVersion: $Version
DefaultLocale: en-US
ManifestType: version
ManifestVersion: 1.10.0
"@
$versionContent | Set-Content $versionFile

$localeFile = Join-Path winget-manifests 'axeprpr.SSHCopyID.locale.en-US.yaml'
$localeContent = @"
# Created with komac v2.14.0
# yaml-language-server: `$schema=https://aka.ms/winget-manifest.defaultLocale.1.10.0.schema.json

PackageIdentifier: axeprpr.SSHCopyID
PackageVersion: $Version
PackageLocale: en-US
Publisher: axeprpr
PublisherUrl: https://github.com/axeprpr
PublisherSupportUrl: https://github.com/$GitHubRepo/issues
Author: axeprpr
PackageName: SSH Copy ID
PackageUrl: https://github.com/$GitHubRepo
License: MIT
LicenseUrl: https://github.com/$GitHubRepo/blob/HEAD/LICENSE
Copyright: Copyright (c) axeprpr
ShortDescription: SSH-Copy-ID for Windows - Copy SSH public keys to remote servers
Description: |-
  SSH-Copy-ID for Windows is a command-line tool that copies SSH public keys to remote servers' authorized_keys files.
  It provides the same functionality as the Linux ssh-copy-id command but is specifically designed for Windows systems.

  Features:
  - Copy SSH public keys to remote servers
  - Support for custom SSH key files and ports
  - Automatic creation of remote .ssh directory and authorized_keys file
  - Duplicate key detection and prevention
  - Cross-platform compatibility
ReleaseNotes: |-
  - Hardened the key copy flow by streaming the public key over stdin
  - Added public key validation before connecting
  - Added tests for argument parsing and command generation
ReleaseNotesUrl: https://github.com/$GitHubRepo/releases/tag/v$Version
Moniker: ssh-copy-id
Tags:
- authentication
- command-line
- remote
- ssh
- ssh-keys
- terminal
- windows
ManifestType: defaultLocale
ManifestVersion: 1.10.0
"@
$localeContent | Set-Content $localeFile

Write-Ok "Manifests updated"

# 5. Stage winget-pkgs submission files
Write-Step "Stage winget-pkgs submission"
$publisher = $GitHubRepo.Split('/')[0]
$packageName = 'SSHCopyID'
$first = $publisher.Substring(0,1).ToLowerInvariant()
$submissionDir = Join-Path $OutputRoot "winget-pkgs/manifests/$first/$publisher/$packageName/$Version"
New-Item -ItemType Directory -Path $submissionDir -Force | Out-Null
Copy-Item winget-manifests\*.yaml -Destination $submissionDir -Force
Write-Ok "Staged manifests at $submissionDir"

# 6. Git commit/tag/push
Write-Step "Git operations"
if($DryRun){ Write-Warn "DryRun: skip git" } else {
  git add ssh-copy-id.exe winget-manifests/*.yaml main.go .gitignore README.md WINGET_PUBLISH.md scripts\release-and-winget.ps1 scripts\generate-windows-resource.ps1 assets\icon.ico 2>$null
  git commit -m "release: $Version" | Out-Null
  git tag "v$Version"
  git push origin main
  git push origin "v$Version"
  Write-Ok "Git pushed with tag v$Version"
}

# 7. GitHub Release (requires gh cli)
Write-Step "GitHub Release"
if($DryRun){ Write-Warn "DryRun: skip release" }
else {
  if(-not (Get-Command gh -ErrorAction SilentlyContinue)){ Write-Warn 'gh CLI not found, skip release'; }
  else {
    $exists = gh release view "v$Version" 2>$null
    if($LASTEXITCODE -eq 0){ Write-Warn "Release v$Version already exists" }
    else {
      gh release create "v$Version" ssh-copy-id.exe -t "v$Version" -n "Release $Version" | Out-Null
      Write-Ok "Release created"
    }
  }
}

# 8. Prepare winget-pkgs next steps
Write-Step "Next manual step"
Write-Host "Open microsoft/winget-pkgs and submit the files from: $submissionDir" -ForegroundColor Yellow
Write-Host "Target path in winget-pkgs: manifests/$first/$publisher/$packageName/$Version/" -ForegroundColor Yellow
Write-Ok "Done"

param(
  [Parameter(Mandatory=$true)][string]$Version,
  [string]$GitHubRepo = "axeprpr/ssh-copy-id-windows",
  [switch]$SkipBuild,
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

function Write-Step($t){ Write-Host "[STEP] $t" -ForegroundColor Cyan }
function Write-Info($t){ Write-Host "[INFO] $t" -ForegroundColor Gray }
function Write-Warn($t){ Write-Host "[WARN] $t" -ForegroundColor Yellow }
function Write-Ok($t){ Write-Host "[OK] $t" -ForegroundColor Green }

# 1. Build
if(-not $SkipBuild){
  Write-Step "Build"
  go build -trimpath -ldflags "-s -w" -o ssh-copy-id.exe main.go
  if(-not (Test-Path ssh-copy-id.exe)){ throw 'Build failed' }
  Write-Ok "Binary built"
}else{ Write-Warn "Skip build" }

# 2. Hash
Write-Step "Hash"
$hash = (Get-FileHash -Path ssh-copy-id.exe -Algorithm SHA256).Hash
Write-Info "SHA256=$hash"

# 3. Update manifests
Write-Step "Update winget manifests"
$installer = Join-Path winget-manifests 'axeprpr.SSHCopyID.installer.yaml'
(Get-Content $installer) -replace 'PackageVersion: .*', "PackageVersion: $Version" `
  -replace 'InstallerUrl: https://github.com/.*/download/v.*?/ssh-copy-id.exe', "InstallerUrl: https://github.com/$GitHubRepo/releases/download/v$Version/ssh-copy-id.exe" `
  -replace 'InstallerSha256: .*', "InstallerSha256: $hash" | Set-Content $installer

$versionFile = Join-Path winget-manifests 'axeprpr.SSHCopyID.yaml'
(Get-Content $versionFile) -replace 'PackageVersion: .*', "PackageVersion: $Version" | Set-Content $versionFile

$localeFile = Join-Path winget-manifests 'axeprpr.SSHCopyID.locale.en-US.yaml'
(Get-Content $localeFile) -replace 'PackageVersion: .*', "PackageVersion: $Version" `
  -replace 'Version bump to .*', "Version bump to $Version" | Set-Content $localeFile

Write-Ok "Manifests updated"

# 4. Git commit/tag/push
Write-Step "Git operations"
if($DryRun){ Write-Warn "DryRun: skip git" } else {
  git add ssh-copy-id.exe winget-manifests/*.yaml main.go 2>$null
  git commit -m "release: $Version" | Out-Null
  git tag "v$Version"
  git push origin main
  git push origin "v$Version"
  Write-Ok "Git pushed with tag v$Version"
}

# 5. GitHub Release (requires gh cli)
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

# 6. Prepare winget-pkgs submission folder snippet hint
Write-Step "Next manual step"
$first = $GitHubRepo.Split('/')[0][0]
Write-Host "Copy manifests to: manifests/$first/$(($GitHubRepo.Split('/')[0]))/SSHCopyID/$Version/ in winget-pkgs fork" -ForegroundColor Yellow
Write-Ok "Done"

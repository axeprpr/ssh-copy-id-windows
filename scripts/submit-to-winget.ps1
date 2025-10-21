param(
  [Parameter(Mandatory=$true)][string]$Version,
  [Parameter(Mandatory=$true)][string]$WingetPkgsPath,
  [string]$Publisher = "axeprpr",
  [string]$PackageName = "SSHCopyID"
)

$ErrorActionPreference = 'Stop'

function Write-Step($t){ Write-Host "[STEP] $t" -ForegroundColor Cyan }
function Write-Info($t){ Write-Host "[INFO] $t" -ForegroundColor Gray }
function Write-Warn($t){ Write-Host "[WARN] $t" -ForegroundColor Yellow }
function Write-Ok($t){ Write-Host "[OK] $t" -ForegroundColor Green }
function Write-Err($t){ Write-Host "[ERROR] $t" -ForegroundColor Red }

# Validate winget-pkgs path
if (-not (Test-Path $WingetPkgsPath)) {
  Write-Err "WinGet-pkgs path not found: $WingetPkgsPath"
  Write-Info "Please clone your fork first: git clone https://github.com/$Publisher/winget-pkgs.git"
  exit 1
}

# Validate manifest files exist
$sourceDir = Join-Path $PSScriptRoot ".." "1.1.0"
if (-not (Test-Path $sourceDir)) {
  Write-Err "Source manifest directory not found: $sourceDir"
  exit 1
}

# Calculate correct path in winget-pkgs
$firstLetter = $Publisher[0].ToString().ToLower()
$targetDir = Join-Path $WingetPkgsPath "manifests" $firstLetter $Publisher $PackageName $Version

Write-Step "Preparing WinGet submission"
Write-Info "Source: $sourceDir"
Write-Info "Target: $targetDir"
Write-Info "Package: $Publisher.$PackageName"
Write-Info "Version: $Version"

# Create target directory
Write-Step "Creating target directory"
if (Test-Path $targetDir) {
  Write-Warn "Target directory already exists, removing..."
  Remove-Item -Path $targetDir -Recurse -Force
}
New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
Write-Ok "Directory created"

# Copy manifest files
Write-Step "Copying manifest files"
$files = @(
  "$Publisher.$PackageName.yaml",
  "$Publisher.$PackageName.installer.yaml",
  "$Publisher.$PackageName.locale.en-US.yaml"
)

foreach ($file in $files) {
  $sourcePath = Join-Path $sourceDir $file
  $targetPath = Join-Path $targetDir $file
  
  if (-not (Test-Path $sourcePath)) {
    Write-Err "Source file not found: $sourcePath"
    exit 1
  }
  
  Copy-Item -Path $sourcePath -Destination $targetPath -Force
  Write-Info "Copied: $file"
}
Write-Ok "All manifest files copied"

# Validate manifests (if winget is available)
Write-Step "Validating manifests"
if (Get-Command winget -ErrorAction SilentlyContinue) {
  try {
    $validation = winget validate --manifest $targetDir 2>&1
    if ($LASTEXITCODE -eq 0) {
      Write-Ok "Validation passed"
    } else {
      Write-Err "Validation failed:"
      Write-Host $validation -ForegroundColor Red
      exit 1
    }
  } catch {
    Write-Warn "Validation check failed: $_"
  }
} else {
  Write-Warn "WinGet CLI not found, skipping validation"
}

# Git operations in winget-pkgs repo
Write-Step "Git operations"
Push-Location $WingetPkgsPath
try {
  # Ensure we're on master and up to date
  Write-Info "Updating master branch..."
  git checkout master 2>&1 | Out-Null
  git pull upstream master 2>&1 | Out-Null
  
  # Create new branch
  $branchName = "$Publisher.$PackageName.version.$Version"
  Write-Info "Creating branch: $branchName"
  git checkout -b $branchName 2>&1 | Out-Null
  
  # Add and commit
  Write-Info "Adding manifest files..."
  git add "manifests/$firstLetter/$Publisher/$PackageName/$Version/*"
  
  $commitMsg = "New version: $Publisher.$PackageName version $Version"
  Write-Info "Committing: $commitMsg"
  git commit -m $commitMsg 2>&1 | Out-Null
  
  Write-Ok "Git operations completed"
  Write-Host ""
  Write-Host "=====================================" -ForegroundColor Magenta
  Write-Host "Next steps:" -ForegroundColor Yellow
  Write-Host "1. Push the branch:" -ForegroundColor White
  Write-Host "   git push origin $branchName" -ForegroundColor Cyan
  Write-Host ""
  Write-Host "2. Go to GitHub and create a Pull Request:" -ForegroundColor White
  Write-Host "   https://github.com/microsoft/winget-pkgs/compare" -ForegroundColor Cyan
  Write-Host ""
  Write-Host "3. Set base repository to: microsoft/winget-pkgs (master)" -ForegroundColor White
  Write-Host "   Set compare to: $Publisher/winget-pkgs ($branchName)" -ForegroundColor White
  Write-Host "=====================================" -ForegroundColor Magenta
  
} catch {
  Write-Err "Git operation failed: $_"
  exit 1
} finally {
  Pop-Location
}

Write-Ok "Done! Ready to push and create PR."


param(
  [string]$Version = "1.1.1",
  [string]$OutputPrefix = "rsrc"
)

$ErrorActionPreference = "Stop"

function Write-Step($t){ Write-Host "[STEP] $t" -ForegroundColor Cyan }
function Write-Ok($t){ Write-Host "[OK] $t" -ForegroundColor Green }

Write-Step "Generate Windows resource"
$goWinRes = Join-Path $env:USERPROFILE "go\bin\go-winres.exe"
if(-not (Test-Path $goWinRes)){
  throw "go-winres.exe not found at $goWinRes"
}

& $goWinRes simply `
  --arch amd64 `
  --out $OutputPrefix `
  --icon assets/icon.ico `
  --product-version $Version `
  --file-version $Version `
  --file-description "Copy SSH public keys to remote servers on Windows" `
  --product-name "SSH Copy ID" `
  --copyright "Copyright (c) axeprpr" `
  --original-filename "ssh-copy-id.exe"

Write-Ok "Generated ${OutputPrefix}_windows_amd64.syso"

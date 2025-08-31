#!/usr/bin/env pwsh
# 发布到winget的自动化脚本

param(
    [Parameter(Mandatory=$true)]
    [string]$Version,
    
    [Parameter(Mandatory=$true)]
    [string]$GitHubUsername,
    
    [Parameter(Mandatory=$false)]
    [string]$RepoName = "ssh-copy-id-windows"
)

Write-Host "开始发布流程..." -ForegroundColor Green

# 1. 构建应用程序
Write-Host "1. 构建应用程序..." -ForegroundColor Yellow
go build -ldflags "-s -w" -o ssh-copy-id.exe main.go

if (-not (Test-Path "ssh-copy-id.exe")) {
    Write-Error "构建失败！"
    exit 1
}

# 2. 计算SHA256
Write-Host "2. 计算SHA256哈希..." -ForegroundColor Yellow
$hash = Get-FileHash -Path "ssh-copy-id.exe" -Algorithm SHA256
$sha256 = $hash.Hash
Write-Host "SHA256: $sha256" -ForegroundColor Cyan

# 3. 创建Git标签
Write-Host "3. 创建Git标签..." -ForegroundColor Yellow
git tag "v$Version"
git push origin "v$Version"

# 4. 准备winget清单文件
Write-Host "4. 更新winget清单文件..." -ForegroundColor Yellow

# 创建目录
if (-not (Test-Path "winget-manifests")) {
    New-Item -ItemType Directory -Path "winget-manifests" | Out-Null
}

$packageId = "$GitHubUsername.SSHCopyID"
$downloadUrl = "https://github.com/$GitHubUsername/$RepoName/releases/download/v$Version/ssh-copy-id.exe"

# 创建version文件
$versionContent = @"
# Created using wingetcreate 1.0.0.0
# yaml-language-server: `$schema=https://aka.ms/winget-manifest.version.1.2.0.schema.json

PackageIdentifier: $packageId
PackageVersion: $Version
DefaultLocale: en-US
ManifestType: version
ManifestVersion: 1.2.0
"@

$versionContent | Out-File -FilePath "winget-manifests\$packageId.yaml" -Encoding UTF8

# 创建installer文件
$installerContent = @"
# Created using wingetcreate 1.0.0.0
# yaml-language-server: `$schema=https://aka.ms/winget-manifest.installer.1.2.0.schema.json

PackageIdentifier: $packageId
PackageVersion: $Version
MinimumOSVersion: 10.0.0.0
Scope: user
InstallModes:
- interactive
- silent
- silentWithProgress
UpgradeBehavior: install
Protocols:
- ssh
FileExtensions:
- pub
Installers:
- Architecture: x64
  InstallerType: portable
  InstallerUrl: $downloadUrl
  InstallerSha256: $sha256
  Commands:
  - ssh-copy-id
ManifestType: installer
ManifestVersion: 1.2.0
"@

$installerContent | Out-File -FilePath "winget-manifests\$packageId.installer.yaml" -Encoding UTF8

# 创建locale文件
$localeContent = @"
# Created using wingetcreate 1.0.0.0
# yaml-language-server: `$schema=https://aka.ms/winget-manifest.defaultLocale.1.2.0.schema.json

PackageIdentifier: $packageId
PackageVersion: $Version
PackageLocale: en-US
Publisher: $GitHubUsername
PublisherUrl: https://github.com/$GitHubUsername
PublisherSupportUrl: https://github.com/$GitHubUsername/$RepoName/issues
Author: $GitHubUsername
PackageName: SSH Copy ID
PackageUrl: https://github.com/$GitHubUsername/$RepoName
License: MIT
LicenseUrl: https://github.com/$GitHubUsername/$RepoName/blob/main/LICENSE
Copyright: Copyright (c) $GitHubUsername
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
Moniker: ssh-copy-id
Tags:
- ssh
- ssh-keys
- remote
- authentication
- windows
- command-line
- terminal
ManifestType: defaultLocale
ManifestVersion: 1.2.0
"@

$localeContent | Out-File -FilePath "winget-manifests\$packageId.locale.en-US.yaml" -Encoding UTF8

Write-Host "5. 发布信息:" -ForegroundColor Green
Write-Host "   版本: v$Version" -ForegroundColor White
Write-Host "   下载URL: $downloadUrl" -ForegroundColor White
Write-Host "   SHA256: $sha256" -ForegroundColor White
Write-Host "   包标识符: $packageId" -ForegroundColor White

Write-Host ""
Write-Host "接下来的步骤:" -ForegroundColor Yellow
Write-Host "1. 在GitHub上创建Release并上传ssh-copy-id.exe" -ForegroundColor White
Write-Host "2. Fork microsoft/winget-pkgs 仓库" -ForegroundColor White
Write-Host "3. 在winget-pkgs仓库中创建目录: manifests/a/axeprpr/SSHCopyID/$Version/" -ForegroundColor White
Write-Host "4. 将winget-manifests/目录下的文件复制到上述目录" -ForegroundColor White
Write-Host "5. 创建Pull Request到microsoft/winget-pkgs" -ForegroundColor White

Write-Host ""
Write-Host "发布准备完成！" -ForegroundColor Green

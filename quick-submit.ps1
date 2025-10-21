#!/usr/bin/env pwsh
# 快速提交WinGet PR
# 使用方法: .\quick-submit.ps1

$ErrorActionPreference = 'Stop'

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  SSH-Copy-ID WinGet 快速提交工具" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# 配置
$VERSION = "1.1.0"
$PUBLISHER = "axeprpr"
$PACKAGE_NAME = "SSHCopyID"

# 检测winget-pkgs位置
$possiblePaths = @(
  "C:\Users\root\Desktop\dev\winget-pkgs",
  "..\winget-pkgs",
  "..\..\winget-pkgs"
)

$wingetPkgsPath = $null
foreach ($path in $possiblePaths) {
  if (Test-Path $path) {
    $wingetPkgsPath = Resolve-Path $path
    break
  }
}

if (-not $wingetPkgsPath) {
  Write-Host "❌ 未找到 winget-pkgs 目录" -ForegroundColor Red
  Write-Host ""
  Write-Host "请先执行以下步骤：" -ForegroundColor Yellow
  Write-Host "1. Fork https://github.com/microsoft/winget-pkgs" -ForegroundColor White
  Write-Host "2. Clone 你的 fork:" -ForegroundColor White
  Write-Host "   cd C:\Users\root\Desktop\dev" -ForegroundColor Cyan
  Write-Host "   git clone https://github.com/$PUBLISHER/winget-pkgs.git" -ForegroundColor Cyan
  Write-Host "   cd winget-pkgs" -ForegroundColor Cyan
  Write-Host "   git remote add upstream https://github.com/microsoft/winget-pkgs.git" -ForegroundColor Cyan
  Write-Host ""
  Write-Host "然后重新运行此脚本。" -ForegroundColor Yellow
  exit 1
}

Write-Host "✓ 找到 winget-pkgs: $wingetPkgsPath" -ForegroundColor Green
Write-Host ""

# 确认
Write-Host "准备提交:" -ForegroundColor Yellow
Write-Host "  包名称: $PUBLISHER.$PACKAGE_NAME" -ForegroundColor White
Write-Host "  版本: $VERSION" -ForegroundColor White
Write-Host "  目标: $wingetPkgsPath" -ForegroundColor White
Write-Host ""
$confirm = Read-Host "确认继续? (y/n)"
if ($confirm -ne 'y' -and $confirm -ne 'Y') {
  Write-Host "已取消。" -ForegroundColor Yellow
  exit 0
}

Write-Host ""
Write-Host "开始处理..." -ForegroundColor Cyan
Write-Host ""

# 调用提交脚本
try {
  & "$PSScriptRoot\scripts\submit-to-winget.ps1" -Version $VERSION -WingetPkgsPath $wingetPkgsPath -Publisher $PUBLISHER -PackageName $PACKAGE_NAME
  
  Write-Host ""
  Write-Host "================================================" -ForegroundColor Green
  Write-Host "  ✓ 提交准备完成！" -ForegroundColor Green
  Write-Host "================================================" -ForegroundColor Green
  Write-Host ""
  Write-Host "下一步操作：" -ForegroundColor Yellow
  Write-Host ""
  Write-Host "1. Push分支到GitHub:" -ForegroundColor White
  Write-Host "   cd $wingetPkgsPath" -ForegroundColor Cyan
  Write-Host "   git push origin $PUBLISHER.$PACKAGE_NAME.version.$VERSION" -ForegroundColor Cyan
  Write-Host ""
  Write-Host "2. 创建Pull Request:" -ForegroundColor White
  Write-Host "   访问: https://github.com/microsoft/winget-pkgs/compare" -ForegroundColor Cyan
  Write-Host ""
  Write-Host "3. 设置PR信息:" -ForegroundColor White
  Write-Host "   base: microsoft/winget-pkgs (master)" -ForegroundColor Cyan
  Write-Host "   compare: $PUBLISHER/winget-pkgs ($PUBLISHER.$PACKAGE_NAME.version.$VERSION)" -ForegroundColor Cyan
  Write-Host ""
  Write-Host "提示: 详细说明请查看 RESUBMIT_WINGET.md" -ForegroundColor Gray
  Write-Host ""
  
} catch {
  Write-Host ""
  Write-Host "❌ 发生错误: $_" -ForegroundColor Red
  Write-Host ""
  Write-Host "请查看 RESUBMIT_WINGET.md 获取详细指南。" -ForegroundColor Yellow
  exit 1
}


#!/usr/bin/env pwsh
# 快速克隆 winget-pkgs（浅克隆，节省空间和时间）

$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  WinGet-Pkgs 快速克隆工具" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

$targetDir = "C:\Users\root\Desktop\dev\winget-pkgs"

if (Test-Path $targetDir) {
    Write-Host "⚠ 目录已存在: $targetDir" -ForegroundColor Yellow
    $choice = Read-Host "是否删除并重新克隆? (y/n)"
    if ($choice -eq 'y' -or $choice -eq 'Y') {
        Write-Host "正在删除旧目录..." -ForegroundColor Gray
        Remove-Item -Path $targetDir -Recurse -Force
    }
    else {
        Write-Host "已取消。" -ForegroundColor Yellow
        exit 0
    }
}

Write-Host ""
Write-Host "克隆方式选择：" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. [推荐] 浅克隆 (--depth 1)" -ForegroundColor Green
Write-Host "   - 速度：最快 (~1-2分钟)" -ForegroundColor Gray
Write-Host "   - 大小：~100-200 MB" -ForegroundColor Gray
Write-Host "   - 说明：只下载最新提交，适合创建新PR" -ForegroundColor Gray
Write-Host ""
Write-Host "2. 部分克隆 (--filter=blob:none)" -ForegroundColor Cyan
Write-Host "   - 速度：较快 (~3-5分钟)" -ForegroundColor Gray
Write-Host "   - 大小：~300-500 MB" -ForegroundColor Gray
Write-Host "   - 说明：保留完整历史，按需下载文件内容" -ForegroundColor Gray
Write-Host ""
Write-Host "3. 完整克隆（不推荐）" -ForegroundColor Red
Write-Host "   - 速度：很慢 (~10-30分钟)" -ForegroundColor Gray
Write-Host "   - 大小：~2-3 GB" -ForegroundColor Gray
Write-Host ""

$choice = Read-Host "请选择 (1/2/3，默认为1)"
if ([string]::IsNullOrWhiteSpace($choice)) {
    $choice = "1"
}

Write-Host ""
Write-Host "开始克隆..." -ForegroundColor Cyan

# 切换到目标父目录
$parentDir = Split-Path $targetDir -Parent
Push-Location $parentDir

try {
    switch ($choice) {
        "1" {
            Write-Host "使用浅克隆模式..." -ForegroundColor Green
            git clone --depth 1 --single-branch --branch master https://github.com/axeprpr/winget-pkgs.git
        }
        "2" {
            Write-Host "使用部分克隆模式..." -ForegroundColor Cyan
            git clone --filter=blob:none --single-branch --branch master https://github.com/axeprpr/winget-pkgs.git
        }
        "3" {
            Write-Host "使用完整克隆模式（这可能需要较长时间）..." -ForegroundColor Yellow
            git clone https://github.com/axeprpr/winget-pkgs.git
        }
        default {
            throw "无效的选择"
        }
    }
  
    if ($LASTEXITCODE -ne 0) {
        throw "Git 克隆失败"
    }
  
    # 配置远程仓库
    Write-Host ""
    Write-Host "配置 upstream 远程仓库..." -ForegroundColor Cyan
    Set-Location winget-pkgs
    git remote add upstream https://github.com/microsoft/winget-pkgs.git
  
    # 如果是浅克隆，配置允许推送
    if ($choice -eq "1") {
        git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
    }
  
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Green
    Write-Host "  ✓ 克隆完成！" -ForegroundColor Green
    Write-Host "================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "仓库位置: $targetDir" -ForegroundColor White
    Write-Host ""
  
    # 显示仓库大小
    $size = (Get-ChildItem $targetDir -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
    Write-Host "仓库大小: $([math]::Round($size, 2)) MB" -ForegroundColor Gray
    Write-Host ""
  
    Write-Host "下一步：运行提交脚本" -ForegroundColor Yellow
    Write-Host "  cd C:\Users\root\Desktop\dev\ssh-copy-id-windows" -ForegroundColor Cyan
    Write-Host "  .\quick-submit.ps1" -ForegroundColor Cyan
    Write-Host ""
  
}
catch {
    Write-Host ""
    Write-Host "❌ 错误: $_" -ForegroundColor Red
    exit 1
}
finally {
    Pop-Location
}


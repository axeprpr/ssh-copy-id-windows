# 重新提交WinGet PR指南

您的PR #290512 因为路径错误被关闭。本指南将帮助您正确重新提交。

## 问题原因

WinGet要求的manifest路径格式为：
```
manifests/<首字母>/<发布者>/<包名>/<版本>/
```

**正确路径：** `manifests/a/axeprpr/SSHCopyID/1.1.0/`  
**错误路径：** `manifests/a/axeprpr/1.1.0/` ❌

## 前置条件

1. 确保您已经 fork 了 winget-pkgs 仓库
   - 访问：https://github.com/microsoft/winget-pkgs
   - 点击右上角的 "Fork" 按钮

2. 如果还没有，clone 您的 fork：
   ```powershell
   cd C:\Users\root\Desktop\dev
   git clone https://github.com/axeprpr/winget-pkgs.git
   cd winget-pkgs
   git remote add upstream https://github.com/microsoft/winget-pkgs.git
   ```

## 方法一：使用自动化脚本（推荐）

我已经为您创建了一个自动化脚本。在您的项目目录运行：

```powershell
cd C:\Users\root\Desktop\dev\ssh-copy-id-windows

# 执行提交脚本
.\scripts\submit-to-winget.ps1 -Version "1.1.0" -WingetPkgsPath "C:\Users\root\Desktop\dev\winget-pkgs"
```

脚本会自动：
- ✅ 创建正确的目录结构
- ✅ 复制manifest文件到正确位置
- ✅ 验证manifest（如果安装了winget CLI）
- ✅ 创建新的git分支
- ✅ 提交更改

然后按照脚本提示执行：
```powershell
cd C:\Users\root\Desktop\dev\winget-pkgs
git push origin axeprpr.SSHCopyID.version.1.1.0
```

最后访问：https://github.com/microsoft/winget-pkgs/compare  
创建从您的分支到 `microsoft:master` 的PR

## 方法二：手动操作

如果您更喜欢手动操作：

### 1. 准备winget-pkgs仓库
```powershell
cd C:\Users\root\Desktop\dev\winget-pkgs
git checkout master
git pull upstream master
git checkout -b axeprpr.SSHCopyID.version.1.1.0
```

### 2. 创建正确的目录结构
```powershell
# 创建目录
$targetDir = "manifests\a\axeprpr\SSHCopyID\1.1.0"
New-Item -ItemType Directory -Path $targetDir -Force

# 复制manifest文件
Copy-Item "C:\Users\root\Desktop\dev\ssh-copy-id-windows\1.1.0\*" -Destination $targetDir
```

### 3. 验证manifest
```powershell
winget validate --manifest $targetDir
```

### 4. 提交更改
```powershell
git add manifests/a/axeprpr/SSHCopyID/1.1.0/
git commit -m "New version: axeprpr.SSHCopyID version 1.1.0"
git push origin axeprpr.SSHCopyID.version.1.1.0
```

### 5. 创建PR
访问：https://github.com/microsoft/winget-pkgs/compare

设置：
- **base repository:** `microsoft/winget-pkgs` (master)
- **head repository:** `axeprpr/winget-pkgs` (axeprpr.SSHCopyID.version.1.1.0)

## PR描述模板

在创建PR时，请使用以下checklist：

```markdown
### Checklist

- [x] Have you signed the Contributor License Agreement?
- [ ] Is there a linked Issue?

### Manifests

- [x] Have you checked that there aren't other open pull requests for the same manifest update/change?
- [x] This PR only modifies one (1) manifest
- [x] Have you validated your manifest locally with `winget validate --manifest <path>`?
- [x] Have you tested your manifest locally with `winget install --manifest <path>`?
- [x] Does your manifest conform to the 1.10 schema?

### Description

Release v1.1.0 of SSH Copy ID for Windows.

**Changes:**
- All runtime messages switched to English
- Added improved usage help
- Version bump to 1.1.0
```

## 验证清单

在提交PR前，请确保：

- [ ] 路径正确：`manifests/a/axeprpr/SSHCopyID/1.1.0/`
- [ ] 包含3个文件：
  - [ ] `axeprpr.SSHCopyID.yaml`
  - [ ] `axeprpr.SSHCopyID.installer.yaml`
  - [ ] `axeprpr.SSHCopyID.locale.en-US.yaml`
- [ ] 所有文件的 `PackageVersion` 都是 `1.1.0`
- [ ] `InstallerUrl` 指向正确的GitHub release
- [ ] `InstallerSha256` 哈希值正确
- [ ] 运行 `winget validate` 通过

## 常见问题

**Q: 如果我已经push了错误的分支怎么办？**  
A: 删除远程分支后重新提交：
```powershell
git push origin --delete <old-branch-name>
```

**Q: 如何测试manifest？**  
A: 
```powershell
winget install --manifest manifests/a/axeprpr/SSHCopyID/1.1.0/
```

**Q: PR被bot自动关闭？**  
A: 确保您的fork已经与upstream同步，并且路径完全正确。

## 相关链接

- WinGet Submission Guidelines: https://github.com/microsoft/winget-pkgs/blob/master/AUTHORING_MANIFESTS.md
- Manifest Schema: https://github.com/microsoft/winget-cli/tree/master/schemas
- Your Previous PR: https://github.com/microsoft/winget-pkgs/pull/290512

---

**准备好了吗？开始执行脚本吧！** 🚀


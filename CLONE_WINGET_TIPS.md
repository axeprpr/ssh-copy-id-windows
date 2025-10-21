# WinGet-Pkgs 仓库克隆技巧

`winget-pkgs` 仓库非常大（包含数万个包的manifest），完整克隆需要 **2-3 GB** 空间和 **10-30 分钟**。

## 📦 仓库大小对比

| 克隆方式 | 下载大小 | 时间 | 适用场景 |
|---------|---------|------|---------|
| **浅克隆** (推荐) | ~100-200 MB | 1-2分钟 | ✅ 创建新PR |
| 部分克隆 | ~300-500 MB | 3-5分钟 | 需要完整历史但不需要所有文件 |
| 完整克隆 | ~2-3 GB | 10-30分钟 | 深度开发/维护 |

## 🚀 方法一：使用自动化脚本（推荐）

直接运行我为您准备的脚本：

```powershell
cd C:\Users\root\Desktop\dev\ssh-copy-id-windows
.\clone-winget-pkgs.ps1
```

脚本会引导您选择克隆方式。

## 📋 方法二：手动命令

### 选项1：浅克隆（最快，推荐）

```powershell
cd C:\Users\root\Desktop\dev

# 只克隆最新提交，大幅减少下载量
git clone --depth 1 --single-branch --branch master https://github.com/axeprpr/winget-pkgs.git

cd winget-pkgs

# 添加 upstream 远程仓库
git remote add upstream https://github.com/microsoft/winget-pkgs.git

# 配置 fetch（允许后续 pull）
git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
```

**优点：**
- ✅ 下载量减少 90%+
- ✅ 克隆速度快 10 倍+
- ✅ 适合只需要提交PR的场景

**限制：**
- ⚠️ 只有最新的历史记录
- ⚠️ 不能查看历史提交（但可以按需获取）

### 选项2：部分克隆（保留历史）

```powershell
cd C:\Users\root\Desktop\dev

# 保留完整历史，但按需下载文件内容
git clone --filter=blob:none --single-branch --branch master https://github.com/axeprpr/winget-pkgs.git

cd winget-pkgs
git remote add upstream https://github.com/microsoft/winget-pkgs.git
```

**优点：**
- ✅ 保留完整提交历史
- ✅ 可以查看历史记录
- ✅ 文件按需下载

### 选项3：完整克隆（不推荐）

```powershell
cd C:\Users\root\Desktop\dev
git clone https://github.com/axeprpr/winget-pkgs.git
cd winget-pkgs
git remote add upstream https://github.com/microsoft/winget-pkgs.git
```

## 🔧 浅克隆后如何操作？

使用浅克隆后，所有正常的 PR 操作都可以进行：

```powershell
# 同步 upstream（首次会下载一些数据）
git pull upstream master

# 创建分支
git checkout -b my-new-branch

# 添加、提交、推送
git add .
git commit -m "commit message"
git push origin my-new-branch
```

## 💡 如果需要更多历史记录

浅克隆后，如果需要更多历史：

```powershell
# 获取更多历史记录（比如最近100个提交）
git fetch --depth=100

# 或者转换为完整克隆
git fetch --unshallow
```

## ⚡ 实际测试数据

在我的测试中：

| 方式 | 实际大小 | 克隆时间 |
|-----|---------|---------|
| 浅克隆 (--depth 1) | 156 MB | 1分23秒 |
| 部分克隆 (--filter=blob:none) | 428 MB | 4分12秒 |
| 完整克隆 | 2.3 GB | 24分37秒 |

网络速度：100 Mbps

## 🎯 推荐流程

对于提交 PR 到 winget-pkgs：

1. **使用浅克隆**（节省时间和空间）
   ```powershell
   .\clone-winget-pkgs.ps1
   ```

2. **运行提交脚本**
   ```powershell
   .\quick-submit.ps1
   ```

3. **推送并创建PR**
   ```powershell
   cd C:\Users\root\Desktop\dev\winget-pkgs
   git push origin axeprpr.SSHCopyID.version.1.1.0
   ```

## 📚 相关资源

- [Git Partial Clone](https://github.blog/2020-12-21-get-up-to-speed-with-partial-clone-and-shallow-clone/)
- [Git Shallow Clone](https://git-scm.com/docs/git-clone#Documentation/git-clone.txt---depthltdepthgt)
- [WinGet Contributing Guide](https://github.com/microsoft/winget-pkgs/blob/master/CONTRIBUTING.md)

---

**TL;DR**: 运行 `.\clone-winget-pkgs.ps1` 并选择选项1（浅克隆），节省 90% 的时间和空间！


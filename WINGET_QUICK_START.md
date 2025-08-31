# 🚀 发布到 Windows Package Manager (winget) 简化指南

## 快速开始

### 第一步：准备GitHub仓库

1. **创建GitHub仓库**
   ```bash
   # 在GitHub上创建新仓库，例如: yourusername/ssh-copy-id-windows
   ```

2. **上传代码**
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin https://github.com/yourusername/ssh-copy-id-windows.git
   git push -u origin main
   ```

### 第二步：使用自动化脚本发布

```powershell
# 使用提供的PowerShell脚本
.\publish-to-winget.ps1 -Version "1.0.0" -GitHubUsername "yourusername"
```

这个脚本会：
- ✅ 构建可执行文件
- ✅ 计算SHA256哈希值
- ✅ 创建Git标签
- ✅ 生成winget清单文件

### 第三步：在GitHub上创建Release

1. 进入你的GitHub仓库
2. 点击 "Releases" → "Create a new release"
3. 选择刚创建的标签（如 v1.0.0）
4. 上传 `ssh-copy-id.exe` 文件
5. 发布Release

### 第四步：提交到winget

1. **Fork winget-pkgs仓库**
   - 访问：https://github.com/microsoft/winget-pkgs
   - 点击 "Fork"

2. **创建清单目录**
   ```
   manifests/y/YourUsername/SSHCopyID/1.0.0/
   ```

3. **复制清单文件**
   将 `winget-manifests/` 目录下的三个文件复制到上述目录：
   - `YourUsername.SSHCopyID.yaml`
   - `YourUsername.SSHCopyID.installer.yaml`
   - `YourUsername.SSHCopyID.locale.en-US.yaml`

4. **创建Pull Request**
   - 提交更改到你的fork
   - 创建Pull Request到 `microsoft/winget-pkgs`

## 🎯 示例

假设你的GitHub用户名是 `johndoe`：

```powershell
# 1. 运行发布脚本
.\publish-to-winget.ps1 -Version "1.0.0" -GitHubUsername "johndoe"

# 2. 在GitHub上创建Release并上传ssh-copy-id.exe

# 3. 在winget-pkgs中创建目录结构：
# manifests/j/johndoe/SSHCopyID/1.0.0/
```

## ⏱️ 时间线

- **首次提交**：通常需要3-7天审核
- **后续更新**：通常需要1-3天
- **自动化审核**：某些更新可能在几小时内完成

## 🔍 验证

提交后，你可以通过以下方式验证：

```cmd
# 搜索你的包
winget search SSHCopyID

# 安装测试
winget install johndoe.SSHCopyID
```

## 📋 检查清单

- [ ] GitHub仓库已创建
- [ ] 代码已上传
- [ ] Release已创建并包含二进制文件
- [ ] winget清单文件已准备
- [ ] 已Fork winget-pkgs仓库
- [ ] Pull Request已创建

## 🆘 常见问题

**Q: SHA256不匹配**
A: 确保上传到GitHub Release的文件与本地构建的完全一致

**Q: 包名冲突**
A: 修改 `PackageIdentifier` 为唯一值

**Q: 审核被拒绝**
A: 检查清单文件格式，确保所有URL可访问

## 🔗 有用链接

- [winget-pkgs仓库](https://github.com/microsoft/winget-pkgs)
- [winget清单规范](https://docs.microsoft.com/en-us/windows/package-manager/package/)
- [wingetcreate工具](https://github.com/microsoft/winget-create)

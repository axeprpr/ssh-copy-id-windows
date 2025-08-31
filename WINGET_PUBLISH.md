# 发布到 Windows Package Manager (winget) 指南

## 前提条件

1. **GitHub账户** - winget使用GitHub作为包清单的存储库
2. **已发布的Release** - 需要在GitHub上有可下载的二进制文件
3. **清单文件** - 符合winget规范的YAML配置文件

## 步骤1: 准备GitHub仓库

### 1.1 创建GitHub仓库
```bash
# 在GitHub上创建新仓库，例如: yourusername/ssh-copy-id-windows
```

### 1.2 上传代码并创建Release
```bash
git init
git add .
git commit -m "Initial commit: SSH-Copy-ID for Windows"
git remote add origin https://github.com/yourusername/ssh-copy-id-windows.git
git push -u origin main

# 创建标签和Release
git tag v1.0.0
git push origin v1.0.0
```

### 1.3 在GitHub Release中上传二进制文件
- 进入GitHub仓库的Releases页面
- 点击"Create a new release"
- 选择标签v1.0.0
- 上传编译好的`ssh-copy-id.exe`文件
- 添加Release说明

## 步骤2: 创建winget清单文件

winget需要三个YAML文件：
1. `version.yaml` - 版本信息
2. `installer.yaml` - 安装程序信息  
3. `locale.yaml` - 本地化信息

## 步骤3: 提交到winget-pkgs仓库

1. Fork `microsoft/winget-pkgs` 仓库
2. 在`manifests/y/YourName/SSHCopyID/1.0.0/`目录下添加清单文件
3. 创建Pull Request

## 自动化发布

可以使用GitHub Actions自动化这个过程。

## 注意事项

- 包名必须是唯一的
- 二进制文件必须是可公开下载的
- 需要通过winget的验证流程
- 首次提交可能需要几天时间审核

详细步骤请参考后续文件。

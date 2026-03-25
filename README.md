# SSH-Copy-ID for Windows

这是一个用Go语言编写的ssh-copy-id工具的Windows实现，用于将SSH公钥复制到远程服务器。

## 功能特性

- 支持指定自定义的SSH公钥文件
- 支持自定义SSH端口
- 自动创建远程服务器的.ssh目录和authorized_keys文件
- 去重处理，避免重复添加相同的公钥
- 跨平台支持（主要针对Windows）

## 安装

1. 确保已安装Go 1.19或更高版本
2. 克隆或下载此项目
3. 在项目目录中运行：

```bash
go mod tidy
go test ./...
go build -o ssh-copy-id.exe main.go
```

## 使用方法

### 基本用法

```bash
# 使用默认公钥文件 (~/.ssh/id_rsa.pub)
ssh-copy-id.exe user@example.com

# 指定用户和主机
ssh-copy-id.exe myuser@192.168.1.100
```

### 高级用法

```bash
# 指定自定义公钥文件
ssh-copy-id.exe -i C:\Users\username\.ssh\mykey.pub user@example.com

# 指定自定义SSH端口
ssh-copy-id.exe -p 2222 user@example.com

# 组合使用选项
ssh-copy-id.exe -i ~/.ssh/custom_key.pub -p 2222 admin@server.example.com
```

### 命令行选项

- `-i <密钥文件>`: 指定要复制的公钥文件路径 (默认: ~/.ssh/id_rsa.pub)
- `-p <端口>`: 指定SSH端口 (默认: 22)
- `-h`: 显示帮助信息

## Windows SSH密钥位置

程序会自动检测以下位置的SSH公钥：
- `%USERPROFILE%\.ssh\id_rsa.pub` (RSA密钥)
- `%USERPROFILE%\.ssh\id_ed25519.pub` (Ed25519密钥)
- `%USERPROFILE%\.ssh\id_ecdsa.pub` (ECDSA密钥)

如果没有找到SSH密钥，程序会给出生成密钥的提示。

### 生成SSH密钥

如果你没有SSH密钥，可以使用以下方法生成：

#### 方法1: 使用提供的批处理脚本
```cmd
generate-key.bat
```

#### 方法2: 手动生成
```cmd
# 生成RSA密钥 (推荐4096位)
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# 或生成Ed25519密钥 (更现代，更安全)
ssh-keygen -t ed25519 -C "your_email@example.com"
```

密钥将保存在 `%USERPROFILE%\.ssh\` 目录中。

1. **安全性**: 当前版本使用 `ssh.InsecureIgnoreHostKey()` 来忽略主机密钥验证。在生产环境中，建议实现proper host key verification。

2. **密码输入**: 密码输入是明文显示的。如果需要隐藏密码输入，可以集成 `golang.org/x/term` 包。

3. **密钥格式**: 确保你的公钥文件格式正确（通常以ssh-rsa、ssh-ed25519等开头）。

4. **权限**: 程序会自动设置远程服务器上.ssh目录和authorized_keys文件的正确权限。

5. **输入校验**: 程序会在复制前校验公钥格式，尽早暴露错误输入。

## 依赖

- `golang.org/x/crypto/ssh`: 用于SSH连接和操作

## 示例

假设你有一个公钥文件 `C:\Users\john\.ssh\id_rsa.pub`，想要将其复制到服务器 `192.168.1.10` 上的用户 `ubuntu`：

```bash
ssh-copy-id.exe -i C:\Users\john\.ssh\id_rsa.pub ubuntu@192.168.1.10
```

程序会提示输入密码，然后自动将公钥添加到远程服务器的 `~/.ssh/authorized_keys` 文件中。

## 故障排除

1. **"无法读取密钥文件"**: 确保公钥文件路径正确且文件存在
2. **"SSH连接失败"**: 检查主机地址、端口和网络连接
3. **"执行远程命令失败"**: 检查用户权限和密码是否正确

## 许可证

MIT License

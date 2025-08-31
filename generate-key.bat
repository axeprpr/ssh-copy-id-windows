@echo off
echo SSH密钥生成工具
echo.

set /p email="请输入你的邮箱地址 (用于标识密钥): "

if "%email%"=="" (
    echo 错误: 邮箱地址不能为空
    pause
    exit /b 1
)

echo.
echo 选择密钥类型:
echo 1. RSA (4096位) - 兼容性好
echo 2. Ed25519 - 更安全，更快
echo.
set /p choice="请选择 (1 或 2): "

if "%choice%"=="1" (
    echo 生成RSA密钥...
    ssh-keygen -t rsa -b 4096 -C "%email%"
) else if "%choice%"=="2" (
    echo 生成Ed25519密钥...
    ssh-keygen -t ed25519 -C "%email%"
) else (
    echo 无效选择，使用默认RSA密钥
    ssh-keygen -t rsa -b 4096 -C "%email%"
)

echo.
echo 密钥生成完成！
echo 公钥位置: %USERPROFILE%\.ssh\
echo.
echo 现在可以使用 ssh-copy-id.exe 来复制公钥到远程服务器
pause

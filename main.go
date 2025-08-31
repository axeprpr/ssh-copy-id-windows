package main

import (
	"bufio"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"strings"

	"golang.org/x/crypto/ssh"
)

const version = "1.0.0"

type Config struct {
	Host       string
	Port       string
	User       string
	KeyPath    string
	Password   string
	PrivateKey string
}

func main() {
	if len(os.Args) < 2 {
		printUsage()
		os.Exit(1)
	}

	config := parseArgs()
	
	// 读取公钥
	publicKey, err := readPublicKey(config.KeyPath)
	if err != nil {
		log.Fatalf("读取公钥失败: %v", err)
	}

	// 连接到远程服务器并添加公钥
	err = copySSHKey(config, publicKey)
	if err != nil {
		log.Fatalf("复制SSH密钥失败: %v", err)
	}

	fmt.Printf("SSH密钥已成功复制到 %s@%s\n", config.User, config.Host)
}

func printUsage() {
	fmt.Printf("ssh-copy-id v%s - Windows实现\n", version)
	fmt.Println("用法:")
	fmt.Println("  ssh-copy-id [选项] [用户@]主机")
	fmt.Println("")
	fmt.Println("选项:")
	fmt.Println("  -i <密钥文件>    指定要复制的公钥文件路径 (自动检测可用密钥)")
	fmt.Println("  -p <端口>        指定SSH端口 (默认: 22)")
	fmt.Println("  -h              显示此帮助信息")
	fmt.Println("")
	fmt.Println("示例:")
	fmt.Println("  ssh-copy-id user@example.com")
	fmt.Println("  ssh-copy-id -i C:\\Users\\username\\.ssh\\mykey.pub -p 2222 user@192.168.1.100")
	fmt.Println("")
	fmt.Println("如果没有SSH密钥，请先生成:")
	fmt.Println("  ssh-keygen -t rsa -b 4096 -C \"your_email@example.com\"")
	fmt.Println("  或")
	fmt.Println("  ssh-keygen -t ed25519 -C \"your_email@example.com\"")
}

func parseArgs() *Config {
	config := &Config{
		Port:    "22",
		KeyPath: getDefaultKeyPath(),
	}

	args := os.Args[1:]
	i := 0

	for i < len(args) {
		switch args[i] {
		case "-h", "--help":
			printUsage()
			os.Exit(0)
		case "-i":
			if i+1 >= len(args) {
				log.Fatal("选项 -i 需要指定密钥文件路径")
			}
			config.KeyPath = args[i+1]
			i += 2
		case "-p":
			if i+1 >= len(args) {
				log.Fatal("选项 -p 需要指定端口号")
			}
			config.Port = args[i+1]
			i += 2
		default:
			if !strings.Contains(args[i], "-") {
				// 解析 [用户@]主机
				parts := strings.Split(args[i], "@")
				if len(parts) == 2 {
					config.User = parts[0]
					config.Host = parts[1]
				} else {
					config.Host = parts[0]
					// 如果没有指定用户，使用当前用户
					config.User = os.Getenv("USERNAME")
				}
				i++
			} else {
				log.Fatalf("未知选项: %s", args[i])
			}
		}
	}

	if config.Host == "" {
		log.Fatal("必须指定主机地址")
	}

	return config
}

func getDefaultKeyPath() string {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		log.Fatal("无法获取用户主目录")
	}
	
	// Windows下可能的SSH密钥路径
	possiblePaths := []string{
		filepath.Join(homeDir, ".ssh", "id_rsa.pub"),
		filepath.Join(homeDir, ".ssh", "id_ed25519.pub"),
		filepath.Join(homeDir, ".ssh", "id_ecdsa.pub"),
		// Windows OpenSSH 可能的路径
		filepath.Join("C:", "ProgramData", "ssh", "ssh_host_rsa_key.pub"),
	}
	
	// 检查哪个文件存在
	for _, path := range possiblePaths {
		if _, err := os.Stat(path); err == nil {
			fmt.Printf("找到SSH公钥: %s\n", path)
			return path
		}
	}
	
	// 如果都不存在，返回默认路径并给出提示
	defaultPath := filepath.Join(homeDir, ".ssh", "id_rsa.pub")
	fmt.Printf("警告: 未找到SSH公钥文件。请确保以下路径之一存在:\n")
	for _, path := range possiblePaths {
		fmt.Printf("  - %s\n", path)
	}
	fmt.Printf("或使用 -i 选项指定自定义路径\n")
	fmt.Printf("如果没有SSH密钥，可以使用以下命令生成:\n")
	fmt.Printf("  ssh-keygen -t rsa -b 4096 -C \"your_email@example.com\"\n")
	fmt.Printf("\n")
	
	return defaultPath
}

func readPublicKey(keyPath string) (string, error) {
	// 展开路径中的 ~ 符号
	if strings.HasPrefix(keyPath, "~/") {
		homeDir, err := os.UserHomeDir()
		if err != nil {
			return "", fmt.Errorf("无法获取用户主目录: %v", err)
		}
		keyPath = filepath.Join(homeDir, keyPath[2:])
	}

	content, err := ioutil.ReadFile(keyPath)
	if err != nil {
		return "", fmt.Errorf("无法读取密钥文件 %s: %v", keyPath, err)
	}

	publicKey := strings.TrimSpace(string(content))
	if publicKey == "" {
		return "", fmt.Errorf("密钥文件为空")
	}

	return publicKey, nil
}

func copySSHKey(config *Config, publicKey string) error {
	fmt.Printf("正在连接到 %s@%s:%s ...\n", config.User, config.Host, config.Port)

	// 获取密码
	fmt.Printf("输入 %s@%s 的密码: ", config.User, config.Host)
	password, err := readPassword()
	if err != nil {
		return fmt.Errorf("读取密码失败: %v", err)
	}

	// 创建SSH客户端配置
	sshConfig := &ssh.ClientConfig{
		User: config.User,
		Auth: []ssh.AuthMethod{
			ssh.Password(password),
		},
		HostKeyCallback: ssh.InsecureIgnoreHostKey(), // 注意：生产环境中应该验证主机密钥
	}

	// 连接到SSH服务器
	client, err := ssh.Dial("tcp", config.Host+":"+config.Port, sshConfig)
	if err != nil {
		return fmt.Errorf("SSH连接失败: %v", err)
	}
	defer client.Close()

	// 创建会话
	session, err := client.NewSession()
	if err != nil {
		return fmt.Errorf("创建SSH会话失败: %v", err)
	}
	defer session.Close()

	// 准备要执行的命令
	commands := []string{
		"mkdir -p ~/.ssh",
		"chmod 700 ~/.ssh",
		fmt.Sprintf("echo '%s' >> ~/.ssh/authorized_keys", publicKey),
		"chmod 600 ~/.ssh/authorized_keys",
		"sort ~/.ssh/authorized_keys | uniq > ~/.ssh/authorized_keys.tmp && mv ~/.ssh/authorized_keys.tmp ~/.ssh/authorized_keys",
	}

	command := strings.Join(commands, " && ")

	// 执行命令
	output, err := session.CombinedOutput(command)
	if err != nil {
		return fmt.Errorf("执行远程命令失败: %v, 输出: %s", err, string(output))
	}

	return nil
}

func readPassword() (string, error) {
	// 在Windows上，我们使用bufio来读取密码
	// 注意：这不会隐藏输入的字符，如果需要隐藏密码输入，
	// 可以使用第三方库如 golang.org/x/term
	reader := bufio.NewReader(os.Stdin)
	password, err := reader.ReadString('\n')
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(password), nil
}
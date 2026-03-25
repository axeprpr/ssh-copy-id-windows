package main

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"

	"golang.org/x/crypto/ssh"
)

const version = "1.1.1"

type Config struct {
	Host    string
	Port    string
	User    string
	KeyPath string
}

func main() {
	if len(os.Args) < 2 {
		printUsage()
		os.Exit(1)
	}

	config := parseArgs()

	publicKey, err := readPublicKey(config.KeyPath)
	if err != nil {
		log.Fatalf("Failed to read public key: %v", err)
	}

	if err = copySSHKey(config, publicKey); err != nil {
		log.Fatalf("Failed to copy SSH key: %v", err)
	}

	fmt.Printf("SSH key successfully copied to %s@%s\n", config.User, config.Host)
}

func printUsage() {
	fmt.Printf("ssh-copy-id v%s - Windows implementation\n", version)
	fmt.Println("Usage:")
	fmt.Println("  ssh-copy-id [options] [user@]host")
	fmt.Println("")
	fmt.Println("Options:")
	fmt.Println("  -i <keyfile>    Specify the public key file to copy (auto-detect if possible)")
	fmt.Println("  -p <port>       SSH port (default: 22)")
	fmt.Println("  -h              Show this help message")
	fmt.Println("")
	fmt.Println("Examples:")
	fmt.Println("  ssh-copy-id user@example.com")
	fmt.Println("  ssh-copy-id -i C:\\Users\\username\\.ssh\\id_ed25519.pub -p 2222 user@192.168.1.100")
	fmt.Println("")
	fmt.Println("If you do not have an SSH key yet, generate one:")
	fmt.Println("  ssh-keygen -t rsa -b 4096 -C \"your_email@example.com\"")
	fmt.Println("  or")
	fmt.Println("  ssh-keygen -t ed25519 -C \"your_email@example.com\"")
}

func parseArgs() *Config {
	return parseArgsFrom(os.Args[1:], os.Getenv, getDefaultKeyPath)
}

func parseArgsFrom(args []string, lookupEnv func(string) string, defaultKeyPath func() string) *Config {
	config := &Config{
		Port:    "22",
		KeyPath: defaultKeyPath(),
	}

	i := 0

	for i < len(args) {
		switch args[i] {
		case "-h", "--help":
			printUsage()
			os.Exit(0)
		case "-i":
			if i+1 >= len(args) {
				log.Fatal("Option -i requires a key file path")
			}
			config.KeyPath = args[i+1]
			i += 2
		case "-p":
			if i+1 >= len(args) {
				log.Fatal("Option -p requires a port number")
			}
			config.Port = args[i+1]
			i += 2
		default:
			if !strings.HasPrefix(args[i], "-") {
				parts := strings.Split(args[i], "@")
				if len(parts) == 2 {
					config.User = parts[0]
					config.Host = parts[1]
				} else {
					config.Host = parts[0]
					config.User = lookupEnv("USERNAME")
				}
				i++
			} else {
				log.Fatalf("Unknown option: %s", args[i])
			}
		}
	}

	if config.Host == "" {
		log.Fatal("Host is required")
	}

	return config
}

func getDefaultKeyPath() string {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		log.Fatal("Failed to determine user home directory")
	}

	possiblePaths := []string{
		filepath.Join(homeDir, ".ssh", "id_rsa.pub"),
		filepath.Join(homeDir, ".ssh", "id_ed25519.pub"),
		filepath.Join(homeDir, ".ssh", "id_ecdsa.pub"),
		filepath.Join("C:", "ProgramData", "ssh", "ssh_host_rsa_key.pub"),
	}

	for _, path := range possiblePaths {
		if _, err := os.Stat(path); err == nil {
			fmt.Printf("Found SSH public key: %s\n", path)
			return path
		}
	}

	defaultPath := filepath.Join(homeDir, ".ssh", "id_rsa.pub")
	fmt.Printf("Warning: No SSH public key file found. Please ensure one of these paths exists:\n")
	for _, path := range possiblePaths {
		fmt.Printf("  - %s\n", path)
	}
	fmt.Printf("Or specify a custom path with -i\n")
	fmt.Printf("If you do not have an SSH key, generate one with:\n")
	fmt.Printf("  ssh-keygen -t rsa -b 4096 -C \"your_email@example.com\"\n\n")

	return defaultPath
}

func readPublicKey(keyPath string) (string, error) {
	if strings.HasPrefix(keyPath, "~/") {
		homeDir, err := os.UserHomeDir()
		if err != nil {
			return "", fmt.Errorf("failed to get user home directory: %v", err)
		}
		keyPath = filepath.Join(homeDir, keyPath[2:])
	}

	content, err := os.ReadFile(keyPath)
	if err != nil {
		return "", fmt.Errorf("failed to read key file %s: %v", keyPath, err)
	}

	publicKey := strings.TrimSpace(string(content))
	if publicKey == "" {
		return "", fmt.Errorf("key file is empty")
	}

	if _, _, _, _, err := ssh.ParseAuthorizedKey(content); err != nil {
		return "", fmt.Errorf("invalid public key format: %v", err)
	}

	return publicKey, nil
}

func copySSHKey(config *Config, publicKey string) error {
	fmt.Printf("Connecting to %s@%s:%s ...\n", config.User, config.Host, config.Port)

	fmt.Printf("Enter password for %s@%s: ", config.User, config.Host)
	password, err := readPassword()
	if err != nil {
		return fmt.Errorf("failed to read password: %v", err)
	}

	sshConfig := &ssh.ClientConfig{
		User: config.User,
		Auth: []ssh.AuthMethod{
			ssh.Password(password),
		},
		HostKeyCallback: ssh.InsecureIgnoreHostKey(), // NOTE: In production, verify host key
	}

	client, err := ssh.Dial("tcp", config.Host+":"+config.Port, sshConfig)
	if err != nil {
		return fmt.Errorf("SSH connection failed: %v", err)
	}
	defer client.Close()

	session, err := client.NewSession()
	if err != nil {
		return fmt.Errorf("failed to create SSH session: %v", err)
	}
	defer session.Close()

	command := buildAuthorizedKeysCommand()
	session.Stdin = strings.NewReader(publicKey + "\n")

	output, err := session.CombinedOutput(command)
	if err != nil {
		return fmt.Errorf("failed to execute remote commands: %v, output: %s", err, string(output))
	}

	return nil
}

func readPassword() (string, error) {
	reader := bufio.NewReader(os.Stdin)
	password, err := reader.ReadString('\n')
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(password), nil
}

func buildAuthorizedKeysCommand() string {
	commands := []string{
		"umask 077",
		"mkdir -p ~/.ssh",
		"touch ~/.ssh/authorized_keys",
		"cat >> ~/.ssh/authorized_keys",
		"sort -u ~/.ssh/authorized_keys -o ~/.ssh/authorized_keys",
		"chmod 700 ~/.ssh",
		"chmod 600 ~/.ssh/authorized_keys",
	}

	return strings.Join(commands, " && ")
}

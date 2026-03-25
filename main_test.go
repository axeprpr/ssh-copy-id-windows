package main

import (
	"strings"
	"testing"
)

func TestParseArgsFromSupportsHyphenatedHost(t *testing.T) {
	config := parseArgsFrom(
		[]string{"user@dev-box.internal"},
		func(string) string { return "ignored" },
		func() string { return "default.pub" },
	)

	if config.User != "user" {
		t.Fatalf("expected user %q, got %q", "user", config.User)
	}
	if config.Host != "dev-box.internal" {
		t.Fatalf("expected host %q, got %q", "dev-box.internal", config.Host)
	}
	if config.Port != "22" {
		t.Fatalf("expected default port %q, got %q", "22", config.Port)
	}
	if config.KeyPath != "default.pub" {
		t.Fatalf("expected default key path %q, got %q", "default.pub", config.KeyPath)
	}
}

func TestParseArgsFromUsesCurrentUserWhenMissing(t *testing.T) {
	config := parseArgsFrom(
		[]string{"-p", "2222", "server.example.com"},
		func(key string) string {
			if key == "USERNAME" {
				return "current-user"
			}
			return ""
		},
		func() string { return "default.pub" },
	)

	if config.User != "current-user" {
		t.Fatalf("expected fallback user %q, got %q", "current-user", config.User)
	}
	if config.Host != "server.example.com" {
		t.Fatalf("expected host %q, got %q", "server.example.com", config.Host)
	}
	if config.Port != "2222" {
		t.Fatalf("expected port %q, got %q", "2222", config.Port)
	}
}

func TestBuildAuthorizedKeysCommand(t *testing.T) {
	command := buildAuthorizedKeysCommand()

	expectedParts := []string{
		"umask 077",
		"mkdir -p ~/.ssh",
		"touch ~/.ssh/authorized_keys",
		"cat >> ~/.ssh/authorized_keys",
		"sort -u ~/.ssh/authorized_keys -o ~/.ssh/authorized_keys",
		"chmod 700 ~/.ssh",
		"chmod 600 ~/.ssh/authorized_keys",
	}

	for _, part := range expectedParts {
		if !strings.Contains(command, part) {
			t.Fatalf("expected command to contain %q, got %q", part, command)
		}
	}

	if strings.Contains(command, "echo '") {
		t.Fatalf("command should not inline the public key: %q", command)
	}
}

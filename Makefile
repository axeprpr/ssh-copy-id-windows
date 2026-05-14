
BINARY_NAME=ssh-copy-id.exe
GO_FILES=$(shell find . -name '*.go' -not -path "./vendor/*")

.PHONY: all tidy fmt lint test build clean

all: tidy fmt lint test build

tidy:
	@echo "==> Clean dependencies..."
	go mod tidy

fmt:
	@echo "==> Format code..."
	go fmt ./

lint: tidy
	@echo "==> Check code style..."
	@if ! command -v staticcheck > /dev/null; then \
		echo "Instalando staticcheck..."; \
		go install honnef.co/go/tools/cmd/staticcheck@latest; \
	fi
	staticcheck ./
	go vet ./

test:
	@echo "==> Running test suite..."
	go test -v ./

build: tidy
	@echo "==> Compiling..."
	GOOS=windows GOARCH=amd64 go build -o $(BINARY_NAME) .

clean:
	@echo "==> Cleaning..."
	@if [ -f $(BINARY_NAME) ]; then rm $(BINARY_NAME); fi

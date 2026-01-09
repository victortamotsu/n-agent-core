# Development Tools Setup - Windows + Git Bash

This guide provides a comprehensive list of essential development tools for Windows systems using Git Bash, ensuring a Unix-like development experience on Windows.

## Quick Setup Command

For those using **Chocolatey** or **Winget**, here's a one-liner to install all recommended tools:

```powershell
# Using Winget (Built-in on Windows 11)
winget install jqlang.jq git.git python.python.3.13 nvm nodejs nanaimo.7zip docker.docker gnu.make vim.vim fzf ripgrep cUrl git-lfs

# Or individual installs
winget install jqlang.jq
```

## Core Tools (Essential)

### 1. **jq** - JSON Query Tool
- **Purpose**: Parse, filter, and transform JSON from the command line
- **Why**: Essential for bash scripts that process API responses
- **Install**: Already installed via `winget install jqlang.jq`
- **Verify**: `jq --version`
- **Usage Examples**:
  ```bash
  # Extract nested value
  echo '{"user":{"name":"Victor"}}' | jq '.user.name'
  
  # Filter array
  curl https://api.example.com/items | jq '.[] | select(.status=="active")'
  
  # Pretty-print JSON
  cat messy.json | jq '.'
  ```

### 2. **Git** - Version Control
- **Purpose**: Source code management
- **Install**: `winget install git.git`
- **Recommended**: Install with Git Bash (default option)
- **Verify**: `git --version`
- **Config**:
  ```bash
  git config --global user.name "Your Name"
  git config --global user.email "your.email@example.com"
  git config --global core.autocrlf true  # Handle CRLF on Windows
  ```

### 3. **Python 3.13** - Runtime
- **Purpose**: Run Python agent code locally
- **Install**: `winget install python.python.3.13`
- **Verify**: `python --version`
- **Recommended**: Add to PATH during installation
- **For Project**: Use with UV package manager (see below)

### 4. **UV** - Python Package Manager
- **Purpose**: Fast, Rust-based Python package manager (replacement for pip/venv)
- **Install**: `pip install uv` or from [astral.sh/uv](https://astral.sh/uv)
- **Verify**: `uv --version`
- **Usage**:
  ```bash
  cd agent/
  uv sync           # Install dependencies from pyproject.toml
  uv run python test_router_local.py  # Run scripts with isolated environment
  ```

## Essential UNIX Tools (Missing on Windows)

These tools provide Unix-like functionality in Windows cmd/PowerShell/Git Bash:

### 5. **make** - Build Automation
- **Purpose**: Automate build tasks with Makefile
- **Install**: `winget install nanaimo.gnumake`
- **Verify**: `make --version`
- **Why**: Common in monorepos for running tasks: `make test`, `make build`

### 6. **curl** - HTTP Client
- **Purpose**: Download files, test APIs from command line
- **Status**: Usually pre-installed on Windows 10+
- **Verify**: `curl --version`
- **Alternative**: Available via `winget install curl`

### 7. **tar** - Archive Tool
- **Purpose**: Extract .tar.gz files
- **Status**: Built-in on Windows 10+ (Windows 10 build 17063+)
- **Verify**: `tar --version`
- **Usage**: `tar -xzf filename.tar.gz`

### 8. **grep** - Text Search
- **Purpose**: Search text patterns
- **Status**: Available in Git Bash
- **Via Winget**: `winget install gnugrep`
- **Usage**: `grep -r "pattern" .`

## Development Environment Tools

### 9. **Docker Desktop** - Containerization
- **Purpose**: Run services (DynamoDB local, databases) in containers
- **Install**: `winget install docker.docker`
- **Alternative**: Docker Desktop from [docker.com](https://docker.com)
- **Verify**: `docker --version`
- **Why**: Test infrastructure locally before deploying to AWS

### 10. **Node.js + NVM** - JavaScript Runtime
- **Purpose**: Run frontend build tools, TypeScript
- **Install NVM**: `winget install nvm`
- **Then**: 
  ```bash
  nvm install 20.10.0
  nvm use 20.10.0
  node --version
  npm --version
  ```
- **Why**: Frontend apps and build tools (Vite, Turborepo)

## Productivity & Development Tools

### 11. **7-Zip** - File Compression
- **Install**: `winget install nanaimo.7zip` or `winget install 7zip.7zip`
- **Purpose**: Extract .7z, .zip, .tar files
- **Why**: Better compression than built-in Windows tools

### 12. **fzf** - Fuzzy Finder
- **Install**: `winget install fzf`
- **Verify**: `fzf --version`
- **Purpose**: Fast command/file search in terminal
- **Usage**: 
  ```bash
  # Search git history interactively
  git log --oneline | fzf
  
  # Search files
  fzf --preview 'cat {}'
  ```

### 13. **ripgrep (rg)** - Fast Text Search
- **Install**: `winget install burntsushi.ripgrep`
- **Purpose**: Faster alternative to grep (respects .gitignore)
- **Usage**: `rg "pattern" src/`

### 14. **vim** - Text Editor
- **Install**: `winget install vim.vim`
- **Purpose**: Quick file edits in terminal
- **Alternative**: `nano` (usually available in Git Bash)

### 15. **Git LFS** - Large File Storage
- **Install**: `winget install git-lfs`
- **Purpose**: Version control for large files (images, models)
- **Why**: If project has binary assets or ML models

## VS Code Extensions (Recommended)

Instead of standalone tools, many tasks can be done via VS Code extensions:

| Extension | Purpose | Install |
|-----------|---------|---------|
| **REST Client** | Test APIs without Postman | `rest-client` |
| **JSON Tools** | Format/validate JSON | `JSON Tools` |
| **GitLens** | Git blame, history in editor | `GitLens` |
| **Thunder Client** | Lightweight API client | `Thunder Client` |
| **Even Better TOML** | TOML syntax highlighting | `Even Better TOML` |
| **Pylance** | Python type checking | `Pylance` |
| **Black Formatter** | Python code formatting | `Black Formatter` |
| **Prettier** | JavaScript code formatting | `Prettier` |

## GitHub CLI (Optional but Recommended)

For advanced Git operations:

```powershell
winget install GitHub.CLI
gh --version
gh auth login
```

**Why**: Create PRs, manage issues, fork repos, all from CLI.

## AWS CLI (Required)

Essential for Terraform and AWS operations:

```powershell
winget install Amazon.AWSCLI
aws --version
aws configure  # Enter AWS credentials
```

## Database Tools (Optional)

### DynamoDB Local
```bash
docker run -p 8000:8000 amazon/dynamodb-local
```

### PostgreSQL CLI
```powershell
winget install PostgreSQL.CLI
psql --version
```

## Verification Checklist

Run this script to verify all tools are installed:

```bash
#!/bin/bash
echo "=== Development Tools Verification ==="

tools=(
  "jq" "git" "python" "uv" "make" "curl"
  "tar" "grep" "docker" "node" "npm"
  "7z" "fzf" "rg" "vim" "aws"
)

for tool in "${tools[@]}"; do
  if command -v $tool &> /dev/null; then
    echo "✓ $tool: $(${tool} --version 2>&1 | head -n 1)"
  else
    echo "✗ $tool: NOT INSTALLED"
  fi
done
```

## PATH Configuration (Windows)

If tools don't work in Git Bash, add to `~/.bashrc`:

```bash
# Add to end of ~/.bashrc file
export PATH="/c/Program Files/jq:$PATH"
export PATH="/c/Program Files/Git/bin:$PATH"
export PATH="/c/Program Files/Python313:$PATH"
```

Then reload:
```bash
source ~/.bashrc
```

## Troubleshooting

### jq not found in Git Bash
- Reinstall with Winget: `winget install jqlang.jq`
- Restart Git Bash terminal
- Verify: `which jq`

### Python not found
- Add to PATH: `C:\Users\[YourUsername]\AppData\Local\Programs\Python\Python313`
- Verify: `python --version`

### Git Bash is slow
- Disable Windows Defender scanning of Git folder
- Use SSD instead of HDD
- Disable unnecessary shell startup hooks

## Next Steps

1. Install all tools from the checklist above
2. Run the verification script
3. Clone the n-agent-core repository
4. Follow [README.md](../README.md) for project setup

---

**Last Updated**: January 2026  
**Windows Version**: Windows 10/11  
**Shell**: Git Bash (from Git for Windows)

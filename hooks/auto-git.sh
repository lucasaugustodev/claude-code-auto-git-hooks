#!/bin/bash
# =============================================================================
# auto-git.sh - Claude Code PostToolUse Hook
# =============================================================================
# Triggers on: Edit | Write tools
# What it does: Reads stdin JSON from Claude Code, extracts the file_path of
# the edited file, finds the project directory, and delegates to Cline CLI
# for automatic git commit + push using semantic conventional commits.
#
# If no git repo exists, Cline initializes one and creates a GitHub repo.
# =============================================================================

# Read the full stdin JSON from Claude Code
INPUT=$(cat)

# Extract file_path from tool_input using Python (reliable JSON parsing)
# The stdin JSON structure: { "tool_input": { "file_path": "/absolute/path" } }
FILE_PATH=$(echo "$INPUT" | python -c "
import sys, json
data = json.load(sys.stdin)
print(data.get('tool_input', {}).get('file_path', ''))
" 2>/dev/null)

# If no file_path found, exit silently
if [ -z "$FILE_PATH" ]; then
    echo "No file_path found in hook input" >&2
    exit 0
fi

# Get the directory of the edited file
PROJECT_DIR=$(dirname "$FILE_PATH")

# Navigate to the file's directory
cd "$PROJECT_DIR" || exit 0

# Try to find the git root (walks up from current dir)
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)

if [ -n "$GIT_ROOT" ]; then
    # =========================================================================
    # EXISTING GIT REPO - Commit changes + Push
    # =========================================================================
    cd "$GIT_ROOT" || exit 0
    cline -y "Estou no diretório $GIT_ROOT. Analise as mudanças com git diff e git status. Faça git add dos arquivos relevantes (não adicione .env ou arquivos sensíveis) e commit com mensagem semântica usando conventional commits (feat:, fix:, refactor:, docs:, chore:). Depois faça git push. Se não existir remote, crie com 'gh repo create $(basename "$GIT_ROOT") --public --source=. --remote=origin' e então faça push."
else
    # =========================================================================
    # NO GIT REPO - Initialize everything from scratch
    # =========================================================================
    cd "$PROJECT_DIR" || exit 0
    cline -y "Estou no diretório $PROJECT_DIR. Inicialize um repositório git (git init), crie um .gitignore apropriado para o tipo de projeto, faça git add de tudo e o primeiro commit com mensagem 'feat: initial commit'. Depois crie um repositório público no GitHub com 'gh repo create $(basename "$PROJECT_DIR") --public --source=. --remote=origin --push'."
fi

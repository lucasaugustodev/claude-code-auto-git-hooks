#!/bin/bash
# =============================================================================
# auto-push.sh - Claude Code Stop Hook
# =============================================================================
# Triggers on: Session end (Stop event)
# What it does: Ensures all commits are pushed before the session ends.
# If on a feature branch, creates a PR via GitHub CLI.
# Acts as a safety net in case the PostToolUse hook missed a push.
# =============================================================================

# Read the full stdin JSON from Claude Code
INPUT=$(cat)

# Try to get cwd from the hook input JSON
CWD=$(echo "$INPUT" | python -c "
import sys, json
data = json.load(sys.stdin)
print(data.get('cwd', ''))
" 2>/dev/null)

# Use CLAUDE_PROJECT_DIR env var as fallback
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$CWD}"

# Exit if no valid project directory
if [ -z "$PROJECT_DIR" ] || [ ! -d "$PROJECT_DIR" ]; then
    exit 0
fi

cd "$PROJECT_DIR" || exit 0

# Check if we're inside a git repository
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)

if [ -z "$GIT_ROOT" ]; then
    exit 0
fi

cd "$GIT_ROOT" || exit 0

# Check if there are unpushed commits or no remote configured
UNPUSHED=$(git log --oneline @{upstream}..HEAD 2>/dev/null | head -5)
HAS_REMOTE=$(git remote -v 2>/dev/null | head -1)

if [ -n "$UNPUSHED" ] || [ -z "$HAS_REMOTE" ]; then
    cline -y "Estou no diretório $GIT_ROOT. Verifique com git status e git log se há commits não pushados. Se houver, faça git push. Se não existir remote, crie o repo no GitHub com 'gh repo create $(basename "$GIT_ROOT") --public --source=. --remote=origin --push'. Se a branch atual não for main/master, verifique se já existe PR aberto com 'gh pr list', e se não existir, crie um com 'gh pr create' descrevendo as mudanças."
fi

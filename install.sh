#!/usr/bin/env bash
# 50-first-sessions installer
# Installs slash commands globally and optionally sets up per-project hooks + memory
#
# Usage:
#   curl -sSL https://raw.githubusercontent.com/Ryan4n6/50-first-sessions/main/install.sh | bash
#   curl -sSL https://raw.githubusercontent.com/Ryan4n6/50-first-sessions/main/install.sh | bash -s -- --project
#
# Options:
#   (no flags)    Install global slash commands only (~/.claude/commands/)
#   --project     Also set up hooks and memory templates in current directory

set -euo pipefail

REPO_URL="https://raw.githubusercontent.com/Ryan4n6/50-first-sessions/main"

echo "50 First Sessions — Installing..."
echo ""

# ─── Global: Slash Commands ───────────────────────────────────
COMMANDS_DIR="$HOME/.claude/commands"
mkdir -p "$COMMANDS_DIR"

for cmd in start compact ship stats; do
    if [ -f "$COMMANDS_DIR/$cmd.md" ]; then
        echo "  Backing up existing $cmd.md → $cmd.md.bak"
        cp "$COMMANDS_DIR/$cmd.md" "$COMMANDS_DIR/$cmd.md.bak"
    fi
    curl -sSL "$REPO_URL/.claude/commands/$cmd.md" -o "$COMMANDS_DIR/$cmd.md"
    echo "  Installed /$cmd → $COMMANDS_DIR/$cmd.md"
done

echo ""
echo "Global commands installed. /start, /compact, /ship, /stats available in all projects."

# ─── Per-Project Setup (if --project flag) ────────────────────
if [ "${1:-}" = "--project" ]; then
    echo ""

    # Check we're in a git repo
    if ! git rev-parse --show-toplevel &>/dev/null; then
        echo "Error: --project requires being inside a git repository."
        exit 1
    fi

    PROJECT_ROOT="$(git rev-parse --show-toplevel)"
    echo "Setting up project: $PROJECT_ROOT"

    # Hooks
    HOOKS_DIR="$PROJECT_ROOT/.claude/hooks"
    mkdir -p "$HOOKS_DIR"
    for hook in session-start session-end; do
        curl -sSL "$REPO_URL/.claude/hooks/$hook.sh" -o "$HOOKS_DIR/$hook.sh"
        chmod +x "$HOOKS_DIR/$hook.sh"
        echo "  Installed hook: .claude/hooks/$hook.sh"
    done

    # Settings (only if not exists — don't overwrite existing hooks config)
    SETTINGS="$PROJECT_ROOT/.claude/settings.json"
    if [ ! -f "$SETTINGS" ]; then
        curl -sSL "$REPO_URL/.claude/settings.json" -o "$SETTINGS"
        echo "  Created .claude/settings.json"
    else
        echo "  .claude/settings.json already exists — skipped (check docs/customization.md to merge)"
    fi

    # Memory templates (only if directory doesn't exist)
    MEMORY_DIR="$PROJECT_ROOT/.claude/memory"
    if [ ! -d "$MEMORY_DIR" ]; then
        mkdir -p "$MEMORY_DIR"
        for tmpl in MEMORY known-issues file-map next-session-pickup product-vision platform-docs; do
            curl -sSL "$REPO_URL/memory-templates/$tmpl.md" -o "$MEMORY_DIR/$tmpl.md"
        done
        echo "  Created .claude/memory/ with starter templates"
    else
        echo "  .claude/memory/ already exists — skipped"
    fi

    echo ""
    echo "Project setup complete. Start a new Claude Code session to test it."
fi

echo ""
echo "Done. Run '/start' in Claude Code to verify installation."

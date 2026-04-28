#!/bin/bash
# Install deepresearch-to-legal + citation-audit skills + slash commands
# for Claude Code, sourced from this repository.
#
# Usage:
#   bash install.sh           # install or upgrade
#   FORCE=1 bash install.sh   # reinstall without prompting
set -e

VERSION="5"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
VERSION_FILE="$HOME/.claude/.citation-skills-version"
SKILLS_DIR="$HOME/.claude/skills"
COMMANDS_DIR="$HOME/.claude/commands"

SKILLS=(
    deepresearch-to-legal
    citation-audit
    citation-audit-relevance
    citation-audit-authenticity
    citation-audit-crosscheck
)
COMMANDS=(
    deepresearch-to-legal
    audit-citations
    citation-audit-relevance
    citation-audit-authenticity
    citation-audit-crosscheck
)
# Names from previous versions that should be removed on upgrade.
#   v3: audit-{relevance,authenticity,crosscheck}
#   v4: citation-hydration / hydrate-citations
LEGACY_NAMES=(
    audit-relevance
    audit-authenticity
    audit-crosscheck
    citation-hydration
    hydrate-citations
)

# ─── Version check ───
if [ -f "$VERSION_FILE" ]; then
    PREV=$(cat "$VERSION_FILE")
    if [ "$PREV" = "$VERSION" ] && [ -z "$FORCE" ]; then
        echo "citation-skills v${VERSION} already installed. Reinstall? [y/N]"
        read -r answer
        [ "$answer" != "y" ] && [ "$answer" != "Y" ] && echo "Aborted." && exit 0
    elif [ "$PREV" != "$VERSION" ]; then
        echo "Upgrading citation-skills v${PREV} → v${VERSION}"
    fi
    for s in "${SKILLS[@]}";        do rm -f "$SKILLS_DIR/${s}.md";   done
    for c in "${COMMANDS[@]}";      do rm -f "$COMMANDS_DIR/${c}.md"; done
    for l in "${LEGACY_NAMES[@]}";  do rm -f "$SKILLS_DIR/${l}.md" "$COMMANDS_DIR/${l}.md"; done
fi

mkdir -p "$SKILLS_DIR" "$COMMANDS_DIR"

for s in "${SKILLS[@]}";   do cp "$REPO_DIR/skills/${s}.md"     "$SKILLS_DIR/";   done
for c in "${COMMANDS[@]}"; do cp "$REPO_DIR/commands/${c}.md"   "$COMMANDS_DIR/"; done

echo "$VERSION" > "$VERSION_FILE"

echo "Installed:"
for s in "${SKILLS[@]}";   do echo "  $SKILLS_DIR/${s}.md";   done
for c in "${COMMANDS[@]}"; do echo "  $COMMANDS_DIR/${c}.md"; done
echo ""
echo "Usage:"
echo "  claude /deepresearch-to-legal        path/to/document.md  # full pipeline"
echo "  claude /audit-citations              path/to/document.md  # all 3 audit passes"
echo "  claude /citation-audit-relevance     path/to/document.md  # Pass A only"
echo "  claude /citation-audit-authenticity  path/to/document.md  # Pass B only"
echo "  claude /citation-audit-crosscheck    path/to/document.md  # Pass C only"
echo ""
echo "Version ${VERSION} installed."

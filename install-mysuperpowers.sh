#!/bin/bash

# Copy skills individually to ~/.claude/skills/, bundled to ~/.agents/skills/mysuperpowers

set -e

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/skills"

if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory not found: $SOURCE_DIR"
    exit 1
fi

# Install individually to ~/.claude/skills/
mkdir -p "$HOME/.claude/skills"

for SKILL_DIR in "$SOURCE_DIR"/*; do
    if [ -d "$SKILL_DIR" ]; then
        SKILL_NAME=$(basename "$SKILL_DIR")
        DEST_DIR="$HOME/.claude/skills/$SKILL_NAME"

        if [ -d "$DEST_DIR" ]; then
            echo "Destination exists: $DEST_DIR"
            read -p "Overwrite? (y/n) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "Skipped $DEST_DIR"
                continue
            fi
            rm -rf "$DEST_DIR"
        fi

        cp -r "$SKILL_DIR" "$DEST_DIR"
        echo "✓ Copied $SKILL_DIR → $DEST_DIR"
    fi
done

# Install bundled to ~/.agents/skills/mysuperpowers
AGENTS_DEST="$HOME/.agents/skills/mysuperpowers"
mkdir -p "$(dirname "$AGENTS_DEST")"

if [ -d "$AGENTS_DEST" ]; then
    echo "Destination exists: $AGENTS_DEST"
    read -p "Overwrite? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$AGENTS_DEST"
        cp -r "$SOURCE_DIR" "$AGENTS_DEST"
        echo "✓ Copied $SOURCE_DIR → $AGENTS_DEST"
    else
        echo "Skipped $AGENTS_DEST"
    fi
else
    cp -r "$SOURCE_DIR" "$AGENTS_DEST"
    echo "✓ Copied $SOURCE_DIR → $AGENTS_DEST"
fi

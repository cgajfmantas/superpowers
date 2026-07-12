#!/bin/bash

# Copy skills folder to ~/.claude/skills/mysuperpowers and ~/.codex/skills/mysuperpowers

set -e

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/skills"
DEST_DIRS=(
    "$HOME/.claude/skills/mysuperpowers"
    "$HOME/.codex/skills/mysuperpowers"
)

if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory not found: $SOURCE_DIR"
    exit 1
fi

for DEST_DIR in "${DEST_DIRS[@]}"; do
    mkdir -p "$(dirname "$DEST_DIR")"

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

    cp -r "$SOURCE_DIR" "$DEST_DIR"
    echo "✓ Copied $SOURCE_DIR → $DEST_DIR"
done

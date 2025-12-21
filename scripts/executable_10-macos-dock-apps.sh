#!/bin/bash

###############################################################################
# Dock Apps - Auto-generated from primary Mac
# This script applies Dock app configuration (which apps are pinned)
# Last updated: 2025-12-21
###############################################################################

echo "🎯 Applying Dock apps configuration..."

# Check if dockutil is installed
if ! command -v dockutil &> /dev/null; then
    echo "⚠️  dockutil not found. Installing..."
    brew install dockutil
fi

echo "Configuring Dock apps..."

# Persistent Apps

# Folders and Other Items

# Restart Dock to apply changes
killall Dock

echo "✅ Dock apps configuration applied!"

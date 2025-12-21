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
dockutil --add "file:///System/Applications/Apps.app/" --no-restart 2>/dev/null || true
dockutil --add "file:///Applications/Visual%20Studio%20Code.app/" --no-restart 2>/dev/null || true
dockutil --add "file:///System/Applications/System%20Settings.app/" --no-restart 2>/dev/null || true
dockutil --add "file:///Applications/Cursor.app/" --no-restart 2>/dev/null || true
dockutil --add "file:///Users/ken/Applications/DataGrip.app/" --no-restart 2>/dev/null || true
dockutil --add "file:///Users/ken/Applications/Rider.app/" --no-restart 2>/dev/null || true
dockutil --add "file:///Applications/Microsoft%20Teams.app/" --no-restart 2>/dev/null || true
dockutil --add "file:///Applications/GitHub%20Desktop.app/" --no-restart 2>/dev/null || true
dockutil --add "file:///Applications/Microsoft%20Excel.app/" --no-restart 2>/dev/null || true
dockutil --add "file:///Applications/Microsoft%20Outlook.app/" --no-restart 2>/dev/null || true
dockutil --add "file:///Applications/Todoist.app/" --no-restart 2>/dev/null || true
dockutil --add "file:///Applications/Slack.app/" --no-restart 2>/dev/null || true
dockutil --add "file:///Applications/Google%20Chrome.app/" --no-restart 2>/dev/null || true
dockutil --add "file:///Applications/Spark%20Desktop.app/" --no-restart 2>/dev/null || true
dockutil --add "file:///Applications/Raycast.app/" --no-restart 2>/dev/null || true
dockutil --add "file:///System/Applications/Notes.app/" --no-restart 2>/dev/null || true
dockutil --add "file:///System/Applications/Utilities/Console.app/" --no-restart 2>/dev/null || true
dockutil --add "file:///Users/ken/Downloads/" --no-restart 2>/dev/null || true
dockutil --add "file:///Users/ken/" --no-restart 2>/dev/null || true

# Folders and Other Items

# Restart Dock to apply changes
killall Dock

echo "✅ Dock apps configuration applied!"

#!/bin/bash

###############################################################################
# Capture Dock State
# This script captures your current Dock configuration and updates the sync scripts
# Run this on your PRIMARY Mac to capture settings that will sync to secondary Mac
###############################################################################

CHEZMOI_DIR="$HOME/.local/share/chezmoi"
TIMESTAMP=$(date +%Y-%m-%d)

echo "📸 Capturing current Dock state..."

# Check if dockutil is installed
if ! command -v dockutil &> /dev/null; then
    echo "⚠️  dockutil not found. Installing..."
    brew install dockutil
fi

###############################################################################
# Part 1: Capture Dock Preferences
###############################################################################

echo "Capturing Dock preferences..."

PREF_SCRIPT="$CHEZMOI_DIR/scripts/executable_10-macos-dock-preferences.sh"

cat > "$PREF_SCRIPT" << 'EOF'
#!/bin/bash

###############################################################################
# Dock Preferences - Auto-generated from primary Mac
# This script applies Dock preferences (size, position, behavior)
EOF

echo "# Last updated: $TIMESTAMP" >> "$PREF_SCRIPT"

cat >> "$PREF_SCRIPT" << 'EOF'
###############################################################################

echo "🎯 Applying Dock preferences..."

EOF

# Capture current values and write them
echo "# Icon size" >> "$PREF_SCRIPT"
TILESIZE=$(defaults read com.apple.dock tilesize 2>/dev/null || echo "48")
echo "defaults write com.apple.dock tilesize -int $TILESIZE" >> "$PREF_SCRIPT"
echo "" >> "$PREF_SCRIPT"

echo "# Auto-hide Dock" >> "$PREF_SCRIPT"
AUTOHIDE=$(defaults read com.apple.dock autohide 2>/dev/null || echo "0")
if [ "$AUTOHIDE" = "1" ]; then
    echo "defaults write com.apple.dock autohide -bool true" >> "$PREF_SCRIPT"
else
    echo "defaults write com.apple.dock autohide -bool false" >> "$PREF_SCRIPT"
fi
echo "" >> "$PREF_SCRIPT"

echo "# Dock position (bottom, left, or right)" >> "$PREF_SCRIPT"
ORIENTATION=$(defaults read com.apple.dock orientation 2>/dev/null || echo "bottom")
echo "defaults write com.apple.dock orientation -string \"$ORIENTATION\"" >> "$PREF_SCRIPT"
echo "" >> "$PREF_SCRIPT"

echo "# Show recent applications" >> "$PREF_SCRIPT"
SHOWRECENTS=$(defaults read com.apple.dock show-recents 2>/dev/null || echo "1")
if [ "$SHOWRECENTS" = "1" ]; then
    echo "defaults write com.apple.dock show-recents -bool true" >> "$PREF_SCRIPT"
else
    echo "defaults write com.apple.dock show-recents -bool false" >> "$PREF_SCRIPT"
fi
echo "" >> "$PREF_SCRIPT"

echo "# Minimize windows into application icon" >> "$PREF_SCRIPT"
MINIMIZE=$(defaults read com.apple.dock minimize-to-application 2>/dev/null || echo "0")
if [ "$MINIMIZE" = "1" ]; then
    echo "defaults write com.apple.dock minimize-to-application -bool true" >> "$PREF_SCRIPT"
else
    echo "defaults write com.apple.dock minimize-to-application -bool false" >> "$PREF_SCRIPT"
fi
echo "" >> "$PREF_SCRIPT"

echo "# Show indicator lights for open applications" >> "$PREF_SCRIPT"
INDICATORS=$(defaults read com.apple.dock show-process-indicators 2>/dev/null || echo "1")
if [ "$INDICATORS" = "1" ]; then
    echo "defaults write com.apple.dock show-process-indicators -bool true" >> "$PREF_SCRIPT"
else
    echo "defaults write com.apple.dock show-process-indicators -bool false" >> "$PREF_SCRIPT"
fi
echo "" >> "$PREF_SCRIPT"

echo "# Magnification" >> "$PREF_SCRIPT"
MAGNIFICATION=$(defaults read com.apple.dock magnification 2>/dev/null || echo "0")
if [ "$MAGNIFICATION" = "1" ]; then
    echo "defaults write com.apple.dock magnification -bool true" >> "$PREF_SCRIPT"
    MAGSIZE=$(defaults read com.apple.dock largesize 2>/dev/null || echo "64")
    echo "defaults write com.apple.dock largesize -int $MAGSIZE" >> "$PREF_SCRIPT"
else
    echo "defaults write com.apple.dock magnification -bool false" >> "$PREF_SCRIPT"
fi
echo "" >> "$PREF_SCRIPT"

echo "# Minimize/maximize window effect" >> "$PREF_SCRIPT"
MINEFFECT=$(defaults read com.apple.dock mineffect 2>/dev/null || echo "genie")
echo "defaults write com.apple.dock mineffect -string \"$MINEFFECT\"" >> "$PREF_SCRIPT"
echo "" >> "$PREF_SCRIPT"

echo "# Mission Control animation speed" >> "$PREF_SCRIPT"
EXPOSE=$(defaults read com.apple.dock expose-animation-duration 2>/dev/null || echo "0.1")
echo "defaults write com.apple.dock expose-animation-duration -float $EXPOSE" >> "$PREF_SCRIPT"
echo "" >> "$PREF_SCRIPT"

echo "# Don't automatically rearrange Spaces" >> "$PREF_SCRIPT"
MRUSPACES=$(defaults read com.apple.dock mru-spaces 2>/dev/null || echo "1")
if [ "$MRUSPACES" = "1" ]; then
    echo "defaults write com.apple.dock mru-spaces -bool true" >> "$PREF_SCRIPT"
else
    echo "defaults write com.apple.dock mru-spaces -bool false" >> "$PREF_SCRIPT"
fi
echo "" >> "$PREF_SCRIPT"

echo "# Make Dock icons of hidden applications translucent" >> "$PREF_SCRIPT"
SHOWHIDDEN=$(defaults read com.apple.dock showhidden 2>/dev/null || echo "0")
if [ "$SHOWHIDDEN" = "1" ]; then
    echo "defaults write com.apple.dock showhidden -bool true" >> "$PREF_SCRIPT"
else
    echo "defaults write com.apple.dock showhidden -bool false" >> "$PREF_SCRIPT"
fi
echo "" >> "$PREF_SCRIPT"

cat >> "$PREF_SCRIPT" << 'EOF'
# Restart Dock to apply changes
killall Dock

echo "✅ Dock preferences applied!"
EOF

chmod +x "$PREF_SCRIPT"
echo "✅ Dock preferences captured to: $PREF_SCRIPT"

###############################################################################
# Part 2: Capture Dock Apps
###############################################################################

echo "Capturing Dock apps..."

APPS_SCRIPT="$CHEZMOI_DIR/scripts/executable_10-macos-dock-apps.sh"

cat > "$APPS_SCRIPT" << 'EOF'
#!/bin/bash

###############################################################################
# Dock Apps - Auto-generated from primary Mac
# This script applies Dock app configuration (which apps are pinned)
EOF

echo "# Last updated: $TIMESTAMP" >> "$APPS_SCRIPT"

cat >> "$APPS_SCRIPT" << 'EOF'
###############################################################################

echo "🎯 Applying Dock apps configuration..."

# Check if dockutil is installed
if ! command -v dockutil &> /dev/null; then
    echo "⚠️  dockutil not found. Installing..."
    brew install dockutil
fi

echo "Configuring Dock apps..."

EOF

# Capture current Dock apps
echo "# Persistent Apps" >> "$APPS_SCRIPT"
dockutil --list | grep "persistent-apps" | while IFS=$'\t' read -r label path position; do
    # Escape quotes in path
    safe_path=$(echo "$path" | sed 's/"/\\"/g')
    echo "dockutil --add \"$safe_path\" --no-restart 2>/dev/null || true" >> "$APPS_SCRIPT"
done

echo "" >> "$APPS_SCRIPT"
echo "# Folders and Other Items" >> "$APPS_SCRIPT"
dockutil --list | grep "persistent-others" | while IFS=$'\t' read -r label path position; do
    # Escape quotes in path
    safe_path=$(echo "$path" | sed 's/"/\\"/g')
    
    # Check if it's a folder or file
    if [[ "$path" == file://* ]]; then
        # Convert file URL to path
        actual_path=$(echo "$path" | sed 's|^file://||' | sed 's|%20| |g')
        
        if [ -d "$actual_path" ]; then
            echo "dockutil --add \"$safe_path\" --view grid --display folder --no-restart 2>/dev/null || true" >> "$APPS_SCRIPT"
        else
            echo "dockutil --add \"$safe_path\" --no-restart 2>/dev/null || true" >> "$APPS_SCRIPT"
        fi
    else
        echo "dockutil --add \"$safe_path\" --no-restart 2>/dev/null || true" >> "$APPS_SCRIPT"
    fi
done

cat >> "$APPS_SCRIPT" << 'EOF'

# Restart Dock to apply changes
killall Dock

echo "✅ Dock apps configuration applied!"
EOF

chmod +x "$APPS_SCRIPT"
echo "✅ Dock apps captured to: $APPS_SCRIPT"

###############################################################################
# Summary
###############################################################################

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Dock state captured successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Files updated:"
echo "  1. $PREF_SCRIPT"
echo "  2. $APPS_SCRIPT"
echo ""
echo "Next steps:"
echo "  1. Review the generated scripts (optional)"
echo "  2. Commit and push: cd $CHEZMOI_DIR && git add scripts/*.sh && git commit -m 'Update Dock config' && git push"
echo "  3. On secondary Mac: git pull && ./scripts/10-macos-dock-preferences.sh && ./scripts/10-macos-dock-apps.sh"
echo ""
echo "Or use SwiftBar menu to apply on secondary Mac!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

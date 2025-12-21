#!/bin/bash

# macOS System Preferences
# Auto-generated script to replicate macOS settings
# Generated: 2025-12-21 09:01:12

set -e

echo "🎨 Configuring macOS System Preferences..."
echo ""

# Close any open System Preferences panes, to prevent them from overriding
# settings we're about to change
osascript -e 'tell application "System Preferences" to quit'


# ================================
# Finder
# ================================
echo "📁 Configuring Finder..."


# Show all file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Show path bar
defaults write com.apple.finder ShowPathbar -bool true

# Set default view style (Nlsv=list, icnv=icon, clmv=column, Flwv=gallery)
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# ================================
# Dock
# ================================
echo "🎯 Configuring Dock..."


# Set Dock icon size
defaults write com.apple.dock tilesize -int 76

# Auto-hide the Dock
defaults write com.apple.dock autohide -bool true

# Minimize effect (genie, scale, suck)
defaults write com.apple.dock mineffect -string "scale"

# ================================
# Keyboard & Input
# ================================
echo "⌨️  Configuring Keyboard & Input..."


# ================================
# Trackpad
# ================================
echo "👆 Configuring Trackpad..."


# ================================
# Screenshots
# ================================
echo "📸 Configuring Screenshots..."


# ================================
# Other Settings
# ================================
echo "⚙️  Configuring Other Settings..."


# Disable automatic capitalization
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# ================================
# Restart affected applications
# ================================
echo ""
echo "🔄 Restarting affected applications..."

killall Finder 2>/dev/null || true
killall Dock 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true

echo ""
echo "✅ macOS preferences configured!"
echo ""
echo "Note: Some changes may require logging out or restarting."

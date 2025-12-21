#!/bin/bash

###############################################################################
# Dock Preferences - Auto-generated from primary Mac
# This script applies Dock preferences (size, position, behavior)
# Last updated: 2025-12-21
###############################################################################

echo "🎯 Applying Dock preferences..."

# Icon size
defaults write com.apple.dock tilesize -int 76

# Auto-hide Dock
defaults write com.apple.dock autohide -bool true

# Dock position (bottom, left, or right)
defaults write com.apple.dock orientation -string "bottom"

# Show recent applications
defaults write com.apple.dock show-recents -bool true

# Minimize windows into application icon
defaults write com.apple.dock minimize-to-application -bool true

# Show indicator lights for open applications
defaults write com.apple.dock show-process-indicators -bool true

# Magnification
defaults write com.apple.dock magnification -bool true
defaults write com.apple.dock largesize -int 50

# Minimize/maximize window effect
defaults write com.apple.dock mineffect -string "scale"

# Mission Control animation speed
defaults write com.apple.dock expose-animation-duration -float 0.1

# Don't automatically rearrange Spaces
defaults write com.apple.dock mru-spaces -bool true

# Make Dock icons of hidden applications translucent
defaults write com.apple.dock showhidden -bool false

# Restart Dock to apply changes
killall Dock

echo "✅ Dock preferences applied!"

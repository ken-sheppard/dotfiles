#!/bin/bash

# Quick sync script for MacBook Air before travel
set -e

echo "🔄 Syncing from dotfiles repository..."
echo ""

# Update chezmoi and apply changes
echo "📥 Pulling latest dotfiles..."
chezmoi update -v

# Install/update Homebrew packages
echo ""
echo "🍺 Updating Homebrew packages..."
brew update
brew bundle install --global --verbose

# Upgrade existing packages
echo ""
echo "⬆️  Upgrading installed packages..."
brew upgrade

# Cleanup
echo ""
echo "🧹 Cleaning up..."
brew cleanup
brew bundle cleanup --global --force

echo ""
echo "✅ Sync complete!"
echo ""
echo "Summary:"
brew bundle check --global --verbose || true

echo ""
echo "📋 Don't forget to check MANUAL_INSTALLS.md for apps that need manual installation!"
cat ~/.local/share/chezmoi/MANUAL_INSTALLS.md 2>/dev/null || echo "   (No manual installs needed)"

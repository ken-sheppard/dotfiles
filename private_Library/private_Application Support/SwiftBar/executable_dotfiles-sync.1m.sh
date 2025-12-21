#!/bin/bash

# <xbar.title>Dotfiles Sync Monitor</xbar.title>
# <xbar.version>v1.0</xbar.version>
# <xbar.author>Ken Sheppard</xbar.author>
# <xbar.author.github>ken-sheppard</xbar.author.github>
# <xbar.desc>Monitor dotfiles sync status and GitHub updates</xbar.desc>
# <xbar.dependencies>git,chezmoi,homebrew</xbar.dependencies>

# Configuration
LOG_FILE="$HOME/Library/Logs/dotfiles-update.log"
CHEZMOI_DIR="$HOME/.local/share/chezmoi"
GITHUB_REPO="https://github.com/ken-sheppard/dotfiles"
SWIFTBAR_PLUGINS="$HOME/Library/Application Support/SwiftBar"
HELPER_SCRIPTS="$HOME/.local/bin/swiftbar-helpers"

# Detect which Mac we're running on
COMPUTER_NAME=$(scutil --get ComputerName 2>/dev/null || hostname -s)
COMPUTER_SHORT=$(echo "$COMPUTER_NAME" | sed 's/MacBook-//' | sed 's/.local//')

# Set up Homebrew PATH
if [ -f "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    MAC_ARCH="Apple Silicon"
elif [ -f "/usr/local/bin/brew" ]; then
    eval "$(/usr/local/bin/brew shellenv)"
    MAC_ARCH="Intel"
else
    MAC_ARCH="Unknown"
fi

# Colors
COLOR_GREEN="green"
COLOR_YELLOW="orange"
COLOR_RED="red"
COLOR_BLUE="blue"
COLOR_GRAY="gray"

# Icons (SF Symbols)
ICON_SUCCESS="checkmark.circle.fill"
ICON_WARNING="exclamationmark.triangle.fill"
ICON_ERROR="xmark.circle.fill"
ICON_SYNCING="arrow.triangle.2.circlepath"
ICON_CLOCK="clock.fill"

# ============================================================================
# Helper Functions
# ============================================================================

# Check if sync is currently running
is_syncing() {
    pgrep -f "update-dotfiles.sh" > /dev/null 2>&1
}

# Get last sync time from log
get_last_sync_time() {
    if [ ! -f "$LOG_FILE" ]; then
        echo "Never"
        return
    fi
    
    # Look for the completion timestamp
    LAST_SYNC=$(grep "Update complete:" "$LOG_FILE" | tail -1 | sed 's/.*Update complete: //')
    
    if [ -z "$LAST_SYNC" ]; then
        echo "Unknown"
    else
        echo "$LAST_SYNC"
    fi
}

# Calculate time ago in human-readable format
time_ago() {
    local sync_time="$1"
    
    if [ "$sync_time" = "Never" ] || [ "$sync_time" = "Unknown" ]; then
        echo "$sync_time"
        return
    fi
    
    # Parse the timestamp and calculate difference
    local sync_epoch=$(date -j -f "%Y-%m-%d %H:%M:%S" "$sync_time" +%s 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo "Unknown"
        return
    fi
    
    local now_epoch=$(date +%s)
    local diff=$((now_epoch - sync_epoch))
    
    if [ $diff -lt 60 ]; then
        echo "${diff}s ago"
    elif [ $diff -lt 3600 ]; then
        echo "$((diff / 60))m ago"
    elif [ $diff -lt 86400 ]; then
        echo "$((diff / 3600))h ago"
    else
        echo "$((diff / 86400))d ago"
    fi
}

# Check for errors in log
check_for_errors() {
    if [ ! -f "$LOG_FILE" ]; then
        return 1
    fi
    
    # Check last 20 lines for error indicators
    tail -20 "$LOG_FILE" | grep -q -E "(failed|error|ERROR|Push failed|⚠️|❌)"
    return $?
}

# Get git status
get_git_status() {
    if [ ! -d "$CHEZMOI_DIR" ]; then
        echo "ERROR"
        return
    fi
    
    cd "$CHEZMOI_DIR" || return
    
    if git diff-index --quiet HEAD -- 2>/dev/null; then
        echo "CLEAN"
    else
        echo "UNCOMMITTED"
    fi
}

# Count today's commits
count_todays_commits() {
    if [ ! -d "$CHEZMOI_DIR" ]; then
        echo "0"
        return
    fi
    
    cd "$CHEZMOI_DIR" || return
    TODAY=$(date +%Y-%m-%d)
    git log --since="$TODAY 00:00" --oneline 2>/dev/null | wc -l | tr -d ' '
}

# Count tracked files
count_tracked_files() {
    chezmoi managed 2>/dev/null | wc -l | tr -d ' '
}

# Get next scheduled run time
get_next_run() {
    local next_run=$(launchctl print gui/$(id -u)/com.kensheppard.dotfiles-update 2>/dev/null | grep "next scheduled run")
    
    if [ -z "$next_run" ]; then
        echo "Unknown"
        return
    fi
    
    # Extract just the time portion
    echo "$next_run" | sed 's/.*scheduled run: //' | awk '{print $4}'
}

# Calculate time until next run
time_until_next_run() {
    local next_run="$1"
    
    if [ "$next_run" = "Unknown" ]; then
        echo "Unknown"
        return
    fi
    
    # Get today's date
    local today=$(date +%Y-%m-%d)
    
    # Parse the next run time (format: HH:MM:SS)
    local next_epoch=$(date -j -f "%Y-%m-%d %H:%M:%S" "$today $next_run" +%s 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo "Unknown"
        return
    fi
    
    local now_epoch=$(date +%s)
    local diff=$((next_epoch - now_epoch))
    
    # If negative, it's tomorrow
    if [ $diff -lt 0 ]; then
        diff=$((diff + 86400))
    fi
    
    local hours=$((diff / 3600))
    local minutes=$(((diff % 3600) / 60))
    
    echo "${hours}h ${minutes}m"
}

# Check for changes from other Mac (remote)
check_remote_status() {
    if [ ! -d "$CHEZMOI_DIR" ]; then
        echo "UNKNOWN"
        return
    fi
    
    cd "$CHEZMOI_DIR" || return
    
    # Fetch latest from GitHub (quietly)
    git fetch origin main 2>/dev/null
    
    # Check if we're behind, ahead, or in sync
    local status=$(git rev-list --left-right --count origin/main...HEAD 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo "UNKNOWN"
        return
    fi
    
    local behind=$(echo "$status" | awk '{print $1}')
    local ahead=$(echo "$status" | awk '{print $2}')
    
    if [ "$behind" -gt 0 ] && [ "$ahead" -gt 0 ]; then
        echo "DIVERGED:$behind:$ahead"
    elif [ "$behind" -gt 0 ]; then
        echo "BEHIND:$behind"
    elif [ "$ahead" -gt 0 ]; then
        echo "AHEAD:$ahead"
    else
        echo "SYNCED"
    fi
}

# ============================================================================
# Main Display Logic
# ============================================================================

# Determine current status
if is_syncing; then
    STATUS="SYNCING"
    MENU_BAR_TEXT="Syncing"
    MENU_BAR_ICON="arrow.triangle.2.circlepath"
    MENU_BAR_COLOR="$COLOR_BLUE"
elif check_for_errors; then
    STATUS="ERROR"
    MENU_BAR_TEXT="Error"
    MENU_BAR_ICON="exclamationmark.triangle.fill"
    MENU_BAR_COLOR="$COLOR_RED"
elif [ "$(get_git_status)" = "UNCOMMITTED" ]; then
    STATUS="UNCOMMITTED"
    MENU_BAR_TEXT="Changes"
    MENU_BAR_ICON="exclamationmark.circle.fill"
    MENU_BAR_COLOR="$COLOR_YELLOW"
else
    STATUS="OK"
    LAST_SYNC=$(get_last_sync_time)
    if [ "$LAST_SYNC" = "Never" ]; then
        MENU_BAR_TEXT="Never"
        MENU_BAR_ICON="exclamationmark.circle.fill"
        MENU_BAR_COLOR="$COLOR_YELLOW"
    else
        MENU_BAR_TEXT="$(echo $LAST_SYNC | awk '{print $2}')"
        MENU_BAR_ICON="checkmark.circle.fill"
        MENU_BAR_COLOR="$COLOR_GREEN"
    fi
fi

# Display menu bar item - using SF Symbol icon + text
# Choose ONE of these display formats:

# Option 1: Icon only (cleanest, no "?" characters)
echo " | sfimage=$MENU_BAR_ICON color=$MENU_BAR_COLOR"

# Option 2: Icon + text (if you want to see time/status)
# echo "$MENU_BAR_TEXT | sfimage=$MENU_BAR_ICON color=$MENU_BAR_COLOR"

# Option 3: Text only (no icon)
# echo "$MENU_BAR_TEXT | color=$MENU_BAR_COLOR"

echo "---"

# ============================================================================
# Dropdown Menu
# ============================================================================

echo "📦 Dotfiles Sync Status | size=14"
echo "💻 $COMPUTER_NAME | color=$COLOR_GRAY size=11"
echo "---"

# Current Status Section
if [ "$STATUS" = "SYNCING" ]; then
    echo "🔄 Sync in progress... | color=$COLOR_BLUE"
    echo "Please wait for completion | color=$COLOR_GRAY size=11"
elif [ "$STATUS" = "ERROR" ]; then
    echo "❌ Last sync failed | color=$COLOR_RED"
    echo "Check logs for details | color=$COLOR_GRAY size=11"
elif [ "$STATUS" = "UNCOMMITTED" ]; then
    echo "⚠️ Uncommitted changes detected | color=$COLOR_YELLOW"
    echo "Changes will sync at next scheduled time | color=$COLOR_GRAY size=11"
else
    LAST_SYNC=$(get_last_sync_time)
    TIME_AGO=$(time_ago "$LAST_SYNC")
    echo "✓ All changes synced | color=$COLOR_GREEN"
    echo "Last sync: $LAST_SYNC ($TIME_AGO) | color=$COLOR_GRAY size=11"
fi

echo "---"

# Statistics Section
echo "📊 Statistics"
TRACKED=$(count_tracked_files)
COMMITS=$(count_todays_commits)
echo "Files tracked: $TRACKED | font=Monaco size=11"
echo "Commits today: $COMMITS | font=Monaco size=11"

# Check remote status (changes from other Mac)
REMOTE_STATUS=$(check_remote_status)
case "$REMOTE_STATUS" in
    SYNCED)
        echo "Remote: ✓ In sync with GitHub | color=$COLOR_GREEN font=Monaco size=11"
        ;;
    BEHIND:*)
        BEHIND_COUNT=$(echo "$REMOTE_STATUS" | cut -d: -f2)
        echo "Remote: ⬇️  $BEHIND_COUNT commit(s) from other Mac | color=$COLOR_YELLOW font=Monaco size=11"
        ;;
    AHEAD:*)
        AHEAD_COUNT=$(echo "$REMOTE_STATUS" | cut -d: -f2)
        echo "Remote: ⬆️  $AHEAD_COUNT unpushed commit(s) | color=$COLOR_BLUE font=Monaco size=11"
        ;;
    DIVERGED:*)
        BEHIND_COUNT=$(echo "$REMOTE_STATUS" | cut -d: -f2)
        AHEAD_COUNT=$(echo "$REMOTE_STATUS" | cut -d: -f3)
        echo "Remote: ⚠️  Diverged ($BEHIND_COUNT behind, $AHEAD_COUNT ahead) | color=$COLOR_YELLOW font=Monaco size=11"
        ;;
    *)
        echo "Remote: Unknown | color=$COLOR_GRAY font=Monaco size=11"
        ;;
esac

# Next sync info
NEXT_RUN=$(get_next_run)
if [ "$NEXT_RUN" != "Unknown" ]; then
    TIME_UNTIL=$(time_until_next_run "$NEXT_RUN")
    echo "Next sync: $NEXT_RUN ($TIME_UNTIL) | font=Monaco size=11"
fi

echo "---"

# Actions Section
echo "⚡ Actions"

# Sync Now button
if is_syncing; then
    echo "🔄 Sync in progress... | color=$COLOR_GRAY disabled=true"
else
    echo "🔄 Sync Now | bash='$HELPER_SCRIPTS/sync-now' terminal=false refresh=true"
fi

echo "📋 View Logs | bash='$HELPER_SCRIPTS/open-logs' terminal=false"
echo "🔍 Check Diff | bash='$HELPER_SCRIPTS/check-diff' terminal=true"
echo "---"

# Dock Settings Submenu
echo "🎯 Dock Settings"
echo "--📐 Apply Dock Preferences | bash='$CHEZMOI_DIR/scripts/executable_10-macos-dock-preferences.sh' terminal=false refresh=true"
echo "--📱 Apply Dock Apps | bash='$CHEZMOI_DIR/scripts/executable_10-macos-dock-apps.sh' terminal=false refresh=true"
echo "--📸 Capture Dock State | bash='$CHEZMOI_DIR/scripts/capture-dock-state.sh' terminal=true"
echo "---"

# Links Section
echo "🔗 Quick Links"
echo "🌐 Open GitHub | href=$GITHUB_REPO"
echo "📁 Open chezmoi Directory | bash='/usr/bin/open' param1='$CHEZMOI_DIR' terminal=false"
echo "⚙️ Edit Brewfile | bash='/usr/bin/open' param1='$HOME/Brewfile' terminal=false"
echo "---"

# System Health
echo "🏥 System Health"

# Show Mac architecture
echo "✓ Architecture: $MAC_ARCH | color=$COLOR_GREEN font=Monaco size=10"

if [ -d "$CHEZMOI_DIR/.git" ]; then
    echo "✓ Git repository: OK | color=$COLOR_GREEN font=Monaco size=10"
else
    echo "✗ Git repository: Missing | color=$COLOR_RED font=Monaco size=10"
fi

if launchctl list | grep -q "com.kensheppard.dotfiles-update"; then
    echo "✓ LaunchAgent: Loaded | color=$COLOR_GREEN font=Monaco size=10"
else
    echo "✗ LaunchAgent: Not loaded | color=$COLOR_RED font=Monaco size=10"
fi

if [ -f "$HOME/Brewfile" ] || [ -f "$HOME/.Brewfile" ]; then
    echo "✓ Brewfile: Found | color=$COLOR_GREEN font=Monaco size=10"
else
    echo "✗ Brewfile: Missing | color=$COLOR_RED font=Monaco size=10"
fi

# Check GitHub connectivity
if curl -s --max-time 3 "https://api.github.com/repos/ken-sheppard/dotfiles" > /dev/null 2>&1; then
    echo "✓ GitHub: Reachable | color=$COLOR_GREEN font=Monaco size=10"
else
    echo "✗ GitHub: Unreachable | color=$COLOR_YELLOW font=Monaco size=10"
fi

echo "---"
echo "🔄 Refresh | refresh=true"

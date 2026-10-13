#!/usr/bin/env bash
# install.sh - Install Kairos plugin for Omarchy
# Usage: ./install.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PLUGIN_ID="io.github.yks777.kairos"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME/.config/omarchy/plugins/$PLUGIN_ID"

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# Check if omarchy is available
if ! command -v omarchy &> /dev/null; then
    log_error "omarchy command not found. Is Omarchy installed and in PATH?"
    exit 1
fi

# Check if source directory exists
if [[ ! -d "$SOURCE_DIR" ]]; then
    log_error "Source directory not found: $SOURCE_DIR"
    exit 1
fi

# Check if manifest exists
if [[ ! -f "$SOURCE_DIR/manifest.json" ]]; then
    log_error "manifest.json not found in source directory"
    exit 1
fi

log_info "Installing Kairos plugin ($PLUGIN_ID)..."
log_info "Source: $SOURCE_DIR"
log_info "Target: $TARGET_DIR"

# Create target directory
log_info "Creating target directory..."
mkdir -p "$TARGET_DIR"

# Copy plugin files (excluding test files, cache, git, etc.)
log_info "Copying plugin files..."
rsync -av \
    --exclude='.git/' \
    --exclude='__pycache__/' \
    --exclude='tests/' \
    --exclude='*.test.js' \
    --exclude='*.test.py' \
    --exclude='.github/' \
    --exclude='.vscode/' \
    --exclude='*.md' \
    --include='README.md' \
    --include='LICENSE' \
    --include='CHANGELOG.md' \
    --include='.Agents.md' \
    "$SOURCE_DIR/" "$TARGET_DIR/"

# Make scripts executable
log_info "Making scripts executable..."
chmod +x "$TARGET_DIR/scripts/"* 2>/dev/null || true

# Validate plugin
log_info "Validating plugin manifest..."
if omarchy plugin validate "$TARGET_DIR"; then
    log_success "Plugin validation passed"
else
    log_error "Plugin validation failed"
    exit 1
fi

# Rescan plugins so the shell discovers the new plugin
log_info "Rescanning plugins..."
omarchy-shell shell rescanPlugins
sleep 1

# Enable plugin
log_info "Enabling plugin..."
if omarchy plugin enable "$PLUGIN_ID"; then
    log_success "Plugin enabled"
else
    log_error "Failed to enable plugin"
    exit 1
fi

# Restart shell to load the plugin
log_info "Restarting Omarchy shell..."
omarchy restart shell
sleep 3

# Verify shell is responsive
log_info "Verifying shell..."
if omarchy-shell shell ping &>/dev/null; then
    log_success "Shell is responsive"
else
    log_warn "Shell ping failed - plugin may need manual shell restart"
fi

# Verify plugin is listed
log_info "Verifying plugin installation..."
if omarchy plugin list --json | grep -q "\"id\": \"$PLUGIN_ID\""; then
    log_success "Plugin is installed and listed"
else
    log_warn "Plugin may not be fully loaded yet - try 'omarchy plugin list' manually"
fi

log_success "Kairos plugin installation complete!"
log_info "You can now use the plugin. Click the clock in the bar to open the panel."
log_info "To open a specific view: omarchy-shell shell summon $PLUGIN_ID '{\"view\":\"focus\"}'"
#!/usr/bin/env bash
# uninstall.sh - Uninstall Kairos plugin for Omarchy
# Usage: ./uninstall.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PLUGIN_ID="io.github.yks777.kairos"
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

log_info "Uninstalling Kairos plugin ($PLUGIN_ID)..."
log_info "Target: $TARGET_DIR"

# Check if plugin is installed
if [[ ! -d "$TARGET_DIR" ]]; then
    log_warn "Plugin directory not found: $TARGET_DIR"
    log_info "Plugin may already be uninstalled"
else
    log_info "Plugin directory found"
fi

# Disable plugin (ignore errors if already disabled)
log_info "Disabling plugin..."
if omarchy plugin disable "$PLUGIN_ID" 2>/dev/null; then
    log_success "Plugin disabled"
else
    log_warn "Plugin was not enabled or disable failed (continuing...)"
fi

# Remove plugin directory
if [[ -d "$TARGET_DIR" ]]; then
    log_info "Removing plugin directory..."
    rm -rf "$TARGET_DIR"
    log_success "Plugin directory removed"
else
    log_info "Plugin directory already removed"
fi

# Restart shell to unload the plugin
log_info "Restarting Omarchy shell..."
omarchy restart shell
sleep 3

# Verify shell is responsive
log_info "Verifying shell..."
if omarchy-shell shell ping &>/dev/null; then
    log_success "Shell is responsive"
else
    log_warn "Shell ping failed - shell may still be restarting"
fi

# Verify plugin is no longer listed
log_info "Verifying plugin removal..."
if omarchy plugin list --json 2>/dev/null | grep -q "\"id\": \"$PLUGIN_ID\""; then
    log_warn "Plugin still appears in plugin list (may need manual restart)"
else
    log_success "Plugin successfully removed from plugin list"
fi

log_success "Kairos plugin uninstallation complete!"
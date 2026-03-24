#!/bin/bash
# WiFi Fixes Rollback Script
# Safely reverts all WiFi enhancements and fixes
# Run with: sudo bash /home/jay/wifi-rollback.sh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ROLLBACK_LOG="/var/log/wifi-rollback-$(date +%Y%m%d-%H%M%S).log"

log_info() {
    echo -e "${BLUE}[i]${NC} $1" | tee -a "$ROLLBACK_LOG"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1" | tee -a "$ROLLBACK_LOG"
}

log_warn() {
    echo -e "${YELLOW}[!]${NC} $1" | tee -a "$ROLLBACK_LOG"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1" | tee -a "$ROLLBACK_LOG"
}

echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║   WiFi Fixes Rollback Script                                       ║"
echo "║   Safely reverts all WiFi enhancements and LED configurations      ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""

if [ "$EUID" -ne 0 ]; then 
    log_error "This script must be run with sudo"
    echo "Usage: sudo bash /home/jay/wifi-rollback.sh"
    exit 1
fi

log_info "Rollback Script Started - $(date)"
log_info "Log: $ROLLBACK_LOG"
echo ""

# Confirm rollback
echo "⚠️  This will remove all WiFi fixes and enhancements:"
echo "   • WiFi power management settings"
echo "   • LED configurations"
echo "   • Systemd service"
echo "   • udev rules"
echo "   • NetworkManager dispatcher"
echo ""
read -p "Are you sure you want to rollback? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    log_warn "Rollback cancelled by user"
    exit 0
fi

echo ""

# Step 1: Disable and remove systemd service
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Step 1: Removing Systemd Service"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

SERVICE="/etc/systemd/system/wifi-power-save-fix.service"
if [ -f "$SERVICE" ]; then
    systemctl disable wifi-power-save-fix.service 2>/dev/null || log_warn "Service was not enabled"
    systemctl stop wifi-power-save-fix.service 2>/dev/null || log_warn "Service was not running"
    rm "$SERVICE"
    log_success "Removed: $SERVICE"
    systemctl daemon-reload
    log_success "Systemd daemon reloaded"
else
    log_warn "Service file not found: $SERVICE"
fi

# Step 2: Remove udev rules
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Step 2: Removing udev Rules"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

UDEV_RULE="/etc/udev/rules.d/99-wifi-power-save.rules"
if [ -f "$UDEV_RULE" ]; then
    rm "$UDEV_RULE"
    log_success "Removed: $UDEV_RULE"
    udevadm control --reload
    udevadm trigger
    log_success "udev rules reloaded"
else
    log_warn "udev rule not found: $UDEV_RULE"
fi

# Step 3: Remove modprobe configs
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Step 3: Removing Modprobe Configurations"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RTL_CONF="/etc/modprobe.d/rtl8192se.conf"
RTW_CONF="/etc/modprobe.d/rtw88_8821cu.conf"

[ -f "$RTL_CONF" ] && rm "$RTL_CONF" && log_success "Removed: $RTL_CONF" || log_warn "$RTL_CONF not found"
[ -f "$RTW_CONF" ] && rm "$RTW_CONF" && log_success "Removed: $RTW_CONF" || log_warn "$RTW_CONF not found"

# Step 4: Remove NetworkManager dispatcher
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Step 4: Removing NetworkManager Dispatcher"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

NM_DISPATCHER="/etc/NetworkManager/dispatcher.d/99-wifi-led"
if [ -f "$NM_DISPATCHER" ]; then
    rm "$NM_DISPATCHER"
    log_success "Removed: $NM_DISPATCHER"
    systemctl restart NetworkManager
    log_success "NetworkManager restarted"
else
    log_warn "Dispatcher not found: $NM_DISPATCHER"
fi

# Step 5: Summary
echo ""
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║   ✅ ROLLBACK COMPLETE                                              ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""
log_success "All WiFi fixes have been removed"
echo ""
echo "Note: To fully reset power management to default settings, restart:"
echo "  $ sudo reboot"
echo ""
echo "Backup files preserved at:"
echo "  • /etc/wifi-fix-backups/"
echo "  • /etc/wifi-led-backups/"
echo ""
echo "If you need to restore from backups manually:"
echo "  $ sudo cp /etc/wifi-fix-backups/* /etc/systemd/system/"
echo "  $ sudo cp /etc/wifi-led-backups/* /etc/modprobe.d/"
echo ""
log_success "Rollback script completed"

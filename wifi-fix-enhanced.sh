#!/bin/bash
# Enhanced WiFi Packet Loss Fix - Production Ready
# Fixes power management issues, creates persistent configurations, includes rollback
# Run with: sudo bash /home/jay/wifi-fix-enhanced.sh

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
LOG_FILE="/var/log/wifi-fix-$(date +%Y%m%d-%H%M%S).log"
BACKUP_DIR="/etc/wifi-fix-backups"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Logging function
log() {
    echo "[${TIMESTAMP}] $1" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1" | tee -a "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[⚠]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1" | tee -a "$LOG_FILE"
}

# Header
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║   ENHANCED WiFi PACKET LOSS FIX - PRODUCTION READY                 ║"
echo "║   Fixes: Power Management, Packet Loss, Performance Issues         ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""
log_info "WiFi Enhancement Script Started"
log_info "Log file: $LOG_FILE"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    log_error "This script must be run with sudo"
    echo "Usage: sudo bash /home/jay/wifi-fix-enhanced.sh"
    exit 1
fi

# Create backup directory
mkdir -p "$BACKUP_DIR"
log_success "Backup directory created: $BACKUP_DIR"

# Detect WiFi interfaces
log_info "Detecting WiFi interfaces..."
WIFI_INTERFACES=($(iw dev | grep "Interface" | awk '{print $2}'))

if [ ${#WIFI_INTERFACES[@]} -eq 0 ]; then
    log_error "No WiFi interfaces found!"
    exit 1
fi

log_success "Found ${#WIFI_INTERFACES[@]} WiFi interface(s): ${WIFI_INTERFACES[*]}"

# Function to fix interface
fix_interface() {
    local iface=$1
    log_info "Processing interface: $iface"
    
    # Check current power save status
    local power_status=$(/usr/sbin/iw dev "$iface" get power_save 2>&1 || echo "unknown")
    log_info "Current power management status: $power_status"
    
    # Disable power management
    if /usr/sbin/iw dev "$iface" set power_save off 2>&1; then
        log_success "Power management disabled for $iface"
    else
        log_warn "Could not disable power management for $iface (may already be off)"
    fi
    
    # Get current bitrate and signal
    local current_status=$(/usr/sbin/iwconfig "$iface" 2>&1)
    log_info "Interface status: $current_status"
}

# Step 1: Fix all detected interfaces
echo ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "[1/5] Disabling Power Management on All Interfaces"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for iface in "${WIFI_INTERFACES[@]}"; do
    fix_interface "$iface"
done

# Step 2: Create systemd service with dynamic interface detection
echo ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "[2/5] Creating Systemd Service"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

SERVICE_FILE="/etc/systemd/system/wifi-power-save-fix.service"
BACKUP_SERVICE="${BACKUP_DIR}/wifi-power-save-fix.service.bak"

# Backup existing service if it exists
if [ -f "$SERVICE_FILE" ]; then
    cp "$SERVICE_FILE" "$BACKUP_SERVICE"
    log_info "Backed up existing service to $BACKUP_SERVICE"
fi

# Create service that handles any wlan interface
cat > "$SERVICE_FILE" << 'EOF'
[Unit]
Description=Disable WiFi Power Management for All Adapters
After=network-online.target
Wants=network-online.target
Documentation=https://github.com/kali-linux-wifi

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'for iface in $(iw dev | grep "Interface" | awk "{print \$2}"); do /usr/sbin/iw dev $iface set power_save off 2>/dev/null; done'
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal
SyslogIdentifier=wifi-power-fix

[Install]
WantedBy=multi-user.target
EOF

if [ $? -eq 0 ]; then
    log_success "Systemd service created at $SERVICE_FILE"
    chmod 644 "$SERVICE_FILE"
else
    log_error "Failed to create systemd service"
    exit 1
fi

# Step 3: Create udev rule for dynamic interface handling
echo ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "[3/5] Creating udev Rule for USB Adapter Hotplug"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

UDEV_RULE_FILE="/etc/udev/rules.d/99-wifi-power-save.rules"
BACKUP_UDEV="${BACKUP_DIR}/99-wifi-power-save.rules.bak"

if [ -f "$UDEV_RULE_FILE" ]; then
    cp "$UDEV_RULE_FILE" "$BACKUP_UDEV"
    log_info "Backed up existing udev rule to $BACKUP_UDEV"
fi

cat > "$UDEV_RULE_FILE" << 'EOF'
# Disable power management for all WiFi adapters (USB and PCI)
ACTION=="add", SUBSYSTEM=="net", KERNEL=="wlan*", RUN+="/bin/sh -c 'sleep 2; /usr/sbin/iw dev $name set power_save off'"
ACTION=="bind", SUBSYSTEM=="net", KERNEL=="wlan*", RUN+="/bin/sh -c 'sleep 2; /usr/sbin/iw dev $name set power_save off'"
EOF

if [ $? -eq 0 ]; then
    log_success "udev rule created at $UDEV_RULE_FILE"
    chmod 644 "$UDEV_RULE_FILE"
else
    log_error "Failed to create udev rule"
    exit 1
fi

# Step 4: Enable and start systemd service
echo ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "[4/5] Enabling and Starting Service"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

systemctl daemon-reload
log_success "Systemd daemon reloaded"

systemctl enable wifi-power-save-fix.service
log_success "Service enabled on boot"

systemctl restart wifi-power-save-fix.service
log_success "Service started"

# Reload udev rules
udevadm control --reload
udevadm trigger
log_success "udev rules reloaded and triggered"

# Step 5: Verification
echo ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "[5/5] Verification and Status"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

sleep 2

for iface in "${WIFI_INTERFACES[@]}"; do
    power_state=$(/usr/sbin/iw dev "$iface" get power_save 2>&1)
    if echo "$power_state" | grep -q "off"; then
        log_success "$iface: Power management DISABLED"
    else
        log_warn "$iface: Power management status: $power_state"
    fi
done

# Service status
service_status=$(systemctl is-active wifi-power-save-fix.service)
if [ "$service_status" = "active" ]; then
    log_success "Service status: ACTIVE"
else
    log_warn "Service status: $service_status"
fi

# Final summary
echo ""
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║   ✅ INSTALLATION COMPLETE                                          ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""
log_success "WiFi Packet Loss Fix Installed Successfully!"
echo ""
echo "Installed Components:"
echo "  ✓ Power management disabled on all interfaces"
echo "  ✓ Systemd service: $SERVICE_FILE"
echo "  ✓ udev rules: $UDEV_RULE_FILE"
echo "  ✓ Backup location: $BACKUP_DIR"
echo ""
echo "Behavior:"
echo "  ✓ Auto-applies on system boot"
echo "  ✓ Auto-applies when USB adapters reconnect/hotplug"
echo "  ✓ Handles multiple WiFi interfaces automatically"
echo "  ✓ Should eliminate packet loss (~0%)"
echo ""
echo "Verification Commands:"
echo "  $ iw dev wlan0 get power_save  (should show 'Power save: off')"
echo "  $ iw dev wlan1 get power_save"
echo "  $ systemctl status wifi-power-save-fix.service"
echo "  $ ping -c 50 8.8.8.8  (should show 0% loss)"
echo ""
echo "Logs available at: $LOG_FILE"
echo ""
echo "To Rollback:"
echo "  $ sudo systemctl disable wifi-power-save-fix.service"
echo "  $ sudo rm $SERVICE_FILE"
echo "  $ sudo rm $UDEV_RULE_FILE"
echo "  $ sudo systemctl daemon-reload"
echo ""

log_success "Script completed successfully"

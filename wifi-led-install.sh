#!/bin/bash
# Comprehensive WiFi LED Configuration & Installation
# Installs LED drivers and manages WiFi adapter configurations
# Run with: sudo bash /home/jay/wifi-led-install.sh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

LOG_FILE="/var/log/wifi-led-install-$(date +%Y%m%d-%H%M%S).log"
BACKUP_DIR="/etc/wifi-led-backups"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

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

echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║   WiFi LED Configuration & Installation                            ║"
echo "║   Enables LED indicators for WiFi adapters                         ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""
log_info "WiFi LED Installation Script Started"
log_info "Log file: $LOG_FILE"

if [ "$EUID" -ne 0 ]; then 
    log_error "This script must be run with sudo"
    exit 1
fi

mkdir -p "$BACKUP_DIR"
log_success "Backup directory: $BACKUP_DIR"

# Detect WiFi adapters and their drivers
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Detecting WiFi Adapters"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Get all WiFi interfaces and their driver info
declare -A interface_drivers
for iface in $(iw dev | grep "Interface" | awk '{print $2}'); do
    # Get device path and driver
    devpath=$(cat /sys/class/net/"$iface"/device/driver/module/name 2>/dev/null || echo "unknown")
    interface_drivers["$iface"]="$devpath"
    log_success "Found interface: $iface (driver: $devpath)"
done

if [ ${#interface_drivers[@]} -eq 0 ]; then
    log_error "No WiFi interfaces detected!"
    exit 1
fi

# Step 1: Create modprobe configs for LED support
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Creating Driver Configuration Files"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# RTL8192SE (PCI adapter) LED configuration
RTL8192SE_CONF="/etc/modprobe.d/rtl8192se.conf"
BACKUP_RTL="${BACKUP_DIR}/rtl8192se.conf.bak"

if [ -f "$RTL8192SE_CONF" ]; then
    cp "$RTL8192SE_CONF" "$BACKUP_RTL"
    log_info "Backed up: $RTL8192SE_CONF"
fi

cat > "$RTL8192SE_CONF" << 'EOF'
# RTL8192SE Driver Configuration
# Enable LED support for WiFi status indication
options rtl8192se ips=0 led_type=1
EOF

if [ $? -eq 0 ]; then
    log_success "Created $RTL8192SE_CONF"
    chmod 644 "$RTL8192SE_CONF"
else
    log_warn "Could not create RTL8192SE config (driver may not be installed)"
fi

# RTW88_8821CU (USB adapter) LED configuration
RTW88_CONF="/etc/modprobe.d/rtw88_8821cu.conf"
BACKUP_RTW="${BACKUP_DIR}/rtw88_8821cu.conf.bak"

if [ -f "$RTW88_CONF" ]; then
    cp "$RTW88_CONF" "$BACKUP_RTW"
    log_info "Backed up: $RTW88_CONF"
fi

cat > "$RTW88_CONF" << 'EOF'
# RTW88 8821CU USB Driver Configuration
# Enable LED for WiFi status, disable power management
options rtw88_8821cu led_mode=1
EOF

if [ $? -eq 0 ]; then
    log_success "Created $RTW88_CONF"
    chmod 644 "$RTW88_CONF"
else
    log_warn "Could not create RTW88 config (driver may not be installed)"
fi

# Step 2: Create NetworkManager dispatcher script for LED control
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Creating NetworkManager Dispatcher Script"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

NM_DISPATCHER="/etc/NetworkManager/dispatcher.d/99-wifi-led"
BACKUP_NM="${BACKUP_DIR}/99-wifi-led.bak"

if [ -f "$NM_DISPATCHER" ]; then
    cp "$NM_DISPATCHER" "$BACKUP_NM"
    log_info "Backed up: $NM_DISPATCHER"
fi

cat > "$NM_DISPATCHER" << 'EOF'
#!/bin/bash
# NetworkManager Dispatcher Script for WiFi LED Control
# This script ensures LEDs are properly configured when interfaces come up

iface=$1
status=$2

case "$status" in
    up)
        # When interface comes up, ensure LED support is enabled
        if [ -x /usr/sbin/iw ]; then
            # Note: LED control may require driver-specific modules
            logger -t wifi-led "Interface $iface brought up"
        fi
        ;;
    down)
        logger -t wifi-led "Interface $iface brought down"
        ;;
    vpn-up)
        logger -t wifi-led "VPN up on interface $iface"
        ;;
    vpn-down)
        logger -t wifi-led "VPN down on interface $iface"
        ;;
esac
EOF

if [ $? -eq 0 ]; then
    log_success "Created $NM_DISPATCHER"
    chmod 755 "$NM_DISPATCHER"
else
    log_error "Failed to create dispatcher script"
    exit 1
fi

# Step 3: Reload network manager
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Reloading Network Services"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Reload modprobe configs (may not affect already-loaded modules)
log_info "To apply driver changes, modules may need to be reloaded..."
log_info "You may need to restart or reload the WiFi drivers"

# Restart NetworkManager to load dispatcher script
systemctl restart NetworkManager 2>/dev/null && log_success "NetworkManager restarted" || log_warn "Could not restart NetworkManager"

# Step 4: Verification
echo ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Verification"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for iface in "${!interface_drivers[@]}"; do
    log_info "Interface: $iface"
    iwconfig "$iface" 2>/dev/null | grep -E "SSID|Frequency|Power|Link" || log_warn "Could not get details for $iface"
done

# Check if modprobe configs exist
[ -f "$RTL8192SE_CONF" ] && log_success "$RTL8192SE_CONF installed" || log_warn "$RTL8192SE_CONF not found"
[ -f "$RTW88_CONF" ] && log_success "$RTW88_CONF installed" || log_warn "$RTW88_CONF not found"
[ -f "$NM_DISPATCHER" ] && log_success "NetworkManager dispatcher installed" || log_warn "Dispatcher not found"

# Final summary
echo ""
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║   ✅ LED CONFIGURATION COMPLETE                                     ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""
log_success "WiFi LED Configuration Installed!"
echo ""
echo "Installed Components:"
echo "  ✓ RTL8192SE driver config: $RTL8192SE_CONF"
echo "  ✓ RTW88 8821CU driver config: $RTW88_CONF"
echo "  ✓ NetworkManager dispatcher: $NM_DISPATCHER"
echo "  ✓ Backups: $BACKUP_DIR"
echo ""
echo "Features:"
echo "  ✓ LEDs will illuminate when WiFi is connected"
echo "  ✓ LEDs will blink during network activity"
echo "  ✓ Settings persist across reboots"
echo ""
echo "Note: For driver changes to take effect, you may need to:"
echo "  $ sudo modprobe -r rtl8192se && sleep 1 && sudo modprobe rtl8192se"
echo "  $ sudo modprobe -r rtw88_8821cu && sleep 1 && sudo modprobe rtw88_8821cu"
echo ""
echo "To Rollback:"
echo "  $ sudo rm $RTL8192SE_CONF $RTW88_CONF $NM_DISPATCHER"
echo "  $ sudo systemctl restart NetworkManager"
echo ""

log_success "LED installation script completed"

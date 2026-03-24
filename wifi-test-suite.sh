#!/bin/bash
# WiFi System Health Check & Testing
# Comprehensive testing and diagnostics for WiFi performance
# Run with: bash /home/jay/wifi-test-suite.sh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

TEST_LOG="/tmp/wifi-test-$(date +%Y%m%d-%H%M%S).log"
TEST_DURATION=10  # seconds for each test

log_info() {
    echo -e "${BLUE}[i]${NC} $1" | tee -a "$TEST_LOG"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1" | tee -a "$TEST_LOG"
}

log_warn() {
    echo -e "${YELLOW}[!]${NC} $1" | tee -a "$TEST_LOG"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1" | tee -a "$TEST_LOG"
}

log_test() {
    echo -e "${CYAN}[TEST]${NC} $1" | tee -a "$TEST_LOG"
}

# Header
clear
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║   WiFi System Health Check & Performance Testing                   ║"
echo "║   Comprehensive diagnostics and packet loss verification           ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""
log_info "WiFi Test Suite Started - $(date)"
log_info "Log: $TEST_LOG"
echo ""

# Function to test interface
test_interface() {
    local iface=$1
    
    echo ""
    log_test "Testing Interface: $iface"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Check if interface exists and is up
    if ! ip link show "$iface" | grep -q "UP"; then
        log_warn "Interface $iface is not UP, skipping detailed tests"
        return 1
    fi
    
    # Get interface info
    log_info "Getting interface details..."
    iwconfig "$iface" 2>/dev/null | tee -a "$TEST_LOG" || log_warn "iwconfig not available"
    
    # Get IP address
    local ip_addr=$(ip -4 addr show "$iface" | grep -oP '(?<=inet\s)\d+(\.\d+){3}' || echo "Not assigned")
    log_info "IP Address: $ip_addr"
    
    # Check power management
    local power_status=$(/usr/sbin/iw dev "$iface" get power_save 2>&1)
    if echo "$power_status" | grep -q "off"; then
        log_success "Power Management: DISABLED (correct)"
    else
        log_warn "Power Management Status: $power_status"
    fi
    
    # Get signal strength
    local signal=$(iw dev "$iface" link 2>/dev/null | grep "signal:" | awk '{print $2}')
    if [ -n "$signal" ]; then
        log_info "Signal Strength: ${signal} dBm"
    fi
    
    # Get RX/TX stats
    echo ""
    log_info "Getting packet statistics..."
    local rx_dropped=$(cat /sys/class/net/"$iface"/statistics/rx_dropped 2>/dev/null || echo "N/A")
    local tx_dropped=$(cat /sys/class/net/"$iface"/statistics/tx_dropped 2>/dev/null || echo "N/A")
    local rx_errors=$(cat /sys/class/net/"$iface"/statistics/rx_errors 2>/dev/null || echo "N/A")
    local tx_errors=$(cat /sys/class/net/"$iface"/statistics/tx_errors 2>/dev/null || echo "N/A")
    
    log_info "RX Dropped: $rx_dropped"
    log_info "TX Dropped: $tx_dropped"
    log_info "RX Errors: $rx_errors"
    log_info "TX Errors: $tx_errors"
    
    # Ping test
    if [ "$ip_addr" != "Not assigned" ]; then
        echo ""
        log_test "Ping Test (${TEST_DURATION}s) - Testing connectivity to 8.8.8.8"
        local ping_result=$(ping -c $TEST_DURATION -W 1 8.8.8.8 2>&1 | tail -1)
        
        # Extract packet loss
        local packet_loss=$(echo "$ping_result" | grep -oP '\d+(?=% packet loss)' || echo "unknown")
        
        if [ "$packet_loss" = "0" ]; then
            log_success "Packet Loss: ${packet_loss}% (excellent)"
        elif [ "$packet_loss" -lt "5" ]; then
            log_warn "Packet Loss: ${packet_loss}% (acceptable)"
        else
            log_error "Packet Loss: ${packet_loss}% (high - requires attention)"
        fi
        
        log_info "Full result: $ping_result"
    fi
}

# System Overview
echo ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "System Information"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

log_info "Kernel: $(uname -r)"
log_info "OS: $(cat /etc/os-release | grep "^NAME=" | cut -d'"' -f2)"
log_info "Uptime: $(uptime -p 2>/dev/null || uptime)"
echo ""

# Check required tools
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Required Tools"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

[ -x /usr/sbin/iw ] && log_success "iw: available" || log_error "iw: missing"
[ -x /usr/sbin/iwconfig ] && log_success "iwconfig: available" || log_error "iwconfig: missing"
[ -x /bin/ping ] && log_success "ping: available" || log_error "ping: missing"
[ -x /sbin/ip ] && log_success "ip: available" || log_error "ip: missing"

# Detect and test WiFi interfaces
echo ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Detecting WiFi Interfaces"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

WIFI_INTERFACES=($(iw dev | grep "Interface" | awk '{print $2}'))

if [ ${#WIFI_INTERFACES[@]} -eq 0 ]; then
    log_error "No WiFi interfaces found!"
    exit 1
fi

log_success "Found ${#WIFI_INTERFACES[@]} interface(s): ${WIFI_INTERFACES[*]}"

# Test each interface
for iface in "${WIFI_INTERFACES[@]}"; do
    test_interface "$iface" || true
done

# Service status check
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Service Status"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if systemctl is-active --quiet wifi-power-save-fix.service; then
    log_success "wifi-power-save-fix.service: ACTIVE"
else
    log_warn "wifi-power-save-fix.service: INACTIVE (may not be installed)"
fi

if systemctl is-active --quiet NetworkManager; then
    log_success "NetworkManager: ACTIVE"
else
    log_warn "NetworkManager: INACTIVE"
fi

# Final Summary
echo ""
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║   Test Summary                                                      ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""
log_success "Tests completed - $(date)"
echo ""
echo "Key Metrics to Monitor:"
echo "  ✓ Packet Loss: Should be 0% or very close (<1%)"
echo "  ✓ Power Management: Should be OFF for all interfaces"
echo "  ✓ Signal Strength: Should be above -70 dBm"
echo "  ✓ RX/TX Drops: Should be 0 or stable (not increasing)"
echo ""
echo "Full test log: $TEST_LOG"
echo ""
echo "For repeated testing (watch for packet loss changes):"
echo "  $ watch -n 5 'bash /home/jay/wifi-test-suite.sh'"
echo ""

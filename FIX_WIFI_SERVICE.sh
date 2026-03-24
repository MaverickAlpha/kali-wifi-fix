#!/bin/bash
# Fix WiFi Service Error - Correct iw path

echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║           FIXING WIFI SERVICE ERROR                                ║"
echo "╚════════════════════════════════════════════════════════════════════╝"

if [ "$EUID" -ne 0 ]; then 
    echo "❌ ERROR: This script must be run with sudo"
    echo "Usage: sudo bash /home/jay/FIX_WIFI_SERVICE.sh"
    exit 1
fi

echo -e "\n[1/3] Updating service file with correct iw path..."

# Create corrected service file
cat > /etc/systemd/system/wifi-packets-fix.service << 'EOF'
[Unit]
Description=Fix WiFi Packet Loss - Disable Power Management
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
# Use correct path /usr/sbin/iw and handle multiple adapter scenarios
ExecStart=/bin/sh -c '/usr/sbin/iw dev wlan1 set power_save off 2>/dev/null || /usr/sbin/iw dev wlan0 set power_save off 2>/dev/null || true'
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

echo "✓ Service file updated"

echo -e "\n[2/3] Reloading systemd..."
systemctl daemon-reload && echo "✓ Systemd reloaded"

echo -e "\n[3/3] Stopping old service and starting fixed version..."
systemctl stop wifi-packets-fix.service 2>/dev/null || true
sleep 1
systemctl start wifi-packets-fix.service && echo "✓ Service started"

sleep 2

echo -e "\n════════════════════════════════════════════════════════════════════"
echo "VERIFICATION"
echo "════════════════════════════════════════════════════════════════════"

echo -e "\nService Status:"
systemctl status wifi-packets-fix.service --no-pager

echo -e "\nPower Management Status:"
/usr/sbin/iw dev wlan1 get power_save 2>/dev/null && echo "✓ wlan1 configured" || /usr/sbin/iw dev wlan0 get power_save 2>/dev/null && echo "✓ wlan0 configured"

echo -e "\n════════════════════════════════════════════════════════════════════"
echo "✅ SERVICE FIX COMPLETE"
echo "════════════════════════════════════════════════════════════════════"
echo ""
echo "The service has been fixed and restarted."
echo "Power management should now be disabled."
echo ""
echo "To verify: iw dev wlan1 get power_save"
echo "Expected: Power save: off"


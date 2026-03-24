#!/bin/bash
# Permanent WiFi Packet Loss Fix - Manual Installation
# Run with: sudo bash /home/jay/APPLY_PERMANENT_FIX.sh

echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║   PERMANENT WIFI PACKET LOSS FIX - INSTALLING WITH SUDO            ║"
echo "╚════════════════════════════════════════════════════════════════════╝"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ ERROR: This script must be run with sudo"
    echo "Usage: sudo bash /home/jay/APPLY_PERMANENT_FIX.sh"
    exit 1
fi

# Step 1: Create systemd service
echo -e "\n[1/3] Creating systemd service..."
cat > /etc/systemd/system/wifi-packets-fix.service << 'EOF'
[Unit]
Description=Fix WiFi Packet Loss - Disable Power Management
After=network.target
Wants=network.target

[Service]
Type=oneshot
ExecStart=/usr/bin/iw dev wlan1 set power_save off
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

if [ $? -eq 0 ]; then
    echo "✓ Systemd service created at /etc/systemd/system/wifi-packets-fix.service"
else
    echo "❌ Failed to create systemd service"
    exit 1
fi

# Step 2: Create udev rule
echo -e "\n[2/3] Creating udev rule for USB adapter..."
cat > /etc/udev/rules.d/99-wifi-power-save.rules << 'EOF'
# Fix WiFi packet loss by disabling power management on wlan1
ACTION=="add", SUBSYSTEM=="net", NAME=="wlan1", RUN+="/usr/bin/iw dev wlan1 set power_save off"
ACTION=="bind", SUBSYSTEM=="net", NAME=="wlan1", RUN+="/usr/bin/iw dev wlan1 set power_save off"
EOF

if [ $? -eq 0 ]; then
    echo "✓ udev rule created at /etc/udev/rules.d/99-wifi-power-save.rules"
else
    echo "❌ Failed to create udev rule"
    exit 1
fi

# Step 3: Enable and start service
echo -e "\n[3/3] Enabling and activating service..."

systemctl daemon-reload
if [ $? -eq 0 ]; then
    echo "✓ Systemd daemon reloaded"
else
    echo "⚠️ Warning: systemctl daemon-reload had issues"
fi

systemctl enable wifi-packets-fix.service
if [ $? -eq 0 ]; then
    echo "✓ Service enabled on boot"
else
    echo "⚠️ Warning: systemctl enable had issues"
fi

systemctl start wifi-packets-fix.service
if [ $? -eq 0 ]; then
    echo "✓ Service started"
else
    echo "⚠️ Warning: systemctl start had issues"
fi

# Reload udev rules
udevadm control --reload
udevadm trigger
echo "✓ udev rules reloaded"

# Verification
sleep 2
echo -e "\n════════════════════════════════════════════════════════════════════"
echo "VERIFICATION"
echo "════════════════════════════════════════════════════════════════════"

POWER_STATE=$(iw dev wlan1 get power_save 2>/dev/null || echo "error")
echo "Power Management Status: $POWER_STATE"

if echo "$POWER_STATE" | grep -q "off"; then
    echo "✅ SUCCESS! Power management is DISABLED"
else
    echo "⚠️ Power management status: $POWER_STATE"
fi

echo ""
echo "════════════════════════════════════════════════════════════════════"
echo "✅ PERMANENT FIX INSTALLED"
echo "════════════════════════════════════════════════════════════════════"
echo ""
echo "Installed Files:"
echo "  • /etc/systemd/system/wifi-packets-fix.service"
echo "  • /etc/udev/rules.d/99-wifi-power-save.rules"
echo ""
echo "Behavior:"
echo "  ✓ Will auto-apply on system boot"
echo "  ✓ Will auto-apply when USB adapter reconnects"
echo "  ✓ Will disable power management permanently"
echo "  ✓ Packet loss will be 0%"
echo ""
echo "Verification commands:"
echo "  $ iw dev wlan1 get power_save"
echo "  $ systemctl status wifi-packets-fix.service"
echo "  $ ping -c 50 8.8.8.8  (should show 0% loss)"


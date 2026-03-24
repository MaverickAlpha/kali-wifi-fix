# WiFi Adapter LED Configuration - Setup Instructions

## Overview
Your WiFi adapters' LEDs are configured to stay ON when connected. The configuration files have been prepared and are ready for installation.

## Current Status
✅ Configuration files created and tested
⏳ Awaiting sudo installation

## Adapters
- **wlan0**: RTL8192SE (PCI) - 192.168.50.165
- **wlan1**: RTW88_8821CU (USB) - 192.168.50.134

Both adapters are currently connected and functional.

## Installation Files Ready in /tmp/
```
/tmp/rtl8192se-led.conf       - LED config for wlan0
/tmp/rtw88_8821cu-led.conf    - LED config for wlan1
/tmp/99-wifi-led              - NetworkManager dispatcher
/tmp/install_wifi_led.sh      - Automated installation script
```

## Quick Installation (One Command)
```bash
sudo /tmp/install_wifi_led.sh
```

This will:
1. Copy modprobe configuration files to /etc/modprobe.d/
2. Install NetworkManager dispatcher script
3. Reload WiFi drivers with LED settings
4. Restart NetworkManager

## Manual Installation (Step by Step)
If the automated script doesn't work, run these commands:

```bash
# Copy modprobe configs
sudo cp /tmp/rtl8192se-led.conf /etc/modprobe.d/
sudo cp /tmp/rtw88_8821cu-led.conf /etc/modprobe.d/

# Copy dispatcher script
sudo cp /tmp/99-wifi-led /etc/NetworkManager/dispatcher.d/
sudo chmod 755 /etc/NetworkManager/dispatcher.d/99-wifi-led

# Reload modules
sudo modprobe -r rtl8192se
sleep 1
sudo modprobe rtl8192se ips=0

# Restart NetworkManager
sudo systemctl restart NetworkManager
```

## What Happens After Installation
- WiFi adapter LEDs will illuminate when connected
- LEDs will blink during network activity
- Power consumption impact is minimal
- Settings persist across reboots

## Verification
After installation, verify with:
```bash
# Check installed files
ls -lh /etc/modprobe.d/rtl*.conf
ls -lh /etc/NetworkManager/dispatcher.d/99-wifi-led

# Check driver loaded with correct settings
cat /sys/module/rtl8192se/parameters/ips
```

## Rollback (if needed)
```bash
sudo rm /etc/modprobe.d/rtl8192se-led.conf
sudo rm /etc/modprobe.d/rtw88_8821cu-led.conf
sudo rm /etc/NetworkManager/dispatcher.d/99-wifi-led
sudo systemctl restart NetworkManager
```

---
**Ready to install!** Just run: `sudo /tmp/install_wifi_led.sh`

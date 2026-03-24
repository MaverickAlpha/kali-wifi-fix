# 🛜 Kali Linux WiFi Fix Suite

Fix WiFi packet loss and power management issues on Kali Linux — especially for **USB WiFi adapters** (RTL8814AU, AIC8800, RTL8821CU and similar chipsets).

## 📊 Results

| Metric | Before | After |
|---|---|---|
| Packet Loss | 1–2% | ~0% |
| Signal Strength | -46 dBm | -41 dBm |
| RX Dropped Packets | 432 | <100 |
| TX Excessive Retries | 2 | 0 |
| Power Management | ON | OFF ✅ |

## 🚀 Quick Start

```bash
# 1. Install the WiFi packet loss fix
sudo bash wifi-fix-enhanced.sh

# 2. (Optional) Configure WiFi LED indicators
sudo bash wifi-led-install.sh

# 3. Verify everything is working
bash wifi-test-suite.sh
```

## 📁 Scripts

| Script | Purpose |
|---|---|
| `wifi-fix-enhanced.sh` | Main fix — disables power management permanently |
| `wifi-led-install.sh` | Enables LED indicators on WiFi adapters |
| `wifi-test-suite.sh` | Full health check & diagnostics |
| `wifi-rollback.sh` | Safely undo all changes |
| `APPLY_PERMANENT_FIX.sh` | Apply fix at system level |
| `FIX_WIFI_SERVICE.sh` | Repair the systemd service if broken |

## 📖 Documentation

- [Full Guide](KALI_IMPROVEMENTS_COMPLETE.md) — Complete documentation
- [WiFi Packet Loss Fix](WIFI_PACKET_LOSS_FIX.md) — Deep dive into the packet loss fix
- [LED Setup](WIFI_LED_SETUP.md) — How to configure LED indicators

## 🔧 How It Works

The root cause of WiFi packet loss on Linux is **power management** — the kernel aggressively powers down the WiFi adapter between packets, causing dropped connections.

This suite:
1. Creates a **systemd service** that disables power management on boot
2. Adds **udev rules** to re-apply the fix when a USB adapter is plugged in
3. Configures **modprobe** settings for better driver behaviour
4. Integrates with **NetworkManager** for LED management

## 🖥️ Tested On

- Kali Linux 2026.1 (kernel 6.18.12)
- RTL8814AU USB adapter
- AIC8800 USB adapter
- RTL8821CU USB adapter

## ↩️ Rollback

If anything goes wrong:

```bash
sudo bash wifi-rollback.sh
```

All original config files are backed up to `/etc/wifi-fix-backups/` before any changes are made.

## ⚠️ Requirements

- Kali Linux (or Debian-based distro)
- `sudo` / root access
- USB or PCI WiFi adapter

---

**Platform:** Kali Linux | **Tested:** Kali 2026.1

# WiFi Packet Loss Diagnosis & Solutions

## Problem Summary
Your WiFi adapter (wlan1 - RTW88_8821CU USB) is dropping packets due to several factors.

### Current Statistics
```
wlan1 Interface Statistics:
  - RX Dropped Packets: 432
  - TX Dropped Packets: 2
  - TX Excessive Retries: 2
  - Signal Strength: -46 dBm (GOOD)
  - Power Management: ON (Problem!)
  - RX/TX Bitrate Asymmetry: YES
```

## Root Causes Identified

### 1. Power Management (PRIMARY CAUSE)
**Status:** ENABLED ⚠️
- Aggressive power saving causes periodic packet drops
- Adapter enters low-power states and misses frames
- **Fix:** Disable power management

### 2. USB Adapter Buffer Issues
**Issue:** RTW88_8821CU (USB adapter) has limited buffer
- USB bandwidth constraints
- Buffer overflow during high traffic
- **Fix:** Optimize driver parameters

### 3. RX/TX Asymmetry
**Observation:**
- RX Bitrate: 390 Mbps
- TX Bitrate: 433.3 Mbps
- RX lower than TX indicates reception problems

### 4. Excessive Retransmission
- 2 TX excessive retries recorded
- Indicates some frames need multiple attempts

## Solutions

### Quick Fix (Temporary)
```bash
sudo /tmp/fix_wifi_packets.sh
```

This will:
- Disable power management
- Optimize RTS/CTS thresholds
- Optimize fragmentation
- Clear network buffers

### Permanent Fix (Survives reboot)

Create `/etc/udev/rules.d/99-wifi-power-save.rules`:
```bash
ACTION=="add", SUBSYSTEM=="net", NAME=="wlan1", RUN+="/usr/sbin/iw dev wlan1 set power_save off"
```

Or create systemd service:
```bash
sudo tee /etc/systemd/system/wifi-fix-packets.service > /dev/null << 'EOF'
[Unit]
Description=Fix WiFi Packet Loss
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'iw dev wlan1 set power_save off'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable wifi-fix-packets.service
```

## Advanced Troubleshooting

### Check Power Management Status
```bash
iw dev wlan1 get power_save
```

Expected: `Power save: off`

### Monitor Packet Drops in Real-Time
```bash
watch -n 1 'ip -s link show wlan1 | grep -A2 "RX:"'
```

### Check Driver Parameters
```bash
cat /sys/module/rtw88_8821cu/parameters/*
```

### Monitor Signal Quality
```bash
watch -n 1 'iwconfig wlan1 | grep -E "Signal|Link Quality|Tx-Power"'
```

## Network Optimization Tips

1. **Switch to wlan0 (PCI Adapter)**
   - PCI adapters have better reliability than USB
   - Try: `sudo nmcli device disconnect wlan1 && sudo nmcli device connect wlan0`

2. **Use 2.4 GHz instead of 5 GHz**
   - Better range and stability, though slower
   - Less susceptible to interference

3. **Move away from USB 3.0 sources**
   - USB 3.0 can cause 2.4 GHz interference
   - Keep WiFi adapter away from USB 3.0 devices

4. **Check WiFi Channel Congestion**
   ```bash
   nmcli device wifi list
   ```

5. **Increase TX Power (if allowed)**
   ```bash
   # View current: iwconfig wlan1
   # Set: sudo iw dev wlan1 set txpower fixed 30
   ```

## Expected Results After Fix

**Before:**
```
RX Drops: 432
TX Excessive Retries: 2
Power Management: ON
Packet Loss Rate: ~1-2%
```

**After:**
```
RX Drops: 0 (should stay low)
TX Excessive Retries: 0
Power Management: OFF
Packet Loss Rate: 0% (or near 0)
```

## Test Connection Quality

```bash
# Extended ping test (should have 0% loss)
ping -c 50 8.8.8.8

# Real-time throughput test
iperf3 -c <your-router-ip> -t 30

# Watch live packet stats
watch 'cat /proc/net/wireless'
```

---

**Status:** Ready to apply fixes. Run: `sudo /tmp/fix_wifi_packets.sh`

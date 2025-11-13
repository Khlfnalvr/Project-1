# ⏰ Auto-Shutdown Guide - 3 Hours After Boot

Panduan untuk konfigurasi automatic shutdown Raspberry Pi setelah 3 jam menyala.

## 📋 Overview

Sistem ini menggunakan **systemd timer** untuk shutdown otomatis Raspberry Pi setelah 3 jam (180 menit) dari boot time.

### Timeline:
```
T=0s      : Raspberry Pi boot
T=20s     : YOLO service start
T=0-3h    : YOLO detection running
T=3h      : Automatic shutdown
```

## 🚀 Installation

### Quick Installation (Recommended)

```bash
# 1. Copy files ke Raspberry Pi
scp auto-shutdown.service pi@raspberrypi.local:/home/pi/
scp auto-shutdown.timer pi@raspberrypi.local:/home/pi/
scp install_auto_shutdown.sh pi@raspberrypi.local:/home/pi/

# 2. SSH ke Raspberry Pi
ssh pi@raspberrypi.local

# 3. Run installer
cd /home/pi
chmod +x install_auto_shutdown.sh
./install_auto_shutdown.sh

# 4. Verify installation
systemctl list-timers auto-shutdown.timer
```

### Manual Installation

```bash
# SSH ke Raspberry Pi
ssh pi@raspberrypi.local

# Copy service files to systemd directory
sudo cp auto-shutdown.service /etc/systemd/system/
sudo cp auto-shutdown.timer /etc/systemd/system/

# Set permissions
sudo chmod 644 /etc/systemd/system/auto-shutdown.service
sudo chmod 644 /etc/systemd/system/auto-shutdown.timer

# Reload systemd
sudo systemctl daemon-reload

# Enable and start timer
sudo systemctl enable auto-shutdown.timer
sudo systemctl start auto-shutdown.timer

# Verify
systemctl status auto-shutdown.timer
```

## 📊 Verification

### Check Timer Status

```bash
# Check if timer is active
systemctl status auto-shutdown.timer

# List all timers (see when shutdown will happen)
systemctl list-timers

# Detailed timer information
systemctl show auto-shutdown.timer
```

### Expected Output

```bash
$ systemctl list-timers auto-shutdown.timer

NEXT                         LEFT          LAST PASSED UNIT                  ACTIVATES
Tue 2025-01-13 13:30:00 GMT  2h 59min left n/a  n/a    auto-shutdown.timer   auto-shutdown.service
```

## 🎮 Control Commands

### Start/Stop Timer

```bash
# Start timer (enable shutdown)
sudo systemctl start auto-shutdown.timer

# Stop timer (cancel shutdown for this session)
sudo systemctl stop auto-shutdown.timer

# Restart timer (reset countdown)
sudo systemctl restart auto-shutdown.timer
```

### Enable/Disable Auto-Shutdown

```bash
# Enable auto-shutdown (will activate on every boot)
sudo systemctl enable auto-shutdown.timer

# Disable auto-shutdown (will NOT activate on boot)
sudo systemctl disable auto-shutdown.timer

# Check if enabled
systemctl is-enabled auto-shutdown.timer
```

### Check Remaining Time

```bash
# Show all timers with remaining time
systemctl list-timers

# Show only auto-shutdown timer
systemctl list-timers auto-shutdown.timer
```

## ⚙️ Configuration

### Change Shutdown Time

Edit the timer file to change shutdown delay:

```bash
sudo nano /etc/systemd/system/auto-shutdown.timer
```

Change the `OnBootSec` value:

```ini
[Timer]
OnBootSec=3h    # Change this value
```

**Available time formats:**
- `1h` = 1 hour
- `2h` = 2 hours
- `3h` = 3 hours (default)
- `4h` = 4 hours
- `180m` = 180 minutes (same as 3h)
- `10800s` = 10800 seconds (same as 3h)

After editing, reload and restart:

```bash
sudo systemctl daemon-reload
sudo systemctl restart auto-shutdown.timer
```

### Verify New Configuration

```bash
systemctl list-timers auto-shutdown.timer
```

## 🧪 Testing

### Test Without Waiting 3 Hours

Create a test timer with shorter duration:

```bash
# Create test timer (shutdown after 2 minutes)
sudo nano /etc/systemd/system/auto-shutdown-test.timer
```

Content:
```ini
[Unit]
Description=Test Auto Shutdown - 2 minutes
Requires=auto-shutdown.service

[Timer]
OnBootSec=2m
AccuracySec=1s
Persistent=false

[Install]
WantedBy=timers.target
```

Start test:
```bash
sudo systemctl daemon-reload
sudo systemctl start auto-shutdown-test.timer
systemctl list-timers auto-shutdown-test.timer

# Watch countdown
watch -n 1 'systemctl list-timers auto-shutdown-test.timer'

# Cancel test before it triggers
sudo systemctl stop auto-shutdown-test.timer
```

## 🛡️ Safety Features

### Prevent Accidental Shutdown

If you need to extend working time before shutdown:

```bash
# Option 1: Stop timer (disable shutdown for current session)
sudo systemctl stop auto-shutdown.timer

# Option 2: Restart timer (reset 3-hour countdown)
sudo systemctl restart auto-shutdown.timer

# Option 3: Disable permanently
sudo systemctl disable auto-shutdown.timer
sudo systemctl stop auto-shutdown.timer
```

### Emergency Cancel

If system is about to shutdown and you need to cancel:

```bash
# Immediate cancel
sudo systemctl stop auto-shutdown.timer

# Verify cancelled
systemctl list-timers
```

## 📝 Logs and Monitoring

### View Shutdown Logs

```bash
# View systemd timer logs
sudo journalctl -u auto-shutdown.timer

# View shutdown service logs
sudo journalctl -u auto-shutdown.service

# View last shutdown event
sudo journalctl -u auto-shutdown.service -n 20
```

### Monitor Timer in Real-Time

```bash
# Watch timer countdown (updates every second)
watch -n 1 'systemctl list-timers auto-shutdown.timer'

# Or use tmux/screen for background monitoring
```

### Check System Boot Time

```bash
# Show when system booted (to calculate shutdown time)
uptime -s

# Show system uptime
uptime

# Calculate when shutdown will happen
# Shutdown at: boot_time + 3 hours
```

## 🔧 Troubleshooting

### Timer Not Working

```bash
# Check timer status
systemctl status auto-shutdown.timer

# Check for errors
sudo journalctl -u auto-shutdown.timer -n 50

# Verify timer is loaded
systemctl list-unit-files | grep auto-shutdown

# Reload and restart
sudo systemctl daemon-reload
sudo systemctl restart auto-shutdown.timer
```

### Timer Not Showing in List

```bash
# Enable the timer
sudo systemctl enable auto-shutdown.timer

# Start the timer
sudo systemctl start auto-shutdown.timer

# Verify
systemctl list-timers --all
```

### System Not Shutting Down

```bash
# Check service status
systemctl status auto-shutdown.service

# Test manual shutdown (careful!)
sudo systemctl start auto-shutdown.service
# This will shutdown immediately!

# Check logs
sudo journalctl -u auto-shutdown.service -n 20
```

## 📊 Integration with YOLO Service

Both services work together:

```
Boot Time (T=0)
    ↓
T=20s: YOLO service starts
    ↓
T=0-3h: YOLO running, detecting objects
    ↓
T=3h: Auto-shutdown timer triggers
    ↓
System powers off gracefully
```

### View Both Services

```bash
# Check both YOLO and shutdown status
systemctl status yolo-detection.service auto-shutdown.timer

# List all timers
systemctl list-timers
```

## 🎯 Common Use Cases

### Daily Operation (3 hours per day)

```bash
# Setup once
./install_auto_shutdown.sh

# Every day:
# 1. Power on Raspberry Pi (manual or with timer plug)
# 2. System boots automatically
# 3. YOLO starts at T=20s
# 4. Runs for 3 hours
# 5. Shuts down automatically
# 6. Repeat next day
```

### Extended Operation (disable auto-shutdown)

```bash
# If you need to run longer than 3 hours
ssh pi@raspberrypi.local
sudo systemctl stop auto-shutdown.timer

# Work as long as needed...

# Re-enable for next boot
sudo systemctl enable auto-shutdown.timer
```

### Testing/Development (disable auto-shutdown)

```bash
# Disable during development
sudo systemctl disable auto-shutdown.timer
sudo systemctl stop auto-shutdown.timer

# Development work...

# Re-enable for production
sudo systemctl enable auto-shutdown.timer
sudo systemctl start auto-shutdown.timer
```

## 📅 Scheduled Power-On (Bonus)

Raspberry Pi doesn't have built-in power-on timer, but you can use:

### Option 1: Smart Plug with Timer
- TP-Link Kasa Smart Plug
- Program to turn on at specific time daily
- Raspberry Pi boots when power applied

### Option 2: RTC Wake Alarm (needs RTC module)
```bash
# Example with RTC module
echo 0 > /sys/class/rtc/rtc0/wakealarm
echo $(date '+%s' -d '+ 21 hours') > /sys/class/rtc/rtc0/wakealarm
```

### Option 3: External Timer Relay
- Hardware timer relay
- Set daily schedule
- Cost-effective solution

## ✅ Installation Checklist

- [ ] Files copied to Raspberry Pi
- [ ] Installer executed: `./install_auto_shutdown.sh`
- [ ] Timer status: `systemctl status auto-shutdown.timer` = active
- [ ] Timer enabled: `systemctl is-enabled auto-shutdown.timer` = enabled
- [ ] Timer listed: `systemctl list-timers` shows auto-shutdown.timer
- [ ] Remaining time correct: ~3 hours from boot
- [ ] Test reboot: System boots and timer resets
- [ ] YOLO service still working: `systemctl status yolo-detection`
- [ ] Integration verified: Both services active after boot

## 🎯 Quick Reference

```bash
# Essential Commands
systemctl status auto-shutdown.timer          # Check status
systemctl list-timers                         # Show all timers
sudo systemctl stop auto-shutdown.timer       # Cancel shutdown
sudo systemctl restart auto-shutdown.timer    # Reset countdown
sudo systemctl enable auto-shutdown.timer     # Enable on boot
sudo systemctl disable auto-shutdown.timer    # Disable on boot

# Check remaining time
systemctl list-timers auto-shutdown.timer

# View logs
sudo journalctl -u auto-shutdown.timer -f
```

## ⚠️ Important Notes

1. **Graceful Shutdown**: System shuts down gracefully, saving all data
2. **Power Loss Protection**: Unlike power cut, this is safe shutdown
3. **YOLO Service**: Will be stopped gracefully before shutdown
4. **Network**: TCP connection to ESP2 will be closed properly
5. **Logs**: All logs saved before shutdown

## 📞 Support

If issues occur:
1. Check timer status: `systemctl status auto-shutdown.timer`
2. Check logs: `sudo journalctl -u auto-shutdown.timer`
3. Verify time format in timer file
4. Ensure systemd daemon reloaded: `sudo systemctl daemon-reload`

---
**Default Configuration**: Automatic shutdown 3 hours (180 minutes) after boot.

# 📺 YOLO Detection with Terminal Output (Tmux)

Panduan untuk menjalankan YOLO Detection sebagai service **dengan output visible di terminal window**.

## 🎯 Apa Ini?

Service versi tmux ini akan:
- ✅ Auto-start saat boot (seperti service biasa)
- ✅ Auto-shutdown setelah 3 jam
- ✅ **Output bisa dilihat di terminal window** (attach ke tmux)
- ✅ Persistent walau SSH disconnect
- ✅ Bisa detach/attach kapan saja

## 🔧 Setup

### Step 1: Install Tmux

```bash
ssh pi@raspberrypi.local
sudo apt update
sudo apt install tmux -y
```

### Step 2: Copy Files

```bash
# Copy wrapper script
scp start_yolo_tmux.sh pi@raspberrypi.local:/home/pi/yolo5/

# Copy tmux service file
scp yolo-detection-tmux.service pi@raspberrypi.local:/tmp/
```

### Step 3: Install Service

```bash
ssh pi@raspberrypi.local

# Make wrapper executable
chmod +x /home/pi/yolo5/start_yolo_tmux.sh

# Install service
sudo cp /tmp/yolo-detection-tmux.service /etc/systemd/system/
sudo chmod 644 /etc/systemd/system/yolo-detection-tmux.service
sudo systemctl daemon-reload
sudo systemctl enable yolo-detection-tmux.service
sudo systemctl start yolo-detection-tmux.service
```

## 🖥️ Cara Lihat Output

### Attach ke Terminal Window:

```bash
# SSH ke Raspberry Pi
ssh pi@raspberrypi.local

# Attach ke tmux session
tmux attach -t yolo
```

**Anda akan lihat output real-time:**
```
✅ Connected to ESP2 at 192.168.4.1
✅ Kamera HQ aktif (headless mode).
🚀 Running without GUI window - optimized for performance!
🎲 Random timeout set to 47 seconds
⏱️  Total timeout (delay + random) = 72 seconds
🔍 Detected: person (0.89) | Inference: 234.5ms
🔍 Detected: person (0.87) | Inference: 230.1ms
✅ Sent 'on' via TCP (Object detected: person (0.87)).
🎲 New random timeout set to 63 seconds
⏱️  Total timeout (delay + random) = 88 seconds
```

### Detach dari Terminal (Program Tetap Jalan):

```
Press: Ctrl+B, lalu tekan D
```

Program tetap running di background, Anda bisa disconnect SSH.

### Re-attach Kapan Saja:

```bash
# SSH lagi
ssh pi@raspberrypi.local

# Attach kembali
tmux attach -t yolo
```

## 🎮 Perintah Kontrol

### Service Commands:

```bash
# Start service
sudo systemctl start yolo-detection-tmux

# Stop service
sudo systemctl stop yolo-detection-tmux

# Restart service
sudo systemctl restart yolo-detection-tmux

# Status
sudo systemctl status yolo-detection-tmux

# Enable auto-start
sudo systemctl enable yolo-detection-tmux

# Disable auto-start
sudo systemctl disable yolo-detection-tmux
```

### Tmux Commands:

```bash
# List tmux sessions
tmux ls

# Attach to session
tmux attach -t yolo

# Kill session (stop program)
tmux kill-session -t yolo

# Detach from session (inside tmux)
Ctrl+B, then D
```

## 📊 Tmux Keyboard Shortcuts

Saat sudah attach ke tmux session:

| Shortcut | Function |
|----------|----------|
| `Ctrl+B` then `D` | Detach (program tetap jalan) |
| `Ctrl+B` then `[` | Scroll mode (panah atas/bawah untuk scroll) |
| `q` | Exit scroll mode |
| `Ctrl+C` | **STOP program** (hati-hati!) |

## 🔄 Workflow Harian

### Auto-Start Setiap Boot:

```
1. Raspberry Pi boot
2. Service auto-start (20 detik setelah boot)
3. Program running di tmux session 'yolo'
4. Anda bisa attach kapan saja untuk lihat output
5. Auto-shutdown setelah 3 jam
```

### Monitoring Output:

```bash
# SSH ke Raspberry Pi
ssh pi@raspberrypi.local

# Attach ke tmux
tmux attach -t yolo

# Lihat output real-time
# (scrolling otomatis, seperti terminal biasa)

# Detach jika mau disconnect
Ctrl+B, D

# SSH disconnect (program tetap jalan)
exit
```

## 📋 Comparison: Regular Service vs Tmux Service

| Feature | Regular Service | Tmux Service |
|---------|----------------|--------------|
| **Auto-start** | ✅ | ✅ |
| **Auto-shutdown** | ✅ | ✅ |
| **View output** | journalctl -f | tmux attach |
| **Output format** | With timestamps | Clean terminal |
| **Scrollback** | Full history | Limited by tmux |
| **Multiple viewers** | ✅ Multiple | ⚠️ One at a time |
| **Resource** | Lighter | Slightly heavier |

## 🎯 Rekomendasi

### Gunakan Tmux Service Jika:
- ✅ Anda sering ingin lihat output real-time
- ✅ Anda ingin terminal "clean" (tanpa timestamp journalctl)
- ✅ Anda nyaman dengan tmux shortcuts

### Gunakan Regular Service Jika:
- ✅ Monitoring sesekali saja (jarang)
- ✅ Prefer standard systemd logging
- ✅ Ingin query log dengan waktu (--since, --until)
- ✅ Resource seminimal mungkin

## 🧪 Testing

```bash
# Test manual (tanpa service)
cd /home/pi/yolo5
./start_yolo_tmux.sh

# Check tmux session created
tmux ls
# Output: yolo: 1 windows (created ...)

# Attach
tmux attach -t yolo

# Verify output tampil
# Detach
Ctrl+B, D

# Test service
sudo systemctl start yolo-detection-tmux
tmux attach -t yolo
```

## 🔍 Troubleshooting

### Tmux session tidak ada:

```bash
# Check service status
sudo systemctl status yolo-detection-tmux

# Check logs
sudo journalctl -u yolo-detection-tmux -n 50

# Restart service
sudo systemctl restart yolo-detection-tmux
```

### Tidak bisa attach:

```bash
# List all sessions
tmux ls

# If session exists tapi stuck
tmux kill-session -t yolo
sudo systemctl restart yolo-detection-tmux
```

### "sessions should be nested with care" error:

```bash
# You're already inside tmux, detach first
Ctrl+B, D

# Then attach again
tmux attach -t yolo
```

## ⚙️ Migration

### Dari Regular Service ke Tmux Service:

```bash
# 1. Stop old service
sudo systemctl stop yolo-detection
sudo systemctl disable yolo-detection

# 2. Enable tmux service
sudo systemctl enable yolo-detection-tmux
sudo systemctl start yolo-detection-tmux

# 3. Verify
tmux attach -t yolo
```

### Dari Tmux Service ke Regular Service:

```bash
# 1. Stop tmux service
sudo systemctl stop yolo-detection-tmux
sudo systemctl disable yolo-detection-tmux

# 2. Enable regular service
sudo systemctl enable yolo-detection
sudo systemctl start yolo-detection

# 3. Monitor dengan journalctl
sudo journalctl -u yolo-detection -f
```

## 📝 Notes

- Tmux session name: `yolo` (fixed)
- Program tetap running walau tidak ada yang attach
- Detach tidak stop program
- Multiple attach bisa tapi semua lihat output yang sama
- Auto-shutdown 3 jam tetap berlaku

---

**TL;DR:** Service dengan tmux = Auto-start + Lihat output di terminal window!

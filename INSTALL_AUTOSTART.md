# 🚀 Auto-Start Installation Guide untuk YOLO Detection

Panduan ini akan membuat YOLO Detection script berjalan otomatis 20 detik setelah Raspberry Pi boot.

## 📋 Prerequisites

Pastikan file-file berikut sudah ada:
- `/home/pi/yolo5/start_yolo.sh` - Startup script
- `/home/pi/yolo5/yolo.py` atau `yolo_picamera_tcp_detection_headless.py` - Program YOLO
- `/home/pi/yolo5/best.pt` - Model YOLO

## 🔧 Langkah-Langkah Instalasi

### Step 1: Copy File ke Raspberry Pi

Dari komputer development, copy file ke Raspberry Pi:

```bash
# Copy startup script
scp start_yolo.sh pi@raspberrypi.local:/home/pi/yolo5/

# Copy service file
scp yolo-detection.service pi@raspberrypi.local:/tmp/

# Copy Python script (pilih salah satu)
scp yolo_picamera_tcp_detection_headless.py pi@raspberrypi.local:/home/pi/yolo5/yolo.py
# atau
scp yolo_picamera_tcp_detection.py pi@raspberrypi.local:/home/pi/yolo5/yolo.py
```

### Step 2: Setup di Raspberry Pi

SSH ke Raspberry Pi:

```bash
ssh pi@raspberrypi.local
```

Jalankan perintah berikut:

```bash
# 1. Buat executable startup script
cd /home/pi/yolo5
chmod +x start_yolo.sh

# 2. Test manual dulu (PENTING!)
./start_yolo.sh
# Tekan Ctrl+C untuk stop setelah yakin jalan

# 3. Copy service file ke systemd
sudo cp /tmp/yolo-detection.service /etc/systemd/system/

# 4. Set permission yang benar
sudo chmod 644 /etc/systemd/system/yolo-detection.service

# 5. Reload systemd daemon
sudo systemctl daemon-reload

# 6. Enable service (auto-start on boot)
sudo systemctl enable yolo-detection.service

# 7. Start service sekarang (untuk test)
sudo systemctl start yolo-detection.service

# 8. Check status
sudo systemctl status yolo-detection.service
```

### Step 3: Verifikasi Installation

```bash
# Check apakah service enabled
systemctl is-enabled yolo-detection.service
# Output: enabled

# Check status service
sudo systemctl status yolo-detection.service
# Output harus: active (running)

# Lihat log real-time
tail -f /home/pi/yolo_service.log

# Atau pakai journalctl
sudo journalctl -u yolo-detection.service -f
```

## 🎮 Perintah Kontrol Service

### Start/Stop/Restart Service

```bash
# Start service
sudo systemctl start yolo-detection.service

# Stop service
sudo systemctl stop yolo-detection.service

# Restart service
sudo systemctl restart yolo-detection.service

# Check status
sudo systemctl status yolo-detection.service
```

### Enable/Disable Auto-Start

```bash
# Enable auto-start on boot
sudo systemctl enable yolo-detection.service

# Disable auto-start on boot
sudo systemctl disable yolo-detection.service
```

### Lihat Logs

```bash
# Log dari systemd
sudo journalctl -u yolo-detection.service

# Log 100 baris terakhir
sudo journalctl -u yolo-detection.service -n 100

# Follow log real-time
sudo journalctl -u yolo-detection.service -f

# Log dari file
tail -f /home/pi/yolo_service.log

# Log hari ini saja
sudo journalctl -u yolo-detection.service --since today
```

## 🔍 Troubleshooting

### Service Gagal Start

```bash
# Check error detail
sudo systemctl status yolo-detection.service -l

# Check log
sudo journalctl -u yolo-detection.service -n 50 --no-pager
```

### Penyebab Umum Error:

1. **Path salah** - Pastikan path di `start_yolo.sh` benar:
   ```bash
   cd /home/pi/yolo5 || exit
   ```

2. **Permission denied** - Fix dengan:
   ```bash
   chmod +x /home/pi/yolo5/start_yolo.sh
   chmod +r /home/pi/yolo5/best.pt
   ```

3. **Virtual environment tidak ada**:
   ```bash
   cd /home/pi/yolo5
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```

4. **WiFi tidak connect** - Check WiFi credentials di `start_yolo.sh`:
   ```bash
   WIFI_SSID="ESP32_AP"
   WIFI_PASSWORD="12345678"
   ```

### Test Manual Tanpa Service

```bash
# Stop service dulu
sudo systemctl stop yolo-detection.service

# Jalankan manual
cd /home/pi/yolo5
./start_yolo.sh
```

## ⚙️ Konfigurasi Lanjutan

### Ubah Delay Boot

Edit file service:

```bash
sudo nano /etc/systemd/system/yolo-detection.service
```

Ubah baris:
```ini
ExecStartPre=/bin/sleep 20    # Ubah 20 ke nilai lain (detik)
```

Reload dan restart:
```bash
sudo systemctl daemon-reload
sudo systemctl restart yolo-detection.service
```

### Ubah Resource Limits

Edit section `[Service]` di file service:

```ini
MemoryLimit=1G      # Limit RAM (1GB)
CPUQuota=90%        # Limit CPU (90%)
```

### Auto-Restart jika Crash

Sudah dikonfigurasi default:
```ini
Restart=on-failure  # Restart otomatis jika crash
RestartSec=10       # Tunggu 10 detik sebelum restart
```

## 🧪 Test Auto-Start

Untuk test apakah auto-start bekerja:

```bash
# Reboot Raspberry Pi
sudo reboot

# Setelah boot (tunggu ~30 detik), check status
sudo systemctl status yolo-detection.service

# Atau lihat log
tail -f /home/pi/yolo_service.log
```

## 📊 Monitoring

### Check Service Health

```bash
# Status singkat
systemctl is-active yolo-detection.service

# Status detail
sudo systemctl status yolo-detection.service
```

### Monitor Resource Usage

```bash
# CPU dan Memory usage
top -p $(pgrep -f yolo.py)

# Atau pakai htop
sudo apt install htop
htop
```

### Log Rotation (Agar log tidak terlalu besar)

Create log rotation config:

```bash
sudo nano /etc/logrotate.d/yolo-detection
```

Isi dengan:
```
/home/pi/yolo_service.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
    create 644 pi pi
}
```

## ✅ Checklist Installation

- [ ] File `start_yolo.sh` sudah di `/home/pi/yolo5/`
- [ ] File `start_yolo.sh` executable (`chmod +x`)
- [ ] Program Python (`yolo.py`) ada di `/home/pi/yolo5/`
- [ ] Model YOLO (`best.pt`) ada di `/home/pi/yolo5/`
- [ ] Virtual environment setup di `/home/pi/yolo5/venv/`
- [ ] Service file copied ke `/etc/systemd/system/`
- [ ] Service enabled (`systemctl enable`)
- [ ] Service running (`systemctl status` = active)
- [ ] Test manual `./start_yolo.sh` berhasil
- [ ] Test reboot dan auto-start berhasil
- [ ] WiFi auto-connect ke ESP32_AP berhasil
- [ ] TCP connection ke ESP2 (192.168.4.1) berhasil

## 🎯 Quick Reference

```bash
# Essential Commands
sudo systemctl start yolo-detection      # Start
sudo systemctl stop yolo-detection       # Stop
sudo systemctl restart yolo-detection    # Restart
sudo systemctl status yolo-detection     # Status
sudo systemctl enable yolo-detection     # Enable auto-start
sudo systemctl disable yolo-detection    # Disable auto-start
tail -f /home/pi/yolo_service.log       # View log

# Reboot untuk test auto-start
sudo reboot
```

## 📞 Support

Jika ada masalah, check:
1. Service status: `sudo systemctl status yolo-detection.service`
2. Log file: `tail -f /home/pi/yolo_service.log`
3. Journal log: `sudo journalctl -u yolo-detection.service -n 100`
4. Test manual: `./start_yolo.sh`

---
**Note**: Service akan start 20 detik setelah boot untuk memastikan network sudah ready.

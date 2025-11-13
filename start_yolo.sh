#!/bin/bash

echo "================================================"
echo "🚀 YOLO Startup Script"
echo "================================================"

# Kill existing processes
echo "🛑 Stopping existing processes..."
sudo pkill -9 python3
sudo pkill -9 libcamera
sleep 2

# WiFi Configuration
WIFI_SSID="ESP32_AP"
WIFI_PASSWORD="12345678"
MAX_WIFI_RETRY=5
WIFI_RETRY_COUNT=0

# Function to check WiFi connection
check_wifi() {
    # Check if connected to the correct WiFi
    CURRENT_SSID=$(iwgetid -r)
    if [ "$CURRENT_SSID" == "$WIFI_SSID" ]; then
        echo "✅ Already connected to $WIFI_SSID"
        return 0
    else
        echo "❌ Not connected to $WIFI_SSID (current: $CURRENT_SSID)"
        return 1
    fi
}

# Function to connect to WiFi
connect_wifi() {
    echo "📡 Connecting to WiFi: $WIFI_SSID"

    # Try using nmcli (NetworkManager) first
    if command -v nmcli &> /dev/null; then
        echo "Using nmcli to connect..."

        # Check if connection already exists
        if nmcli connection show "$WIFI_SSID" &> /dev/null; then
            # Connection exists, just bring it up
            sudo nmcli connection up "$WIFI_SSID"
        else
            # Create new connection
            sudo nmcli device wifi connect "$WIFI_SSID" password "$WIFI_PASSWORD"
        fi

        sleep 3

        if check_wifi; then
            return 0
        else
            return 1
        fi

    # Fallback to wpa_cli method
    elif command -v wpa_cli &> /dev/null; then
        echo "Using wpa_cli to connect..."

        # Add network and configure
        NETWORK_ID=$(wpa_cli -i wlan0 add_network | tail -n 1)
        wpa_cli -i wlan0 set_network $NETWORK_ID ssid "\"$WIFI_SSID\""
        wpa_cli -i wlan0 set_network $NETWORK_ID psk "\"$WIFI_PASSWORD\""
        wpa_cli -i wlan0 enable_network $NETWORK_ID
        wpa_cli -i wlan0 save_config

        sleep 5

        if check_wifi; then
            return 0
        else
            return 1
        fi

    else
        echo "⚠️  Neither nmcli nor wpa_cli found. Please install network-manager."
        return 1
    fi
}

# WiFi connection with retry
echo ""
echo "📡 Checking WiFi connection..."
if ! check_wifi; then
    while [ $WIFI_RETRY_COUNT -lt $MAX_WIFI_RETRY ]; do
        WIFI_RETRY_COUNT=$((WIFI_RETRY_COUNT + 1))
        echo "🔄 WiFi connection attempt $WIFI_RETRY_COUNT of $MAX_WIFI_RETRY"

        if connect_wifi; then
            echo "✅ WiFi connected successfully!"
            break
        else
            if [ $WIFI_RETRY_COUNT -lt $MAX_WIFI_RETRY ]; then
                echo "⏳ Waiting 5 seconds before retry..."
                sleep 5
            else
                echo "❌ Failed to connect to WiFi after $MAX_WIFI_RETRY attempts"
                echo "⚠️  Continuing anyway (program may fail without network)..."
            fi
        fi
    done
else
    echo "✅ WiFi already connected"
fi

# Wait for network to stabilize
echo "⏳ Waiting for network to stabilize..."
sleep 3

# Test ESP2 connectivity
ESP2_IP="192.168.4.1"
echo ""
echo "🔍 Testing connection to ESP2 at $ESP2_IP..."
if ping -c 2 -W 2 $ESP2_IP &> /dev/null; then
    echo "✅ ESP2 is reachable"
else
    echo "⚠️  Warning: Cannot reach ESP2 at $ESP2_IP"
    echo "   Program may fail to send TCP messages"
fi

# Navigate to project directory
echo ""
echo "📂 Navigating to project directory..."
cd /home/pi/yolo5 || {
    echo "❌ Error: Directory /home/pi/yolo5 not found"
    exit 1
}

# Activate virtual environment
echo "🐍 Activating virtual environment..."
if [ -d "venv" ]; then
    source venv/bin/activate
    echo "✅ Virtual environment activated"
else
    echo "⚠️  Warning: venv directory not found, continuing without venv..."
fi

# Run the Python program with retry
echo ""
echo "================================================"
echo "🎯 Starting YOLO Detection Program"
echo "================================================"
echo ""

RETRY_COUNT=0
MAX_RETRIES=10

while true; do
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "🔄 Attempt #$RETRY_COUNT"
    echo "⏰ Started at: $(date '+%Y-%m-%d %H:%M:%S')"

    # Run the program
    python yolo.py
    EXIT_CODE=$?

    # Check exit code
    if [ $EXIT_CODE -eq 0 ]; then
        echo "✅ Program exited normally (exit code: 0)"
        echo "🏁 Script finished at: $(date '+%Y-%m-%d %H:%M:%S')"
        break
    else
        echo "❌ Program failed with exit code: $EXIT_CODE"

        if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
            echo "🛑 Maximum retries ($MAX_RETRIES) reached. Stopping."
            exit 1
        fi

        echo "⏳ Waiting 5 seconds before retry..."
        sleep 5

        # Re-check WiFi connection before retry
        if ! check_wifi; then
            echo "📡 WiFi disconnected, attempting to reconnect..."
            connect_wifi
        fi
    fi
done

echo ""
echo "================================================"
echo "✅ Script execution completed"
echo "================================================"

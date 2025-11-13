#!/bin/bash

echo "================================================"
echo "⏰ Auto-Shutdown Installer (3 hours after boot)"
echo "================================================"
echo ""

# Configuration
SERVICE_FILE="auto-shutdown.service"
TIMER_FILE="auto-shutdown.timer"
SHUTDOWN_AFTER="3 hours"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "ℹ️  $1"
}

echo "⚠️  WARNING: This will configure automatic shutdown"
echo "   Raspberry Pi will shutdown automatically $SHUTDOWN_AFTER after boot"
echo ""
read -p "Do you want to continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Installation cancelled"
    exit 0
fi

echo ""
echo "📋 Pre-Installation Checks"
echo "----------------------------"

# Check if service files exist
if [ ! -f "$SERVICE_FILE" ]; then
    print_error "Service file not found: $SERVICE_FILE"
    exit 1
else
    print_success "Service file found"
fi

if [ ! -f "$TIMER_FILE" ]; then
    print_error "Timer file not found: $TIMER_FILE"
    exit 1
else
    print_success "Timer file found"
fi

echo ""
echo "📦 Installation Steps"
echo "----------------------------"

# Step 1: Copy service file
echo "1️⃣  Installing shutdown service..."
sudo cp "$SERVICE_FILE" /etc/systemd/system/
if [ $? -eq 0 ]; then
    print_success "Service file copied"
else
    print_error "Failed to copy service file"
    exit 1
fi

# Step 2: Copy timer file
echo ""
echo "2️⃣  Installing shutdown timer..."
sudo cp "$TIMER_FILE" /etc/systemd/system/
if [ $? -eq 0 ]; then
    print_success "Timer file copied"
else
    print_error "Failed to copy timer file"
    exit 1
fi

# Step 3: Set permissions
echo ""
echo "3️⃣  Setting permissions..."
sudo chmod 644 /etc/systemd/system/$SERVICE_FILE
sudo chmod 644 /etc/systemd/system/$TIMER_FILE
print_success "Permissions set"

# Step 4: Reload systemd
echo ""
echo "4️⃣  Reloading systemd daemon..."
sudo systemctl daemon-reload
if [ $? -eq 0 ]; then
    print_success "Systemd daemon reloaded"
else
    print_error "Failed to reload systemd daemon"
    exit 1
fi

# Step 5: Enable timer
echo ""
echo "5️⃣  Enabling auto-shutdown timer..."
sudo systemctl enable auto-shutdown.timer
if [ $? -eq 0 ]; then
    print_success "Auto-shutdown timer enabled"
else
    print_error "Failed to enable timer"
    exit 1
fi

# Step 6: Start timer
echo ""
echo "6️⃣  Starting timer..."
sudo systemctl start auto-shutdown.timer
if [ $? -eq 0 ]; then
    print_success "Timer started"
else
    print_error "Failed to start timer"
    exit 1
fi

# Installation complete
echo ""
echo "================================================"
echo "✅ Installation Complete!"
echo "================================================"
echo ""
echo "⏰ Auto-Shutdown Configuration:"
echo "   Shutdown after: $SHUTDOWN_AFTER from boot"
echo "   Status: $(systemctl is-enabled auto-shutdown.timer)"
echo "   Active: $(systemctl is-active auto-shutdown.timer)"
echo ""

# Show next trigger time
echo "📅 Next Shutdown Time:"
systemctl list-timers auto-shutdown.timer --no-pager
echo ""

# Show remaining time
REMAINING=$(systemctl show auto-shutdown.timer --property=NextElapseUSecRealtime --value)
if [ ! -z "$REMAINING" ] && [ "$REMAINING" != "0" ]; then
    print_success "Timer is active and scheduled"
else
    print_warning "Timer may not be properly scheduled"
fi

echo ""
echo "📝 Useful Commands:"
echo "   systemctl status auto-shutdown.timer     # Check timer status"
echo "   systemctl list-timers                    # List all timers"
echo "   sudo systemctl stop auto-shutdown.timer  # Cancel shutdown (temporary)"
echo "   sudo systemctl disable auto-shutdown.timer  # Disable auto-shutdown"
echo ""
echo "🎯 Testing:"
echo "   1. Reboot to test: sudo reboot"
echo "   2. After reboot, check timer: systemctl list-timers"
echo "   3. System will shutdown automatically after 3 hours"
echo ""
echo "⚠️  To DISABLE auto-shutdown:"
echo "   sudo systemctl stop auto-shutdown.timer"
echo "   sudo systemctl disable auto-shutdown.timer"
echo ""
echo "================================================"

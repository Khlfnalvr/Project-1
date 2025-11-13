#!/bin/bash

echo "================================================"
echo "🚀 YOLO Detection Auto-Start Installer"
echo "================================================"
echo ""

# Configuration
INSTALL_DIR="/home/pi/yolo5"
SERVICE_NAME="yolo-detection"
SERVICE_FILE="${SERVICE_NAME}.service"
STARTUP_SCRIPT="start_yolo.sh"
LOG_FILE="/home/pi/yolo_service.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
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

# Check if running as pi user
if [ "$USER" != "pi" ]; then
    print_warning "This script should be run as user 'pi'"
    print_info "Current user: $USER"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "📋 Pre-Installation Checks"
echo "----------------------------"

# Check if install directory exists
if [ ! -d "$INSTALL_DIR" ]; then
    print_error "Directory $INSTALL_DIR not found!"
    read -p "Create directory? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        mkdir -p "$INSTALL_DIR"
        print_success "Directory created: $INSTALL_DIR"
    else
        print_error "Installation cancelled"
        exit 1
    fi
else
    print_success "Install directory exists: $INSTALL_DIR"
fi

# Check if startup script exists
if [ ! -f "$INSTALL_DIR/$STARTUP_SCRIPT" ]; then
    print_error "Startup script not found: $INSTALL_DIR/$STARTUP_SCRIPT"
    print_info "Please copy $STARTUP_SCRIPT to $INSTALL_DIR first"
    exit 1
else
    print_success "Startup script found"
fi

# Check if service file exists in current directory
if [ ! -f "$SERVICE_FILE" ]; then
    print_error "Service file not found: $SERVICE_FILE"
    print_info "Please make sure $SERVICE_FILE is in current directory"
    exit 1
else
    print_success "Service file found"
fi

echo ""
echo "📦 Installation Steps"
echo "----------------------------"

# Step 1: Make startup script executable
echo "1️⃣  Making startup script executable..."
chmod +x "$INSTALL_DIR/$STARTUP_SCRIPT"
if [ $? -eq 0 ]; then
    print_success "Startup script is now executable"
else
    print_error "Failed to make startup script executable"
    exit 1
fi

# Step 2: Copy service file to systemd
echo ""
echo "2️⃣  Installing systemd service..."
sudo cp "$SERVICE_FILE" /etc/systemd/system/
if [ $? -eq 0 ]; then
    print_success "Service file copied to /etc/systemd/system/"
else
    print_error "Failed to copy service file"
    exit 1
fi

# Step 3: Set correct permissions
echo ""
echo "3️⃣  Setting permissions..."
sudo chmod 644 /etc/systemd/system/$SERVICE_FILE
if [ $? -eq 0 ]; then
    print_success "Service file permissions set"
else
    print_error "Failed to set permissions"
    exit 1
fi

# Step 4: Reload systemd daemon
echo ""
echo "4️⃣  Reloading systemd daemon..."
sudo systemctl daemon-reload
if [ $? -eq 0 ]; then
    print_success "Systemd daemon reloaded"
else
    print_error "Failed to reload systemd daemon"
    exit 1
fi

# Step 5: Enable service
echo ""
echo "5️⃣  Enabling auto-start on boot..."
sudo systemctl enable $SERVICE_NAME.service
if [ $? -eq 0 ]; then
    print_success "Service enabled for auto-start"
else
    print_error "Failed to enable service"
    exit 1
fi

# Step 6: Ask if user wants to start now
echo ""
read -p "🚀 Start service now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "6️⃣  Starting service..."
    sudo systemctl start $SERVICE_NAME.service
    sleep 2

    # Check status
    if sudo systemctl is-active --quiet $SERVICE_NAME.service; then
        print_success "Service started successfully!"
    else
        print_error "Service failed to start"
        echo ""
        echo "Checking status..."
        sudo systemctl status $SERVICE_NAME.service --no-pager -l
        exit 1
    fi
else
    print_info "Service not started. You can start it manually with:"
    echo "   sudo systemctl start $SERVICE_NAME.service"
fi

# Installation complete
echo ""
echo "================================================"
echo "✅ Installation Complete!"
echo "================================================"
echo ""
echo "📊 Service Information:"
echo "   Name: $SERVICE_NAME"
echo "   Status: $(systemctl is-enabled $SERVICE_NAME.service)"
echo "   Active: $(systemctl is-active $SERVICE_NAME.service)"
echo ""
echo "📝 Useful Commands:"
echo "   sudo systemctl status $SERVICE_NAME    # Check status"
echo "   sudo systemctl start $SERVICE_NAME     # Start service"
echo "   sudo systemctl stop $SERVICE_NAME      # Stop service"
echo "   sudo systemctl restart $SERVICE_NAME   # Restart service"
echo "   tail -f $LOG_FILE                      # View logs"
echo "   sudo journalctl -u $SERVICE_NAME -f    # View journal logs"
echo ""
echo "🎯 Next Steps:"
echo "   1. Check service status:"
echo "      sudo systemctl status $SERVICE_NAME"
echo ""
echo "   2. View logs:"
echo "      tail -f $LOG_FILE"
echo ""
echo "   3. Test auto-start by rebooting:"
echo "      sudo reboot"
echo ""
echo "   4. After reboot, check if service is running:"
echo "      sudo systemctl status $SERVICE_NAME"
echo ""
echo "================================================"

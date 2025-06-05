#!/bin/bash

# JLBMaritime-AIS Captive Portal Installation Script
# This script prepares and installs the captive portal solution to the appropriate directories
# Run this script on the Raspberry Pi as the JLBMaritime user

set -e  # Exit on error

BASEDIR=$(dirname "$0")
LOG_FILE="$BASEDIR/install.log"

# GitHub repository URL
GITHUB_REPO="https://github.com/jlbmaritime/ais-captive-portal.git"

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "Starting JLBMaritime-AIS Captive Portal installation"

# Check if running as JLBMaritime user
if [ "$(whoami)" != "JLBMaritime" ]; then
    log "This script should be run as the JLBMaritime user" >&2
    log "Please run: sudo -u JLBMaritime ./install.sh" >&2
    exit 1
fi

# Create project directory
log "Creating project directory"
mkdir -p /home/JLBMaritime/captive-portal/
PROJECT_DIR="/home/JLBMaritime/captive-portal"

# Check if we're installing from GitHub or local files
if [ "$1" = "--from-github" ]; then
    # Install git if not already installed
    if ! command -v git &> /dev/null; then
        log "Git not found. Installing git..."
        sudo apt-get update
        sudo apt-get install -y git
    fi
    
    log "Cloning repository from GitHub"
    # Clone to a temporary directory first
    TEMP_DIR=$(mktemp -d)
    git clone "$GITHUB_REPO" "$TEMP_DIR"
    
    # Copy files from the temporary directory
    cp -r "$TEMP_DIR/etc" "$PROJECT_DIR/"
    cp -r "$TEMP_DIR/usr" "$PROJECT_DIR/"
    cp -r "$TEMP_DIR/var" "$PROJECT_DIR/"
    
    # Cleanup
    rm -rf "$TEMP_DIR"
else
    # Copy all files from the local directory to the project directory
    log "Copying files from local directory"
    cp -r "$BASEDIR/etc" "$PROJECT_DIR/"
    cp -r "$BASEDIR/usr" "$PROJECT_DIR/"
    cp -r "$BASEDIR/var" "$PROJECT_DIR/"
fi

# Create placeholder for company logo if it doesn't exist
if [ ! -f "$PROJECT_DIR/var/www/portal/logo.png" ]; then
    log "Creating placeholder logo file"
    touch "$PROJECT_DIR/var/www/portal/logo.png"
    echo "<!-- Replace this file with your company logo -->" > "$PROJECT_DIR/var/www/portal/logo.png"
fi

# Set permissions
log "Setting permissions"
chmod +x "$PROJECT_DIR/usr/local/bin/setup_ap.sh"
chmod +x "$PROJECT_DIR/usr/local/bin/wifi_portal.py"

# Create installation summary file
cat > "$PROJECT_DIR/README.txt" <<EOF
JLBMaritime-AIS Captive Portal Solution
=======================================

Installation completed on: $(date)

Files installed in: $PROJECT_DIR

To complete the installation, run the following command as root:
    sudo cp $PROJECT_DIR/etc/systemd/system/captive-portal.service /etc/systemd/system/
    sudo systemctl enable captive-portal.service
    sudo systemctl start captive-portal.service

After running these commands, the Raspberry Pi will:
1. Create an access point with SSID "JLBMaritime-AIS" and password "Admin"
2. Provide a captive portal at http://192.168.4.1
3. Allow customers to input their WiFi credentials
4. Connect to the customer's WiFi network
5. Automatically reconnect to the known WiFi network after power loss
6. Reactivate the captive portal if the WiFi connection is lost

For customization:
- Replace the logo image at $PROJECT_DIR/var/www/portal/logo.png with your company logo
- Edit the web page at $PROJECT_DIR/var/www/portal/index.html if needed

For troubleshooting, check the following log files:
- /var/log/setup_ap.log - Setup script logs
- /var/log/wifi_portal.log - WiFi portal service logs
- /var/log/wifi_monitor.log - Connection monitoring logs
EOF

log "Creating final installation script"
cat > "$BASEDIR/complete_installation.sh" <<EOF
#!/bin/bash

# Final installation script for JLBMaritime-AIS Captive Portal
# This script must be run as root

if [ "\$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

echo "Completing JLBMaritime-AIS Captive Portal installation..."

# Copy service file and enable it
cp $PROJECT_DIR/etc/systemd/system/captive-portal.service /etc/systemd/system/
systemctl enable captive-portal.service
systemctl start captive-portal.service

echo "Installation completed!"
echo "The Raspberry Pi will now function as a captive portal with SSID: JLBMaritime-AIS"
echo "Customers can connect to this network with password: Admin"
echo "After connecting, they will be redirected to a portal to configure their WiFi settings"

exit 0
EOF

chmod +x "$BASEDIR/complete_installation.sh"

log "Installation preparation completed!"
log "To complete the installation, please run: sudo $BASEDIR/complete_installation.sh"

exit 0

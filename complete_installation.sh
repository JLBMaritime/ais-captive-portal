#!/bin/bash

# Final installation script for JLBMaritime-AIS Captive Portal
# This script must be run as root

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

echo "Completing JLBMaritime-AIS Captive Portal installation..."

PROJECT_DIR="/home/JLBMaritime/captive-portal"

# Copy service file and enable it
cp $PROJECT_DIR/etc/systemd/system/captive-portal.service /etc/systemd/system/
systemctl enable captive-portal.service
systemctl start captive-portal.service

echo "Installation completed!"
echo "The Raspberry Pi will now function as a captive portal with SSID: JLBMaritime-AIS"
echo "Customers can connect to this network with password: Admin"
echo "After connecting, they will be redirected to a portal to configure their WiFi settings"

exit 0

#!/bin/bash

# Final installation script for JLBMaritime-AIS Captive Portal
# This script must be run as root

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

echo "Completing JLBMaritime-AIS Captive Portal installation..."

PROJECT_DIR="/home/JLBMaritime/captive-portal"

# Create necessary system directories
mkdir -p /usr/local/bin
mkdir -p /etc/hostapd
mkdir -p /etc/dnsmasq.d
mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
mkdir -p /var/www/portal

# Copy scripts to system locations
echo "Copying scripts to system locations..."
cp $PROJECT_DIR/usr/local/bin/setup_ap.sh /usr/local/bin/
cp $PROJECT_DIR/usr/local/bin/wifi_portal.py /usr/local/bin/
chmod +x /usr/local/bin/setup_ap.sh
chmod +x /usr/local/bin/wifi_portal.py

# Copy configuration files
echo "Copying configuration files..."
cp $PROJECT_DIR/etc/hostapd/hostapd.conf /etc/hostapd/
cp $PROJECT_DIR/etc/dnsmasq.d/captive-portal.conf /etc/dnsmasq.d/
cp $PROJECT_DIR/etc/nginx/sites-available/captive-portal /etc/nginx/sites-available/
ln -sf /etc/nginx/sites-available/captive-portal /etc/nginx/sites-enabled/default

# Copy web portal files
echo "Copying web portal files..."
cp -r $PROJECT_DIR/var/www/portal/* /var/www/portal/
chown -R www-data:www-data /var/www/portal

# Copy service file and enable it
echo "Setting up systemd service..."
cp $PROJECT_DIR/etc/systemd/system/captive-portal.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable captive-portal.service
systemctl start captive-portal.service

echo "Installation completed!"
echo "The Raspberry Pi will now function as a captive portal with SSID: JLBMaritime-AIS"
echo "Customers can connect to this network with password: Admin"
echo "After connecting, they will be redirected to a portal to configure their WiFi settings"

exit 0

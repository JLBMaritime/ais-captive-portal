#!/bin/bash

# Script to configure the Raspberry Pi as an access point
# This script should be run with root privileges

set -e  # Exit on error
LOG_FILE="/var/log/setup_ap.log"

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

log "Starting access point setup"

# Install required packages if not already installed
log "Installing required packages"
apt-get update
apt-get install -y hostapd dnsmasq nginx python3-flask

# Stop services during configuration
log "Stopping services for configuration"
systemctl stop hostapd
systemctl stop dnsmasq
systemctl stop wpa_supplicant

# Configure network interfaces
log "Configuring network interfaces"
cat > /etc/network/interfaces.d/ap <<EOF
# Access point interface configuration
allow-hotplug wlan0
iface wlan0 inet static
    address 192.168.4.1
    netmask 255.255.255.0
EOF

# Configure hostapd
log "Configuring hostapd"
cat > /etc/default/hostapd <<EOF
# Default settings for hostapd
DAEMON_CONF="/etc/hostapd/hostapd.conf"
EOF

# Copy the hostapd.conf file from our project directory
cp -f /home/JLBMaritime/captive-portal/etc/hostapd/hostapd.conf /etc/hostapd/
chmod 600 /etc/hostapd/hostapd.conf

# Configure dnsmasq
log "Configuring dnsmasq"
cp -f /home/JLBMaritime/captive-portal/etc/dnsmasq.d/captive-portal.conf /etc/dnsmasq.d/
chmod 644 /etc/dnsmasq.d/captive-portal.conf

# Configure nginx
log "Configuring nginx"
cp -f /home/JLBMaritime/captive-portal/etc/nginx/sites-available/captive-portal /etc/nginx/sites-available/
ln -sf /etc/nginx/sites-available/captive-portal /etc/nginx/sites-enabled/default

# Create web directory and copy files
log "Setting up web portal files"
mkdir -p /var/www/portal
cp -rf /home/JLBMaritime/captive-portal/var/www/portal/* /var/www/portal/
chown -R www-data:www-data /var/www/portal

# Configure and enable services
log "Enabling services"
systemctl unmask hostapd
systemctl enable hostapd
systemctl enable dnsmasq
systemctl enable nginx

# Set up IP forwarding for internet access if connected
log "Configuring IP forwarding"
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/90-ip-forward.conf
sysctl -p /etc/sysctl.d/90-ip-forward.conf

# Set up NAT
log "Configuring NAT"
cat > /etc/iptables-ap-rules <<EOF
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -o eth0 -j MASQUERADE
COMMIT
EOF

# Create service to load iptables rules
cat > /etc/systemd/system/iptables-ap.service <<EOF
[Unit]
Description=Restore iptables rules for AP mode
After=network.target

[Service]
Type=oneshot
ExecStart=/sbin/iptables-restore /etc/iptables-ap-rules
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl enable iptables-ap.service

# Copy the WiFi portal script and make it executable
log "Setting up WiFi portal service"
cp -f /home/JLBMaritime/captive-portal/usr/local/bin/wifi_portal.py /usr/local/bin/
chmod +x /usr/local/bin/wifi_portal.py

# Create systemd service for WiFi portal
cat > /etc/systemd/system/wifi-portal.service <<EOF
[Unit]
Description=WiFi Portal Service
After=network.target

[Service]
ExecStart=/usr/bin/python3 /usr/local/bin/wifi_portal.py
Restart=always
User=root
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

systemctl enable wifi-portal.service

# Create service to monitor WiFi connection
log "Setting up connection monitoring service"
cat > /usr/local/bin/monitor_connection.sh <<EOF
#!/bin/bash

# Monitor WiFi connection and reactivate AP if connection is lost
LOG_FILE="/var/log/wifi_monitor.log"

log() {
    echo "\$(date '+%Y-%m-%d %H:%M:%S') - \$1" >> "\$LOG_FILE"
}

while true; do
    # Check if connected to a WiFi network
    if ! wpa_cli -i wlan0 status | grep -q 'wpa_state=COMPLETED'; then
        log "WiFi connection not detected, reactivating access point"
        
        # Stop wpa_supplicant
        systemctl stop wpa_supplicant
        
        # Configure static IP for AP mode
        ip addr flush dev wlan0
        ip addr add 192.168.4.1/24 dev wlan0
        
        # Start AP services
        systemctl restart hostapd
        systemctl restart dnsmasq
    fi
    
    # Sleep for 60 seconds before checking again
    sleep 60
done
EOF

chmod +x /usr/local/bin/monitor_connection.sh

# Create systemd service for connection monitoring
cat > /etc/systemd/system/wifi-monitor.service <<EOF
[Unit]
Description=WiFi Connection Monitor Service
After=network.target

[Service]
ExecStart=/usr/local/bin/monitor_connection.sh
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl enable wifi-monitor.service

# Final startup
log "Starting services"
systemctl start hostapd
systemctl start dnsmasq
systemctl start nginx
systemctl start wifi-portal
systemctl start wifi-monitor

log "Access point setup completed"
log "SSID: JLBMaritime-AIS"
log "Password: Admin"
log "Captive portal is accessible at http://192.168.4.1"

exit 0

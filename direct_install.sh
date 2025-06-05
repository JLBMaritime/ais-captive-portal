#!/bin/bash

# Direct installation script for JLBMaritime-AIS Captive Portal
# This script handles the entire installation process
# Run this script as root

# Exit on error
set -e

echo "Starting JLBMaritime-AIS Captive Portal direct installation..."

# Create necessary system directories
mkdir -p /usr/local/bin
mkdir -p /etc/hostapd
mkdir -p /etc/dnsmasq.d
mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
mkdir -p /var/www/portal

# Copy setup script directly
cat > /usr/local/bin/setup_ap.sh << 'EOF'
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
systemctl stop hostapd || true
systemctl stop dnsmasq || true
systemctl stop wpa_supplicant || true

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

# Create hostapd.conf
log "Creating hostapd.conf"
cat > /etc/hostapd/hostapd.conf <<EOF
# Access Point Configuration for JLBMaritime-AIS
interface=wlan0
driver=nl80211
ssid=JLBMaritime-AIS
hw_mode=g
channel=7
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=Admin
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOF
chmod 600 /etc/hostapd/hostapd.conf

# Configure dnsmasq
log "Configuring dnsmasq"
cat > /etc/dnsmasq.d/captive-portal.conf <<EOF
# DHCP and DNS Configuration for Captive Portal

# Don't use /etc/resolv.conf
no-resolv

# Interface to bind to
interface=wlan0

# Specify the DHCP range
dhcp-range=192.168.4.2,192.168.4.20,255.255.255.0,24h

# Set the gateway IP address
dhcp-option=3,192.168.4.1

# Set DNS server address
dhcp-option=6,192.168.4.1

# Redirect all domains to captive portal IP
address=/#/192.168.4.1

# Enable logging
log-queries
log-dhcp
EOF
chmod 644 /etc/dnsmasq.d/captive-portal.conf

# Configure nginx
log "Configuring nginx"
cat > /etc/nginx/sites-available/captive-portal <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/portal;
    index index.html;

    server_name _;

    location / {
        try_files \$uri \$uri/ =404;
    }

    # API endpoint for handling WiFi credentials
    location /api/connect {
        proxy_pass http://localhost:5000/api/connect;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    # API endpoint for checking connection status
    location /api/status {
        proxy_pass http://localhost:5000/api/status;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF
ln -sf /etc/nginx/sites-available/captive-portal /etc/nginx/sites-enabled/default

# Create web portal files
log "Creating web portal files"
mkdir -p /var/www/portal

# Create index.html
cat > /var/www/portal/index.html <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>JLBMaritime-AIS</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 0;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            background-color: #f5f5f5;
        }
        .container {
            background-color: white;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
            padding: 30px;
            width: 90%;
            max-width: 500px;
        }
        .logo-container {
            text-align: center;
            margin-bottom: 20px;
        }
        .logo {
            max-width: 200px;
            height: auto;
        }
        h1 {
            text-align: center;
            color: #003366;
            margin-bottom: 30px;
        }
        .form-group {
            margin-bottom: 20px;
        }
        label {
            display: block;
            margin-bottom: 5px;
            font-weight: bold;
            color: #333;
        }
        input[type="text"],
        input[type="password"] {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 4px;
            box-sizing: border-box;
            font-size: 16px;
        }
        button {
            background-color: #003366;
            color: white;
            border: none;
            border-radius: 4px;
            padding: 12px 20px;
            font-size: 16px;
            cursor: pointer;
            width: 100%;
            transition: background-color 0.2s;
        }
        button:hover {
            background-color: #004b8f;
        }
        .status {
            margin-top: 20px;
            padding: 10px;
            border-radius: 4px;
            text-align: center;
            display: none;
        }
        .success {
            background-color: #e8f5e9;
            color: #2e7d32;
            border: 1px solid #c8e6c9;
        }
        .error {
            background-color: #ffebee;
            color: #c62828;
            border: 1px solid #ffcdd2;
        }
        .loading {
            display: none;
            text-align: center;
            margin-top: 20px;
        }
        .spinner {
            border: 4px solid rgba(0, 0, 0, 0.1);
            border-left-color: #003366;
            border-radius: 50%;
            width: 30px;
            height: 30px;
            animation: spin 1s linear infinite;
            margin: 0 auto;
        }
        @keyframes spin {
            to { transform: rotate(360deg); }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo-container">
            <img src="logo.png" alt="JLBMaritime Logo" class="logo">
        </div>
        <h1>JLBMaritime-AIS</h1>
        
        <form id="wifi-form">
            <div class="form-group">
                <label for="ssid">Wi-Fi Network Name (SSID):</label>
                <input type="text" id="ssid" name="ssid" required>
            </div>
            
            <div class="form-group">
                <label for="password">Wi-Fi Password:</label>
                <input type="password" id="password" name="password" required>
            </div>
            
            <button type="submit">Connect</button>
        </form>
        
        <div class="loading">
            <div class="spinner"></div>
            <p>Connecting to network...</p>
        </div>
        
        <div id="status-message" class="status"></div>
    </div>

    <script>
        document.addEventListener('DOMContentLoaded', function() {
            const form = document.getElementById('wifi-form');
            const statusMessage = document.getElementById('status-message');
            const loading = document.querySelector('.loading');
            
            // Check connection status on page load
            checkConnectionStatus();
            
            // Periodically check connection status
            setInterval(checkConnectionStatus, 10000);
            
            form.addEventListener('submit', function(e) {
                e.preventDefault();
                
                const ssid = document.getElementById('ssid').value;
                const password = document.getElementById('password').value;
                
                if (!ssid) {
                    showStatus('Please enter a Wi-Fi network name.', 'error');
                    return;
                }
                
                // Show loading spinner
                form.style.display = 'none';
                loading.style.display = 'block';
                statusMessage.style.display = 'none';
                
                // Send connection request to backend
                fetch('/api/connect', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({
                        ssid: ssid,
                        password: password
                    }),
                })
                .then(response => response.json())
                .then(data => {
                    loading.style.display = 'none';
                    form.style.display = 'block';
                    
                    if (data.success) {
                        showStatus(data.message, 'success');
                    } else {
                        showStatus(data.message, 'error');
                    }
                })
                .catch(error => {
                    loading.style.display = 'none';
                    form.style.display = 'block';
                    showStatus('Error connecting to network. Please try again.', 'error');
                });
            });
            
            function showStatus(message, type) {
                statusMessage.textContent = message;
                statusMessage.className = 'status ' + type;
                statusMessage.style.display = 'block';
            }
            
            function checkConnectionStatus() {
                fetch('/api/status')
                    .then(response => response.json())
                    .then(data => {
                        if (data.connected) {
                            showStatus('Connected to: ' + data.ssid, 'success');
                        }
                    })
                    .catch(error => {
                        // Silent fail - might not be connected yet
                    });
            }
        });
    </script>
</body>
</html>
EOF

# Create placeholder logo
touch /var/www/portal/logo.png
echo "<!-- Replace this file with your company logo -->" > /var/www/portal/logo.png

# Set permissions
chown -R www-data:www-data /var/www/portal

# Create WiFi portal service
log "Creating WiFi portal service"
cat > /usr/local/bin/wifi_portal.py << 'EOF'
#!/usr/bin/env python3
import os
import json
import time
import subprocess
import threading
import logging
from flask import Flask, request, jsonify

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("/var/log/wifi_portal.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Global variables
CREDENTIALS_FILE = "/etc/wpa_supplicant/credentials.json"
WPA_SUPPLICANT_CONF = "/etc/wpa_supplicant/wpa_supplicant.conf"
CONNECTION_STATUS = {
    "connected": False,
    "ssid": "",
    "last_updated": 0
}

# Create necessary directories if they don't exist
os.makedirs(os.path.dirname(CREDENTIALS_FILE), exist_ok=True)

def run_command(command):
    """Run a shell command and return its output."""
    try:
        result = subprocess.run(
            command, 
            shell=True, 
            check=True, 
            stdout=subprocess.PIPE, 
            stderr=subprocess.PIPE,
            text=True
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        logger.error(f"Command failed: {command}")
        logger.error(f"Error output: {e.stderr}")
        return None

def save_credentials(ssid, password):
    """Save WiFi credentials to a file."""
    credentials = {
        "ssid": ssid,
        "password": password
    }
    
    try:
        with open(CREDENTIALS_FILE, 'w') as f:
            json.dump(credentials, f)
        os.chmod(CREDENTIALS_FILE, 0o600)  # Secure file permissions
        return True
    except Exception as e:
        logger.error(f"Failed to save credentials: {str(e)}")
        return False

def generate_wpa_supplicant_conf(ssid, password):
    """Generate wpa_supplicant.conf file with provided credentials."""
    config = f"""ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=GB

network={{
    ssid="{ssid}"
    psk="{password}"
    key_mgmt=WPA-PSK
}}
"""
    
    try:
        with open(WPA_SUPPLICANT_CONF, 'w') as f:
            f.write(config)
        os.chmod(WPA_SUPPLICANT_CONF, 0o600)  # Secure file permissions
        return True
    except Exception as e:
        logger.error(f"Failed to generate wpa_supplicant.conf: {str(e)}")
        return False

def connect_to_wifi(ssid, password):
    """Connect to WiFi using provided credentials."""
    if not save_credentials(ssid, password):
        return False, "Failed to save credentials"
    
    if not generate_wpa_supplicant_conf(ssid, password):
        return False, "Failed to generate configuration"
    
    # Restart wpa_supplicant service
    restart_result = run_command("systemctl restart wpa_supplicant")
    if restart_result is None:
        return False, "Failed to restart wpa_supplicant service"
    
    # Wait for connection
    for _ in range(30):  # Try for 30 seconds
        check_result = run_command("wpa_cli -i wlan0 status | grep 'wpa_state=COMPLETED'")
        if check_result:
            # Update connection status
            CONNECTION_STATUS["connected"] = True
            CONNECTION_STATUS["ssid"] = ssid
            CONNECTION_STATUS["last_updated"] = time.time()
            return True, f"Successfully connected to {ssid}"
        time.sleep(1)
    
    return False, "Failed to connect to WiFi network"

def check_connection_status():
    """Check current WiFi connection status."""
    while True:
        try:
            # Check if wlan0 is connected
            check_result = run_command("wpa_cli -i wlan0 status | grep 'wpa_state=COMPLETED'")
            if check_result:
                # Get SSID
                ssid_result = run_command("wpa_cli -i wlan0 status | grep '^ssid=' | cut -d= -f2")
                if ssid_result:
                    CONNECTION_STATUS["connected"] = True
                    CONNECTION_STATUS["ssid"] = ssid_result
                    CONNECTION_STATUS["last_updated"] = time.time()
                else:
                    CONNECTION_STATUS["connected"] = False
            else:
                CONNECTION_STATUS["connected"] = False
        except Exception as e:
            logger.error(f"Error checking connection status: {str(e)}")
            CONNECTION_STATUS["connected"] = False
        
        time.sleep(10)  # Check every 10 seconds

# Start connection status monitoring thread
status_thread = threading.Thread(target=check_connection_status, daemon=True)
status_thread.start()

@app.route('/api/connect', methods=['POST'])
def connect():
    """API endpoint to connect to a WiFi network."""
    data = request.get_json()
    
    if not data or 'ssid' not in data:
        return jsonify({
            'success': False,
            'message': 'SSID is required'
        }), 400
    
    ssid = data['ssid']
    password = data.get('password', '')
    
    logger.info(f"Attempting to connect to: {ssid}")
    success, message = connect_to_wifi(ssid, password)
    
    return jsonify({
        'success': success,
        'message': message
    })

@app.route('/api/status', methods=['GET'])
def status():
    """API endpoint to check WiFi connection status."""
    return jsonify(CONNECTION_STATUS)

if __name__ == '__main__':
    # Initialize connection status
    check_connection_status()
    
    # Start Flask application
    app.run(host='0.0.0.0', port=5000)
EOF
chmod +x /usr/local/bin/wifi_portal.py

# Create connection monitor script
log "Creating connection monitor script"
cat > /usr/local/bin/monitor_connection.sh << 'EOF'
#!/bin/bash

# Monitor WiFi connection and reactivate AP if connection is lost
LOG_FILE="/var/log/wifi_monitor.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
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

# Configure and enable services
log "Configuring services"

# Set up IP forwarding for internet access if connected
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/90-ip-forward.conf
sysctl -p /etc/sysctl.d/90-ip-forward.conf

# Set up NAT
cat > /etc/iptables-ap-rules << 'EOF'
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -o eth0 -j MASQUERADE
COMMIT
EOF

# Create systemd services
cat > /etc/systemd/system/iptables-ap.service << 'EOF'
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

cat > /etc/systemd/system/wifi-portal.service << 'EOF'
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

cat > /etc/systemd/system/wifi-monitor.service << 'EOF'
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

cat > /etc/systemd/system/captive-portal.service << 'EOF'
[Unit]
Description=JLBMaritime-AIS Captive Portal
After=network.target
Wants=network.target
Documentation=https://github.com/jlbmaritime/ais-captive-portal

[Service]
Type=oneshot
ExecStart=/usr/local/bin/setup_ap.sh
RemainAfterExit=yes
StandardOutput=journal+console
StandardError=journal+console
Restart=on-failure
RestartSec=30s

[Install]
WantedBy=multi-user.target
EOF

# Make setup script executable
chmod +x /usr/local/bin/setup_ap.sh

# Enable services
systemctl daemon-reload
systemctl enable iptables-ap.service
systemctl enable wifi-portal.service
systemctl enable wifi-monitor.service
systemctl enable captive-portal.service

# Start services
systemctl start captive-portal.service

echo "JLBMaritime-AIS Captive Portal installation completed!"
echo "The Raspberry Pi will now function as a captive portal with SSID: JLBMaritime-AIS"
echo "Customers can connect to this network with password: Admin"
echo "After connecting, they will be redirected to a portal to configure their WiFi settings"

exit 0
EOF

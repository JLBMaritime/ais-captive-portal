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

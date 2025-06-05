# JLBMaritime-AIS Captive Portal

A captive portal solution for Raspberry Pi 4B 2GB that allows customers to input their Wi-Fi credentials and connect the AIS receiver/server to their Wi-Fi network.

## Features

- Creates a wireless access point with SSID "JLBMaritime-AIS" and password "Admin"
- Provides a captive portal web interface accessible on any device (desktop PC, laptop, iPhone, Android phone)
- Allows customers to input their Wi-Fi network credentials
- Connects the Raspberry Pi to the customer's Wi-Fi network
- Automatically reconnects to the known Wi-Fi network after power loss
- Reactivates the captive portal if the Wi-Fi connection is lost
- Displays success/failure messages when connecting to a network
- Handles invalid credentials by allowing users to re-enter information

## Requirements

- Raspberry Pi 4B 2GB
- Fresh 64-bit Bookworm operating system
- Username: JLBMaritime
- Hostname: AIS
- Wi-Fi adapter (built-in or external)

## Installation Instructions

### Method 1: Direct Installation from GitHub

1. SSH into your Raspberry Pi as the JLBMaritime user
2. Clone the repository:
   ```
   git clone https://github.com/jlbmaritime/ais-captive-portal.git
   cd ais-captive-portal
   ```
3. Make the installation scripts executable:
   ```
   chmod +x install.sh complete_installation.sh
   ```
4. Run the installation script with the GitHub flag:
   ```
   ./install.sh --from-github
   ```
5. Complete the installation as root:
   ```
   sudo ./complete_installation.sh
   ```

### Method 2: Manual Installation

1. Download the repository as a ZIP file from GitHub
2. Extract and copy all files to the Raspberry Pi
3. Make the installation scripts executable:
   ```
   chmod +x install.sh
   ```
4. Run the installation script as the JLBMaritime user:
   ```
   ./install.sh
   ```
5. Complete the installation as root:
   ```
   sudo ./complete_installation.sh
   ```

### One-Line Installation (Advanced)

For a quick installation directly from GitHub, you can use this one-line command:

```bash
curl -sSL https://raw.githubusercontent.com/jlbmaritime/ais-captive-portal/main/install.sh | bash -s -- --from-github && sudo ./complete_installation.sh
```

### Direct Installation (Troubleshooting)

If you encounter issues with the standard installation method, you can use the direct installation script which installs all files directly to their system locations:

```bash
# Make the script executable
chmod +x direct_install.sh

# Run the installation script as root
sudo ./direct_install.sh
```

This direct installation method is useful when troubleshooting file path issues or when you need to ensure all components are installed correctly. It bypasses the two-step installation process by creating all necessary files directly in their required system locations.

## Customization

- Replace the logo image at `/home/JLBMaritime/captive-portal/var/www/portal/logo.png` with your company logo
- Edit the web page at `/home/JLBMaritime/captive-portal/var/www/portal/index.html` if needed

## How It Works

1. When powered on, the Raspberry Pi creates a Wi-Fi access point named "JLBMaritime-AIS"
2. Customers connect to this network using the password "Admin"
3. Any web request is redirected to the captive portal page
4. Customers enter their Wi-Fi network name and password
5. The Raspberry Pi attempts to connect to the customer's network
6. Success or failure messages are displayed to the customer
7. If the connection is successful, the Raspberry Pi maintains the connection
8. If the connection is lost, the captive portal is reactivated

## File Structure

- `etc/hostapd/hostapd.conf`: Access point configuration
- `etc/dnsmasq.d/captive-portal.conf`: DHCP and DNS configuration
- `etc/nginx/sites-available/captive-portal`: Web server configuration
- `var/www/portal/`: Web portal files
- `usr/local/bin/wifi_portal.py`: Backend service for handling Wi-Fi connections
- `usr/local/bin/setup_ap.sh`: Script to set up the wireless access point
- `usr/local/bin/monitor_connection.sh`: Script to monitor Wi-Fi connection
- `etc/systemd/system/captive-portal.service`: Systemd service for automatic startup

## Troubleshooting

Check the following log files for troubleshooting:
- `/var/log/setup_ap.log`: Setup script logs
- `/var/log/wifi_portal.log`: Wi-Fi portal service logs
- `/var/log/wifi_monitor.log`: Connection monitoring logs

### Common issues:

#### The captive portal doesn't appear
- Try navigating directly to http://192.168.4.1
- Check if hostapd is running: `systemctl status hostapd`
- Verify the Wi-Fi interface is working: `ifconfig wlan0`
- Check hostapd logs: `journalctl -u hostapd`

#### The Raspberry Pi can't connect to the customer's network
- Verify the credentials are correct
- Check if the network is in range: `iwlist wlan0 scan | grep ESSID`
- Check wpa_supplicant logs: `journalctl -u wpa_supplicant`
- Review the Wi-Fi portal logs: `cat /var/log/wifi_portal.log`

#### The access point doesn't appear
- Restart the Raspberry Pi: `sudo reboot`
- Check if the setup script is running: `systemctl status captive-portal`
- Look for errors in setup logs: `cat /var/log/setup_ap.log`
- Manually restart the service: `sudo systemctl restart captive-portal`

#### Services fail to start
- Check if the setup script is executable: `ls -la /usr/local/bin/setup_ap.sh`
- Ensure Python Flask is installed: `pip3 list | grep Flask`
- Check system logs: `journalctl -xe`
- Manually start each service to see errors:
  ```
  sudo systemctl start hostapd
  sudo systemctl start dnsmasq
  sudo systemctl start nginx
  sudo systemctl start wifi-portal
  ```

## Service Management

- Check status: `sudo systemctl status captive-portal.service`
- Restart service: `sudo systemctl restart captive-portal.service`
- Stop service: `sudo systemctl stop captive-portal.service`
- Start service: `sudo systemctl start captive-portal.service`

# JLBMaritime-AIS Captive Portal Deployment Guide

This guide provides step-by-step instructions for deploying the JLBMaritime-AIS captive portal solution to your Raspberry Pi 4B 2GB devices. Follow these instructions to ensure a successful installation.

## Pre-Deployment Checklist

- [ ] Raspberry Pi 4B 2GB with 64-bit Bookworm OS installed
- [ ] Username set to: JLBMaritime
- [ ] Hostname set to: AIS
- [ ] Internet connectivity (for initial setup)
- [ ] SSH access enabled

## Deployment Methods

Choose one of the following deployment methods based on your needs:

### Method 1: Standard Two-Step Installation

This is the recommended method for most deployments.

```bash
# 1. Connect to your Raspberry Pi via SSH
ssh JLBMaritime@AIS.local

# 2. Clone the repository
git clone https://github.com/jlbmaritime/ais-captive-portal.git
cd ais-captive-portal

# 3. Make installation scripts executable
chmod +x install.sh complete_installation.sh

# 4. Run the first installation step
./install.sh

# 5. Run the second installation step as root
sudo ./complete_installation.sh

# 6. Verify installation
systemctl status captive-portal.service
```

### Method 2: Direct Installation (For Troubleshooting)

Use this method if you encounter issues with the standard installation method.

```bash
# 1. Connect to your Raspberry Pi via SSH
ssh JLBMaritime@AIS.local

# 2. Clone the repository
git clone https://github.com/jlbmaritime/ais-captive-portal.git
cd ais-captive-portal

# 3. Make the direct installation script executable
chmod +x direct_install.sh

# 4. Run the direct installation script as root
sudo ./direct_install.sh

# 5. Verify installation
systemctl status captive-portal.service
```

### Method 3: One-Line Installation

For quick deployment across multiple devices.

```bash
# Connect to your Raspberry Pi and run this single command:
curl -sSL https://raw.githubusercontent.com/jlbmaritime/ais-captive-portal/main/install.sh | bash -s -- --from-github && sudo ./complete_installation.sh
```

## Post-Installation Verification

After installation, perform these checks to ensure everything is working properly:

1. **Check Service Status**:
   ```bash
   sudo systemctl status captive-portal.service
   sudo systemctl status hostapd
   sudo systemctl status dnsmasq
   sudo systemctl status nginx
   sudo systemctl status wifi-portal.service
   ```

2. **Verify Network Access Point**:
   - Use a smartphone or laptop to search for a Wi-Fi network named "JLBMaritime-AIS"
   - Connect using the password "Admin"

3. **Test Captive Portal**:
   - After connecting to the Wi-Fi network, open a web browser
   - The captive portal page should appear automatically
   - If not, navigate to http://192.168.4.1

4. **Test Wi-Fi Configuration**:
   - Enter valid Wi-Fi credentials in the portal
   - Verify connection success message

## Troubleshooting

If you encounter issues during deployment:

### Setup Script Not Found Error

If you see `Failed at step EXEC spawning /usr/local/bin/setup_ap.sh: No such file or directory`:

```bash
# 1. Check if the script exists
ls -la /usr/local/bin/setup_ap.sh

# 2. If it doesn't exist, use the direct installation method:
sudo ./direct_install.sh
```

### Services Fail to Start

```bash
# Check logs for errors
journalctl -xeu captive-portal.service

# Restart the service
sudo systemctl restart captive-portal.service

# If problems persist, try the direct installation method
sudo ./direct_install.sh
```

### Captive Portal Not Appearing

```bash
# Restart the services
sudo systemctl restart hostapd dnsmasq nginx wifi-portal

# Check hostapd configuration
cat /etc/hostapd/hostapd.conf

# Verify Wi-Fi interface
iwconfig
```

## GitHub Deployment

To deploy your customized captive portal solution to GitHub:

```bash
# 1. Run the GitHub setup script
./setup_github.sh

# 2. Or use the push script for more options
./push_to_github.sh
```

## Customizing for Production

Before mass deployment:

1. Replace the logo at `/var/www/portal/logo.png` with your company logo
2. Customize the HTML/CSS in `/var/www/portal/index.html` if needed
3. Update any documentation references to match your GitHub repository

## Support

For technical support or to report issues:
- Check detailed logs in `/var/log/setup_ap.log`
- Use `journalctl -xe` to view system logs
- Refer to the troubleshooting section in README.md

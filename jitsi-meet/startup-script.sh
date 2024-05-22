#!/bin/bash

# Variables
DOMAIN="meet.dizikloud.top"
PUBLIC_IP=$(curl -s http://checkip.amazonaws.com)
EMAIL="anindya.subs@gmail.com"

# Set the hostname
sudo hostnamectl set-hostname $DOMAIN
hostname

# Update /etc/hosts
echo "$PUBLIC_IP $DOMAIN" | sudo tee -a /etc/hosts

# Update the package list and upgrade the system
sudo apt-get update
sudo apt-get upgrade -y

# Install required packages for Jitsi Meet
sudo apt-get install -y apt-transport-https curl gnupg

# Add Jitsi repository key
curl https://download.jitsi.org/jitsi-key.gpg.key -o jitsi-key.gpg.key
sudo gpg --output /usr/share/keyrings/jitsi-key.gpg --dearmor jitsi-key.gpg.key
echo "deb [signed-by=/usr/share/keyrings/jitsi-key.gpg] https://download.jitsi.org stable/" | sudo tee /etc/apt/sources.list.d/jitsi-stable.list

# Add Prosody repository key
curl https://prosody.im/files/prosody-debian-packages.key -o prosody-debian-packages.key
sudo gpg --output /usr/share/keyrings/prosody-keyring.gpg --dearmor prosody-debian-packages.key
echo "deb [signed-by=/usr/share/keyrings/prosody-keyring.gpg] http://packages.prosody.im/debian jammy main" | sudo tee /etc/apt/sources.list.d/prosody.list

# Clean up key files
rm jitsi-key.gpg.key prosody-debian-packages.key

# Update package lists with new repositories
sudo apt-get update

# Preconfigure answers for jitsi-meet installation
echo "jitsi-videobridge2 jitsi-videobridge/jvb-hostname string $DOMAIN" | sudo debconf-set-selections
echo "jitsi-meet-web-config jitsi-meet/cert-choice select Self-signed certificate" | sudo debconf-set-selections

# Install Jitsi Meet in an unattended way
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y jitsi-meet

# Configure firewall
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 3478/udp
sudo ufw allow 5349/tcp
sudo ufw allow 10000/udp
sudo ufw --force enable
sudo ufw status

# Configure Jitsi Meet with Let's Encrypt certificates
sudo /usr/share/jitsi-meet/scripts/install-letsencrypt-cert.sh $EMAIL

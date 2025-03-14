#!/bin/bash

# Ensure script runs with root privileges
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Exiting."
    exit 1
fi

echo "Starting Assignment 2 Configuration Script..."

# Define network interface manually
INTERFACE="ens33"

# Validate if the interface exists
if ! ip link show "$INTERFACE" &>/dev/null; then
    echo "Error: Network interface $INTERFACE not found! Check with 'ip a'"
    exit 1
fi

echo "Using network interface: $INTERFACE"

# 1. Configure the network (Netplan)
echo "Configuring network settings..."
NETPLAN_FILE="/etc/netplan/00-installer-config.yaml"

if grep -q "192.168.16.21/24" "$NETPLAN_FILE"; then
    echo "Network configuration already set."
else
    cat <<EOF > "$NETPLAN_FILE"
network:
  ethernets:
    $INTERFACE:
      dhcp4: no
      addresses:
        - 192.168.16.21/24
  version: 2
EOF
    netplan apply
    echo "Network configuration updated and applied."
fi

# 2. Update /etc/hosts
echo "Updating /etc/hosts..."
if grep -q "192.168.16.21 server1" /etc/hosts; then
    echo "/etc/hosts is already configured."
else
    sed -i '/server1/d' /etc/hosts
    echo "192.168.16.21 server1" >> /etc/hosts
    echo "/etc/hosts updated."
fi

# 3. Install required software (Apache2 and Squid Proxy)
echo "Checking required software installation..."
apt update -y

for package in apache2 squid; do
    if dpkg -l | grep -q "$package"; then
        echo "$package is already installed."
    else
        echo "Installing $package..."
        apt install -y "$package"
    fi
done

# 4. Create user accounts and set up SSH keys
echo "Creating user accounts..."
USERS=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")

for user in "${USERS[@]}"; do
    if id "$user" &>/dev/null; then
        echo "User $user already exists."
    else
        echo "Creating user $user..."
        useradd -m -s /bin/bash "$user"
        mkdir -p /home/$user/.ssh
        ssh-keygen -t rsa -b 2048 -f /home/$user/.ssh/id_rsa -N ""
        ssh-keygen -t ed25519 -f /home/$user/.ssh/id_ed25519 -N ""
        cat /home/$user/.ssh/id_rsa.pub >> /home/$user/.ssh/authorized_keys
        cat /home/$user/.ssh/id_ed25519.pub >> /home/$user/.ssh/authorized_keys
        chown -R $user:$user /home/$user/.ssh
        chmod 700 /home/$user/.ssh
        chmod 600 /home/$user/.ssh/authorized_keys
    fi
done

# 5. Add sudo access to user dennis
if id "dennis" &>/dev/null; then
    echo "Ensuring user dennis has sudo access..."
    usermod -aG sudo dennis
fi

# 6. Add the provided SSH key for dennis
echo "Adding SSH key for dennis..."
mkdir -p /home/dennis/.ssh
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm" >> /home/dennis/.ssh/authorized_keys
chown -R dennis:dennis /home/dennis/.ssh
chmod 700 /home/dennis/.ssh
chmod 600 /home/dennis/.ssh/authorized_keys

echo "Assignment 2 Configuration Complete!"


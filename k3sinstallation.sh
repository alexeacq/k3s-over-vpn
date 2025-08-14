#!/bin/bash

# Define the config file path
CONFIG_FILE="configuration"

# Check if the config file exists
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: Config file '$CONFIG_FILE' not found!"
  exit 1
fi

# Read variables from the config file
while IFS='=' read -r key value; do
  # Skip comments and empty lines
  [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue

  # Remove quotes and export the variable
  value=$(echo "$value" | sed "s/['\"]//g")
  declare "$key=$value"
done <"$CONFIG_FILE"

# Define log directory and file
LOG_DIR="/home/aledpi/Desktop/logs"
LOG_FILE="$LOG_DIR/installationlogs"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Function to log messages
log_message() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >>"$LOG_FILE"
  echo "$1"
}

# Check if VPN interface exists
VPN_INTERFACE="raspVPN"
if ! ip link show "$VPN_INTERFACE" &>/dev/null; then
  log_message "ERROR: VPN interface '$VPN_INTERFACE' not found. Installation canceled."
  exit 1
fi

# Get the VPN IP from the raspVPN interface
VPN_IP=$(ip -4 addr show "$VPN_INTERFACE" | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

if [ -z "$VPN_IP" ]; then
  log_message "ERROR: Could not detect IP address for VPN interface '$VPN_INTERFACE'. Installation canceled."
  exit 1
fi

log_message "Detected VPN IP: $VPN_IP"

# Check if this is a server (control plane) or agent installation
#read -p "Is this a control plane node? (y/n): " IS_SERVER

if [[ "$IS_SERVER" == "y" || "$IS_SERVER" == "Y" ]]; then
  log_message "Installing k3s server with VPN IP $VPN_IP"

  # Now install k3s server with the detected VPN IP
  if curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-ip=$VPN_IP --flannel-iface=$VPN_INTERFACE --bind-address=$VPN_IP --advertise-address=$VPN_IP" sh -; then
    log_message "k3s server was successfully installed on $VPN_IP"

    # Display the token for agent nodes
    NODE_TOKEN=$(sudo cat /var/lib/rancher/k3s/server/node-token)
    log_message "Node token for adding worker nodes: $NODE_TOKEN"
    log_message "Use this token with the K3S_TOKEN environment variable when installing agents"
  else
    log_message "ERROR: k3s server installation failed"
    exit 1
  fi
else
  # For agent/worker nodes, we need the server URL and token
  #   read -p "Enter the control plane VPN IP: " SERVER_IP
  #   read -p "Enter the node token: " NODE_TOKEN

  log_message "Installing k3s agent with VPN IP $VPN_IP connecting to server $SERVER_IP"

  # Now install k3s agent with the detected VPN IP
  if curl -sfL https://get.k3s.io | K3S_URL="https://$SERVER_IP:6443" K3S_TOKEN="$NODE_TOKEN" INSTALL_K3S_EXEC="--node-ip=$VPN_IP --flannel-iface=$VPN_INTERFACE" sh -; then
    log_message "k3s agent was successfully installed on $VPN_IP connected to $SERVER_IP"
  else
    log_message "ERROR: k3s agent installation failed"
    exit 1
  fi
fi

exit 0

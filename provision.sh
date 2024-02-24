#!/bin/bash
#
# Bootstrap a node.
#

set -u
set -e

# Variables
export DEBIAN_FRONTEND=noninteractive
SYSTEM_REPO="git@github.com:killerbeebatteries/bushive-system.git"

# if arguments contain --hardware-node, then set HARDWARE_NODE to true
if [[ "$*" == *--hardware-node* ]]; then
  HARDWARE_NODE=true
else
  HARDWARE_NODE=false
fi

# Update the system
sudo apt-get update

# Install the required OS packages
sudo apt-get install -y git dnsmasq curl

# Install golang via goenv https://github.com/go-nv/goenv/blob/master/INSTALL.md
rm -Rf ~/.goenv 
git clone https://github.com/go-nv/goenv.git ~/.goenv

echo 'export GOENV_ROOT="$HOME/.goenv"' >> ~/.bashrc
echo 'export PATH="$GOENV_ROOT/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(goenv init -)"' >> ~/.bash_profile

source ~/.bashrc

goenv install 1.21.7
goenv global 1.21.7

# Install k3s
curl -sfL https://get.k3s.io | sh - 
# Check for Ready node, takes ~30 seconds 
sudo k3s kubectl get node 

# Install Flux CD
curl -s https://fluxcd.io/install.sh | sudo bash
. <(flux completion bash)

# Provision Flux CD
echo "TODO: Provision Flux CD"


# Configure WIFI and DHCP
if [ $HARDWARE_NODE == true ]; then
  echo "TODO: Configure WIFI for hardware node"
  echo "TODO: Configure DHCP for hardware node"
else
  echo "Node is not a hardware node?"
  echo "Assuming node is already configured for DHCP."
  echo "No WIFI configuration required."
fi  

# Configure DNS
echo "TODO: Configure DNS"

#!/bin/bash
set -e

echo "🔐 Installing Gasket DKMS APT repo..."

# Define repo and key URLs
REPO_URL="https://pcpedersen.github.io/gasket-driver/apt"
KEY_URL="$REPO_URL/pubkey.gpg"
KEYRING_PATH="/etc/apt/trusted.gpg.d/gasket-driver.gpg"
LIST_PATH="/etc/apt/sources.list.d/gasket-driver.list"

# Step 1: Import GPG key (non-deprecated method)
echo "📥 Fetching and registering GPG key..."
curl -fsSL "$KEY_URL" | sudo gpg --dearmor -o "$KEYRING_PATH"

# Step 2: Add the APT source with signed-by
echo "➕ Adding APT source..."
echo "deb [arch=amd64 signed-by=$KEYRING_PATH] $REPO_URL noble main" | \
  sudo tee "$LIST_PATH" > /dev/null

# Step 3: Update and install the package
echo "🔄 Updating package list..."
sudo apt update

echo "📦 Installing gasket-dkms..."
sudo apt install -y gasket-dkms

echo "✅ Installation complete. DKMS status:"
dkms status | grep gasket || echo "Module not yet built — run 'sudo dkms autoinstall' if needed."

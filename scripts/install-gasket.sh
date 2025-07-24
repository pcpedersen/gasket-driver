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

echo "🔐 Checking Secure Boot status..."
if mokutil --sb-state | grep -q 'SecureBoot enabled'; then
  CERT_PATH="/usr/share/doc/gasket-dkms/signing_key.der"
  if [ -f "$CERT_PATH" ]; then
    echo "📎 Found signing certificate at $CERT_PATH"
    echo "🚀 Automatically requesting MOK enrollment..."

    # Request enrollment with a pre-defined password
    ENROLL_PASSWORD=$(cat /etc/mok-password)
    echo "$ENROLL_PASSWORD" | sudo mokutil --import $CERT_PATH

    echo "✅ Key import requested. You must reboot and complete enrollment in the MOK Manager."
    echo "🔒 Use password: $ENROLL_PASSWORD"
  else
    echo "❌ Certificate not found at expected location: $CERT_PATH"
  fi
else
  echo "🔓 Secure Boot is disabled — no key enrollment needed."
fi

#!/bin/bash
set -e

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    if ! command -v brew &> /dev/null; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    echo "Installing PowerShell via Homebrew..."
    brew install --cask powershell

elif [[ -f "/etc/debian_version" ]]; then
    # Debian/Ubuntu
    echo "Installing PowerShell on Debian/Ubuntu..."
    # Install system components
    sudo apt-get update
    sudo apt-get install -y curl gnupg apt-transport-https

    # Import the public repository GPG keys
    curl -sSL https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -

    # Register the Microsoft Product feed
    DISTRO=$(lsb_release -cs)
    sudo sh -c "echo 'deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-debian-${DISTRO}-prod ${DISTRO} main' > /etc/apt/sources.list.d/microsoft.list"

    # Install PowerShell
    sudo apt-get update
    sudo apt-get install -y powershell

elif [[ -f "/etc/redhat-release" ]]; then
    # RHEL/CentOS
    echo "Installing PowerShell on RHEL/CentOS..."
    # Register the Microsoft RedHat repository
    curl -sSL https://packages.microsoft.com/config/rhel/7/prod.repo | sudo tee /etc/yum.repos.d/microsoft.repo

    # Install PowerShell
    sudo yum install -y powershell

else
    echo "Unsupported operating system"
    exit 1
fi

# Verify PowerShell installation
if ! command -v pwsh &> /dev/null; then
    echo "PowerShell installation failed"
    exit 1
fi

echo "PowerShell installation completed successfully" 
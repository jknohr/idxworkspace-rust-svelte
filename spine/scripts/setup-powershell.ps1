# Setup script for installing PowerShell
param (
    [string]$Version = "7.4.1"
)

$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'

# Function to test if PowerShell 7+ is installed
function Test-PowerShellCore {
    try {
        $pwshPath = Get-Command pwsh -ErrorAction SilentlyContinue
        if ($pwshPath) {
            $version = & pwsh -Version
            return [version]$version -ge [version]"7.0"
        }
    } catch {
        return $false
    }
    return $false
}

# Function to install PowerShell Core silently
function Install-PowerShellCore {
    $os = if ($IsWindows) { "win" } elseif ($IsMacOS) { "osx" } else { "linux" }
    $arch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
    
    switch ($os) {
        "win" {
            $url = "https://github.com/PowerShell/PowerShell/releases/download/v$Version/PowerShell-$Version-win-$arch.msi"
            $installer = Join-Path $env:TEMP "powershell-installer.msi"
            
            Write-Host "Downloading PowerShell $Version..."
            Invoke-WebRequest -Uri $url -OutFile $installer
            
            Write-Host "Installing PowerShell..."
            Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", $installer, "/quiet", "/norestart" -Wait
            Remove-Item $installer
        }
        "osx" {
            # For macOS, we use Homebrew
            if (-not (Get-Command brew -ErrorAction SilentlyContinue)) {
                Write-Host "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            }
            Write-Host "Installing PowerShell via Homebrew..."
            brew install --cask powershell
        }
        "linux" {
            # For Linux, we need to handle different distributions
            if (Test-Path "/etc/debian_version") {
                # Debian/Ubuntu
                Write-Host "Installing PowerShell on Debian/Ubuntu..."
                # Add Microsoft repository
                curl -sSL https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
                sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-debian-$(lsb_release -cs)-prod $(lsb_release -cs) main" > /etc/apt/sources.list.d/microsoft.list'
                sudo apt-get update
                sudo apt-get install -y powershell
            }
            elseif (Test-Path "/etc/redhat-release") {
                # RHEL/CentOS
                Write-Host "Installing PowerShell on RHEL/CentOS..."
                curl -sSL https://packages.microsoft.com/config/rhel/7/prod.repo | sudo tee /etc/yum.repos.d/microsoft.repo
                sudo yum install -y powershell
            }
            else {
                throw "Unsupported Linux distribution"
            }
        }
    }
    
    # Verify installation
    if (-not (Test-PowerShellCore)) {
        throw "PowerShell installation failed"
    }
}

# Main installation logic
try {
    if (Test-PowerShellCore) {
        Write-Host "PowerShell Core is already installed"
    }
    else {
        Install-PowerShellCore
        Write-Host "PowerShell Core installation completed successfully"
    }
}
catch {
    Write-Error "Failed to install PowerShell Core: $_"
    exit 1
} 
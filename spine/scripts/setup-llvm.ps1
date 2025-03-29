# Setup script for installing LLVM
param (
    [string]$Version = "17.0.6"
)

$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'

# Function to test if LLVM is installed
function Test-LLVMInstalled {
    if ($IsWindows) {
        $llvmPath = "C:\Program Files\LLVM"
        $libclangPath = Join-Path $llvmPath "bin\libclang.dll"
    } else {
        $llvmPath = "/usr/local/opt/llvm"
        if (-not $IsMacOS) {
            $llvmPath = "/usr/lib/llvm-$Version"
        }
        $libclangPath = Join-Path $llvmPath "lib/libclang.so"
        if ($IsMacOS) {
            $libclangPath = Join-Path $llvmPath "lib/libclang.dylib"
        }
    }
    return (Test-Path $libclangPath)
}

# Function to install LLVM silently
function Install-LLVMSilently {
    $os = if ($IsWindows) { "windows" } elseif ($IsMacOS) { "darwin" } else { "linux" }
    $arch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
    
    Write-Host "Installing LLVM for $os-$arch..."
    
    switch ($os) {
        "windows" {
            $url = "https://github.com/llvm/llvm-project/releases/download/llvmorg-$Version/LLVM-$Version-win64.exe"
            $installer = Join-Path $env:TEMP "llvm-installer.exe"
            
            Write-Host "Downloading LLVM $Version..."
            Invoke-WebRequest -Uri $url -OutFile $installer
            
            Write-Host "Installing LLVM..."
            Start-Process -FilePath $installer -Args "/S" -Wait
            Remove-Item $installer
        }
        "darwin" {
            # For macOS, we use Homebrew
            if (-not (Get-Command brew -ErrorAction SilentlyContinue)) {
                Write-Host "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            }
            Write-Host "Installing LLVM via Homebrew..."
            brew install llvm@$Version
            brew link --force llvm@$Version
        }
        "linux" {
            # For Linux, we need to handle different distributions
            if (Test-Path "/etc/debian_version") {
                # Debian/Ubuntu
                Write-Host "Installing LLVM on Debian/Ubuntu..."
                $shortVersion = $Version.Split('.')[0]
                
                # Add LLVM repository
                curl -sSL https://apt.llvm.org/llvm.sh | sudo bash -s $shortVersion
                
                # Install LLVM packages
                sudo apt-get update
                sudo apt-get install -y libclang-$shortVersion-dev llvm-$shortVersion-dev
            }
            elseif (Test-Path "/etc/redhat-release") {
                # RHEL/CentOS
                Write-Host "Installing LLVM on RHEL/CentOS..."
                $shortVersion = $Version.Split('.')[0]
                
                # Add LLVM repository
                sudo yum install -y centos-release-scl
                sudo yum install -y llvm-toolset-$shortVersion
                
                # Enable LLVM toolset
                echo "source scl_source enable llvm-toolset-$shortVersion" | sudo tee -a /etc/profile.d/llvm.sh
            }
            else {
                throw "Unsupported Linux distribution"
            }
        }
    }
    
    # Verify installation
    if (-not (Test-LLVMInstalled)) {
        throw "LLVM installation failed"
    }
}

# Function to create cleanup script
function New-CleanupScript {
    $cleanupScript = @'
$ErrorActionPreference = "Stop"
# Remove LLVM from PATH
$path = [Environment]::GetEnvironmentVariable("PATH", "Machine")
$llvmPath = if ($IsWindows) {
    "C:\Program Files\LLVM\bin"
} elseif ($IsMacOS) {
    "/usr/local/opt/llvm/bin"
} else {
    "/usr/lib/llvm-$Version/bin"
}
$newPath = ($path.Split(';') | Where-Object { $_ -ne $llvmPath }) -join ';'
[Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")

# Remove LIBCLANG_PATH
[Environment]::SetEnvironmentVariable("LIBCLANG_PATH", $null, "Machine")
'@
    
    $cleanupPath = "cleanup-llvm.ps1"
    Set-Content -Path $cleanupPath -Value $cleanupScript
    Write-Host "Created cleanup script at $cleanupPath"
}

# Main installation logic
try {
    if (Test-LLVMInstalled) {
        Write-Host "LLVM is already installed"
    } else {
        Install-LLVMSilently
        
        # Add LLVM to PATH if not already present
        $llvmBinPath = if ($IsWindows) {
            "C:\Program Files\LLVM\bin"
        } elseif ($IsMacOS) {
            "/usr/local/opt/llvm/bin"
        } else {
            "/usr/lib/llvm-$Version/bin"
        }
        
        $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
        if ($currentPath -notlike "*$llvmBinPath*") {
            $newPath = "$currentPath;$llvmBinPath"
            [Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")
        }
        
        # Set LIBCLANG_PATH
        [Environment]::SetEnvironmentVariable("LIBCLANG_PATH", $llvmBinPath, "Machine")
        
        Write-Host "LLVM installation completed successfully"
        New-CleanupScript
    }
} catch {
    Write-Error "Failed to install LLVM: $_"
    exit 1
} 
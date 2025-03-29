# Setup script for installing WasmEdge
param (
    [string]$Version = "0.13.5"
)

$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'

# Function to test if WasmEdge is installed
function Test-WasmEdgeInstalled {
    if ($IsWindows) {
        $wasmedgePath = "C:\Program Files\WasmEdge"
        $wasmedgeLibPath = Join-Path $wasmedgePath "lib\wasmedge.dll"
    } else {
        $wasmedgePath = "/usr/local/lib/wasmedge"
        $wasmedgeLibPath = Join-Path $wasmedgePath "libwasmedge.so"
        if ($IsMacOS) {
            $wasmedgeLibPath = Join-Path $wasmedgePath "libwasmedge.dylib"
        }
    }
    return (Test-Path $wasmedgeLibPath)
}

# Function to install WasmEdge silently
function Install-WasmEdgeSilently {
    $os = if ($IsWindows) { "windows" } elseif ($IsMacOS) { "darwin" } else { "linux" }
    $arch = if ([Environment]::Is64BitOperatingSystem) { "amd64" } else { "amd32" }
    
    Write-Host "Installing WasmEdge for $os-$arch..."
    
    switch ($os) {
        "windows" {
            $url = "https://github.com/WasmEdge/WasmEdge/releases/download/$Version/WasmEdge-$Version-windows.msi"
            $installer = Join-Path $env:TEMP "wasmedge-installer.msi"
            
            Write-Host "Downloading WasmEdge $Version..."
            Invoke-WebRequest -Uri $url -OutFile $installer
            
            Write-Host "Installing WasmEdge..."
            Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", $installer, "/quiet", "/norestart" -Wait
            Remove-Item $installer
        }
        "darwin" {
            # For macOS, we use Homebrew
            if (-not (Get-Command brew -ErrorAction SilentlyContinue)) {
                Write-Host "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            }
            Write-Host "Installing WasmEdge via Homebrew..."
            brew install wasmedge
        }
        "linux" {
            # For Linux, we use the official install script
            Write-Host "Installing WasmEdge using official install script..."
            $env:WASMEDGE_VERSION = $Version
            curl -sSf https://raw.githubusercontent.com/WasmEdge/WasmEdge/master/utils/install.sh | bash
        }
    }
    
    # Verify installation
    if (-not (Test-WasmEdgeInstalled)) {
        throw "WasmEdge installation failed"
    }
}

# Function to create cleanup script
function New-CleanupScript {
    $cleanupScript = @'
$ErrorActionPreference = "Stop"
# Remove WasmEdge from PATH
$path = [Environment]::GetEnvironmentVariable("PATH", "Machine")
$wasmedgePath = if ($IsWindows) { "C:\Program Files\WasmEdge\bin" } else { "/usr/local/bin" }
$newPath = ($path.Split(';') | Where-Object { $_ -ne $wasmedgePath }) -join ';'
[Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")

# Remove WasmEdge environment variables
[Environment]::SetEnvironmentVariable("WASMEDGE_LIB_DIR", $null, "Machine")
[Environment]::SetEnvironmentVariable("WASMEDGE_INCLUDE_DIR", $null, "Machine")
'@
    
    $cleanupPath = "cleanup-wasmedge.ps1"
    Set-Content -Path $cleanupPath -Value $cleanupScript
    Write-Host "Created cleanup script at $cleanupPath"
}

# Main installation logic
try {
    if (Test-WasmEdgeInstalled) {
        Write-Host "WasmEdge is already installed"
    } else {
        Install-WasmEdgeSilently
        
        # Add WasmEdge to PATH if not already present
        $wasmedgeBinPath = if ($IsWindows) { "C:\Program Files\WasmEdge\bin" } else { "/usr/local/bin" }
        $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
        if ($currentPath -notlike "*$wasmedgeBinPath*") {
            $newPath = "$currentPath;$wasmedgeBinPath"
            [Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")
        }
        
        # Set WasmEdge environment variables
        $wasmedgeRoot = if ($IsWindows) { "C:\Program Files\WasmEdge" } else { "/usr/local" }
        [Environment]::SetEnvironmentVariable("WASMEDGE_LIB_DIR", (Join-Path $wasmedgeRoot "lib"), "Machine")
        [Environment]::SetEnvironmentVariable("WASMEDGE_INCLUDE_DIR", (Join-Path $wasmedgeRoot "include"), "Machine")
        
        Write-Host "WasmEdge installation completed successfully"
        New-CleanupScript
    }
} catch {
    Write-Error "Failed to install WasmEdge: $_"
    exit 1
} 
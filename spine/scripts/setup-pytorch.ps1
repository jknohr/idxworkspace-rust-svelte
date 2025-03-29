# Setup script for installing PyTorch C++ API (LibTorch)
param (
    [string]$Version = "2.2.1"
)

$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'

# Function to test if LibTorch is installed
function Test-LibTorchInstalled {
    if ($IsWindows) {
        $torchPath = "C:\Program Files\libtorch"
        $libPath = Join-Path $torchPath "lib\torch.dll"
    } else {
        $torchPath = "/usr/local/libtorch"
        $libPath = Join-Path $torchPath "lib/libtorch.so"
        if ($IsMacOS) {
            $libPath = Join-Path $torchPath "lib/libtorch.dylib"
        }
    }
    return (Test-Path $libPath)
}

# Function to install LibTorch silently
function Install-LibTorchSilently {
    $os = if ($IsWindows) { "windows" } elseif ($IsMacOS) { "darwin" } else { "linux" }
    $arch = if ([Environment]::Is64BitOperatingSystem) { "x86_64" } else { "x86" }
    $cuda = "cpu"  # Using CPU version for simplicity
    
    Write-Host "Installing LibTorch for $os-$arch..."
    
    # Create temporary directory
    $tempDir = Join-Path $env:TEMP "libtorch-install"
    New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
    
    switch ($os) {
        "windows" {
            $url = "https://download.pytorch.org/libtorch/cpu/libtorch-win-shared-with-deps-$Version%2Bcpu.zip"
            $zipFile = Join-Path $tempDir "libtorch.zip"
            $extractPath = "C:\Program Files"
            
            Write-Host "Downloading LibTorch..."
            Invoke-WebRequest -Uri $url -OutFile $zipFile
            
            Write-Host "Extracting LibTorch..."
            Expand-Archive -Path $zipFile -DestinationPath $extractPath -Force
            
            # Add DLL directory to PATH
            $dllPath = Join-Path $extractPath "libtorch\lib"
            $env:PATH = "$dllPath;$env:PATH"
            [Environment]::SetEnvironmentVariable("PATH", $env:PATH, "Machine")
        }
        "darwin" {
            $url = "https://download.pytorch.org/libtorch/cpu/libtorch-macos-$Version.zip"
            $zipFile = Join-Path $tempDir "libtorch.zip"
            
            Write-Host "Downloading LibTorch..."
            Invoke-WebRequest -Uri $url -OutFile $zipFile
            
            Write-Host "Extracting LibTorch..."
            Expand-Archive -Path $zipFile -DestinationPath "/usr/local" -Force
            
            # Set up symbolic links
            sudo ln -sf /usr/local/libtorch/lib/* /usr/local/lib/
            sudo ln -sf /usr/local/libtorch/include/* /usr/local/include/
        }
        "linux" {
            $url = "https://download.pytorch.org/libtorch/cpu/libtorch-cxx11-abi-shared-with-deps-$Version%2Bcpu.zip"
            $zipFile = Join-Path $tempDir "libtorch.zip"
            
            Write-Host "Downloading LibTorch..."
            Invoke-WebRequest -Uri $url -OutFile $zipFile
            
            Write-Host "Extracting LibTorch..."
            Expand-Archive -Path $zipFile -DestinationPath "/usr/local" -Force
            
            # Update shared library cache
            sudo ldconfig
        }
    }
    
    # Cleanup
    Remove-Item -Recurse -Force $tempDir
    
    # Verify installation
    if (-not (Test-LibTorchInstalled)) {
        throw "LibTorch installation failed"
    }
}

# Function to create cleanup script
function New-CleanupScript {
    $cleanupScript = @'
$ErrorActionPreference = "Stop"

# Remove LibTorch files
if ($IsWindows) {
    Remove-Item -Recurse -Force "C:\Program Files\libtorch" -ErrorAction SilentlyContinue
} else {
    sudo rm -rf /usr/local/libtorch
    sudo rm -f /usr/local/lib/libtorch*
    sudo rm -f /usr/local/include/torch
    if (-not $IsMacOS) {
        sudo ldconfig
    }
}

# Remove from PATH on Windows
if ($IsWindows) {
    $path = [Environment]::GetEnvironmentVariable("PATH", "Machine")
    $torchPath = "C:\Program Files\libtorch\lib"
    $newPath = ($path.Split(';') | Where-Object { $_ -ne $torchPath }) -join ';'
    [Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")
}
'@
    
    $cleanupPath = "cleanup-pytorch.ps1"
    Set-Content -Path $cleanupPath -Value $cleanupScript
    Write-Host "Created cleanup script at $cleanupPath"
}

# Main installation logic
try {
    if (Test-LibTorchInstalled) {
        Write-Host "LibTorch is already installed"
    } else {
        Install-LibTorchSilently
        Write-Host "LibTorch installation completed successfully"
        New-CleanupScript
        
        # Set environment variables
        $torchPath = if ($IsWindows) {
            "C:\Program Files\libtorch"
        } else {
            "/usr/local/libtorch"
        }
        
        [Environment]::SetEnvironmentVariable("TORCH_ROOT", $torchPath, "Machine")
        Write-Host "Environment variables set successfully"
    }
} catch {
    Write-Error "Failed to install LibTorch: $_"
    exit 1
} 
# Setup script for installing TensorFlow C API
param (
    [string]$Version = "2.15.0"
)

$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'

# Function to test if TensorFlow C API is installed
function Test-TensorFlowInstalled {
    if ($IsWindows) {
        $tfPath = "C:\Program Files\tensorflow"
        $libPath = Join-Path $tfPath "lib\tensorflow.dll"
    } else {
        $tfPath = "/usr/local/lib"
        $libPath = Join-Path $tfPath "libtensorflow.so"
        if ($IsMacOS) {
            $libPath = Join-Path $tfPath "libtensorflow.dylib"
        }
    }
    return (Test-Path $libPath)
}

# Function to install TensorFlow C API silently
function Install-TensorFlowSilently {
    $os = if ($IsWindows) { "windows" } elseif ($IsMacOS) { "darwin" } else { "linux" }
    $arch = if ([Environment]::Is64BitOperatingSystem) { "x86_64" } else { "x86" }
    
    Write-Host "Installing TensorFlow C API for $os-$arch..."
    
    # Create temporary directory
    $tempDir = Join-Path $env:TEMP "tensorflow-install"
    New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
    
    switch ($os) {
        "windows" {
            $url = "https://storage.googleapis.com/tensorflow/libtensorflow/libtensorflow-cpu-windows-$arch-$Version.zip"
            $zipFile = Join-Path $tempDir "tensorflow.zip"
            $extractPath = "C:\Program Files\tensorflow"
            
            Write-Host "Downloading TensorFlow C API..."
            Invoke-WebRequest -Uri $url -OutFile $zipFile
            
            Write-Host "Extracting TensorFlow C API..."
            Expand-Archive -Path $zipFile -DestinationPath $extractPath -Force
            
            # Add DLL directory to PATH
            $dllPath = Join-Path $extractPath "lib"
            $env:PATH = "$dllPath;$env:PATH"
            [Environment]::SetEnvironmentVariable("PATH", $env:PATH, "Machine")
        }
        "darwin" {
            # For macOS, we build from source using bazel
            if (-not (Get-Command bazel -ErrorAction SilentlyContinue)) {
                Write-Host "Installing Bazel..."
                brew install bazel
            }
            
            Write-Host "Cloning TensorFlow repository..."
            Set-Location $tempDir
            git clone https://github.com/tensorflow/tensorflow.git
            Set-Location tensorflow
            git checkout "v$Version"
            
            Write-Host "Configuring TensorFlow build..."
            python configure.py
            
            Write-Host "Building TensorFlow C API..."
            bazel build --config=opt //tensorflow:libtensorflow.so
            
            Write-Host "Installing TensorFlow C API..."
            sudo cp bazel-bin/tensorflow/libtensorflow.so /usr/local/lib/
            sudo cp -r bazel-bin/tensorflow/include /usr/local/include/tensorflow
        }
        "linux" {
            $url = "https://storage.googleapis.com/tensorflow/libtensorflow/libtensorflow-cpu-linux-$arch-$Version.tar.gz"
            $tarFile = Join-Path $tempDir "tensorflow.tar.gz"
            
            Write-Host "Downloading TensorFlow C API..."
            Invoke-WebRequest -Uri $url -OutFile $tarFile
            
            Write-Host "Extracting TensorFlow C API..."
            tar -C /usr/local -xzf $tarFile
            
            # Update shared library cache
            sudo ldconfig
        }
    }
    
    # Cleanup
    Remove-Item -Recurse -Force $tempDir
    
    # Verify installation
    if (-not (Test-TensorFlowInstalled)) {
        throw "TensorFlow C API installation failed"
    }
}

# Function to create cleanup script
function New-CleanupScript {
    $cleanupScript = @'
$ErrorActionPreference = "Stop"

# Remove TensorFlow files
if ($IsWindows) {
    Remove-Item -Recurse -Force "C:\Program Files\tensorflow" -ErrorAction SilentlyContinue
} else {
    sudo rm -f /usr/local/lib/libtensorflow*
    sudo rm -rf /usr/local/include/tensorflow
    if (-not $IsMacOS) {
        sudo ldconfig
    }
}

# Remove from PATH on Windows
if ($IsWindows) {
    $path = [Environment]::GetEnvironmentVariable("PATH", "Machine")
    $tfPath = "C:\Program Files\tensorflow\lib"
    $newPath = ($path.Split(';') | Where-Object { $_ -ne $tfPath }) -join ';'
    [Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")
}
'@
    
    $cleanupPath = "cleanup-tensorflow.ps1"
    Set-Content -Path $cleanupPath -Value $cleanupScript
    Write-Host "Created cleanup script at $cleanupPath"
}

# Main installation logic
try {
    if (Test-TensorFlowInstalled) {
        Write-Host "TensorFlow C API is already installed"
    } else {
        Install-TensorFlowSilently
        Write-Host "TensorFlow C API installation completed successfully"
        New-CleanupScript
    }
} catch {
    Write-Error "Failed to install TensorFlow C API: $_"
    exit 1
} 
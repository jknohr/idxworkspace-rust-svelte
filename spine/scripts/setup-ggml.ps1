# Setup script for installing GGML
param (
    [string]$Version = "master"
)

$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'

# Function to test if GGML is installed
function Test-GGMLInstalled {
    $ggmlPath = "C:\Program Files\ggml"
    $ggmlLibPath = Join-Path $ggmlPath "lib\ggml.lib"
    return (Test-Path $ggmlLibPath)
}

# Function to install GGML silently
function Install-GGMLSilently {
    $ggmlDir = "C:\Program Files\ggml"
    $libDir = Join-Path $ggmlDir "lib"
    $includeDir = Join-Path $ggmlDir "include"
    $buildDir = Join-Path $ggmlDir "build"
    
    # Create directories
    New-Item -ItemType Directory -Force -Path $libDir
    New-Item -ItemType Directory -Force -Path $includeDir
    New-Item -ItemType Directory -Force -Path $buildDir
    
    # Clone GGML repository
    $repoUrl = "https://github.com/ggerganov/ggml.git"
    $repoPath = Join-Path $env:TEMP "ggml"
    
    Write-Host "Cloning GGML repository..."
    git clone --depth 1 --branch $Version $repoUrl $repoPath
    
    # Build GGML
    Push-Location $repoPath
    try {
        Write-Host "Configuring GGML build..."
        cmake -S . -B build -G "Visual Studio 17 2022" -A x64 `
            -DCMAKE_BUILD_TYPE=Release `
            -DBUILD_SHARED_LIBS=ON `
            -DGGML_BUILD_TESTS=OFF
        
        Write-Host "Building GGML..."
        cmake --build build --config Release
        
        # Copy files to installation directory
        Write-Host "Installing GGML..."
        Copy-Item "build\bin\Release\*.dll" -Destination $libDir
        Copy-Item "build\lib\Release\*.lib" -Destination $libDir
        Copy-Item "include\*.h" -Destination $includeDir
    } finally {
        Pop-Location
        Remove-Item -Path $repoPath -Recurse -Force
    }
    
    # Verify installation
    if (-not (Test-GGMLInstalled)) {
        throw "GGML installation failed"
    }
}

# Function to create cleanup script
function New-CleanupScript {
    $cleanupScript = @'
$ErrorActionPreference = "Stop"
# Remove GGML from PATH
$path = [Environment]::GetEnvironmentVariable("PATH", "Machine")
$ggmlPath = "C:\Program Files\ggml\lib"
$newPath = ($path.Split(';') | Where-Object { $_ -ne $ggmlPath }) -join ';'
[Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")

# Remove GGML_DIR
[Environment]::SetEnvironmentVariable("GGML_DIR", $null, "Machine")
'@
    
    $cleanupPath = "cleanup-ggml.ps1"
    Set-Content -Path $cleanupPath -Value $cleanupScript
    Write-Host "Created cleanup script at $cleanupPath"
}

# Check for required tools
function Test-Prerequisites {
    $requirements = @(
        @{Name = "Git"; Command = "git --version"},
        @{Name = "CMake"; Command = "cmake --version"},
        @{Name = "Visual Studio"; Command = "where cl.exe"}
    )
    
    foreach ($req in $requirements) {
        Write-Host "Checking for $($req.Name)..."
        if (-not (Invoke-Expression $req.Command -ErrorAction SilentlyContinue)) {
            throw "$($req.Name) is required but not found"
        }
    }
}

# Main installation logic
try {
    Test-Prerequisites
    
    if (Test-GGMLInstalled) {
        Write-Host "GGML is already installed"
    } else {
        Install-GGMLSilently
        
        # Add GGML to PATH if not already present
        $ggmlLibPath = "C:\Program Files\ggml\lib"
        $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
        if ($currentPath -notlike "*$ggmlLibPath*") {
            $newPath = "$currentPath;$ggmlLibPath"
            [Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")
        }
        
        # Set GGML_DIR
        [Environment]::SetEnvironmentVariable("GGML_DIR", "C:\Program Files\ggml", "Machine")
        
        Write-Host "GGML installation completed successfully"
        New-CleanupScript
    }
} catch {
    Write-Error "Failed to install GGML: $_"
    exit 1
} 
# Build script for SSR WASM module
param (
    [switch]$Release,
    [switch]$Watch
)

$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'

# Ensure required tools are installed
function Install-Requirements {
    Write-Host "Checking and installing required tools..."

    # Check for wasm-pack
    if (-not (Get-Command wasm-pack -ErrorAction SilentlyContinue)) {
        Write-Host "Installing wasm-pack..."
        cargo install wasm-pack
    }

    # Check for wasm-bindgen-cli
    if (-not (Get-Command wasm-bindgen -ErrorAction SilentlyContinue)) {
        Write-Host "Installing wasm-bindgen-cli..."
        cargo install wasm-bindgen-cli
    }

    # Check for wasm-opt
    if (-not (Get-Command wasm-opt -ErrorAction SilentlyContinue)) {
        Write-Host "Installing binaryen (for wasm-opt)..."
        if ($IsWindows) {
            # Download and extract binaryen
            $binaryenVersion = "version_111"
            $url = "https://github.com/WebAssembly/binaryen/releases/download/$binaryenVersion/binaryen-$binaryenVersion-x86_64-windows.tar.gz"
            $tempFile = Join-Path $env:TEMP "binaryen.tar.gz"
            Invoke-WebRequest -Uri $url -OutFile $tempFile
            tar -xzf $tempFile -C $env:TEMP
            $binPath = Join-Path $env:TEMP "binaryen-$binaryenVersion"
            $env:PATH = "$binPath;$env:PATH"
        } elseif ($IsMacOS) {
            brew install binaryen
        } else {
            sudo apt-get update
            sudo apt-get install -y binaryen
        }
    }
}

# Build the SSR WASM module
function Build-SSRModule {
    param (
        [string]$BuildType = "debug"
    )

    Write-Host "Building SSR WASM module ($BuildType)..."
    Set-Location crates/spine-ssr

    if ($BuildType -eq "release") {
        wasm-pack build --target web --release
    } else {
        wasm-pack build --target web --dev
    }

    # Optimize the WASM binary if in release mode
    if ($BuildType -eq "release") {
        Write-Host "Optimizing WASM binary..."
        $wasmFile = "pkg/spine_ssr_bg.wasm"
        wasm-opt -O3 -o "$wasmFile.opt" $wasmFile
        Move-Item "$wasmFile.opt" $wasmFile -Force
    }

    # Copy the output to the interface directory
    Write-Host "Copying WASM module to interface..."
    $targetDir = "../../interface/static/wasm"
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Force -Path $targetDir
    }
    Copy-Item "pkg/*" $targetDir -Force -Recurse

    Set-Location ../..
}

# Watch for changes and rebuild
function Watch-AndBuild {
    Write-Host "Watching for changes..."
    while ($true) {
        $changes = $false
        
        Get-ChildItem -Recurse -Path "crates/spine-ssr/src" -Filter "*.rs" | ForEach-Object {
            $lastWrite = $_.LastWriteTime
            $path = $_.FullName
            
            # Store the last write time if we haven't seen this file before
            if (-not $script:lastWrites.ContainsKey($path)) {
                $script:lastWrites[$path] = $lastWrite
                $changes = $true
            }
            # Check if the file has been modified
            elseif ($script:lastWrites[$path] -ne $lastWrite) {
                $script:lastWrites[$path] = $lastWrite
                $changes = $true
            }
        }
        
        if ($changes) {
            Write-Host "`nChanges detected, rebuilding..."
            Build-SSRModule -BuildType $(if ($Release) { "release" } else { "debug" })
        }
        
        Start-Sleep -Seconds 2
    }
}

# Main execution
try {
    Install-Requirements

    # Initialize the last write times hash table for watch mode
    $script:lastWrites = @{}

    if ($Watch) {
        Watch-AndBuild
    } else {
        Build-SSRModule -BuildType $(if ($Release) { "release" } else { "debug" })
    }

    Write-Host "Build completed successfully!"
} catch {
    Write-Error "Build failed: $_"
    exit 1
} 
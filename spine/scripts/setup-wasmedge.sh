#!/bin/bash

# Setup script for WasmEdge and LLVM installation on Unix-like systems
# This script checks if WasmEdge and LLVM are installed and installs them if needed

# Function to check if WasmEdge is installed
check_wasmedge() {
    if command -v wasmedge >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to check if LLVM/libclang is installed
check_llvm() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if [ -d "/usr/local/opt/llvm/lib" ]; then
            return 0
        fi
    else
        # Linux
        if ldconfig -p | grep -q libclang; then
            return 0
        fi
    fi
    return 1
}

# Function to install WasmEdge
install_wasmedge() {
    echo "Installing WasmEdge..."
    
    # Detect OS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew >/dev/null 2>&1; then
            brew install wasmedge
        else
            echo "Homebrew is required to install WasmEdge on macOS"
            echo "Please install Homebrew first: https://brew.sh"
            exit 1
        fi
    else
        # Linux
        if command -v curl >/dev/null 2>&1; then
            curl -sSf https://raw.githubusercontent.com/WasmEdge/WasmEdge/master/utils/install.sh | bash
        else
            echo "curl is required to install WasmEdge"
            echo "Please install curl first"
            exit 1
        fi
    fi
}

# Function to install LLVM/libclang
install_llvm() {
    echo "Installing LLVM/libclang..."
    
    # Detect OS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew >/dev/null 2>&1; then
            brew install llvm
        else
            echo "Homebrew is required to install LLVM on macOS"
            echo "Please install Homebrew first: https://brew.sh"
            exit 1
        fi
    else
        # Linux
        if command -v apt-get >/dev/null 2>&1; then
            # Debian/Ubuntu
            sudo apt-get update
            sudo apt-get install -y libclang-dev
        elif command -v dnf >/dev/null 2>&1; then
            # Fedora
            sudo dnf install -y clang-devel
        elif command -v pacman >/dev/null 2>&1; then
            # Arch Linux
            sudo pacman -S --noconfirm clang
        else
            echo "Unsupported Linux distribution"
            echo "Please install libclang-dev manually"
            exit 1
        fi
    fi
}

# Function to create cleanup script
create_cleanup_script() {
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    CLEANUP_SCRIPT="$SCRIPT_DIR/cleanup-env.sh"
    
    cat > "$CLEANUP_SCRIPT" << 'EOF'
#!/bin/bash

# Cleanup script for environment variables set by setup-wasmedge.sh
# This script removes environment variables set during the build process

echo "Cleaning up environment variables..."

# Unset environment variables
unset WASMEDGE_INCLUDE_DIR
unset WASMEDGE_LIB_DIR
unset LIBCLANG_PATH

echo "Environment variables cleaned up successfully."
EOF
    
    chmod +x "$CLEANUP_SCRIPT"
    echo "Created cleanup script at: $CLEANUP_SCRIPT"
}

# Main script
echo "Checking WasmEdge installation..."

ENV_CHANGED=0

# Check and install WasmEdge if needed
if check_wasmedge; then
    echo "WasmEdge is already installed."
    wasmedge --version
else
    echo "WasmEdge is not installed. Installing..."
    install_wasmedge
    if check_wasmedge; then
        echo "WasmEdge installed successfully."
        ENV_CHANGED=1
    else
        echo "Failed to install WasmEdge."
        exit 1
    fi
fi

# Check and install LLVM if needed
echo "Checking LLVM installation..."
if check_llvm; then
    echo "LLVM/libclang is already installed."
else
    echo "LLVM/libclang is not installed. Installing..."
    install_llvm
    if check_llvm; then
        echo "LLVM/libclang installed successfully."
        ENV_CHANGED=1
    else
        echo "Failed to install LLVM/libclang."
        exit 1
    fi
fi

# Set environment variables for the current process
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    if [ -d "/usr/local/opt/wasmedge" ]; then
        export WASMEDGE_INCLUDE_DIR="/usr/local/opt/wasmedge/include"
        export WASMEDGE_LIB_DIR="/usr/local/opt/wasmedge/lib"
        echo "Set WASMEDGE_INCLUDE_DIR=$WASMEDGE_INCLUDE_DIR"
        echo "Set WASMEDGE_LIB_DIR=$WASMEDGE_LIB_DIR"
        ENV_CHANGED=1
    fi
    
    if [ -d "/usr/local/opt/llvm" ]; then
        export LIBCLANG_PATH="/usr/local/opt/llvm/lib"
        echo "Set LIBCLANG_PATH=$LIBCLANG_PATH"
        ENV_CHANGED=1
    fi
else
    # Linux
    if [ -d "/usr/local/include/wasmedge" ]; then
        export WASMEDGE_INCLUDE_DIR="/usr/local/include"
        export WASMEDGE_LIB_DIR="/usr/local/lib"
        echo "Set WASMEDGE_INCLUDE_DIR=$WASMEDGE_INCLUDE_DIR"
        echo "Set WASMEDGE_LIB_DIR=$WASMEDGE_LIB_DIR"
        ENV_CHANGED=1
    fi
    
    # On Linux, libclang should be in the system path
    # but we'll set it explicitly if we can find it
    if [ -d "/usr/lib/llvm-14/lib" ]; then
        export LIBCLANG_PATH="/usr/lib/llvm-14/lib"
        echo "Set LIBCLANG_PATH=$LIBCLANG_PATH"
        ENV_CHANGED=1
    fi
fi

# Create cleanup script if environment was changed
if [ $ENV_CHANGED -eq 1 ]; then
    create_cleanup_script
fi

echo "Setup completed successfully." 
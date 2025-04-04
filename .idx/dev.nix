# .idx/dev.nix
# Defines the development environment for the NeuralUI/Spine workspace.
# This file is typically generated by an idx-template.nix bootstrap script.

{ pkgs, lib, ... }:

let
  # --- Define specific versions/toolchains ---
  # Using Node.js 21 as requested
  nodeJs = pkgs.nodejs-21_x;

  # LLVM/Clang version (adjust if needed)
  llvmVersion = "17";
  llvmPkgs = pkgs."llvmPackages_${llvmVersion}"; # Use attribute set access

  # Stable Rust toolchain with source for rust-analyzer
  rustToolchain = pkgs.rust-bin.stable.latest.default.override {
    extensions = [ "rust-src" ]; # Essential for rust-analyzer completions/goto-def
    # Add other components like "clippy" or "rustfmt" if desired by default:
    # extensions = [ "rust-src" "clippy" "rustfmt" ];
  };

in {
  # Nix Packages channel to use for 'pkgs'
  channel = "stable-23.11"; # Or "stable-24.05" if preferred/needed

  # --- Nix Packages available in the environment PATH ---
  packages = [
    # --- Core Development & Build Tools ---
    pkgs.git # Version control
    pkgs.gcc # C/C++ Compiler (GNU)
    # pkgs.clang # Alternative C/C++ Compiler (Clang, often covered by llvmPkgs.clang)
    pkgs.gdb # Debugger
    pkgs.cmake # Build system generator (for C++/GGML)
    pkgs.pkg-config # Helps build tools find libraries
    pkgs.make # Common build utility
    pkgs.ninja # Alternative faster build system (used by some CMake projects)
    pkgs.protobuf # Protocol Buffers compiler (often needed for gRPC/ML)

    # --- Frontend (NeuralUI) ---
    nodeJs # Node.js v21 runtime
    pkgs.nodePackages.npm # Node Package Manager (comes with Node.js usually)
    # pkgs.yarn # Uncomment if you prefer Yarn

    # --- Backend (Spine - C++/Rust) ---
    # C++ / LLVM Related
    (llvmPkgs.llvm.override { enableManpages = false; }) # LLVM Toolchain
    llvmPkgs.libclang # Clang library (needed by some tools/bindings)
    # Rust Related
    rustToolchain # Rust compiler (rustc) and package manager (cargo)
    pkgs.lld # Linker from LLVM project, often faster for Rust builds
    pkgs.openssl.dev # Development headers for OpenSSL (very common Rust dependency)
    pkgs.opus.dev # <<<< Opus library development files (headers/libs) for Rust crates

    # --- AI/ML Runtime & Scripting Dependencies ---
    pkgs.wasmedge # WasmEdge Runtime
    pkgs.powershell # PowerShell Core (for running setup scripts)
    pkgs.python3 # Often useful for helper scripts or ML tooling

    # --- Utilities ---
    pkgs.coreutils # Basic utils (ls, cp, mkdir, etc.) - usually implicitly available
    pkgs.curl # Tool for downloading files via HTTP(S)
    pkgs.wget # Alternative download tool
    pkgs.gnutar # For extracting .tar archives
    pkgs.unzip # For extracting .zip archives
    pkgs.jq # Command-line JSON processor
    pkgs.htop # Interactive process viewer
    pkgs.ripgrep # Fast code searching tool
    pkgs.fd # Fast alternative to `find`
  ];

  # --- Environment Variables ---
  environment.variables = {
    # Example: Set Node.js environment
    NODE_ENV = "development";

    # Set path for libclang if required by specific tools (often found automatically)
    # LIBCLANG_PATH = "${llvmPkgs.libclang.lib}/lib";

    # --- PLACEHOLDERS for Manually Installed Libraries ---
    # These need to be uncommented/set AFTER running the setup scripts
    # and then rebuilding the environment (Cmd+Shift+P -> IDX: Rebuild Env)
    # LIBTORCH_ROOT = "/workspace/spine/deps/libtorch";
    # TENSORFLOW_ROOT = "/workspace/spine/deps/tensorflow";
    # GGML_DIR = "/workspace/spine/deps/ggml";

    # Optional: Hint for reproducible builds
    SOURCE_DATE_EPOCH = "0";
  };

  # --- Shell Hook ---
  # Runs commands when the shell starts. Useful for PATH modifications.
  environment.shellHook = ''
    echo "Welcome to the NeuralUI/Spine IDX Environment!"
    # --- PLACEHOLDERS for Manually Installed Libraries ---
    # Uncomment and adjust paths AFTER running setup scripts and placing libs
    # export LD_LIBRARY_PATH="/workspace/spine/deps/libtorch/lib:$LD_LIBRARY_PATH"
    # export LD_LIBRARY_PATH="/workspace/spine/deps/tensorflow/lib:$LD_LIBRARY_PATH"
    # export LD_LIBRARY_PATH="/workspace/spine/deps/ggml/lib:$LD_LIBRARY_PATH" # Adjust GGML lib path as needed
  '';

  # --- Recommended VS Code Extensions ---
  idx.extensions = [
    # General
    "github.copilot" # Or github.copilot-chat
    "ms-vscode.powershell"
    "esbenp.prettier-vscode" # Code formatter

    # C/C++
    "vscode.cpptools" # IntelliSense, debugging
    "ms-vscode.cmake-tools" # CMake integration
    "cheshirekow.cmake-format" # Formatting CMake files

    # Rust
    "rust-lang.rust-analyzer" # Language server (essential)
    "tamasfe.even-better-toml" # TOML file support (for Cargo.toml)
    "serayuzgur.crates" # Helps manage Cargo dependencies

    # Node.js / Frontend
    "dbaeumer.vscode-eslint" # JavaScript/TypeScript linter
    # Add framework-specific extensions if needed (e.g., Vue, React)
  ];

  # --- Workspace Lifecycle Hooks ---
  idx.workspace = {
    # Runs ONCE when the workspace is first created.
    onCreate = {
      # 1. Install frontend dependencies
      install-frontend-deps = "echo 'Installing frontend dependencies...' && cd neuralui && npm install && cd ..";

      # 2. Run setup scripts for complex backend dependencies
      #    Requires MODIFIED PowerShell scripts placed in /workspace/spine/scripts
      info-backend-deps = ''
        echo ""
        echo "---------------------------------------------------------"
        echo " Running Backend AI/ML Dependency Setup Scripts... "
        echo " Using PowerShell scripts from /workspace/spine/scripts/ "
        echo "---------------------------------------------------------"
        echo "This will download/build LibTorch, TensorFlow C API, and GGML."
        echo "Ensure the scripts are modified for Linux/IDX and install"
        echo "dependencies into '/workspace/spine/deps/'."
        echo "Monitor the output below for success or errors."
        echo "---------------------------------------------------------"
      '';
      # Make sure these script paths exist in your template source
      setup-libtorch = "pwsh -NoProfile -File /workspace/spine/scripts/setup_libtorch.ps1";
      setup-tensorflow = "pwsh -NoProfile -File /workspace/spine/scripts/setup_tensorflow.ps1";
      setup-ggml = "pwsh -NoProfile -File /workspace/spine/scripts/setup_ggml.ps1";

      # 3. Provide clear instructions for the necessary manual step
      final-instructions = ''
        echo ""
        echo "---------------------------------------------------------"
        echo " ACTION REQUIRED: Finalize Backend Setup "
        echo "---------------------------------------------------------"
        echo "The setup scripts have attempted to download/build backend libraries."
        echo "1. Check the output above for any errors during script execution."
        echo "2. Verify that libraries exist in '/workspace/spine/deps/'."
        echo "3. **Edit this file (.idx/dev.nix):**"
        echo "   - Uncomment and set the correct *_ROOT variables under 'environment.variables'."
        echo "   - Uncomment and set the correct library paths under 'environment.shellHook' for LD_LIBRARY_PATH."
        echo "4. **Rebuild the Environment:**"
        echo "   - Press Cmd+Shift+P (or Ctrl+Shift+P)"
        echo "   - Type 'IDX: Rebuild Environment' and select it."
        echo "---------------------------------------------------------"
        echo ""
      '';

      # 4. Files to open automatically on first workspace creation
      default.openFiles = [
        ".idx/dev.nix"         # Open this file first for editing env vars
        "README.md"            # Project overview
        "neuralui/package.json"
        "spine/Cargo.toml"     # Assuming Rust backend uses Cargo
        # "spine/CMakeLists.txt" # If using CMake for C++ parts
      ];
    };

    # Runs EVERY time the workspace starts (including restarts).
    onStart = {
      # Example: Check if backend deps setup seems complete (basic check)
      check-backend-vars = ''
        if [[ "$LIBTORCH_ROOT" == "" ]]; then
          echo "Reminder: Backend dependency variables (e.g., LIBTORCH_ROOT) may need to be set in .idx/dev.nix. Rebuild environment after editing."
        fi
      '';
      # Optional: Re-open key files on every start
      # default.openFiles = [ ".idx/dev.nix", "spine/src/main.rs" ];
    };
  };

  # --- IDX Previews Configuration ---
  idx.previews = {
    enable = true; # Enable the previews panel
    previews = [
      {
        # Example preview for the NeuralUI frontend dev server
        id = "neuralui-dev";
        label = "NeuralUI Dev";
        # Adjust command based on your package.json scripts
        command = ["npm", "run", "dev", "--", "--port", "$PORT"];
        manager = "web"; # Use 'web' for web servers
        cwd = "neuralui"; # Run command in the frontend directory
        env = { # Optional: specific environment variables for this preview
          # EXAMPLE_VAR = "example_value";
        };
      }
      # Add a preview for the Spine backend if it runs a server process
      # {
      #   id = "spine-server";
      #   label = "Spine Backend";
      #   # Adjust command based on how you run your backend
      #   command = ["cargo", "run"]; # Example for Rust
      #   # command = ["./build/spine_executable"]; # Example for C++ executable
      #   manager = "process"; # Use 'process' for non-web backend processes
      #   cwd = "spine";
      # }
    ];
  };

  # --- Optional Services (Database, etc.) ---
  # services.postgres = { enable = true; extensions = ["pgvector"]; };
  # services.redis = { enable = true; };
  # services.docker = { enable = true; }; # Uncomment if you decide you need the Docker CLI later

}

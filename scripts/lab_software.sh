#!/bin/bash

function jupyter_soft_install() {
	goodecho "[+] Installing Jupyter Notebook"
	install_dependencies "jupyter-notebook"
}


function ml_and_dl_soft_install() {
    goodecho "[+] Installing ML/DL tools in virtual environment"

    # Define paths
    MLDL_VENV_DIR="/opt/mldl"
    MLDL_WRAPPER="/usr/sbin/mldl"

    # Install system dependencies
    install_dependencies "python3-venv python3-dev build-essential"

    # Clean up any existing installation
    rm -rf "$MLDL_VENV_DIR" "$MLDL_WRAPPER"

    # Create directory
    mkdir -p "$MLDL_VENV_DIR"

    # Create virtual environment
    goodecho "[+] Creating Python virtual environment"
    python3 -m venv "$MLDL_VENV_DIR/venv"
    if [ $? -ne 0 ]; then
        criticalecho "[!] Failed to create virtual environment"
        return 1
    fi

    # Install ML/DL packages in the virtual environment
    goodecho "[+] Installing ML/DL dependencies"
    source "$MLDL_VENV_DIR/venv/bin/activate"

    # Upgrade pip first
    pip install --upgrade pip
    
    # Install ML/DL packages
    pip install scikit-learn pandas seaborn tensorflow
    pip install "numpy"
    
    MLDL_INSTALL_STATUS=$?
    deactivate

    if [ $MLDL_INSTALL_STATUS -ne 0 ]; then
        criticalecho "[!] Failed to install ML/DL packages"
        return 1
    fi

    # Create simple activation wrapper script
    goodecho "[+] Creating ML/DL activation script"
    cat > "$MLDL_WRAPPER" << 'EOF'
#!/bin/bash

# ML/DL Environment Activation Script
MLDL_VENV_DIR="/opt/mldl/venv"

if [ ! -d "$MLDL_VENV_DIR" ]; then
    echo "Error: ML/DL virtual environment not found at $MLDL_VENV_DIR"
    exit 1
fi

source "$MLDL_VENV_DIR/bin/activate"
echo "[+] ML/DL virtual environment activated"
echo "[INFO] Use 'deactivate' to exit the environment"

# Start a new shell to keep the environment active
exec "$SHELL"
EOF

    # Make wrapper executable
    chmod +x "$MLDL_WRAPPER"

    # Set proper ownership
    chown root:root "$MLDL_WRAPPER"
    chown -R root:root "$MLDL_VENV_DIR"

    goodecho "[+] ML/DL environment installation completed successfully"
    goodecho "[+] Use 'mldl' to activate the environment"

    return 0
}
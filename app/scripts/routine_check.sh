#!/bin/bash

# Get the current directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Source configuration and common functions
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/common.sh"

# Get current timestamp for logging
timestamp=$(date +"%Y-%m-%d %H:%M:%S")

# Check connectivity first
check_connectivity "$MACHINE" "$PORT"

# Path to local scripts with absolute paths
CONNECT_SCRIPT="$SCRIPT_DIR/connect.sh"
SETUP_SCRIPT="$SCRIPT_DIR/setup.sh"
DEPLOY_SCRIPT="$SCRIPT_DIR/deploy.sh"

# Log start
echo "[$timestamp] Starting SSH connectivity check..."

# Check SSH connection using custom key
if ! check_ssh "$CUSTOM_KEY" "$USER" "$MACHINE" "$PORT"; then
    echo "[$timestamp] SSH connection failed. Machine has probably been reset. Attempting redeployment..."
    
    # Run connect.sh, setup.sh, and deploy.sh in sequence
    echo "[$timestamp] Running connect.sh..."
    bash "$CONNECT_SCRIPT"
    
    echo "[$timestamp] Running setup.sh..."
    bash "$SETUP_SCRIPT"
    
    echo "[$timestamp] Running deploy.sh..."
    bash "$DEPLOY_SCRIPT"
    
    echo "[$timestamp] Redeployment completed."
else
    echo "[$timestamp] SSH connection successful. Remote is up and accessible with the custom key. No action taken."
fi

#!/bin/bash

# Source configuration and common functions
source config.sh
source common.sh

# Check connectivity first
check_connectivity "$MACHINE" "$PORT"

# Check SSH connection
if ! check_ssh "$CUSTOM_KEY" "$USER" "$MACHINE" "$PORT"; then
    echo "SSH connection failed. Please run connect.sh to check connectivity first."
    exit 1
fi

# SCP the remote setup script to the remote machine
echo "Copying remote_setup.sh to the remote machine..."
scp -i "$CUSTOM_KEY" -P "$PORT" ./remote_setup.sh "$USER@$MACHINE:$SETUP_DIR"

# Execute the remote setup script on the remote machine in the setup directory
echo "Executing remote setup script..."
ssh -i "$CUSTOM_KEY" -p "$PORT" "$USER@$MACHINE" "bash $SETUP_DIR/remote_setup.sh '$PROJECT_DIR' '$PYTHON_VERSION' '$ASDF_VERSION' '$REPO_URL' '$SETUP_DIR'"

# Notify the user of the setup completion
echo "Remote setup completed."

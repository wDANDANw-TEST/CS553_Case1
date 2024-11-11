#!/bin/bash

# Source configuration and common functions
source config.sh
source common.sh

# Local vars
APP_ENTRYPOINT="app.py"

# Check connectivity first
check_connectivity "$MACHINE" "$PORT"

# Check SSH connection
if ! check_ssh "$CUSTOM_KEY" "$USER" "$MACHINE" "$PORT"; then
    echo "SSH connection failed. Please run connect.sh to check connectivity first."
    exit 1
fi

# Copy the remote deployment script to the remote machine
echo "Copying remote_deploy.sh to the remote machine..."
scp -i "$CUSTOM_KEY" -P "$PORT" ./remote_deploy.sh "$USER@$MACHINE:$SETUP_DIR"

# Execute the remote deployment script
echo "Executing the remote deployment script..."
ssh -t -i "$CUSTOM_KEY" -p "$PORT" "$USER@$MACHINE" bash $SETUP_DIR/remote_deploy.sh "$PROJECT_DIR" "$APP_ENTRYPOINT"

echo "Deployment completed on remote machine."
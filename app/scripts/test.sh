#!/bin/bash

# Source configuration and common functions
source config.sh
source common.sh

# Check connectivity first
check_connectivity

# Check SSH connection
if ! check_ssh "$CUSTOM_KEY" "$USER" "$MACHINE" "$PORT"; then
    echo "SSH connection failed. Please run connect.sh to check connectivity first."
    exit 1
fi

# Todo: Add tests to test ports & DNS
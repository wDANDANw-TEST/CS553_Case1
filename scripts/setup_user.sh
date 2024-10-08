#!/bin/bash

# setup_user.sh

# Parameters
USER_TO_ADD="$1"
PRESET_USER="$2"
CUSTOM_PUB_KEY="$3"
PRESET_PUB_KEY="$4"
REMOVE_PRESET_KEY="$5"
SETUP_DIR="$6"

# Function to check if sudo can be run without a password
check_sudo_nopasswd() {
    if ! sudo -n true 2>/dev/null; then
        echo "Error: Preset user cannot run sudo without a password."
        exit 1
    fi
}

# Function to check if the SSH key already exists in authorized_keys
check_key_in_authorized() {
    
    local key="$1"
    local user="$2"

    sudo grep -qF "$key" /home/$user/.ssh/authorized_keys 2>/dev/null
}

# Function to set up SSH directory and authorized_keys for the existing user
setup_user() {
    # Create .ssh directory if not present
    sudo mkdir -p /home/$USER_TO_ADD/.ssh

    # Check if the key is already present, if not, append the key
    if check_key_in_authorized "$CUSTOM_PUB_KEY" "$USER_TO_ADD"; then
        echo "SSH key already exists for $USER_TO_ADD. No action needed."
    else
        echo "$CUSTOM_PUB_KEY" | sudo tee -a /home/$USER_TO_ADD/.ssh/authorized_keys
        echo "SSH key has been added for $USER_TO_ADD."
    fi

    # Set the correct permissions
    sudo chmod 700 /home/$USER_TO_ADD/.ssh
    sudo chmod 600 /home/$USER_TO_ADD/.ssh/authorized_keys
    sudo chown -R $USER_TO_ADD:$USER_TO_ADD /home/$USER_TO_ADD/.ssh

    # Make the setup directory
    sudo -u $USER_TO_ADD bash -c "mkdir -p \$HOME/$SETUP_DIR"
    echo "Setting up setup directory: \$HOME/$SETUP_DIR"
}

# Check if we can run sudo without a password
check_sudo_nopasswd

# Check if the user exists
if id "$USER_TO_ADD" >/dev/null 2>&1; then
    echo "User '$USER_TO_ADD' already exists on the remote machine."
    echo "Setting up SSH keys for existing user."

    setup_user
else
    echo "Creating new user '$USER_TO_ADD' and setting up SSH keys."

    # Create new user without password and add to sudoers with NOPASSWD
    sudo adduser --disabled-password --gecos "" $USER_TO_ADD
    sudo usermod -aG sudo $USER_TO_ADD
    echo "$USER_TO_ADD ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$USER_TO_ADD

    setup_user
fi

# Check if the CUSTOM_PUB_KEY exists in PRESET_USER's authorized_keys
if check_key_in_authorized "$CUSTOM_PUB_KEY" "$PRESET_USER"; then
    echo "CUSTOM_PUB_KEY already exists in $PRESET_USER's authorized_keys. No action needed."
else
    echo "$CUSTOM_PUB_KEY" | sudo tee -a /home/$PRESET_USER/.ssh/authorized_keys
    echo "CUSTOM_PUB_KEY has been added to $PRESET_USER's authorized_keys."
    
    # Remove PRESET_KEY from authorized_keys if requested
    if [[ "$REMOVE_PRESET_KEY" =~ ^[Yy](es|ES)?$ ]]; then
        sudo sed -i "/$PRESET_PUB_KEY/d" /home/$PRESET_USER/.ssh/authorized_keys
        echo "PRESET_KEY has been removed from $PRESET_USER's authorized_keys."
    else
        echo "PRESET_KEY remains in $PRESET_USER's authorized_keys."
    fi
fi

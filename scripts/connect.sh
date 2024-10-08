#!/bin/bash

# Source configuration and common functions
source config.sh
source common.sh

# Check connectivity first
check_connectivity "$MACHINE" "$PORT"

# Func to prepare remote on first connection (add user & update keys)
prepare_remote() {

    local need_to_remove_preset_key="$1"
    local key_using="$2"

    # Read public keys
    CUSTOM_PUB_KEY_CONTENT=$(<"$CUSTOM_PUB_KEY")
    PRESET_PUB_KEY_CONTENT=$(<"$PRESET_PUB_KEY")

    # SCP over the setup_user.sh script
    echo "Copying setup_user.sh to the remote machine..."
    scp -i "$key_using" -P "$PORT" ./setup_user.sh "$PRESET_USER@$MACHINE:~"

    # Execute the setup_user.sh script on the remote machine with passed parameters
    echo "Executing the setup script on the remote machine..."
    ssh -i "$key_using" -p "$PORT" "$PRESET_USER@$MACHINE" bash setup_user.sh "$USER" "$PRESET_USER" \
        "'$CUSTOM_PUB_KEY_CONTENT'" "'$PRESET_PUB_KEY_CONTENT'" "$need_to_remove_preset_key" "$SETUP_DIR"

    echo "Setup completed. Please run the script again to connect using $CUSTOM_KEY."
    exit 0
}

# Check if `yes` argument is passed to automatically remove preset key without prompting
AUTO_REMOVE=${1:-"n"}

# Attempt to SSH using CUSTOM_KEY
echo "Attempting to connect using $CUSTOM_KEY..."
if check_ssh "$CUSTOM_KEY" "$USER" "$MACHINE" "$PORT"; then
    ssh -i "$CUSTOM_KEY" -p "$PORT" "$USER@$MACHINE"
else
    echo "Failed to connect with $CUSTOM_KEY."
    echo "Attempting to connect using PRESET_KEY as $PRESET_USER..."

    if check_ssh "$CUSTOM_KEY" "$USER" "$MACHINE" "$PORT"; then
        echo "Connected successfully with CUSTOM_KEY $CUSTOM_KEY as $PRESET_USER."
        
        prepare_remote "y" "$CUSTOM_KEY"

    elif check_ssh "$CUSTOM_KEY" "$USER" "$MACHINE" "$PORT"; then
        echo "Connected successfully with PRESET_KEY $PRESET_KEY as $PRESET_USER."

        # Check if running in script mode (no prompting)
        if [ "$AUTO_REMOVE" == "yes" ]; then
            REMOVE_PRESET_KEY="y"
        else
            # Prompt the user locally
            while true; do
                read -p "Do you want to remove PRESET_KEY from $PRESET_USER's authorized_keys? (Yes/No): " choice
                case "$choice" in
                    [Yy][Ee][Ss]|[Yy] ) REMOVE_PRESET_KEY="y"; break;;
                    [Nn][Oo]|[Nn] ) REMOVE_PRESET_KEY="n"; break;;
                    * ) echo "Please answer Yes or No (Y/y for yes, N/n for no).";;
                esac
            done
        fi

        # Pass the user's choice or the script argument to the remote
        echo "Your choice: $REMOVE_PRESET_KEY"
        prepare_remote "$REMOVE_PRESET_KEY" "$PRESET_KEY"

    else
        echo "Failed to connect with both CUSTOM_KEY and PRESET_KEY for $PRESET_USER."
        exit -1
    fi
fi

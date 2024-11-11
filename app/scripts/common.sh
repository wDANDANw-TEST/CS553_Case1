# common.sh

# Function to check connectivity
check_connectivity() {

    local machine="$1"
    local port="$2"

    if nc -z -w5 "$machine" "$port" &>/dev/null; then
        echo "Host $machine is reachable on port $port."
    else
        echo "Cannot reach $machine on port $port. Please check network connection (VPN?) and ensure the host is up."
        exit 1
    fi
}

# Function to check SSH connection
check_ssh() {
    local key="$1"
    local user="$2"
    local machine="$3"
    local port="$4"

    echo "Checking SSH connection to $user@$machine..."

    # Build the SSH command
    ssh_command="ssh -i \"$key\""

    # Include port if PORT variable is set and not empty
    if [ -n "$port" ]; then
        ssh_command="$ssh_command -p $port"
    fi

    # Complete the SSH command
    ssh_command="$ssh_command -o BatchMode=yes -o ConnectTimeout=5 \"$user@$machine\" 'exit'"

    # Execute the SSH command
    eval "$ssh_command" &>/dev/null

    if [ $? -ne 0 ]; then
        echo "check_ssh: SSH connection with $key to $user@$machine failed."
        return 1
    else
        echo "check_ssh: SSH connection with $key to $user@$machine successful."
        return 0
    fi
}

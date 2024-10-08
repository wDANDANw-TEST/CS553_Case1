#!/bin/bash

# Get the current directory of the script (assuming all other scripts are in the same directory)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Path to routine_check.sh
ROUTINE_CHECK_SCRIPT="$SCRIPT_DIR/routine_check.sh"

# Ensure the routine_check.sh script is executable
chmod +x "$ROUTINE_CHECK_SCRIPT"

# Set up cron job to run routine_check.sh every 6 hours
(crontab -l ; echo "0 */6 * * * $ROUTINE_CHECK_SCRIPT >> $SCRIPT_DIR/routine_check.log 2>&1") | crontab -

echo "Cron job configured to run routine_check.sh every 6 hours."

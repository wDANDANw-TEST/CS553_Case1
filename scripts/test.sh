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

# Commands to run on the remote machine
read -r -d '' REMOTE_COMMANDS <<EOF
echo "Starting tests on remote machine..."

# Function to activate virtual environment
activate_venv() {
    echo "Activating virtual environment..."
    if [ -d "venv" ]; then
        source "venv/bin/activate"
        if [ \$? -ne 0 ]; then
            echo "Error activating virtual environment."
            exit 1
        fi
        echo "Virtual environment activated."
    else
        echo "Virtual environment not found."
        exit 1
    fi
}

# Function to run tests
run_tests() {
    echo "Running tests..."
    if [ ! -f "$TEST_SCRIPT" ]; then
        echo "Test script $TEST_SCRIPT not found."
        exit 1
    fi
    # Install pytest if not installed
    if ! pip show pytest &>/dev/null; then
        echo "Installing pytest..."
        pip install pytest
        if [ \$? -ne 0 ]; then
            echo "Error installing pytest."
            exit 1
        fi
    fi
    # Run pytest and output results to results.xml
    pytest "$TEST_SCRIPT" --junitxml="results.xml"
    if [ \$? -ne 0 ]; then
        echo "Tests failed."
        exit 1
    fi
    echo "Tests passed."
}

# Main test execution
cd "\$HOME/$PROJECT_DIR"

activate_venv
run_tests

echo "Tests on remote machine completed."
EOF

# Run commands on the remote machine
ssh -i "$CUSTOM_KEY" -p "$PORT" "$USER@$MACHINE" "$REMOTE_COMMANDS"

# Copy test results to local machine
echo "Copying test results to local machine..."
scp -i "$CUSTOM_KEY" "$USER@$MACHINE:\$HOME/$PROJECT_DIR/results.xml" .

# Check test results
if [ -f "results.xml" ]; then
    if grep -q 'errors="0" failures="0"' "results.xml"; then
        echo "All tests passed."
    else
        echo "Some tests failed. Check results.xml for details."
    fi
else
    echo "Failed to retrieve test results."
fi

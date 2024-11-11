#!/bin/bash

# Parameters passed from deploy.sh
PROJECT_DIR="$1"
APP_ENTRYPOINT="$2"

echo "Starting deployment on remote machine..."

# Function to activate virtual environment
activate_venv() {
    echo "Activating virtual environment..."
    if [ -d "venv" ]; then
        source "venv/bin/activate"
        if [ $? -ne 0 ]; then
            echo "Error activating virtual environment."
            exit 1
        fi
        echo "Virtual environment activated."
    else
        echo "Virtual environment not found."
        create_venv
    fi
}

# Function to create virtual environment
create_venv() {
    echo "Creating virtual environment..."
    if command -v python &>/dev/null; then
        PYTHON_COMMAND="python"
    elif command -v python3 &>/dev/null; then
        PYTHON_COMMAND="python3"
    else
        echo "Python is not installed."
        exit 1
    fi
    $PYTHON_COMMAND -m venv venv
    if [ $? -ne 0 ]; then
        echo "Error creating virtual environment."
        exit 1
    fi
    echo "Virtual environment created."
    source "venv/bin/activate"
    if [ $? -ne 0 ]; then
        echo "Error activating virtual environment."
        exit 1
    fi
    echo "Virtual environment activated."
}

# Function to install dependencies
install_python_lib_dependencies() {
    echo "Installing dependencies..."
    if [ ! -f "requirements.txt" ]; then
        echo "requirements.txt not found."
        exit 1
    fi
    pip install -r "requirements.txt"
    if [ $? -ne 0 ]; then
        echo "Error installing dependencies."
        exit 1
    fi
    echo "Dependencies installed."
}

# Function to run the application using tmux
run_application() {
    echo "Running the application..."
    if [ ! -f "$APP_ENTRYPOINT" ]; then
        echo "Application entry point $APP_ENTRYPOINT not found."
        exit 1
    fi
    # Kill existing instance if running
    tmux kill-session -t gradio-app 2>/dev/null || true

    # Run the application in a new detached tmux session
    tmux new-session -d -s gradio-app ./venv/bin/python3 "$APP_ENTRYPOINT" > app.log 2>&1

    if [ $? -ne 0 ]; then
        echo "Error starting the application."
        exit 1
    fi

    echo "Application is now running in a detached tmux session named 'gradio-app'."
    echo "To reattach to the tmux session: tmux attach -t gradio-app"
}


# Main deployment execution
cd "$HOME/$PROJECT_DIR"

activate_venv
install_python_lib_dependencies
run_application

echo "Deployment on remote machine completed successfully."

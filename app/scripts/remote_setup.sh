#!/bin/bash

# Parameters passed from setup.sh
PROJECT_DIR="$1"
PYTHON_VERSION="$2"
ASDF_VERSION="$3"
REPO_URL="$4"
SETUP_DIR="$5"

# Ensure the setup directory exists
if [ ! -d "$SETUP_DIR" ]; then
    echo "Setup directory $SETUP_DIR does not exist. Creating..."
    mkdir -p "$SETUP_DIR"
    if [ $? -ne 0 ]; then
        echo "Error creating setup directory $SETUP_DIR."
        exit 1
    fi
else
    echo "Setup directory $SETUP_DIR exists."
fi

# Ensure the user exists
if ! id "$USER" &>/dev/null; then
    echo "User $USER does not exist on the remote machine."
    exit 1
fi

# Function to install common dependencies
install_common_dependencies() {
    echo "Installing common dependencies ..."
    sudo apt-get update -qq
    sudo apt-get install -qq -y git \
        curl make wget \
        tmux \
        build-essential # Moved build-essential here as some packages seem to need it
    if [ $? -ne 0 ]; then
        echo "Error installing common dependencies."
        exit 1
    fi
    echo "Common dependencies installed."
}

# Function to check if Python is installed
check_python() {
    echo "Checking if Python is installed..."
    if command -v python &>/dev/null; then
        echo "Python is installed."
        PYTHON_COMMAND="python"
    elif command -v python3 &>/dev/null; then
        echo "Python3 is installed."
        PYTHON_COMMAND="python3"
    else
        echo "Python is not installed."
        PYTHON_COMMAND=""
    fi
}

# Function to install asdf
install_asdf() {
    echo "Installing asdf version $ASDF_VERSION..."
    git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch "$ASDF_VERSION"
    if [ $? -ne 0 ]; then
        echo "Error cloning asdf repository."
        exit 1
    fi
    echo "asdf installed."

    # Add asdf to shell
    if ! grep -q 'asdf.sh' ~/.bashrc; then
        echo "Adding asdf to .bashrc..."
        echo '. $HOME/.asdf/asdf.sh' >> ~/.bashrc
        echo '. $HOME/.asdf/completions/asdf.bash' >> ~/.bashrc
        echo "asdf added to .bashrc."
    else
        echo "asdf already present in .bashrc."
    fi
}

# Function to source asdf
source_asdf() {
    echo "Sourcing asdf..."
    source "$HOME/.asdf/asdf.sh"
    if [ $? -ne 0 ]; then
        echo "Error sourcing asdf."
        exit 1
    fi
    echo "asdf sourced."
}

# Function to install Python using asdf
install_python() {
    source_asdf

    # Install Python build dependencies
    echo "Installing Python build dependencies..."
    sudo apt-get install -qq -y \
        libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
        libsqlite3-dev libffi-dev libncursesw5-dev xz-utils tk-dev \
        liblzma-dev libgdbm-dev libnss3-dev libgdbm-compat-dev libxml2-dev libxmlsec1-dev \
        uuid-dev
    if [ $? -ne 0 ]; then
        echo "Error installing Python build dependencies."
        exit 1
    fi
    echo "Python build dependencies installed."

    # Install Python plugin
    if ! asdf plugin-list | grep -q 'python'; then
        echo "Adding Python plugin to asdf..."
        asdf plugin-add python
        if [ $? -ne 0 ]; then
            echo "Error adding Python plugin."
            exit 1
        fi
        echo "Python plugin added."
    else
        echo "Python plugin already installed."
    fi

    # Install Python version specified in .tool-versions or default to provided PYTHON_VERSION
    if [ -f "$HOME/$PROJECT_DIR/.tool-versions" ]; then
        echo "Using .tool-versions from project directory."
        cd "$HOME/$PROJECT_DIR"
        echo "Installing Python versions from .tool-versions..."
        asdf install
        if [ $? -ne 0 ]; then
            echo "Error installing Python versions from .tool-versions."
            exit 1
        fi
        echo "Python versions installed."
    else
        echo "Installing Python $PYTHON_VERSION globally..."
        asdf install python "$PYTHON_VERSION"
        if [ $? -ne 0 ]; then
            echo "Error installing Python $PYTHON_VERSION."
            exit 1
        fi
        asdf global python "$PYTHON_VERSION"
        echo "Python $PYTHON_VERSION installed and set as global version."
    fi

    # Set PYTHON_COMMAND
    PYTHON_COMMAND="python"
}

# Main script execution
cd "$SETUP_DIR"

# Install common dependencies
install_common_dependencies
echo ""

# Check if Python is installed
check_python
echo ""

if [ -z "$PYTHON_COMMAND" ]; then
    echo "Python not found. Installing asdf."
    install_asdf
    source_asdf
    install_python
else
    echo "Python found: $PYTHON_COMMAND"
fi
echo ""

# Verify installations
echo "Verifying installations..."
git --version
if [ $? -ne 0 ]; then
    echo "Error verifying git installation."
    exit 1
fi
$PYTHON_COMMAND --version
if [ $? -ne 0 ]; then
    echo "Error verifying Python installation."
    exit 1
fi
echo "Installations verified."
echo ""

# Clone or update the repository
if [ ! -d "$HOME/$PROJECT_DIR" ]; then
    echo "Cloning repository from $REPO_URL..."
    git clone "$REPO_URL" "$HOME/$PROJECT_DIR"
    if [ $? -ne 0 ]; then
        echo "Error cloning repository."
        exit 1
    fi
    echo "Repository cloned."
else
    echo "Updating repository..."
    cd "$HOME/$PROJECT_DIR" && git pull
    if [ $? -ne 0 ]; then
        echo "Error updating repository."
        exit 1
    fi
    echo "Repository updated."
fi
echo ""

# Create virtual environment using the available Python
cd "$HOME/$PROJECT_DIR"

echo "Creating virtual environment..."
sudo apt install -qq -y python3-venv
$PYTHON_COMMAND -m venv venv
if [ $? -ne 0 ]; then
    echo "Error creating virtual environment."
    exit 1
fi
echo "Virtual environment created."

echo "Setup on remote machine completed successfully."

#!/bin/bash

set -e

echo "HTW Saar Grade Tracker Setup"
echo "--------------------------------"

PROJECT_DIR=$(pwd)
VENV_DIR="$PROJECT_DIR/venv"
SCRIPT_PATH="$PROJECT_DIR/script.py"

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "Python3 is not installed. Please install Python first."
    exit 1
fi

echo "Python found: $(python3 --version)"

# Check Python version (>=3.9 recommended)
PY_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
echo "Detected Python version: $PY_VERSION"

# Create virtual environment if not existing
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating virtual environment..."
    python3 -m venv "$VENV_DIR"
else
    echo "Virtual environment already exists."
fi

# Activate venv
source "$VENV_DIR/bin/activate"

# Upgrade pip
pip install --upgrade pip

# Install dependencies
if [ -f "requirements.txt" ]; then
    echo "Installing dependencies..."
    pip install -r requirements.txt

    # Check if Chrome is installed (required for Selenium)
    if ! command -v google-chrome &> /dev/null && ! command -v chrome &> /dev/null && ! command -v chromium &> /dev/null && ! command -v "Google Chrome" &> /dev/null; then
        echo "Warning: Chrome browser not detected. Selenium requires Chrome to be installed."
    else
        echo "Chrome installation detected."
    fi
else
    echo "requirements.txt not found!"
    exit 1
fi

# Ensure tmp directory exists
mkdir -p "$PROJECT_DIR/tmp"

# Create .env if missing
if [ ! -f "$PROJECT_DIR/.env" ]; then
    if [ -f "$PROJECT_DIR/.env.example" ]; then
        cp "$PROJECT_DIR/.env.example" "$PROJECT_DIR/.env"
        echo "Created .env file from template."
        echo "Please edit the .env file and add your credentials."
    else
        echo ".env.example not found. Please create a .env manually."
    fi
else
    echo ".env already exists."
fi

# Ask user if cronjob should be installed
read -p "Install cronjob to check grades every 3 hours? (y/n): " INSTALL_CRON

if [[ "$INSTALL_CRON" == "y" || "$INSTALL_CRON" == "Y" ]]; then

    CRON_JOB="0 */3 * * * cd $PROJECT_DIR && $VENV_DIR/bin/python $SCRIPT_PATH >> cron.log 2>&1"

    (crontab -l 2>/dev/null | grep -v "$SCRIPT_PATH"; echo "$CRON_JOB") | crontab -

    echo ""
    echo "Cronjob installed:"
    echo "$CRON_JOB"
else
    echo "Cronjob skipped."
fi

# Final message

echo ""
echo "Setup complete!"
echo ""
echo "Next steps:"
echo "1. Edit the .env file and add your credentials"
echo "2. Test the script:"
echo ""
echo "   source venv/bin/activate"
echo "   python script.py"
#!/usr/bin/env bash
set -euo pipefail

# Print the absolute path of this script
realpath "$0"

# Configuration
SANDBOX_ROOT="/home/raspberry/sandbox"
VENV_DIR="$SANDBOX_ROOT/venv"
BOOTSTRAP_SH="$SANDBOX_ROOT/bootstrap.sh"
BASHRC="/home/raspberry/.bashrc"

# Update system packages
sudo apt-get update
sudo apt-get -y upgrade

# Install required packages
sudo apt-get install -y \
  python3 python3-pip python3-venv \
  git tmux screen \
  build-essential minicom

# Create sandbox directory structure
mkdir -p "$SANDBOX_ROOT"/{venv,experiments,esp_tools,protocols,tests,logs}

# Create Python virtual environment if missing
if [ ! -d "$VENV_DIR" ]; then
  python3 -m venv "$VENV_DIR"
fi

# Install Python packages into the venv
"$VENV_DIR/bin/pip" install --upgrade pip
"$VENV_DIR/bin/pip" install pyserial esptool requests flask rich click

# Create bootstrap script to activate the venv
cat <<'BOOTSTRAP' > "$BOOTSTRAP_SH"
#!/usr/bin/env bash
# Safe to source multiple times
if [ -n "${VIRTUAL_ENV:-}" ] && [ "$VIRTUAL_ENV" = "/home/raspberry/sandbox/venv" ]; then
  return 0 2>/dev/null || exit 0
fi

source "/home/raspberry/sandbox/venv/bin/activate"
python --version
printf "Sandbox path: %s\n" "/home/raspberry/sandbox"
BOOTSTRAP

chmod +x "$BOOTSTRAP_SH"

# Ensure .bashrc auto-activates sandbox for interactive shells only
if ! grep -q "sandbox/bootstrap.sh" "$BASHRC"; then
  cat <<'BASHRC_SNIPPET' >> "$BASHRC"

# Auto-activate Raspberry Pi sandbox for interactive shells
if [[ $- == *i* ]]; then
  if [ -f "/home/raspberry/sandbox/bootstrap.sh" ]; then
    source "/home/raspberry/sandbox/bootstrap.sh"
  fi
fi
BASHRC_SNIPPET
fi

# Add user to dialout group for serial access
sudo usermod -aG dialout raspberry

# Reboot reminder
printf "\nSetup complete. Please reboot the Raspberry Pi for group changes to take effect.\n"

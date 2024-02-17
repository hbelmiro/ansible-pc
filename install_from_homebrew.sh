#!/usr/bin/env bash

set -e

install_from_homebrew() {
    local package_name="$1"
    log "Installing $package_name..."
    if brew install "$package_name"; then
        log "$package_name has been successfully installed."
    else
        log "Failed to install $package_name. Please install it manually."
        exit 1
    fi
}
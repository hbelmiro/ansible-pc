#!/usr/bin/env bash

set -e

log() {
    local message="$1"
    echo -e "\033[1m$message\033[0m"
}

install_from_dnf() {
    local package_name="$1"

    log "Installing $package_name..."

    if ! sudo dnf install "$package_name" -y; then
        log "Failed to install $package_name. Please install it manually."
        exit 1
    fi
}

install_from_flatpak() {
    local package_name="$1"
    log "Installing $package_name..."
    if flatpak install flathub "$package_name" -y; then
        log "$package_name has been successfully installed."
    else
        log "Failed to install $package_name. Please install it manually."
        exit 1
    fi
}

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

install_homebrew() {
    if ! command -v "brew" &> /dev/null; then
        log "Homebrew is not installed. Installing..."
        
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        log "Homebrew is already installed."
    fi
}

configure_git() {
    log "Configuring git..."

    git config --global user.name "hbelmiro"
    git config --global user.email helber.belmiro@gmail.com

    log "Git successfully configured."
}

generate_gpg_keys() {
    log "Existing GPG keys:"
    gpg --list-secret-keys

    log "Recommended values:"
    log "Type of the key: RSA"
    log "Key size: at least 4096 bits"
    log "Key validity period: 1 year (it's a good practice to rotate the key once a year)"

    echo "Do you want to generate a new GPG key?"
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) gpg --full-generate-key; break;;
            No ) exit;;
        esac
    done
}

main() {
    install_from_dnf "python3-pip"
    install_from_dnf "bat"
    install_from_dnf "flatpak"
    install_from_dnf "gcc"
    install_from_dnf "gnome-tweaks"
    install_from_dnf "terminator"
    install_from_dnf "zsh"
    
    install_from_flatpak "com.bitwarden.desktop"
    install_from_flatpak "com.jetbrains.GoLand"
    install_from_flatpak "com.jetbrains.IntelliJ-IDEA-Ultimate"
    install_from_flatpak "com.jetbrains.PyCharm-Professional"
    install_from_flatpak "com.slack.Slack"
    install_from_flatpak "org.gnome.DejaDup"
    install_from_flatpak "org.gnome.Extensions"
    install_from_flatpak "us.zoom.Zoom"

    install_homebrew

    install_from_homebrew "bitwarden-cli"
    install_from_homebrew "go"
    install_from_homebrew "zsh-autosuggestions"

    configure_git
    generate_gpg_keys

    echo "test"
}

main
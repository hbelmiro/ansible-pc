#!/usr/bin/env bash

set -e

DIRECTORIES_TO_ADD_TO_PATH=()

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

    log "Do you want to generate a new GPG key?"
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) do_generate_gpg_keys; break;;
            No ) break;;
        esac
    done
}

do_generate_gpg_keys() {
    gpg --full-generate-key
    git config commit.gpgsign false
}

install_jdk() {
    local VERSION="$1"

    log "Installing JDK ${VERSION}..."

    local DIRECTORY="${HOME}/dev/jdk/${VERSION}"

    if [ -d "${DIRECTORY}" ]; then
        log "JDK ${VERSION} already installed."
    else
        mkdir -p "${DIRECTORY}"

        local API_URL="https://api.adoptium.net/v3/binary/latest/${VERSION}/ga/linux/x64/jdk/hotspot/normal/eclipse"

        local FETCH_URL
        FETCH_URL=$(curl -s -w %{redirect_url} "${API_URL}")

        local FILENAME
        FILENAME=$(curl -OL -w %{filename_effective} "${FETCH_URL}")

        mv "$FILENAME" "$DIRECTORY"

        pushd "${DIRECTORY}"
        curl -Ls "${FETCH_URL}.sha256.txt" | sha256sum -c --status
        popd

        log "Uncompressing downloaded file..."
        tar -xzf "${DIRECTORY}"/"${FILENAME}" -C "${DIRECTORY}/"

        rm "${DIRECTORY}"/"${FILENAME}"

        log "JDK ${VERSION} successfully installed."
    fi
}

allow_volume_over_100_percent() {
    gsettings set org.gnome.desktop.sound allow-volume-above-100-percent 'true'
}

install_kgrep() {
    pushd ~/dev/hbelmiro/

    git clone https://github.com/hbelmiro/kgrep.git
    DIRECTORIES_TO_ADD_TO_PATH+=( "${HOME}/dev/hbelmiro/kgrep" )

    popd
}

show_directories_for_path() {
    log "Directories to add to PATH:"
    for DIR in "${DIRECTORIES_TO_ADD_TO_PATH[@]}"; do
        echo "${DIR}"
    done
}

main() {
    install_from_dnf "python3-pip"
    install_from_dnf "bat"
    install_from_dnf "flatpak"
    install_from_dnf "gcc"
    install_from_dnf "gnome-tweaks"
    install_from_dnf "maven"
    install_from_dnf "podman-docker" && sudo touch /etc/containers/nodocker
    install_from_dnf "terminator"
    install_from_dnf "zsh"
    
    install_from_flatpak "com.bitwarden.desktop"
    install_from_flatpak "com.discordapp.Discord"
    install_from_flatpak "com.slack.Slack"
    install_from_flatpak "org.gnome.DejaDup"
    install_from_flatpak "org.gnome.Extensions"
    install_from_flatpak "org.telegram.desktop"
    install_from_flatpak "org.videolan.VLC"
    install_from_flatpak "us.zoom.Zoom"

    install_homebrew

    install_from_homebrew "bitwarden-cli"
    install_from_homebrew "go"
    install_from_homebrew "kustomize"
    install_from_homebrew "yq"
    install_from_homebrew "zsh-autosuggestions"

    generate_gpg_keys
    configure_git

    install_jdk "17"
    install_jdk "21"

    allow_volume_over_100_percent

    install_kgrep

    show_directories_for_path
}

main
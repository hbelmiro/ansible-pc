#!/usr/bin/env bash

set -e

source log.sh
source install_from_homebrew.sh

DIRECTORIES_TO_ADD_TO_PATH=()

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

install_homebrew() {
    if ! command -v "brew" &> /dev/null; then
        log "Homebrew is not installed. Installing..."
        
        export NONINTERACTIVE=true && /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        (echo; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> /home/hbelmiro/.zshrc
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        sudo yum groupinstall 'Development Tools' -y
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
    rm -rf ~/dev/hbelmiro/kgrep

    pushd ~/dev/hbelmiro/

    git clone https://github.com/hbelmiro/kgrep.git
    DIRECTORIES_TO_ADD_TO_PATH+=( "${HOME}/dev/hbelmiro/kgrep" )

    popd
}

install_configure_ocp_pull_secrets() {
    rm -rf ~/dev/hbelmiro/configure-ocp-pull-secrets

    pushd ~/dev/hbelmiro/

    git clone https://github.com/hbelmiro/configure-ocp-pull-secrets.git
    DIRECTORIES_TO_ADD_TO_PATH+=( "${HOME}/dev/hbelmiro/configure-ocp-pull-secrets" )

    popd
}

show_directories_for_path() {
    log "Directories to add to PATH:"
    for DIR in "${DIRECTORIES_TO_ADD_TO_PATH[@]}"; do
        echo "${DIR}"
    done
}

install_oc() {
    if ! command -v "oc" &> /dev/null; then
        log "OpenShift CLI is not installed. Installing..."

        mkdir "${HOME}"/dev/oc

        curl -L https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/oc.tar.gz  | tar -xzf - -C "${HOME}"/dev/oc
        chmod +x ~/dev/oc/oc && chmod +x ~/dev/oc/kubectl

        DIRECTORIES_TO_ADD_TO_PATH+=( "${HOME}/dev/oc" )
    else
        log "OpenShift CLI is already installed."
    fi
}

configure_us_international_keyboard() {
    log "Configuring keyboard..."
    cp resources/.XCompose ~
    log "Keyboard configured. Restart Gnome"
}

install_vscode() {
    if ! command -v "code" &> /dev/null; then
        log "Visual Studio Code is not installed. Installing..."

        sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
        sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
        sudo dnf install code -y
    else
        log "Visual Studio Code is already installed."
    fi
}

install_flatpak() {
    install_from_dnf "flatpak"
    sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
}

main() {
    install_from_dnf "python3.10-devel"
    install_from_dnf "python3-pip"
    install_from_dnf "python3-pytest"
    install_from_dnf "bat"
    install_from_dnf "cmake"
    install_from_dnf "fzf"
    install_from_dnf "gcc"
    install_from_dnf "gcc-c++"
    install_from_dnf "git-crypt"
    install_from_dnf "gnome-tweaks"
    install_from_dnf "kolourpaint"
    install_from_dnf "maven"
    install_from_dnf "podman-docker" && sudo touch /etc/containers/nodocker
    install_from_dnf "terminator"
    install_from_dnf "tmux"
    install_from_dnf "xclip"
    install_from_dnf "zsh"

    install_flatpak

    install_vscode
    
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
    install_from_homebrew "quarkusio/tap/quarkus"
    install_from_homebrew "yq"
    install_from_homebrew "zsh-autosuggestions"

    source install_conda.sh

    generate_gpg_keys
    configure_git

    install_jdk "17"
    install_jdk "21"

    allow_volume_over_100_percent

    install_kgrep
    install_oc
    install_configure_ocp_pull_secrets

    show_directories_for_path

    configure_us_international_keyboard
}

main
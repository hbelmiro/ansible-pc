#!/usr/bin/env bash

set -e

install_pip() {
    if ! command -v pip &> /dev/null; then
        echo "pip is not installed. Installing..."
        if dnf install python3-pip; then
            echo "pip has been successfully installed."
        else
            echo "Failed to install pip. Please install it manually."
            exit 1
        fi
    else
        echo "pip is already installed."
    fi
}

install_ansible() {
    pip install ansible
}

main() {
    install_pip
    install_ansible
    ansible-playbook first_playbook.yaml
}

main
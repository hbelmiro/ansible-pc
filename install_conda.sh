#!/usr/bin/env bash

set -e

source log.sh

install_conda() {
    if ! command -v "conda" &> /dev/null; then
        log "Installing Conda..."

        mkdir -p ~/miniconda3
        wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
        bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
        rm -rf ~/miniconda3/miniconda.sh

        ~/miniconda3/bin/conda init bash
        ~/miniconda3/bin/conda init zsh
    else
        log "Conda is already installed."
    fi
}

install_conda
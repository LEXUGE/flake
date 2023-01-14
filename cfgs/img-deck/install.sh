#!/usr/bin/env bash

MOUNTPOINT="/mnt"

set -e

sudo -u nixos git clone https://github.com/LEXUGE/flake

disko

mkdir -p ${MOUNTPOINT}/persist/secrets/

sudo -u nixos gpg -o ash_ed25519 -d flake/secrets/raw/ash_ed25519.asc
mv ash_ed25519 "${MOUNTPOINT}"/persist/secrets/

# secrets folder not be accessible by anybody
chmod 700 "${MOUNTPOINT}"/persist/secrets/

nixos-install --flake "./flake#deck" --no-root-passwd --no-channel-copy

#!/usr/bin/env bash

MOUNTPOINT="/mnt"

set -e

sudo -u nixos git clone https://github.com/LEXUGE/flake

# Create secureboot keys
mkdir -p /etc/secureboot/keys/db

# start using user "nixos" is necessary, otherwise pinetry cannot work
# we cannot directly output the decrypted files to /etc due to permission issue
sudo -u nixos gpg -o db.pem -d flake/secrets/raw/db.pem.asc
sudo -u nixos gpg -o db.key -d flake/secrets/raw/db.key.asc

mv db.pem /etc/secureboot/keys/db/db.pem
mv db.key /etc/secureboot/keys/db/db.key

chmod 400 /etc/secureboot

disko

mkdir -p ${MOUNTPOINT}/persist/secrets/

sudo -u nixos gpg -o ash_ed25519 -d flake/secrets/raw/ash_ed25519.asc
mv ash_ed25519 "${MOUNTPOINT}"/persist/secrets/

# secrets folder not be accessible by anybody
chmod 700 "${MOUNTPOINT}"/persist/secrets/

nixos-install --flake "./flake#deck" --no-root-passwd --no-channel-copy

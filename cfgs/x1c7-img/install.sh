#!/usr/bin/env bash

set -e

prompt1="Enter your option: "
ESP="/boot/efi"
MOUNTPOINT="/mnt"

contains_element() {
	#check if an element exist in a string
	for e in "${@:2}"; do [[ $e == "$1" ]] && break; done
}

#SELECT DEVICE
select_device() {
	devices_list=($(lsblk -d | awk '{print "/dev/" $1}' | grep 'sd\|hd\|vd\|nvme\|mmcblk'))
	PS3="$prompt1"
	echo -e "Attached Devices:\n"
	lsblk -lnp -I 2,3,8,9,22,34,56,57,58,65,66,67,68,69,70,71,72,91,128,129,130,131,132,133,134,135,259 | awk '{print $1,$4,$6,$7}' | column -t
	echo -e "\n"
	echo -e "Select device to partition:\n"
	select device in "${devices_list[@]}"; do
		if contains_element "${device}" "${devices_list[@]}"; then
			break
		else
			exit 1
		fi
	done
	if [ "$1" = "-n" ]; then
		ESP_PARTITION="${device}p1"
		SWAP_PARTITION="${device}p2"
		ROOT_PARTITION="${device}p3"
	else
		ESP_PARTITION="${device}1"
		SWAP_PARTITION="${device}2"
		ROOT_PARTITION="${device}3"
	fi
	echo "ESP partition: ${ESP_PARTITION}"
	echo "Root partition: ${ROOT_PARTITION}"
	echo "Swap partition: ${SWAP_PARTITION}"
}

#CREATE_PARTITION
create_partition() {
	wipefs -a "${device}"
	# Set GPT scheme
	parted "${device}" mklabel gpt
	# Create ESP for /efi
	parted "${device}" -- mkpart primary fat32 1MiB 512MiB
	parted "${device}" -- set 1 esp on
	# Create encrypted SWAP
	parted "${device}" -- mkpart primary 512MiB 20.5GiB
	# Create /
	parted "${device}" -- mkpart primary 20.5GiB 100%
}

#FORMAT_PARTITION
format_partition() {
	mkfs.fat -n "ESP" -F32 "${ESP_PARTITION}"
	echo "LUKS Setup for btrfs root"
	cryptsetup luksFormat --type luks1 -s 512 -h sha512 -i 3000 "${ROOT_PARTITION}"
	echo "Open btrfs root"
	cryptsetup open "${ROOT_PARTITION}" cryptroot

	mkfs.btrfs --csum sha256 /dev/mapper/cryptroot
	mount -t btrfs -o compress-force=zstd,noatime /dev/mapper/cryptroot "${MOUNTPOINT}"

	btrfs subvolume create "${MOUNTPOINT}"/nix
	btrfs subvolume create "${MOUNTPOINT}"/persist
	btrfs subvolume create "${MOUNTPOINT}"/persist/home
	btrfs subvolume create "${MOUNTPOINT}"/boot
	btrfs subvolume create "${MOUNTPOINT}"/.snapshots

	umount ${MOUNTPOINT}

	echo "LUKS Setup for 'SWAP' partition"
	cryptsetup luksFormat --type luks1 -s 512 -h sha512 -i 3000 "${SWAP_PARTITION}"
	echo "Open btrfs root"
	cryptsetup open "${SWAP_PARTITION}" cryptswap
	mkswap /dev/mapper/cryptswap
	swapon /dev/mapper/cryptswap
}

#MOUNT_PARTITION
mount_partition() {
	mount -t tmpfs -o defaults,size=2G,mode=755 none "${MOUNTPOINT}"

	mkdir -p "${MOUNTPOINT}"/nix
	mkdir -p "${MOUNTPOINT}"/persist
	mkdir -p "${MOUNTPOINT}"/boot
	mkdir -p "${MOUNTPOINT}"/.snapshots

	mount -t btrfs -o compress-force=zstd,noatime,subvol=nix /dev/mapper/cryptroot "${MOUNTPOINT}"/nix
	mount -t btrfs -o compress-force=zstd,noatime,subvol=persist /dev/mapper/cryptroot "${MOUNTPOINT}"/persist
	mount -t btrfs -o compress-force=zstd,noatime,subvol=boot /dev/mapper/cryptroot "${MOUNTPOINT}"/boot
	mount -t btrfs -o compress-force=zstd,noatime,subvol=.snapshots /dev/mapper/cryptroot "${MOUNTPOINT}"/.snapshots

	mkdir -p "${MOUNTPOINT}"${ESP}
	mount "${ESP_PARTITION}" "${MOUNTPOINT}"${ESP}
}

#CREATE_KEYFILE
create_keyfile() {
	mkdir -p ${MOUNTPOINT}/persist/secrets/

	dd bs=512 count=4 if=/dev/random of=${MOUNTPOINT}/persist/secrets/keyfile.bin iflag=fullblock
	echo "Add key to btrfs root partition"
	cryptsetup luksAddKey "${ROOT_PARTITION}" ${MOUNTPOINT}/persist/secrets/keyfile.bin
	echo "Add key to swap partition"
	cryptsetup luksAddKey "${SWAP_PARTITION}" ${MOUNTPOINT}/persist/secrets/keyfile.bin
}

# NIXOS_INSTALL
nixos_install() {
	sudo -u nixos git clone https://github.com/LEXUGE/flake

	sudo -u nixos gpg -o ash_ed25519 -d flake/secrets/raw/ash_ed25519.asc
	mv ash_ed25519 ${MOUNTPOINT}/persist/secrets/

	# secrets folder not be accessible by anybody
	chmod 700 ${MOUNTPOINT}/persist/secrets/

	blkid -o list "${ROOT_PARTITION}"
	blkid -o list "${SWAP_PARTITION}"

	echo "YOU SHOULD DO THE FOLLOWING STEPS MANUALLY:"

	echo "1. Change UUIDs of your BTRFS root and swap partition accordingly in flake/cfgs/x1c7/hardware.nix"

	echo "2. nixos-install --flake \"./flake#x1c7\" --no-root-passwd --no-channel-copy"
}

# INSTALLATION
select_device "$@"
create_partition
format_partition
mount_partition
create_keyfile
nixos_install

#!/usr/bin/env bash

set -o errexit
set -o nounset

timedatectl set-ntp true

echo "Partitioning..."
readonly ESP_SIZE=102

readonly ALIGNMENT_OFFSET_FILE="/sys/block/sda/queue/alignment_offset"
if [[ -f "${ALIGNMENT_OFFSET_FILE}" ]]; then
	readonly ALIGNMENT_OFFSET=$(cat ${ALIGNMENT_OFFSET_FILE})
	readonly OPTIMAL_IO_SIZE=$(cat /sys/block/sda/queue/optimal_io_size)
	readonly PHYSICAL_BLOCK_SIZE=$(cat /sys/block/sda/queue/physical_block_size)
	readonly ESP_START=(${OPTIMAL_IO_SIZE}+${ALIGNMENT_OFFSET})/${PHYSICAL_BLOCK_SIZE}
else
	readonly ESP_START=1
fi

parted /dev/sda --script mktable gpt
parted /dev/sda --script mkpart primary fat32 ${ESP_START}MiB ${ESP_SIZE}MiB
parted /dev/sda --script name 1 esp
parted /dev/sda --script set 1 boot on
parted /dev/sda --script set 1 esp on
parted /dev/sda --script mkpart primary ext4 ${ESP_SIZE}MiB 100%
parted /dev/sda --script name 2 system

echo "Creating filesystesm..."
mkfs.fat /dev/sda1 -F 32 -n ESP
mkfs.ext4 /dev/sda2 -L System

echo "Mounting filesystems.."
mount /dev/sda2 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

echo "Installing..."
pacstrap /mnt bash dosfstools e2fsprogs filesystem iproute2 iputils linux-lts linux-lts-headers logrotate neovim nftables openssh pacman pciutils procps-ng psmisc rsync sed sudo virtualbox-guest-utils-nox

echo "Now set up this thing!"
genfstab -pL /mnt >> /mnt/etc/fstab
# TODO: Write my own optimized fstab in set-up.sh

arch-chroot /mnt

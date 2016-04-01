#!/usr/bin/env bash

set -o errexit
set -o nounset

pacman -Syu git linux-lts neovim nftables python-neovim rsync syslinux xclip --noconfirm
pacman -Rns dhcpcd diffutils file grub jfsutils licenses lvm2 mdadm nano netctl pcmciautils reiserfsprogs s-nail parted tar usbutils vi which xfsprogs --noconfirm

# Hostname
while : 
do
	echo "Enter hostname:"
	read HOSTNAME
	if [[ -n "${HOSTNAME}" ]]; then
		hostnamectl set-hostname ${HOSTNAME}
		break
	fi
done

# Locales
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen

# Time
while :
do
	echo "Enter time zone:"
	read TIME_ZONE
	echo "Enter time sub-zone:"
	read TIME_SUB_ZONE
	if [[ -n "${TIME_ZONE}" && -n "${TIME_SUB_ZONE}" ]]
		timedatectl set-timezone "${TIME_ZONE}"/"${TIME_SUB_ZONE}"
		timedatectl set-ntp true
		systemctl enable systemd-timesyncd
		break
	fi
done

# Users
passwd

while :
do
	echo "Enter username:"
	read USERNAME
	if [[ -n "${USERNAME}" ]]; then
		useradd -m -G wheel -s /bin/bash ${USERNAME}
		passwd ${USERNAME}
		break
	fi
done

echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su
echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su-l
echo "hvc0" > /etc/securetty

echo "Defaults editor=/usr/bin/nvim" > /etc/sudoers
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
echo "root ALL=(ALL) ALL" >> /etc/sudoers

# SSH
echo "AllowGroups wheel" >> /etc/ssh/sshd_config
echo "PermitRootLogin no" >> /etc/ssh/sshd_config
echo "#PasswordAuthentication no" >> /etc/ssh/sshd_config
echo "UseDNS no" >> /etc/ssh/sshd_config

# Services
systemctl enable logrotate
systemctl start logrotate

systemctl enable nftables

systemctl set-default multi-user.target

# Bootloader
syslinux-install_update -iam
cp syslinux.cfg /boot/syslinux/syslinux.cfg

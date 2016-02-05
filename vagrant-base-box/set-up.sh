#!/usr/bin/env bash

set -o errexit
set -o nounset

# Locales
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen

# Time
ln -s /usr/share/zoneinfo/America/Santiago /etc/localtime

echo "[Time]" > /etc/systemd/timesyncd.conf
echo "NTP=0.arch.pool.ntp.org 1.arch.pool.ntp.org 2.arch.pool.ntp.org 3.arch.pool.ntp.org" >> /etc/systemd/timesyncd.conf
echo "FallbackNTP=0.pool.ntp.org 1.pool.ntp.org 0.fr.pool.ntp.org" >> /etc/systemd/timesyncd.conf

systemctl enable systemd-timesyncd

# Users
readonly DEFAULT_USER="vagrant"
useradd -m -G wheel -s /bin/bash "${DEFAULT_USER}"
echo "${DEFAULT_USER}" | passwd "${DEFAULT_USER}" --stdin
echo "${DEFAULT_USER}" | passwd --stdin

echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su
echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su-l
echo "hvc0" >> /etc/securetty

# Sudoers
echo "Defaults editor=/usr/bin/nvim" > /etc/sudoers
echo "root ALL=(ALL) ALL" >> /etc/sudoers
echo "${DEFAULT_USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# Firewall
systemctl enable nftables

# SSH
echo "AllowGroups wheel" >> /etc/ssh/sshd_config
echo "PermitRootLogin no" >> /etc/ssh/sshd_config
echo "#PasswordAuthentication no" >> /etc/ssh/sshd_config
echo "UseDNS no" >> /etc/ssh/sshd_config

systemctl enable sshd.socket

# Systemd default target
systemctl set-default multi-user.target

# Kernel
echo "blacklist i2c_piix4" > /etc/modprobe.d/i2c_piix4.conf
# VirtualBox does not provide smbus

# Network
echo "[Match]" > /etc/systemd/network/10-default.network
echo "Name=en*" >> /etc/systemd/network/10-default.network
echo "[Network]" >> /etc/systemd/network/10-default.network
echo "DHCP=yes" >> /etc/systemd/network/10-default.network

systemctl enable systemd-networkd

# Boot loader
bootctl --path=/boot install

echo "default arch" > /boot/loader/loader.conf
echo "timeout 0" >> /boot/loader/loader.conf
echo "editor 0" >> /boot/loader/loader.conf

echo "title Arch Linux" > /boot/loader/entries/arch.conf
echo "linux /vmlinuz-linux-lts" >> /boot/loader/entries/arch.conf
echo "initrd /initramfs-linux-lts.img" >> /boot/loader/entries/arch.conf
echo "options root=PARTUUID=$(blkid -s PARTUUID -o value /dev/sda2) rw init=/usr/lib/systemd/systemd" >> /boot/loader/entries/arch.conf

echo "Done! Now quit and don't forget to umount -R /mnt before reboot"

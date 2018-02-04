#!/usr/bin/env bash

set -o allexport
source ./env
set +o allexport

set -o errexit
set -o nounset

part() {
	echo "Partitioning..."

	local readonly ALIGNMENT_OFFSET_FILE="/sys/block/sda/queue/alignment_offset"
	if [[ -f "${ALIGNMENT_OFFSET_FILE}" ]]; then
		local readonly ALIGNMENT_OFFSET=$(cat ${ALIGNMENT_OFFSET_FILE})
		local readonly OPTIMAL_IO_SIZE=$(cat /sys/block/sda/queue/optimal_io_size)
		local readonly PHYSICAL_BLOCK_SIZE=$(cat /sys/block/sda/queue/physical_block_size)
		local readonly ESP_START=(${OPTIMAL_IO_SIZE}+${ALIGNMENT_OFFSET})/${PHYSICAL_BLOCK_SIZE}
	else
		local readonly ESP_START=1
	fi

	local readonly ESP_SIZE=102
	parted /dev/sda --script mktable gpt
	parted /dev/sda --script mkpart primary fat32 ${ESP_START}MiB ${ESP_SIZE}MiB
	parted /dev/sda --script name 1 esp
	parted /dev/sda --script set 1 boot on
	parted /dev/sda --script set 1 esp on
	parted /dev/sda --script mkpart primary ext4 ${ESP_SIZE}MiB 100%
	parted /dev/sda --script name 2 system
}

format() {
	echo "Creating filesystesm..."
	mkfs.fat /dev/sda1 -F 32 -n ESP
	mkfs.ext4 /dev/sda2 -L System
}

mount() {
	echo "Mounting filesystems..."
	command mount /dev/sda2 /mnt
	mkdir /mnt/boot
	command mount /dev/sda1 /mnt/boot
}

set-hostname() {
	hostnamectl set-hostname "${HOSTNAME}"
}

set-locales() {
	echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
	locale-gen
	echo LANG=en_US.UTF-8 > /etc/locale.conf
}

set-up-network() {
	echo "[Match]" > /etc/systemd/network/10-default.network
	echo "Name=en*" >> /etc/systemd/network/10-default.network
	echo "[Network]" >> /etc/systemd/network/10-default.network
	echo "DHCP=yes" >> /etc/systemd/network/10-default.network

	systemctl enable systemd-networkd
	systemctl enable systemd-resolved
}

set-time() {
	if [ "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/.)" ]; then
		ln -sf /usr/share/zoneinfo/"${TIME_ZONE}" /etc/localtime
	else
		timedatectl set-timezone "${TIME_ZONE}"
	fi
}

set-packages() {
	if [ "$(stat -c %d:%i /)" = "$(stat -c %d:%i /proc/1/root/.)" ]; then
		while :
		do
			DELETE_CANDIDATES=$(pacman -Qet | while read a b; do echo "$a"; done)
			KEEP=$(echo "$DELETE_CANDIDATES $DESIRED_PKGS" | tr ' ' '\n' | sort | uniq -d)
			if [ "$KEEP" = "$DELETE_CANDIDATES" ]; then
				break
			fi
			pacman -Rns --noconfirm $(echo "${KEEP} ${DELETE_CANDIDATES}" | tr ' ' '\n' | sort | uniq -u | tr '\n' ' ')
		done
	fi

	pacman -Syu --noconfirm $DESIRED_PKGS
}

set-up-pam() {
	echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su
	echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su-l
}

set-up-postgresql() {
	pacman -Syu --noconfirm postgresql
	echo "es_CL.UTF-8 UTF-8" >> /etc/locale.gen
	locale-gen
	sudo -iu postgres initdb \
		--auth-local peer \
		--auth-host md5 \
		--encoding UTF8 \
		--locale en_US.UTF-8 \
		--pgdata /var/lib/postgres/data
	systemctl enable postgresql
	systemctl start postgresql
	sudo -u postgres psql -f conf/set-up-postgresql.sql
	cp conf/back-up-postgresql /home/backups/bin/
	cp conf/back-up-postgresql.* /etc/systemd/system/
	systemctl enable back-up-postgresql.timer
	systemctl start back-up-postgresql.timer
}

set-users() {
	if [ $(id -u backups > /dev/null 2>&1; echo $?) -eq 1 ]; then
		useradd backups \
			--system \
			--create-home \
			--user-group \
			--shell /usr/bin/nologin
		chmod 750 /home/backups
	fi

	if [ $(id -u "$USERNAME" > /dev/null 2>&1; echo $?) -eq 1 ]; then
		useradd -m -G wheel -s /bin/bash ${USERNAME}
		gpasswd -a "${USERNAME}" backups
		echo "${USERNAME}:${USER_PASSWORD}" | chpasswd
		echo "root:${SU_PASSWORD}" | chpasswd

		if ["$USERNAME" = vagrant]; then
			echo "vagrant ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
			curl --output key.pub \
				https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant.pub
		fi

		mkdir /home/${USERNAME}/.ssh
		cp key.pub /home/${USERNAME}/.ssh/authorized_keys
		chmod 400 /home/${USERNAME}/.ssh/authorized_keys
		chmod 700 /home/${USERNAME}/.ssh
		chown ${USERNAME}: -R /home/${USERNAME}/.ssh
		chattr +i /home/${USERNAME}/.ssh/authorized_keys
		chattr +i /home/${USERNAME}/.ssh
	fi
}

set-up-securetty() {
	echo "hvc0" > /etc/securetty
}

enable-services() {
	systemctl enable logrotate.timer
	systemctl enable nftables
	systemctl enable systemd-timesyncd
	systemctl set-default multi-user.target
}

set-up-sshd() {
	cp conf/sshd /etc/ssh/sshd_config
}

set-up-sudoers() {
	cp conf/sudoers /etc/sudoers
}

set-up-bootloader() {
	if [ -d /sys/firmware/efi ]; then
		bootctl --path=/boot install
		cp conf/loader.conf /boot/loader/loader.conf
		cp conf/arch.conf /boot/loader/entries/arch.conf
	else
		pacman -S --noconfirm syslinux
		syslinux-install_update -iam
		cp conf/syslinux.cfg /boot/syslinux/syslinux.cfg
	fi
}

case $1 in
	new)
		timedatectl set-ntp true
		part
		format
		mount
		set-packages
		genfstab -pL /mnt >> /mnt/etc/fstab
		# TODO: Write my own optimized fstab
		cp --recursive conf /mnt/conf
		export -f set-locales
		arch-chroot /mnt /bin/bash -c "set-locales"
		export -f set-time
		arch-chroot /mnt /bin/bash -c "set-time"
		export -f set-up-network
		arch-chroot /mnt /bin/bash -c "set-up-network"
		export -f set-up-pam
		arch-chroot /mnt /bin/bash -c "set-up-pam"
		export -f set-up-securetty
		arch-chroot /mnt /bin/bash -c "set-up-securetty"
		export -f set-up-sshd
		arch-chroot /mnt /bin/bash -c "set-up-sshd"
		export -f set-up-sudoers
		arch-chroot /mnt /bin/bash -c "set-up-sudoers"
		export -f set-up-bootloader
		arch-chroot /mnt /bin/bash -c "set-up-bootloader"
		export -f set-users
		arch-chroot /mnt /bin/bash -c "set-users"
		export -f enable-services
		arch-chroot /mnt /bin/bash -c "enable-services"
		arch-chroot /mnt echo "blacklist i2c_piix4" > /etc/modprobe.d/i2c_piix4.conf
		rm --recursive /mnt/conf
		echo "Done! Rebooting..."
		systemctl reboot
		;;
	vm)
		timedatectl set-ntp true
		set-hostname
		set-locales
		set-packages
		set-time
		set-up-pam
		set-up-securetty
		set-up-sshd
		set-up-sudoers
		set-up-bootloader
		set-users
		enable-services
		echo "Done!"
		;;
	*)
		# TODO: Add help
		;;
esac

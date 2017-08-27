.PHONY: hostname
hostname:
	sh bin/hostname.sh

.PHONY: locales
locales:
	sh bin/locales.sh

.PHONY: network
network:
	sh bin/network.sh

.PHONY: time
time:
	sh bin/time.sh

.PHONY: packages
packages:
	sh bin/packages.sh

pam:
	echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su
	echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su-l

postgresql:
	sh bin/postgresql.sh
	sudo -u postgres psql -f etc/set-up-postgresql.sql
	cp etc/back-up-postgresql /home/backups/bin/
	cp etc/back-up-postgresql.* /etc/systemd/system/
	systemctl enable back-up-postgresql.timer
	systemctl start back-up-postgresql.timer

.PHONY: users
users:
	sh bin/users.sh

shutdown:
	cp etc/shutdown /usr/local/bin/shutdown
	chmod +x /usr/local/bin/shutdown

securetty:
	echo "hvc0" > /etc/securetty

.PHONY: services
services:
	systemctl enable logrotate.timer
	systemctl enable nftables
	systemctl enable systemd-timesyncd
	systemctl set-default multi-user.target

sshd:
	cp etc/sshd /etc/ssh/sshd_config

sudoers:
	cp etc/sudoers /etc/sudoers

syslinux:
	syslinux-install_update -iam
	cp etc/syslinux.cfg /boot/syslinux/syslinux.cfg

systemd-boot:
	bootctl --path=/boot install
	cp etc/loader.conf /boot/loader/loader.conf
	cp etc/arch.conf /boot/loader/entries/arch.conf

# Main stuff

.PHONY: install
install:
	sh bin/install.sh

.PHONY: box
box:
	sh bin/box.sh

.PHONY: production
production: hostname locales packages pam securetty services sshd sudoers syslinux time users
	timedatectl set-ntp true
	echo "Done!"

.PHONY: development
development: locales network pam securetty services shutdown sshd sudoers systemd-boot time
	pacman -Scc --noconfirm
	useradd -m -G wheel -s /bin/bash vagrant
	echo "vagrant:vagrant" | chpasswd
	echo "root:vagrant" | chpasswd
	echo "vagrant ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
	mkdir /home/vagrant/.ssh
	curl https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub -o /home/vagrant/.ssh/authorized_keys
	chown -R vagrant:vagrant /home/vagrant/.ssh
	chmod 0400 /home/vagrant/.ssh/authorized_keys
	chmod 0700 /home/vagrant/.ssh
	echo "blacklist i2c_piix4" > /etc/modprobe.d/i2c_piix4.conf
	systemctl enable sshd.socket
	systemctl enable vboxservice

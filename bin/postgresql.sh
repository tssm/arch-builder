#!/usr/bin/env bash

set -o errexit
set -o nounset

pacman -Syu --noconfirm postgresql
echo "es_CL.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
sudo -iu postgres initdb\
	--auth-local peer\
	--auth-host md5\
	--encoding UTF8\
	--locale en_US.UTF-8\
	--pgdata "/var/lib/postgres/data"
	systemctl enable postgresql
	systemctl start postgresql

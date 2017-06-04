#!/usr/bin/env bash

set -o errexit
set -o nounset

# TODO: Make a explicit list of needed packages an remove every package that appears on -Qet but not in that list
pacman -Syu --noconfirm git\
	gptfdisk\
	linux-lts\
	neovim\
	nftables\
	python-neovim\
	rsync\
	syslinux\
	xclip
pacman -Rns --noconfirm dhcpcd\
	diffutils\
	file\
	inetutils\
	grub\
	haveged\
	jfsutils\
	licenses\
	linux\
	lvm2\
	mdadm\
	nano\
	netctl\
	pcmciautils\
	reiserfsprogs\
	s-nail\
	parted\
	tar\
	usbutils\
	vi\
	which\
	xfsprogs

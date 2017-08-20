#!/usr/bin/env bash

set -o errexit
set -o nounset

readonly NATURAL_REGEX="^[0-9]+$"

readonly DEFAULT_MACHINE_NAME="Test"
readonly DEFAULT_DRIVE_SIZE=3000
readonly DEFAULT_MEMORY_SIZE=512

echo Machine name, default ${DEFAULT_MACHINE_NAME}:
read MACHINE_NAME
if [[ -z "${MACHINE_NAME}" ]]; then
	MACHINE_NAME=${DEFAULT_MACHINE_NAME}
fi

while :
do
	echo "Machine memory (in mebibytes), default ${DEFAULT_MEMORY_SIZE}":
	read MACHINE_MEMORY
	if [[ "${MACHINE_MEMORY}" =~ $NATURAL_REGEX ]]; then
		break
	elif [[ -z "${MACHINE_MEMORY}" ]]; then
		MACHINE_MEMORY=$DEFAULT_MEMORY_SIZE
		break
	fi
done

while :
do
	echo "Drive size (in megabytes), default $DEFAULT_DRIVE_SIZE":
	read DRIVE_SIZE
	if [[ "${DRIVE_SIZE}" =~ $NATURAL_REGEX ]]; then
		break
	elif [[ -z "${DRIVE_SIZE}" ]]; then
		DRIVE_SIZE=$DEFAULT_DRIVE_SIZE
		break
	fi
done

readonly DRIVE_PATH="$HOME/VirtualBox VMs/${MACHINE_NAME}/${MACHINE_NAME}"

VBoxManage createvm --name "${MACHINE_NAME}" --ostype ArchLinux_64 --register
VBoxManage createmedium disk --filename "${DRIVE_PATH}" --size "${DRIVE_SIZE}" --variant Standard
VBoxManage storagectl "${MACHINE_NAME}" --name SATA --add sata --controller IntelAHCI
VBoxManage storageattach "${MACHINE_NAME}" --storagectl SATA --port 0 --type hdd --medium "${DRIVE_PATH}.vdi"
VBoxManage modifyvm "${MACHINE_NAME}" --audio none
VBoxManage modifyvm "${MACHINE_NAME}" --firmware efi
VBoxManage modifyvm "${MACHINE_NAME}" --memory "${MACHINE_MEMORY}"
VBoxManage modifyvm "${MACHINE_NAME}" --natpf1 "ssh,tcp,,2222,,22"
VBoxManage modifyvm "${MACHINE_NAME}" --nictype1 virtio
VBoxManage modifyvm "${MACHINE_NAME}" --rtcuseutc on
VBoxManage modifyvm "${MACHINE_NAME}" --boot1 disk
VBoxManage modifyvm "${MACHINE_NAME}" --boot2 none
VBoxManage modifyvm "${MACHINE_NAME}" --boot3 none
VBoxManage modifyvm "${MACHINE_NAME}" --boot4 none

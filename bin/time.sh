#!/usr/bin/env bash

set -o errexit
set -o nounset

while :
do
	echo "Enter time zone:"
	read TIME_ZONE
	echo "Enter time sub-zone:"
	read TIME_SUB_ZONE
	if [[ -n "${TIME_ZONE}" && -n "${TIME_SUB_ZONE}" ]]; then
		if [ "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/.)" ]; then
			ln -sf /usr/share/zoneinfo/"${TIME_ZONE}"/"${TIME_SUB_ZONE}" /etc/localtime
		else
			timedatectl set-timezone "${TIME_ZONE}"/"${TIME_SUB_ZONE}"
		fi
		break
	fi
done

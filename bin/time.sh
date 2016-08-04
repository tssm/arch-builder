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
		ln -s /usr/share/zoneinfo/"${TIME_ZONE}"/"${TIME_SUB_ZONE}" /etc/localtime
		break
	fi
done

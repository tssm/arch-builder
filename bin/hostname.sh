#!/usr/bin/env bash

set -o errexit
set -o nounset

while :
do
	echo "Enter hostname:"
	read HOSTNAME
	if [[ -n "${HOSTNAME}" ]]; then
		hostnamectl set-hostname ${HOSTNAME}
		break
	fi
done

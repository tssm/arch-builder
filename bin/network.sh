#!/usr/bin/env bash

set -o errexit
set -o nounset

echo "[Match]" > /etc/systemd/network/10-default.network
echo "Name=en*" >> /etc/systemd/network/10-default.network
echo "[Network]" >> /etc/systemd/network/10-default.network
echo "DHCP=yes" >> /etc/systemd/network/10-default.network

systemctl enable systemd-networkd
systemctl enable systemd-resolved

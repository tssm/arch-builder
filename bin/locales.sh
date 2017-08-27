#!/usr/bin/env bash

set -o errexit
set -o nounset

echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8 > /etc/locale.conf

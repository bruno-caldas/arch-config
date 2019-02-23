#!/bin/bash

DISK='/dev/sda'

format_disk() {
  local memory=vmstat -s -S M | grep 'total memory' | tr -dc '0-9'
  local memory_addr=$(($memory + 100))M

  echo "Formatting disk"
  parted -s "$DISK" \
    mklabel msdos \
    mkpart primary ext4 1 100M \
    mkpart primary ext4 $memory_addr 100% \
    mkpart primary linux-swap 100M  $memory_addr\
    set 1 boot on \
    set 2 LVM on
    set 3 SWAP on
}

install_arch() {
  format_disk
}

install_arch

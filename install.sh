#!/bin/bash

DISK='/dev/sda'

# System configuration variables
TIMEZONE='America/Sao_Paulo'
LOCALE='pt_BR.UTF-8 UTF-8'
USERNAME=
PASSWORD=
HOSTNAME=

user_configurations() {
  echo "Choose your user name"
  read USERNAME
  echo "Set your root password"
  read -s PASSWORD
  echo "Set your hostname:"
  read HOSTNAME
}

config_partitions() {
  local boot_size=256
  local memory=$(vmstat -s -S M | grep 'total memory' | tr -dc '0-9')
  local memory_addr=$(($memory + $boot_size))M

  echo "Formatting disk"
  parted -s "$DISK" \
    mklabel msdos \
    mkpart primary ext2 1 "$boot_size"M \
    mkpart primary ext4 $memory_addr 100% \
    mkpart primary linux-swap "$boot_size"M  $memory_addr \
    set 1 boot on \
    set 2 LVM on \
    set 3 LVM on
}

format_disk() {
  local boot_dev="$DISK"1
  local lvm_dev="$DISK"2
  local swap_dev="$DISK"3

  config_partitions

  mkfs.ext2 -L boot "$boot_dev"
  mkfs.ext4 -L root "$lvm_dev"
  mkswap $swap_dev
  swapon $swap_dev

  mount $lvm_dev /mnt
  mkdir /mnt/boot
  mount $boot_dev /mnt/boot
}

install_base() {
  pacstrap /mnt base base-devel
}

config_locale() {
  echo 'LANG="en_US.UTF-8"' >> /etc/locale.conf
  echo 'LC_COLLATE="C"' >> /etc/locale.conf
  echo  $LOCALE >> /etc/locale.gen
  locale-gen
}

set_hostname() {
  cat > /etc/hosts <<EOF
127.0.0.1 localhost
::1  localhost
127.0.1.1 "$HOSTNAME".localdomain	$HOSTNAME
EOF
}

create_user() {
  useradd -m -s /bin/zsh -G root sudo "$USERNAME"
  echo -en "$PASSWORD\n$PASSWORD" | passwd "$USERNAME"
}

config_system() {
  genfstab -U /mnt >> /mnt/etc/fstab
  arch-chroot /mnt
  ln -sT "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
  hwclock --systohc
  config_locale
  set_hostname
  echo -en "$PASSWORD\n$PASSWORD" | passwd
  create_user
}

install_arch() {
  user_configurations
  format_disk
  install_base
  config_system
}

install_arch

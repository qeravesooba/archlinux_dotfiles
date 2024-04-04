#!/bin/bash

TIMEZONE="Europe/Berlin"
DRIVE="sda"
EFI_PARTLABEL="EFI"
EFI_SIZE="512MiB"
SWAP_PARTLABEL="SWAP"
SWAP_SIZE="1GiB"
ROOT_PARTLABEL="ROOT"
BTRFS_MOUNT_OPTIONS="noatime,compress=zstd:4,autodefrag"
HOSTNAME="archlinux"
ROOT_PASSWORD="password"
USER_NAME="user"
USER_GROUPS="audio,network,video,storage,wheel"
USER_PASSWORD="password"
LOADER_LABEL="archlinux"
KERNEL_PARAMETERS="rw ibt=off mem_sleep_default=deep quiet loglevel=3 audit=0"

if [ ! -d "/sys/firmware/efi/efivars" ]
then
    echo "Error: not booted in efi mode"
    exit 1
fi

timedatectl set-ntp true
timedatectl set-timezone ${TIMEZONE}
timedatectl status

wipefs --all /dev/${DRIVE}
cryptsetup open --type plain -d /dev/urandom /dev/${DRIVE} "to_be_wiped"
dd if=/dev/zero of=/dev/mapper/"to_be_wiped" bs=4096 status=progress
cryptsetup close "to_be_wiped"

sgdisk -g /dev/${DRIVE}
sgdisk --new=1:0:+${EFI_SIZE}  --typecode=1:ef00 --change-name=1:${EFI_PARTLABEL} \
       --new=2:0:+${SWAP_SIZE} --typecode=2:8200 --change-name=2:${SWAP_PARTLABEL} \
       --new=3:0:0             --typecode=3:8300 --change-name=3:${ROOT_PARTLABEL} /dev/${DRIVE}

mkfs.btrfs --force /dev/disk/by-partlabel/${ROOT_PARTLABEL}
mount -t btrfs PARTLABEL=${ROOT_PARTLABEL} /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@tmp
btrfs subvolume create /mnt/@usr_local
btrfs subvolume create /mnt/@var_cache
btrfs subvolume create /mnt/@var_log
btrfs subvolume create /mnt/@var_tmp
btrfs subvolume create /mnt/@snapshots
umount -R /mnt

mount -t btrfs -o x-mount.mkdir,${BTRFS_MOUNT_OPTIONS},subvol=@          PARTLABEL=${ROOT_PARTLABEL} /mnt
mount -t btrfs -o x-mount.mkdir,${BTRFS_MOUNT_OPTIONS},subvol=@home      PARTLABEL=${ROOT_PARTLABEL} /mnt/home
mount -t btrfs -o x-mount.mkdir,${BTRFS_MOUNT_OPTIONS},subvol=@tmp       PARTLABEL=${ROOT_PARTLABEL} /mnt/tmp
mount -t btrfs -o x-mount.mkdir,${BTRFS_MOUNT_OPTIONS},subvol=@usr_local PARTLABEL=${ROOT_PARTLABEL} /mnt/usr/local
mount -t btrfs -o x-mount.mkdir,${BTRFS_MOUNT_OPTIONS},subvol=@var_cache PARTLABEL=${ROOT_PARTLABEL} /mnt/var/cache
mount -t btrfs -o x-mount.mkdir,${BTRFS_MOUNT_OPTIONS},subvol=@var_log   PARTLABEL=${ROOT_PARTLABEL} /mnt/var/log
mount -t btrfs -o x-mount.mkdir,${BTRFS_MOUNT_OPTIONS},subvol=@var_tmp   PARTLABEL=${ROOT_PARTLABEL} /mnt/var/tmp
mount -t btrfs -o x-mount.mkdir,${BTRFS_MOUNT_OPTIONS},subvol=@snapshots PARTLABEL=${ROOT_PARTLABEL} /mnt/.snapshots

mkswap -L swap /dev/disk/by-partlabel/${SWAP_PARTLABEL}
swapon -L swap

mkfs.fat -F32 -n EFI /dev/disk/by-partlabel/${EFI_PARTLABEL}
mkdir /mnt/boot
mount PARTLABEL=${EFI_PARTLABEL} /mnt/boot

pacstrap /mnt base base-devel

genfstab -U /mnt > /mnt/etc/fstab

arch-chroot /mnt ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
arch-chroot /mnt hwclock --systohc --utc

sed -i "s/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g" /mnt/etc/locale.gen
sed -i "s/#ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/g" /mnt/etc/locale.gen
arch-chroot /mnt locale-gen

echo ${HOSTNAME} > /mnt/etc/hostname
echo -n "127.0.0.1    localhost\n::1          localhost\n127.0.1.1    ${HOSTNAME}.localdomain\n::1          ${HOSTNAME}.localdomain" > /mnt/etc/hosts

echo "root:${ROOT_PASSWORD}" | arch-chroot /mnt chpasswd

sed -i "s/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/" /mnt/etc/sudoers

arch-chroot /mnt pacman --noconfirm -Sy archlinux-keyring
arch-chroot /mnt pacman --noconfirm -S linux linux-firmware linux-headers intel-ucode btrfs-progs efibootmgr zsh networkmanager neovim git openssh openssl openvpn reflector

arch-chroot /mnt systemctl enable NetworkManager.service

arch-chroot /mnt useradd -m -g users -G ${USER_GROUPS} -s /bin/zsh ${USER_NAME}
echo "${USER_NAME}:${USER_PASSWORD}" | arch-chroot /mnt chpasswd

sed -i "s/^MODULES=.*/MODULES=(btrfs)/" /mnt/etc/mkinitcpio.conf
sed -i "s/^HOOKS=.*/HOOKS=(base keyboard udev autodetect modconf block filesystems resume)/" /mnt/etc/mkinitcpio.conf
arch-chroot /mnt mkinitcpio -P

arch-chroot /mnt efibootmgr --create \
                            --gpt \
                            --disk /dev/${DRIVE} \
                            --part 1 \
                            --label ${LOADER_LABEL} \
                            --loader /vmlinuz-linux \
                            --unicode "root=PARTLABEL=${ROOT_PARTLABEL} rootflags=${BTRFS_MOUNT_OPTIONS},subvol=@ resume=PARTLABEL=${SWAP_PARTLABEL} initrd=\intel-ucode.img initrd=\initramfs-linux.img ${KERNEL_PARAMETERS}" \
                            --verbose

TIMESTAMP=$(date +"%s")
arch-chroot /mnt btrfs subvolume snapshot -r /     /.snapshots/root_${TIMESTAMP}
arch-chroot /mnt btrfs subvolume snapshot -r /home /.snapshots/home_${TIMESTAMP}

swapoff /dev/disk/by-partlabel/${SWAP_PARTLABEL}
umount -R /mnt
reboot
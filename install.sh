#!/bin/bash

if [ -z "$1" ]
then
    echo "Enter your username: "
    read user
else
    user=$1
fi

if [ -z "$2" ]
then
    echo "Enter your master password: "
    read -s password
else
    password=$2
fi

#if [ -z "$3" ]
#then
    #echo "Do you want to skip rankmirrors (faster upfront)? [y/N] "
    #read response
    #if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]
    #then
        #fast=1
    #else
        #fast=0
    #fi
#else
    #fast=$3
#fi

# set time
timedatectl set-ntp true

#partiton disk
parted --script /dev/sda mklabel msdos mkpart primary ext4 0% 87% mkpart primary linux-swap 87% 100%
mkfs.ext4 /dev/sda1
mkswap /dev/sda2
swapon /dev/sda2
mount /dev/sda1 /mnt

#update pacman database first, and install pacman-contrib for rankmirrors
pacman -Sy
pacman -S --noconfirm pacman-contrib

# Rank mirror first to speed up pacstrap download
#if [ "$fast" -eq "1"]
#then
echo 'Downloading list of BR and US mirrors'
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
wget "https://www.archlinux.org/mirrorlist/?country=BR&country=US&protocol=http&protocol=https&ip_version=4" -O /etc/pacman.d/mirrorlist.unranked
echo 'Setting up mirrors'
sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist.unranked
rankmirrors -n 12 /etc/pacman.d/mirrorlist.unranked > /etc/pacman.d/mirrorlist
#else
    #echo 'Skipping mirror ranking because fast'
#fi

# pacstrap
pacstrap /mnt base

# fstab
genfstab -U /mnt >> /mnt/etc/fstab
#echo "org /home/$user/org vboxsf uid=$user,gid=wheel,rw,dmode=700,fmode=600,nofail 0 0" >> /mnt/etc/fstab
#echo "workspace /home/$user/workspace vboxsf uid=$user,gid=wheel,rw,dmode=700,fmode=600,nofail 0 0" >> /mnt/etc/fstab

# chroot
wget https://raw.githubusercontent.com/RenatoLacerda92/spartan-arch/master/chroot-install.sh -O /mnt/chroot-install.sh
arch-chroot /mnt /bin/bash ./chroot-install.sh $user $password $fast

# reboot
umount /mnt
reboot

#!/bin/bash

# Exit if any command fails
set -e

LOG_FILE="/mnt/install_progress.log"

echo "🚀 Arch Linux ARM Full Automated Installer - Parallels (AArch64) 🚀"

### FUNCTION TO ASK YES/NO ###
ask() {
    while true; do
        read -p "$1 (y/n): " yn
        case $yn in
            [Yy]* ) return 0;;  # Continue to next step
            [Nn]* ) echo "❌ Installation Aborted!"; exit 1;;
            * ) echo "Please answer y or n.";;
        esac
    done
}

### FUNCTION TO CHECK PROGRESS ###
check_progress() {
    grep -Fxq "$1" "$LOG_FILE" && return 1 || return 0
}

### FUNCTION TO UNMOUNT EVERYTHING ###
cleanup_mounts() {
    echo "🔄 Cleaning up old mounts..."
    sudo umount -l /mnt/boot/efi 2>/dev/null || true
    sudo umount -l /mnt/sys 2>/dev/null || true
    sudo umount -l /mnt/proc 2>/dev/null || true
    sudo umount -l /mnt/dev 2>/dev/null || true
    sudo umount -l /mnt/run 2>/dev/null || true
    sudo umount -l /mnt 2>/dev/null || true
}

### FUNCTION TO CHECK MOUNTS ###
check_mounts() {
    echo "📡 Checking if /mnt is already mounted..."
    if mount | grep -q "/mnt"; then
        echo "⚠️ /mnt is already mounted. Unmounting..."
        cleanup_mounts
    fi
}

### FUNCTION TO FIX CHROOT ISSUES ###
fix_chroot() {
    echo "🔍 Checking if chroot setup is broken..."
    for dir in /mnt/proc /mnt/sys /mnt/dev /mnt/run; do
        if ! mountpoint -q "$dir"; then
            echo "⚠️ $dir is not mounted! Fixing..."
            mount --rbind /sys /mnt/sys
            mount --rbind /dev /mnt/dev
            mount --rbind /run /mnt/run
            mount -t proc /proc /mnt/proc
        fi
    done
}

echo "📄 Creating Progress Log at $LOG_FILE"
touch "$LOG_FILE"

# Step 1: Update Ubuntu Live & Install `arch-chroot`
if check_progress "INSTALL_CHROOT_DONE"; then
    ask "📦 Update Ubuntu Live & Install arch-chroot?"
    sudo apt update -y || { echo "❌ Failed to update packages. Check your network."; exit 1; }
    sudo apt install -y arch-install-scripts || { echo "❌ Failed to install arch-install-scripts."; exit 1; }
    echo "INSTALL_CHROOT_DONE" >> "$LOG_FILE"
fi

# Step 2: Wipe Disk and Partition
if check_progress "PARTITION_DONE"; then
    ask "🛠️ Wipe and partition the disk?"
    check_mounts
    wipefs -a /dev/sda
    echo "🛠️ Partitioning Disk..."
    (
    echo g        # Create GPT Partition Table
    echo n        # New Partition (EFI)
    echo 1        # Partition Number 1
    echo          # Default first sector
    echo +512M    # EFI Partition
    echo t        # Change partition type
    echo 1        # Set type to EFI

    echo n        # New Partition (Root)
    echo 2        # Partition Number 2
    echo          # Default first sector
    echo          # Use remaining space

    echo w        # Write changes
    ) | fdisk /dev/sda
    echo "PARTITION_DONE" >> "$LOG_FILE"
fi

# Step 3: Format Partitions
if check_progress "FORMAT_DONE"; then
    ask "🖥️ Format partitions?"
    mkfs.fat -F32 /dev/sda1
    mkfs.ext4 /dev/sda2
    echo "FORMAT_DONE" >> "$LOG_FILE"
fi

# Step 4: Mount Partitions
if check_progress "MOUNT_DONE"; then
    ask "📂 Mount partitions?"
    mount /dev/sda2 /mnt
    mkdir -p /mnt/boot/efi
    mount /dev/sda1 /mnt/boot/efi
    echo "MOUNT_DONE" >> "$LOG_FILE"
fi

# Step 5: Download & Extract Arch Linux ARM
if check_progress "DOWNLOAD_DONE"; then
    ask "📦 Download and extract Arch Linux ARM?"
    wget --tries=3 --timeout=20 -O /mnt/arch.tar.gz http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz || {
        echo "❌ Failed to download Arch Linux ARM. Check your internet connection."
        exit 1
    }
    tar -xpf /mnt/arch.tar.gz -C /mnt
    sync
    echo "DOWNLOAD_DONE" >> "$LOG_FILE"
fi

# Step 6: Prepare for chroot
if check_progress "MOUNT_SYSTEM_DONE"; then
    ask "🔗 Mount system directories?"
    fix_chroot
    echo "MOUNT_SYSTEM_DONE" >> "$LOG_FILE"
fi

# Step 7: Enter Chroot and Install Arch Linux
if check_progress "CHROOT_DONE"; then
    ask "🚀 Enter chroot?"
    arch-chroot /mnt /bin/bash << 'EOF'

# Step 8: System Configuration
echo "🌍 Setting up Locale and Timezone..."
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=us" > /etc/vconsole.conf
echo "archlinux" > /etc/hostname
echo "127.0.1.1 archlinux.localdomain archlinux" >> /etc/hosts

# Generate Locale
sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen

# Step 9: Install Essential Packages
pacman -Syu --noconfirm
pacman -S base linux linux-firmware nano sudo networkmanager grub efibootmgr bash-completion \
mesa git xdg-utils xdg-user-dirs --noconfirm

# Step 10: Install Bootloader
grub-install --target=arm64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Step 11: Set Root Password
echo "root:toor" | chpasswd

EOF
    echo "CHROOT_DONE" >> "$LOG_FILE"
fi

# Step 12: Unmount & Reboot
if check_progress "REBOOT_DONE"; then
    ask "🔄 Unmount and reboot?"
    cleanup_mounts
    reboot
    echo "REBOOT_DONE" >> "$LOG_FILE"
fi
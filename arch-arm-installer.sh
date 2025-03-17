#!/bin/bash

# Exit on error
set -e

LOG_FILE="/mnt/install_progress.log"

echo "🚀 Arch Linux ARM Full Automated Installer - Parallels (AArch64) 🚀"

### FUNCTION TO ASK YES/NO ###
ask() {
    while true; do
        read -p "$1 (y/n): " yn
        case $yn in
            [Yy]* ) return 0;;  # Continue
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
    sudo umount -lf /mnt/boot/efi 2>/dev/null || true
    sudo umount -lf /mnt/sys 2>/dev/null || true
    sudo umount -lf /mnt/proc 2>/dev/null || true
    sudo umount -lf /mnt/dev 2>/dev/null || true
    sudo umount -lf /mnt/run 2>/dev/null || true
    sudo umount -lf /mnt 2>/dev/null || true
}

### FUNCTION TO CHECK & FIX CHROOT ###
fix_chroot() {
    echo "🔍 Checking chroot setup..."
    cleanup_mounts

    # Ensure dependencies exist
    sudo apt update && sudo apt install -y arch-install-scripts

    # Ensure clean mount
    sudo mount -t proc /proc /mnt/proc
    sudo mount --rbind /sys /mnt/sys
    sudo mount --rbind /dev /mnt/dev
    sudo mount --rbind /run /mnt/run
}

### FUNCTION TO ENTER CHROOT SAFELY ###
enter_chroot() {
    echo "🚀 Attempting to enter Arch Linux Chroot..."
    
    # Try normal arch-chroot
    if arch-chroot /mnt; then
        echo "✅ Successfully entered chroot using arch-chroot!"
        return 0
    fi
    
    # Try standard chroot
    if chroot /mnt /bin/bash; then
        echo "✅ Successfully entered chroot using chroot!"
        return 0
    fi

    # Try systemd-nspawn
    if systemd-nspawn -D /mnt; then
        echo "✅ Successfully entered chroot using systemd-nspawn!"
        return 0
    fi

    # Try using env -i
    if sudo env -i HOME=/root TERM="$TERM" /usr/sbin/chroot /mnt /bin/bash; then
        echo "✅ Successfully entered chroot using env!"
        return 0
    fi

    echo "❌ Chroot failed! Debugging info:"
    dmesg | tail -50
    exit 1
}

# Create log file
echo "📄 Creating Progress Log at $LOG_FILE"
touch "$LOG_FILE"

# Step 1: Partitioning
if check_progress "PARTITION_DONE"; then
    ask "🛠️ Partition and format the disk?"
    cleanup_mounts
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

# Step 2: Format Partitions
if check_progress "FORMAT_DONE"; then
    ask "🖥️ Format partitions?"
    mkfs.fat -F32 /dev/sda1
    mkfs.ext4 /dev/sda2
    echo "FORMAT_DONE" >> "$LOG_FILE"
fi

# Step 3: Mount Partitions
if check_progress "MOUNT_DONE"; then
    ask "📂 Mount partitions?"
    mount /dev/sda2 /mnt
    mkdir -p /mnt/boot/efi
    mount /dev/sda1 /mnt/boot/efi
    echo "MOUNT_DONE" >> "$LOG_FILE"
fi

# Step 4: Download & Extract Arch Linux ARM
if check_progress "DOWNLOAD_DONE"; then
    ask "📦 Download and extract Arch Linux ARM?"
    wget http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz -O /mnt/arch.tar.gz
    tar -xpf /mnt/arch.tar.gz -C /mnt
    sync
    echo "DOWNLOAD_DONE" >> "$LOG_FILE"
fi

# Step 5: Prepare for chroot
if check_progress "MOUNT_SYSTEM_DONE"; then
    ask "🔗 Mount system directories?"
    fix_chroot
    echo "MOUNT_SYSTEM_DONE" >> "$LOG_FILE"
fi

# Step 6: Enter Chroot
if check_progress "CHROOT_DONE"; then
    ask "🚀 Enter chroot and install Arch Linux?"
    enter_chroot << 'EOF'

# Step 7: System Configuration
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
echo "LOCALE_DONE" >> "$LOG_FILE"

# Step 8: Install Essential Packages
if check_progress "PACKAGES_DONE"; then
    ask "🛠️ Install essential packages?"
    pacman -Syu --noconfirm
    pacman -S base linux linux-firmware nano sudo networkmanager grub efibootmgr bash-completion \
    mesa git xdg-utils xdg-user-dirs --noconfirm
    echo "PACKAGES_DONE" >> "$LOG_FILE"
fi

# Step 9: Install Bootloader
if check_progress "BOOTLOADER_DONE"; then
    ask "🔧 Install bootloader?"
    grub-install --target=arm64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
    grub-mkconfig -o /boot/grub/grub.cfg
    echo "BOOTLOADER_DONE" >> "$LOG_FILE"
fi

echo "✅ Installation Complete! Exiting Chroot..."
EOF
    echo "CHROOT_DONE" >> "$LOG_FILE"
fi

# Step 10: Unmount & Reboot
if check_progress "REBOOT_DONE"; then
    ask "🔄 Unmount and reboot?"
    cleanup_mounts
    reboot
    echo "REBOOT_DONE" >> "$LOG_FILE"
fi

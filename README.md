# 🚀 Arch Linux ARM Automated Installer for Parallels (AArch64)

This script automates the installation of **Arch Linux ARM** on **Parallels (AArch64) or any linux live system**.  
It handles **partitioning, formatting, system setup, package installation, and bootloader configuration**.

---

## 📥 Download & Run the Script (Ubuntu Live Environment)

You can install **Arch Linux ARM** without using a browser. Just run:

```bash
sudo apt update && sudo apt install -y git
git clone https://github.com/rootshinerobin/arch-arm-installer.git
cd arch-arm-installer
chmod +x arch-arm-installer.sh
sudo ./arch-arm-installer.sh
```
🛠️ Features

    ✅ Automated Partitioning (GPT, EFI, Root)
    ✅ Downloads & Extracts Arch Linux ARM
    ✅ Configures Chroot Environment
    ✅ Sets Up Bootloader (GRUB for AArch64)
    ✅ Auto-Resume (Script remembers the last successful step and continues from there)
    ✅ Yes/No Prompts (Control installation at every step)
    ✅ Network & Keyring Fixes
    ✅ Error Handling & Debugging Logs

📌 Installation Steps (Automatically Handled)

    Partitions the Disk (EFI + Root)
    Formats Partitions (FAT32 for EFI, EXT4 for root)
    Mounts the System
    Downloads & Extracts Arch Linux ARM
    Enters Chroot (arch-chroot)
    Configures Network & Keyring
    Installs Essential Packages (pacman Setup)
    Bootloader Installation (grub-install)
    Final Cleanup & Reboot

🛠️ Debugging Issues

If you face installation failures, you can resume by running:

```bash
cd arch-arm-installer
sudo ./arch-arm-installer.sh
```
The script will resume from the last successful step.

To manually check logs:

```bash
cat /mnt/install_progress.log
```
🚀 Contributing

Feel free to suggest improvements or report bugs by opening an Issue or a Pull Request.

🛑 Disclaimer

This script is intended for advanced users who understand Linux installation.
Use at your own risk! ⚠️




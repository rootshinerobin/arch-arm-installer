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

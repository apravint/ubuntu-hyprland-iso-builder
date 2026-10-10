# 💿 Ubuntu Hyprland ISO Builder

> **Automated toolchain & GitHub Actions CI to build custom, bootable Ubuntu 26.04 LTS Live ISO images preloaded with Hyprland and Waybar.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Base: Ubuntu 26.04 LTS](https://img.shields.io/badge/Ubuntu-26.04%20LTS-orange.svg)]()
[![Compositor: Hyprland](https://img.shields.io/badge/Compositor-Hyprland%20Wayland-teal.svg)]()
[![Automated CI](https://img.shields.io/badge/CI-GitHub%20Actions-2088FF.svg)]()

Because Ubuntu does not officially ship a modern tiling Wayland flavor, building a stable, bootable Ubuntu + Hyprland live image has historically been challenging.

This repository provides a **fully automated, reproducible build pipeline**:
- Boots straight into a pristine, hardware-accelerated **Hyprland** session.
- Dual-mode UEFI & legacy BIOS booting via GRUB.
- Automated GitHub Actions workflow with cloud caching and automated GitHub Releases.
- Preconfigured audio (`PipeWire`), networking (`NetworkManager`), and Waybar.

---

## 🛠️ Build Pipeline Architecture

```
┌─────────────────────────┐
│ Ubuntu Noble/Resolute   │
│ Minimal Debootstrap     │
└───────────┬─────────────┘
            ▼
┌─────────────────────────┐
│ Linux Kernel & Drivers  │ (OEM/Generic kernel, linux-firmware, mesa)
└───────────┬─────────────┘
            ▼
┌─────────────────────────┐
│ Hyprland & Wayland Core │ (Hyprland, Waybar, Wofi, Foot, PipeWire)
└───────────┬─────────────┘
            ▼
┌─────────────────────────┐
│ Live Boot Engine        │ (Casper live system, skeleton configs)
└───────────┬─────────────┘
            ▼
┌─────────────────────────┐
│ Mksquashfs & Xorriso    │ (Hybrid ISO, UEFI ESP image, GRUB El-Torito)
└───────────┬─────────────┘
            ▼
      💿 Bootable ISO
```

---

## 🚀 Building Locally

### Prerequisites
Install the required ISO generation dependencies on Ubuntu/Debian:
```bash
sudo apt update && sudo apt install -y \
  debootstrap squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin mtools dosfstools
```

### Run the Build
```bash
git clone https://github.com/apravint/ubuntu-hyprland-iso-builder.git
cd ubuntu-hyprland-iso-builder
sudo ./build/build-iso.sh
```

The completed image will be generated in `./output/ubuntu-hyprland-live.iso`.

---

## 🧪 Testing with QEMU / KVM

You can test-boot the compiled ISO instantly in a virtual machine:
```bash
qemu-system-x86_64 \
  -enable-kvm \
  -m 4G \
  -smp 4 \
  -vga virtio \
  -cdrom output/ubuntu-hyprland-live.iso \
  -boot d
```

---

## ☁️ Automated GitHub Actions Cloud Builds

This repository includes [`.github/workflows/build-iso.yml`](.github/workflows/build-iso.yml).  
Whenever you push a tag or trigger the workflow manually in the GitHub Actions tab, it:
1. Spawns an Ubuntu cloud runner with virtualization flags.
2. Compiles the complete live image.
3. Automatically publishes the generated `.iso` and `SHA256SUMS.txt` to GitHub Releases.

---

## 📄 License

Released under the [MIT License](LICENSE).

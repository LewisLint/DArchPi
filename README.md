# DArchPi

## Menu dispatcher

Run the menu with:

```bash
./darchpi-menu.sh
```

The dispatcher presents the two supported Raspberry Pi options, then asks separately whether to install Nipe, WARP, Tor, and the BlackArch repositories:

```text
scripts/option-13.sh  # Raspberry Pi ARMv7
scripts/option-18.sh  # Raspberry Pi 3/4 AArch64
```

Each target script should be executable:

```bash
chmod +x scripts/option-13.sh scripts/option-18.sh
```

## Arch Linux Codespace

This repository includes an Arch Linux devcontainer. Rebuild the Codespace container after pulling the repository configuration to use it. The container includes the image-building tools and a passwordless `vscode` sudo user.

## Raspberry Pi AArch64 image

The menu builds either `ArchLinuxARM-rpi-armv7.img.xz` or `ArchLinuxARM-rpi-aarch64.img.xz`. The builder requires root privileges and host tools including `dosfstools`, `util-linux`, and `xz`:

```bash
sudo ./darchpi-menu.sh
```

The image uses a Raspberry Pi-compatible FAT `/boot` partition and ext4 root partition. On first boot it updates `pacman`, installs IWD, and installs Nipe from its upstream repository.

It also installs ARM-compatible WireGuard WARP tooling. To create and enable a WARP profile on the Pi, run:

```bash
sudo darchpi-enable-warp
sudo systemctl start wg-quick@wgcf-profile
```

WARP registration is intentionally performed on the device so credentials are not embedded in the image. Selecting WARP creates the `darchpi-enable-warp` helper. Selecting BlackArch downloads and runs its `strap.sh` setup script; selecting Tor installs it from the Arch repositories.

BlackArch support is added but still in testing. Its official repository may not provide packages for Arch Linux ARM architectures, so image provisioning or later `pacman` operations may fail. The other 21 boards need their own boot partition and bootloader layouts before they can safely be built as bootable images.
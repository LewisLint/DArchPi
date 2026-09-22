# DArchPi

## Menu dispatcher

Run the menu with:

```bash
./darchpi-menu.sh
```

The dispatcher presents the two supported Raspberry Pi options, then asks separately whether to install Nipe, WARP, Tor, and the BlackArch repositories. Nipe requires Tor, so selecting Nipe automatically selects and installs Tor without asking the Tor question separately. All download and provisioning logic is contained in the executable files at the repository root; no `scripts/` directory is required.

## Raspberry Pi AArch64 image

The menu builds either `ArchLinuxARM-rpi-armv7.img.xz` or `ArchLinuxARM-rpi-aarch64.img.xz`. The builder requires root privileges and host tools including `dosfstools`, `util-linux`, and `xz`:

```bash
sudo ./darchpi-menu.sh
```

On first boot, the image prompts on the Pi console for a Wi-Fi SSID and password before running `pacman`. It writes an iwd connection profile, connects to the network, and waits for internet access. Press Enter at the SSID prompt to use Ethernet instead. The Wi-Fi password is written to the live system, so only use it with an image you trust.

It also installs ARM-compatible WireGuard WARP tooling. To create and enable a WARP profile on the Pi, run:

```bash
sudo darchpi-enable-warp
sudo systemctl start wg-quick@wgcf-profile
```

WARP registration is intentionally performed on the device so credentials are not embedded in the image. Selecting WARP creates the `darchpi-enable-warp` helper. Selecting Tor installs it from the Arch repositories; selecting Nipe also installs Tor because it is a Nipe dependency. Selecting BlackArch downloads and runs its `strap.sh` setup script.

## Warnings

BlackArch will be installed only when selected. Keep in mind that this is still in testing, so you may come across unprecedented issues. Just a friendly warning!

BlackArch supports Arch Linux ARM and AArch64, but this DArchPi integration has not been tested yet. Image provisioning or later `pacman` operations may still fail unexpectedly. The other 21 boards need their own boot partition and bootloader layouts before they can safely be built as bootable images; in the future when I have more time, I may add these, but they are very low priority in my personal opinion.

## Future Aims 
***(Top Priorities First)***
1.  Add support for running this script on Arch Linux PCs
2.  Add support for running this script on a Raspberry Pi itself
3.  Add a custom `.zshrc` (which can be found at `https://github.com/lewislint/.dots`)
4.  Add a custom `.vimrc`
5.  Add an optional WM or DE choice to automatically install one of your choice
6.  Add support for the 21 other boards supporte by Arch Linux ARM

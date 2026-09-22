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
**Project Phase: Alpha / Untested**

This project has been sitting unmaintained and untested for about a month. It is maintained by a **solo developer** who works on this in their free time, so updates and bug fixes may be slow. 

BlackArch will be installed only when selected. Keep in mind that this is still in testing, so you may come across unprecedented issues. Just a friendly warning!

Please keep in mind:
* **Use at your own risk:** This project is not yet in active testing and features may fail completely.
* **BlackArch integration** is entirely untested on ARM architectures and may break `pacman` or image provisioning.
* **Limited board support:** Presently, *only two* Raspberry Pi boards, *ARMv7l* and *ARMv8*, are supported. The *other 21 Arch Linux ARM-supported boards require unique bootloader configurations* and are **not** currently a priority.

## Future Aims and Plans
***(Top Priorities First)***

Since this is a solo project, features will be added as time permits. Priorities are ordered from highest to lowest:

1. **Host Compatibility:** Add package manager checks for *Arch Linux (Pacman)* and *Fedora (DNF)* so MicroSD cards can be formatted from more host operating systems.
2. **Native Execution:** Add support for running the build script *directly* on a Raspberry Pi board.
3. **Environment Customization:** Build in optional steps to impliment custom configuration files *(like my `.zshrc` and `.vimrc` dotfiles).*
4. **Desktop Environments:** Add options to automatically install a *WM* or *DE* during the image creation process.
5. **Board Expansion:** *Gradually* introduce compatability for the *other 21 boards* supported by Arch Linux ARM (ALARM).

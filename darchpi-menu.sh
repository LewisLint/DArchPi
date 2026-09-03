#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
echo "What system are you installing Arch Linux ARM on?"
echo "Below is a list of supported systems. If your system is not listed, please check the Arch Linux ARM website for more information."
options=(
    "ARMv7 Raspberry Pi"
    "ARMv8 AArch64 Raspberry Pi 3/4"
)

image_names=(
    "ArchLinuxARM-rpi-armv7.img"
    "ArchLinuxARM-rpi-aarch64.img"
)

download_urls=(
    "http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-armv7-latest.tar.gz"
    "http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-aarch64-latest.tar.gz"
)

printf 'Choose an option:\n\n'
for index in "${!options[@]}"; do
    printf '%2d) %s\n' "$((index + 1))" "${options[index]}"
done

printf '\nEnter a number (1-2): '
read -r selection

if [[ ! "$selection" =~ ^[12]$ ]]; then
    printf 'Invalid selection: %s. Please choose a number from 1 to 2.\n' "$selection" >&2
    exit 1
fi

index=$((selection - 1))

features=()
for feature in Nipe WARP Tor BlackArch; do
    printf '\nInstall %s? (y/N): ' "$feature"
    read -r feature_selection
    if [[ "$feature_selection" =~ ^[Yy]$ ]]; then
        features+=("${feature,,}")
    fi
done

if [[ "${#features[@]}" -eq 0 ]]; then
    printf 'Select at least one feature.\n' >&2
    exit 1
fi

feature_list=$(IFS=,; printf '%s' "${features[*]}")

if ! command -v curl >/dev/null; then
    printf 'curl is required. Install it with: sudo pacman -S curl\n' >&2
    exit 1
fi

archive="ArchLinuxARM-.tar.gz"
printf 'Downloading %s...\n' "${download_urls[index]}"
if ! curl -L --fail --retry 3 --output "$archive" "${download_urls[index]}"; then
    printf 'Root filesystem download failed.\n' >&2
    rm -f "$archive"
    exit 1
fi

"$SCRIPT_DIR/build-rpi-image.sh" ArchLinuxARM-.tar.gz "${image_names[index]}" "$feature_list"

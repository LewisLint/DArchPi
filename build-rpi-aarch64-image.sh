#!/usr/bin/env bash

set -Eeuo pipefail

if [[ $# -ne 2 ]]; then
    printf 'Usage: %s ROOTFS_ARCHIVE IMAGE_NAME\n' "$0" >&2
    exit 2
fi

archive=$1
image=$2
compressed_image="$image.xz"
work_dir=$(mktemp -d)
mount_dir="$work_dir/root"
loop_device=''

cleanup() {
    set +e
    sync
    mountpoint -q "$mount_dir/boot" && umount "$mount_dir/boot"
    mountpoint -q "$mount_dir" && umount "$mount_dir"
    [[ -n "$loop_device" ]] && losetup -d "$loop_device"
    rm -rf "$work_dir"
}
trap cleanup EXIT

[[ $EUID -eq 0 ]] || { printf 'Run this builder with sudo.\n' >&2; exit 1; }
[[ -f "$archive" ]] || { printf 'Archive not found: %s\n' "$archive" >&2; exit 1; }

for command in dd losetup mkfs.vfat mkfs.ext4 mount mountpoint sfdisk tar udevadm xz; do
    if ! command -v "$command" >/dev/null; then
        case "$command" in
            mkfs.vfat) package=dosfstools ;;
            sfdisk) package=util-linux-extra ;;
            xz) package=xz-utils ;;
            udevadm) package=udev ;;
            *) package=util-linux ;;
        esac
        printf 'Missing required command: %s\n' "$command" >&2
        printf 'Install it on Ubuntu/Debian with: sudo apt install %s\n' "$package" >&2
        exit 1
    fi
done

rm -f "$image" "$compressed_image"
printf 'Creating %s...\n' "$image"
dd if=/dev/zero of="$image" bs=1M count=4096 status=progress
sfdisk "$image" <<'PARTITIONS'
label: dos

start=8192, size=524288, type=c, bootable
start=532480, type=83
PARTITIONS

loop_device=$(losetup --find --show --partscan "$image")
udevadm settle
mkfs.vfat -F 32 -n BOOT "${loop_device}p1"
mkfs.ext4 -L ROOT "${loop_device}p2"

mkdir -p "$mount_dir"
mount "${loop_device}p2" "$mount_dir"
mkdir -p "$mount_dir/boot"
mount "${loop_device}p1" "$mount_dir/boot"
tar --numeric-owner -xzf "$archive" -C "$mount_dir"

cat > "$mount_dir/etc/fstab" <<'FSTAB'
LABEL=ROOT  /      ext4  defaults,noatime  0 1
LABEL=BOOT  /boot  vfat  defaults           0 2
FSTAB

mkdir -p "$mount_dir/root"
cat > "$mount_dir/root/darchpi-first-boot.sh" <<'FIRSTBOOT'
#!/usr/bin/env bash
set -Eeuo pipefail

pacman -Syu --noconfirm iwd git perl cpanminus curl
systemctl enable iwd.service

cd /root
curl -O https://blackarch.org/strap.sh

if [[ ! -d /opt/nipe ]]; then
    git clone https://github.com/htrgouvea/nipe.git /opt/nipe
    cd /opt/nipe
    cpanm --installdeps .
    perl nipe.pl install
fi

rm -f /etc/systemd/system/darchpi-first-boot.service /root/darchpi-first-boot.sh
systemctl daemon-reload
FIRSTBOOT
chmod 700 "$mount_dir/root/darchpi-first-boot.sh"

cat > "$mount_dir/etc/systemd/system/darchpi-first-boot.service" <<'SERVICE'
[Unit]
Description=Install DArchPi networking and Nipe packages
After=network-online.target
Wants=network-online.target
ConditionPathExists=/root/darchpi-first-boot.sh

[Service]
Type=oneshot
ExecStart=/root/darchpi-first-boot.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
SERVICE

mkdir -p "$mount_dir/etc/systemd/system/multi-user.target.wants"
ln -s ../darchpi-first-boot.service \
    "$mount_dir/etc/systemd/system/multi-user.target.wants/darchpi-first-boot.service"

sync
umount "$mount_dir/boot"
umount "$mount_dir"
losetup -d "$loop_device"
loop_device=''
xz -T0 -z "$image"
printf 'Created %s\n' "$compressed_image"
#!/usr/bin/env bash

set -Eeuo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
    printf 'Usage: %s ROOTFS_ARCHIVE IMAGE_NAME [FEATURES]\n' "$0" >&2
    exit 2
fi

archive=$1
image=$2
features=${3:-all}
if [[ "$features" == all ]]; then
    features=nipe,warp,tor,blackarch
fi
[[ "$features" =~ ^(nipe|warp|tor|blackarch)(,(nipe|warp|tor|blackarch))*$ ]] || {
    printf 'Unsupported feature set: %s\n' "$features" >&2
    exit 1
}
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
printf '%s\n' "$features" > "$mount_dir/etc/darchpi-features"
cat > "$mount_dir/root/darchpi-first-boot.sh" <<'FIRSTBOOT'
#!/usr/bin/env bash
set -Eeuo pipefail

IFS=, read -r -a selected_features < /etc/darchpi-features
has_feature() {
    local feature=$1
    for selected_feature in "${selected_features[@]}"; do
        [[ "$selected_feature" == "$feature" ]] && return 0
    done
    return 1
}

packages=(iwd)
if has_feature nipe; then
    packages+=(git perl cpanminus)
fi
if has_feature warp; then
    packages+=(git go wireguard-tools)
fi
if has_feature tor; then
    packages+=(tor)
fi
if has_feature blackarch; then
    packages+=(curl)
fi
pacman -Syu --noconfirm "${packages[@]}"
systemctl enable iwd.service

if has_feature warp; then
    GOBIN=/usr/local/bin go install github.com/ViRb3/wgcf/cmd/wgcf@latest
    install -d -m 700 /etc/wireguard
    cat > /usr/local/sbin/darchpi-enable-warp <<'WARP'
#!/usr/bin/env bash
set -Eeuo pipefail

cd /etc/wireguard
wgcf register
wgcf generate
install -m 600 wgcf-profile.conf /etc/wireguard/wgcf-profile.conf
systemctl enable wg-quick@wgcf-profile.service
printf 'WARP configuration created. Start it with: systemctl start wg-quick@wgcf-profile\n'
WARP
    chmod 700 /usr/local/sbin/darchpi-enable-warp
fi

if has_feature blackarch; then
    cd /root
    curl --fail --location --output strap.sh https://blackarch.org/strap.sh
    chmod 700 strap.sh
    ./strap.sh
fi

if has_feature nipe && [[ ! -d /opt/nipe ]]; then
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
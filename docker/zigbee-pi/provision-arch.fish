#!/usr/bin/env fish
#
# provision-arch.fish -- flash a microSD card with a bootable ArchLinuxARM
# (AArch64) system for the Raspberry Pi 4B, i.e. this repo's zigbee-pi doco-cd host.
#
# Follows the official AArch64 installation instructions for the Pi 4
# (https://archlinuxarm.org/platforms/armv8/broadcom/raspberry-pi-4):
#   - MBR: 1G FAT32 boot partition + ext4 root (mainline kernel / U-Boot image)
#   - extract ArchLinuxARM-rpi-aarch64-latest.tar.gz, move boot files to FAT32
#   - /etc/fstab: s/mmcblk0/mmcblk1/  (Pi 4-specific: the SD card is mmcblk1)
# and adds a one-shot first-boot service that initializes the pacman keyring
# (official step 10), updates the system (recommended on first boot for the
# Pi 4, to pick up current U-Boot/kernel), and installs Docker + the compose
# plugin (needed by doco-cd) via pacman or the official static binaries.
#
# Run on an Arch-based Linux host, as root:
#   ./provision-arch.fish /dev/sdX
#
# Optional environment:
#   HOSTNAME   hostname to give the Pi        (default: zigbee-pi.ctec.internal)
#   TZ         IANA time zone                 (default: America/New_York)
#
# After first boot (see the summary this script prints) change the default
# alarm/alarm and root/root credentials, then bring up doco-cd:
#   git clone <this repo> && docker compose -f docker/zigbee-pi/.doco-cd/docker-compose.app.yaml up -d

if test (count $argv) -lt 1
    echo "usage: $0 /dev/sdX" >&stderr
    exit 1
end

set -l device $argv[1]
if not string match -q "/dev/*" -- $device
    set device "/dev$device"
end

if test $EUID -ne 0
    echo "this script must run as root (it wipes a block device)" >&stderr
    exit 1
end

if not test -b $device
    echo "$device is not a block device" >&stderr
    exit 1
end

for tool in lsblk sfdisk partprobe mkfs.vfat mkfs.ext4 bsdtar wget
    if not command -q $tool
        echo "missing required tool: $tool" >&stderr
        exit 1
    end
end

set -l pi_hostname $HOSTNAME
if test -z $pi_hostname
    set pi_hostname zigbee-pi.ctec.internal
end
set -l pi_tz $TZ
if test -z $pi_tz
    set pi_tz America/New_York
end

# Refuse to continue if anything is mounted on the device or its partitions.
set -l mounted (lsblk -no MOUNTPOINT $device | string trim | string match -a -- .)
if test (count $mounted) -gt 0
    echo "$device is mounted: $mounted - unmount it first" >&stderr
    exit 1
end

echo
lsblk -o NAME,SIZE,TYPE,MODEL,STATE $device
printf "\nThis will ERASE all data on %s. Type the full device path to confirm: " $device
set -l confirm
read --local confirm
if not test $confirm = $device
    echo "aborted." >&stderr
    exit 1
end

set -g tmp
function __cleanup
    if test -n $tmp
        umount $tmp/boot $tmp/root 2>/dev/null
        rm -rf $tmp
    end
end
# fish 4 dropped the "on signal" block form; --on-signal functions work in 3 and 4.
function --on-signal INT __on_sigint
    __cleanup
    exit 130
end
function --on-signal TERM __on_sigterm
    __cleanup
    exit 143
end
function --on-signal HUP __on_sighup
    __cleanup
    exit 129
end

set tmp (mktemp -d)
mkdir -p $tmp/boot $tmp/root

echo "Partitioning (MBR: 1G FAT32 boot + ext4 root)..."
printf "unit: MiB\nlabel: dos\np1: start=1, size=1024, type=0c\np2: type=83\n" | sfdisk --force $device
partprobe $device
sleep 1

echo "Formatting and mounting..."
mkfs.vfat {$device}1
mkfs.ext4 {$device}2
mount {$device}1 $tmp/boot
mount {$device}2 $tmp/root

set -l tarball "$tmp/ArchLinuxARM-rpi-aarch64-latest.tar.gz"
echo "Downloading the aarch64 rootfs (a few hundred MB, give it a few minutes)..."
wget -O $tarball "http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-aarch64-latest.tar.gz"
bsdtar -xpf $tarball -C $tmp/root
rm -f $tarball

if not test -d $tmp/root/boot
    echo "sanity check failed: extracted image has no boot/ directory, aborting" >&stderr
    exit 1
end
mv $tmp/root/boot/* $tmp/boot
# Pi 4 specific: the SD card shows up as /dev/mmcblk1, not mmcblk0.
sed -i 's/mmcblk0/mmcblk1/g' $tmp/root/etc/fstab

echo "Configuring hostname ($pi_hostname) and timezone ($pi_tz)..."
printf "%s\n" $pi_hostname > $tmp/root/etc/hostname
if test -f $tmp/root/usr/share/zoneinfo/$pi_tz
    ln -sf /usr/share/zoneinfo/$pi_tz $tmp/root/etc/localtime
else
    echo "warning: $pi_tz not present in the image, timezone left as-is" >&stderr
end

# One-shot first-boot service: keyring init + full update (per the official
# docs / known Pi 4 AArch64 first-boot steps) + Docker for doco-cd.
mkdir -p $tmp/root/usr/local/bin $tmp/root/etc/systemd/system/multi-user.target.wants

set -l unit
set unit '[Unit]'
set unit $unit 'Description=zigbee-pi first boot setup'
set unit $unit 'After=network-online.target'
set unit $unit 'Wants=network-online.target'
set unit $unit ''
set unit $unit '[Service]'
set unit $unit 'Type=oneshot'
set unit $unit 'TimeoutStartSec=30min'
set unit $unit 'ExecStart=/usr/local/bin/firstboot.sh'
set unit $unit ''
set unit $unit '[Install]'
set unit $unit 'WantedBy=multi-user.target'
printf '%s\n' $unit > $tmp/root/etc/systemd/system/firstboot.service
chmod 0644 $tmp/root/etc/systemd/system/firstboot.service
ln -s /etc/systemd/system/firstboot.service $tmp/root/etc/systemd/system/multi-user.target.wants/firstboot.service

set -l firstboot
set firstboot '#!/bin/sh'
set firstboot $firstboot '# One-shot first boot setup for zigbee-pi: pacman keyring, system'
set firstboot $firstboot '# update, Docker (for doco-cd). Disables itself on success.'
set firstboot $firstboot 'set -e'
set firstboot $firstboot ''
set firstboot $firstboot 'pacman-key --init'
set firstboot $firstboot 'pacman-key --populate archlinuxarm'
set firstboot $firstboot 'pacman -Syu --noconfirm'
set firstboot $firstboot ''
set firstboot $firstboot 'if command -v wget >/dev/null 2>&1; then'
set firstboot $firstboot '    http_get() { wget -qO- "$1"; }'
set firstboot $firstboot '    http_save() { wget -O "$2" "$1"; }'
set firstboot $firstboot 'elif command -v curl >/dev/null 2>&1; then'
set firstboot $firstboot '    http_get() { curl -fsSL "$1"; }'
set firstboot $firstboot '    http_save() { curl -fsSL -o "$2" "$1"; }'
set firstboot $firstboot 'else'
set firstboot $firstboot '    echo "no wget or curl available, cannot fetch Docker"; exit 1'
set firstboot $firstboot 'fi'
set firstboot $firstboot ''
set firstboot $firstboot 'if pacman -S --noconfirm docker >/dev/null 2>&1; then'
set firstboot $firstboot '    systemctl enable --now docker'
set firstboot $firstboot 'else'
set firstboot $firstboot '    echo "pacman: no docker package available, using official static binaries"'
set firstboot $firstboot '    dver=$(http_get https://download.docker.com/linux/static/stable/aarch64/ | grep -oE "docker-[0-9]+[.][0-9]+[.][0-9]+[.]tgz" | sort -Vu | tail -1)'
set firstboot $firstboot '    if [ -z "$dver" ]; then echo "could not resolve a docker version, check the network"; exit 1; fi'
set firstboot $firstboot '    http_save "https://download.docker.com/linux/static/stable/aarch64/$dver" "/tmp/$dver"'
set firstboot $firstboot '    tar -xzf "/tmp/$dver" -C /usr/local/bin'
set firstboot $firstboot '    mv /usr/local/bin/docker/* /usr/local/bin/'
set firstboot $firstboot '    rm -rf "/tmp/$dver" /usr/local/bin/docker'
set firstboot $firstboot '    if [ ! -e /etc/systemd/system/docker.service ]; then'
set firstboot $firstboot '        printf "%s\n" "" "[Unit]" "Description=Docker Application Container Engine" "After=network-online.target" "Wants=network-online.target" "" "[Service]" "ExecStart=/usr/local/bin/dockerd" "Restart=on-failure" "" "[Install]" "WantedBy=multi-user.target" > /etc/systemd/system/docker.service'
set firstboot $firstboot '        systemctl daemon-reload'
set firstboot $firstboot '    fi'
set firstboot $firstboot '    systemctl enable --now docker'
set firstboot $firstboot 'fi'
set firstboot $firstboot ''
set firstboot $firstboot 'systemctl disable --now firstboot.service'
printf '%s\n' $firstboot > $tmp/root/usr/local/bin/firstboot.sh
chmod 0755 $tmp/root/usr/local/bin/firstboot.sh

echo "Finalizing (sync + unmount)..."
sync
umount $tmp/root $tmp/boot
umount $tmp/boot 2>/dev/null
rm -rf $tmp
set tmp ""
sync

echo
echo "Done. The card is ready for the Raspberry Pi 4B."
echo
echo "  Power      5V / 3A or better (official recommendation - underpowering corrupts the card)"
echo "  First boot a one-shot service (firstboot.service) runs: pacman keyring init,"
echo "               system update, Docker install. It disables itself when done."
echo "  Login      alarm/alarm or root/root - change both immediately"
echo "  Hostname   $pi_hostname   (timezone $pi_tz)"
echo
echo "  Once Docker is up:"
echo "    git clone <this repo>  (e.g. /home/\$USER/k8s-home-ops)"
echo "    docker compose -f docker/zigbee-pi/.doco-cd/docker-compose.app.yaml up -d"
echo "  Then plug in the USB controllers and fill in the TODO by-id serial paths"
echo "  in docker/zigbee-pi/01-zigbee2mqtt and 02-zwave2mqtt (see docker/AGENTS.md)."

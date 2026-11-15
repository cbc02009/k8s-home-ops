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
# (official step 10) and updates the system (recommended on first boot for
# the Pi 4, to pick up current U-Boot/kernel).
#
# It does NOT set up Docker or doco-cd - do that afterwards with the
# companion setup-doco-cd.sh, run on the Pi itself.
#
# Run on an Arch-based Linux host, as root:
#   ./provision-arch.fish /dev/sdX
#
# Optional environment:
#   PI_HOSTNAME  hostname to give the Pi        (default: zigbee-pi.ctec.internal)
#   TZ           IANA time zone                 (default: America/New_York)

if test (count $argv) -lt 1
    echo "usage: "(status filename)" /dev/sdX" >&2
    exit 1
end

set -l device $argv[1]
if not string match -q "/dev/*" -- $device
    set device "/dev$device"
end

if test $EUID -ne 0
    echo "this script must run as root (it wipes a block device)" >&2
    exit 1
end

if not test -b $device
    echo "$device is not a block device" >&2
    exit 1
end

for tool in lsblk sfdisk partprobe mkfs.vfat mkfs.ext4 mountpoint bsdtar wget
    if not command -q $tool
        echo "missing required tool: $tool" >&2
        exit 1
    end
end

set -l pi_hostname zigbee-pi.ctec.internal
if set -q PI_HOSTNAME
    set pi_hostname $PI_HOSTNAME
end
set -l pi_tz America/New_York
if set -q TZ
    set pi_tz $TZ
end

# Refuse to continue if anything is mounted on the device or its partitions.
set -l mounted (lsblk -no MOUNTPOINT $device | string trim | string match -a -- .)
if test (count $mounted) -gt 0
    echo "$device is mounted: $mounted - unmount it first" >&2
    exit 1
end

echo
lsblk -o NAME,SIZE,TYPE,MODEL,STATE $device
printf "\nThis will ERASE all data on %s. Type the full device path to confirm: " $device
set -l confirm
read --local confirm
if not test $confirm = $device
    echo "aborted." >&2
    exit 1
end

set -g tmp
function __cleanup
    if test -n "$tmp"
        umount $tmp/boot 2>/dev/null
        umount $tmp/root 2>/dev/null
        # remove the temp dir only if nothing is still mounted under it, so a
        # failed unmount can never rm -rf into a live filesystem
        if not mountpoint -q $tmp/boot; and not mountpoint -q $tmp/root
            rm -rf $tmp
            set tmp ""
        end
    end
end
function fail
    echo "error: $argv" >&2
    __cleanup
    exit 1
end
# fish 4 dropped the "on signal" block form; --on-signal functions work in 3 and 4
# (the function name must come first, then the --on-signal option).
function __on_sigint --on-signal INT
    __cleanup
    exit 130
end
function __on_sigterm --on-signal TERM
    __cleanup
    exit 143
end
function __on_sighup --on-signal HUP
    __cleanup
    exit 129
end

set tmp (mktemp -d)
mkdir -p $tmp/boot $tmp/root

echo "Partitioning (MBR: 1G FAT32 boot + ext4 root)..."
# sfdisk only accepts "unit: sectors" (anything else is an unsupported command,
# which aborts the whole table), so stay in the default and suffix values with MiB.
printf "label: dos\np1 : start=1MiB, size=1024MiB, type=c\np2 : type=83\n" | sfdisk --force $device
or fail "sfdisk failed to write the partition table"
partprobe $device 2>/dev/null

set -l bootpart "$device"1
set -l rootpart "$device"2
# USB card readers can take a moment to expose the new partition nodes
# (loop variable: _ is a read-only fish special, not assignable)
for i in (seq 1 10)
    if test -b $bootpart; and test -b $rootpart
        break
    end
    sleep 1
end
test -b $bootpart; and test -b $rootpart
or fail "partition devices did not appear ($bootpart / $rootpart)"

echo "Formatting and mounting..."
mkfs.vfat $bootpart
or fail "mkfs.vfat $bootpart failed"
mkfs.ext4 -F $rootpart
or fail "mkfs.ext4 $rootpart failed"
mount $bootpart $tmp/boot
or fail "mount $bootpart failed"
mount $rootpart $tmp/root
or fail "mount $rootpart failed"

echo "Downloading and extracting the aarch64 rootfs (a few hundred MB, give it a few minutes)..."
wget -q --show-progress -O - "http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-aarch64-latest.tar.gz" | bsdtar -xpf - -C $tmp/root
set -l pipe_st $pipestatus
test $pipe_st[1] -eq 0; and test $pipe_st[2] -eq 0
or fail "download/extract of the rootfs failed (wget=$pipe_st[1], bsdtar=$pipe_st[2])"

if not test -d $tmp/root/boot
    fail "extracted image has no boot/ directory - unexpected rootfs layout"
end
mv $tmp/root/boot/* $tmp/boot
or fail "moving boot files to the FAT32 partition failed"
# Pi 4 specific: the SD card shows up as /dev/mmcblk1, not mmcblk0.
sed -i 's/mmcblk0/mmcblk1/g' $tmp/root/etc/fstab

echo "Configuring hostname ($pi_hostname) and timezone ($pi_tz)..."
printf "%s\n" $pi_hostname > $tmp/root/etc/hostname
if test -f $tmp/root/usr/share/zoneinfo/$pi_tz
    ln -sf /usr/share/zoneinfo/$pi_tz $tmp/root/etc/localtime
else
    echo "warning: $pi_tz not present in the image, timezone left as-is" >&2
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
set firstboot $firstboot '# One-shot first boot setup for zigbee-pi: pacman keyring and'
set firstboot $firstboot '# system update. Disables itself on success.'
set firstboot $firstboot 'set -e'
set firstboot $firstboot ''
set firstboot $firstboot 'pacman-key --init'
set firstboot $firstboot 'pacman-key --populate archlinuxarm'
set firstboot $firstboot 'pacman -Syu --noconfirm'
set firstboot $firstboot ''
# no --now: stopping the unit from inside itself would kill this script mid-run
set firstboot $firstboot 'systemctl disable firstboot.service'
printf '%s\n' $firstboot > $tmp/root/usr/local/bin/firstboot.sh
chmod 0755 $tmp/root/usr/local/bin/firstboot.sh

echo "Finalizing (sync + unmount)..."
sync
umount $tmp/boot $tmp/root
or begin
    echo "error: could not unmount cleanly - leaving $tmp in place, inspect it manually" >&2
    exit 1
end
rm -rf $tmp
set tmp ""
sync

echo
echo "Done. The card is ready for the Raspberry Pi 4B."
echo
echo "  Power      5V / 3A or better (official recommendation - underpowering corrupts the card)"
echo "  First boot a one-shot service (firstboot.service) runs the pacman keyring init"
echo "               and the system update, then disables itself."
echo "  Login      alarm/alarm or root/root - change both immediately"
echo "  Hostname   $pi_hostname   (timezone $pi_tz)"
echo
echo "  Then bring up Docker and doco-cd on the Pi with the companion script:"
echo "    scp docker/zigbee-pi/setup-doco-cd.sh \$pi_hostname:"
echo "    ssh \$pi_hostname sh setup-doco-cd.sh"
echo
echo "  doco-cd then polls this repo; plug in the USB controllers and fill in"
echo "  the TODO by-id serial paths in 01-zigbee2mqtt and 02-zwave2mqtt"
echo "  (see docker/AGENTS.md) and the stacks deploy on the next poll."

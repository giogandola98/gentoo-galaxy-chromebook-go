#!/bin/bash
# Install SASUKE Gentoo on the Chromebook's internal eMMC, from a live Linux USB.
# Run as root on the Chromebook (live session), from the root of this repository:
#
#   ./scripts/install.sh --disk /dev/mmcblk1 --binhost http://<builder>:8780 --user <name> [--hostname sasuke]
#
# Requirements: network, the builder (builder/) already populated (it serves packages + kernel).
# WARNING: wipes the whole --disk.
set -euo pipefail

DISK="" BINHOST="" USERNAME="" HOSTNAME=sasuke
while [[ $# -gt 0 ]]; do
  case "$1" in
    --disk) DISK=$2; shift 2 ;;
    --binhost) BINHOST=${2%/}; shift 2 ;;
    --user) USERNAME=$2; shift 2 ;;
    --hostname) HOSTNAME=$2; shift 2 ;;
    *) echo "unknown option $1"; exit 1 ;;
  esac
done
[[ -b $DISK && -n $BINHOST && -n $USERNAME ]] || { sed -n '2,9p' "$0"; exit 1; }
[[ $EUID -eq 0 ]] || { echo "run as root"; exit 1; }
REPO=$(cd "$(dirname "$0")/.." && pwd)
MNT=/mnt/gentoo
P() { [[ $DISK == *[0-9] ]] && echo "${DISK}p$1" || echo "${DISK}$1"; }
say() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }

curl -sfm 10 "$BINHOST/Packages" -o /dev/null || { echo "binhost $BINHOST unreachable"; exit 1; }
# builder signing key: trust on first use, confirmed by the user
curl -sf "$BINHOST/sasuke-signing.asc" -o /tmp/sasuke-signing.asc || { echo "no signing key on the binhost"; exit 1; }
FPR=$(gpg --batch --with-colons --import-options show-only --import /tmp/sasuke-signing.asc 2>/dev/null | awk -F: '/^fpr/ {print $10; exit}')
echo "Builder signing key: $FPR"
echo "(check on the build server: docker compose exec builder cat /usr/src/build/gnupg/fpr)"
read -rp "Does it match? Type YES: " ok
[[ $ok == YES ]] || exit 1
lsblk "$DISK"
read -rp "ALL DATA on $DISK will be erased. Type YES to continue: " ok
[[ $ok == YES ]] || exit 1

say "Partitioning $DISK (512M EFI + ext4)"
wipefs -af "$DISK"
sfdisk "$DISK" <<EOF
label: gpt
size=512MiB, type=uefi, name=EFI
type=linux, name=gentoo
EOF
udevadm settle
mkfs.vfat -F 32 -n EFI "$(P 1)"
mkfs.ext4 -F -L gentoo "$(P 2)"
mkdir -p $MNT && mount "$(P 2)" $MNT
mkdir -p $MNT/efi && mount "$(P 1)" $MNT/efi

say "Stage3 (amd64 desktop systemd)"
BASE=https://distfiles.gentoo.org/releases/amd64/autobuilds
STAGE=$(curl -sf $BASE/latest-stage3-amd64-desktop-systemd.txt | awk '/^[0-9].*\.tar\.xz/ {print $1; exit}')
curl -f -o $MNT/stage3.tar.xz "$BASE/$STAGE"
curl -sf "$BASE/$STAGE.sha256" | awk '{print $1"  '"$MNT"'/stage3.tar.xz"}' | grep -E '^[0-9a-f]{64} ' | sha256sum -c -
tar -C $MNT -xpf $MNT/stage3.tar.xz --xattrs-include='*.*' --numeric-owner && rm $MNT/stage3.tar.xz

say "Portage configuration + system overlay"
cp -a "$REPO"/gentoo/portage/{package.*,env} $MNT/etc/portage/
cp "$REPO"/gentoo/device/make.conf $MNT/etc/portage/make.conf
rm -rf $MNT/etc/portage/binrepos.conf && mkdir -p $MNT/etc/portage/binrepos.conf
sed "s|^sync-uri.*|sync-uri = $BINHOST|" "$REPO"/gentoo/device/binrepos.conf/sasuke.conf > $MNT/etc/portage/binrepos.conf/sasuke.conf
cp "$REPO"/gentoo/device/binrepos.conf/gentoo.conf $MNT/etc/portage/binrepos.conf/
cp "$REPO"/gentoo/world $MNT/root/world.txt
cp -a "$REPO"/builder/repos.conf $MNT/etc/portage/repos.conf/sasuke.conf 2>/dev/null || { mkdir -p $MNT/etc/portage/repos.conf; cp "$REPO"/builder/repos.conf $MNT/etc/portage/repos.conf/sasuke.conf; }
(cd "$REPO"/rootfs && tar --exclude='._*' -cf - .) | tar -C $MNT --no-same-owner -xf -
chmod 440 $MNT/etc/sudoers.d/* 2>/dev/null || true
cp "$REPO"/build/postinstall.sh $MNT/root/postinstall.sh
cp /tmp/sasuke-signing.asc $MNT/root/sasuke-signing.asc
cp -L /etc/resolv.conf $MNT/etc/resolv.conf

say "Chroot"
for d in proc sys dev run; do mount --rbind /$d $MNT/$d; mount --make-rslave $MNT/$d; done
cat > $MNT/root/inside.sh <<EOF
set -e
source /etc/profile
emerge-webrsync -q
eselect profile set default/linux/amd64/23.0/desktop/systemd
emaint sync -r guru || emerge -q --getbinpkgonly app-eselect/eselect-repository dev-vcs/git && emaint sync -r guru
echo "it_IT.UTF-8 UTF-8" >> /etc/locale.gen; echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen; locale-gen
printf 'LANG=it_IT.UTF-8\nLC_MESSAGES=it_IT.UTF-8\n' > /etc/locale.conf
echo KEYMAP=it > /etc/vconsole.conf
ln -sf ../usr/share/zoneinfo/Europe/Rome /etc/localtime
echo $HOSTNAME > /etc/hostname
getuto   # Gentoo keys + local trust key in /etc/portage/gnupg
gpg --homedir /etc/portage/gnupg --batch --import /root/sasuke-signing.asc
gpg --homedir /etc/portage/gnupg --batch --yes --pinentry-mode loopback --passphrase-file /etc/portage/gnupg/pass --quick-lsign-key $FPR
emerge -q --getbinpkgonly --noreplace \$(grep -v '^#' /root/world.txt)
# kernel built by the builder
KV=\$(curl -sf $BINHOST/sasuke-kernel/LATEST)
curl -sf $BINHOST/sasuke-kernel/kernel-\${KV}-sasuke.tar.zst | tar -C / --keep-directory-symlink --no-same-owner --zstd -xf - boot lib
mkdir -p /var/lib/sasuke; curl -sf $BINHOST/sasuke-kernel/kernel-\${KV}-sasuke.tar.zst.sha256 | awk '{print \$1}' > /var/lib/sasuke/kernel.sha256
depmod \${KV}-gentoo-sasuke
dracut -f --kver \${KV}-gentoo-sasuke /boot/initramfs-\${KV}-gentoo-sasuke.img
sed -i 's|^#\?GRUB_TIMEOUT=.*|GRUB_TIMEOUT=2|; s|^#\?GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT="quiet loglevel=3 mem_sleep_default=deep panic=10 i915.enable_guc=2 nowatchdog"|' /etc/default/grub
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=gentoo
grub-install --target=x86_64-efi --efi-directory=/efi --removable
grub-mkconfig -o /boot/grub/grub.cfg
# Chromebook audio (SOF da7219 + max98360a): ChromeOS UCM profiles
git clone --depth 1 https://github.com/WeirdTreeThing/alsa-ucm-conf-cros /usr/local/share/alsa-ucm-conf-cros
cp -r /usr/local/share/alsa-ucm-conf-cros/ucm2/* /usr/share/alsa/ucm2/
cp -r /usr/local/share/alsa-ucm-conf-cros/overrides/* /usr/share/alsa/ucm2/conf.d/
# user
useradd -m -G wheel,audio,video,input,usb,users -s /bin/bash $USERNAME
echo "Set the password for $USERNAME:"; passwd $USERNAME
passwd -l root
echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/wheel; chmod 440 /etc/sudoers.d/wheel
bash /root/postinstall.sh
systemctl enable sasuke-firewall sasuke-charge
EOF
chroot $MNT /bin/bash /root/inside.sh

say "Done. Remove the USB stick and reboot. First login: $USERNAME (password just set)."
echo "Then: open the Tailscale menu (TS in the bar) to log in, and connect Wi-Fi from the tray icon."

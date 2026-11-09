#!/bin/bash
# Run inside the Gentoo chroot (or on the booted system) after the desktop binpkgs are installed.
set -x
# NetworkManager owns Wi-Fi from now on (iwd only as its backend)
sed -i '/EnableNetworkConfiguration/d; /NameResolvingService/d' /etc/iwd/main.conf 2>/dev/null
systemctl disable iwd.service 2>/dev/null
systemctl enable NetworkManager.service bluetooth.service greetd.service tailscaled.service \
    systemd-resolved.service systemd-timesyncd.service sshd.service keyd.service thermald.service 2>&1
systemctl enable tlp.service 2>/dev/null
systemctl mask systemd-rfkill.service systemd-rfkill.socket 2>/dev/null
systemctl set-default graphical.target
# greetd user
getent passwd greeter >/dev/null || useradd -r -M -G video,input -s /bin/false greeter
# user groups for the desktop (first regular user)
U=$(getent passwd 1000 | cut -d: -f1)
for g in video audio input plugdev bluetooth; do getent group $g >/dev/null && gpasswd -a "$U" $g >/dev/null; done
# pipewire user units
systemctl --global enable pipewire.socket pipewire-pulse.socket wireplumber.service 2>&1
# Bluetooth on at boot
sed -i "s/^#\?AutoEnable=.*/AutoEnable=true/" /etc/bluetooth/main.conf
# Citrix telemetry off
/usr/local/sbin/citrix-notelemetry
systemctl enable tlp-pd.service rtkit-daemon.service upower.service 2>/dev/null
echo POSTINSTALL_DONE

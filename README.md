# Gentoo for the Samsung Galaxy Chromebook Go (SASUKE)

A small, fast, telemetry-free Gentoo desktop for the **Samsung Galaxy Chromebook Go**
(board `SASUKE`, Intel Celeron N4500 "Jasper Lake", 4 GB RAM, 64 GB eMMC), with every package
compiled for the Celeron by a Docker build server and installed as binary packages.

The user interface is in Italian (keyboard `it`, locale `it_IT`); commands and scripts are in English.

## What works

| Area | Status |
|---|---|
| Boot | MrChromebox UEFI → GRUB → custom 6.18 LTS kernel (`-march=tremont`, ~15 MB of modules), ~7 s to login |
| Wi-Fi | Intel AX201 (iwlwifi), NetworkManager with iwd backend, tray applet |
| Bluetooth | btusb + BlueZ + Blueman; on/off state is remembered |
| Audio | SOF `sof-da7219max98360a` (speakers, headset, internal mic) via ChromeOS UCM profiles |
| Webcam / mic | in Firefox (Teams, Webex), PipeWire |
| Sleep | S3 deep sleep on lid close, ~1 s resume, Wi-Fi reconnects |
| Keyboard | ChromeOS top row via keyd; hold **Search (○)** to show an on-screen F1–F12 overlay |
| Brightness / volume | top-row keys + on-screen indicator |
| Power | TLP profiles (⚡ performance / ⚖ balanced / 🍃 saver) switchable from the bar, 80 % charge limit |
| Remote work | Citrix Workspace (opens `.ica` from the browser), FreeRDP, TigerVNC, OpenSSH |
| Private network | Tailscale with a graphical menu in the bar (exit nodes, routes, devices) |
| Apps | Firefox ESR (telemetry removed by policy, uBlock Origin), VSCodium, Obsidian, OBS Studio, Thunar |
| Canon cameras | photo download (gphoto2/gvfs) and use as webcam (`canon-webcam`, v4l2loopback) |
| Security | nftables firewall: nothing inbound except via Tailscale; SSH keys only |

Desktop: **labwc** (floating windows, Openbox-like) + waybar (top) + fuzzel + mako + swaylock/swayidle,
greetd/tuigreet login, zram swap, MGLRU.

## Repository layout

```
builder/        Docker build server (image + compose): builds all packages and the kernel, serves them
gentoo/portage/ Portage configuration used by the builder (make.conf, USE flags, keywords, env)
gentoo/device/  make.conf, binrepos.conf and firmware trim for the Chromebook itself
gentoo/world    the package set
kernel/         kernel config (config-sasuke-*) and KERNEL_VERSION
rootfs/         files copied as-is onto the Chromebook (desktop, keys, power, firewall, scripts)
scripts/        install.sh (from a live USB)
build/          postinstall.sh (services, groups, tweaks)
```

## 1. Build server

Any x86-64 Linux machine with Docker. At start-up the builder checks which Tremont instructions the
host CPU supports and uses as many as possible (`builder cpu`), so binaries always run on the Celeron.

```sh
cd builder
cp env.example .env      # set DATA (data dir) and BIND (the host's Tailscale IP)
docker compose build
docker compose up -d
docker compose exec builder builder update     # first run: many hours (Firefox, LLVM, Rust…)
docker compose exec builder builder status
```

The `binhost` service (nginx) publishes the packages and the kernel on `BIND:8780`.
Bind it to the Tailscale IP so it is reachable only from your tailnet.

Every package is **GPG-signed** by the builder (`builder cpu` creates the key on first start; the
private key stays in `DATA/kernel/gnupg`, the public key is served as `sasuke-signing.asc`).
The Chromebook accepts only packages signed by this key or by Gentoo. Packages built before
signing was enabled can be signed with `builder sign`.

> After rebuilding the image, start services by name (`docker compose up -d builder binhost`)
> while an ULTRA build is running: a plain `docker compose up` restarts `builder-ultra` too.

### Start a build from the Chromebook

`sasuke-update --build` connects to the build server with a dedicated SSH key that can only start
`builder update` (or `check`). On the Chromebook (root):

```sh
ssh-keygen -t ed25519 -N "" -C sasuke-update -f /root/.ssh/sasuke-builder
echo BUILDER_USER=<user on the build server> > /etc/sasuke/update.conf
```

On the build server, add the public key to `~/.ssh/authorized_keys` with a forced command:

```
command="/path/to/builder/remote-build.sh",restrict ssh-ed25519 AAAA... sasuke-update
```

## 2. Install on the Chromebook

1. Flash the MrChromebox UEFI firmware (<https://mrchromebox.tech>).
2. Boot any live Linux from USB, connect to the network, become root.
3. Clone this repository and run:

```sh
./scripts/install.sh --disk /dev/mmcblk1 --binhost http://<builder>:8780 --user <name>
```

The script partitions the eMMC (512 MB EFI + ext4), unpacks a Gentoo stage3, copies the
configuration, installs every package and the kernel **as binaries from the builder**, sets up
GRUB, audio profiles, the user and all services. Reboot, log in, then log in to Tailscale from the
`TS` menu in the bar.

> The installation was first done by hand; `install.sh` reproduces those exact steps.

## 3. Updating

On the Chromebook:

```sh
sasuke-update            # install whatever the builder already built
sasuke-update --build    # ask the builder to sync + rebuild first (SSH key, restricted command)
```

Nothing is ever compiled on the Chromebook by accident: if the builder is unreachable the update stops.

### Ultra packages (LTO + PGO, clang full-LTO kernel)

The `builder-ultra` service builds the same system with global LTO and PGO; it is served under
`/ultra`. First build: `builder world full`, then `builder kernel` and `builder sign`. To switch the
Chromebook to it (and back), change the sync-uri and reinstall everything once:

```sh
sed -i 's|^sync-uri.*|sync-uri = http://<builder>:8780/ultra|' /etc/portage/binrepos.conf/sasuke.conf
sasuke-update --reinstall      # every package from the new binhost, plus its kernel
```

`sasuke-update --build` then starts the ULTRA build. LTO needs ~3 GB of RAM per job: on a
12 GB build server use `ULTRA_JOBS=4`.

## Daily use

| Key / place | Action |
|---|---|
| ▭\|\|\| (overview key) or "☰ App" | open/close the app menu |
| hold ○ (Search) | show the F1–F12 overlay; ○+top row = F1–F10, ○+' = F11, ○+ì = F12 |
| ⛶ | fullscreen on/off |
| ○+Esc | pass all shortcuts to Citrix/RDP (and back) |
| Ctrl+○+Q W E / A S D / Z X C | snap window to a screen region (grid) |
| ○+V | clipboard history |
| ○+Enter / ○+E / ○+L | terminal / files / lock |
| ⏻ in the bar | power off, reboot, suspend, logout, battery charge mode |
| TS in the bar | Tailscale menu |
| ⚡/⚖/🍃 in the bar | power profile |
| 🌙/☀ in the bar | night light |

## Notes

- **Citrix**: install requires the `linuxx64-*.tar.gz` from citrix.com in the builder's distfiles
  (licence: not redistributable). Telemetry (CEIP, Google Analytics, LaunchDarkly) is disabled by
  `citrix-notelemetry`. Its OpenGL renderer does not start under labwc/XWayland, so the software
  renderer is used.
- **Firefox**: telemetry, studies, Pocket, sponsored content and AI features are disabled through
  `policies.json`; hardware video decoding (VA-API) is enabled.

## Credits

- [MrChromebox](https://mrchromebox.tech) – UEFI firmware
- [WeirdTreeThing/alsa-ucm-conf-cros](https://github.com/WeirdTreeThing/alsa-ucm-conf-cros) – Chromebook audio profiles
- [keyd](https://github.com/rvaiya/keyd), [labwc](https://labwc.github.io), Gentoo and GURU maintainers

# LyargoOS

A custom Void Linux-based desktop distribution built using [void-mklive](https://github.com/void-linux/void-mklive).

## Features

- Multiple desktop flavors: KDE Plasma 5, XFCE, GNOME
- Comprehensive CLI toolkit: zsh, nano, neovim, git, tmux, htop, eza, fzf, fastfetch, and more
- GUI essentials: alacritty, gparted, gnome-disk-utility, zathura, copyq, celluloid, gwenview
- Input method: fcitx5 with Rime, Chinese addons, and config tool
- Papirus icon theme + WQY Microhei font
- Calamares GUI installer with optional software selection (browsers, media, graphics, etc.)
- void-installer (text mode fallback)
- Pipewire audio (per-user, auto-starts on login)
- NetworkManager + Avahi/mDNS (enabled at boot)
- elogind (session management, suspend, power control)
- Flatpak with Flathub pre-configured
- Void nonfree repo enabled by default (nvidia drivers, wifi firmware, microcode)
- qemu-guest-agent + spice-vdagent on x86_64 (for VM testing)
- Custom XBPS repository support
- Void Linux compatible (uses official Void repos)

## Quick Start

```bash
# Clone this repo
git clone https://github.com/Meniny/LyargoOS.git
cd lyargoos

# Add void-mklive as a submodule
git submodule add https://github.com/void-linux/void-mklive.git

# Build the KDE ISO (default flavor)
sudo ./mkiso.sh ./void-mklive

# Or build XFCE / GNOME
sudo ./mkiso.sh ./void-mklive -f xfce
sudo ./mkiso.sh ./void-mklive -f gnome
```

The built ISO will be named `void-live-<arch>-<date>-<flavor>.iso`.

## Build Options

```bash
sudo ./mkiso.sh ./void-mklive -f kde              # Desktop flavor (default: kde)
sudo ./mkiso.sh ./void-mklive -a x86_64            # Architecture (default: host arch)
sudo ./mkiso.sh ./void-mklive -d 20240101          # Override datecode
sudo ./mkiso.sh ./void-mklive -r https://...       # Add extra XBPS repo
```

Supported architectures: `x86_64`, `i686`, `aarch64`, `asahi` (Apple Silicon)

## Project Structure

```
lyargoos/
├── mkiso.sh              # Build script
├── lyargoos.conf         # Central config (brand, repos, extra packages)
├── flavors/
│   ├── kde/
│   │   ├── flavor.sh     # KDE Plasma 5 packages & services
│   │   └── overlay/      # KDE-specific rootfs overlay
│   ├── xfce/
│   │   ├── flavor.sh     # XFCE packages & services
│   │   └── overlay/      # XFCE-specific rootfs overlay
│   └── gnome/
│       ├── flavor.sh     # GNOME packages & services
│       └── overlay/      # GNOME-specific rootfs overlay
├── overlay/
│   └── common/           # Shared rootfs overlay (all flavors)
│       └── etc/
│           └── issue     # Login message
├── postsetup.sh          # Post-install script (flatpak setup, etc.)
└── .github/workflows/    # CI build workflow
```

Artwork and themes are installed via XBPS packages from the custom repo, not stored in this repo.

## Customization

| What | Where |
|------|-------|
| Brand identity | `lyargoos.conf` (`BRAND_NAME`, `BRAND_ID`, etc.) |
| Live user | `lyargoos.conf` (`LIVE_USER`, `LIVE_HOSTNAME`) |
| Custom repos | `lyargoos.conf` (`REPOS` array) |
| Base packages | `lyargoos.conf` (`BASE_PACKAGES` array) |
| Base services | `lyargoos.conf` (`BASE_SERVICES` array) |
| Desktop packages | `flavors/<flavor>/flavor.sh` (`FLAVOR_PKGS`) |
| Desktop services | `flavors/<flavor>/flavor.sh` (`FLAVOR_SERVICES`) |
| Shared overlay files | `overlay/common/` |
| Per-flavor overlay | `flavors/<flavor>/overlay/` |
| Login message | `overlay/common/etc/issue` |
| Post-install setup | `postsetup.sh` |

## GitHub Actions

Push to main or use the manual trigger in the Actions tab to build ISOs in CI. You can select the flavor, architecture, and datecode when triggering manually.

## Documentation

- [LYARGOOS.md](LYARGOOS.md) — Full documentation (English)
- [LYARGOOS.zh-CN.md](LYARGOOS.zh-CN.md) — 完整文档（中文）

## Updating void-mklive

```bash
cd void-mklive && git pull
cd .. && git add void-mklive && git commit -m "Update void-mklive submodule"
```

## License

Build scripts and configuration: MIT
Void Linux packages: their respective licenses

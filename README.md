# LyargoOS

![LyargoOS Linux](banner.jpg)

[LyargoOS](https://hotodogo.com/lyargoos/) is an opinionated Void Linux-based distribution named after the author's nickname "李二狗" (Li Ergou). It provides a preconfigured desktop with curated application choices out of the box.

## Features

- Multiple desktop flavors: KDE Plasma 5, XFCE, GNOME
- Comprehensive CLI toolkit: zsh, nano, neovim, git, tmux, htop, eza, fzf, fastfetch, and more
- GUI essentials: alacritty, gparted, gnome-disk-utility, zathura, CopyQ, celluloid, gwenview
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

## Why

Because I'm lazy.

## Download

Go to [SourceForge](https://sourceforge.net/projects/lyargoos/files/).

## Quick Start

```bash
# Clone this repo (includes void-mklive and lyargoos-artwork as submodules)
git clone --recursive https://github.com/Meniny/LyargoOS.git
cd lyargoos

# Build the KDE ISO (default flavor)
sudo ./mkiso.sh

# Or build XFCE / GNOME
sudo ./mkiso.sh -f xfce
sudo ./mkiso.sh -f gnome
```

If you already cloned without `--recursive`:
```bash
git submodule update --init --recursive
```

The built ISO will be named `void-live-<arch>-<date>-<flavor>.iso`.

## Build Options

```bash
sudo ./mkiso.sh -f kde              # Desktop flavor (default: kde)
sudo ./mkiso.sh -a x86_64            # Architecture (default: host arch)
sudo ./mkiso.sh -d 20240101          # Override datecode
sudo ./mkiso.sh -r https://...       # Add extra XBPS repo
sudo ./mkiso.sh -i cli               # CLI installer only (smaller ISO)
sudo ./mkiso.sh -i gui               # GUI installer only (Calamares)
sudo ./mkiso.sh -i full              # Both installers (default)
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

ISOs are built manually from the Actions tab. Click **Build LyargoOS ISO** → **Run workflow**, then choose the flavor, architecture, installer type, and datecode.

## Syncing with Upstream

If you forked this repo and want to pull in updates:

```bash
# One-time: add the original repo as "upstream"
git remote add upstream https://github.com/Meniny/LyargoOS.git

# Whenever you want updates:
git fetch upstream
git merge upstream/main
git push
```

Or use the **"Sync fork"** button on your fork's GitHub page.

## Documentation

- [LYARGOOS.md](LYARGOOS.md) — Full documentation (English)
- [LYARGOOS.zh-CN.md](LYARGOOS.zh-CN.md) — 完整文档（中文）

## Updating void-mklive

```bash
git submodule update --remote void-mklive
git add void-mklive
git commit -m "Update void-mklive submodule"
```

## License

Build scripts and configuration: MIT
Void Linux packages: their respective licenses

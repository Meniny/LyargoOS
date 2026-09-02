# LyargoOS Build System Documentation

LyargoOS is a custom Void Linux-based distribution built using the void-mklive tooling. This document explains the build system structure and how to customize it.

## Overview

LyargoOS is a **completely independent project** from void-mklive. It uses void-mklive as a build dependency but keeps all customization in its own repository. This means:

- No need to fork or modify void-mklive
- Easy to update void-mklive independently (just pull new changes)
- Clean separation between upstream tooling and your customization
- Your LyargoOS repo can be hosted anywhere, versioned independently

## Directory Structure

```
lyargoos/                      # This repository
├── mkiso.sh                   # Main build script
├── lyargoos.conf              # Central config (brand, repos, extra packages)
├── flavors/
│   ├── kde/
│   │   ├── flavor.sh          # KDE Plasma 5 packages & services
│   │   └── overlay/           # KDE-specific rootfs overlay
│   ├── xfce/
│   │   ├── flavor.sh          # XFCE packages & services
│   │   └── overlay/           # XFCE-specific rootfs overlay
│   └── gnome/
│       ├── flavor.sh          # GNOME packages & services
│       └── overlay/           # GNOME-specific rootfs overlay
├── overlay/
│   └── common/                # Shared rootfs overlay (all flavors)
│       └── etc/
│           └── issue          # Login message
├── postsetup.sh               # Post-install script (runs once during build)
├── void-mklive/               # Git submodule (upstream, unmodified)
├── .github/workflows/
│   └── build.yml              # GitHub Actions CI
├── LYARGOOS.md                # This documentation (English)
└── LYARGOOS.zh-CN.md          # This documentation (中文)
```

Artwork and themes are installed via XBPS packages from the custom `lyargoos-repo` and `lyargoos-artwork` repositories, not stored in this repo.

## Setup

### Local Development

```bash
# Clone your LyargoOS repo
git clone https://github.com/Meniny/LyargoOS.git
cd lyargoos

# Clone void-mklive (or add as submodule)
git clone https://github.com/void-linux/void-mklive.git

# Or use as a submodule (recommended)
git submodule add https://github.com/void-linux/void-mklive.git
git submodule update --init --recursive
```

### First-Time Setup (New Repository)

If you're starting from scratch:

```bash
# Create the project directory
mkdir lyargoos && cd lyargoos
git init

# Copy LyargoOS files into this directory (mkiso.sh, flavors/, overlay/, etc.)

# Add void-mklive as a submodule
git submodule add https://github.com/void-linux/void-mklive.git

# Commit and push
git add .
git commit -m "Initial LyargoOS setup"
git remote add origin https://github.com/Meniny/LyargoOS.git
git push -u origin main
```

After pushing, GitHub Actions will be available in the Actions tab.

### GitHub Actions

The included workflow builds ISOs automatically on push/PR and supports manual triggers with flavor, arch, and datecode selection.

To set up:
1. Push this repo to GitHub with the void-mklive submodule
2. Go to Actions tab — the workflow runs automatically
3. For manual builds: Actions > Build LyargoOS ISO > Run workflow (choose flavor, arch, datecode)

## Building

### Basic Build

```bash
sudo ./mkiso.sh ./void-mklive
```

This builds an x86_64 KDE ISO with the default configuration.

### Build Options

```bash
# Specify flavor (kde, xfce, gnome)
sudo ./mkiso.sh ./void-mklive -f kde             # Default
sudo ./mkiso.sh ./void-mklive -f xfce
sudo ./mkiso.sh ./void-mklive -f gnome

# Specify architecture
sudo ./mkiso.sh ./void-mklive -a x86_64          # Default
sudo ./mkiso.sh ./void-mklive -a i686            # 32-bit x86
sudo ./mkiso.sh ./void-mklive -a aarch64         # ARM 64-bit
sudo ./mkiso.sh ./void-mklive -a asahi           # Apple Silicon

# Override datecode (default: today's date in YYYYMMDD format)
sudo ./mkiso.sh ./void-mklive -d 20240101

# Add extra XBPS repository
sudo ./mkiso.sh ./void-mklive -r https://my-repo.example.com/current

# Combine options
sudo ./mkiso.sh ./void-mklive -f xfce -a x86_64 -d 20240101 -r https://...
```

### Output

The built ISO is named: `void-live-<arch>-<date>-<flavor>.iso`

## Customization Guide

### Central Configuration (lyargoos.conf)

The `lyargoos.conf` file controls brand identity, artwork, repositories, and extra packages. Edit this file instead of modifying scripts.

```bash
# Brand identity
BRAND_NAME="LyargoOS"
BRAND_VERSION="2024.1"
BRAND_ID="lyargo"
BRAND_PRETTY_NAME="LyargoOS (Void Linux)"
BRAND_HOME_URL="https://github.com/Meniny/LyargoOS"

# Custom XBPS repositories
REPOS=(
    "https://repo.lyargo.example.com/current"
)

# Extra packages (added to all flavors)
EXTRA_PACKAGES=(
    "flatpak"
    "brave"
    "lyargoos-artwork"
)

# Extra services (added to all flavors)
EXTRA_SERVICES=(
    "cupsd"
)

# Boot menu title
BOOT_TITLE="LyargoOS"
```

### Desktop Flavors

Each flavor defines which desktop environment and display manager to install. Flavor configs live in `flavors/`.

**Available flavors:**

| Flavor | Desktop | Display Manager | File |
|--------|---------|-----------------|------|
| `kde` | KDE Plasma 5 | sddm | `flavors/kde/flavor.sh` |
| `xfce` | XFCE 4 | lightdm | `flavors/xfce/flavor.sh` |
| `gnome` | GNOME | gdm | `flavors/gnome/flavor.sh` |

**Editing a flavor** (e.g., `flavors/kde/flavor.sh`):

```bash
FLAVOR_PKGS="$XORG_PKGS kde5 konsole firefox dolphin NetworkManager"
FLAVOR_PKGS="$FLAVOR_PKGS flatpak my-custom-package"

FLAVOR_SERVICES="dbus NetworkManager sddm polkitd"

POSTSETUP_SCRIPT="postsetup.sh"
```

**Available package groups** (defined by mkiso.sh before sourcing the flavor):
- `$XORG_PKGS` — X11 graphics stack + fonts
- `$WAYLAND_PKGS` — Wayland graphics stack + fonts (use for GNOME)
- `$FONTS` — Basic fonts (terminus, dejavu)
- `$A11Y_PKGS` — Accessibility packages (espeakup, brltty)
- `$GRUB_PKGS` — Architecture-specific bootloader packages
- `$GFX_PKGS` — Graphics drivers for current arch
- `$GFX_WL_PKGS` — Wayland graphics drivers for current arch

**Base packages** (defined in `lyargoos.conf`, installed on all flavors):
- Core: dialog, cryptsetup, lvm2, mdadm, chrony, elogind
- Shell & editors: zsh, nano, neovim
- CLI tools: ranger, mc, tmux, git, curl, wget, rsync, openssl, htop, eza, tree, fzf, ncdu, fastfetch, progress, glow, newt, zip, unzip, unrar, gzip, xz, p7zip
- Services: cronie, nss-mdns, avahi
- Fonts & icons: fontconfig, wqy-microhei, papirus-icon-theme
- GUI apps: alacritty, copyq, gparted, gnome-disk-utility, zathura, zathura-pdf-mupdf, grim, gwenview, celluloid
- Input method: fcitx5, fcitx5-qt, fcitx5-gtk4, fcitx5-rime, fcitx5-lua, fcitx5-chinese-addons, fcitx5-configtool
- Flatpak
- Audio: pipewire, alsa-pipewire
- VM tools: qemu-guest-agent, spice-vdagent (x86_64/i686 only)
- Installer: calamares, lyargoos-calamares-config

**Optional software** (selectable during Calamares installation):
- Browsers: chromium, brave
- Network: flclash
- Media: vlc (default), smplayer, audacious, audacity, kdenlive, obs-studio, guvcview, celluloid
- Graphics: gimp, inkscape, krita, flameshot (default)
- Productivity: peazip-qt6, okular, kate

**Base services** (enabled at boot):
- sshd, chronyd, elogind, spice-vdagentd (x86_64 only)

**Repositories**: The Void nonfree repo is enabled automatically for x86_64 and aarch64. This provides access to nvidia drivers, wifi firmware (linux-firmware), and CPU microcode.

### Adding/Removing Services

Edit the flavor file (e.g., `flavors/kde/flavor.sh`):

```bash
FLAVOR_SERVICES="dbus NetworkManager sddm polkitd"
FLAVOR_SERVICES="$FLAVOR_SERVICES my-custom-service"
```

Services must have a corresponding `/etc/sv/<service-name>` directory (provided by the package that installs the service).

### Overlay Files

The build system supports two overlay directories that are copied into the ISO rootfs:

1. **Common overlay** (`overlay/common/`) — shared across all flavors
2. **Per-flavor overlay** (`flavors/<flavor>/overlay/`) — specific to one flavor

The directory structure mirrors the target filesystem.

**Examples:**

```bash
# Add a default neovim config (all flavors)
mkdir -p overlay/common/etc/xdg/nvim
cp my-init.vim overlay/common/etc/xdg/nvim/init.vim

# Add a KDE-specific Dolphin config
mkdir -p flavors/kde/overlay/etc/xdg/dolphinrc
cp dolphinrc flavors/kde/overlay/etc/xdg/

# Add a default zsh config for new users
cp my-zshrc overlay/common/etc/skel/.zshrc

# Add a custom X11 config
mkdir -p overlay/common/etc/X11/xorg.conf.d
cp my-monitor.conf overlay/common/etc/X11/xorg.conf.d/90-monitor.conf
```

All files in overlay directories are copied into the ISO rootfs, overwriting any existing files with the same path. The common overlay is applied first, then the flavor overlay (so flavor files can override common ones).

**Note:** `os-release` is generated automatically from `lyargoos.conf` — do not place a static one in `overlay/`.

### Login Message

Edit `overlay/common/etc/issue`. This is displayed at the text login prompt.

### Post-Install Script

The post-install script (`postsetup.sh`) runs once during ISO build, after all packages are installed. It receives the rootfs path as `$1`.

Use it for:
- Setting up flatpak remotes
- Generating caches (icon caches, font caches, etc.)
- Any one-time configuration that needs to run in the target environment

Example:

```bash
#!/bin/sh
ROOTFS="$1"

# Add Flathub remote
mkdir -p "$ROOTFS/etc/flatpak/remotes.d"
cat > "$ROOTFS/etc/flatpak/remotes.d/flathub.conf" << 'EOF'
[remote "flathub"]
url=https://dl.flathub.org/repo/flathub.flatpakrepo
gpg-verify=true
EOF

# Generate font cache
xbps-uchroot "$ROOTFS" fc-cache -f
```

### Adding a New Flavor

1. **Create the flavor directory:**

```bash
mkdir -p flavors/my-desktop/overlay
touch flavors/my-desktop/overlay/.gitkeep
```

2. **Create the flavor config:**

```bash
# flavors/my-desktop/flavor.sh
FLAVOR_PKGS="$XORG_PKGS my-desktop-environment my-terminal"
FLAVOR_PKGS="$FLAVOR_PKGS flatpak"
FLAVOR_SERVICES="dbus NetworkManager my-display-manager polkitd"
POSTSETUP_SCRIPT="postsetup.sh"
```

3. **Build with the new flavor:**

```bash
sudo ./mkiso.sh ./void-mklive -f my-desktop
```

## Architecture Support

The build system supports multiple architectures with arch-specific packages:

| Architecture | GRUB Packages | Graphics Drivers | Kernel | Installer |
|--------------|---------------|------------------|--------|-----------|
| x86_64 | grub-i386-efi, grub-x86_64-efi | xorg-video-drivers, xf86-video-intel | linux (default) | Yes |
| i686 | grub-i386-efi, grub-x86_64-efi | xorg-video-drivers, xf86-video-intel | linux (default) | Yes |
| aarch64 | grub-arm64-efi | xorg-video-drivers | linux (default) | Stub only |
| asahi | asahi-base, asahi-scripts, grub-arm64-efi | mesa-asahi-dri | linux-asahi | Stub only |

For Asahi builds, additional packages are automatically added:
- `asahi-audio` — Audio support for Apple Silicon
- `speakersafetyd` service — Speaker protection daemon

## Syncing with Upstream

Since LyargoOS uses void-mklive as a submodule, updating is straightforward:

```bash
# Update the void-mklive submodule
cd void-mklive
git pull

# Go back to LyargoOS root and commit the updated submodule reference
cd ..
git add void-mklive
git commit -m "Update void-mklive submodule"

# Build with the updated tooling
sudo ./mkiso.sh ./void-mklive
```

No merge conflicts possible — your files and upstream files never mix.

## Troubleshooting

### Build fails with "void-mklive directory not found"

Make sure you're passing the correct path to void-mklive as the first argument:

```bash
sudo ./mkiso.sh /path/to/void-mklive
```

### Build fails with "flavor 'xyz' not found"

Check that `flavors/xyz/flavor.sh` exists. List available flavors:

```bash
ls flavors/
```

### Packages not installing

Check that the package names are correct. You can search for packages at:
- https://voidlinux.org/packages/

### Service fails to enable

Services must have a corresponding `/etc/sv/<service-name>` directory. Check that the package providing the service is installed.

### Custom repo not working

1. Check the URL in `lyargoos.conf` (`REPOS` array)
2. Ensure the repo is signed and the key is trusted
3. Test with: `xbps-install -S` (sync repos) then `xbps-query -R <package>`

## Advanced Topics

### Multiple Custom Repositories

Add multiple repos in `lyargoos.conf`:

```bash
REPOS=(
    "https://repo.lyargo.example.com/current"
    "https://repo.lyargo.example.com/extra"
    "https://repo.lyargo.example.com/testing"
)
```

Each repo will be added as a separate config file in `/etc/xbps.d/`.

### Pre-configuring Flatpak Remotes

Edit `postsetup.sh`:

```bash
# Add Flathub
cat > "$ROOTFS/etc/flatpak/remotes.d/flathub.conf" << 'EOF'
[remote "flathub"]
url=https://dl.flathub.org/repo/flathub.flatpakrepo
gpg-verify=true
EOF

# Add a custom remote
cat > "$ROOTFS/etc/flatpak/remotes.d/my-remote.conf" << 'EOF'
[remote "my-remote"]
url=https://my-flatpak-repo.example.com
gpg-verify=false
EOF
```

### Custom Default User Configuration

Files in `overlay/common/etc/skel/` are copied to new user home directories:

```bash
overlay/common/etc/skel/
├── .bashrc
├── .zshrc
├── .config/
│   └── nvim/
│       └── init.vim
└── .local/
    └── share/
        └── applications/
            └── my-app.desktop
```

## File Reference

| File | Purpose |
|------|---------|
| `mkiso.sh` | Main build script — handles flavor selection, arch detection, package assembly, ISO generation |
| `lyargoos.conf` | Central config — brand identity, repos, extra packages/services, boot title |
| `flavors/kde/flavor.sh` | KDE Plasma 5 packages and services |
| `flavors/xfce/flavor.sh` | XFCE packages and services |
| `flavors/gnome/flavor.sh` | GNOME packages and services |
| `overlay/common/` | Shared files overlaid into the ISO rootfs (all flavors) |
| `flavors/<flavor>/overlay/` | Per-flavor files overlaid into the ISO rootfs |
| `overlay/common/etc/issue` | Login prompt message |
| `postsetup.sh` | Post-install script (flatpak setup, cache generation, etc.) |

## See Also

- [Void Linux Handbook](https://docs.voidlinux.org/)
- [xbps documentation](https://github.com/void-linux/xbps)
- [void-mklive upstream](https://github.com/void-linux/void-mklive)

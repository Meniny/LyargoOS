#!/bin/sh
# LyargoOS postsetup script
# This runs once during ISO build after packages are installed
# Receives $ROOTFS as the first argument

set -e

ROOTFS="$1"

if [ -z "$ROOTFS" ]; then
    echo "Error: ROOTFS path not provided" >&2
    exit 1
fi

echo "=> Running LyargoOS postsetup script..."

# Add Flathub remote for flatpak
if [ -x "$ROOTFS/usr/bin/flatpak" ]; then
    echo "=> Adding Flathub remote..."
    mkdir -p "$ROOTFS/var/lib/flatpak/remotes"
    mkdir -p "$ROOTFS/etc/flatpak/remotes.d"
    # Create a system-wide flatpak config that adds Flathub on first boot
    cat > "$ROOTFS/etc/flatpak/remotes.d/flathub.conf" << 'EOF'
[remote "flathub"]
url=https://dl.flathub.org/repo/flathub.flatpakrepo
gpg-verify=true
EOF
fi

echo "=> LyargoOS postsetup complete"

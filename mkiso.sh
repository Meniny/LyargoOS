#!/bin/bash
#
# mkiso.sh — Build LyargoOS live ISO
#
# This script builds LyargoOS ISOs using the void-mklive submodule.
# All LyargoOS-specific configuration lives in this directory.
#
# Usage:
#   ./mkiso.sh                        # Build x86_64 KDE ISO (full installer)
#   ./mkiso.sh -f xfce                # Build XFCE flavor
#   ./mkiso.sh -a i686 -f gnome       # Build GNOME for i686
#   ./mkiso.sh -d 20240101            # Override datecode
#   ./mkiso.sh -r https://...         # Add extra repo
#   ./mkiso.sh -i cli                 # CLI installer only (smaller ISO)
#   ./mkiso.sh -i gui                 # GUI installer only
#   ./mkiso.sh -i full                # Both installers (default)
#
# Requirements:
#   - void-mklive submodule (git submodule update --init --recursive)
#   - root privileges (or run with sudo)

set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MKLIVE_DIR="$SCRIPT_DIR/void-mklive"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
info() { echo -e "${BLUE}==>${NC} $1"; }
success() { echo -e "${GREEN}==>${NC} $1"; }
warn() { echo -e "${YELLOW}==>${NC} $1" >&2; }
error() { echo -e "${RED}Error:${NC} $1" >&2; }

# --- Validate void-mklive submodule ---
if [ ! -d "$MKLIVE_DIR" ]; then
    error "void-mklive submodule not found"
    echo "Run: git submodule update --init --recursive" >&2
    exit 1
fi

if [ ! -f "$MKLIVE_DIR/mklive.sh" ]; then
    error "mklive.sh not found in void-mklive submodule"
    echo "Run: git submodule update --init --recursive" >&2
    exit 1
fi

# --- Source lib.sh from mklive ---
. "$MKLIVE_DIR/lib.sh"

# --- Load LyargoOS config ---
if [ -f "$SCRIPT_DIR/lyargoos.conf" ]; then
    . "$SCRIPT_DIR/lyargoos.conf"
else
    error "lyargoos.conf not found in: $SCRIPT_DIR"
    exit 1
fi

# --- Default values ---
ARCH=$(uname -m)
DATE=$(date -u +%Y%m%d)
FLAVOR="kde"
INSTALLER="full"
REPO=""
MIRROR_OVERRIDE=""

# --- Parse remaining arguments ---
while getopts "a:d:f:i:m:r:h" opt; do
case $opt in
    a) ARCH="$OPTARG";;
    d) DATE="$OPTARG";;
    f) FLAVOR="$OPTARG";;
    i) INSTALLER="$OPTARG";;
    m) MIRROR_OVERRIDE="$OPTARG";;
    r) REPO="--repository=$OPTARG $REPO";;
    h)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Build LyargoOS live ISO."
        echo ""
        echo "Options:"
        echo "  -a ARCH       Target architecture (default: $(uname -m))"
        echo "                Values: x86_64, i686, aarch64, asahi"
        echo "  -d DATECODE   Build datecode in YYYYMMDD format (default: today)"
        echo "  -f FLAVOR     Desktop flavor (default: kde)"
        echo "                Values: kde, xfce, gnome"
        echo "  -i INSTALLER  Installer type (default: full)"
        echo "                Values: cli (text only), gui (GUI only), full (both)"
        echo "  -m MIRROR     Void Linux repository mirror"
        echo "                Default: https://repo-default.voidlinux.org/current"
        echo "                Examples:"
        echo "                  https://mirrors.tuna.tsinghua.edu.cn/voidlinux/current"
        echo "                  https://mirrors.ustc.edu.cn/voidlinux/current"
        echo "  -r URL        Add extra repository URL (can be specified multiple times)"
        echo "  -h            Show this help message"
        echo ""
        echo "Output:"
        echo "  Filename: void-live-{ARCH}-{DATE}-{FLAVOR}.iso"
        echo "  Location: Same directory as this script"
        echo "  Example:  void-live-x86_64-20240101-kde.iso"
        echo ""
        echo "Examples:"
        echo "  sudo $0                        # Build x86_64 KDE ISO with full installer"
        echo "  sudo $0 -f xfce                # Build XFCE flavor"
        echo "  sudo $0 -a aarch64 -f gnome    # Build GNOME for ARM64"
        echo "  sudo $0 -i cli -d 20240101     # CLI installer only, specific date"
        echo "  sudo $0 -m https://mirrors.tuna.tsinghua.edu.cn/voidlinux/current"
        echo ""
        echo "Note: This script requires root privileges (run with sudo)."
        exit 0;;
    *) exit 1;;
esac
done
shift $((OPTIND - 1))

# --- Check root privileges ---
if [ "$(id -u)" -ne 0 ]; then
    error "This script must be run as root (use sudo)"
    exit 1
fi

# Validate installer type
case "$INSTALLER" in
    cli|gui|full) ;;
    *) error "Invalid installer type '$INSTALLER'. Use: cli, gui, full"; exit 1;;
esac

# --- Arch-specific setup (mirrors mkiso.sh logic) ---
TARGET_ARCH="$ARCH"
KERNEL_PKG=""
WANT_INSTALLER=no

# Use mirror from command line (-m) or from config (VOID_MIRROR)
VOID_MIRROR="${MIRROR_OVERRIDE:-$VOID_MIRROR}"

case "$ARCH" in
    x86_64*|i686*)
        GRUB_PKGS="grub-i386-efi grub-x86_64-efi"
        GFX_PKGS="xorg-video-drivers xf86-video-intel"
        GFX_WL_PKGS="mesa-dri"
        WANT_INSTALLER=yes
        NONFREE_REPO="$VOID_MIRROR/nonfree"
        VM_PKGS="qemu-ga spice-vdagent"
        VM_SERVICES="spice-vdagentd"
        # x86_64 glibc: only need main repo (musl and aarch64 repos are not needed)
        export XBPS_REPOSITORY="--repository=$VOID_MIRROR"
        ;;
    aarch64*)
        GRUB_PKGS="grub-arm64-efi"
        GFX_PKGS="xorg-video-drivers"
        GFX_WL_PKGS="mesa-dri"
        NONFREE_REPO="$VOID_MIRROR/nonfree"
        VM_PKGS=""
        VM_SERVICES=""
        # aarch64 glibc: only need aarch64 repo
        export XBPS_REPOSITORY="--repository=$VOID_MIRROR/aarch64"
        ;;
    asahi*)
        GRUB_PKGS="asahi-base asahi-scripts grub-arm64-efi"
        GFX_PKGS="mesa-asahi-dri"
        GFX_WL_PKGS="mesa-asahi-dri"
        KERNEL_PKG="linux-asahi"
        TARGET_ARCH="aarch64${ARCH#asahi}"
        NONFREE_REPO=""
        VM_PKGS=""
        VM_SERVICES=""
        # Asahi: aarch64 repo
        export XBPS_REPOSITORY="--repository=$VOID_MIRROR/aarch64"
        ;;
    *)
        echo "Unsupported architecture: $ARCH" >&2
        exit 1
        ;;
esac

# --- Common package groups (graphics stacks, added based on flavor) ---
A11Y_PKGS="espeakup void-live-audio brltty"
FONTS="font-misc-misc terminus-font dejavu-fonts-ttf"
XORG_PKGS="$GFX_PKGS $FONTS xorg-minimal xorg-input-drivers setxkbmap xauth orca"
WAYLAND_PKGS="$GFX_WL_PKGS $FONTS orca"

# --- Validate flavor ---
case "$FLAVOR" in
    kde|xfce|gnome) ;;
    *)
        error "Unknown flavor '$FLAVOR'"
        echo "Available flavors: kde, xfce, gnome" >&2
        exit 1
        ;;
esac

# --- Build package and service lists ---
# Base packages and services from lyargoos.conf
PKGS="${BASE_PACKAGES[*]}"
PKGS="$PKGS $VM_PKGS"
PKGS="$PKGS $A11Y_PKGS $GRUB_PKGS"
SERVICES="${BASE_SERVICES[*]} $VM_SERVICES"

# Flavor-specific packages and services
case "$FLAVOR" in
    kde)
        PKGS="$PKGS $XORG_PKGS ${KDE_PKGS[*]}"
        SERVICES="$SERVICES ${KDE_SERVICES[*]}"
        ;;
    xfce)
        PKGS="$PKGS $XORG_PKGS ${XFCE_PKGS[*]}"
        SERVICES="$SERVICES ${XFCE_SERVICES[*]}"
        ;;
    gnome)
        PKGS="$PKGS $WAYLAND_PKGS ${GNOME_PKGS[*]}"
        SERVICES="$SERVICES ${GNOME_SERVICES[*]}"
        ;;
esac

# Add calamares (GUI installer) based on installer type
if [ "$INSTALLER" = "gui" ] || [ "$INSTALLER" = "full" ]; then
    PKGS="$PKGS calamares lyargoos-calamares-config"
fi

# Add nonfree repo (if available for this arch)
if [ -n "$NONFREE_REPO" ]; then
    REPO="-r $NONFREE_REPO $REPO"
fi

# Add repos from config as -r flags
for repo_url in "${REPOS[@]}"; do
    REPO="-r $repo_url $REPO"
done

# --- Prepare include directory ---
INCLUDEDIR=$(mktemp -d)
COMBINED_POSTSETUP=""
LYARGO_KEY_COPIED=""
cleanup() {
    rm -rf "$INCLUDEDIR"
    [ -n "$COMBINED_POSTSETUP" ] && rm -f "$COMBINED_POSTSETUP"
    # Remove LyargoOS key from void-mklive/keys/ if we copied it
    if [ -n "$LYARGO_KEY_COPIED" ] && [ -f "$MKLIVE_DIR/keys/$LYARGO_KEY_COPIED" ]; then
        rm -f "$MKLIVE_DIR/keys/$LYARGO_KEY_COPIED"
    fi
}
trap cleanup INT TERM EXIT

# Generate os-release from config
mkdir -p "$INCLUDEDIR"/etc
cat > "$INCLUDEDIR"/etc/os-release << EOF
NAME="$BRAND_NAME"
VERSION="$BRAND_VERSION"
ID=$BRAND_ID
ID_LIKE=void
PRETTY_NAME="$BRAND_PRETTY_NAME"
HOME_URL="$BRAND_HOME_URL"
DOCUMENTATION_URL="$BRAND_DOC_URL"
EOF

# Generate live branding config (read by dracut branding.sh at boot)
cat > "$INCLUDEDIR"/etc/void-live.conf << EOF
LIVE_USER="${LIVE_USER:-live}"
LIVE_HOSTNAME="${LIVE_HOSTNAME:-lyargoos-live}"
LIVE_PASSWORD="${LIVE_PASSWORD:-lyargoos}"
EOF

# Generate repo configs from REPOS array + nonfree
if [ ${#REPOS[@]} -gt 0 ] || [ -n "$NONFREE_REPO" ]; then
    mkdir -p "$INCLUDEDIR"/etc/xbps.d
    i=0
    if [ -n "$NONFREE_REPO" ]; then
        echo "repository=$NONFREE_REPO" > "$INCLUDEDIR/etc/xbps.d/00-nonfree.conf"
    fi
    for repo_url in "${REPOS[@]}"; do
        echo "repository=$repo_url" > "$INCLUDEDIR/etc/xbps.d/lyargo-repo-$i.conf"
        i=$((i + 1))
    done
fi

# Include void-installer (x86_64/i686) or stub (ARM)
if [ "$WANT_INSTALLER" = yes ]; then
    if [ -x "$MKLIVE_DIR/installer.sh" ]; then
        MKLIVE_VERSION="$(cat "$MKLIVE_DIR/version") $(git -C "$MKLIVE_DIR" rev-parse --short HEAD 2>/dev/null || echo '')"
        installer=$(mktemp)
        sed "s/@@MKLIVE_VERSION@@/${MKLIVE_VERSION}/" "$MKLIVE_DIR/installer.sh" > "$installer"
        install -Dm755 "$installer" "$INCLUDEDIR"/usr/bin/void-installer
        rm "$installer"
    fi
else
    mkdir -p "$INCLUDEDIR"/usr/bin
    printf "#!/bin/sh\necho 'void-installer is not supported on this live image'\n" > "$INCLUDEDIR"/usr/bin/void-installer
    chmod 755 "$INCLUDEDIR"/usr/bin/void-installer
fi

# Setup pipewire symlinks
PKGS="$PKGS pipewire alsa-pipewire"
case "$ARCH" in
    asahi*)
        PKGS="$PKGS asahi-audio"
        SERVICES="$SERVICES speakersafetyd"
        ;;
esac
mkdir -p "$INCLUDEDIR"/etc/xdg/autostart
ln -sf /usr/share/applications/pipewire.desktop "$INCLUDEDIR"/etc/xdg/autostart/
mkdir -p "$INCLUDEDIR"/etc/pipewire/pipewire.conf.d
ln -sf /usr/share/examples/wireplumber/10-wireplumber.conf "$INCLUDEDIR"/etc/pipewire/pipewire.conf.d/
ln -sf /usr/share/examples/pipewire/20-pipewire-pulse.conf "$INCLUDEDIR"/etc/pipewire/pipewire.conf.d/
mkdir -p "$INCLUDEDIR"/etc/alsa/conf.d
ln -sf /usr/share/alsa/alsa.conf.d/50-pipewire.conf "$INCLUDEDIR"/etc/alsa/conf.d
ln -sf /usr/share/alsa/alsa.conf.d/99-pipewire-default.conf "$INCLUDEDIR"/etc/alsa/conf.d

# --- Determine postsetup scripts ---
# Supports: common postsetup.sh + flavor-specific flavors/$FLAVOR/postsetup.sh
# Common runs first, then flavor-specific (if both exist)
COMMON_POSTSETUP="$SCRIPT_DIR/postsetup.sh"
FLAVOR_POSTSETUP="$SCRIPT_DIR/flavors/$FLAVOR/postsetup.sh"
POSTSETUP_FULL=""

# Helper: extract body of a postsetup script (skip shebang, set -e, ROOTFS assignment)
extract_postsetup_body() {
    sed -e '1{/^#!/d}' -e '/^[[:space:]]*set[[:space:]]\+-e[[:space:]]*$/d' -e '/^[[:space:]]*ROOTFS=/d' "$1"
}

if [ -f "$COMMON_POSTSETUP" ] && [ -f "$FLAVOR_POSTSETUP" ]; then
    # Both exist: create wrapper that runs common first, then flavor-specific
    COMBINED_POSTSETUP=$(mktemp)
    cat > "$COMBINED_POSTSETUP" << 'WRAPPER'
#!/bin/sh
# Combined postsetup: common + flavor-specific
set -e
ROOTFS="$1"
WRAPPER
    echo "" >> "$COMBINED_POSTSETUP"
    echo "# --- Common postsetup ---" >> "$COMBINED_POSTSETUP"
    extract_postsetup_body "$COMMON_POSTSETUP" >> "$COMBINED_POSTSETUP"
    echo "" >> "$COMBINED_POSTSETUP"
    echo "# --- Flavor-specific postsetup ---" >> "$COMBINED_POSTSETUP"
    extract_postsetup_body "$FLAVOR_POSTSETUP" >> "$COMBINED_POSTSETUP"
    chmod +x "$COMBINED_POSTSETUP"
    POSTSETUP_FULL="$COMBINED_POSTSETUP"
elif [ -f "$COMMON_POSTSETUP" ]; then
    POSTSETUP_FULL="$COMMON_POSTSETUP"
elif [ -f "$FLAVOR_POSTSETUP" ]; then
    POSTSETUP_FULL="$FLAVOR_POSTSETUP"
fi

# --- Build ISO ---
IMG="lyargoos-${ARCH}-${DATE}-${FLAVOR}.iso"

info "Building LyargoOS ISO: $IMG"
echo "    void-mklive: $MKLIVE_DIR"
echo "    Flavor: $FLAVOR"
echo "    Arch: $TARGET_ARCH"
echo "    Date: $DATE"
echo "    Mirror: $VOID_MIRROR"

cd "$MKLIVE_DIR"

# Build -I arguments: temp dir + common overlay + flavor overlay
INCLUDE_ARGS="-I $INCLUDEDIR"
if [ -d "$SCRIPT_DIR/overlay/common" ]; then
    INCLUDE_ARGS="$INCLUDE_ARGS -I $SCRIPT_DIR/overlay/common"
fi
FLAVOR_OVERLAY="$SCRIPT_DIR/flavors/$FLAVOR/overlay"
if [ -d "$FLAVOR_OVERLAY" ] && [ "$(find "$FLAVOR_OVERLAY" -mindepth 1 -maxdepth 1 2>/dev/null)" ]; then
    INCLUDE_ARGS="$INCLUDE_ARGS -I $FLAVOR_OVERLAY"
fi

# Resolve artwork path for GRUB/isolinux splash image
ARTWORK_FULL="$(cd "$SCRIPT_DIR" && cd "$ARTWORK_DIR" 2>/dev/null && pwd)" || ARTWORK_FULL=""
SPLASH_ARGS=""
if [ -n "$ARTWORK_FULL" ] && [ -f "$ARTWORK_FULL/grub/grub.png" ]; then
    export SPLASH_IMAGE="$ARTWORK_FULL/grub/grub.png"
fi

# Copy LyargoOS signing key to void-mklive/keys/ so xbps trusts the custom repo
# This avoids the "Do you want to import this public key?" prompt during build
LYARGO_PUBKEY="$SCRIPT_DIR/overlay/common/etc/xbps.d/LyargoOS.pub"
LYARGO_FINGERPRINT_FILE="$SCRIPT_DIR/overlay/common/etc/xbps.d/fingerprint"
if [ -f "$LYARGO_PUBKEY" ] && [ -f "$LYARGO_FINGERPRINT_FILE" ]; then
    # Read fingerprint from file (generated by publish.sh)
    LYARGO_FINGERPRINT=$(cat "$LYARGO_FINGERPRINT_FILE" | tr -d '[:space:]')
    LYARGO_KEY_DEST="$MKLIVE_DIR/keys/${LYARGO_FINGERPRINT}.plist"
    if [ ! -f "$LYARGO_KEY_DEST" ]; then
        # Get key size
        KEY_SIZE=$(openssl rsa -pubin -in "$LYARGO_PUBKEY" -text -noout 2>/dev/null | head -1 | grep -oP '\d+' | head -1)
        KEY_SIZE=${KEY_SIZE:-4096}
        # Generate plist from PEM public key
        PUBKEY_B64=$(base64 -w 0 < "$LYARGO_PUBKEY")
        cat > "$LYARGO_KEY_DEST" << KEYEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>public-key</key>
	<data>${PUBKEY_B64}</data>
	<key>public-key-size</key>
	<integer>${KEY_SIZE}</integer>
	<key>signature-by</key>
	<string>LyargoOS</string>
</dict>
</plist>
KEYEOF
        LYARGO_KEY_COPIED="${LYARGO_FINGERPRINT}.plist"
        info "LyargoOS repo key installed (fingerprint: $LYARGO_FINGERPRINT)"
    fi
elif [ -f "$LYARGO_PUBKEY" ]; then
    warn "LyargoOS.pub found but fingerprint file missing. Run publish.sh first."
fi

./mklive.sh \
    -a "$TARGET_ARCH" \
    -o "$IMG" \
    -p "$PKGS" \
    -S "$SERVICES" \
    $INCLUDE_ARGS \
    -T "$BOOT_TITLE" \
    -C "live.user=${LIVE_USER:-live}" \
    -C "live.shell=/bin/zsh" \
    ${POSTSETUP_FULL:+-x "$POSTSETUP_FULL"} \
    ${KERNEL_PKG:+-v "$KERNEL_PKG"} \
    $REPO \
    "$@"

# Move ISO to script directory
mv "$IMG" "$SCRIPT_DIR/"

success "Done: $SCRIPT_DIR/$IMG"

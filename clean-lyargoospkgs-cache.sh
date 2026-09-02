#!/bin/sh
# Clean cached custom packages to force re-download on next ISO build
set -e

usage() {
    cat <<EOF
Usage: $(basename "$0") [options] [package1 package2 ...]

Clean cached custom packages from the XBPS cache directory.

Options:
  -h, --help    Show this help message

Arguments:
  package1 ...  Specific packages to clean. If none specified, cleans all
                custom packages.

Examples:
  $(basename "$0")                  Clean all custom packages
  $(basename "$0") peazip-qt6      Clean only peazip-qt6
  $(basename "$0") brave flclash   Clean brave and flclash

Custom packages:
  $ALL_PKGS
EOF
}

# All custom packages from lyargoos-repo
ALL_PKGS="base-files brave calamares flclash lyargoos-artwork lyargoos-base \
          lyargoos-calamares-config lyargoos-kde-theme lyargoos-welcome lyargoos-xbps \
          onlyoffice peazip-gtk2 peazip-qt6 qq ungoogled-chromium vscodium wechat wps-office zen"

# Check for help flag
case "${1:-}" in
    -h|--help)
        usage
        exit 0
        ;;
esac

CACHE_DIR="void-mklive/xbps-cachedir-$(uname -m)"

if [ ! -d "$CACHE_DIR" ]; then
    echo "Cache directory not found: $CACHE_DIR"
    exit 0
fi

# Use specified packages or all if none specified
if [ $# -gt 0 ]; then
    PKGS="$@"
    echo "Cleaning specific packages: $PKGS"
else
    PKGS="$ALL_PKGS"
    echo "Cleaning all custom packages..."
fi

for pkg in $PKGS; do
    sudo rm -f "$CACHE_DIR"/${pkg}-*.xbps "$CACHE_DIR"/${pkg}-*.xbps.sig2 2>/dev/null || true
done

echo "Done. Next ISO build will download fresh packages."

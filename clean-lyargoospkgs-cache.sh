#!/bin/sh
# Clean cached custom packages to force re-download on next ISO build
# Usage: ./clean-lyargoospkgs-cache.sh [package1] [package2] ...
# If no packages specified, cleans all custom packages
set -e

CACHE_DIR="void-mklive/xbps-cachedir-$(uname -m)"

if [ ! -d "$CACHE_DIR" ]; then
    echo "Cache directory not found: $CACHE_DIR"
    exit 0
fi

# All custom packages from lyargoos-repo
ALL_PKGS="base-files brave calamares flclash lyargoos-artwork lyargoos-base \
          lyargoos-calamares-config lyargoos-kde-theme lyargoos-welcome lyargoos-xbps \
          onlyoffice peazip peazip-gtk2 qq ungoogled-chromium vscodium wechat wps-office zen"

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

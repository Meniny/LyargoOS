#!/bin/sh
# Clean cached custom packages to force re-download on next ISO build
set -e

CACHE_DIR="void-mklive/xbps-cachedir-$(uname -m)"

if [ ! -d "$CACHE_DIR" ]; then
    echo "Cache directory not found: $CACHE_DIR"
    exit 0
fi

echo "Cleaning custom package cache..."

# Remove all custom packages from lyargoos-repo
for pkg in brave calamares flclash lyargoos-artwork lyargoos-base lyargoos-base-files \
           lyargoos-calamares-config lyargoos-kde-theme lyargoos-welcome lyargoos-xbps \
           onlyoffice peazip qq ungoogled-chromium vscodium wechat wps-office zen; do
    sudo rm -f "$CACHE_DIR"/${pkg}-*.xbps 2>/dev/null || true
done

echo "Done. Next ISO build will download fresh packages."

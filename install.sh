#!/bin/bash
set -e

# Folio CLI univerzális Linux/macOS telepítő szkript
# Használat: curl -fsSL https://raw.githubusercontent.com/CsPS0/folio-cli/main/install.sh | bash

REPO="CsPS0/folio-cli"
BIN_DIR="/usr/local/bin"
BIN_NAME="folio-cli"

echo "Folio CLI letöltése és telepítése..."

# Legújabb verzió kiderítése
LATEST_RELEASE=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$LATEST_RELEASE" ]; then
    echo "Hiba: Nem sikerült lekérdezni a legújabb verziót."
    exit 1
fi

echo "Legújabb verzió: $LATEST_RELEASE"

# Operációs rendszer és architektúra detektálása
OS="$(uname -s)"
ARCH="$(uname -m)"

if [ "$OS" = "Linux" ]; then
    ASSET_NAME="folio-cli-linux"
elif [ "$OS" = "Darwin" ]; then
    ASSET_NAME="folio-cli-macos"
else
    echo "Nem támogatott operációs rendszer: $OS"
    exit 1
fi

DOWNLOAD_URL="https://github.com/$REPO/releases/download/$LATEST_RELEASE/$ASSET_NAME"

echo "Letöltés: $DOWNLOAD_URL"
curl -fsSL -o "$BIN_NAME" "$DOWNLOAD_URL"
chmod +x "$BIN_NAME"

echo "Telepítés a $BIN_DIR mappába (sudo jogosultság szükséges lehet)..."
sudo mv "$BIN_NAME" "$BIN_DIR/$BIN_NAME"

echo "Sikeres telepítés! Futtasd a 'folio-cli' parancsot az indításhoz."

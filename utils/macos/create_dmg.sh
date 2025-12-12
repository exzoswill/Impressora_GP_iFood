#!/usr/bin/env bash
# Cria um .dmg a partir de um .app (macOS)
# Uso: create_dmg.sh /path/to/App.app /output/App.dmg

set -euo pipefail

APP_PATH="${1:?Usage: $0 /path/to/App.app /output/App.dmg}"
OUT_DMG="${2:?Usage: $0 /path/to/App.app /output/App.dmg}"

if [ ! -d "$APP_PATH" ]; then
  echo "App não encontrado em $APP_PATH"; exit 1
fi

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

cp -R "$APP_PATH" "$TMPDIR/"
VOLUME_NAME="ImpressoraGPiFood"

echo "Criando imagem de disco..."
hdiutil create -volname "$VOLUME_NAME" -srcfolder "$TMPDIR" -ov -format UDZO "$OUT_DMG"

echo "DMG criado em $OUT_DMG"
exit 0

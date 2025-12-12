#!/usr/bin/env bash
# Baixa e embute um binário Node.js dentro de um .app gerado pelo create_app.sh
# Uso: ./embed_node.sh /caminho/para/ImpressoraGPiFood.app [12.22.12]

set -euo pipefail

APP_PATH="${1:?Usage: $0 /path/to/ImpressoraGPiFood.app [node_version]}"
NODE_VERSION="${2:-12.22.12}"

if [ ! -d "$APP_PATH/Contents/Resources" ]; then
  echo "Diretório $APP_PATH/Contents/Resources não encontrado. Crie o app com create_app.sh antes."
  exit 1
fi

ARCH=$(uname -m)
case "$ARCH" in
  x86_64) NODE_ARCH="x64";;
  arm64|aarch64) NODE_ARCH="arm64";;
  *) echo "Arquitetura $ARCH não suportada automaticamente"; exit 1;;
esac

TAR_NAME="node-v${NODE_VERSION}-darwin-${NODE_ARCH}.tar.gz"
URL="https://nodejs.org/dist/v${NODE_VERSION}/${TAR_NAME}"

echo "Baixando $URL..."
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

if command -v curl >/dev/null 2>&1; then
  curl -fSL "$URL" -o "$TMPDIR/$TAR_NAME"
elif command -v wget >/dev/null 2>&1; then
  wget -O "$TMPDIR/$TAR_NAME" "$URL"
else
  echo "curl ou wget necessário para baixar o Node"; exit 1
fi

echo "Extraindo..."
tar -xzf "$TMPDIR/$TAR_NAME" -C "$TMPDIR"

SRC_DIR="$TMPDIR/node-v${NODE_VERSION}-darwin-${NODE_ARCH}"
if [ ! -f "$SRC_DIR/bin/node" ]; then
  echo "Binário node não encontrado no pacote extraído"; exit 1
fi

DEST="$APP_PATH/Contents/Resources"
mkdir -p "$DEST"
cp "$SRC_DIR/bin/node" "$DEST/node"
chmod +x "$DEST/node"

# Substitui o start-server.sh para priorizar o node embutido
START="$APP_PATH/Contents/MacOS/start-server.sh"
if [ -f "$START" ]; then
  cat > "$START" <<'EOF'
#!/usr/bin/env bash
SCRIPT_DIR="$(dirname "$0")/../Resources"
cd "$SCRIPT_DIR"
if [ -x "$SCRIPT_DIR/node" ]; then
  exec "$SCRIPT_DIR/node" server.js
elif command -v node >/dev/null 2>&1; then
  exec node server.js
else
  echo "Node não encontrado. Instale Node ou embuta-o no app usando embed_node.sh"
  sleep 5
  exit 1
fi
EOF
  chmod +x "$START"
fi

echo "Node v$NODE_VERSION embutido em $APP_PATH/Contents/Resources/node"
exit 0

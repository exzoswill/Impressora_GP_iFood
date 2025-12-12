#!/usr/bin/env bash
# Gera um app bundle macOS mínimo para rodar o servidor Node localmente.
# Uso (no macOS):
#   ./create_app.sh /caminho/para/repo /destino/onde/colocar/ImpressoraGPiFood.app

set -euo pipefail

SRC_DIR="${1:-$(pwd)}"
OUT_APP="${2:-${PWD}/ImpressoraGPiFood.app}"

echo "Criando app em: $OUT_APP"

CONTENTS="$OUT_APP/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

mkdir -p "$MACOS" "$RESOURCES"

# Copia arquivos necessários do projeto
cp -R "$SRC_DIR/server.js" "$RESOURCES/" || true
cp -R "$SRC_DIR/ws_server.js" "$RESOURCES/" || true
cp -R "$SRC_DIR/package.json" "$RESOURCES/" || true
cp -R "$SRC_DIR/static" "$RESOURCES/" || true

# Start script que será executado pelo bundle
cat > "$MACOS/start-server.sh" <<'EOF'
#!/usr/bin/env bash
# Caminho relativo aos Resources
SCRIPT_DIR="$(dirname "$0")/../Resources"
cd "$SCRIPT_DIR"

# Prefer system node; se usar nvm, o usuário deve configurar previamente
if command -v node >/dev/null 2>&1; then
  exec node server.js
else
  echo "Node não encontrado. Instale o Node (recomendado via nvm com v12) e abra o app novamente."
  sleep 5
  exit 1
fi
EOF

chmod +x "$MACOS/start-server.sh"

# Info.plist
if [ -f "$SRC_DIR/utils/macos/Info.plist.template" ]; then
  sed "s|__APP_NAME__|ImpressoraGPiFood|g" "$SRC_DIR/utils/macos/Info.plist.template" > "$CONTENTS/Info.plist"
else
  cat > "$CONTENTS/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>ImpressoraGPiFood</string>
  <key>CFBundleIdentifier</key>
  <string>br.ifood.ImpressoraGPiFood</string>
  <key>CFBundleVersion</key>
  <string>1.0</string>
  <key>CFBundleExecutable</key>
  <string>start-server.sh</string>
  <key>LSBackgroundOnly</key>
  <true/>
</dict>
</plist>
EOF
fi

echo "App criado em $OUT_APP. Para testar, abra no Finder e execute, ou rode:$OUT_APP/Contents/MacOS/start-server.sh"

echo "Observação: este bundle não inclui o binário Node. Instale Node (recomendado via nvm) antes de usar."

exit 0

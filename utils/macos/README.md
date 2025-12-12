# macOS: Gerar um .app mínimo para o Impressora_GP_iFood

Este diretório contém scripts e templates para criar um app macOS mínimo que inicia o servidor local do projeto.

Observações importantes:
- O bundle gerado NÃO inclui o binário `node`. É necessário ter o Node instalado no sistema (recomendado via `nvm` com Node v12 conforme README principal).
- A app é criada como background-only (sem interface gráfica) e executa `server.js` do diretório `Resources`.

Passos (no macOS):

1. Abra o Terminal e execute:

```bash
cd /caminho/para/Impressora_GP_iFood
chmod +x utils/macos/create_app.sh
./utils/macos/create_app.sh "$(pwd)" "$HOME/Applications/ImpressoraGPiFood.app"
```

2. Teste a execução manualmente:

```bash
# Inicie o servidor diretamente
"$HOME/Applications/ImpressoraGPiFood.app/Contents/MacOS/start-server.sh"

# Ou abra a app pelo Finder
open "$HOME/Applications/ImpressoraGPiFood.app"
```

3. Notas sobre empacotamento final e distribuição:
- Para criar um instalador `.dmg` ou assinar/notarizar a app para distribuição a usuários, use ferramentas macOS como `hdiutil`, `productbuild` e `codesign`.
- Se desejar incluir o binário do Node dentro do bundle, copie o binário `node` para `Contents/Resources/` e ajuste `start-server.sh` para usar esse binário embutido.

Exemplo simples para usar node embutido (opcional):

```bash
# cp /usr/local/bin/node "$OUT_APP/Contents/Resources/node"
# editar start-server.sh para usar "$(dirname \"$0\")/../Resources/node server.js"
```

4. Embutir Node automaticamente

Existe um script `embed_node.sh` que baixa um binário Node.js para macOS (x64/arm64) e o coloca dentro do bundle:

```bash
# Após criar o app com create_app.sh
chmod +x utils/macos/embed_node.sh
./utils/macos/embed_node.sh "$HOME/Applications/ImpressoraGPiFood.app" 12.22.12
```

O script também atualiza o `start-server.sh` do bundle para priorizar o `node` embutido.

Build local do DMG

Para criar um `.dmg` a partir do `.app` localmente no macOS:

```bash
chmod +x utils/macos/create_dmg.sh
./utils/macos/create_dmg.sh "$HOME/Applications/ImpressoraGPiFood.app" "$HOME/Desktop/ImpressoraGPiFood.dmg"
```

Ver [BUILD_DMG_LOCAL.md](BUILD_DMG_LOCAL.md) para instruções detalhadas (codesign, notarização com `altool` ou `notarytool`, etc).

CI/CD (GitHub Actions)

O workflow `.github/workflows/release-macos.yml` automatiza:
1. Criação do `.app`.
2. Embutir Node.
3. Codesign (se `P12_BASE64` + `P12_PASSWORD` forem fornecidos).
4. Criação do DMG.
5. Notarização com `notarytool` (se `APPLE_NOTARYTOOL_KEYID`, `APPLE_NOTARYTOOL_ISSUEID` e `APPLE_NOTARYTOOL_KEY` forem fornecidos).

Secrets necessários (no repositório GitHub):
- `P12_BASE64` e `P12_PASSWORD` (para codesign; opcionais).
- `APPLE_NOTARYTOOL_KEYID`, `APPLE_NOTARYTOOL_ISSUEID`, `APPLE_NOTARYTOOL_KEY` (para notarização com notarytool; recomendado).
- Opcional: `NODE_VERSION` (ex.: `12.22.12`).

Para executar manualmente:
1. Configure os secrets (Settings → Secrets and variables → Actions).
2. Vá em Actions → Build and Release macOS → Run workflow → selecione branch `macos-from-clean` ou `macos-bundle` e clique em Run workflow.

Existe um script `embed_node.sh` que baixa um binário Node.js para macOS (x64/arm64) e o coloca dentro do bundle:

```bash
# Após criar o app com create_app.sh
chmod +x utils/macos/embed_node.sh
./utils/macos/embed_node.sh "$HOME/Applications/ImpressoraGPiFood.app" 12.22.12
```

O script também atualiza o `start-server.sh` do bundle para priorizar o `node` embutido.

Se quiser, eu posso gerar um script opcional que baixa um binário Node compatível e o coloca dentro do bundle (requer decisão sobre a versão alvo e arquitetura).

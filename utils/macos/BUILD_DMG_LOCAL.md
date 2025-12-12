# Como criar o DMG localmente (macOS)

Este guia detalha como criar um `.app` bundle, embutir Node, assinar e criar um `.dmg` no seu Mac local.

Requisitos
- macOS 10.13+
- Xcode Command Line Tools instalados (`xcode-select --install`)
- Node v12 instalado via `nvm` ou outro método
- Certificado Developer ID Application (se quiser codesign/notarizar)

Passos rápidos (sem codesign/notarização)

1. Clone ou navegue até o repositório:

```bash
cd /path/to/Impressora_GP_iFood
```

2. Torne os scripts executáveis:

```bash
chmod +x utils/macos/create_app.sh utils/macos/embed_node.sh utils/macos/create_dmg.sh
```

3. Crie o app bundle:

```bash
./utils/macos/create_app.sh "$(pwd)" "$HOME/Desktop/ImpressoraGPiFood.app"
```

Saída esperada: `App criado em /Users/seu_usuario/Desktop/ImpressoraGPiFood.app`

4. Embuta o Node:

```bash
./utils/macos/embed_node.sh "$HOME/Desktop/ImpressoraGPiFood.app" 12.22.12
```

Saída esperada: `Node v12.22.12 embutido em /Users/seu_usuario/Desktop/ImpressoraGPiFood.app/Contents/Resources/node`

5. Teste a app (opcional):

```bash
# Executar servidor manualmente
"$HOME/Desktop/ImpressoraGPiFood.app/Contents/MacOS/start-server.sh"

# Ou abrir no Finder
open "$HOME/Desktop/ImpressoraGPiFood.app"
```

6. Crie o DMG:

```bash
./utils/macos/create_dmg.sh "$HOME/Desktop/ImpressoraGPiFood.app" "$HOME/Desktop/ImpressoraGPiFood.dmg"
```

Saída esperada: `DMG criado em /Users/seu_usuario/Desktop/ImpressoraGPiFood.dmg`

7. O arquivo `ImpressoraGPiFood.dmg` está pronto para enviar ao release!

Passos com codesign (assinatura)

Se quiser assinar o app antes de criar o DMG:

```bash
# Substituir "Developer ID Application: Your Name (TEAMID)" pelo seu identificador real
codesign --deep --force --verbose --sign "Developer ID Application: Your Name (TEAMID)" "$HOME/Desktop/ImpressoraGPiFood.app"

# Verificar assinatura
codesign --verify --deep --strict --verbose=2 "$HOME/Desktop/ImpressoraGPiFood.app"

# Prosseguir com criação de DMG
./utils/macos/create_dmg.sh "$HOME/Desktop/ImpressoraGPiFood.app" "$HOME/Desktop/ImpressoraGPiFood.dmg"
```

Passos com notarização (altool — método antigo)

```bash
# Criar DMG conforme acima

# Submeter para notarização via altool
xcrun altool --notarize-app -u "seu@email.com" -p "app-senha" \
  --primary-bundle-id "br.ifood.ImpressoraGPiFood" \
  -f "$HOME/Desktop/ImpressoraGPiFood.dmg"

# Você verá um UUID; use-o para verificar o status
xcrun altool --notarization-info <UUID> -u "seu@email.com" -p "app-senha"

# Após aprovação, fixe a aprovação no DMG
xcrun stapler staple "$HOME/Desktop/ImpressoraGPiFood.dmg"
```

Passos com notarização (notarytool — método moderno, recomendado)

Requer um API key do App Store Connect:
1. Vá em https://appstoreconnect.apple.com/ → Users and Access → Keys → App Store Connect API.
2. Crie uma nova chave com permissão "Developer" e baixe o arquivo `.p8`.
3. Guarde os valores: Key ID, Issuer ID e o conteúdo da chave `.p8`.

Depois use:

```bash
# Salvar a chave de forma segura (temporariamente)
cat > /tmp/notarytool.p8 <<'KEYEOF'
# Colar aqui o conteúdo da chave baixada do App Store Connect
KEYEOF

# Submeter para notarização (wait = esperar conclusão)
xcrun notarytool submit "$HOME/Desktop/ImpressoraGPiFood.dmg" \
  --key-id "XXX_YOUR_KEY_ID_XXX" \
  --issuer-id "XXX_YOUR_ISSUER_ID_XXX" \
  --key /tmp/notarytool.p8 \
  --wait

# Se bem-sucedido, a saída dirá "Ready for distribution"
# Fixe a aprovação no DMG
xcrun stapler staple "$HOME/Desktop/ImpressoraGPiFood.dmg"

# Limpe a chave temporária
rm /tmp/notarytool.p8
```

Resumo dos arquivos gerados

Após seguir os passos acima, você terá:
- `$HOME/Desktop/ImpressoraGPiFood.app` — bundle executável.
- `$HOME/Desktop/ImpressoraGPiFood.dmg` — imagem de disco (pronto para distribuição).

Próximos passos

1. Enviar o DMG manualmente:
   - Vá em https://github.com/exzoswill/Impressora_GP_iFood/releases/tag/v0.1-macos
   - Clique em "Edit" no draft release.
   - Arraste/selecione o arquivo `ImpressoraGPiFood.dmg`.
   - Salve as mudanças.

2. Publicar o release (quando pronto).

3. Alternativa: configurar os `secrets` do GitHub e deixar o workflow CI fazer tudo automaticamente na próxima execução.

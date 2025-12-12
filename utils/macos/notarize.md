# Codesign e Notarização (instruções)

Este documento descreve como preparar e automatizar a assinatura (`codesign`) e notarização (`notarize`) do aplicativo macOS.

Requisitos
- Conta Apple Developer ativa.
- Certificado de Developer ID Application exportado como `.p12` (incluindo chave privada).
- Senha de app específico da Apple para `altool` (ou usar `notarytool` com API key).

Gerar arquivo P12
1. No macOS com Xcode instalado, abra o Keychain Access.
2. Exportar o certificado Developer ID Application e a chave privada como `cert.p12`.

GitHub Actions (requisitos de secrets)
- `P12_BASE64`: conteúdo base64 do `cert.p12` (use `base64 cert.p12 | pbcopy`).
- `P12_PASSWORD`: senha do arquivo p12 (se houver).
- `APPLE_ID`: seu Apple ID (email).
- `APP_SPECIFIC_PASSWORD`: senha de app específica (ou use notarytool com chave API).

Passos locais (macOS)
1. Importar o p12 para um keychain temporário:

```bash
security create-keychain -p mypw ci-build.keychain
security import cert.p12 -k ci-build.keychain -P "p12password" -T /usr/bin/codesign
security unlock-keychain -p mypw ci-build.keychain
security list-keychains -s ci-build.keychain
```

2. Assinar o app:

```bash
codesign --deep --force --verbose --sign "Developer ID Application: Your Name (TEAMID)" /path/to/ImpressoraGPiFood.app
```

3. Verificar assinatura:

```bash
codesign --verify --deep --strict --verbose=2 /path/to/ImpressoraGPiFood.app
spctl -a -t exec -v /path/to/ImpressoraGPiFood.app
```

4. Criar DMG (use `utils/macos/create_dmg.sh`).

5. Notarizar usando `altool` (alternativa `notarytool` está disponível nas versões mais recentes):

```bash
xcrun altool --notarize-app -u "APPLE_ID" -p "APP_SPECIFIC_PASSWORD" --primary-bundle-id "br.ifood.ImpressoraGPiFood" -f /path/to/ImpressoraGPiFood.dmg
```

6. Verificar status e baixar UUID de notarização para esperar a conclusão:

```bash
xcrun altool --notarization-info <REQUEST_UUID> -u "APPLE_ID" -p "APP_SPECIFIC_PASSWORD"
```

7. Depois de aprovado, use `stapler` para fixar a aprovação no pacote:

```bash
xcrun stapler staple /path/to/ImpressoraGPiFood.dmg
```

Observações
- Notarização e codesign exigem um ambiente macOS com Xcode command line tools.
- Para automação no GitHub Actions, o workflow `.github/workflows/release-macos.yml` inclui passos para importar o p12 e rodar a notarização via `altool`. Configure os `secrets` citados antes de rodar.

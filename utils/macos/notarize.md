# Codesign e Notarização (instruções)

Este documento descreve como preparar e automatizar a assinatura (`codesign`) e notarização do aplicativo macOS.

**Recomendação:** use `notarytool` (moderno) em vez de `altool` (descontinuado).

## Requisitos

- Conta Apple Developer ativa.
- Certificado de Developer ID Application exportado como `.p12` (para codesign; opcional).
- API key do App Store Connect (para `notarytool`; recomendado).

## Obter App Store Connect API key (notarytool — recomendado)

1. Acesse https://appstoreconnect.apple.com/ → Users and Access → Keys.
2. Clique em "+" para criar uma nova App Store Connect API key.
3. Preenchimento obrigatório:
   - Name: ex. "GitHub Actions Notarization"
   - Access: "Developer"
4. Clique em Create.
5. Na próxima tela, copie/guarde:
   - **Key ID** (ex. `ABC123DEF`)
   - **Issuer ID** (ex. `12345678-1234-1234-1234-123456789abc`)
6. Download do arquivo `.p8` (guarde-o seguro, é a chave privada).
7. Configure os secrets no GitHub com esses valores (veja seção GitHub Actions abaixo).

## Gerar arquivo P12 (para codesign — opcional)

Se quiser assinar o app:
1. No macOS com Xcode instalado, abra o Keychain Access.
2. Exporte o certificado Developer ID Application e a chave privada como `cert.p12`.

## GitHub Actions (requisitos de secrets)

Configure os seguintes secrets no repositório (Settings → Secrets and variables → Actions):

**Para notarytool (recomendado):**
- `APPLE_NOTARYTOOL_KEYID`: Key ID da API key.
- `APPLE_NOTARYTOOL_ISSUEID`: Issuer ID.
- `APPLE_NOTARYTOOL_KEY`: conteúdo do arquivo `.p8` (base64 ou texto simples).

**Para codesign (opcional):**
- `P12_BASE64`: conteúdo base64 do `cert.p12` (use `base64 cert.p12 | pbcopy`).
- `P12_PASSWORD`: senha do arquivo p12 (se houver).

## Passos locais (macOS)

### notarytool (recomendado)

1. **Preparar a chave .p8:**

```bash
# Salve em um local seguro (ex. ~/.notary_key.p8)
cat > ~/.notary_key.p8 <<'KEYEOF'
# Colar aqui o conteúdo da chave .p8 baixada do App Store Connect
KEYEOF
chmod 600 ~/.notary_key.p8
```

2. **Assinar o app (opcional, se tiver certificado):**

```bash
ID=$(security find-identity -v -p codesigning | awk '/"/ {print $2; exit}' | tr -d '"')
codesign --deep --force --verbose --sign "$ID" /path/to/ImpressoraGPiFood.app

# Verificar assinatura
codesign --verify --deep --strict --verbose=2 /path/to/ImpressoraGPiFood.app
```

3. **Criar DMG:**

```bash
./utils/macos/create_dmg.sh /path/to/ImpressoraGPiFood.app /path/to/ImpressoraGPiFood.dmg
```

4. **Notarizar com notarytool:**

```bash
xcrun notarytool submit /path/to/ImpressoraGPiFood.dmg \
  --key-id "ABC123DEF" \
  --issuer-id "12345678-1234-1234-1234-123456789abc" \
  --key ~/.notary_key.p8 \
  --wait
```

Saída esperada: `The notarization request completed successfully`

5. **Fixar a aprovação (staple):**

```bash
xcrun stapler staple /path/to/ImpressoraGPiFood.dmg
```

Agora o DMG está pronto para distribuição!

### altool (legado, não recomendado)

Se preferir usar `altool` (descontinuado):

```bash
# Submeter para notarização
xcrun altool --notarize-app -u "seu@email.com" -p "app-senha" \
  --primary-bundle-id "br.ifood.ImpressoraGPiFood" \
  -f /path/to/ImpressoraGPiFood.dmg

# Verá um UUID; use-o para verificar o status
xcrun altool --notarization-info <UUID> -u "seu@email.com" -p "app-senha"

# Após aprovação, fixe a aprovação
xcrun stapler staple /path/to/ImpressoraGPiFood.dmg
```

## Observações

- Notarização e codesign exigem um ambiente macOS com Xcode command line tools.
- **Recomendado:** usar `notarytool` com API key (mais seguro, mais moderno, sem expiração de senha).
- O workflow `.github/workflows/release-macos.yml` está configurado para usar `notarytool`.
- Para instruções locais passo-a-passo, veja também [BUILD_DMG_LOCAL.md](BUILD_DMG_LOCAL.md).

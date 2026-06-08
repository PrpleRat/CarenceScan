#!/usr/bin/env bash
# Installe le certificat Distribution depuis les secrets (réutilisé, pas de nouveau cert).
set -euo pipefail

SCRIPT_DIR="${GITHUB_WORKSPACE:?GITHUB_WORKSPACE requis}/ci"
# shellcheck source=check-signing-secrets.sh
bash "$SCRIPT_DIR/check-signing-secrets.sh"

KEYCHAIN_PATH="${RUNNER_TEMP:-/tmp}/carencescan-ci-${GITHUB_RUN_ID:-local}.keychain-db"
CERT_PATH="${RUNNER_TEMP:-/tmp}/distribution.p12"

decode_base64_to_file() {
  local b64="$1"
  local out="$2"
  # Retire espaces / retours ligne (copier-coller secret GitHub).
  local cleaned
  cleaned="$(printf '%s' "$b64" | tr -d '[:space:]')"
  if [ -z "$cleaned" ]; then
    echo "::error::Secret base64 vide après nettoyage"
    exit 1
  fi
  # macOS : base64 -D  |  Linux : base64 -d
  if printf '%s' "$cleaned" | base64 -D > "$out" 2>/dev/null; then
    return 0
  fi
  printf '%s' "$cleaned" | base64 -d > "$out"
}

echo "=== Trousseau CI + certificat Distribution (depuis secrets) ==="
security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"

WWDR="${RUNNER_TEMP:-/tmp}/AppleWWDRCAG3.cer"
curl -fsSL -o "$WWDR" "https://www.apple.com/certificateauthority/AppleWWDRCAG3.cer"
security import "$WWDR" -k "$KEYCHAIN_PATH" -T /usr/bin/codesign -T /usr/bin/security -A

decode_base64_to_file "$IOS_DISTRIBUTION_CERTIFICATE_BASE64" "$CERT_PATH"
if [ ! -s "$CERT_PATH" ]; then
  echo "::error::Décodage p12 échoué — vérifie IOS_DISTRIBUTION_CERTIFICATE_BASE64 (fichier .txt du bootstrap)"
  exit 1
fi

security import "$CERT_PATH" \
  -P "$IOS_DISTRIBUTION_CERTIFICATE_PASSWORD" \
  -A -T /usr/bin/codesign -T /usr/bin/security \
  -t cert -f pkcs12 -k "$KEYCHAIN_PATH"

# shellcheck source=keychain-unlock.sh
source "$SCRIPT_DIR/keychain-unlock.sh"
security list-keychains -d user -s "$KEYCHAIN_PATH"

if ! security find-identity -v -p codesigning "$KEYCHAIN_PATH" | grep -q "Apple Distribution"; then
  echo "::error::Import p12 échoué — mot de passe incorrect ou certificat révoqué"
  echo "Vérifie IOS_DISTRIBUTION_CERTIFICATE_PASSWORD (fichier IOS_DISTRIBUTION_CERTIFICATE_PASSWORD.txt du bootstrap)"
  security find-identity -v -p codesigning "$KEYCHAIN_PATH" || true
  exit 1
fi

if [ -n "${GITHUB_ENV:-}" ]; then
  echo "KEYCHAIN_PATH=$KEYCHAIN_PATH" >> "$GITHUB_ENV"
fi

echo "Certificat Distribution installé (réutilisé)."

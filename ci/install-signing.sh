#!/usr/bin/env bash
# Installe le certificat Distribution depuis les secrets (réutilisé, pas de nouveau cert).
set -euo pipefail

bash "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/check-signing-secrets.sh"

KEYCHAIN_PATH="${RUNNER_TEMP:-/tmp}/carencescan-ci-${GITHUB_RUN_ID:-local}.keychain-db"
CERT_PATH="${RUNNER_TEMP:-/tmp}/distribution.p12"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"

WWDR="${RUNNER_TEMP:-/tmp}/AppleWWDRCAG3.cer"
curl -fsSL -o "$WWDR" "https://www.apple.com/certificateauthority/AppleWWDRCAG3.cer"
security import "$WWDR" -k "$KEYCHAIN_PATH" -T /usr/bin/codesign -T /usr/bin/security -A

echo -n "$IOS_DISTRIBUTION_CERTIFICATE_BASE64" | base64 --decode > "$CERT_PATH"
security import "$CERT_PATH" \
  -P "$IOS_DISTRIBUTION_CERTIFICATE_PASSWORD" \
  -A -T /usr/bin/codesign -T /usr/bin/security \
  -t cert -f pkcs12 -k "$KEYCHAIN_PATH"

# shellcheck source=keychain-unlock.sh
source "$SCRIPT_DIR/keychain-unlock.sh"
security list-keychains -d user -s "$KEYCHAIN_PATH"

if ! security find-identity -v -p codesigning "$KEYCHAIN_PATH" | grep -q "Apple Distribution"; then
  echo "::error::Import p12 échoué — certificat révoqué ou secrets incorrects"
  exit 1
fi

if [ -n "${GITHUB_ENV:-}" ]; then
  echo "KEYCHAIN_PATH=$KEYCHAIN_PATH" >> "$GITHUB_ENV"
fi

echo "Certificat Distribution installé (réutilisé)."

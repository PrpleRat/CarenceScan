#!/usr/bin/env bash
set -euo pipefail

PROVISION_PATH="${1:?chemin .mobileprovision requis}"
: "${KEYCHAIN_PATH:?KEYCHAIN_PATH requis}"

PLIST="${PROVISION_PATH}.verify.plist"
security cms -D -i "$PROVISION_PATH" > "$PLIST"

CERT_LINE=$(security find-identity -v -p codesigning "$KEYCHAIN_PATH" 2>/dev/null | grep "Apple Distribution" | head -1 || true)
CERT_HASH=$(echo "$CERT_LINE" | sed -n 's/^[[:space:]]*[0-9]*) \([A-F0-9]*\).*/\1/p')

if [ -z "$CERT_HASH" ]; then
  echo "::error::Aucune identité Apple Distribution dans le trousseau CI"
  exit 1
fi

echo "Profil OK — cert CI $CERT_HASH"

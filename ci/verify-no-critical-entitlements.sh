#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if grep -q "CODE_SIGN_ENTITLEMENTS" project.yml 2>/dev/null; then
  echo "::error::Retire CODE_SIGN_ENTITLEMENTS de project.yml"
  exit 1
fi

echo "OK — pas d'entitlements spéciaux requis."

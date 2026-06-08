#!/usr/bin/env bash
# DÉPRÉCIÉ pour TestFlight CI — recréait un certificat à chaque run.
# Utiliser install_signing.py + refresh-profiles-api.sh (workflow TestFlight).
set -euo pipefail
: "${ASC_KEY_ID:?}"
: "${ASC_ISSUER_ID:?}"
: "${ASC_PRIVATE_KEY:?}"

REPO_ROOT="${GITHUB_WORKSPACE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
KEYCHAIN_PATH="${RUNNER_TEMP:-/tmp}/ci-signing-api.keychain-db"
KEYCHAIN_PASSWORD="${KEYCHAIN_PASSWORD:-$(openssl rand -hex 16)}"
CERTS_PATH="${RUNNER_TEMP:-/tmp}/certs-api"
PROFILES_PATH="${RUNNER_TEMP:-/tmp}/profiles-api"
FASTLANE_LOG="${RUNNER_TEMP:-/tmp}/fastlane-ci-signing.log"

export KEYCHAIN_PATH KEYCHAIN_PASSWORD CERTS_PATH PROFILES_PATH
export FASTLANE_OPT_OUT_USAGE=YES FASTLANE_SKIP_UPDATE_CHECK=YES FASTLANE_DISABLE_ANIMATION=YES

security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security list-keychains -d user -s "$KEYCHAIN_PATH" $(security list-keychains -d user | sed 's/^[[:space:]]*"\(.*\)";/\1/')

WWDR="${RUNNER_TEMP:-/tmp}/AppleWWDRCAG3.cer"
curl -fsSL -o "$WWDR" "https://www.apple.com/certificateauthority/AppleWWDRCAG3.cer"
security import "$WWDR" -k "$KEYCHAIN_PATH" -T /usr/bin/codesign -T /usr/bin/security -A

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
brew list fastlane >/dev/null 2>&1 || brew install fastlane
FASTLANE_BIN="$(command -v fastlane)"

run_fastlane() {
  set +e
  (cd "$REPO_ROOT" && export CI=true FORCE_NEW_CERT="$1" && "$FASTLANE_BIN" ios ci_signing --verbose) 2>&1 | tee "$FASTLANE_LOG"
  return "${PIPESTATUS[0]}"
}

run_fastlane "0" || run_fastlane "1" || { tail -80 "$FASTLANE_LOG"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=profile-utils.sh
source "$SCRIPT_DIR/profile-utils.sh"

APP_PROV="${PROFILES_PATH}/app.mobileprovision"
test -f "$APP_PROV" || (echo "::error::Profil non généré" && exit 1)
profile_verify_bundle_id "$APP_PROV" >/dev/null
bash "$SCRIPT_DIR/verify-profile-cert.sh" "$APP_PROV"

APP_UUID=$(profile_install_uuid_only "$APP_PROV")
write_release_xcconfig "$APP_UUID"

if [ -n "${GITHUB_ENV:-}" ]; then
  echo "KEYCHAIN_PATH=$KEYCHAIN_PATH" >> "$GITHUB_ENV"
  echo "IOS_APP_PROFILE_UUID=$APP_UUID" >> "$GITHUB_ENV"
fi

echo "Signing API OK — profil $APP_UUID"

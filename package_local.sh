#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="${PROJECT_DIR}/artifacts"
APP_DIR="${OUTPUT_DIR}/Cawernda.app"
ASSET_TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "${ASSET_TEMP_DIR}"' EXIT

if [ -e "${APP_DIR}" ]; then
  echo "Local app already exists: ${APP_DIR}" >&2
  exit 1
fi

swift build -c release --product Cawernda
BIN_DIR="$(swift build -c release --product Cawernda --show-bin-path)"

mkdir -p "${APP_DIR}/Contents/MacOS" "${APP_DIR}/Contents/Resources"
cp "${BIN_DIR}/Cawernda" "${APP_DIR}/Contents/MacOS/Cawernda"
cp "${PROJECT_DIR}/LocalInfo.plist" "${APP_DIR}/Contents/Info.plist"
cp "${PROJECT_DIR}/THIRD_PARTY_NOTICES.md" "${APP_DIR}/Contents/Resources/THIRD_PARTY_NOTICES.md"
mkdir -p "${APP_DIR}/Contents/Resources/sounds"
cp -X "${PROJECT_DIR}"/sounds/*.mp3 "${APP_DIR}/Contents/Resources/sounds/"
xcrun actool "${PROJECT_DIR}/Assets.xcassets" \
  --compile "${APP_DIR}/Contents/Resources" \
  --platform macosx \
  --minimum-deployment-target 15.0 \
  --app-icon AppIcon \
  --output-partial-info-plist "${ASSET_TEMP_DIR}/asset-info.plist" >/dev/null
chmod +x "${APP_DIR}/Contents/MacOS/Cawernda"

codesign \
  --force \
  --deep \
  --sign - \
  --entitlements "${PROJECT_DIR}/Cawernda.entitlements" \
  "${APP_DIR}"

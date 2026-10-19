#!/bin/bash
set -euo pipefail

TAG="${1:-}"
if [[ ! "${TAG}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+-preview\.[0-9]+$ ]]; then
  echo "Expected a tag such as v0.1.1-preview.1" >&2
  exit 1
fi

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="${PROJECT_DIR}/artifacts/preview"
STAGE_DIR="$(mktemp -d)"
APP_DIR="${STAGE_DIR}/Cawenda.app"
VERSION="${TAG#v}"
BUNDLE_VERSION="${VERSION%%-preview.*}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
ARCHIVE_NAME="Cawenda-${VERSION}-macOS-Intel.zip"

cleanup() {
  rm -rf "${STAGE_DIR}"
}
trap cleanup EXIT

cd "${PROJECT_DIR}"
mkdir -p "${OUTPUT_DIR}"
rm -f "${OUTPUT_DIR}/${ARCHIVE_NAME}" "${OUTPUT_DIR}/${ARCHIVE_NAME}.sha256"

swift build -c release --product Cawenda
BIN_DIR="$(swift build -c release --product Cawenda --show-bin-path)"

mkdir -p "${APP_DIR}/Contents/MacOS" "${APP_DIR}/Contents/Resources/sounds"
cp "${BIN_DIR}/Cawenda" "${APP_DIR}/Contents/MacOS/Cawenda"
cp LocalInfo.plist "${APP_DIR}/Contents/Info.plist"
cp LICENSE THIRD_PARTY_NOTICES.md PREVIEW_RELEASE_NOTES.md "${APP_DIR}/Contents/Resources/"

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${BUNDLE_VERSION}" "${APP_DIR}/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${BUILD_NUMBER}" "${APP_DIR}/Contents/Info.plist"

while IFS= read -r -d '' sound_file; do
  cp -X "${sound_file}" "${APP_DIR}/Contents/Resources/sounds/"
done < <(find sounds -maxdepth 1 -type f -iname '*.mp3' -print0)

ASSET_INFO="${STAGE_DIR}/asset-info.plist"
xcrun actool Assets.xcassets \
  --compile "${APP_DIR}/Contents/Resources" \
  --platform macosx \
  --minimum-deployment-target 15.0 \
  --app-icon AppIcon \
  --output-partial-info-plist "${ASSET_INFO}" >/dev/null

chmod +x "${APP_DIR}/Contents/MacOS/Cawenda"
codesign \
  --force \
  --deep \
  --options runtime \
  --sign - \
  --entitlements Cawenda.entitlements \
  "${APP_DIR}"
codesign --verify --deep --strict "${APP_DIR}"

ARCHS="$(lipo -archs "${APP_DIR}/Contents/MacOS/Cawenda")"
if [[ " ${ARCHS} " != *" x86_64 "* ]]; then
  echo "Preview archive does not contain an Intel x86_64 executable." >&2
  exit 1
fi

ditto -c -k --sequesterRsrc --keepParent "${APP_DIR}" "${OUTPUT_DIR}/${ARCHIVE_NAME}"
(
  cd "${OUTPUT_DIR}"
  shasum -a 256 "${ARCHIVE_NAME}" > "${ARCHIVE_NAME}.sha256"
)

echo "${OUTPUT_DIR}/${ARCHIVE_NAME}"

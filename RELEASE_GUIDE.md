# Cawenda Release Guide

## Public preview without Apple Developer membership

Preview tags matching `v*-preview.*` trigger `.github/workflows/preview-release.yml`. The workflow runs tests on a fresh Intel macOS runner, creates an ad-hoc-signed ZIP, publishes a SHA-256 checksum and build attestation, and creates the GitHub Release.

Example tag:

```bash
git tag v0.1.1-preview.1
git push origin v0.1.1-preview.1
```

Do not create or push a preview tag until the release notes, public warning, source state, and website link have been reviewed. Preview builds are not Apple-notarized and must never be described as notarized or fully trusted by Gatekeeper.

## Developer ID release

Use `package_local.sh` for an ad-hoc signed local build. Use `build_dmg.sh` only when producing signed release archives for distribution.

## 1. Configure the release

Copy `.env.example` to `.env`, then set `VERSION`, `BUILD_NUMBER`, the Apple developer identity, and the notarization profile.

## 2. Verify the source

```bash
swift test
bash package_local.sh
open artifacts/Cawenda.app
```

## 3. Build the release archives

```bash
bash build_dmg.sh
```

This creates signed DMG and ZIP archives for Apple Silicon and Intel. Notarization runs when the configured keychain profile is available. Verify the archives on their matching architectures before publishing.

## 4. Tag and publish

After committing the verified release, tag it and create a GitHub release. For version `0.1.0`:

```bash
git tag v0.1.0
git push origin v0.1.0
```

```bash
gh release create v0.1.0 \
  --title "Cawenda v0.1.0" \
  --notes "Release notes" \
  Cawenda_Silicon.dmg Cawenda_Silicon.zip \
  Cawenda_Intel.dmg Cawenda_Intel.zip
```

# Cawernda Release Guide

Use `package_local.sh` for an ad-hoc signed local build. Use `build_dmg.sh` only when producing signed release archives for distribution.

## 1. Configure the release

Copy `.env.example` to `.env`, then set `VERSION`, `BUILD_NUMBER`, the Apple developer identity, and the notarization profile.

## 2. Verify the source

```bash
swift test
bash package_local.sh
open artifacts/Cawernda.app
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
  --title "Cawernda v0.1.0" \
  --notes "Release notes" \
  Cawernda_Silicon.dmg Cawernda_Silicon.zip \
  Cawernda_Intel.dmg Cawernda_Intel.zip
```

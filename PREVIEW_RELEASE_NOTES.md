# Cawenda public preview

Cawenda is a local-first reminder and enforced-break app for macOS.

## Before installing

This is an early public test build for Intel Macs running macOS 15 or later. It is ad-hoc signed and **not Apple-notarized**, so macOS may display a security warning.

Install only if you are comfortable testing software built from this public repository. Do not rely on this preview for safety-critical, medical, emergency, or other high-consequence reminders. Back up important information before testing.

The software is provided **“as is,” without warranty of any kind**, as described in the repository's MIT License.

## Verify the download

The release includes a `.sha256` file. From Terminal, run:

```bash
shasum -a 256 -c Cawenda-*-macOS-Intel.zip.sha256
```

GitHub also publishes a build-provenance attestation for the ZIP generated from the tagged source.

## Install

1. Unzip the archive.
2. Move `Cawenda.app` to Applications.
3. Control-click Cawenda and choose **Open** if macOS displays a warning.

Do not disable Gatekeeper globally.

## Feedback and security

Use GitHub Issues for reproducible bugs and feature feedback. Follow `SECURITY.md` for security reports.

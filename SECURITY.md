# Security policy

## Supported releases

Only the newest GitHub preview release receives security fixes. Preview builds are not Apple-notarized and are intended for voluntary testing.

## Reporting a vulnerability

Do not open a public issue for a vulnerability that could put users or their data at risk.

Use GitHub's private vulnerability reporting feature when it is available for this repository. Include:

- affected version and commit;
- macOS version and processor architecture;
- reproduction steps;
- security impact;
- logs or proof of concept with secrets and personal data removed.

If private reporting is unavailable, open a minimal issue asking the maintainer for a private reporting channel without disclosing exploit details.

## Distribution guarantees

Every automated preview release:

- runs the Swift test suite on a fresh GitHub-hosted Intel macOS runner;
- packages the app from the tagged public source;
- verifies the ad-hoc code signature;
- publishes a SHA-256 checksum;
- publishes GitHub build provenance for the ZIP.

These controls improve transparency and tamper detection. They do not provide Apple Developer ID identity verification or Apple notarization.

# Security and data handling

## Report a vulnerability privately

Use [GitHub private vulnerability reporting](https://github.com/Shr1ramN/Dhara-Mitra_V1/security/advisories/new). Include the affected version or commit, Android version, a reproduction using sample data and the impact. Keep credentials and personal farm records out of reports and issues.

## Local records and releases

- The published APK uses local mode. Farm records and attachments stay in app storage until you export or share them.
- The optional app lock uses Android authentication. Dhara Mitra leaves SQLite databases, ZIP backups and exported reports unencrypted. Store and share those files with care.
- Anyone with the public development signing key can sign an APK. GitHub releases use this key for compatibility with previous test builds. Use the repository's [Releases](https://github.com/Shr1ramN/Dhara-Mitra_V1/releases) and compare the APK's SHA-256 with the release checksum.
- Keep credentials and private signing material out of Git and APKs. Revoke and rotate exposed credentials at their provider.

GitHub secret scanning and push protection cover supported credential patterns. CI scans resolved Dart dependencies for known OSV advisories.

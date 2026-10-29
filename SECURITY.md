# Security and data handling

Dhara Mitra is a development preview. Production hardening, final device acceptance and cloud backup are incomplete. See the [work tracker](https://github.com/Shr1ramN/Dhara-Mitra/issues/20).

## Report a vulnerability

Use GitHub's **Security → Report a vulnerability** option if private vulnerability reporting is enabled for this repository. Otherwise, arrange a private reporting channel with the maintainer through the contact methods on their GitHub profile before sending sensitive details. Do not post credentials, real farm records or an exploitable private-data disclosure in a public issue.

Include the affected commit/build, a minimal synthetic reproduction, impact and relevant platform versions. No response-time or supported-release guarantee is currently published.

## Current protections and limits

- Records and attachments are stored in the app's local storage. Optional device authentication gates access in the UI; it is not SQLite encryption.
- Local ZIP backups contain farm records and attachments and are not encrypted by this app. Treat exported databases, ZIPs and reports as private files.
- The secure-window flag is used while the app lock is enabled; verify behavior on the target Android device.
- Weather refresh sends the configured farm location to Open-Meteo when used. Cloud farm-data backup and automatic market feeds are not currently active.
- The committed `dev-signing.p12` certificate is public and test-only. It provides no production publisher trust. Private production signing remains future work.

Keep API/server keys and private signing material out of source, APKs, logs and issue attachments. If a private credential is exposed, revoke/rotate it at its provider; deleting it from the latest commit alone does not remove it from Git history.

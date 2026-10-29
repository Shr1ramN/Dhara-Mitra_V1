# Contributing

Start with the [README](README.md), [development guide](docs/DEVELOPMENT.md), [plan](docs/PLAN.md) and [remaining-work tracker](https://github.com/Shr1ramN/Dhara-Mitra/issues/20).

## Issues

- Check existing issues before opening one. Include a plan feature ID such as F3.4 when relevant.
- For bugs, describe the steps, expected result, actual result, language, device/Android version and app build or commit.
- Use synthetic examples. Remove worker names/phone numbers, loan details, coordinates, photos and credentials from screenshots and logs.
- New features should explain the farm workflow and offline behavior. Ideas marked unaccepted in the plan need owner agreement before implementation.

## Pull requests

1. Branch from the intended base (`develop` for current development). Use a descriptive branch; Codex changes use `codex/` by default.
2. Keep changes focused and link the relevant issue. Preserve unrelated work.
3. Add a regression test for financial logic, migrations or data-integrity fixes; use appropriate widget checks for form behavior.
4. Update both English and Kannada strings and regenerate committed code when required.
5. Run `flutter analyze`, `flutter test` and an appropriate Android build from `app/`.
6. Explain the concrete behavior changed, validation performed, migration implications and remaining limitations.

CI must pass before merging. Do not disable analyzer findings or tests to make a check green. Do not mark physical-device behavior tested unless it was exercised.

## Data conventions

- Money is integer paise; do not introduce floating-point monetary storage.
- Preserve units and configurable season boundaries.
- Use transactions for linked stock, wage and sale mutations.
- Daily diary wages reuse attendance; piecework is additional. Harvest consistency is tracked in #3.
- Version installed schemas forward with migration tests; never wipe the database as an upgrade fix.
- Keep operations usable offline and preserve cached data on network failure.

## Secrets and licensing

Do not commit private keys, credentials, real database exports or personal records. The existing development signing key is explicitly test-only. Retain the MIT license and bundled font license notices. Read [SECURITY.md](SECURITY.md) before reporting a vulnerability.

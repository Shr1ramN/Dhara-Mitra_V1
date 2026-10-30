# Android delivery

Pull requests to develop and master require repository-owner review, passing Analyze and test and Android build checks, resolved review conversations, and an up-to-date branch. Force pushes and branch deletion are blocked.

The owner is @Shr1ramN (see .github/CODEOWNERS). GitHub does not allow authors to approve their own pull requests; owner approval requires a PR authored by another collaborator or bot identity.

After merging to develop, CI publishes a prerelease. After merging to master, CI publishes a regular release marked Latest. Both deliver DharaMitra.apk, SHA256SUMS and the source commit. PR builds are Actions artifacts and do not publish releases.

The app ID is in.dharamitra.app. CI version codes are 20000 + run number. The existing public development signing certificate remains in use for update compatibility. Regular GitHub release status does not change the signing identity; private production signing is pending and requires a data-preserving migration plan.

Before installing, export a backup. Verify existing records remain accessible after updating. Do not uninstall or clear storage as an update workaround.

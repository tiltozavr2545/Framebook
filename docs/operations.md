# Operations

Maintainer procedures for Google OAuth, Android signing, symbols, CI and
release publication. Local SDK/setup belongs to [development](development.md),
test fixtures to [testing](testing.md#capturing-api-fixtures), and personal API
key registration to the [user guide](api-keys.md).

Android recovery and the Samsung resume investigation are maintained in
[Android troubleshooting](android-troubleshooting.md). Current delivery status
belongs to the [implementation plan](implementation-plan.md).

## Google Cloud: OAuth for Drive

One Google Cloud project per app, set up by the repository owner.

1. Create a project and enable the **Google Drive API**.
2. **OAuth consent screen**: type External, name Framebook, a support email.
   The only scope is `.../auth/drive.appdata` (non-sensitive). Publishing
   needs Branding filled in: the home page
   `https://tiltozavr2545.github.io/Framebook/` and the privacy policy
   `https://tiltozavr2545.github.io/Framebook/privacy.html`, authorized
   domain `tiltozavr2545.github.io`. Both pages are GitHub Pages from the
   `gh-pages` branch; their source is `docs/gh-pages/`, copied over by
   `sync-gh-pages.yml` on main pushes that change `docs/gh-pages/**`.
3. **Credentials → OAuth client ID → Android**: package name
   `com.github.tiltozavr2545.framebook` and the signing key's SHA-1. Several
   clients are needed — one for every key that signs builds:
   - the release keystore (builds for friends);
   - the debug keystore of **every** development machine
     (`~/.android/debug.keystore`; each machine has its own).

   SHA-1: `keytool -list -v -keystore <file> -alias <alias>`.
   A SHA-1 mismatch is the most common cause of `ApiException: 10` on
   sign-in.
4. **Web client** (type "Web application", no origins or redirects) —
   required: google_sign_in 7 signs in on Android through Credential
   Manager, which wants a `serverClientId`. Its client id is in
   `app/lib/data/sync/google_account.dart` (`googleServerClientId`); a client
   id isn't a secret. The client secret isn't used and never goes into the
   repository.

Set up on 2026-10-26: project `framebook-512810`, the Drive API, Branding
with the GitHub Pages home page and privacy policy, the `drive.appdata`
scope, Android clients for the release key and the Intel Mac's debug key,
and the Web client.

### Testing or Production

While the OAuth app is in **Testing** status:

- only accounts from the Test users list (up to 100) can sign in — friends
  have to be added by hand;
- refresh tokens live **7 days**, after which a new sign-in is needed.

The repository's Stage 5 record says this app was moved to **Production**.
This is the recorded setup, not a live check of the Cloud console. For a new
installation of the Google Cloud project, verify the publishing status there;
leaving it in Testing requires maintaining the test-user list and can force
periodic reauthorization. The app never bypasses consent with an automatic
interactive authorization dialog.

## Signing and building

The release key was created on 2026-10-20 and doesn't depend on any one
person:

| Where | What | Why |
| --- | --- | --- |
| GitHub repository secrets | `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` | CI signs releases with them (`release-apk.yml`) |
| `~/.config/framebook/` on the Intel Mac | `framebook-release.jks` + `key.properties` | local backup; GitHub secrets cannot be read back |
| `app/android/key.properties` (gitignored) | a copy of `key.properties` with an absolute path to the key | local `make build-apk` |

The key is RSA 4096, valid for 100 years, alias `framebook`. Keep keystore
passwords in the private locations above, never in repository documentation.

Losing the key means the app can't be updated over the installed one:
friends would have to uninstall the old one, and with it any unsynced data.
Keep an independent encrypted backup of the signing material; GitHub secrets
cannot be exported as a recovery copy.

Signing fingerprints for Android OAuth clients:

| Key | SHA-1 |
| --- | --- |
| release (`framebook`) | `F4:07:7F:14:A1:36:FF:01:70:F1:CB:C6:4A:1A:F4:20:51:4C:0A:FD` |
| debug, Intel Mac | `D0:75:83:3B:53:FB:34:2B:78:97:6E:FD:5D:F3:2B:C4:EE:D0:5B:5B` |
| debug, another machine | take it there: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android` |

Building:

- `make build-apk` → a signed APK built with `--split-debug-info` and
  symbols in `app/build/symbols/<version+build>/`. One
  universal APK, no `--split-per-abi`: one file is simpler for friends than
  choosing an architecture.
- Without `key.properties` a release build **fails** rather than being
  silently signed with the debug key. To check that it compiles there is
  `make build-apk-check`: it explicitly allows debug signing, and CI builds
  the same way.
- To build signed on another machine, copy `~/.config/framebook/` and
  `app/android/key.properties` there (the key path in it is absolute — adjust
  it for that machine).
- `keytool` and `apksigner` use the JDK from Android Studio:
  `/Applications/Android Studio.app/Contents/jbr/Contents/Home`. To check an
  APK's signature: `apksigner verify --print-certs <apk>`.
- `applicationId` is `com.github.tiltozavr2545.framebook`, `minSdk` 26,
  `targetSdk`/`compileSdk` 36.

## Android symbols

Starting with 0.8.4, `make build-apk`, `make build-apk-check`, CI and the release
workflow use `--split-debug-info` without obfuscation. The APK remains universal
and uses the existing signing key. A raw `flutter build apk --release` omits
this setting; use the Makefile targets for comparable builds.

Release assets contain only the installable APK. Matching ARM32, ARM64 and
x86-64 symbols and a README identifying the source commit are retained as
`framebook-<version>-symbols` in the release workflow's Actions artifacts for
90 days. Download them before expiry and keep a durable local backup; they
are required to decode crashes from that exact build. Publication fails if
any ABI's symbols are missing or artifact upload fails. Existing release
symbols are backed up locally under the ignored `.release-symbols/` directory.
Do not run `git clean -x` over that directory without copying the backup.

To decode a saved Dart crash stack from the matching ARM64 release:

```sh
unzip framebook-0.8.4-symbols.zip -d framebook-0.8.4-symbols
flutter symbolize -i crash.txt -d framebook-0.8.4-symbols/app.android-arm64.symbols
```

Use `app.android-arm.symbols` for ARM32 and `app.android-x64.symbols` for x86-64.
Local symbol files are under the ignored `app/build/` tree and can disappear on
`flutter clean`; preserve them before distributing a local APK.

## Android distribution

Publish only when the current request authorizes a release. Prepare a concrete
candidate and complete applicable checks before publication.

1. Update the version/build and [changelog](../CHANGELOG.md), then commit
   the authorized release changes. Version tooling is described in
   [development](development.md); required checks are in [testing](testing.md).
2. Create and push the matching `vX.Y.Z` tag. `release-apk.yml` checks the tag
   against `pubspec.yaml`, runs analysis/tests, builds the signed universal
   `framebook-X.Y.Z.apk`, verifies the release certificate and publishes it.
3. Wait for the workflow to succeed and confirm the APK asset exists. This
   completes the distribution check; downloading the APK solely to repeat
   the workflow's signature check is unnecessary. Symbol retention is
   described in [Android symbols](#android-symbols).
4. Replace generated release notes with English, user-facing notes following
   the established release style: a short introduction, What's new,
   installation/update steps, requirements, signing certificate and attribution.
   Omit future plans and personal-device test reports. Use
   `gh release edit vX.Y.Z --notes-file <file>` for the prepared text.

Users install the APK from the release page, allowing installation from that
source. Updates install over the existing package with the same signing key
and a higher Android `versionCode`. In-app update behavior is specified in
[product behavior](features.md#first-launch-and-sources).

## CI

GitHub Actions on every push/PR: `dart format --set-exit-if-changed`, a check
that generated code is up to date, `flutter analyze`, `flutter test`, a
version bump check on PRs, and an APK build with the debug key. CI uses the
[pinned SDK](development.md#sdk-and-dependencies). CI needs no secrets: tests never
call external APIs. Only `release-apk.yml` uses the signing secrets.

## CI Java and release recovery

CI and release jobs explicitly select Temurin JDK 21 through a pinned
`actions/setup-java` action. Gradle 8.12 supports this runtime; the hosted
runner's default Java 25 is incompatible. The first 0.8.4 release attempt
passed all tests but stopped during Gradle startup for this reason.

To publish an existing tag after fixing workflow infrastructure, dispatch the
current workflow from `main` instead of moving the tag:

```sh
gh workflow run release-apk.yml --ref main -f release_tag=v0.8.4
```

The job checks out the requested tag, checks its pubspec version, reruns tests,
builds with JDK 21, checks the certificate and retains matching symbols in Actions artifacts.
The symbols README records the checked-out commit, not the dispatch commit.
Use this recovery path only when the release has not already been published;
the workflow deliberately does not overwrite existing release assets.

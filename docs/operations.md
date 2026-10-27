# Operations

What to set up and what to press so the app builds, syncs and reaches
friends. There is no server, so operations come down to three things: the
external API keys, the Google OAuth client, and distributing the APK.

**Status: keys, signing and releases are in use since Stages 0–2; the
Google Cloud project for Drive sync since Stage 5 (0.5.0).**

---

## External API keys (every user does this)

Keys are neither in the repository nor in the build: everyone gets their own
and enters them in the app (onboarding or Settings → Sources). The
step-by-step guide for all three services, with what to enter in every form
field, is in [api-keys.md](api-keys.md) (Russian translation:
[api-keys.ru.md](api-keys.ru.md)).

The developer needs their own keys for tests. They never reach the
repository or the test fixtures (fixtures are recorded responses, without
request headers).

### Capturing fixtures

`scripts/capture-fixtures.sh` records live responses of all three APIs into
`app/test/fixtures/`. It takes the keys from a file outside the repository,
`~/.config/framebook/keys.env` (or the path in `FRAMEBOOK_KEYS`):

```sh
TMDB_TOKEN=eyJ...
POISKKINO_KEY=...
OMDB_KEY=...
```

A source without a key is skipped. The script spends 8 of the 200 daily
PoiskKino requests. At the end it checks that no key value ended up in the
saved files. Rerun it when the response format changes or a new request is
added.

---

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
   `sync-gh-pages.yml` on every push to `main` (the same scheme as Amicus).
3. **Credentials → OAuth client ID → Android**: package name
   `com.github.tiltozavr2545.framebook` and the signing key's SHA-1. Several
   clients are needed — one for every key that signs builds:
   - the release keystore (builds for friends);
   - the debug keystore of **every** development machine
     (`~/.android/debug.keystore`; the Intel and M4 Macs have different
     ones).

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

For three people the test user list is no problem, but signing in again
every week is. The plan: move to **Production**. For a non-sensitive scope
that doesn't require Google's app verification, but the consent screen may
show an "app not verified" warning **(to be checked when moving)**. If the
move runs into verification, stay in Testing and make the repeated sign-in
invisible (a silent re-authorization on launch, without losing local data).

---

## Signing and building

The release key was created on 2026-10-20 and doesn't depend on any one
person:

| Where | What | Why |
|---|---|---|
| GitHub repository secrets | `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` | CI signs releases with them (`release-apk.yml`) |
| `~/.config/framebook/` on the Intel Mac | `framebook-release.jks` + `key.properties` | a backup copy: GitHub secrets can't be read back |
| `app/android/key.properties` (gitignored) | a copy of `key.properties` with an absolute path to the key | local `make build-apk` |

The password is random (32 characters) and written down nowhere but these
places. The key is RSA 4096, valid for 100 years, alias `framebook`.

Losing the key means the app can't be updated over the installed one:
friends would have to uninstall the old one, and with it any unsynced data.
The key is lost only if both the repository and the copy on the Mac vanish at
once. For peace of mind the copy of `~/.config/framebook/` could go somewhere
else too (a password manager, an encrypted archive in the cloud), but that is
optional.

Fingerprints — for the Android OAuth clients in Google Cloud (Stage 5):

| Key | SHA-1 |
|---|---|
| release (`framebook`) | `F4:07:7F:14:A1:36:FF:01:70:F1:CB:C6:4A:1A:F4:20:51:4C:0A:FD` |
| debug, Intel Mac | `D0:75:83:3B:53:FB:34:2B:78:97:6E:FD:5D:F3:2B:C4:EE:D0:5B:5B` |
| debug, M4 Mac | take it there: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android` |

Building:

- `make build-apk` → `flutter build apk --release`, a signed APK. One
  universal APK, no `--split-per-abi`: one file is simpler for friends than
  choosing an architecture.
- Without `key.properties` a release build **fails** rather than being
  silently signed with the debug key. To check that it compiles there is
  `make build-apk-check`: it explicitly allows debug signing, and CI builds
  the same way.
- To build signed on another machine (M4), copy `~/.config/framebook/` and
  `app/android/key.properties` there (the key path in it is absolute — adjust
  it for that machine).
- `keytool` and `apksigner` use the JDK from Android Studio:
  `/Applications/Android Studio.app/Contents/jbr/Contents/Home`. To check an
  APK's signature: `apksigner verify --print-certs <apk>`.
- `applicationId` is `com.github.tiltozavr2545.framebook`, `minSdk` 26,
  `targetSdk`/`compileSdk` 36.

---

## Distribution (Android)

- **A release is a tag.** Bump the version (`make bump-minor` etc.), add to
  [../CHANGELOG.md](../CHANGELOG.md), commit, then
  `git tag v0.2.0 && git push origin v0.2.0`. The `release-apk.yml` workflow
  checks that the tag matches the version in `pubspec.yaml`, runs analyze and
  the tests, builds the signed APK `framebook-0.2.0.apk`, verifies its
  signature and that the certificate is the release one (the SHA-1 above),
  and creates a GitHub Release with it.
- A release is done when the workflow is green and the APK is in the
  release's assets. The published APK isn't downloaded back to check it:
  the workflow has already verified it.
- The workflow fills the release body with GitHub's generated notes; replace
  them with written ones (`gh release edit vX.Y.Z --notes-file …`) — in
  English, like all repository text: what is new, how to install, the
  signing certificate's SHA-1, the TMDB attribution line.
- Installing at a friend's: download the APK from the release page, allow
  installs from that source, install. An update is a new APK over the old
  one, and the data stays (the same signing key, a higher `versionCode`).
- Checking for updates inside the app is planned in Stage 6.5 of
  [implementation-plan.md](implementation-plan.md); until then it is a
  message in a chat.

---

## CI

GitHub Actions on every push/PR: `dart format --set-exit-if-changed`, a check
that generated code is up to date, `flutter analyze`, `flutter test`, a
version bump check on PRs, and an APK build with the debug key. Flutter in CI
is the same 3.32.8 as on the machines. CI needs no secrets: the tests never
call external APIs. Only `release-apk.yml` uses the signing secrets.

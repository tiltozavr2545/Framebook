# Development

Local setup, dependency compatibility, generated code and implementation
pitfalls. Verification procedures are in [testing](testing.md); signing,
OAuth and publication are in [operations](operations.md).

## SDK and dependencies

Flutter is pinned to **3.32.8** across development and CI. The Intel Mac runs
macOS 12.7.6 and cannot run the newer SDK required by current Flutter releases.
Choose dependencies for the Dart SDK bundled with the pinned Flutter version.
Other development machines use the same SDK and committed lockfile.

Exact direct constraints and resolved versions live in `app/pubspec.yaml` and
`app/pubspec.lock`. Known compatibility boundaries:

| Package | Constraint or integration detail |
| --- | --- |
| Riverpod | The chosen 3.3 line supports this SDK; 3.4.1+ requires Dart 3.12 |
| Drift | The chosen 2.29 line resolves with Flutter's pinned test dependencies; newer releases can require Dart 3.10+ through sqlite3/test |
| fl_chart | The chosen 1.0 line works with Flutter's vector_math 2.1.4; 1.1 requires vector_math 2.2 |
| google_sign_in | Version 7 separates sign-in and authorization; 6.x examples do not apply |

For a deliberate dependency upgrade, temporarily relax that package's constraint
and inspect the solver result and lockfile diff. Do not use a blanket
`flutter pub upgrade --major-versions` on this SDK.

## Local setup

From the repository root:

```sh
make deps
cd app
flutter run
```

Use the connected physical Android phone; never start an emulator on the Intel
Mac. Personal API keys are entered in the app using the
[key guide](api-keys.md). Google Drive testing additionally requires the
[OAuth setup](operations.md#google-cloud-oauth-for-drive).

Make defaults to `~/development/flutter/bin/flutter` and the adjacent Dart
binary. Override `FLUTTER` and `DART` when the installation lives elsewhere.
`make help` lists the supported targets. `make install-hooks` enables the
repository's fast pre-commit and full pre-push checks.

Version changes use `make bump-build`, `make bump-patch`, `make bump-minor` or
`make bump-major`, only when authorized by the current task. Android build
numbers are monotonic. `make verify-version` checks against `origin/main` by
default; set `BASE_REF` for a different comparison base. The version itself
lives in `app/pubspec.yaml`.

## Generated code and migrations

After changing Drift tables or localization ARB files, run:

```sh
make codegen
```

This rebuilds Drift parts and localizations and generates schema snapshots and
migration-test scaffolding when the schema version increases. Commit generated
files together with their sources when a commit is authorized. Implement and
test migrations against the previous snapshot; generated scaffolding alone
does not validate data preservation.

Keep `*.g.dart` in static analysis. They are library parts: excluding them once
hid a compile error after removal of an import needed by generated code.
Edit `app/lib/l10n/app_{en,ru}.arb` as text; JSON reserialization removes the
blank lines separating string groups.

## Implementation pitfalls

- Capture `ProviderScope.containerOf(context, listen: false)` before an
  `await` when work must update providers after its widget unmounts. Accessing
  that widget's `ref` afterward throws in release builds too.
- Use a block body for completion callbacks that remove their own future:
  `whenComplete(() { pending.remove(key); })`. Returning the removed future
  makes completion wait for itself indefinitely.
- Preserve the main Android manifest's `INTERNET` permission. Permissions
  present only in debug/profile manifests do not cover a release APK.
- Test Back behavior according to route ownership. A screen reached with
  `context.go()` can legitimately have no back stack; minimizing there is valid.
- Keep storage timestamps in UTC and API release dates as calendar dates.
  The complete storage contract is in the [data model](data-model.md).
- Source clients request plain text and parse JSON themselves. The reason
  and failure classification are in [external sources](external-sources.md).

## Stalled package downloads

The development connection can be slow. A `flutter pub get -v` log that stops
growing for minutes at `Creating … .tar.gz from stream` can indicate a stalled
archive download. Stop that process and retry; completed downloads remain in
the package cache. A quiet log alone does not establish a dependency conflict.

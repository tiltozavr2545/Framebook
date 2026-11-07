# AGENTS.md

Shared instructions for agents working in Framebook. Start with the
[README](README.md) and [documentation index](docs/README.md), then read the
primary documents for the task. `CLAUDE.md` is a thin wrapper around this file.

## Scope and environment

- Follow the current request and the [implementation plan](docs/implementation-plan.md).
  Keep unscheduled ideas in [future development](docs/future-development.md).
- Use the pinned SDK and compatibility rules in
  [development](docs/development.md#sdk-and-dependencies). Do not suggest
  upgrading Flutter on the Intel macOS 12 development machine.
- Never start an Android emulator on that machine. Use a connected physical
  phone. Preserve installed app data when testing updates.
- Android is the supported target. Keep the existing iOS scaffold, but do not
  maintain it as part of Android work. There is no backend in the current scope.

## Required references

Read and preserve the following contracts before changing their code:

- [Data model](docs/data-model.md): snapshot boundaries, natural keys,
  integer scores, identity protection and user-versus-derived timestamps.
- [Sync](docs/sync.md): permanent deletion knowledge, deterministic merging,
  backward reading and refusal to overwrite newer formats.
- [External sources](docs/external-sources.md): typed ID matching, source
  errors, caching and request budgets.
- [Development](docs/development.md): Riverpod lifecycle, async completion,
  generated analysis and other implementation pitfalls.
- [Testing](docs/testing.md): required pure-logic coverage, fixture-only API
  tests and widget cleanup conventions.

## Change workflow

- Write repository documentation, comments/docstrings, commits and release
  text in English. Preserve Russian app localization and keep
  `docs/api-keys.ru.md` aligned with `docs/api-keys.md`.
- Keep credentials out of source, builds, fixtures and logs. Follow the
  storage boundaries in the data model and sync specification.
- Change the local schema through Drift migrations: raise `schemaVersion`,
  add a migration step and test the previous schema snapshot. Do not write
  ad hoc `ALTER` statements.
- Generated code is tracked. After table or ARB changes, run `make codegen`
  and include the generated result. Edit ARB files as text so their grouping
  blank lines survive.
- Run `make verify` before handing over. See the testing guide for focused
  checks and limits of automated verification.
- A PR requires a version/build increase checked by `make verify-version`.
  Do not bump versions or create commits, pushes or releases unless the
  current user request authorizes them.
- Update the primary document for each changed decision; link from related
  documents. Keep history in the changelog and review evidence in reports.
  Follow the [documentation conventions](docs/README.md#editing-conventions).

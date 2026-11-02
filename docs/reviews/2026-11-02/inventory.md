# File inventory — audit scope

All 264 files tracked at the start of the audit are listed below. Methods are
file-specific; structural inspection is not a claim of device-level execution.
The report and diagnostic files created by this audit are additional artifacts.

| File | Inspection |
|---|---|
| [.githooks/pre-commit](../../../.githooks/pre-commit) | Shell control-flow review; sh -n; no release/push/fixture capture executed |
| [.githooks/pre-push](../../../.githooks/pre-push) | Shell control-flow review; sh -n; no release/push/fixture capture executed |
| [.github/workflows/ci.yml](../../../.github/workflows/ci.yml) | Workflow triggers, permissions, signing and verification review; no remote run |
| [.github/workflows/release-apk.yml](../../../.github/workflows/release-apk.yml) | Workflow triggers, permissions, signing and verification review; no remote run |
| [.github/workflows/sync-gh-pages.yml](../../../.github/workflows/sync-gh-pages.yml) | Workflow triggers, permissions, signing and verification review; no remote run |
| [.gitignore](../../../.gitignore) | Configuration/build-role inspection |
| [AGENTS.md](../../../AGENTS.md) | Documentation/implementation consistency; relative file links |
| [CHANGELOG.md](../../../CHANGELOG.md) | Documentation/implementation consistency; relative file links |
| [CLAUDE.md](../../../CLAUDE.md) | Documentation/implementation consistency; relative file links |
| [Makefile](../../../Makefile) | Configuration/build-role inspection |
| [README.md](../../../README.md) | Documentation/implementation consistency; relative file links |
| [app/.gitignore](../../../app/.gitignore) | Configuration/build-role inspection |
| [app/.metadata](../../../app/.metadata) | Configuration/build-role inspection |
| [app/README.md](../../../app/README.md) | Documentation/implementation consistency; relative file links |
| [app/analysis_options.yaml](../../../app/analysis_options.yaml) | Configuration/build-role inspection |
| [app/android/.gitignore](../../../app/android/.gitignore) | Android configuration/resources; structured-file checks; release compile |
| [app/android/app/build.gradle.kts](../../../app/android/app/build.gradle.kts) | Android configuration/resources; structured-file checks; release compile |
| [app/android/app/src/debug/AndroidManifest.xml](../../../app/android/app/src/debug/AndroidManifest.xml) | Android configuration/resources; structured-file checks; release compile |
| [app/android/app/src/main/AndroidManifest.xml](../../../app/android/app/src/main/AndroidManifest.xml) | Android configuration/resources; structured-file checks; release compile |
| [app/android/app/src/main/kotlin/com/github/tiltozavr2545/framebook/MainActivity.kt](../../../app/android/app/src/main/kotlin/com/github/tiltozavr2545/framebook/MainActivity.kt) | Android configuration/resources; structured-file checks; release compile |
| [app/android/app/src/main/res/drawable-v21/launch_background.xml](../../../app/android/app/src/main/res/drawable-v21/launch_background.xml) | Android configuration/resources; structured-file checks; release compile |
| [app/android/app/src/main/res/drawable/ic_launcher_foreground.xml](../../../app/android/app/src/main/res/drawable/ic_launcher_foreground.xml) | Android configuration/resources; structured-file checks; release compile |
| [app/android/app/src/main/res/drawable/ic_launcher_monochrome.xml](../../../app/android/app/src/main/res/drawable/ic_launcher_monochrome.xml) | Android configuration/resources; structured-file checks; release compile |
| [app/android/app/src/main/res/drawable/launch_background.xml](../../../app/android/app/src/main/res/drawable/launch_background.xml) | Android configuration/resources; structured-file checks; release compile |
| [app/android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml](../../../app/android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml) | Android configuration/resources; structured-file checks; release compile |
| [app/android/app/src/main/res/values-night-v31/styles.xml](../../../app/android/app/src/main/res/values-night-v31/styles.xml) | Android configuration/resources; structured-file checks; release compile |
| [app/android/app/src/main/res/values-night/styles.xml](../../../app/android/app/src/main/res/values-night/styles.xml) | Android configuration/resources; structured-file checks; release compile |
| [app/android/app/src/main/res/values-v31/styles.xml](../../../app/android/app/src/main/res/values-v31/styles.xml) | Android configuration/resources; structured-file checks; release compile |
| [app/android/app/src/main/res/values/colors.xml](../../../app/android/app/src/main/res/values/colors.xml) | Android configuration/resources; structured-file checks; release compile |
| [app/android/app/src/main/res/values/styles.xml](../../../app/android/app/src/main/res/values/styles.xml) | Android configuration/resources; structured-file checks; release compile |
| [app/android/app/src/profile/AndroidManifest.xml](../../../app/android/app/src/profile/AndroidManifest.xml) | Android configuration/resources; structured-file checks; release compile |
| [app/android/build.gradle.kts](../../../app/android/build.gradle.kts) | Android configuration/resources; structured-file checks; release compile |
| [app/android/gradle.properties](../../../app/android/gradle.properties) | Android configuration/resources; structured-file checks; release compile |
| [app/android/gradle/wrapper/gradle-wrapper.properties](../../../app/android/gradle/wrapper/gradle-wrapper.properties) | Android configuration/resources; structured-file checks; release compile |
| [app/android/key.properties.example](../../../app/android/key.properties.example) | Android configuration/resources; structured-file checks; release compile |
| [app/android/settings.gradle.kts](../../../app/android/settings.gradle.kts) | Android configuration/resources; structured-file checks; release compile |
| [app/assets/fonts/OFL.txt](../../../app/assets/fonts/OFL.txt) | Configuration/build-role inspection |
| [app/assets/fonts/SofiaSans-400.ttf](../../../app/assets/fonts/SofiaSans-400.ttf) | Font signature; loaded by screenshot render suite |
| [app/assets/fonts/SofiaSans-500.ttf](../../../app/assets/fonts/SofiaSans-500.ttf) | Font signature; loaded by screenshot render suite |
| [app/assets/fonts/SofiaSans-600.ttf](../../../app/assets/fonts/SofiaSans-600.ttf) | Font signature; loaded by screenshot render suite |
| [app/assets/fonts/SofiaSans-700.ttf](../../../app/assets/fonts/SofiaSans-700.ttf) | Font signature; loaded by screenshot render suite |
| [app/assets/fonts/SofiaSansExtraCondensed-500.ttf](../../../app/assets/fonts/SofiaSansExtraCondensed-500.ttf) | Font signature; loaded by screenshot render suite |
| [app/assets/fonts/SofiaSansExtraCondensed-700.ttf](../../../app/assets/fonts/SofiaSansExtraCondensed-700.ttf) | Font signature; loaded by screenshot render suite |
| [app/assets/fonts/SofiaSansExtraCondensed-800.ttf](../../../app/assets/fonts/SofiaSansExtraCondensed-800.ttf) | Font signature; loaded by screenshot render suite |
| [app/assets/tmdb_logo.png](../../../app/assets/tmdb_logo.png) | PNG signature and chunk CRCs; asset/screenshot role |
| [app/build.yaml](../../../app/build.yaml) | Configuration/build-role inspection |
| [app/drift_schemas/framebook/drift_schema_v1.json](../../../app/drift_schemas/framebook/drift_schema_v1.json) | Configuration/build-role inspection |
| [app/ios/.gitignore](../../../app/ios/.gitignore) | Platform/template configuration and structure; no iOS build (postponed) |
| [app/ios/Flutter/AppFrameworkInfo.plist](../../../app/ios/Flutter/AppFrameworkInfo.plist) | Platform/template configuration and structure; no iOS build (postponed) |
| [app/ios/Flutter/Debug.xcconfig](../../../app/ios/Flutter/Debug.xcconfig) | Platform/template configuration and structure; no iOS build (postponed) |
| [app/ios/Flutter/Release.xcconfig](../../../app/ios/Flutter/Release.xcconfig) | Platform/template configuration and structure; no iOS build (postponed) |
| [app/ios/Runner.xcodeproj/project.pbxproj](../../../app/ios/Runner.xcodeproj/project.pbxproj) | Platform/template configuration and structure; no iOS build (postponed) |
| [app/ios/Runner.xcodeproj/project.xcworkspace/contents.xcworkspacedata](../../../app/ios/Runner.xcodeproj/project.xcworkspace/contents.xcworkspacedata) | Platform/template configuration and structure; no iOS build (postponed) |
| [app/ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist](../../../app/ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist) | Platform/template configuration and structure; no iOS build (postponed) |
| [app/ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings](../../../app/ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings) | Platform/template configuration and structure; no iOS build (postponed) |
| [app/ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme](../../../app/ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme) | Platform/template configuration and structure; no iOS build (postponed) |
| [app/ios/Runner.xcworkspace/contents.xcworkspacedata](../../../app/ios/Runner.xcworkspace/contents.xcworkspacedata) | Platform/template configuration and structure; no iOS build (postponed) |
| [app/ios/Runner.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist](../../../app/ios/Runner.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist) | Platform/template configuration and structure; no iOS build (postponed) |
| [app/ios/Runner.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings](../../../app/ios/Runner.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings) | Platform/template configuration and structure; no iOS build (postponed) |
| [app/ios/Runner/AppDelegate.swift](../../../app/ios/Runner/AppDelegate.swift) | Platform/template configuration and structure; no iOS build (postponed) |
| [app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json](../../../app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json) | Platform/template configuration and structure; no iOS build (postponed) |
| [app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png](../../../app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png) | PNG signature and chunk CRCs; asset/screenshot role |
| [app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png](../../../app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png) | PNG signature and chunk CRCs; asset/screenshot role |
| [app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png](../../../app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png) | PNG signature and chunk CRCs; asset/screenshot role |
| [app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png](../../../app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png) | PNG signature and chunk CRCs; asset/screenshot role |
| [app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png](../../../app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png) | PNG signature and chunk CRCs; asset/screenshot role |
| [app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png](../../../app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png) | PNG signature and chunk CRCs; asset/screenshot role |
| [app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png](../../../app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png) | PNG signature and chunk CRCs; asset/screenshot role |
| [app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png](../../../app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png) | PNG signature and chunk CRCs; asset/screenshot role |
| [app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png](../../../app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png) | PNG signature and chunk CRCs; asset/screenshot role |
| [app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png](../../../app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png) | PNG signature and chunk CRCs; asset/screenshot role |
| [app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png](../../../app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png) | PNG signature and chunk CRCs; asset/screenshot role |
| [app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png](../../../app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png) | PNG signature and chunk CRCs; asset/screenshot role |
| [app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png](../../../app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png) | PNG signature and chunk CRCs; asset/screenshot role |
| [app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png](../../../app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png) | PNG signature and chunk CRCs; asset/screenshot role |
| [app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png](../../../app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png) | PNG signature and chunk CRCs; asset/screenshot role |
| [app/ios/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json](../../../app/ios/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json) | Platform/template configuration and structure; no iOS build (postponed) |
| [app/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png](../../../app/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png) | PNG signature and chunk CRCs; asset/screenshot role |
| [app/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png](../../../app/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png) | PNG signature and chunk CRCs; asset/screenshot role |
| [app/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png](../../../app/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png) | PNG signature and chunk CRCs; asset/screenshot role |
| [app/ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md](../../../app/ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md) | Platform/template configuration and structure; no iOS build (postponed) |
| [app/ios/Runner/Base.lproj/LaunchScreen.storyboard](../../../app/ios/Runner/Base.lproj/LaunchScreen.storyboard) | Platform/template configuration and structure; no iOS build (postponed) |
| [app/ios/Runner/Base.lproj/Main.storyboard](../../../app/ios/Runner/Base.lproj/Main.storyboard) | Platform/template configuration and structure; no iOS build (postponed) |
| [app/ios/Runner/Info.plist](../../../app/ios/Runner/Info.plist) | Platform/template configuration and structure; no iOS build (postponed) |
| [app/ios/Runner/Runner-Bridging-Header.h](../../../app/ios/Runner/Runner-Bridging-Header.h) | Platform/template configuration and structure; no iOS build (postponed) |
| [app/ios/RunnerTests/RunnerTests.swift](../../../app/ios/RunnerTests/RunnerTests.swift) | Platform/template configuration and structure; no iOS build (postponed) |
| [app/l10n.yaml](../../../app/l10n.yaml) | Configuration/build-role inspection |
| [app/lib/app/app.dart](../../../app/lib/app/app.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/app/preferences.dart](../../../app/lib/app/preferences.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/app/router.dart](../../../app/lib/app/router.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/app/theme.dart](../../../app/lib/app/theme.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/data/api_keys.dart](../../../app/lib/data/api_keys.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/data/api_source.dart](../../../app/lib/data/api_source.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/data/background_refresh.dart](../../../app/lib/data/background_refresh.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/data/budget.dart](../../../app/lib/data/budget.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/data/db/database.dart](../../../app/lib/data/db/database.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/data/db/database.g.dart](../../../app/lib/data/db/database.g.dart) | Regenerated; no tracked diff; analyzed and compiled |
| [app/lib/data/db/database_provider.dart](../../../app/lib/data/db/database_provider.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/data/db/tables.dart](../../../app/lib/data/db/tables.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/data/http.dart](../../../app/lib/data/http.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/data/key_validator.dart](../../../app/lib/data/key_validator.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/data/library/divergence.dart](../../../app/lib/data/library/divergence.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/data/library/library.dart](../../../app/lib/data/library/library.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/data/library/localized_titles.dart](../../../app/lib/data/library/localized_titles.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/data/library/renumbering.dart](../../../app/lib/data/library/renumbering.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/data/library/stats.dart](../../../app/lib/data/library/stats.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/data/library/work_snapshot.dart](../../../app/lib/data/library/work_snapshot.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/data/ratings_service.dart](../../../app/lib/data/ratings_service.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/data/response_cache.dart](../../../app/lib/data/response_cache.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/data/source_failure.dart](../../../app/lib/data/source_failure.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/data/sources/omdb/omdb_client.dart](../../../app/lib/data/sources/omdb/omdb_client.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/data/sources/poiskkino/poiskkino_client.dart](../../../app/lib/data/sources/poiskkino/poiskkino_client.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/data/sources/providers.dart](../../../app/lib/data/sources/providers.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/data/sources/tmdb/tmdb_client.dart](../../../app/lib/data/sources/tmdb/tmdb_client.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/data/sources/tmdb/tmdb_models.dart](../../../app/lib/data/sources/tmdb/tmdb_models.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/data/sources/tmdb/tmdb_people.dart](../../../app/lib/data/sources/tmdb/tmdb_people.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/data/sync/drive_remote.dart](../../../app/lib/data/sync/drive_remote.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/data/sync/google_account.dart](../../../app/lib/data/sync/google_account.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/data/sync/merge.dart](../../../app/lib/data/sync/merge.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/data/sync/secrets_controller.dart](../../../app/lib/data/sync/secrets_controller.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/data/sync/secrets_vault.dart](../../../app/lib/data/sync/secrets_vault.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/data/sync/sync_controller.dart](../../../app/lib/data/sync/sync_controller.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/data/sync/sync_engine.dart](../../../app/lib/data/sync/sync_engine.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/data/sync/sync_file.dart](../../../app/lib/data/sync/sync_file.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/data/sync/sync_store.dart](../../../app/lib/data/sync/sync_store.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/data/update_checker.dart](../../../app/lib/data/update_checker.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/data/update_version.dart](../../../app/lib/data/update_version.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/data/work_key.dart](../../../app/lib/data/work_key.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/features/onboarding/onboarding_screen.dart](../../../app/lib/features/onboarding/onboarding_screen.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/features/person/person_screen.dart](../../../app/lib/features/person/person_screen.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/features/ratings/ratings_screen.dart](../../../app/lib/features/ratings/ratings_screen.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/features/search/search_controller.dart](../../../app/lib/features/search/search_controller.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/features/search/search_screen.dart](../../../app/lib/features/search/search_screen.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/features/search/shelves.dart](../../../app/lib/features/search/shelves.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/features/settings/about_screen.dart](../../../app/lib/features/settings/about_screen.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/features/settings/api_keys_form.dart](../../../app/lib/features/settings/api_keys_form.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/features/settings/settings_screen.dart](../../../app/lib/features/settings/settings_screen.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/features/settings/sources_screen.dart](../../../app/lib/features/settings/sources_screen.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/features/settings/sync_screen.dart](../../../app/lib/features/settings/sync_screen.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/features/shell/shell_screen.dart](../../../app/lib/features/shell/shell_screen.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/features/stats/stats_screen.dart](../../../app/lib/features/stats/stats_screen.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/features/title/cast_section.dart](../../../app/lib/features/title/cast_section.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/features/title/cover_viewer.dart](../../../app/lib/features/title/cover_viewer.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/features/title/episode_screen.dart](../../../app/lib/features/title/episode_screen.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/features/title/movie_screen.dart](../../../app/lib/features/title/movie_screen.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/features/title/my_rating.dart](../../../app/lib/features/title/my_rating.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/features/title/ratings_panel.dart](../../../app/lib/features/title/ratings_panel.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/features/title/renumber_notice.dart](../../../app/lib/features/title/renumber_notice.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/features/title/saved_card.dart](../../../app/lib/features/title/saved_card.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/features/title/score_reel.dart](../../../app/lib/features/title/score_reel.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/features/title/season_screen.dart](../../../app/lib/features/title/season_screen.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/features/title/title_layout.dart](../../../app/lib/features/title/title_layout.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/features/title/title_providers.dart](../../../app/lib/features/title/title_providers.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/features/title/title_ratings.dart](../../../app/lib/features/title/title_ratings.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/features/title/title_routes.dart](../../../app/lib/features/title/title_routes.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/features/title/tv_screen.dart](../../../app/lib/features/title/tv_screen.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/features/watchlist/watchlist_screen.dart](../../../app/lib/features/watchlist/watchlist_screen.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/l10n/app_en.arb](../../../app/lib/l10n/app_en.arb) | Strings/placeholder and key parity; localization regeneration; UI renders |
| [app/lib/l10n/app_localizations.dart](../../../app/lib/l10n/app_localizations.dart) | Regenerated; no tracked diff; analyzed and compiled |
| [app/lib/l10n/app_localizations_en.dart](../../../app/lib/l10n/app_localizations_en.dart) | Regenerated; no tracked diff; analyzed and compiled |
| [app/lib/l10n/app_localizations_ru.dart](../../../app/lib/l10n/app_localizations_ru.dart) | Regenerated; no tracked diff; analyzed and compiled |
| [app/lib/l10n/app_ru.arb](../../../app/lib/l10n/app_ru.arb) | Strings/placeholder and key parity; localization regeneration; UI renders |
| [app/lib/main.dart](../../../app/lib/main.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/shared/coverage_line.dart](../../../app/lib/shared/coverage_line.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/shared/failure_view.dart](../../../app/lib/shared/failure_view.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/shared/format.dart](../../../app/lib/shared/format.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/shared/kind_filter.dart](../../../app/lib/shared/kind_filter.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/shared/poster.dart](../../../app/lib/shared/poster.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/shared/title_row.dart](../../../app/lib/shared/title_row.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/lib/shared/title_text.dart](../../../app/lib/shared/title_text.dart) | Implementation and call-path review; analyzer/tests; Android compile |
| [app/pubspec.lock](../../../app/pubspec.lock) | Resolved dependency versions; enforced lockfile resolution; compile |
| [app/pubspec.yaml](../../../app/pubspec.yaml) | Configuration/build-role inspection |
| [app/test/app_test.dart](../../../app/test/app_test.dart) | Scenario/fixture review; full test run (screenshots run explicitly) |
| [app/test/data/api_keys_test.dart](../../../app/test/data/api_keys_test.dart) | Scenario/fixture review; full test run (screenshots run explicitly) |
| [app/test/data/background_refresh_test.dart](../../../app/test/data/background_refresh_test.dart) | Scenario/fixture review; full test run (screenshots run explicitly) |
| [app/test/data/comparison_test.dart](../../../app/test/data/comparison_test.dart) | Scenario/fixture review; full test run (screenshots run explicitly) |
| [app/test/data/database_test.dart](../../../app/test/data/database_test.dart) | Scenario/fixture review; full test run (screenshots run explicitly) |
| [app/test/data/key_validator_test.dart](../../../app/test/data/key_validator_test.dart) | Scenario/fixture review; full test run (screenshots run explicitly) |
| [app/test/data/library_test.dart](../../../app/test/data/library_test.dart) | Scenario/fixture review; full test run (screenshots run explicitly) |
| [app/test/data/localized_titles_test.dart](../../../app/test/data/localized_titles_test.dart) | Scenario/fixture review; full test run (screenshots run explicitly) |
| [app/test/data/omdb_client_test.dart](../../../app/test/data/omdb_client_test.dart) | Scenario/fixture review; full test run (screenshots run explicitly) |
| [app/test/data/poiskkino_client_test.dart](../../../app/test/data/poiskkino_client_test.dart) | Scenario/fixture review; full test run (screenshots run explicitly) |
| [app/test/data/ratings_service_test.dart](../../../app/test/data/ratings_service_test.dart) | Scenario/fixture review; full test run (screenshots run explicitly) |
| [app/test/data/renumbering_test.dart](../../../app/test/data/renumbering_test.dart) | Scenario/fixture review; full test run (screenshots run explicitly) |
| [app/test/data/response_cache_test.dart](../../../app/test/data/response_cache_test.dart) | Scenario/fixture review; full test run (screenshots run explicitly) |
| [app/test/data/sync/drive_remote_test.dart](../../../app/test/data/sync/drive_remote_test.dart) | Scenario/fixture review; full test run (screenshots run explicitly) |
| [app/test/data/sync/secrets_vault_test.dart](../../../app/test/data/sync/secrets_vault_test.dart) | Scenario/fixture review; full test run (screenshots run explicitly) |
| [app/test/data/sync_controller_test.dart](../../../app/test/data/sync_controller_test.dart) | Scenario/fixture review; full test run (screenshots run explicitly) |
| [app/test/data/sync_test.dart](../../../app/test/data/sync_test.dart) | Scenario/fixture review; full test run (screenshots run explicitly) |
| [app/test/data/tmdb_client_test.dart](../../../app/test/data/tmdb_client_test.dart) | Scenario/fixture review; full test run (screenshots run explicitly) |
| [app/test/data/update_checker_test.dart](../../../app/test/data/update_checker_test.dart) | Scenario/fixture review; full test run (screenshots run explicitly) |
| [app/test/data/update_version_test.dart](../../../app/test/data/update_version_test.dart) | Scenario/fixture review; full test run (screenshots run explicitly) |
| [app/test/data/work_key_test.dart](../../../app/test/data/work_key_test.dart) | Scenario/fixture review; full test run (screenshots run explicitly) |
| [app/test/features/calibration_visibility_test.dart](../../../app/test/features/calibration_visibility_test.dart) | Scenario/fixture review; full test run (screenshots run explicitly) |
| [app/test/features/cast_layout_test.dart](../../../app/test/features/cast_layout_test.dart) | Scenario/fixture review; full test run (screenshots run explicitly) |
| [app/test/features/cover_viewer_test.dart](../../../app/test/features/cover_viewer_test.dart) | Scenario/fixture review; full test run (screenshots run explicitly) |
| [app/test/features/rating_cell_state_test.dart](../../../app/test/features/rating_cell_state_test.dart) | Scenario/fixture review; full test run (screenshots run explicitly) |
| [app/test/features/search_controller_test.dart](../../../app/test/features/search_controller_test.dart) | Scenario/fixture review; full test run (screenshots run explicitly) |
| [app/test/features/sync_screen_test.dart](../../../app/test/features/sync_screen_test.dart) | Scenario/fixture review; full test run (screenshots run explicitly) |
| [app/test/features/update_check_test.dart](../../../app/test/features/update_check_test.dart) | Scenario/fixture review; full test run (screenshots run explicitly) |
| [app/test/fixtures/omdb/invalid_key.json](../../../app/test/fixtures/omdb/invalid_key.json) | JSON structure; source-client fixture tests |
| [app/test/fixtures/omdb/malformed_id.json](../../../app/test/fixtures/omdb/malformed_id.json) | JSON structure; source-client fixture tests |
| [app/test/fixtures/omdb/not_found.json](../../../app/test/fixtures/omdb/not_found.json) | JSON structure; source-client fixture tests |
| [app/test/fixtures/omdb/tt0133093.json](../../../app/test/fixtures/omdb/tt0133093.json) | JSON structure; source-client fixture tests |
| [app/test/fixtures/omdb/tt0944947_s1e3.json](../../../app/test/fixtures/omdb/tt0944947_s1e3.json) | JSON structure; source-client fixture tests |
| [app/test/fixtures/omdb/tt0944947_season_1.json](../../../app/test/fixtures/omdb/tt0944947_season_1.json) | JSON structure; source-client fixture tests |
| [app/test/fixtures/omdb/tt0944947_series.json](../../../app/test/fixtures/omdb/tt0944947_series.json) | JSON structure; source-client fixture tests |
| [app/test/fixtures/poiskkino/movie_301.json](../../../app/test/fixtures/poiskkino/movie_301.json) | JSON structure; source-client fixture tests |
| [app/test/fixtures/poiskkino/movie_by_imdb_not_found.json](../../../app/test/fixtures/poiskkino/movie_by_imdb_not_found.json) | JSON structure; source-client fixture tests |
| [app/test/fixtures/poiskkino/movie_by_imdb_tt0133093.json](../../../app/test/fixtures/poiskkino/movie_by_imdb_tt0133093.json) | JSON structure; source-client fixture tests |
| [app/test/fixtures/poiskkino/movie_by_tmdb_603.json](../../../app/test/fixtures/poiskkino/movie_by_tmdb_603.json) | JSON structure; source-client fixture tests |
| [app/test/fixtures/poiskkino/movie_by_tmdb_603_type_movie.json](../../../app/test/fixtures/poiskkino/movie_by_tmdb_603_type_movie.json) | JSON structure; source-client fixture tests |
| [app/test/fixtures/poiskkino/movie_by_tmdb_out_of_range.json](../../../app/test/fixtures/poiskkino/movie_by_tmdb_out_of_range.json) | JSON structure; source-client fixture tests |
| [app/test/fixtures/poiskkino/season_464963.json](../../../app/test/fixtures/poiskkino/season_464963.json) | JSON structure; source-client fixture tests |
| [app/test/fixtures/poiskkino/tv_by_tmdb_1399.json](../../../app/test/fixtures/poiskkino/tv_by_tmdb_1399.json) | JSON structure; source-client fixture tests |
| [app/test/fixtures/tmdb/configuration.json](../../../app/test/fixtures/tmdb/configuration.json) | JSON structure; source-client fixture tests |
| [app/test/fixtures/tmdb/discover_movie_best_ru.json](../../../app/test/fixtures/tmdb/discover_movie_best_ru.json) | JSON structure; source-client fixture tests |
| [app/test/fixtures/tmdb/discover_tv_best_ru.json](../../../app/test/fixtures/tmdb/discover_tv_best_ru.json) | JSON structure; source-client fixture tests |
| [app/test/fixtures/tmdb/episode_images.json](../../../app/test/fixtures/tmdb/episode_images.json) | JSON structure; source-client fixture tests |
| [app/test/fixtures/tmdb/genre_movie_ru.json](../../../app/test/fixtures/tmdb/genre_movie_ru.json) | JSON structure; source-client fixture tests |
| [app/test/fixtures/tmdb/genre_tv_ru.json](../../../app/test/fixtures/tmdb/genre_tv_ru.json) | JSON structure; source-client fixture tests |
| [app/test/fixtures/tmdb/movie_603_recommendations_ru.json](../../../app/test/fixtures/tmdb/movie_603_recommendations_ru.json) | JSON structure; source-client fixture tests |
| [app/test/fixtures/tmdb/movie_603_ru.json](../../../app/test/fixtures/tmdb/movie_603_ru.json) | JSON structure; source-client fixture tests |
| [app/test/fixtures/tmdb/movie_not_found.json](../../../app/test/fixtures/tmdb/movie_not_found.json) | JSON structure; source-client fixture tests |
| [app/test/fixtures/tmdb/movie_now_playing_ru.json](../../../app/test/fixtures/tmdb/movie_now_playing_ru.json) | JSON structure; source-client fixture tests |
| [app/test/fixtures/tmdb/person_6384_ru.json](../../../app/test/fixtures/tmdb/person_6384_ru.json) | JSON structure; source-client fixture tests |
| [app/test/fixtures/tmdb/search_multi_matrix_ru.json](../../../app/test/fixtures/tmdb/search_multi_matrix_ru.json) | JSON structure; source-client fixture tests |
| [app/test/fixtures/tmdb/season_images.json](../../../app/test/fixtures/tmdb/season_images.json) | JSON structure; source-client fixture tests |
| [app/test/fixtures/tmdb/trending_all_week_ru.json](../../../app/test/fixtures/tmdb/trending_all_week_ru.json) | JSON structure; source-client fixture tests |
| [app/test/fixtures/tmdb/tv_1399_recommendations_ru.json](../../../app/test/fixtures/tmdb/tv_1399_recommendations_ru.json) | JSON structure; source-client fixture tests |
| [app/test/fixtures/tmdb/tv_1399_ru.json](../../../app/test/fixtures/tmdb/tv_1399_ru.json) | JSON structure; source-client fixture tests |
| [app/test/fixtures/tmdb/tv_1399_s1e3_credits_ru.json](../../../app/test/fixtures/tmdb/tv_1399_s1e3_credits_ru.json) | JSON structure; source-client fixture tests |
| [app/test/fixtures/tmdb/tv_1399_s1e3_external_ids.json](../../../app/test/fixtures/tmdb/tv_1399_s1e3_external_ids.json) | JSON structure; source-client fixture tests |
| [app/test/fixtures/tmdb/tv_1399_season_1_ru.json](../../../app/test/fixtures/tmdb/tv_1399_season_1_ru.json) | JSON structure; source-client fixture tests |
| [app/test/screenshots/poster_a.png](../../../app/test/screenshots/poster_a.png) | PNG signature and chunk CRCs; asset/screenshot role |
| [app/test/screenshots/poster_b.png](../../../app/test/screenshots/poster_b.png) | PNG signature and chunk CRCs; asset/screenshot role |
| [app/test/screenshots/poster_c.png](../../../app/test/screenshots/poster_c.png) | PNG signature and chunk CRCs; asset/screenshot role |
| [app/test/screenshots/poster_d.png](../../../app/test/screenshots/poster_d.png) | PNG signature and chunk CRCs; asset/screenshot role |
| [app/test/screenshots/screens_test.dart](../../../app/test/screenshots/screens_test.dart) | Scenario/fixture review; full test run (screenshots run explicitly) |
| [app/test/secrets_controller_test.dart](../../../app/test/secrets_controller_test.dart) | Scenario/fixture review; full test run (screenshots run explicitly) |
| [app/test/support/api_fixtures.dart](../../../app/test/support/api_fixtures.dart) | Scenario/fixture review; full test run (screenshots run explicitly) |
| [app/test/support/fake_google.dart](../../../app/test/support/fake_google.dart) | Scenario/fixture review; full test run (screenshots run explicitly) |
| [app/test/support/fake_http.dart](../../../app/test/support/fake_http.dart) | Scenario/fixture review; full test run (screenshots run explicitly) |
| [app/test/support/memory_key_storage.dart](../../../app/test/support/memory_key_storage.dart) | Scenario/fixture review; full test run (screenshots run explicitly) |
| [app/test/support/memory_remote.dart](../../../app/test/support/memory_remote.dart) | Scenario/fixture review; full test run (screenshots run explicitly) |
| [docs/api-keys.md](../../../docs/api-keys.md) | Documentation/implementation consistency; relative file links |
| [docs/api-keys.ru.md](../../../docs/api-keys.ru.md) | Documentation/implementation consistency; relative file links |
| [docs/client-architecture.md](../../../docs/client-architecture.md) | Documentation/implementation consistency; relative file links |
| [docs/data-model.md](../../../docs/data-model.md) | Documentation/implementation consistency; relative file links |
| [docs/external-sources.md](../../../docs/external-sources.md) | Documentation/implementation consistency; relative file links |
| [docs/future-development.md](../../../docs/future-development.md) | Documentation/implementation consistency; relative file links |
| [docs/gh-pages/index.html](../../../docs/gh-pages/index.html) | Documentation/implementation consistency; relative file links |
| [docs/gh-pages/privacy.html](../../../docs/gh-pages/privacy.html) | Documentation/implementation consistency; relative file links |
| [docs/implementation-plan.md](../../../docs/implementation-plan.md) | Documentation/implementation consistency; relative file links |
| [docs/operations.md](../../../docs/operations.md) | Documentation/implementation consistency; relative file links |
| [docs/project-brief.md](../../../docs/project-brief.md) | Documentation/implementation consistency; relative file links |
| [docs/screenshots/card-light.png](../../../docs/screenshots/card-light.png) | PNG signature and chunk CRCs; asset/screenshot role |
| [docs/screenshots/editor-light.png](../../../docs/screenshots/editor-light.png) | PNG signature and chunk CRCs; asset/screenshot role |
| [docs/screenshots/search-light.png](../../../docs/screenshots/search-light.png) | PNG signature and chunk CRCs; asset/screenshot role |
| [docs/screenshots/stats-dark.png](../../../docs/screenshots/stats-dark.png) | PNG signature and chunk CRCs; asset/screenshot role |
| [docs/sync.md](../../../docs/sync.md) | Documentation/implementation consistency; relative file links |
| [scripts/bump-version.sh](../../../scripts/bump-version.sh) | Shell control-flow review; sh -n; no release/push/fixture capture executed |
| [scripts/capture-fixtures.sh](../../../scripts/capture-fixtures.sh) | Shell control-flow review; sh -n; no release/push/fixture capture executed |
| [scripts/verify-version.sh](../../../scripts/verify-version.sh) | Shell control-flow review; sh -n; no release/push/fixture capture executed |

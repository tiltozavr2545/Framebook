import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../data/sync/sync_controller.dart';
import '../../data/update_checker.dart';
import '../../l10n/app_localizations.dart';

/// About the app and where the data comes from. TMDB attribution — the logo
/// and a fixed sentence — is a condition of their API
/// (docs/external-sources.md).
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  static final _tmdb = Uri.parse('https://www.themoviedb.org');
  static final _poiskkino = Uri.parse('https://poiskkino.dev');
  static final _omdb = Uri.parse('https://www.omdbapi.com');
  static final _repo = Uri.parse('https://github.com/tiltozavr2545/Framebook');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // "0.5.0+7" as pubspec has it.
    final [name, build] = '${ref.watch(appVersionProvider)}+'
        .split('+')
        .take(2)
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(l10n.appTitle, style: theme.textTheme.headlineLarge),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
            child: Text(
              build.isEmpty
                  ? l10n.aboutVersionName(name)
                  : l10n.aboutVersion(name, build),
              style: theme.textTheme.labelLarge?.copyWith(
                color: Reel.of(context).edge,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.system_update),
            title: Text(l10n.updateCheck),
            onTap: () async {
              final controller = ref.read(updateControllerProvider.notifier);
              final result = await controller.check(manual: true);
              if (!context.mounted) return;
              final text = switch (result) {
                UpdateResult.available => l10n.updateFound,
                UpdateResult.current => l10n.updateCurrent,
                UpdateResult.failed => l10n.updateFailed,
              };
              final release = controller.lastRelease;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(text),
                  action: result == UpdateResult.available && release != null
                      ? SnackBarAction(
                          label: l10n.updateOpen,
                          onPressed: () => _open(release.url),
                        )
                      : null,
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Text(l10n.aboutIntro, style: theme.textTheme.bodyLarge),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(l10n.aboutData, style: theme.textTheme.titleMedium),
          ),
          InkWell(
            onTap: () => _open(_tmdb),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/tmdb_logo.png',
                    height: 20,
                    semanticLabel: 'TMDB',
                  ),
                  const SizedBox(height: 12),
                  // TMDB's own wording; not translated.
                  Text(
                    'This product uses the TMDB API but is not endorsed or '
                    'certified by TMDB.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.aboutTmdb,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            title: Text(l10n.aboutPoiskkinoTitle),
            subtitle: Text(l10n.aboutPoiskkino),
            onTap: () => _open(_poiskkino),
          ),
          ListTile(
            title: const Text('OMDb API'),
            subtitle: Text(l10n.aboutOmdb),
            onTap: () => _open(_omdb),
          ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.code),
            title: Text(l10n.aboutSource),
            subtitle: const Text('github.com/tiltozavr2545/Framebook'),
            onTap: () => _open(_repo),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(l10n.aboutLicenses),
            onTap: () => showLicensePage(
              context: context,
              applicationName: l10n.appTitle,
              applicationVersion: name,
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _open(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);
}

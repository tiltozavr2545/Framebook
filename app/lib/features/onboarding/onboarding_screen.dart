import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../data/api_keys.dart';
import '../../data/api_source.dart';
import '../../l10n/app_localizations.dart';
import '../settings/api_keys_form.dart';

/// First launch: without a TMDB key the router lets no one further
/// (app/router.dart). The user leaves on their own, with a button, so there is
/// time to add the optional keys as well.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hasTmdb = ref.watch(apiKeysProvider).has(ApiSource.tmdb);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 16),
            Text(l10n.onboardingTitle, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(l10n.onboardingIntro, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => context.push(Routes.restoreDrive),
              icon: const Icon(Icons.cloud_download_outlined),
              label: Text(l10n.secretsRestoreFromDrive),
            ),
            const SizedBox(height: 16),
            const ApiKeysForm(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!hasTmdb)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    l10n.onboardingTmdbRequired,
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: hasTmdb ? () => context.go(Routes.search) : null,
                  child: Text(l10n.onboardingContinue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/router.dart';
import '../data/source_failure.dart';
import '../l10n/app_localizations.dart';

/// Why the catalog failed — never the raw exception text.
SourceFailure failureOf(Object error) =>
    error is SourceException ? error.failure : SourceFailure.failed;

/// Text for a TMDB error (search, cards).
String catalogFailureText(AppLocalizations l10n, SourceFailure failure) =>
    switch (failure) {
      SourceFailure.offline => l10n.failureOffline,
      SourceFailure.unauthorized => l10n.failureTmdbKey,
      SourceFailure.notFound => l10n.failureNotFound,
      SourceFailure.limitReached || SourceFailure.failed => l10n.failureTmdb,
    };

/// Shown instead of content that failed to load.
class FailureView extends StatelessWidget {
  const FailureView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final failure = failureOf(error);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              failure == SourceFailure.offline
                  ? Icons.cloud_off_outlined
                  : Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              catalogFailureText(l10n, failure),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            if (failure == SourceFailure.unauthorized)
              FilledButton.tonal(
                onPressed: () => context.push(Routes.sources),
                child: Text(l10n.settingsSources),
              )
            else if (failure != SourceFailure.notFound && onRetry != null)
              FilledButton.tonal(onPressed: onRetry, child: Text(l10n.retry)),
          ],
        ),
      ),
    );
  }
}

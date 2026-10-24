import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/sources/tmdb/tmdb_models.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/failure_view.dart';
import '../../shared/format.dart';
import '../../shared/poster.dart';

/// Card scaffold: title, loading, error with a retry.
class TitlePage<T> extends ConsumerWidget {
  const TitlePage({
    super.key,
    required this.value,
    required this.title,
    required this.onRetry,
    required this.builder,
  });

  final AsyncValue<T> value;

  /// The app bar title once the data is there.
  final String? Function(T data) title;
  final VoidCallback onRetry;
  final List<Widget> Function(BuildContext context, T data) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = value.value;
    return Scaffold(
      appBar: AppBar(
        title: data == null
            ? null
            : Text(title(data) ?? '', overflow: TextOverflow.ellipsis),
      ),
      body: switch (value) {
        AsyncValue(value: final data?) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: builder(context, data),
        ),
        AsyncValue(:final error?) => FailureView(
          error: error,
          onRetry: onRetry,
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

/// Poster on the left, title and facts on the right.
class TitleHeader extends StatelessWidget {
  const TitleHeader({
    super.key,
    required this.posterPath,
    required this.title,
    this.originalTitle,
    this.facts = const [],
    this.tagline,
    this.posterIcon = Icons.movie_outlined,
  });

  final String? posterPath;
  final String title;

  /// Shown only when it differs from [title].
  final String? originalTitle;

  /// Lines like "1999 · 2 h 16 min"; empty ones are skipped.
  final List<String?> facts;
  final String? tagline;
  final IconData posterIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final original = originalTitle;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Poster(posterPath, size: ImageSize.w342, width: 116, icon: posterIcon),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleLarge),
              if (original != null && original != title)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(original, style: muted),
                ),
              const SizedBox(height: 8),
              for (final fact in facts)
                if (fact != null && fact.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(fact, style: muted),
                  ),
              if (tagline case final tagline?)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    tagline,
                    style: muted?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A card section heading.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 8),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

/// The overview, if there is one.
List<Widget> overviewSection(BuildContext context, String? overview) {
  if (overview == null) return const [];
  return [
    SectionTitle(AppLocalizations.of(context).titleOverview),
    Text(overview, style: Theme.of(context).textTheme.bodyMedium),
  ];
}

/// TMDB rating at the end of a list row; nothing if there are no votes.
class TmdbScore extends StatelessWidget {
  const TmdbScore(this.vote, {super.key});

  final TmdbVote vote;

  @override
  Widget build(BuildContext context) {
    final average = vote.average;
    if (average == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: 16, color: theme.colorScheme.outline),
        const SizedBox(width: 2),
        Text(formatScore(average), style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

/// "1999 · 2 h 16 min": facts joined with a dot, empty ones skipped.
String joinFacts(Iterable<String?> parts) =>
    parts.whereType<String>().where((p) => p.isNotEmpty).join(' · ');

/// Two requests as one: an error in either is the screen's error, data comes
/// once both have arrived.
AsyncValue<(A, B)> combineAsync<A, B>(AsyncValue<A> a, AsyncValue<B> b) =>
    switch ((a, b)) {
      (AsyncValue(:final error?, :final stackTrace?), _) ||
      (
        _,
        AsyncValue(:final error?, :final stackTrace?),
      ) => AsyncError(error, stackTrace),
      (AsyncValue(value: final x?), AsyncValue(value: final y?)) => AsyncData((
        x,
        y,
      )),
      _ => const AsyncLoading(),
    };

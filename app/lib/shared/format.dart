import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../data/api_source.dart';
import '../l10n/app_localizations.dart';

/// Formatting for display — only here, at the moment of display.
extension Formatting on BuildContext {
  String get _locale => Localizations.localeOf(this).toLanguageTag();

  /// `YYYY-MM-DD` from an API → "May 1, 2011". A date without a time: built
  /// from its numbers, with no time zone (AGENTS.md, pitfalls).
  String? formatDate(String? ymd) {
    if (ymd == null) return null;
    final parts = ymd.split('-').map(int.tryParse).toList();
    if (parts.length != 3 || parts.contains(null)) return ymd;
    return DateFormat.yMMMd(
      _locale,
    ).format(DateTime(parts[0]!, parts[1]!, parts[2]!));
  }

  /// UTC ms → a short date in local time.
  String formatTimestamp(int millis) => DateFormat.MMMd(
    _locale,
  ).format(DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).toLocal());

  /// 816869 → "817K" / "817 тыс.".
  String formatCount(int count) =>
      NumberFormat.compact(locale: _locale).format(count);

  /// 136 → "2 h 16 min".
  String formatRuntime(int minutes) {
    final l10n = AppLocalizations.of(this);
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    if (hours == 0) return l10n.runtimeMinutes(rest);
    if (rest == 0) return l10n.runtimeHours(hours);
    return l10n.runtimeHoursMinutes(hours, rest);
  }
}

/// A 10-point rating with one decimal: Kinopoisk sends 8.501, TMDB 8.261.
String formatScore(double value) => value.toStringAsFixed(1);

/// Your own score from half points: "8" or "8.5" — the scale goes in steps
/// of 0.5, so a trailing ".0" would only be noise.
String formatMyScore(int scoreHalf) =>
    scoreHalf.isEven ? '${scoreHalf ~/ 2}' : '${scoreHalf ~/ 2}.5';

/// "Mine − theirs" with its sign: "+0.7", "−1.2", "±0". One decimal, like
/// the ratings it is computed from; a true minus sign, not a hyphen.
String formatDivergence(double value) {
  final rounded = (value * 10).round();
  if (rounded == 0) return '±0';
  final digits = (rounded.abs() / 10).toStringAsFixed(1);
  return rounded > 0 ? '+$digits' : '−$digits';
}

/// A rating source's name as the user sees it.
String ratingSourceLabel(AppLocalizations l10n, RatingSource source) =>
    switch (source) {
      RatingSource.kp => l10n.ratingKinopoisk,
      RatingSource.imdb => 'IMDb',
      RatingSource.tmdb => 'TMDB',
      RatingSource.rt => 'Rotten Tomatoes',
      RatingSource.metacritic => 'Metacritic',
    };

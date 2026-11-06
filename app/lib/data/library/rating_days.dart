import 'library_models.dart';

sealed class RatingListItem {
  const RatingListItem();
}

final class RatingDay extends RatingListItem {
  const RatingDay(this.date);
  final DateTime date;
}

final class RatingItem extends RatingListItem {
  const RatingItem(this.title);
  final RatedTitle title;
}

/// UTC at rest, local calendar days at display time. Comparing calendar
/// components also handles daylight-saving days that are not 24 hours long.
List<RatingListItem> ratingDayItems(
  List<RatedTitle> ordered, {
  DateTime Function(int)? toLocal,
}) {
  final items = <RatingListItem>[];
  DateTime? previous;
  for (final title in ordered) {
    final local =
        toLocal?.call(title.rating.scoredAt) ??
        DateTime.fromMillisecondsSinceEpoch(
          title.rating.scoredAt,
          isUtc: true,
        ).toLocal();
    final date = DateTime(local.year, local.month, local.day);
    if (date != previous) {
      items.add(RatingDay(date));
      previous = date;
    }
    items.add(RatingItem(title));
  }
  return items;
}

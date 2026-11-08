import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/library/library.dart';
import '../../data/api_source.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/format.dart';
import '../../shared/score_color.dart';
import '../../shared/title_row.dart';
import '../../shared/title_text.dart';
import '../title/title_routes.dart';

void showRatedWorks(
  BuildContext context,
  String heading,
  List<RatedTitle> titles, {
  RatingSource? compareWith,
}) {
  final router = GoRouter.of(context);
  final branch = TitleRoutes.branchOf(context);
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .75,
      minChildSize: .3,
      maxChildSize: .95,
      builder: (context, controller) => ListView.builder(
        controller: controller,
        itemCount: titles.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '$heading · ${titles.length}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            );
          }
          final title = titles[index - 1];
          final lines = describeRated(AppLocalizations.of(context), title);
          final sourceValue = title.external[compareWith]?.value;
          return TitleRow(
            posterPath: title.posterPath,
            lines: compareWith != null && sourceValue != null
                ? (
                    title: lines.title,
                    subtitle:
                        '${ratingSourceLabel(AppLocalizations.of(context), compareWith)} '
                        '${formatScore(sourceValue)} · ${formatDivergence(title.divergenceFrom(compareWith)!)}',
                  )
                : lines,
            trailing: Text(
              formatMyScore(title.rating.scoreHalf),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: scoreColor(context, title.rating.scoreHalf / 2),
              ),
            ),
            onTap: () {
              Navigator.of(sheetContext).pop();
              router.push('$branch/${TitleRoutes.path(title.key)}');
            },
          );
        },
      ),
    ),
  );
}

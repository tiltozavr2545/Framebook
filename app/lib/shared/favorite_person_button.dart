import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/library/favorite_people.dart';
import '../data/sources/tmdb/tmdb_models.dart';
import '../l10n/app_localizations.dart';

class FavoritePersonButton extends ConsumerStatefulWidget {
  const FavoritePersonButton({super.key, required this.person});
  final PersonSummary person;
  @override
  ConsumerState<FavoritePersonButton> createState() =>
      _FavoritePersonButtonState();
}

class _FavoritePersonButtonState extends ConsumerState<FavoritePersonButton> {
  bool _saving = false;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final saved = ref.watch(isFavoritePersonProvider(widget.person.id));
    final favorite = saved ?? false;
    return IconButton(
      tooltip: favorite ? l10n.peopleRemoveFavorite : l10n.peopleAddFavorite,
      icon: Icon(favorite ? Icons.favorite : Icons.favorite_border),
      color: favorite ? Theme.of(context).colorScheme.primary : null,
      onPressed: _saving || saved == null
          ? null
          : () async {
              final library = ref.read(peopleLibraryProvider);
              setState(() => _saving = true);
              try {
                await library.setFavorite(widget.person, !favorite);
              } on Object {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.peopleFavoriteFailed)),
                  );
                }
              } finally {
                if (mounted) setState(() => _saving = false);
              }
            },
    );
  }
}

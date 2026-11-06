import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/library/favorite_people.dart';
import '../data/sources/tmdb/tmdb_models.dart';
import '../l10n/app_localizations.dart';

class FavoritePersonButton extends ConsumerStatefulWidget {
  const FavoritePersonButton({
    super.key,
    required this.person,
    this.prominent = false,
  });
  final PersonSummary person;
  final bool prominent;
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
    final tooltip = favorite
        ? l10n.peopleRemoveFavorite
        : l10n.peopleAddFavorite;
    final icon = Icon(favorite ? Icons.favorite : Icons.favorite_border);
    final VoidCallback? onPressed = _saving || saved == null
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
          };
    if (widget.prominent) {
      return Semantics(
        toggled: favorite,
        child: Tooltip(
          message: tooltip,
          child: FilledButton.icon(
            onPressed: onPressed,
            icon: icon,
            label: Text(
              favorite ? l10n.peopleInFavorites : l10n.peopleAddFavorite,
            ),
          ),
        ),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: tooltip,
      icon: icon,
      color: favorite ? scheme.primary : null,
      onPressed: onPressed,
    );
  }
}

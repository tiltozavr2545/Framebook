import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/library/favorite_people.dart';
import '../data/sources/tmdb/tmdb_models.dart';
import '../l10n/app_localizations.dart';
import 'poster.dart';

/// Shelf-only double-tap action; the profile uses an explicit full-size button.
class FavoritePersonPortrait extends ConsumerStatefulWidget {
  const FavoritePersonPortrait({
    super.key,
    required this.person,
    required this.onTap,
  });
  final PersonSummary person;
  final VoidCallback onTap;

  @override
  ConsumerState<FavoritePersonPortrait> createState() =>
      _FavoritePersonPortraitState();
}

class _FavoritePersonPortraitState
    extends ConsumerState<FavoritePersonPortrait> {
  bool _saving = false;

  Future<void> _toggle() async {
    final favorite = ref.read(isFavoritePersonProvider(widget.person.id));
    if (_saving || favorite == null) return;
    _saving = true;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final overlay = Overlay.of(context, rootOverlay: true);
    final box = context.findRenderObject()! as RenderBox;
    final bounds =
        box.localToGlobal(
          Offset.zero,
          ancestor: overlay.context.findRenderObject(),
        ) &
        box.size;
    try {
      await ref
          .read(peopleLibraryProvider)
          .setFavorite(widget.person, !favorite);
      if (!messenger.mounted || !overlay.mounted) return;
      late final OverlayEntry feedback;
      feedback = OverlayEntry(
        builder: (_) => Positioned.fromRect(
          rect: bounds,
          child: IgnorePointer(
            child: _HeartFeedback(
              added: !favorite,
              onComplete: () {
                feedback.remove();
                feedback.dispose();
              },
            ),
          ),
        ),
      );
      overlay.insert(feedback);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              favorite
                  ? l10n.peopleFavoriteRemoved(widget.person.name)
                  : l10n.peopleFavoriteAdded(widget.person.name),
            ),
          ),
        );
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.peopleFavoriteFailed)));
      }
    } finally {
      _saving = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final favorite =
        ref.watch(isFavoritePersonProvider(widget.person.id)) ?? false;
    final l10n = AppLocalizations.of(context);
    const shadow = [Shadow(color: Colors.black54, blurRadius: 5)];
    return Semantics(
      toggled: favorite,
      customSemanticsActions: {
        CustomSemanticsAction(
          label: favorite ? l10n.peopleRemoveFavorite : l10n.peopleAddFavorite,
        ): _toggle,
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: _toggle,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Poster(
              widget.person.profilePath,
              size: ImageSize.w185,
              width: 96,
              icon: Icons.person_outline,
            ),
            if (favorite)
              const Positioned(
                right: 6,
                bottom: 6,
                child: IgnorePointer(
                  child: Icon(
                    Icons.favorite,
                    key: ValueKey('favorite-portrait-badge'),
                    size: 22,
                    color: Color(0xB3FFFFFF),
                    shadows: shadow,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Owned by the overlay so removing a favourite shelf row cannot cut it short.
class _HeartFeedback extends StatefulWidget {
  const _HeartFeedback({required this.added, required this.onComplete});
  final bool added;
  final VoidCallback onComplete;
  @override
  State<_HeartFeedback> createState() => _HeartFeedbackState();
}

class _HeartFeedbackState extends State<_HeartFeedback>
    with SingleTickerProviderStateMixin {
  late final _heart = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  @override
  void initState() {
    super.initState();
    _heart.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onComplete();
    });
    unawaited(_heart.forward());
  }

  @override
  void dispose() {
    _heart.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: AnimatedBuilder(
      animation: _heart,
      builder: (context, _) {
        final t = _heart.value;
        final opacity = t < 0.2
            ? t / 0.2
            : t < 0.55
            ? 1.0
            : (1 - t) / 0.45;
        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: MediaQuery.disableAnimationsOf(context)
                ? 1
                : 0.65 +
                      Curves.easeOutBack.transform((t / 0.4).clamp(0.0, 1.0)) *
                          0.35,
            child: Icon(
              widget.added ? Icons.favorite : Icons.heart_broken,
              size: 54,
              color: Colors.white,
              shadows: const [Shadow(color: Colors.black54, blurRadius: 5)],
            ),
          ),
        );
      },
    ),
  );
}

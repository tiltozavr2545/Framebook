import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/work_key.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/field_switcher.dart';

/// The same moving inset selection as Discover, with four title kinds.
class StatsKindSwitcher extends StatefulWidget {
  const StatsKindSwitcher({
    super.key,
    required this.selected,
    required this.onSelected,
  });
  final WorkKind? selected;
  final ValueChanged<WorkKind> onSelected;
  @override
  State<StatsKindSwitcher> createState() => _StatsKindSwitcherState();
}

class _StatsKindSwitcherState extends State<StatsKindSwitcher>
    with SingleTickerProviderStateMixin {
  late final _position = AnimationController.unbounded(
    vsync: this,
    value: (widget.selected?.index ?? 0).toDouble(),
  );
  bool _dragging = false;
  int _dragOrigin = 0;
  int _lastRequested = 0;

  void _animate(int index) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _position.value = index.toDouble();
    } else {
      unawaited(
        _position.animateTo(
          index.toDouble(),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        ),
      );
    }
  }

  void _select(int index) {
    _dragging = false;
    _lastRequested = index;
    widget.onSelected(WorkKind.values[index]);
    _animate(index);
  }

  @override
  void didUpdateWidget(StatsKindSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging && oldWidget.selected != widget.selected) {
      _animate(widget.selected?.index ?? 0);
    }
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: FieldSwitcher(
        keyPrefix: 'stats-kind',
        position: _position,
        selectedIndex: widget.selected?.index ?? 0,
        labels: [
          l10n.kindMovies,
          l10n.kindSeries,
          l10n.kindSeasons,
          l10n.kindEpisodes,
        ],
        onSelected: _select,
        onDragStart: () {
          _dragOrigin = widget.selected?.index ?? 0;
          _lastRequested = _dragOrigin;
          _dragging = true;
          _position.stop();
        },
        onDragUpdate: (delta) {
          _position.value = (_position.value + delta).clamp(0.0, 3.0);
          final index = _position.value.round();
          if (index != _lastRequested) {
            _lastRequested = index;
            widget.onSelected(WorkKind.values[index]);
          }
        },
        onDragEnd: (velocity) => _select(
          (_position.value + (velocity.abs() > 2 ? velocity.sign * .35 : 0))
              .round()
              .clamp(0, 3),
        ),
        onDragCancel: () {
          if (_dragging) {
            _select(_dragOrigin);
          }
        },
      ),
    );
  }
}

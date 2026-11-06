import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../shared/glass_selection.dart';

/// An inset field, aligned and sized like the search editor above it.
class SearchModeSwitcher extends StatelessWidget {
  const SearchModeSwitcher({
    super.key,
    required this.position,
    required this.selectedIndex,
    required this.labels,
    required this.onSelected,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDragCancel,
  });

  final AnimationController position;
  final int selectedIndex;
  final List<String> labels;
  final ValueChanged<int> onSelected;
  final VoidCallback onDragStart;
  final ValueChanged<double> onDragUpdate;
  final ValueChanged<double> onDragEnd;
  final VoidCallback onDragCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final slot = constraints.maxWidth / labels.length;
        final rtl = Directionality.of(context) == TextDirection.rtl;
        final style = theme.textTheme.bodyLarge!;
        var height = 56.0;
        for (final label in labels) {
          final painter = TextPainter(
            text: TextSpan(
              text: label,
              style: style.copyWith(fontWeight: FontWeight.w600),
            ),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
            maxLines: 2,
          )..layout(maxWidth: math.max(1, slot - 24));
          height = math.max(height, painter.height + 24);
          painter.dispose();
        }
        return GestureDetector(
          key: const ValueKey('search-mode-slider'),
          onHorizontalDragStart: (_) => onDragStart(),
          onHorizontalDragUpdate: (details) =>
              onDragUpdate(details.delta.dx / slot * (rtl ? -1 : 1)),
          onHorizontalDragEnd: (details) =>
              onDragEnd((details.primaryVelocity ?? 0) / slot * (rtl ? -1 : 1)),
          onHorizontalDragCancel: onDragCancel,
          child: Container(
            height: height,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color:
                  theme.navigationBarTheme.backgroundColor ??
                  scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: position,
                  builder: (context, _) => PositionedDirectional(
                    start: position.value * slot + 4,
                    width: slot - 8,
                    top: 4,
                    bottom: 4,
                    child: const GlassSelection(radius: 8),
                  ),
                ),
                Row(
                  children: [
                    for (var index = 0; index < labels.length; index++)
                      Expanded(
                        child: Semantics(
                          selected: selectedIndex == index,
                          child: SizedBox.expand(
                            child: TextButton(
                              key: ValueKey('search-mode-$index'),
                              style:
                                  TextButton.styleFrom(
                                    foregroundColor: selectedIndex == index
                                        ? scheme.onSurface
                                        : scheme.onSurfaceVariant,
                                    textStyle: style.copyWith(
                                      fontWeight: selectedIndex == index
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    splashFactory: NoSplash.splashFactory,
                                  ).copyWith(
                                    overlayColor: const WidgetStatePropertyAll(
                                      Colors.transparent,
                                    ),
                                  ),
                              onPressed: () => onSelected(index),
                              child: Text(
                                labels[index],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Keep each mode's scroll position while translating only the content below.
class SearchModePages extends StatefulWidget {
  const SearchModePages({
    super.key,
    required this.position,
    required this.selectedIndex,
    required this.children,
  });
  final AnimationController position;
  final int selectedIndex;
  final List<Widget> children;
  @override
  State<SearchModePages> createState() => _SearchModePagesState();
}

class _SearchModePagesState extends State<SearchModePages> {
  final _visited = <int>{};
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.position,
    builder: (context, _) {
      final position = widget.position.value;
      final direction = Directionality.of(context) == TextDirection.rtl
          ? -1
          : 1;
      return ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            for (var index = 0; index < widget.children.length; index++)
              _page(index, position, direction),
          ],
        ),
      );
    },
  );

  Widget _page(int index, double position, int direction) {
    final visible = (position - index).abs() < 1;
    if (visible) _visited.add(index);
    return Offstage(
      offstage: !visible,
      child: TickerMode(
        enabled: visible,
        child: ExcludeFocus(
          excluding: index != widget.selectedIndex,
          child: IgnorePointer(
            ignoring: position != index || index != widget.selectedIndex,
            child: FractionalTranslation(
              translation: Offset((index - position) * direction, 0),
              child: _visited.contains(index)
                  ? widget.children[index]
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}

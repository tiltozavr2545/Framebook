import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'glass_selection.dart';

/// An inset mode field with a moving glass selection and adaptive labels.
class FieldSwitcher extends StatelessWidget {
  const FieldSwitcher({
    super.key,
    required this.keyPrefix,
    required this.position,
    required this.selectedIndex,
    required this.labels,
    required this.onSelected,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDragCancel,
  });

  final String keyPrefix;
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
        final style = labels.length > 2
            ? theme.textTheme.labelLarge!
            : theme.textTheme.bodyLarge!;
        final labelPadding = labels.length > 2 ? 4.0 : 12.0;
        var height = 56.0;
        for (final label in labels) {
          final painter =
              TextPainter(
                text: TextSpan(
                  text: label,
                  style: style.copyWith(fontWeight: FontWeight.w600),
                ),
                textDirection: Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context),
                maxLines: labels.length > 2 ? 1 : 2,
              )..layout(
                maxWidth: labels.length > 2
                    ? double.infinity
                    : math.max(1, slot - labelPadding * 2),
              );
          height = math.max(height, painter.height + 24);
          painter.dispose();
        }
        return GestureDetector(
          key: ValueKey('$keyPrefix-slider'),
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
                              key: ValueKey('$keyPrefix-$index'),
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
                                    padding: EdgeInsets.symmetric(
                                      horizontal: labelPadding,
                                    ),
                                    splashFactory: NoSplash.splashFactory,
                                  ).copyWith(
                                    overlayColor: const WidgetStatePropertyAll(
                                      Colors.transparent,
                                    ),
                                  ),
                              onPressed: () => onSelected(index),
                              child: labels.length > 2
                                  ? FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(labels[index], maxLines: 1),
                                    )
                                  : Text(
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

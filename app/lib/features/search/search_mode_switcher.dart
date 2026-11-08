import 'package:flutter/material.dart';

import '../../shared/field_switcher.dart';

/// Discover's two-mode version of the shared inset switcher.
class SearchModeSwitcher extends FieldSwitcher {
  const SearchModeSwitcher({
    super.key,
    required super.position,
    required super.selectedIndex,
    required super.labels,
    required super.onSelected,
    required super.onDragStart,
    required super.onDragUpdate,
    required super.onDragEnd,
    required super.onDragCancel,
  }) : super(keyPrefix: 'search-mode');
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

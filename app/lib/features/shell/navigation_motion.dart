import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/glass_selection.dart';

/// Shared by the bar and branch container so a drag moves both in one frame.
class NavigationMotion extends InheritedWidget {
  const NavigationMotion({
    super.key,
    required this.position,
    required this.enabled,
    required super.child,
  });

  final AnimationController position;
  final bool enabled;

  static NavigationMotion of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NavigationMotion>()!;

  @override
  bool updateShouldNotify(NavigationMotion oldWidget) =>
      enabled != oldWidget.enabled || position != oldWidget.position;
}

/// Mount branches on first display and retain their independent back stacks.
class NavigationPages extends StatefulWidget {
  const NavigationPages({
    super.key,
    required this.shell,
    required this.children,
  });
  final StatefulNavigationShell shell;
  final List<Widget> children;

  @override
  State<NavigationPages> createState() => _NavigationPagesState();
}

class _NavigationPagesState extends State<NavigationPages> {
  final _visited = <int>{};

  @override
  Widget build(BuildContext context) {
    final motion = NavigationMotion.of(context);
    return AnimatedBuilder(
      animation: motion.position,
      builder: (context, _) {
        final position = motion.enabled
            ? motion.position.value
            : widget.shell.currentIndex.toDouble();
        final direction = Directionality.of(context) == TextDirection.ltr
            ? 1
            : -1;
        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              for (var i = 0; i < widget.children.length; i++)
                _branch(i, position, direction),
            ],
          ),
        );
      },
    );
  }

  Widget _branch(int index, double position, int direction) {
    final visible = (index - position).abs() < 1;
    if (visible || index == widget.shell.currentIndex) _visited.add(index);
    return Offstage(
      offstage: !visible,
      child: TickerMode(
        enabled: visible,
        child: ExcludeFocus(
          excluding: index != widget.shell.currentIndex,
          child: IgnorePointer(
            ignoring: index != widget.shell.currentIndex || position != index,
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

/// A bounded blur and a fine highlight give the moving selection a glass rim.
class GlassNavigationBar extends StatelessWidget {
  const GlassNavigationBar({
    super.key,
    required this.position,
    required this.selectedIndex,
    required this.destinations,
    required this.onSelected,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDragCancel,
  });

  final AnimationController position;
  final int selectedIndex;
  final List<NavigationDestination> destinations;
  final ValueChanged<int> onSelected;
  final VoidCallback onDragStart;
  final ValueChanged<double> onDragUpdate;
  final ValueChanged<double> onDragEnd;
  final VoidCallback onDragCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final background =
        theme.navigationBarTheme.backgroundColor ?? scheme.surfaceContainerLow;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.55),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final slot = constraints.maxWidth / destinations.length;
              final rtl = Directionality.of(context) == TextDirection.rtl;
              return GestureDetector(
                key: const ValueKey('glass-navigation'),
                onHorizontalDragStart: (_) => onDragStart(),
                onHorizontalDragUpdate: (details) =>
                    onDragUpdate(details.delta.dx / slot * (rtl ? -1 : 1)),
                onHorizontalDragEnd: (details) =>
                    onDragEnd(details.primaryVelocity! / slot * (rtl ? -1 : 1)),
                onHorizontalDragCancel: onDragCancel,
                child: Stack(
                  children: [
                    AnimatedBuilder(
                      animation: position,
                      builder: (context, _) => PositionedDirectional(
                        start: position.value * slot + 5,
                        top: 5,
                        bottom: 5,
                        width: slot - 10,
                        child: const GlassSelection(radius: 25),
                      ),
                    ),
                    Theme(
                      data: theme.copyWith(
                        splashFactory: NoSplash.splashFactory,
                        highlightColor: Colors.transparent,
                      ),
                      child: NavigationBar(
                        animationDuration: Duration.zero,
                        overlayColor: const WidgetStatePropertyAll(
                          Colors.transparent,
                        ),
                        backgroundColor: Colors.transparent,
                        surfaceTintColor: Colors.transparent,
                        indicatorColor: Colors.transparent,
                        elevation: 0,
                        selectedIndex: selectedIndex,
                        onDestinationSelected: onSelected,
                        destinations: destinations,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/widgets.dart';

/// Defers a feed's replacement until its current scroll activity ends.
/// Descendant consumers (for example favourite buttons) remain reactive.
class ScrollStableContent extends StatefulWidget {
  const ScrollStableContent({super.key, required this.child});
  final Widget child;

  @override
  State<ScrollStableContent> createState() => _ScrollStableContentState();
}

class _ScrollStableContentState extends State<ScrollStableContent> {
  late Widget _shown = widget.child;
  final _active = <BuildContext?>{};

  @override
  void didUpdateWidget(ScrollStableContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_active.isEmpty) _shown = widget.child;
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      _active.add(notification.context);
    }
    if (notification is ScrollEndNotification) {
      _active.remove(notification.context);
      if (_active.isEmpty && !identical(_shown, widget.child)) {
        setState(() => _shown = widget.child);
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: _shown,
      );
}

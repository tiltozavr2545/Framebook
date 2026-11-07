import 'package:flutter/widgets.dart';

/// Fixed-width slots avoid estimating variable child extents during scrolling.
/// Stable keys also preserve mounted tile state when a feed changes its order.
class HorizontalShelf extends StatelessWidget {
  const HorizontalShelf({
    super.key,
    required this.itemKeys,
    required this.itemWidth,
    required this.itemBuilder,
    this.spacing = 12,
    this.horizontalPadding = 20,
  }) : assert(horizontalPadding >= spacing);

  final List<Object> itemKeys;
  final double itemWidth;
  final IndexedWidgetBuilder itemBuilder;
  final double spacing;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final indices = {
      for (var i = 0; i < itemKeys.length; i++)
        ValueKey<Object>(itemKeys[i]): i,
    };
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      primary: false,
      padding: EdgeInsetsDirectional.only(
        start: horizontalPadding,
        end: horizontalPadding - spacing,
      ),
      itemExtent: itemWidth + spacing,
      itemCount: itemKeys.length,
      findChildIndexCallback: (key) => indices[key],
      itemBuilder: (context, index) => KeyedSubtree(
        key: ValueKey<Object>(itemKeys[index]),
        child: Padding(
          padding: EdgeInsetsDirectional.only(end: spacing),
          child: itemBuilder(context, index),
        ),
      ),
    );
  }
}

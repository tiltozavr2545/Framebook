import 'package:flutter/widgets.dart';

/// Retains a visited section in a bounded page of independently loaded sections.
/// Do not use for individual rows in an unbounded list.
class RetainedSection extends StatefulWidget {
  const RetainedSection({super.key, required this.child});
  final Widget child;
  @override
  State<RetainedSection> createState() => _RetainedSectionState();
}

class _RetainedSectionState extends State<RetainedSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

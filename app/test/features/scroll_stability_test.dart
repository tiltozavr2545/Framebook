import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/features/title/title_layout.dart';
import 'package:framebook/shared/poster_tint.dart';
import 'package:framebook/shared/retained_section.dart';
import 'package:framebook/shared/scroll_stable_content.dart';
import 'package:framebook/shared/horizontal_shelf.dart';

class _Probe extends StatefulWidget {
  const _Probe(this.onMount, {super.key});
  final VoidCallback onMount;
  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    widget.onMount();
  }

  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: 120, child: Text('loaded section'));
}

void main() {
  testWidgets('shelves build lazily and preserve tile state when reordered', (
    tester,
  ) async {
    final keys = ValueNotifier(List.generate(50, (i) => i));
    final mounts = <int, int>{};
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 180,
            child: ValueListenableBuilder<List<int>>(
              valueListenable: keys,
              builder: (_, ids, _) => HorizontalShelf(
                itemKeys: ids,
                itemWidth: 96,
                itemBuilder: (_, i) => _Probe(
                  () => mounts.update(ids[i], (n) => n + 1, ifAbsent: () => 1),
                  key: ValueKey('probe-${ids[i]}'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(mounts.length, lessThan(20));
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable));
    scroll.position.jumpTo(1080);
    await tester.pumpAndSettle();
    final before = tester.state<_ProbeState>(
      find.byKey(const ValueKey('probe-10')),
    );
    final reordered = [...keys.value];
    reordered[10] = 11;
    reordered[11] = 10;
    keys.value = reordered;
    await tester.pumpAndSettle();
    expect(
      tester.state<_ProbeState>(find.byKey(const ValueKey('probe-10'))),
      same(before),
    );
    expect(mounts[10], 1);
    await tester.pumpWidget(const SizedBox());
    keys.dispose();
  });

  testWidgets('feed changes wait for the vertical or horizontal drag to end', (
    tester,
  ) async {
    for (final axis in Axis.values) {
      final label = ValueNotifier('old');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<String>(
              valueListenable: label,
              builder: (_, value, _) => ScrollStableContent(
                child: ListView(
                  scrollDirection: axis,
                  children: [
                    SizedBox(width: 2400, height: 2400, child: Text(value)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      final gesture = await tester.startGesture(const Offset(250, 250));
      await gesture.moveBy(
        axis == Axis.vertical ? const Offset(0, -70) : const Offset(-70, 0),
      );
      await tester.pump();
      label.value = 'new';
      await tester.pump();
      expect(find.text('old'), findsOneWidget);
      expect(find.text('new'), findsNothing);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('new'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      label.dispose();
    }
  });

  testWidgets('poster tint never changes header geometry', (tester) async {
    final color = Completer<Color?>();
    const contentKey = ValueKey('header-content');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          posterTintProvider.overrideWith((ref, path) => color.future),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: PosterTint(
              path: '/poster',
              child: SizedBox(key: contentKey, width: 200, height: 100),
            ),
          ),
        ),
      ),
    );
    final before = tester.getRect(find.byKey(contentKey));
    color.complete(Colors.blue);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(contentKey)), before);
  });

  testWidgets('card sections survive scrolling outside the viewport', (
    tester,
  ) async {
    var mounts = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: TitlePage<int>(
            value: const AsyncData(1),
            onRetry: () {},
            builder: (_, _) => [
              RetainedSection(child: _Probe(() => mounts++)),
              const SizedBox(height: 2400),
              const Text('bottom'),
            ],
          ),
        ),
      ),
    );
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable));
    scroll.position.jumpTo(scroll.position.maxScrollExtent);
    await tester.pumpAndSettle();
    scroll.position.jumpTo(0);
    await tester.pumpAndSettle();
    expect(find.text('loaded section'), findsOneWidget);
    expect(mounts, 1);
    await tester.pumpWidget(const SizedBox());
  });
}

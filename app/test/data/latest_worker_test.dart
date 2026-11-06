import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/latest_worker.dart';

void main() {
  test(
    'only the latest queued input runs after an active computation',
    () async {
      final gate = Completer<int>();
      final calls = <int>[];
      final worker = LatestWorker<int, int>((value) {
        calls.add(value);
        return value == 1 ? gate.future : Future.value(value);
      });
      final first = worker.run(1);
      await pumpEventQueue();
      final obsolete = worker.run(2);
      final last = worker.run(3);
      expect(calls, [1]);
      gate.complete(1);
      expect(await first, 1);
      expect(await obsolete, isNull);
      expect(await last, 3);
      expect(calls, [1, 3]);
      worker.dispose();
      expect(await worker.run(4), isNull);
    },
  );

  test('a failed computation does not poison subsequent requests', () async {
    final worker = LatestWorker<int, int>((value) async {
      if (value == 1) throw StateError('failed');
      return value;
    });
    await expectLater(worker.run(1), throwsStateError);
    expect(await worker.run(2), 2);
    worker.dispose();
  });
}

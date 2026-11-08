import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/distinct_stream.dart';

void main() {
  test(
    'unchanged data after an error still publishes successful recovery',
    () async {
      final source = StreamController<int>();
      final events = <Object>[];
      final subscription = distinctData(
        source.stream,
        (a, b) => a == b,
      ).listen(events.add, onError: (Object error) => events.add(error));
      final failure = StateError('Unavailable');
      source.add(1);
      source.add(1);
      source.addError(failure);
      source.add(1);
      source.add(1);
      await source.close();
      expect(events, [1, failure, 1]);
      await subscription.cancel();
    },
  );

  test(
    'broadcast subscribers keep independent first and previous values',
    () async {
      final source = StreamController<int>.broadcast();
      final stream = distinctData(source.stream, (a, b) => a == b);
      expect(stream.isBroadcast, isTrue);
      final first = <int>[];
      final second = <int>[];
      final a = stream.listen(first.add);
      source.add(1);
      await pumpEventQueue();
      final b = stream.listen(second.add);
      source.add(1);
      source.add(2);
      source.add(2);
      await source.close();
      expect(first, [1, 2]);
      expect(second, [1, 2]);
      await a.cancel();
      await b.cancel();
    },
  );

  test('canceling the consumer cancels upstream work', () async {
    var canceled = false;
    final source = StreamController<int>(onCancel: () => canceled = true);
    final subscription = distinctData(
      source.stream,
      (a, b) => a == b,
    ).listen((_) {});
    await subscription.cancel();
    expect(canceled, isTrue);
    await source.close();
  });
}

import 'dart:async';

/// Serialize expensive work and skip queued requests superseded by newer input.
/// Running isolates may finish, but rapid updates never spawn parallel workers.
final class LatestWorker<Input, Output> {
  LatestWorker(this.compute);
  final Future<Output> Function(Input) compute;
  Future<void> _tail = Future.value();
  int _revision = 0;
  bool _disposed = false;

  Future<Output?> run(Input input) {
    final revision = ++_revision;
    final result = _tail.then<Output?>((_) async {
      if (_disposed || revision != _revision) return null;
      return await compute(input);
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  void dispose() {
    _disposed = true;
    _revision++;
  }
}

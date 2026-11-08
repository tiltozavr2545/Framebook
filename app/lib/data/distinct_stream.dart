import 'dart:async';

/// Suppress unchanged data, but always publish recovery after a stream error.
/// Each subscription owns its previous value, including on broadcast streams.
Stream<T> distinctData<T>(Stream<T> source, bool Function(T, T) equals) =>
    Stream<T>.eventTransformed(
      source,
      (sink) => _DistinctDataSink<T>(sink, equals),
    );

class _DistinctDataSink<T> implements EventSink<T> {
  _DistinctDataSink(this.sink, this.equals);
  final EventSink<T> sink;
  final bool Function(T, T) equals;
  T? _previous;
  bool _hasPrevious = false;

  @override
  void add(T data) {
    try {
      if (_hasPrevious && equals(_previous as T, data)) return;
    } on Object catch (error, stack) {
      addError(error, stack);
      return;
    }
    _previous = data;
    _hasPrevious = true;
    sink.add(data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _previous = null;
    _hasPrevious = false;
    sink.addError(error, stackTrace);
  }

  @override
  void close() {
    _previous = null;
    sink.close();
  }
}

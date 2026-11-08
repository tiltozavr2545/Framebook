/// Serialize one preference's writes and retain its last successful value.
/// Failed earlier writes must not replace a newer optimistic selection.
class PreferenceWrites<T> {
  PreferenceWrites(this._persisted);
  T _persisted;
  Future<void> _tail = Future.value();
  int _revision = 0;

  Future<void> save(
    T value,
    Future<bool> Function() write,
    void Function(T) rollback,
  ) {
    final revision = ++_revision;
    final operation = _tail.then((_) async {
      try {
        if (!await write()) throw StateError('Could not save preference');
        _persisted = value;
      } on Object {
        if (revision == _revision) rollback(_persisted);
        rethrow;
      }
    });
    _tail = operation.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return operation;
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Scheduling boundary for pure view preparation; widget tests replace only
/// scheduling, while worker tests exercise actual isolate transfer.
abstract class ViewComputer {
  const ViewComputer();
  Future<O> run<I, O>(ComputeCallback<I, O> callback, I input, String label);
}

class _IsolateComputer extends ViewComputer {
  const _IsolateComputer();
  @override
  Future<O> run<I, O>(ComputeCallback<I, O> callback, I input, String label) =>
      compute(callback, input, debugLabel: label);
}

final viewComputerProvider = Provider<ViewComputer>(
  (ref) => const _IsolateComputer(),
);

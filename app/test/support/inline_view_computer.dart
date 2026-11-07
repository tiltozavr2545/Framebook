import 'package:flutter/foundation.dart';
import 'package:framebook/data/view_computer.dart';

/// Keep virtual-clock widget tests deterministic without changing algorithms.
class InlineViewComputer extends ViewComputer {
  const InlineViewComputer();
  @override
  Future<O> run<I, O>(
    ComputeCallback<I, O> callback,
    I input,
    String label,
  ) async => callback(input);
}

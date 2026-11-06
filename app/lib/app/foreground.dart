import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared foreground boundary for optional catalog enrichment.
class Foreground extends Notifier<bool> {
  @override
  bool build() {
    final lifecycle = AppLifecycleListener(
      onStateChange: (value) => state = value == AppLifecycleState.resumed,
    );
    ref.onDispose(lifecycle.dispose);
    final initial = WidgetsBinding.instance.lifecycleState;
    return initial == null || initial == AppLifecycleState.resumed;
  }
}

final foregroundProvider = NotifierProvider<Foreground, bool>(Foreground.new);

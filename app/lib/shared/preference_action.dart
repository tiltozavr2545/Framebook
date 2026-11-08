import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Keep a failed preference write recoverable after an optimistic UI change.
Future<void> savePreference(
  BuildContext context,
  Future<void> Function() save,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final message = AppLocalizations.of(context).recommendationsSaveFailed;
  try {
    await save();
  } on Object {
    if (messenger.mounted) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'api_keys_form.dart';

class SourcesScreen extends StatelessWidget {
  const SourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sourcesTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [ApiKeysForm()],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/api_keys.dart';
import '../../data/api_source.dart';
import '../../data/key_validator.dart';
import '../../l10n/app_localizations.dart';

/// Пошаговая инструкция по ключам — та же, что в репозитории.
final apiKeysGuideUrl = Uri.parse(
  'https://github.com/tiltozavr2545/Framebook/blob/main/docs/api-keys.md',
);

/// Ввод и проверка ключей всех источников. Общий для онбординга и
/// «Настройки → Источники».
class ApiKeysForm extends StatelessWidget {
  const ApiKeysForm({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: Text(l10n.sourcesHowToGet),
            onPressed: () => launchUrl(
              apiKeysGuideUrl,
              mode: LaunchMode.externalApplication,
            ),
          ),
        ),
        for (final source in ApiSource.values) ...[
          _KeyCard(source: source),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

enum _Status { missing, empty, checking, valid, limit, unverified, invalid }

class _KeyCard extends ConsumerStatefulWidget {
  const _KeyCard({required this.source});

  final ApiSource source;

  @override
  ConsumerState<_KeyCard> createState() => _KeyCardState();
}

class _KeyCardState extends ConsumerState<_KeyCard> {
  late final TextEditingController _controller;
  late _Status _status;
  bool _obscured = true;

  ApiSource get _source => widget.source;

  @override
  void initState() {
    super.initState();
    final stored = ref.read(apiKeysProvider)[_source];
    _controller = TextEditingController(text: stored?.value ?? '');
    _status = switch (stored) {
      null => _Status.missing,
      StoredKey(verified: true) => _Status.valid,
      StoredKey(verified: false) => _Status.unverified,
    };
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _status = _Status.empty);
      return;
    }
    setState(() => _status = _Status.checking);
    // Всё из ref — до await: после него экран может быть уже закрыт, и ref
    // бросит (AGENTS.md, «Грабли»).
    final keys = ref.read(apiKeysProvider.notifier);
    final validator = ref.read(keyValidatorProvider);

    final result = await validator.check(_source, value);
    final status = switch (result) {
      KeyCheck.valid => _Status.valid,
      KeyCheck.limitReached => _Status.limit,
      KeyCheck.offline => _Status.unverified,
      KeyCheck.invalid => _Status.invalid,
    };
    if (status != _Status.invalid) {
      await keys.save(
        _source,
        StoredKey(value, verified: status != _Status.unverified),
      );
    }
    if (!mounted) return;
    setState(() => _status = status);
  }

  Future<void> _remove() async {
    await ref.read(apiKeysProvider.notifier).remove(_source);
    if (!mounted) return;
    _controller.clear();
    setState(() => _status = _Status.missing);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final stored = ref.watch(apiKeysProvider).has(_source);
    final required = _source == ApiSource.tmdb;
    final (name, description, hint) = switch (_source) {
      ApiSource.tmdb => (
        l10n.sourceTmdbName,
        l10n.sourceTmdbDescription,
        l10n.sourceTmdbHint,
      ),
      ApiSource.poiskkino => (
        l10n.sourcePoiskkinoName,
        l10n.sourcePoiskkinoDescription,
        l10n.sourcePoiskkinoHint,
      ),
      ApiSource.omdb => (
        l10n.sourceOmdbName,
        l10n.sourceOmdbDescription,
        l10n.sourceOmdbHint,
      ),
    };
    final checking = _status == _Status.checking;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(name, style: theme.textTheme.titleMedium),
                const SizedBox(width: 8),
                Text(
                  required ? l10n.sourceRequired : l10n.sourceOptional,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: required
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              obscureText: _obscured,
              autocorrect: false,
              enableSuggestions: false,
              enabled: !checking,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: hint,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscured ? Icons.visibility : Icons.visibility_off,
                  ),
                  tooltip: _obscured ? l10n.keyShow : l10n.keyHide,
                  onPressed: () => setState(() => _obscured = !_obscured),
                ),
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 8),
            _StatusLine(status: _status),
            const SizedBox(height: 8),
            Row(
              children: [
                FilledButton.tonal(
                  onPressed: checking ? null : _save,
                  child: Text(l10n.keySave),
                ),
                if (stored) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: checking ? null : _remove,
                    child: Text(l10n.keyRemove),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.status});

  final _Status status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final (icon, color, text) = switch (status) {
      _Status.missing => (
        Icons.remove_circle_outline,
        colors.outline,
        l10n.keyStatusMissing,
      ),
      _Status.empty => (Icons.info_outline, colors.error, l10n.keyStatusEmpty),
      _Status.checking => (
        Icons.hourglass_empty,
        colors.outline,
        l10n.keyStatusChecking,
      ),
      _Status.valid => (
        Icons.check_circle_outline,
        colors.primary,
        l10n.keyStatusValid,
      ),
      _Status.limit => (
        Icons.check_circle_outline,
        colors.tertiary,
        l10n.keyStatusLimit,
      ),
      _Status.unverified => (
        Icons.cloud_off,
        colors.tertiary,
        l10n.keyStatusUnverified,
      ),
      _Status.invalid => (
        Icons.error_outline,
        colors.error,
        l10n.keyStatusInvalid,
      ),
    };
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

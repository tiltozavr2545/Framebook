import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/preferences.dart';
import '../../app/router.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/preference_action.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.key_outlined),
            title: Text(l10n.settingsSources),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.sources),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_sync_outlined),
            title: Text(l10n.settingsSync),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.sync),
          ),
          const Divider(),
          _SettingsChoice(
            leading: const Icon(Icons.view_day_outlined),
            title: Text(l10n.settingsNavigationStyle),
            selection: DropdownButton<bool>(
              isExpanded: true,
              itemHeight: null,
              value: ref.watch(floatingNavigationProvider),
              underline: const SizedBox.shrink(),
              onChanged: (floating) {
                if (floating != null) {
                  savePreference(
                    context,
                    () => ref
                        .read(floatingNavigationProvider.notifier)
                        .set(floating),
                  );
                }
              },
              items: [
                DropdownMenuItem(
                  value: true,
                  child: Text(l10n.navigationFloating),
                ),
                DropdownMenuItem(
                  value: false,
                  child: Text(l10n.navigationClassic),
                ),
              ],
            ),
          ),
          _SettingsChoice(
            leading: const Icon(Icons.language),
            title: Text(l10n.settingsLanguage),
            selection: DropdownButton<String>(
              isExpanded: true,
              itemHeight: null,
              value: locale?.languageCode ?? '',
              underline: const SizedBox.shrink(),
              onChanged: (code) => savePreference(
                context,
                () => ref
                    .read(localeProvider.notifier)
                    .set(code == null || code.isEmpty ? null : Locale(code)),
              ),
              items: [
                DropdownMenuItem(value: '', child: Text(l10n.languageSystem)),
                DropdownMenuItem(
                  value: 'en',
                  child: Text(l10n.languageEnglish),
                ),
                DropdownMenuItem(
                  value: 'ru',
                  child: Text(l10n.languageRussian),
                ),
              ],
            ),
          ),
          _SettingsChoice(
            leading: const Icon(Icons.brightness_6_outlined),
            title: Text(l10n.settingsTheme),
            selection: DropdownButton<ThemeMode>(
              isExpanded: true,
              itemHeight: null,
              value: themeMode,
              underline: const SizedBox.shrink(),
              onChanged: (mode) {
                if (mode != null) {
                  savePreference(
                    context,
                    () => ref.read(themeModeProvider.notifier).set(mode),
                  );
                }
              },
              items: [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text(l10n.themeSystem),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text(l10n.themeLight),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text(l10n.themeDark),
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.aboutTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.about),
          ),
        ],
      ),
    );
  }
}

/// Use a row at normal text sizes and let accessibility text grow vertically.
class _SettingsChoice extends StatelessWidget {
  const _SettingsChoice({
    required this.leading,
    required this.title,
    required this.selection,
  });

  final Widget leading;
  final Widget title;
  final Widget selection;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme.titleMedium!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconTheme.merge(
            data: IconThemeData(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            child: leading,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final scaledSize = MediaQuery.textScalerOf(
                  context,
                ).scale(text.fontSize!);
                final stacked =
                    constraints.maxWidth < 220 ||
                    scaledSize > text.fontSize! * 1.3;
                final label = DefaultTextStyle(style: text, child: title);
                return stacked
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [label, selection],
                      )
                    : Row(
                        children: [
                          Expanded(child: label),
                          const SizedBox(width: 16),
                          Expanded(child: selection),
                        ],
                      );
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'theme.dart';

/// Initialization failures stay recoverable without clearing user data.
class StartupApp extends StatefulWidget {
  const StartupApp({super.key, required this.load});
  final Future<Widget> Function() load;
  @override
  State<StartupApp> createState() => _StartupAppState();
}

class _StartupAppState extends State<StartupApp> {
  late Future<Widget> _loading = Future.sync(widget.load);
  @override
  Widget build(BuildContext context) => FutureBuilder<Widget>(
    future: _loading,
    builder: (context, snapshot) {
      if (snapshot.hasData) return snapshot.data!;
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: FramebookTheme.light,
        darkTheme: FramebookTheme.dark,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SafeArea(
            child: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: snapshot.hasError
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l10n.startupFailed,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: () => setState(() {
                                  _loading = Future.sync(widget.load);
                                }),
                                child: Text(l10n.retry),
                              ),
                            ],
                          )
                        : const CircularProgressIndicator(),
                  ),
                );
              },
            ),
          ),
        ),
      );
    },
  );
}

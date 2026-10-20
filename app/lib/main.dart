import 'package:flutter/material.dart';

// Этап 0: только скелет, чтобы проверить сборку, CI и установку APK.
// Шелл с вкладками, локализация и тема — Этап 1
// (docs/implementation-plan.md).
void main() {
  runApp(const FramebookApp());
}

class FramebookApp extends StatelessWidget {
  const FramebookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Framebook',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.dark,
        ),
      ),
      home: const Scaffold(body: Center(child: Text('Framebook'))),
    );
  }
}

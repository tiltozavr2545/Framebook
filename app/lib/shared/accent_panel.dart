import 'package:flutter/material.dart';

/// The static violet frame shared by person headers and featured actions.
BoxDecoration accentPanelDecoration(BuildContext context) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  return BoxDecoration(
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: scheme.primary.withValues(alpha: 0.65)),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.alphaBlend(
          scheme.primary.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.38 : 0.24,
          ),
          scheme.surface,
        ),
        scheme.surface,
      ],
    ),
  );
}

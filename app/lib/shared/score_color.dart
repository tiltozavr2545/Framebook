import 'package:flutter/material.dart';

/// A shared ten-point scale. Percentages must be divided by ten first.
Color scoreColor(BuildContext context, double score) =>
    scoreColorFor(Theme.of(context).brightness, score);

Color scoreColorFor(Brightness brightness, double score) {
  final dark = brightness == Brightness.dark;
  if (score < 4) {
    return dark ? const Color(0xFFFF8C82) : const Color(0xFFB3261E);
  }
  if (score <= 6.5) {
    return dark ? const Color(0xFFECC36A) : const Color(0xFF805900);
  }
  return dark ? const Color(0xFF82D9A4) : const Color(0xFF187044);
}

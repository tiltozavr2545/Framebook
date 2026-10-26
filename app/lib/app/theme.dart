import 'package:flutter/material.dart';

// The look is an editing table: a cool lightbox, ink, film stock, and the
// editor's grease pencil — red is *your* mark (your score, your actions) and
// nothing else. Everything else stays quiet so that the score carousel, the
// one bold element, carries the identity (docs/client-architecture.md,
// "Design").

/// The two typefaces: one superfamily, two widths. Extra Condensed is for
/// figures and titles — tall narrow numerals like edge print on film and
/// marquee letters; the normal width is for reading.
abstract final class Fonts {
  static const text = 'Sofia Sans';
  static const display = 'Sofia Sans Extra Condensed';
}

/// Colours outside the Material scheme: the film strip of the score carousel
/// and the edge-print amber of secondary figures.
@immutable
class Reel extends ThemeExtension<Reel> {
  const Reel({
    required this.strip,
    required this.sprocket,
    required this.frame,
    required this.onFrame,
    required this.gate,
    required this.edge,
  });

  /// The film base the frames sit on.
  final Color strip;

  /// The perforation holes, seen through to the lightbox.
  final Color sprocket;

  /// A frame outside the gate, and the figure printed on it.
  final Color frame;
  final Color onFrame;

  /// The frame in the gate: lit by the lightbox.
  final Color gate;

  /// Edge-print amber: years, vote counts, the as-of dates.
  final Color edge;

  static Reel of(BuildContext context) => Theme.of(context).extension<Reel>()!;

  @override
  Reel copyWith({
    Color? strip,
    Color? sprocket,
    Color? frame,
    Color? onFrame,
    Color? gate,
    Color? edge,
  }) => Reel(
    strip: strip ?? this.strip,
    sprocket: sprocket ?? this.sprocket,
    frame: frame ?? this.frame,
    onFrame: onFrame ?? this.onFrame,
    gate: gate ?? this.gate,
    edge: edge ?? this.edge,
  );

  @override
  Reel lerp(Reel? other, double t) => other == null
      ? this
      : Reel(
          strip: Color.lerp(strip, other.strip, t)!,
          sprocket: Color.lerp(sprocket, other.sprocket, t)!,
          frame: Color.lerp(frame, other.frame, t)!,
          onFrame: Color.lerp(onFrame, other.onFrame, t)!,
          gate: Color.lerp(gate, other.gate, t)!,
          edge: Color.lerp(edge, other.edge, t)!,
        );
}

abstract final class FramebookTheme {
  // Light: the lightbox.
  static const _lightbox = Color(0xFFF2F4F3);
  static const _ink = Color(0xFF1A2027);
  static const _film = Color(0xFF2B3038);
  static const _grease = Color(0xFFD33A2C);
  static const _muted = Color(0xFF6B737C);

  static final light = _build(
    const ColorScheme(
      brightness: Brightness.light,
      primary: _grease,
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFFBDAD5),
      onPrimaryContainer: Color(0xFF5A110A),
      secondary: _film,
      onSecondary: _lightbox,
      secondaryContainer: Color(0xFFDCE1E0),
      onSecondaryContainer: _ink,
      tertiary: Color(0xFF8A5A00),
      onTertiary: Color(0xFFFFFFFF),
      error: Color(0xFF9C2F5E),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFF6D9E4),
      onErrorContainer: Color(0xFF3F0A22),
      surface: _lightbox,
      onSurface: _ink,
      onSurfaceVariant: Color(0xFF4E5660),
      surfaceContainerLowest: Color(0xFFFAFBFA),
      surfaceContainerLow: Color(0xFFE9ECEB),
      surfaceContainer: Color(0xFFE3E7E6),
      surfaceContainerHigh: Color(0xFFDCE1E0),
      surfaceContainerHighest: Color(0xFFD4DAD9),
      outline: _muted,
      outlineVariant: Color(0xFFC5CBCA),
      inverseSurface: _film,
      onInverseSurface: Color(0xFFE4E8EA),
      inversePrimary: Color(0xFFFF8A7A),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
    ),
    const Reel(
      strip: _film,
      sprocket: _lightbox,
      frame: Color(0xFF3A4049),
      onFrame: Color(0xFFB9C0C6),
      gate: Color(0xFFFDFDFB),
      edge: Color(0xFF8A5A00),
    ),
  );

  // Dark: the editing room with the lights down.
  static final dark = _build(
    const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFFF6A57),
      onPrimary: Color(0xFF2A0A06),
      primaryContainer: Color(0xFF6B1B12),
      onPrimaryContainer: Color(0xFFFFDAD4),
      secondary: Color(0xFFC9D1D6),
      onSecondary: Color(0xFF171B20),
      secondaryContainer: Color(0xFF323941),
      onSecondaryContainer: Color(0xFFE4E8EA),
      tertiary: Color(0xFFE3A93B),
      onTertiary: Color(0xFF2B1B00),
      error: Color(0xFFF08DB4),
      onError: Color(0xFF3F0A22),
      errorContainer: Color(0xFF5E1736),
      onErrorContainer: Color(0xFFFFD9E6),
      surface: Color(0xFF171B20),
      onSurface: Color(0xFFE4E8EA),
      onSurfaceVariant: Color(0xFFA9B1B9),
      surfaceContainerLowest: Color(0xFF111418),
      surfaceContainerLow: Color(0xFF1D2228),
      surfaceContainer: Color(0xFF22282F),
      surfaceContainerHigh: Color(0xFF2A3038),
      surfaceContainerHighest: Color(0xFF323941),
      outline: Color(0xFF7D868F),
      outlineVariant: Color(0xFF3A424B),
      inverseSurface: Color(0xFFE4E8EA),
      onInverseSurface: Color(0xFF1A2027),
      inversePrimary: _grease,
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
    ),
    const Reel(
      strip: Color(0xFF0D1013),
      sprocket: Color(0xFF2A3038),
      frame: Color(0xFF1D2228),
      onFrame: Color(0xFF8C959E),
      gate: Color(0xFFEDEFEA),
      edge: Color(0xFFE3A93B),
    ),
  );

  /// The type scale: display and headline sizes in Extra Condensed, the rest
  /// in the normal width. Body text gets air (1.45) for notes and overviews.
  static TextTheme _text(Color ink) {
    TextStyle display(double size, FontWeight weight, double height) =>
        TextStyle(
          fontFamily: Fonts.display,
          fontSize: size,
          fontWeight: weight,
          height: height,
          letterSpacing: 0,
          color: ink,
        );
    TextStyle text(
      double size,
      FontWeight weight,
      double height, {
      double spacing = 0,
    }) => TextStyle(
      fontFamily: Fonts.text,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: spacing,
      color: ink,
    );
    return TextTheme(
      displayLarge: display(80, FontWeight.w800, 0.95),
      displayMedium: display(56, FontWeight.w800, 1),
      displaySmall: display(40, FontWeight.w700, 1.05),
      headlineLarge: display(36, FontWeight.w700, 1.05),
      headlineMedium: display(30, FontWeight.w700, 1.1),
      headlineSmall: display(26, FontWeight.w700, 1.1),
      titleLarge: text(20, FontWeight.w600, 1.25),
      titleMedium: text(16, FontWeight.w600, 1.3),
      titleSmall: text(14, FontWeight.w600, 1.3),
      bodyLarge: text(16, FontWeight.w400, 1.45),
      bodyMedium: text(14, FontWeight.w400, 1.45),
      bodySmall: text(12.5, FontWeight.w400, 1.4),
      labelLarge: text(14, FontWeight.w600, 1.2, spacing: 0.1),
      labelMedium: text(12, FontWeight.w500, 1.2, spacing: 0.2),
      labelSmall: text(11, FontWeight.w500, 1.2, spacing: 0.3),
    );
  }

  static ThemeData _build(ColorScheme scheme, Reel reel) {
    final text = _text(scheme.onSurface);
    return ThemeData(
      colorScheme: scheme,
      fontFamily: Fonts.text,
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      extensions: [reel],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.headlineMedium,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.secondaryContainer,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      // Your actions are red; a secondary action is ink on the lightbox.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: text.labelLarge,
          minimumSize: const Size(64, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          textStyle: text.labelLarge,
          minimumSize: const Size(64, 44),
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: text.labelLarge),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: text.labelLarge,
        // A selected chip is film-dark; its label is printed light on it.
        secondaryLabelStyle: text.labelLarge?.copyWith(
          color: scheme.onSecondary,
        ),
        selectedColor: scheme.secondary,
        secondarySelectedColor: scheme.secondary,
        checkmarkColor: scheme.onSecondary,
        showCheckmark: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.onSurface, width: 1.5),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: text.headlineSmall,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      listTileTheme: ListTileThemeData(
        titleTextStyle: text.titleMedium,
        subtitleTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.onSurface,
        linearTrackColor: scheme.surfaceContainerHighest,
      ),
    );
  }
}

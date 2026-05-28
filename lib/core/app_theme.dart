import 'package:flutter/material.dart';

// ─── Color verde primario (mismo en ambos temas) ───────────────────────────
const Color kVerde     = Color(0xFF1D9E75);
const Color kVerdeDark = Color(0xFF0F6E56);
const Color kVerdeLight= Color(0xFF5DCAA5);

class AppTheme {
  AppTheme._();

  // ── Tema OSCURO (como está ahora) ────────────────────────────────────────
  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary:    Color(0xFF1D9E75),
      secondary:  Color(0xFF5DCAA5),
      surface:    Color(0xFF1E1E1E),
      error:      Color(0xFFE24B4A),
    ),
    scaffoldBackgroundColor: const Color(0xFF111111),
    cardColor: const Color(0xFF1E1E1E),
    dividerColor: const Color(0xFF2A2A2A),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF111111),
      foregroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? kVerde : const Color(0xFF888780)),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
              ? kVerde.withOpacity(0.4)
              : const Color(0xFF2A2A2A)),
    ),
    textTheme: const TextTheme(
      bodyLarge:  TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
      bodySmall:  TextStyle(color: Colors.white54),
    ),
    extensions: const [DispersaludColors.dark],
  );

  // ── Tema CLARO ────────────────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary:    Color(0xFF0F6E56),
      secondary:  Color(0xFF1D9E75),
      surface:    Color(0xFFF5F5F5),
      error:      Color(0xFFE24B4A),
    ),
    scaffoldBackgroundColor: const Color(0xFFF0F0F0),
    cardColor: Colors.white,
    dividerColor: const Color(0xFFE0E0E0),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0F6E56),
      foregroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? const Color(0xFF0F6E56) : Colors.white),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
              ? const Color(0xFF0F6E56).withOpacity(0.4)
              : const Color(0xFFCCCCCC)),
    ),
    textTheme: const TextTheme(
      bodyLarge:  TextStyle(color: Color(0xFF1A1A1A)),
      bodyMedium: TextStyle(color: Color(0xFF444444)),
      bodySmall:  TextStyle(color: Color(0xFF888888)),
    ),
    extensions: const [DispersaludColors.light],
  );
}

// ─── Colores semánticos adaptativos ───────────────────────────────────────
// Úsalos con: Theme.of(context).extension<DispersaludColors>()!
class DispersaludColors extends ThemeExtension<DispersaludColors> {
  final Color bg;       // Fondo principal
  final Color card;     // Fondo de tarjetas
  final Color border;   // Bordes
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;

  const DispersaludColors({
    required this.bg,
    required this.card,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
  });

  static const dark = DispersaludColors(
    bg:            Color(0xFF111111),
    card:          Color(0xFF1E1E1E),
    border:        Color(0xFF2A2A2A),
    textPrimary:   Colors.white,
    textSecondary: Color(0xFFCCCCCC),
    textHint:      Color(0xFF888780),
  );

  static const light = DispersaludColors(
    bg:            Color(0xFFF0F0F0),
    card:          Colors.white,
    border:        Color(0xFFE0E0E0),
    textPrimary:   Color(0xFF1A1A1A),
    textSecondary: Color(0xFF444444),
    textHint:      Color(0xFF888888),
  );

  @override
  DispersaludColors copyWith({
    Color? bg, Color? card, Color? border,
    Color? textPrimary, Color? textSecondary, Color? textHint,
  }) => DispersaludColors(
    bg:            bg            ?? this.bg,
    card:          card          ?? this.card,
    border:        border        ?? this.border,
    textPrimary:   textPrimary   ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textHint:      textHint      ?? this.textHint,
  );

  @override
  DispersaludColors lerp(DispersaludColors? other, double t) {
    if (other == null) return this;
    return DispersaludColors(
      bg:            Color.lerp(bg,            other.bg,            t)!,
      card:          Color.lerp(card,          other.card,          t)!,
      border:        Color.lerp(border,        other.border,        t)!,
      textPrimary:   Color.lerp(textPrimary,   other.textPrimary,   t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textHint:      Color.lerp(textHint,      other.textHint,      t)!,
    );
  }
}
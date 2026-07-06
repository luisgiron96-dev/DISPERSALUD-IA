// lib/core/responsive.dart
// ════════════════════════════════════════════════════════════════════════════
//  DISPERSALUD IA — Utilidades de diseño adaptativo (responsive)
//
//  Puntos de quiebre (estándar Material 3):
//   • < 600px   → Celular   (compact)
//   • 600–900px → Tablet    (medium)
//   • > 900px   → Escritorio (expanded)
//
//  Uso típico:
//    if (context.isDesktop) { ... }
//    ResponsiveCenter(child: miContenido)
// ════════════════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';

class Breakpoints {
  Breakpoints._();
  static const double tablet   = 600;
  static const double desktop  = 900;
  // Ancho máximo de contenido en pantallas muy grandes (evita que las
  // tarjetas/listas se estiren feo en monitores ultra-anchos).
  static const double maxContentWidth = 1100;
}

enum TipoPantalla { movil, tablet, escritorio }

extension ResponsiveContext on BuildContext {
  double get anchoPantalla => MediaQuery.of(this).size.width;

  TipoPantalla get tipoPantalla {
    final w = anchoPantalla;
    if (w >= Breakpoints.desktop) return TipoPantalla.escritorio;
    if (w >= Breakpoints.tablet)  return TipoPantalla.tablet;
    return TipoPantalla.movil;
  }

  bool get isMovil     => tipoPantalla == TipoPantalla.movil;
  bool get isTablet    => tipoPantalla == TipoPantalla.tablet;
  bool get isDesktop   => tipoPantalla == TipoPantalla.escritorio;
  // true para tablet o escritorio — útil para "¿muestro menú lateral?"
  bool get isAnchoGrande => anchoPantalla >= Breakpoints.tablet;
}

/// Centra el contenido y le pone un ancho máximo en pantallas grandes.
/// En celular se comporta exactamente igual que antes (ancho completo).
///
/// Además, en tablet/escritorio aumenta un poco el tamaño de letra: los
/// textos de la app se diseñaron en tamaños pequeños pensados para
/// celular (10-14px), y aunque el ancho ya no se estira, en un monitor
/// grande esos mismos píxeles se ven diminutos. Este aumento aplica sobre
/// el ajuste de fuente que el usuario ya tenga configurado en Ajustes
/// (no lo reemplaza, se compone con él).
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.maxContentWidth,
    this.padding,
    this.escalarTexto = true,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  // Poner en `false` en alguna pantalla puntual si el aumento de letra
  // llega a desbordar algún recuadro de tamaño fijo muy ajustado.
  final bool escalarTexto;

  @override
  Widget build(BuildContext context) {
    Widget contenido = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    );

    if (escalarTexto) {
      final ancho = MediaQuery.sizeOf(context).width;
      double extra = 1.0;
      if (ancho >= Breakpoints.desktop) {
        extra = 1.15;
      } else if (ancho >= Breakpoints.tablet) {
        extra = 1.08;
      }
      if (extra != 1.0) {
        // Se compone con el escalado de fuente que el usuario ya tenga
        // elegido en Ajustes (no lo pisa, multiplica sobre él).
        final actual = MediaQuery.textScalerOf(context).scale(100) / 100;
        contenido = MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(actual * extra)),
          child: contenido,
        );
      }
    }

    return Center(
      child: padding != null
          ? Padding(padding: padding!, child: contenido)
          : contenido,
    );
  }
}

/// Calcula cuántas columnas usar en un GridView según el ancho disponible.
/// [base] es el número de columnas en celular (el que ya tenías).
int columnasResponsivas(
  double ancho, {
  int base = 2,
  int tablet = 3,
  int escritorio = 4,
}) {
  if (ancho >= Breakpoints.desktop) return escritorio;
  if (ancho >= Breakpoints.tablet)  return tablet;
  return base;
}

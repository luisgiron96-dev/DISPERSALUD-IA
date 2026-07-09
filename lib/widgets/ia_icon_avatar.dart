// lib/widgets/ia_icon_avatar.dart
// ════════════════════════════════════════════════════════════════════════════
// IaIconAvatar — badge circular reutilizable con el ícono oficial de
// DISPERSALUD IA (assets/icono_partera.png). Se usa en encabezados de
// tarjetas, botones de acción y paneles de chat en cualquier pantalla
// (Partera, Saberes Ancestrales, Dashboard, etc.) para que la marca de la
// IA sea siempre la misma. Si la imagen no está disponible, cae a un ícono
// de Material como respaldo.
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

class IaIconAvatar extends StatelessWidget {
  /// Diámetro total del avatar circular.
  final double size;

  /// Color de fondo del círculo. Por defecto blanco (resalta el ícono).
  final Color background;

  /// Ícono de respaldo si `assets/icono_partera.png` no carga.
  final IconData iconoRespaldo;

  /// Color del ícono de respaldo.
  final Color colorRespaldo;

  /// Sombra opcional (útil cuando el avatar "flota" sobre el contenido).
  final bool sombra;

  const IaIconAvatar({
    super.key,
    this.size = 36,
    this.background = Colors.white,
    this.iconoRespaldo = Icons.smart_toy_rounded,
    this.colorRespaldo = const Color(0xFF1D9E75),
    this.sombra = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: background,
        boxShadow: sombra
            ? [
                BoxShadow(
                  color: colorRespaldo.withOpacity(0.35),
                  blurRadius: size * 0.3,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: Padding(
          padding: EdgeInsets.all(size * 0.1),
          child: Image.asset(
            'assets/icono_partera.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              iconoRespaldo,
              color: colorRespaldo,
              size: size * 0.55,
            ),
          ),
        ),
      ),
    );
  }
}
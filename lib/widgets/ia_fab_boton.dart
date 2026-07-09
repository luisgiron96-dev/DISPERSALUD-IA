// lib/widgets/ia_fab_boton.dart
// ════════════════════════════════════════════════════════════════════════════
// IaFabBoton — botón flotante circular, animado y dinámico de DISPERSALUD IA.
// Reutiliza la misma mecánica visual del asistente en el Dashboard (flota
// suavemente, pulsa con un aura de color, cambia entre ícono/"X" y muestra
// un punto de estado online/offline), pero usando el ícono oficial
// `assets/icono_partera.png`. Pensado para usarse como floatingActionButton
// en cualquier pantalla (Partera, Saberes Ancestrales, etc.).
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

class IaFabBoton extends StatefulWidget {
  /// Acción al tocar el botón (normalmente alterna un panel de chat/IA).
  final VoidCallback onTap;

  /// true = el panel asociado está abierto (se muestra una "X" para cerrar).
  final bool abierto;

  /// true = hay conexión (punto verde), false = sin conexión (punto naranja).
  final bool online;

  /// Diámetro del círculo principal (sin contar el aura).
  final double size;

  /// Colores del degradado cuando el panel está abierto (modo "cerrar").
  final Color colorPrincipal;
  final Color colorSecundario;

  const IaFabBoton({
    super.key,
    required this.onTap,
    this.abierto = false,
    this.online = true,
    this.size = 58,
    this.colorPrincipal = const Color(0xFF6C3CE0),
    this.colorSecundario = const Color(0xFF3A1D6E),
  });

  @override
  State<IaFabBoton> createState() => _IaFabBotonState();
}

class _IaFabBotonState extends State<IaFabBoton>
    with TickerProviderStateMixin {
  late final AnimationController _flotarCtrl;
  late final AnimationController _pulsoCtrl;
  late final Animation<double> _flotar;
  late final Animation<double> _pulso;

  @override
  void initState() {
    super.initState();

    // Movimiento flotante suave arriba/abajo.
    _flotarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _flotar = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _flotarCtrl, curve: Curves.easeInOut),
    );

    // Aura pulsante alrededor del ícono.
    _pulsoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulso = Tween<double>(begin: 0.9, end: 1.08).animate(
      CurvedAnimation(parent: _pulsoCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flotarCtrl.dispose();
    _pulsoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auraSize = widget.size + 18;
    return AnimatedBuilder(
      animation: Listenable.merge([_flotarCtrl, _pulsoCtrl]),
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _flotar.value),
        child: GestureDetector(
          onTap: widget.onTap,
          child: SizedBox(
            width: auraSize,
            height: auraSize,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // ── Aura pulsante ─────────────────────────────────────
                Transform.scale(
                  scale: _pulso.value,
                  child: Container(
                    width: auraSize,
                    height: auraSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        widget.colorPrincipal.withOpacity(0.35),
                        widget.colorPrincipal.withOpacity(0.0),
                      ]),
                    ),
                  ),
                ),

                // ── Círculo principal (ícono / cerrar) ────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: widget.abierto
                      ? Container(
                          key: const ValueKey('cerrar'),
                          width: widget.size,
                          height: widget.size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                widget.colorPrincipal,
                                widget.colorSecundario
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: widget.colorPrincipal.withOpacity(0.5),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.close_rounded,
                              color: Colors.white, size: 26),
                        )
                      : Container(
                          key: const ValueKey('mascota'),
                          width: widget.size,
                          height: widget.size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: widget.colorPrincipal.withOpacity(0.5),
                                blurRadius: 16,
                                spreadRadius: 1,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Padding(
                              padding: EdgeInsets.all(widget.size * 0.1),
                              child: Image.asset(
                                'assets/icono_partera.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.smart_toy_rounded,
                                  color: widget.colorPrincipal,
                                  size: widget.size * 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                ),

                // ── Punto de estado online/offline ────────────────────
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.online
                          ? const Color(0xFF2ECC71)
                          : const Color(0xFFEF9F27),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
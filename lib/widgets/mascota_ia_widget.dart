// ignore_for_file: use_build_context_synchronously
// lib/widgets/mascota_ia_widget.dart
// Mascota animada DISPERSALUD IA — reemplaza el FAB simple del asistente
// ════════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'package:flutter/material.dart';

// ── Frases que dice la mascota según el contexto ──────────────────────────
const _kFrasesBienvenida = [
  '¡Hola! ¿En qué te ayudo hoy? 🌿',
  '¡Listo para ayudarte! 💚',
  '¿Tienes una consulta? ¡Pregúntame! 🩺',
  '¡Aquí estoy, promotor/a! 👋',
  '¿Cómo puedo apoyarte hoy? 🌱',
];

const _kFrasesEspera = [
  'Pensando... 🤔',
  'Consultando mis conocimientos... 📚',
  'Analizando la información... 🔍',
  'Un momento... ⏳',
];

const _kFrasesRespuesta = [
  '¡Aquí tienes! 😊',
  'Espero que te ayude 💚',
  'Recuerda: ante duda, remite 🏥',
  '¡Con mucho gusto! 🌿',
];

// ════════════════════════════════════════════════════════════════════════════
// WIDGET PRINCIPAL — MascotaIAWidget
// Úsalo como floatingActionButton en cualquier Scaffold
// ════════════════════════════════════════════════════════════════════════════

class MascotaIAWidget extends StatefulWidget {
  /// Callback que se ejecuta al tocar la mascota
  final VoidCallback onTap;

  /// Si la IA está procesando una respuesta
  final bool cargando;

  /// Frase personalizada (null = usa frases aleatorias)
  final String? frasePersonalizada;

  /// Posición del panel de chat: true = chat visible arriba
  final bool chatVisible;

  const MascotaIAWidget({
    super.key,
    required this.onTap,
    this.cargando = false,
    this.frasePersonalizada,
    this.chatVisible = false,
  });

  @override
  State<MascotaIAWidget> createState() => _MascotaIAWidgetState();
}

class _MascotaIAWidgetState extends State<MascotaIAWidget>
    with TickerProviderStateMixin {

  // ── Animaciones ────────────────────────────────────────────────────────
  late AnimationController _flotarCtrl;   // movimiento flotante suave
  late AnimationController _pulsoCtrl;    // pulso del aura verde
  late AnimationController _saludoCtrl;   // animación de saludo (mano)
  late AnimationController _burbujaCtrl;  // aparición burbuja de texto
  late AnimationController _cargandoCtrl; // rotación cuando procesa

  late Animation<double> _flotar;
  late Animation<double> _pulso;
  late Animation<double> _saludo;
  late Animation<double> _burbuja;
  late Animation<double> _cargando;

  bool _mostrarBurbuja = false;
  String _fraseActual = _kFrasesBienvenida[0];
  final _rng = math.Random();

  @override
  void initState() {
    super.initState();

    // Flotar suave arriba y abajo
    _flotarCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _flotar = Tween<double>(begin: -6, end: 6).animate(
        CurvedAnimation(parent: _flotarCtrl, curve: Curves.easeInOut));

    // Pulso del aura
    _pulsoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _pulso = Tween<double>(begin: 0.85, end: 1.05).animate(
        CurvedAnimation(parent: _pulsoCtrl, curve: Curves.easeInOut));

    // Saludo al iniciar
    _saludoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _saludo = Tween<double>(begin: 0, end: 0.15).animate(
        CurvedAnimation(parent: _saludoCtrl, curve: Curves.elasticOut));

    // Burbuja de texto
    _burbujaCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _burbuja = CurvedAnimation(parent: _burbujaCtrl, curve: Curves.easeOut);

    // Rotación cuando está cargando
    _cargandoCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 1))
      ..repeat();
    _cargando = Tween<double>(begin: 0, end: 2 * math.pi).animate(_cargandoCtrl);

    // Saludo inicial automático
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _ejecutarSaludo();
    });

    // Burbuja periódica
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _mostrarFrasePeriodica();
    });
  }

  void _ejecutarSaludo() {
    _saludoCtrl.forward().then((_) =>
        _saludoCtrl.reverse());
  }

  void _mostrarFrasePeriodica() async {
    if (!mounted || widget.chatVisible) return;
    _fraseActual = _kFrasesBienvenida[_rng.nextInt(_kFrasesBienvenida.length)];
    setState(() => _mostrarBurbuja = true);
    await _burbujaCtrl.forward();
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      await _burbujaCtrl.reverse();
      if (mounted) setState(() => _mostrarBurbuja = false);
    }
    // Repetir cada 12 segundos
    Future.delayed(const Duration(seconds: 12), () {
      if (mounted && !widget.chatVisible) _mostrarFrasePeriodica();
    });
  }

  void _alTocar() {
    _ejecutarSaludo();
    if (!widget.chatVisible) {
      _fraseActual = _kFrasesBienvenida[_rng.nextInt(_kFrasesBienvenida.length)];
      setState(() => _mostrarBurbuja = true);
      _burbujaCtrl.forward();
      Future.delayed(const Duration(seconds: 2), () async {
        if (mounted) {
          await _burbujaCtrl.reverse();
          if (mounted) setState(() => _mostrarBurbuja = false);
        }
      });
    }
    widget.onTap();
  }

  @override
  void didUpdateWidget(MascotaIAWidget old) {
    super.didUpdateWidget(old);
    // Cuando cambia el estado de carga, actualizar la frase
    if (widget.cargando && !old.cargando) {
      _fraseActual = _kFrasesEspera[_rng.nextInt(_kFrasesEspera.length)];
      setState(() => _mostrarBurbuja = true);
      _burbujaCtrl.forward();
    } else if (!widget.cargando && old.cargando) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _fraseActual = _kFrasesRespuesta[_rng.nextInt(_kFrasesRespuesta.length)];
          setState(() {});
        }
      });
      Future.delayed(const Duration(seconds: 2), () async {
        if (mounted) {
          await _burbujaCtrl.reverse();
          if (mounted) setState(() => _mostrarBurbuja = false);
        }
      });
    }
    if (widget.frasePersonalizada != null &&
        widget.frasePersonalizada != old.frasePersonalizada) {
      _fraseActual = widget.frasePersonalizada!;
    }
  }

  @override
  void dispose() {
    _flotarCtrl.dispose();
    _pulsoCtrl.dispose();
    _saludoCtrl.dispose();
    _burbujaCtrl.dispose();
    _cargandoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _alTocar,
      child: SizedBox(
        width: 90,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [

            // ── Burbuja de texto ──────────────────────────────────────────
            if (_mostrarBurbuja)
              FadeTransition(
                opacity: _burbuja,
                child: ScaleTransition(
                  scale: _burbuja,
                  alignment: Alignment.bottomRight,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 180),
                    margin: const EdgeInsets.only(bottom: 6, right: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B2A1A),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14),
                        bottomLeft: Radius.circular(14),
                        bottomRight: Radius.circular(4),
                      ),
                      border: Border.all(
                          color: const Color(0xFF1D9E75).withOpacity(0.6),
                          width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1D9E75).withOpacity(0.2),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Text(
                      widget.frasePersonalizada ?? _fraseActual,
                      style: const TextStyle(
                        color: Color(0xFFB9F5D8),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),

            // ── Mascota animada ───────────────────────────────────────────
            AnimatedBuilder(
              animation: Listenable.merge([
                _flotarCtrl, _pulsoCtrl, _saludoCtrl, _cargandoCtrl,
              ]),
              builder: (_, __) {
                return Transform.translate(
                  offset: Offset(0, _flotar.value),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [

                      // Aura verde pulsante
                      ScaleTransform(
                        scale: _pulso.value,
                        child: Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFF1D9E75).withOpacity(0.35),
                                const Color(0xFF1D9E75).withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Anillo exterior giratorio (solo cuando carga)
                      if (widget.cargando)
                        Transform.rotate(
                          angle: _cargando.value,
                          child: Container(
                            width: 70, height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF2ECC71).withOpacity(0.6),
                                width: 2,
                              ),
                            ),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Container(
                                width: 8, height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2ECC71),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Imagen del personaje con sombra
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1D9E75).withOpacity(0.4),
                              blurRadius: 16,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Container(
                            color: const Color(0xFF0B1F14),
                            child: Image.asset(
                              'assets/mascota_ia.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  // Fallback si la imagen no está aún
                                  Container(
                                color: const Color(0xFF1D9E75).withOpacity(0.2),
                                child: const Icon(
                                    Icons.smart_toy_rounded,
                                    color: Color(0xFF2ECC71),
                                    size: 32),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Indicador de estado (verde = listo, naranja = offline)
                      Positioned(
                        bottom: 2, right: 2,
                        child: Container(
                          width: 14, height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.cargando
                                ? const Color(0xFFEF9F27)
                                : const Color(0xFF2ECC71),
                            border: Border.all(
                                color: const Color(0xFF0A130B), width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // ── Etiqueta debajo ───────────────────────────────────────────
            const SizedBox(height: 4),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B2A1A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFF1D9E75).withOpacity(0.4)),
                ),
                child: Text(
                  widget.chatVisible ? 'Cerrar' : 'Disper IA',
                  style: const TextStyle(
                    color: Color(0xFF2ECC71),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helper para Transform.scale sin widget separado ──────────────────────
class ScaleTransform extends StatelessWidget {
  final double scale;
  final Widget child;
  const ScaleTransform({super.key, required this.scale, required this.child});

  @override
  Widget build(BuildContext context) =>
      Transform.scale(scale: scale, child: child);
}
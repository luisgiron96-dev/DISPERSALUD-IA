import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../services/connectivity_service.dart';

// ─── Colores base (el modo claro se calcula desde el tema) ───────────────────
const Color _kVerde = Color(0xFF1D9E75);
const Color _kRojo  = Color(0xFFE24B4A);

class PinScreen extends StatefulWidget {
  const PinScreen({super.key});
  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> with TickerProviderStateMixin {

  static const _kPinKey  = 'dispersalud_pin';
  static const _kFotoKey = 'promotor_foto';

  final _storage   = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true));

  bool   _cargando   = true;
  bool   _creandoPin = false;
  bool   _confirmar  = false;
  bool   _biometria  = false;
  bool   _online     = false;

  String _pinIngresado = '';
  String _pinTemporal  = '';
  String _error        = '';
  String _nombre       = '';
  String _fotoPath     = '';

  StreamSubscription<bool>? _connSub;

  // Animaciones
  late AnimationController _shakeCtrl;
  late Animation<double>   _shakeAnim;
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();

    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -8.0),  weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0),   weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0),    weight: 1),
    ]).animate(_shakeCtrl);

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.88, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _iniciar();
    _initConectividad();
  }

  Future<void> _initConectividad() async {
    final v = await ConnectivityService.instance.verificarAhora();
    if (mounted) setState(() => _online = v);
    _connSub = ConnectivityService.instance.cambios.listen((v) {
      if (mounted) setState(() => _online = v);
    });
  }

  Future<void> _iniciar() async {
    final prefs       = await SharedPreferences.getInstance();
    final pinGuardado = await _storage.read(key: _kPinKey);
    final tieneBio    = await _verificarBiometria();

    if (!mounted) return;
    setState(() {
      _nombre     = prefs.getString('promotor_nombre') ?? '';
      _fotoPath   = prefs.getString(_kFotoKey)         ?? '';
      _creandoPin = pinGuardado == null;
      _biometria  = tieneBio;
      _cargando   = false;
    });

    // Auto-disparar huella si ya tiene PIN y biometría disponible
    if (pinGuardado != null && tieneBio) {
      await Future.delayed(const Duration(milliseconds: 700));
      _autenticarHuella();
    }
  }

  Future<bool> _verificarBiometria() async {
    if (kIsWeb) return false;
    try {
      // local_auth solo disponible en móvil
      return false; // Se activa en móvil con plugin nativo
    } catch (_) { return false; }
  }

  Future<void> _autenticarHuella() async {
    // Biometría manejada por plugin nativo en móvil
    // En web no está disponible
    if (kIsWeb) return;
    _mostrarError('Huella no disponible. Usa tu PIN.');
  }

  void _presionarTecla(String v) {
    if (_pinIngresado.length >= 4) return;
    HapticFeedback.lightImpact();
    setState(() { _pinIngresado += v; _error = ''; });
    if (_pinIngresado.length == 4)
      Future.delayed(const Duration(milliseconds: 150), _evaluarPin);
  }

  void _borrar() {
    if (_pinIngresado.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() =>
        _pinIngresado = _pinIngresado.substring(0, _pinIngresado.length - 1));
  }

  Future<void> _evaluarPin() async {
    if (_creandoPin) {
      if (!_confirmar) {
        setState(() {
          _pinTemporal = _pinIngresado; _pinIngresado = ''; _confirmar = true;
        });
      } else {
        if (_pinIngresado == _pinTemporal) {
          await _storage.write(key: _kPinKey, value: _pinIngresado);
          if (mounted) _entrarApp();
        } else {
          _mostrarError('Los PINs no coinciden. Intenta de nuevo.');
          setState(() {
            _pinIngresado = ''; _pinTemporal = ''; _confirmar = false;
          });
        }
      }
    } else {
      final guardado = await _storage.read(key: _kPinKey);
      if (_pinIngresado == guardado) {
        if (mounted) _entrarApp();
      } else {
        _mostrarError('PIN incorrecto. Intenta de nuevo.');
        setState(() => _pinIngresado = '');
      }
    }
  }

  void _mostrarError(String msg) {
    HapticFeedback.mediumImpact();
    setState(() => _error = msg);
    _shakeCtrl.forward(from: 0);
  }

  void _entrarApp() {
    HapticFeedback.heavyImpact();
    Navigator.of(context).pushReplacementNamed('/home');
  }

  void _accesoEmergencia() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF0F1E20) : Colors.white;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.medical_services_outlined, color: _kRojo, size: 20),
          const SizedBox(width: 8),
          Text('Acceso de emergencia',
              style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                  fontSize: 15)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            'Si olvidaste tu PIN puedes restablecerlo. '
            'Esto elimina el PIN guardado y podrás crear uno nuevo.',
            style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black54,
                fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _kRojo.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kRojo.withOpacity(0.3)),
            ),
            child: const Row(children: [
              Icon(Icons.warning_amber_rounded, color: _kRojo, size: 16),
              SizedBox(width: 8),
              Expanded(child: Text('Los datos de pacientes NO se eliminarán.',
                  style: TextStyle(color: _kRojo,
                      fontSize: 11, fontWeight: FontWeight.w600))),
            ]),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar',
                style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kRojo,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.pop(context);
              await _storage.delete(key: _kPinKey);
              if (mounted) setState(() {
                _creandoPin = true; _confirmar = false;
                _pinIngresado = ''; _pinTemporal = ''; _error = '';
              });
            },
            child: const Text('Restablecer PIN',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _shakeCtrl.dispose(); _pulseCtrl.dispose(); _connSub?.cancel();
    super.dispose();
  }

  String get _titulo => _creandoPin
      ? (_confirmar ? 'Confirmar PIN' : 'Crear PIN')
      : 'Ingresa tu PIN';

  String get _subtitulo => _creandoPin
      ? (_confirmar
          ? 'Repite los 4 dígitos para confirmar'
          : 'Elige un PIN de 4 dígitos para proteger la app')
      : 'Ingresa tu PIN de 4 dígitos';

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        backgroundColor: Color(0xFF050D0F),
        body: Center(child: CircularProgressIndicator(color: _kVerde)),
      );
    }

    // ── Colores adaptados al tema ─────────────────────────────────────────
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final bgColor  = isDark ? const Color(0xFF050D0F) : const Color(0xFFF4F7F6);
    final cardColor= isDark ? const Color(0xFF0F1E20) : Colors.white;
    final borderC  = isDark ? const Color(0xFF1D9E7540) : const Color(0xFF1D9E7530);
    final textPrim = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final textSec  = isDark ? Colors.white54 : Colors.black45;
    final textHint = isDark ? Colors.white30 : Colors.black26;
    final ecgColor = _kVerde.withOpacity(isDark ? 0.07 : 0.12);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(children: [

        // ── Fondo ECG decorativo ──────────────────────────────────────────
        Positioned.fill(child: CustomPaint(
            painter: _EcgPainter(color: ecgColor))),

        // ── Contenido principal — LayoutBuilder para nunca hacer overflow ─
        SafeArea(
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              // Decidimos si hay suficiente espacio para elementos grandes
              final alto = constraints.maxHeight;
              final compacto = alto < 650;

              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: alto),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(children: [

                        SizedBox(height: compacto ? 12 : 20),

                        // ── Logo + nombre app ─────────────────────────
                        ClipOval(
                          child: Image.asset('assets/logo_dispersalud.png',
                            width: compacto ? 36 : 44,
                            height: compacto ? 36 : 44,
                            fit: BoxFit.cover)),
                        SizedBox(height: compacto ? 4 : 6),
                        Text('DISPERSALUD IA',
                            style: TextStyle(color: textSec, fontSize: 12,
                                fontWeight: FontWeight.bold, letterSpacing: 2)),
                        Text('SALUD RURAL SIN INTERNET',
                            style: TextStyle(color: textHint, fontSize: 8,
                                letterSpacing: 1.5)),

                        SizedBox(height: compacto ? 12 : 18),

                        // ── Avatar — foto real o logo ─────────────────
                        _AvatarFoto(
                          fotoPath: _fotoPath,
                          size: compacto ? 64.0 : 76.0,
                        ),

                        SizedBox(height: compacto ? 8 : 12),

                        // ── Saludo ────────────────────────────────────
                        RichText(text: TextSpan(
                          style: TextStyle(fontSize: compacto ? 17 : 19),
                          children: [
                            TextSpan(text: 'Hola, ',
                                style: TextStyle(color: textPrim,
                                    fontWeight: FontWeight.w500)),
                            TextSpan(
                              text: _nombre.isNotEmpty ? _nombre : 'Promotor/a',
                              style: const TextStyle(color: _kVerde,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        )),
                        const SizedBox(height: 3),
                        Text('Promotor de Salud Rural',
                            style: TextStyle(color: textHint, fontSize: 12)),

                        SizedBox(height: compacto ? 8 : 10),

                        // ── Badge Online/Offline ───────────────────────
                        GestureDetector(
                          onTap: () async {
                            final v = await ConnectivityService.instance
                                .verificarAhora();
                            if (mounted) setState(() => _online = v);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: _online
                                  ? _kVerde.withOpacity(isDark ? 0.12 : 0.10)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: _online
                                      ? _kVerde.withOpacity(0.6)
                                      : (isDark ? Colors.white24 : Colors.black12)),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              // Punto animado
                              _PuntoPulsante(activo: _online),
                              const SizedBox(width: 7),
                              Text(
                                _online
                                    ? 'Modo Online Activo'
                                    : 'Modo Offline Activo',
                                style: TextStyle(
                                  color: _online ? _kVerde : textSec,
                                  fontSize: 12, fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Icon(
                                _online
                                    ? Icons.signal_cellular_alt_rounded
                                    : Icons.signal_cellular_nodata_rounded,
                                color: _online ? _kVerde : textSec,
                                size: 14,
                              ),
                            ]),
                          ),
                        ),

                        SizedBox(height: compacto ? 12 : 16),

                        // Separador
                        Divider(color: isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.08)),

                        SizedBox(height: compacto ? 12 : 16),

                        // ── Título PIN ────────────────────────────────
                        Text(_titulo, style: TextStyle(color: textPrim,
                            fontSize: 17, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 3),
                        Text(_subtitulo, style: TextStyle(
                            color: textSec, fontSize: 11)),

                        SizedBox(height: compacto ? 12 : 16),

                        // ── Puntos PIN con shake ──────────────────────
                        AnimatedBuilder(
                          animation: _shakeAnim,
                          builder: (_, child) => Transform.translate(
                              offset: Offset(_shakeAnim.value, 0),
                              child: child),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(4, (i) {
                              final lleno = i < _pinIngresado.length;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(horizontal: 11),
                                width: 16, height: 16,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: lleno ? _kVerde : Colors.transparent,
                                  border: Border.all(
                                      color: lleno ? _kVerde
                                          : (isDark ? Colors.white30 : Colors.black26),
                                      width: 2),
                                  boxShadow: lleno ? [BoxShadow(
                                      color: _kVerde.withOpacity(0.5),
                                      blurRadius: 8, spreadRadius: 1)] : [],
                                ),
                              );
                            }),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ── Mensaje de error ──────────────────────────
                        SizedBox(height: 18,
                          child: AnimatedOpacity(
                            opacity: _error.isNotEmpty ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: Text(_error,
                                style: const TextStyle(color: _kRojo,
                                    fontSize: 11),
                                textAlign: TextAlign.center),
                          ),
                        ),

                        SizedBox(height: compacto ? 8 : 12),

                        // ── Teclado numérico ──────────────────────────
                        _Teclado(
                          biometria: _biometria && !_creandoPin,
                          pulseAnim: _pulseAnim,
                          cardColor: cardColor,
                          borderColor: borderC,
                          textColor: textPrim,
                          isDark: isDark,
                          onTecla: _presionarTecla,
                          onBorrar: _borrar,
                          onHuella: _autenticarHuella,
                          compacto: compacto,
                        ),

                        if (_biometria && !_creandoPin) ...[
                          const SizedBox(height: 6),
                          Text('Usa tu huella digital',
                              style: const TextStyle(color: _kVerde,
                                  fontSize: 11, fontWeight: FontWeight.w500)),
                        ],

                        const Spacer(),

                        // ── Botón acceso de emergencia ────────────────
                        GestureDetector(
                          onTap: _accesoEmergencia,
                          child: Container(
                            width: double.infinity, height: 46,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(23),
                              border: Border.all(
                                  color: _kRojo.withOpacity(0.5)),
                              color: _kRojo.withOpacity(0.05),
                            ),
                            child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                              Icon(Icons.medical_services_outlined,
                                  color: _kRojo, size: 16),
                              SizedBox(width: 8),
                              Text('Acceso de emergencia',
                                  style: TextStyle(color: _kRojo,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ),

                        SizedBox(height: compacto ? 8 : 12),

                        // ── Footer ────────────────────────────────────
                        Row(mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                          const Icon(Icons.shield_outlined,
                              color: _kVerde, size: 11),
                          const SizedBox(width: 5),
                          Text(
                            'Tus datos están protegidos y solo tú puedes acceder.',
                            style: TextStyle(color: textHint, fontSize: 9),
                          ),
                        ]),
                        const SizedBox(height: 4),
                        Text('v1.0.0  ·  Salud rural sin internet',
                            style: TextStyle(color: textHint, fontSize: 9)),

                        SizedBox(height: compacto ? 10 : 16),
                      ]),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AVATAR — muestra foto real o logo de la app
// ─────────────────────────────────────────────────────────────────────────────
class _AvatarFoto extends StatelessWidget {
  final String fotoPath;
  final double size;
  const _AvatarFoto({required this.fotoPath, required this.size});

  @override
  Widget build(BuildContext context) {
    final tieneFoto = !kIsWeb && fotoPath.isNotEmpty && File(fotoPath).existsSync();
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [
          _kVerde.withOpacity(0.3),
          _kVerde.withOpacity(0.05),
        ]),
        border: Border.all(color: _kVerde.withOpacity(0.5), width: 2),
      ),
      child: ClipOval(
        child: tieneFoto
            ? Image.file(File(fotoPath), fit: BoxFit.cover,
                width: size, height: size)
            : Image.asset('assets/logo_dispersalud.png',
                fit: BoxFit.cover, width: size, height: size),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PUNTO PULSANTE Online/Offline
// ─────────────────────────────────────────────────────────────────────────────
class _PuntoPulsante extends StatefulWidget {
  final bool activo;
  const _PuntoPulsante({required this.activo});
  @override State<_PuntoPulsante> createState() => _PuntoPulsanteState();
}

class _PuntoPulsanteState extends State<_PuntoPulsante>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => Container(
      width: 7, height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.activo
            ? _kVerde.withOpacity(_anim.value)
            : Colors.white38,
        boxShadow: widget.activo ? [BoxShadow(
            color: _kVerde.withOpacity(0.5 * _anim.value),
            blurRadius: 6, spreadRadius: 1)] : [],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TECLADO NUMÉRICO — widget separado para mantener build limpio
// ─────────────────────────────────────────────────────────────────────────────
class _Teclado extends StatelessWidget {
  final bool biometria;
  final Animation<double> pulseAnim;
  final Color cardColor, borderColor, textColor;
  final bool isDark, compacto;
  final ValueChanged<String> onTecla;
  final VoidCallback onBorrar, onHuella;

  const _Teclado({
    required this.biometria, required this.pulseAnim,
    required this.cardColor, required this.borderColor, required this.textColor,
    required this.isDark, required this.compacto,
    required this.onTecla, required this.onBorrar, required this.onHuella,
  });

  @override
  Widget build(BuildContext context) {
    final teclaSize = compacto ? 60.0 : 68.0;
    final fontSize  = compacto ? 22.0 : 24.0;

    return Column(children: [
      _fila(['1','2','3'], teclaSize, fontSize),
      SizedBox(height: compacto ? 8 : 12),
      _fila(['4','5','6'], teclaSize, fontSize),
      SizedBox(height: compacto ? 8 : 12),
      _fila(['7','8','9'], teclaSize, fontSize),
      SizedBox(height: compacto ? 8 : 12),
      // Fila inferior: huella — 0 — borrar
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        // Huella o espacio vacío
        SizedBox(width: teclaSize, height: teclaSize,
          child: biometria
              ? GestureDetector(
                  onTap: onHuella,
                  child: ScaleTransition(
                    scale: pulseAnim,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _kVerde.withOpacity(0.10),
                        border: Border.all(
                            color: _kVerde.withOpacity(0.40), width: 1.5),
                        boxShadow: [BoxShadow(
                            color: _kVerde.withOpacity(0.20),
                            blurRadius: 12, spreadRadius: 1)],
                      ),
                      child: const Icon(Icons.fingerprint_rounded,
                          color: _kVerde, size: 30),
                    ),
                  ),
                )
              : const SizedBox(),
        ),
        // Tecla 0
        _Tecla(valor: '0', size: teclaSize, fontSize: fontSize,
            cardColor: cardColor, borderColor: borderColor,
            textColor: textColor, onTap: onTecla),
        // Borrar
        SizedBox(width: teclaSize, height: teclaSize,
          child: GestureDetector(
            onTap: onBorrar,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: isDark ? Colors.white10 : Colors.black12),
              ),
              child: Icon(Icons.backspace_outlined,
                  color: isDark ? Colors.white38 : Colors.black38, size: 24),
            ),
          ),
        ),
      ]),
    ]);
  }

  Widget _fila(List<String> nums, double size, double fs) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: nums.map((n) => _Tecla(
          valor: n, size: size, fontSize: fs,
          cardColor: cardColor, borderColor: borderColor,
          textColor: textColor, onTap: onTecla,
        )).toList(),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// TECLA NUMÉRICA con animación de presión
// ─────────────────────────────────────────────────────────────────────────────
class _Tecla extends StatefulWidget {
  final String valor;
  final double size, fontSize;
  final Color cardColor, borderColor, textColor;
  final ValueChanged<String> onTap;
  const _Tecla({required this.valor, required this.size, required this.fontSize,
      required this.cardColor, required this.borderColor, required this.textColor,
      required this.onTap});
  @override State<_Tecla> createState() => _TeclaState();
}

class _TeclaState extends State<_Tecla> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 90));
    _scale = Tween(begin: 1.0, end: 0.88)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => _ctrl.forward(),
    onTapUp:   (_) { _ctrl.reverse(); widget.onTap(widget.valor); },
    onTapCancel: () => _ctrl.reverse(),
    child: ScaleTransition(
      scale: _scale,
      child: Container(
        width: widget.size, height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.cardColor,
          border: Border.all(color: widget.borderColor),
          boxShadow: [BoxShadow(color: _kVerde.withOpacity(0.07),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Center(child: Text(widget.valor,
            style: TextStyle(color: widget.textColor,
                fontSize: widget.fontSize, fontWeight: FontWeight.w400))),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PAINTER ECG de fondo
// ─────────────────────────────────────────────────────────────────────────────
class _EcgPainter extends CustomPainter {
  final Color color;
  _EcgPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color ..strokeWidth = 1.2 ..style = PaintingStyle.stroke;
    final path = Path();
    final cy = size.height * 0.38;
    final w  = size.width;

    path.moveTo(0, cy);
    path.lineTo(w * 0.10, cy);
    path.lineTo(w * 0.13, cy - 12);
    path.lineTo(w * 0.16, cy + 8);
    path.lineTo(w * 0.19, cy - 28);
    path.lineTo(w * 0.22, cy + 16);
    path.lineTo(w * 0.25, cy - 8);
    path.lineTo(w * 0.28, cy);
    path.lineTo(w * 0.42, cy);
    path.moveTo(w * 0.58, cy);
    path.lineTo(w * 0.72, cy);
    path.lineTo(w * 0.75, cy - 8);
    path.lineTo(w * 0.78, cy + 16);
    path.lineTo(w * 0.81, cy - 28);
    path.lineTo(w * 0.84, cy + 8);
    path.lineTo(w * 0.87, cy - 12);
    path.lineTo(w * 0.90, cy);
    path.lineTo(w, cy);

    canvas.drawPath(path, paint);
  }

  @override bool shouldRepaint(_EcgPainter o) => o.color != color;
}
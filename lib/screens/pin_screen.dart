import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

const Color _kBg = Color(0xFF111111);
const Color _kCard = Color(0xFF1E1E1E);
const Color _kVerde = Color(0xFF1D9E75);

class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  static const _kPinKey = 'dispersalud_pin';

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  final _localAuth = LocalAuthentication();

  bool _cargando = true;
  bool _creandoPin = false;
  bool _confirmar = false;

  String _pinIngresado = '';
  String _pinTemporal = '';
  String _error = '';

  // ignore: unused_field
  bool _biometria = false;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    final pinGuardado =
        await _storage.read(key: _kPinKey);

    final tieneBio =
        await _verificarBiometria();

    setState(() {
      _creandoPin = pinGuardado == null;
      _biometria = tieneBio;
      _cargando = false;
    });

    // BIOMETRÍA ACTIVA AUTOMÁTICAMENTE
    if (pinGuardado != null && tieneBio) {
      _autenticarHuella();
    }
  }

  Future<bool> _verificarBiometria() async {
    try {
      final disponible =
          await _localAuth.canCheckBiometrics;

      final soportado =
          await _localAuth.isDeviceSupported();

      return disponible && soportado;
    } catch (_) {
      return false;
    }
  }

  Future<void> _autenticarHuella() async {
    try {
      final disponible =
          await _localAuth.canCheckBiometrics;

      if (!disponible) {
        setState(() {
          _error =
              'Huella no disponible en este dispositivo.';
        });

        return;
      }

      final autenticado =
          await _localAuth.authenticate(
        localizedReason:
            'Usa tu huella para entrar a DISPERSALUD IA',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      if (autenticado && mounted) {
        _entrarApp();
      }
    } catch (e) {
      setState(() {
        _error = 'Error biométrico: $e';
      });
    }
  }

  void _presionarTecla(String valor) {
    if (_pinIngresado.length >= 4) return;

    setState(() {
      _pinIngresado += valor;
      _error = '';
    });

    if (_pinIngresado.length == 4) {
      Future.delayed(
        const Duration(milliseconds: 150),
        _evaluarPin,
      );
    }
  }

  void _borrar() {
    if (_pinIngresado.isEmpty) return;

    setState(() {
      _pinIngresado =
          _pinIngresado.substring(
        0,
        _pinIngresado.length - 1,
      );
    });
  }

  Future<void> _evaluarPin() async {
    if (_creandoPin) {
      if (!_confirmar) {
        setState(() {
          _pinTemporal = _pinIngresado;
          _pinIngresado = '';
          _confirmar = true;
        });
      } else {
        if (_pinIngresado == _pinTemporal) {
          await _storage.write(
            key: _kPinKey,
            value: _pinIngresado,
          );

          if (mounted) {
            _entrarApp();
          }
        } else {
          setState(() {
            _error =
                'Los PINs no coinciden. Intenta de nuevo.';
            _pinIngresado = '';
            _pinTemporal = '';
            _confirmar = false;
          });
        }
      }
    } else {
      final pinGuardado =
          await _storage.read(key: _kPinKey);

      if (_pinIngresado == pinGuardado) {
        if (mounted) {
          _entrarApp();
        }
      } else {
        setState(() {
          _error =
              'PIN incorrecto. Intenta de nuevo.';
          _pinIngresado = '';
        });
      }
    }
  }

  void _entrarApp() {
    Navigator.of(context)
        .pushReplacementNamed('/home');
  }

  String get _titulo {
    if (_creandoPin) {
      return _confirmar
          ? 'Confirmar PIN'
          : 'Crear PIN';
    }

    return 'Ingresa tu PIN';
  }

  String get _subtitulo {
    if (_creandoPin) {
      return _confirmar
          ? 'Repite los 4 dígitos para confirmar'
          : 'Elige un PIN de 4 dígitos para proteger la app';
    }

    return 'Ingresa tu PIN de 4 dígitos';
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(
          child: CircularProgressIndicator(
            color: _kVerde,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // LOGO
            Container(
  width: 90,
  height: 90,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    border: Border.all(
      color: _kVerde.withValues(alpha: 0.3),
      width: 2,
    ),
  ),
  child: ClipOval(
    child: Image.asset(
      'assets/logo_dispersalud.png',
      fit: BoxFit.cover,
    ),
  ),
),

            const SizedBox(height: 20),

            // TÍTULO
            Text(
              'DISPERSALUD IA',
              style: TextStyle(
                color:
                    Colors.white.withValues(alpha: 0.9),
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              _titulo,
              style: const TextStyle(
                color: _kVerde,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              _subtitulo,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // PUNTOS PIN
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final lleno =
                    i < _pinIngresado.length;

                return Container(
                  margin:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                  ),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: lleno
                        ? _kVerde
                        : Colors.transparent,
                    border: Border.all(
                      color: lleno
                          ? _kVerde
                          : Colors.white38,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 12),

            // ERROR
            AnimatedOpacity(
              opacity:
                  _error.isNotEmpty ? 1.0 : 0.0,
              duration:
                  const Duration(milliseconds: 200),
              child: Text(
                _error,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 24),

            // TECLADO
            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 48,
              ),
              child: Column(
                children: [
                  _FilaTeclado(
                    teclas: const [
                      '1',
                      '2',
                      '3'
                    ],
                    onTap:
                        _presionarTecla,
                  ),

                  const SizedBox(height: 12),

                  _FilaTeclado(
                    teclas: const [
                      '4',
                      '5',
                      '6'
                    ],
                    onTap:
                        _presionarTecla,
                  ),

                  const SizedBox(height: 12),

                  _FilaTeclado(
                    teclas: const [
                      '7',
                      '8',
                      '9'
                    ],
                    onTap:
                        _presionarTecla,
                  ),

                  const SizedBox(height: 12),

                  // ÚLTIMA FILA
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceEvenly,
                    children: [

                      // ESPACIO VACÍO
                      const SizedBox(
                        width: 72,
                        height: 72,
                      ),

                      // TECLA 0
                      _Tecla(
                        valor: '0',
                        onTap:
                            _presionarTecla,
                      ),

                      // BORRAR
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: _TeclaAccion(
                          icono: Icons
                              .backspace_outlined,
                          color:
                              Colors.white38,
                          onTap: _borrar,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),

            // FOOTER
            const Padding(
              padding:
                  EdgeInsets.only(bottom: 16),
              child: Text(
                'v1.0.0 · Salud rural sin internet',
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaTeclado extends StatelessWidget {
  final List<String> teclas;
  final ValueChanged<String> onTap;

  const _FilaTeclado({
    required this.teclas,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceEvenly,
      children: teclas
          .map(
            (t) => _Tecla(
              valor: t,
              onTap: onTap,
            ),
          )
          .toList(),
    );
  }
}

class _Tecla extends StatelessWidget {
  final String valor;
  final ValueChanged<String> onTap;

  const _Tecla({
    required this.valor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(valor),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: _kCard,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white10,
          ),
        ),
        child: Center(
          child: Text(
            valor,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _TeclaAccion extends StatelessWidget {
  final IconData icono;
  final Color color;
  final VoidCallback onTap;

  const _TeclaAccion({
    required this.icono,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(36),
        child: Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          child: Icon(
            icono,
            color: color,
            size: 32,
          ),
        ),
      ),
    );
  }
}
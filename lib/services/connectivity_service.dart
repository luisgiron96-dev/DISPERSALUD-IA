import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

// ─── Servicio de conectividad — singleton ─────────────────────────────────
// Detecta internet real (no solo WiFi conectado) y notifica cambios
class ConnectivityService {
  static final ConnectivityService instance = ConnectivityService._();
  ConnectivityService._();

  final _connectivity  = Connectivity();
  final _controller    = StreamController<bool>.broadcast();

  bool _tieneInternet  = false;
  bool _inicializado   = false;

  // URL de verificación real — usa el DNS de Google (muy rápido y confiable)
  static const _checkUrl = 'https://www.gstatic.com/generate_204';

  Stream<bool> get cambios => _controller.stream;
  bool  get tieneInternet  => _tieneInternet;
  bool  get sinInternet    => !_tieneInternet;

  // ── Inicializar ────────────────────────────────────────────────────────
  Future<void> init() async {
    if (_inicializado) return;
    _inicializado = true;

    // Verificar estado inicial
    _tieneInternet = await _verificarInternet();
    _controller.add(_tieneInternet);

    // Escuchar cambios de conectividad del dispositivo
    _connectivity.onConnectivityChanged.listen((results) async {
      // results es List<ConnectivityResult> en versiones recientes
      final conectado = results.any((r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi   ||
          r == ConnectivityResult.ethernet);

      if (!conectado) {
        // Sin red física → sin internet
        if (_tieneInternet) {
          _tieneInternet = false;
          _controller.add(false);
        }
      } else {
        // Hay red física → verificar si hay internet real
        final internet = await _verificarInternet();
        if (internet != _tieneInternet) {
          _tieneInternet = internet;
          _controller.add(internet);
        }
      }
    });

    // Verificación periódica cada 30 segundos (útil en zonas con señal intermitente)
    Timer.periodic(const Duration(seconds: 30), (_) async {
      final internet = await _verificarInternet();
      if (internet != _tieneInternet) {
        _tieneInternet = internet;
        _controller.add(internet);
      }
    });
  }

  // ── Verifica internet real (no solo red local) ─────────────────────────
  Future<bool> _verificarInternet() async {
    try {
      final response = await http.get(
        Uri.parse(_checkUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Llamada manual para verificar en cualquier momento ────────────────
  Future<bool> verificarAhora() async {
    final resultado = await _verificarInternet();
    if (resultado != _tieneInternet) {
      _tieneInternet = resultado;
      _controller.add(resultado);
    }
    return resultado;
  }

  void dispose() {
    _controller.close();
  }
}
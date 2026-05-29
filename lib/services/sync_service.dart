import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import 'connectivity_service.dart';

// ─── Servicio de sincronización ───────────────────────────────────────────
// Guarda todo localmente siempre.
// Cuando hay internet, sincroniza los registros pendientes al servidor.
// Si no hay servidor configurado, solo reporta el estado.
class SyncService {
  static final SyncService instance = SyncService._();
  SyncService._();

  static const _keyUltimaSync  = 'ultima_sincronizacion';
  static const _keyPendientes  = 'sync_pendientes';

  // ── Sincronizar cuando hay internet ──────────────────────────────────
  Future<SyncResultado> sincronizar({String? serverUrl}) async {
    if (ConnectivityService.instance.sinInternet) {
      return SyncResultado(
        exito: false,
        mensaje: 'Sin conexión — los datos están guardados localmente.',
        pendientes: await _contarPendientes(),
      );
    }

    if (serverUrl == null || serverUrl.isEmpty) {
      // Sin servidor configurado: solo marcar como "revisado"
      await _guardarUltimaSync();
      return SyncResultado(
        exito: true,
        mensaje: 'Conexión disponible. Configura un servidor para sincronizar datos.',
        pendientes: await _contarPendientes(),
        tieneServidor: false,
      );
    }

    try {
      // Obtener registros pendientes de sincronización
      final consultas = await DatabaseHelper.instance.obtenerConsultasPendientesSync();
      if (consultas.isEmpty) {
        await _guardarUltimaSync();
        return SyncResultado(
          exito: true,
          mensaje: 'Todo sincronizado — no hay registros pendientes.',
          pendientes: 0,
          sincronizados: 0,
        );
      }

      int sincronizados = 0;
      for (final consulta in consultas) {
        try {
          final response = await http.post(
            Uri.parse('$serverUrl/api/consultas'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(consulta),
          ).timeout(const Duration(seconds: 10));

          if (response.statusCode == 200 || response.statusCode == 201) {
            await DatabaseHelper.instance.marcarConsultaSincronizada(consulta['id']);
            sincronizados++;
          }
        } catch (_) {
          // Si falla uno, continúa con el siguiente
        }
      }

      await _guardarUltimaSync();
      return SyncResultado(
        exito: true,
        mensaje: '$sincronizados de ${consultas.length} registros sincronizados.',
        pendientes: consultas.length - sincronizados,
        sincronizados: sincronizados,
      );
    } catch (e) {
      return SyncResultado(
        exito: false,
        mensaje: 'Error de sincronización: ${e.toString().substring(0, 50)}',
        pendientes: await _contarPendientes(),
      );
    }
  }

  // ── Estado de la última sincronización ────────────────────────────────
  Future<String> ultimaSync() async {
    final prefs = await SharedPreferences.getInstance();
    final fecha = prefs.getString(_keyUltimaSync);
    if (fecha == null) return 'Nunca sincronizado';
    try {
      final dt   = DateTime.parse(fecha);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1)  return 'Hace un momento';
      if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
      if (diff.inHours < 24)   return 'Hace ${diff.inHours}h';
      return 'Hace ${diff.inDays} días';
    } catch (_) {
      return 'Desconocido';
    }
  }

  Future<int> _contarPendientes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyPendientes) ?? 0;
  }

  Future<void> _guardarUltimaSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUltimaSync, DateTime.now().toIso8601String());
    await prefs.setInt(_keyPendientes, 0);
  }
}

class SyncResultado {
  final bool   exito;
  final String mensaje;
  final int    pendientes;
  final int    sincronizados;
  final bool   tieneServidor;

  const SyncResultado({
    required this.exito,
    required this.mensaje,
    this.pendientes    = 0,
    this.sincronizados = 0,
    this.tieneServidor = true,
  });
}
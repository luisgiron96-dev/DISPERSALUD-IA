import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/database_helper.dart';
import 'connectivity_service.dart';

// ─── Servicio de sincronización con Supabase ─────────────────────────────────
// Estrategia offline-first:
//   1. Todo se guarda localmente en SQLite siempre
//   2. Cuando hay internet → sube los registros pendientes a Supabase
//   3. Si falla → queda pendiente para el próximo intento
class SyncService {
  static final SyncService instance = SyncService._();
  SyncService._();

  static const _keyUltimaSync = 'ultima_sincronizacion';
  final _sb = Supabase.instance.client;

  // ── Sincronizar todo cuando hay internet ─────────────────────
  Future<SyncResultado> sincronizar() async {
    if (ConnectivityService.instance.sinInternet) {
      return SyncResultado(
        exito: false,
        mensaje: 'Sin conexión — datos guardados localmente.',
        pendientes: await _contarPendientes(),
      );
    }

    try {
      int total = 0;
      int subidos = 0;

      // ── 1. Sincronizar pacientes ──────────────────────────────
      final pacientes = await DatabaseHelper.instance.obtenerPacientesPendientesSync();
      total += pacientes.length;
      for (final p in pacientes) {
        try {
          await _sb.from('pacientes').upsert({
            'id_local':     p['id'],
            'nombre':       p['nombre'],
            'documento':    p['documento'],
            'fecha_nac':    p['fecha_nac'],
            'sexo':         p['sexo'],
            'edad':         p['edad'],
            'departamento': p['departamento'],
            'municipio':    p['municipio'],
            'vereda':       p['vereda'],
            'telefono':     p['telefono'],
            'eps':          p['eps'],
            'modulo':       p['modulo'],
            'acudiente':    p['acudiente'],
          }, onConflict: 'id_local');
          await DatabaseHelper.instance.marcarPacienteSincronizado(p['id']);
          subidos++;
        } catch (_) {}
      }

      // ── 2. Sincronizar consultas ──────────────────────────────
      final consultas = await DatabaseHelper.instance.obtenerConsultasPendientesSync();
      total += consultas.length;
      for (final c in consultas) {
        try {
          // Parsear datos_json si es String
          dynamic datosJson = c['datos_json'];
          if (datosJson is String && datosJson.isNotEmpty) {
            try { datosJson = jsonDecode(datosJson); } catch (_) {}
          }

          await _sb.from('consultas').upsert({
            'id_local':       c['id'],
            'nombre_paciente': c['nombre'],
            'modulo':         c['modulo'],
            'fecha':          c['fecha'],
            'presion':        c['presion'],
            'glucemia':       c['glucemia'],
            'peso':           c['peso'],
            'talla':          c['talla'],
            'temperatura':    c['temperatura'],
            'spo2':           c['spo2'],
            'fc':             c['fc'],
            'semanas':        c['semanas'],
            'imc':            c['imc'],
            'diagnostico':    c['diagnostico'],
            'nivel_riesgo':   c['nivel_riesgo'],
            'observaciones':  c['observaciones'],
            'datos_json':     datosJson,
          }, onConflict: 'id_local');
          await DatabaseHelper.instance.marcarConsultaSincronizada(c['id']);
          subidos++;
        } catch (_) {}
      }

      // ── 3. Sincronizar alertas ────────────────────────────────
      final alertas = await DatabaseHelper.instance.obtenerAlertasPendientesSync();
      total += alertas.length;
      for (final a in alertas) {
        try {
          await _sb.from('alertas').upsert({
            'id_local': a['id'],
            'modulo':   a['modulo'],
            'paciente': a['paciente'],
            'mensaje':  a['mensaje'],
            'nivel':    a['nivel'],
            'resuelta': a['resuelta'] == 1,
            'fecha':    a['fecha'],
          }, onConflict: 'id_local');
          await DatabaseHelper.instance.marcarAlertaSincronizada(a['id']);
          subidos++;
        } catch (_) {}
      }

      // ── 4. Sincronizar fichas epidemiológicas ─────────────────
      final fichas = await DatabaseHelper.instance.obtenerFichasPendientesSync();
      total += fichas.length;
      for (final f in fichas) {
        try {
          dynamic datosJson = f['datos_json'];
          if (datosJson is String && datosJson.isNotEmpty) {
            try { datosJson = jsonDecode(datosJson); } catch (_) {}
          }

          await _sb.from('fichas_epidemiologicas').upsert({
            'id_local':          f['id'],
            'codigo_evento':     f['codigo_evento'],
            'nombre_evento':     f['nombre_evento'],
            'estado':            f['estado'],
            'exportado':         f['exportado'] == 1,
            'datos_json':        datosJson,
            'nombre_paciente':   f['nombre_paciente'],
            'municipio':         f['municipio'],
            'fecha_notificacion': f['fecha_notificacion'],
            'nivel_urgencia':    f['nivel_urgencia'],
          }, onConflict: 'id_local');
          await DatabaseHelper.instance.marcarFichaSincronizada(f['id']);
          subidos++;
        } catch (_) {}
      }

      await _guardarUltimaSync();

      final pendientes = total - subidos;
      return SyncResultado(
        exito: true,
        mensaje: subidos == total
            ? '$subidos registros sincronizados ✓'
            : '$subidos de $total sincronizados ($pendientes fallaron)',
        pendientes: pendientes,
        sincronizados: subidos,
      );
    } catch (e) {
      return SyncResultado(
        exito: false,
        mensaje: 'Error: ${e.toString().substring(0, 80)}',
        pendientes: await _contarPendientes(),
      );
    }
  }

  // ── Estado de la última sincronización ───────────────────────
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
    } catch (_) { return 'Desconocido'; }
  }

  Future<int> _contarPendientes() async {
    final p = await DatabaseHelper.instance.obtenerConsultasPendientesSync();
    return p.length;
  }

  Future<void> _guardarUltimaSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUltimaSync, DateTime.now().toIso8601String());
  }
}

class SyncResultado {
  final bool   exito;
  final String mensaje;
  final int    pendientes;
  final int    sincronizados;

  const SyncResultado({
    required this.exito,
    required this.mensaje,
    this.pendientes    = 0,
    this.sincronizados = 0,
  });
}
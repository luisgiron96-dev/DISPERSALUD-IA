// ============================================================================
//  lib/services/sivigila_service.dart  —  DISPERSALUD IA
//
//  ALERTAS SIVIGILA AUTOMÁTICAS
//  ─────────────────────────────
//  Detecta enfermedades de notificación obligatoria en cada diagnóstico
//  guardado y genera alertas automáticamente en la tabla `alertas`.
//
//  CÓMO USAR:
//    // Al guardar una consulta:
//    await SivigilaService.instance.evaluarDiagnostico(
//      diagnostico: 'posible dengue con signos de alarma',
//      paciente:    'María López',
//      modulo:      'infancia',
//    );
//
//  Integra también la sincronización de alertas con Supabase (campo
//  `sincronizado` que faltaba en la tabla `alertas`).
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/database_helper.dart';
import 'connectivity_service.dart';

// ── Evento de notificación obligatoria ──────────────────────────────────────
class EventoSivigila {
  final String codigo;
  final String nombre;
  final String nivel;       // 'urgente' | 'alerta' | 'vigilancia'
  final String descripcion;
  final List<RegExp> patrones;

  const EventoSivigila({
    required this.codigo,
    required this.nombre,
    required this.nivel,
    required this.descripcion,
    required this.patrones,
  });
}

// ── Catálogo de detección automática ────────────────────────────────────────
// Cada evento tiene expresiones regulares que se buscan en el diagnóstico.
// Basado en protocolos del INS Colombia.
final List<EventoSivigila> _kEventosDeteccion = [
  // ── VECTORES ──
  EventoSivigila(
    codigo: 'DEN', nombre: 'Dengue', nivel: 'urgente',
    descripcion: 'Caso sospechoso de Dengue. Notificación inmediata requerida.',
    patrones: [RegExp(r'dengue', caseSensitive: false)],
  ),
  EventoSivigila(
    codigo: 'MAL', nombre: 'Malaria', nivel: 'alerta',
    descripcion: 'Caso sospechoso de Malaria. Tomar gota gruesa y notificar.',
    patrones: [RegExp(r'malaria|palu?dic[ao]|plasmodium', caseSensitive: false)],
  ),
  EventoSivigila(
    codigo: 'CHIK', nombre: 'Chikunguña', nivel: 'alerta',
    descripcion: 'Caso sospechoso de Chikunguña. Notificación a epidemiología.',
    patrones: [RegExp(r'chikungu[nñ]a', caseSensitive: false)],
  ),
  EventoSivigila(
    codigo: 'ZIKA', nombre: 'Zika', nivel: 'alerta',
    descripcion: 'Caso sospechoso de Zika. Prioridad en embarazadas.',
    patrones: [RegExp(r'\bzika\b', caseSensitive: false)],
  ),
  EventoSivigila(
    codigo: 'LEIS', nombre: 'Leishmaniasis', nivel: 'alerta',
    descripcion: 'Caso sospechoso de Leishmaniasis. Referir para diagnóstico.',
    patrones: [RegExp(r'leishmaniasis', caseSensitive: false)],
  ),

  // ── INMUNOPREVENIBLES ──
  EventoSivigila(
    codigo: 'SAR', nombre: 'Sarampión', nivel: 'urgente',
    descripcion: 'URGENTE: Caso sospechoso de Sarampión. Notificación inmediata al INS.',
    patrones: [RegExp(r'sarampi[oó]n', caseSensitive: false)],
  ),
  EventoSivigila(
    codigo: 'TOS', nombre: 'Tos ferina', nivel: 'alerta',
    descripcion: 'Caso sospechoso de Tos ferina (Pertussis). Aislamiento y notificación.',
    patrones: [RegExp(r'tos ferina|pertussis|coqueluche', caseSensitive: false)],
  ),
  EventoSivigila(
    codigo: 'PAR', nombre: 'Parotiditis', nivel: 'vigilancia',
    descripcion: 'Caso sospechoso de Parotiditis. Verificar esquema de vacunación.',
    patrones: [RegExp(r'parotiditis|paperas', caseSensitive: false)],
  ),
  EventoSivigila(
    codigo: 'DIF', nombre: 'Difteria', nivel: 'urgente',
    descripcion: 'URGENTE: Caso sospechoso de Difteria. Notificación inmediata.',
    patrones: [RegExp(r'difteria', caseSensitive: false)],
  ),

  // ── RESPIRATORIAS ──
  EventoSivigila(
    codigo: 'TBC', nombre: 'Tuberculosis', nivel: 'alerta',
    descripcion: 'Caso sospechoso de TB. Toma de baciloscopía y referencia.',
    patrones: [RegExp(r'tuberculosis|\btb\b|\btbc\b|bacilo de koch', caseSensitive: false)],
  ),
  EventoSivigila(
    codigo: 'COVID', nombre: 'COVID-19', nivel: 'alerta',
    descripcion: 'Caso sospechoso de COVID-19. Aislamiento y notificación.',
    patrones: [RegExp(r'covid[-\s]?19|sars[-\s]?cov', caseSensitive: false)],
  ),
  EventoSivigila(
    codigo: 'IRA', nombre: 'IRA grave', nivel: 'alerta',
    descripcion: 'IRA de manejo hospitalario. Evaluar signos de alarma respiratoria.',
    patrones: [RegExp(r'neumoni[ao]|bronconeumoni[ao]|sepsis pulmonar', caseSensitive: false)],
  ),

  // ── ALIMENTOS Y AGUA ──
  EventoSivigila(
    codigo: 'ETA', nombre: 'ETA (Enfermedad transmitida por alimentos)', nivel: 'alerta',
    descripcion: 'Caso sospechoso de ETA. Investigar fuente común en comunidad.',
    patrones: [RegExp(r'\beta\b|intoxicaci[oó]n alimentaria|brote aliment', caseSensitive: false)],
  ),
  EventoSivigila(
    codigo: 'COL', nombre: 'Cólera', nivel: 'urgente',
    descripcion: 'URGENTE: Caso sospechoso de Cólera. Notificación inmediata al INS.',
    patrones: [RegExp(r'c[oó]lera|vibrio', caseSensitive: false)],
  ),
  EventoSivigila(
    codigo: 'FIT', nombre: 'Fiebre tifoidea', nivel: 'alerta',
    descripcion: 'Caso sospechoso de Fiebre tifoidea. Referir para hemocultivo.',
    patrones: [RegExp(r'fiebre tifoidea|salmonella typhi', caseSensitive: false)],
  ),
  EventoSivigila(
    codigo: 'LEPT', nombre: 'Leptospirosis', nivel: 'alerta',
    descripcion: 'Caso sospechoso de Leptospirosis. Investigar exposición a aguas.',
    patrones: [RegExp(r'leptospirosis|leptospira', caseSensitive: false)],
  ),

  // ── ITS Y SANGRE ──
  EventoSivigila(
    codigo: 'VIH', nombre: 'VIH/SIDA', nivel: 'alerta',
    descripcion: 'Caso de VIH. Referir para confirmación y seguimiento.',
    patrones: [RegExp(r'\bvih\b|\bsida\b|\bhiv\b', caseSensitive: false)],
  ),
  EventoSivigila(
    codigo: 'SIF', nombre: 'Sífilis', nivel: 'alerta',
    descripcion: 'Caso de Sífilis. Notificación y tratamiento de la pareja.',
    patrones: [RegExp(r's[ií]filis|treponema', caseSensitive: false)],
  ),
  EventoSivigila(
    codigo: 'HEPA', nombre: 'Hepatitis', nivel: 'alerta',
    descripcion: 'Caso de Hepatitis. Identificar tipo y notificar.',
    patrones: [RegExp(r'hepatitis [abc]', caseSensitive: false)],
  ),

  // ── ZOONOSIS ──
  EventoSivigila(
    codigo: 'RAB', nombre: 'Rabia', nivel: 'urgente',
    descripcion: 'URGENTE: Exposición a rabia. Profilaxis post-exposición inmediata.',
    patrones: [RegExp(r'rabia|mordedura animal|exposici[oó]n r[aá]bica', caseSensitive: false)],
  ),
  EventoSivigila(
    codigo: 'CHAG', nombre: 'Chagas', nivel: 'alerta',
    descripcion: 'Caso sospechoso de Chagas. Referir para serología.',
    patrones: [RegExp(r'chagas|trypanosoma', caseSensitive: false)],
  ),

  // ── MATERNA E INFANTIL ──
  EventoSivigila(
    codigo: 'MM', nombre: 'Mortalidad materna', nivel: 'urgente',
    descripcion: 'URGENTE: Muerte materna. Notificación inmediata. Iniciar análisis de caso.',
    patrones: [RegExp(r'mortalidad materna|muerte materna|falleci.{0,20}embaraz', caseSensitive: false)],
  ),
  EventoSivigila(
    codigo: 'MMP', nombre: 'Mortalidad perinatal', nivel: 'urgente',
    descripcion: 'URGENTE: Muerte perinatal. Notificación y análisis de caso.',
    patrones: [RegExp(r'mortalidad perinatal|muerte perinatal|mortinato|óbito', caseSensitive: false)],
  ),
  EventoSivigila(
    codigo: 'MNI', nombre: 'Mortalidad en menores de 5 años', nivel: 'urgente',
    descripcion: 'URGENTE: Muerte en menor de 5 años. Notificación inmediata.',
    patrones: [RegExp(r'mortalidad infantil|muerte ni[ñn]o|falleci.{0,10}(ni[ñn]|menor|infan)', caseSensitive: false)],
  ),
  EventoSivigila(
    codigo: 'DNT', nombre: 'Desnutrición aguda', nivel: 'alerta',
    descripcion: 'Caso de desnutrición aguda. Referir para manejo nutricional urgente.',
    patrones: [RegExp(r'desnutrici[oó]n aguda|marasmo|kwashiorkor|desnutrici[oó]n severa', caseSensitive: false)],
  ),

  // ── LESIONES Y VIOLENCIAS ──
  EventoSivigila(
    codigo: 'VIO', nombre: 'Violencia', nivel: 'alerta',
    descripcion: 'Caso de violencia. Notificación y ruta de atención según protocolo.',
    patrones: [RegExp(r'violencia (sexual|doméstica|intrafamiliar|f[ií]sica)|abuso sexual', caseSensitive: false)],
  ),
  EventoSivigila(
    codigo: 'INT', nombre: 'Intento de suicidio', nivel: 'urgente',
    descripcion: 'URGENTE: Intento de suicidio. Activar ruta de salud mental.',
    patrones: [RegExp(r'intento de suicidio|intent.{0,10}suicid', caseSensitive: false)],
  ),

  // ── ENFERMEDADES ESPECIALES ──
  EventoSivigila(
    codigo: 'MENH', nombre: 'Meningitis', nivel: 'urgente',
    descripcion: 'URGENTE: Caso sospechoso de Meningitis. Remisión inmediata.',
    patrones: [RegExp(r'meningitis|meningoc[oó]cic', caseSensitive: false)],
  ),
  EventoSivigila(
    codigo: 'FIA', nombre: 'Fiebre amarilla', nivel: 'urgente',
    descripcion: 'URGENTE: Caso sospechoso de Fiebre Amarilla. Notificación inmediata al INS.',
    patrones: [RegExp(r'fiebre amarilla', caseSensitive: false)],
  ),
  EventoSivigila(
    codigo: 'EBOL', nombre: 'Ébola', nivel: 'urgente',
    descripcion: 'URGENTE: Caso sospechoso de Ébola. Notificación inmediata al INS y OMS.',
    patrones: [RegExp(r'[eé]bola', caseSensitive: false)],
  ),
];

// ============================================================================
//  SERVICIO PRINCIPAL
// ============================================================================
class SivigilaService {
  static final SivigilaService instance = SivigilaService._();
  SivigilaService._();

  final _sb = Supabase.instance.client;

  // ── 1. EVALUAR DIAGNÓSTICO Y GENERAR ALERTA SI APLICA ───────────────────
  /// Llama esto cada vez que se guarda una consulta.
  /// Si el diagnóstico contiene enfermedad de notificación obligatoria,
  /// guarda automáticamente una alerta en SQLite y la sube a Supabase.
  Future<AlertaSivigilaResultado> evaluarDiagnostico({
    required String diagnostico,
    required String paciente,
    required String modulo,
    int? consultaId,
  }) async {
    if (diagnostico.trim().isEmpty) {
      return AlertaSivigilaResultado(generada: false, razon: 'Diagnóstico vacío');
    }

    final evento = _detectarEvento(diagnostico);
    if (evento == null) {
      return AlertaSivigilaResultado(
        generada: false,
        razon: 'No se detectó enfermedad de notificación obligatoria',
      );
    }

    // Guardar alerta en SQLite
    final alertaId = await _guardarAlertaLocal(
      evento:   evento,
      paciente: paciente,
      modulo:   modulo,
    );

    // Intentar subir a Supabase si hay internet
    bool sincronizado = false;
    if (ConnectivityService.instance.tieneInternet) {
      sincronizado = await _subirAlertaSupabase(
        alertaId: alertaId,
        evento:   evento,
        paciente: paciente,
        modulo:   modulo,
      );
    }

    debugPrint('[SIVIGILA] Alerta automática generada: ${evento.codigo} — '
        '${evento.nombre} — nivel: ${evento.nivel} — sync: $sincronizado');

    return AlertaSivigilaResultado(
      generada:    true,
      evento:      evento,
      alertaId:    alertaId,
      sincronizado: sincronizado,
    );
  }

  // ── 2. SINCRONIZAR ALERTAS PENDIENTES ───────────────────────────────────
  /// Sube a Supabase todas las alertas que quedaron sin sincronizar.
  Future<int> sincronizarAlertasPendientes() async {
    if (ConnectivityService.instance.sinInternet) return 0;

    final db       = await DatabaseHelper.instance.database;
    int subidas    = 0;

    try {
      // Traer alertas con sincronizado = 0
      final pendientes = await db.query(
        'alertas',
        where: 'sincronizado = 0 OR sincronizado IS NULL',
        orderBy: 'fecha DESC',
        limit: 100,
      );

      for (final a in pendientes) {
        try {
          await _sb.from('alertas').upsert({
            'id_local':  a['id'],
            'modulo':    a['modulo'],
            'paciente':  a['paciente'],
            'mensaje':   a['mensaje'],
            'nivel':     a['nivel'],
            'resuelta':  a['resuelta'] == 1,
            'fecha':     a['fecha'],
            'auto':      a['auto'] == 1,
          }, onConflict: 'id_local');

          // Marcar como sincronizada en SQLite
          await db.update(
            'alertas',
            {'sincronizado': 1},
            where: 'id = ?',
            whereArgs: [a['id']],
          );
          subidas++;
        } catch (_) {
          // Continúa con la siguiente
        }
      }
    } catch (e) {
      debugPrint('[SIVIGILA] Error sincronizando alertas: $e');
    }

    return subidas;
  }

  // ── PRIVADOS ─────────────────────────────────────────────────────────────

  /// Busca el primer evento que coincida con el diagnóstico.
  EventoSivigila? _detectarEvento(String diagnostico) {
    for (final ev in _kEventosDeteccion) {
      for (final patron in ev.patrones) {
        if (patron.hasMatch(diagnostico)) return ev;
      }
    }
    return null;
  }

  /// Guarda la alerta en SQLite y retorna el ID insertado.
  Future<int> _guardarAlertaLocal({
    required EventoSivigila evento,
    required String paciente,
    required String modulo,
  }) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('alertas', {
      'modulo':       modulo,
      'paciente':     paciente,
      'mensaje':      '${evento.nombre}: ${evento.descripcion}',
      'nivel':        evento.nivel,
      'resuelta':     0,
      'sincronizado': 0,   // se actualizará cuando haya internet
      'auto':         1,   // indica que fue generada automáticamente
      'codigo_sivigila': evento.codigo,
      'fecha':        DateTime.now().toIso8601String(),
    });
  }

  /// Sube una alerta a Supabase y marca como sincronizada en SQLite.
  Future<bool> _subirAlertaSupabase({
    required int alertaId,
    required EventoSivigila evento,
    required String paciente,
    required String modulo,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await _sb.from('alertas').upsert({
        'id_local':  alertaId,
        'modulo':    modulo,
        'paciente':  paciente,
        'mensaje':   '${evento.nombre}: ${evento.descripcion}',
        'nivel':     evento.nivel,
        'resuelta':  false,
        'auto':      true,
        'codigo_sivigila': evento.codigo,
        'fecha':     DateTime.now().toIso8601String(),
      }, onConflict: 'id_local');

      await db.update(
        'alertas',
        {'sincronizado': 1},
        where: 'id = ?',
        whereArgs: [alertaId],
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Resumen de alertas para el prompt de la IA ─────────────────────
  // Usa alertas reales generadas por los promotores en campo
  Future<String> obtenerResumenAlertas() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(
        'alertas',
        where: 'resuelta = 0',
        orderBy: 'fecha DESC',
        limit: 5,
      );
      if (rows.isEmpty) {
        return 'dengue en Santander de Quilichao, malaria en López de Micay';
      }
      return rows.map((r) {
        final nivel    = r['nivel']?.toString().toUpperCase() ?? '';
        final paciente = r['paciente']?.toString() ?? 'paciente';
        final mensaje  = r['mensaje']?.toString() ?? '';
        return '\$nivel: \$paciente — \$mensaje';
      }).join('; ');
    } catch (_) {
      return 'dengue en Santander de Quilichao, malaria en López de Micay';
    }
  }

}

// ── Resultado de evaluación ──────────────────────────────────────────────────
class AlertaSivigilaResultado {
  final bool             generada;
  final EventoSivigila?  evento;
  final int?             alertaId;
  final bool             sincronizado;
  final String?          razon;

  const AlertaSivigilaResultado({
    required this.generada,
    this.evento,
    this.alertaId,
    this.sincronizado = false,
    this.razon,
  });

  @override
  String toString() => generada
      ? '✅ Alerta SIVIGILA: ${evento?.nombre} (ID $alertaId, sync: $sincronizado)'
      : '— Sin alerta: $razon';
}
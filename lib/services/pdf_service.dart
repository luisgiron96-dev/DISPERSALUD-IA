import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../database/database_helper.dart';

// ── Colores DISPERSALUD ───────────────────────────────────────────────────
const _verde  = PdfColor.fromInt(0xFF1D9E75);
const _gris   = PdfColor.fromInt(0xFF2A2A2A);
const _oscuro = PdfColor.fromInt(0xFF111111);
const _texto  = PdfColor.fromInt(0xFF1A1A1A);

// ── Alertas SIVIGILA activas (mismas que AlertasScreen) ───────────────────
const List<Map<String, dynamic>> _kAlertasActivas = [
  {
    'codigo': 'DEN', 'nombre': 'Dengue',
    'municipio': 'Santander de Quilichao',
    'nivel': 'urgente', 'casos': 18,
    'mensaje': 'Incremento de casos en últimas 2 semanas. Se activa alerta epidemiológica.',
  },
  {
    'codigo': 'MAL', 'nombre': 'Malaria',
    'municipio': 'López de Micay',
    'nivel': 'alerta', 'casos': 5,
    'mensaje': 'Casos confirmados de P. falciparum. Reforzar búsqueda activa con gota gruesa.',
  },
  {
    'codigo': 'DES', 'nombre': 'Desnutrición Aguda',
    'municipio': 'Toribío',
    'nivel': 'alerta', 'casos': 3,
    'mensaje': 'Tres niños menores de 2 años con desnutrición aguda severa. Activar ICBF.',
  },
];

class PdfService {
  // ── Método principal ─────────────────────────────────────────────────────
  static Future<void> generarYCompartir({
    required BuildContext context,
    required int pacienteId,
    required String pacienteNombre,
  }) async {
    // 1 — Cargar datos
    final paciente  = await DatabaseHelper.instance.obtenerPaciente(pacienteId);
    final consultas = await DatabaseHelper.instance.consultasDePaciente(pacienteId);
    final alertas   = await DatabaseHelper.instance.obtenerAlertas();

    // 2 — Construir PDF
    final pdf = pw.Document(
      title: 'Historial clínico — $pacienteNombre',
      author: 'DISPERSALUD IA',
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => _header(pacienteNombre),
        footer: (ctx) => _footer(ctx),
        build: (ctx) => [
          _seccionPaciente(paciente),
          pw.SizedBox(height: 20),
          _seccionConsultas(consultas),
          pw.SizedBox(height: 20),
          _seccionAlertas(alertas),
        ],
      ),
    );

    // 3 — Compartir / imprimir
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'DISPERSALUD_${pacienteNombre.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  // ── Header de cada página ────────────────────────────────────────────────
  static pw.Widget _header(String nombre) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _verde, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('DISPERSALUD IA',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _verde)),
            pw.Text('Sistema de Salud Rural · Cauca, Colombia',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text('Historial Clínico',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _texto)),
            pw.Text(nombre,
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ]),
        ],
      ),
    );
  }

  // ── Footer de cada página ────────────────────────────────────────────────
  static pw.Widget _footer(pw.Context ctx) {
    final fecha = DateTime.now().toLocal();
    final fechaStr =
        '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}  ${fecha.hour.toString().padLeft(2,'0')}:${fecha.minute.toString().padLeft(2,'0')}';
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Generado: $fechaStr · Ley 1581 — Datos protegidos',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
          pw.Text('Página ${ctx.pageNumber} de ${ctx.pagesCount}',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
        ],
      ),
    );
  }

  // ── Sección datos del paciente ───────────────────────────────────────────
  static pw.Widget _seccionPaciente(Map<String, dynamic>? p) {
    if (p == null) return pw.SizedBox();
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      _tituloSeccion('Datos del Paciente'),
      pw.SizedBox(height: 8),
      pw.Container(
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey50,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.grey200),
        ),
        child: pw.Column(children: [
          pw.Row(children: [
            _campo('Nombre completo', p['nombre'] ?? '—'),
            _campo('Documento',       p['documento'] ?? '—'),
          ]),
          pw.SizedBox(height: 8),
          pw.Row(children: [
            _campo('Fecha de nacimiento', p['fecha_nac'] ?? '—'),
            _campo('Sexo biológico',      p['sexo']     ?? '—'),
          ]),
          pw.SizedBox(height: 8),
          pw.Row(children: [
            _campo('Vereda',    p['vereda']    ?? '—'),
            _campo('Municipio', p['municipio'] ?? '—'),
          ]),
          pw.SizedBox(height: 8),
          pw.Row(children: [
            _campo('Teléfono', p['telefono'] ?? '—'),
            _campo('Módulo de atención', p['modulo'] ?? '—'),
          ]),
        ]),
      ),
    ]);
  }

  // ── Sección historial de consultas ───────────────────────────────────────
  static pw.Widget _seccionConsultas(List<Map<String, dynamic>> consultas) {
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      _tituloSeccion('Historial de Consultas (${consultas.length})'),
      pw.SizedBox(height: 8),
      if (consultas.isEmpty)
        pw.Text('Sin consultas registradas.',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600))
      else
        ...consultas.map((c) => _tarjetaConsulta(c)),
    ]);
  }

  static pw.Widget _tarjetaConsulta(Map<String, dynamic> c) {
    final nivel = c['nivel_riesgo'] ?? 'normal';
    final color = _colorNivel(nivel);
    final fecha = _formatFecha(c['fecha']);

    Map<String, dynamic> datos = {};
    try { datos = jsonDecode(c['datos_json'] ?? '{}'); } catch (_) {}

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 0.8),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        // Fila superior: módulo + fecha + nivel
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: pw.BoxDecoration(
                color: color,
                borderRadius: pw.BorderRadius.circular(20),
              ),
              child: pw.Text(c['modulo'] ?? '',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold)),
            ),
            pw.Text(fecha,
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: pw.BoxDecoration(
                color: color.shade(0.15),
                borderRadius: pw.BorderRadius.circular(20),
              ),
              child: pw.Text(nivel.toUpperCase(),
                  style: pw.TextStyle(fontSize: 8, color: color,
                      fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
        // Diagnóstico
        if ((c['diagnostico'] ?? '').isNotEmpty) ...[
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: color.shade(0.08),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Text(
              _limpiarTexto(c['diagnostico'] as String? ?? ''),
              style: pw.TextStyle(fontSize: 10, color: _texto),
            ),
          ),
        ],
        // Datos clínicos
        if (datos.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          pw.Wrap(
            spacing: 16, runSpacing: 4,
            children: datos.entries.take(8).map((e) => pw.RichText(
              text: pw.TextSpan(children: [
                pw.TextSpan(text: '${e.key}: ',
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                pw.TextSpan(text: e.value.toString(),
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _texto)),
              ]),
            )).toList(),
          ),
        ],
      ]),
    );
  }

  // ── Sección alertas SIVIGILA ─────────────────────────────────────────────
  static pw.Widget _seccionAlertas(List<Map<String, dynamic>> alertasSqlite) {
    // Combinar alertas activas del sistema + las del promotor
    final alertasPromotor = alertasSqlite
        .where((a) => (a['resuelta'] as int? ?? 0) == 0)
        .toList();

    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      _tituloSeccion('Alertas SIVIGILA Activas'),
      pw.SizedBox(height: 8),

      // Alertas del sistema
      pw.Text('Alertas epidemiológicas en zona',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700,
              fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 6),
      ..._kAlertasActivas.map((a) => _tarjetaAlerta(
        nombre: a['nombre'],
        municipio: a['municipio'],
        nivel: a['nivel'],
        mensaje: a['mensaje'],
        casos: a['casos'],
      )),

      if (alertasPromotor.isNotEmpty) ...[
        pw.SizedBox(height: 12),
        pw.Text('Alertas registradas por el promotor',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700,
                fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        ...alertasPromotor.map((a) => _tarjetaAlerta(
          nombre: a['modulo'] ?? 'General',
          municipio: a['paciente'] ?? '',
          nivel: a['nivel'] ?? 'normal',
          mensaje: a['mensaje'] ?? '',
          casos: null,
        )),
      ],
    ]);
  }

  static pw.Widget _tarjetaAlerta({
    required String nombre,
    required String municipio,
    required String nivel,
    required String mensaje,
    int? casos,
  }) {
    final color = _colorNivel(nivel);
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 0.8),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: pw.BoxDecoration(
              color: color, borderRadius: pw.BorderRadius.circular(4)),
            child: pw.Text(nivel.toUpperCase(),
                style: pw.TextStyle(fontSize: 8, color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Row(children: [
              pw.Text(nombre,
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _texto)),
              if (municipio.isNotEmpty) ...[
                pw.Text('  ·  $municipio',
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
              ],
              if (casos != null) ...[
                pw.Text('  ·  $casos casos',
                    style: pw.TextStyle(fontSize: 9, color: color,
                        fontWeight: pw.FontWeight.bold)),
              ],
            ]),
            pw.SizedBox(height: 4),
            pw.Text(mensaje,
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          ])),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  static pw.Widget _tituloSeccion(String titulo) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _verde, width: 1.5)),
      ),
      child: pw.Text(titulo,
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _verde)),
    );
  }

  static pw.Widget _campo(String label, String valor) {
    return pw.Expanded(child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(label,
          style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
      pw.SizedBox(height: 2),
      pw.Text(valor,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _texto)),
    ]));
  }

  /// Elimina emojis y caracteres no soportados por la librería PDF
  static String _limpiarTexto(String texto) {
    // Reemplazar emojis comunes del diagnóstico por texto equivalente
    return texto
        .replaceAll('⚠️', '[ALERTA]')
        .replaceAll('🩸', '[SANGRE]')
        .replaceAll('📋', '[NOTA]')
        .replaceAll('✅', '[OK]')
        .replaceAll('🚨', '[URGENTE]')
        .replaceAll('🌡️', '[FIEBRE]')
        .replaceAll('🧠', '[MENTAL]')
        .replaceAll('🚭', '[TABACO]')
        .replaceAll('⚖️', '[PESO]')
        .replaceAll('🫀', '[CORAZON]')
        .replaceAll('💉', '[VACUNA]')
        .replaceAll('🧒', '[NINO]')
        .replaceAll('👁️', '[VISION]')
        .replaceAll('🦷', '[DIENTE]')
        .replaceAll('😮', '[OXIGENO]')
        .replaceAll('🧓', '[ADULTO]')
        // Eliminar cualquier otro emoji o caracter especial no soportado
        .replaceAll(RegExp(r'[^ -~À-ɏЀ-ӿ\[\]]'), '')
        .trim();
  }

  static PdfColor _colorNivel(String nivel) {
    switch (nivel.toLowerCase()) {
      case 'urgente': case 'rojo':    return PdfColors.red700;
      case 'alerta':  case 'naranja': return PdfColors.orange700;
      default:                        return const PdfColor.fromInt(0xFF1D9E75);
    }
  }

  static String _formatFecha(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      // Convertir a hora local del dispositivo (Colombia UTC-5)
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return iso; }
  }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/responsive.dart';
import '../database/database_helper.dart';
import '../services/pdf_service.dart';

const Color _kVerde  = Color(0xFF1D9E75);
DispersaludColors _c(BuildContext ctx) =>
    Theme.of(ctx).extension<DispersaludColors>() ?? DispersaludColors.dark;

class HistorialScreen extends StatefulWidget {
  final int    pacienteId;
  final String nombre;
  HistorialScreen({super.key, required this.pacienteId, required this.nombre});
  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  List<Map<String, dynamic>> _consultas = [];
  Map<String, dynamic>?      _paciente;
  bool _cargando    = true;
  bool _exportando  = false;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final p = await DatabaseHelper.instance.obtenerPaciente(widget.pacienteId);
    final c = await DatabaseHelper.instance.consultasDePaciente(widget.pacienteId);
    setState(() { _paciente = p; _consultas = c; _cargando = false; });
  }

  Future<void> _exportarPdf() async {
    setState(() => _exportando = true);
    try {
      await PdfService.generarYCompartir(
        context:         context,
        pacienteId:      widget.pacienteId,
        pacienteNombre:  widget.nombre,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al generar PDF: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  Color _nivelColor(String? nivel) {
    switch (nivel?.toLowerCase()) {
      case 'urgente': case 'rojo':    return Colors.red;
      case 'alerta':  case 'naranja': return Colors.orange;
      default:                        return _kVerde;
    }
  }

  String _formatFecha(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}  ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) { return iso; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _c(context).bg,
      appBar: AppBar(
        backgroundColor: _c(context).bg, foregroundColor: _c(context).textPrimary,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.nombre,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          Text('Historial clínico',
              style: TextStyle(color: _c(context).textHint, fontSize: 12)),
        ]),
        // ── Botón exportar PDF ────────────────────────────────────────
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _exportando
                ? Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: _kVerde, strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    onPressed: _exportarPdf,
                    tooltip: 'Exportar PDF',
                    icon: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _kVerde.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: _kVerde.withOpacity(0.4)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.picture_as_pdf_outlined,
                            color: _kVerde, size: 16),
                        SizedBox(width: 4),
                        Text('PDF',
                            style: TextStyle(
                                color: _kVerde,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
          ),
        ],
      ),
      body: ResponsiveCenter(child: _cargando
          ? Center(
              child: CircularProgressIndicator(color: Color(0xFF1D9E75)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(children: [

                // ── Datos del paciente ──────────────────────────────────
                if (_paciente != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: _c(context).card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _c(context).border),
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('👤 Datos del paciente',
                          style: TextStyle(
                              color: _c(context).textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 12),
                      _InfoRow(label: 'Documento',
                          value: _paciente!['documento'] ?? '—'),
                      _InfoRow(label: 'Fecha nac.',
                          value: _paciente!['fecha_nac'] ?? '—'),
                      _InfoRow(label: 'Sexo',
                          value: _paciente!['sexo'] ?? '—'),
                      _InfoRow(label: 'Vereda',
                          value: _paciente!['vereda'] ?? '—'),
                      _InfoRow(label: 'Municipio',
                          value: _paciente!['municipio'] ?? '—'),
                      _InfoRow(label: 'Teléfono',
                          value: _paciente!['telefono'] ?? '—'),
                      _InfoRow(label: 'Módulo',
                          value: _paciente!['modulo'] ?? '—'),
                    ]),
                  ),

                // ── Consultas ───────────────────────────────────────────
                Row(children: [
                  Text('Consultas registradas',
                      style: TextStyle(
                          color: _c(context).textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _kVerde.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${_consultas.length} total',
                        style: TextStyle(
                            color: Color(0xFF1D9E75),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
                SizedBox(height: 12),

                if (_consultas.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                        color: _c(context).card,
                        borderRadius: BorderRadius.circular(14)),
                    child: Center(
                        child: Text('Sin consultas registradas aún.',
                            style: TextStyle(
                                color: _c(context).textHint, fontSize: 14))),
                  )
                else
                  ..._consultas.map((c) {
                    final color = _nivelColor(c['nivel_riesgo']);
                    Map<String, dynamic> datos = {};
                    try {
                      datos = jsonDecode(c['datos_json'] ?? '{}');
                    } catch (_) {}
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _c(context).card,
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: color.withOpacity(0.4)),
                      ),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(c['modulo'] ?? '',
                                style: TextStyle(
                                    color: color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ),
                          Spacer(),
                          Text(_formatFecha(c['fecha']),
                              style: TextStyle(
                                  color: _c(context).textHint, fontSize: 11)),
                        ]),
                        if ((c['diagnostico'] ?? '').isNotEmpty) ...[
                          SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(c['diagnostico'],
                                style: TextStyle(
                                    color: color,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500)),
                          ),
                        ],
                        if (datos.isNotEmpty) ...[
                          SizedBox(height: 10),
                          ...datos.entries.take(5).map((e) =>
                              _InfoRow(
                                  label: e.key,
                                  value: e.value.toString())),
                        ],
                      ]),
                    );
                  }),
                SizedBox(height: 24),
              ]),
            ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      SizedBox(
          width: 100,
          child: Text(label,
              style:
                  TextStyle(color: _c(context).textHint, fontSize: 12))),
      Expanded(
          child: Text(value,
              style: TextStyle(
                  color: _c(context).textPrimary, fontSize: 13))),
    ]),
  );
}
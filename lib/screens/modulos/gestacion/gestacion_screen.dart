import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../database/database_helper.dart';

const Color _kPink   = Color(0xFF8E2C52);
const Color _kBg     = Color(0xFF111111);
const Color _kCard   = Color(0xFF1E1E1E);
const Color _kBorder = Color(0xFF2A2A2A);

class GestacionScreen extends StatefulWidget {
  final int?    pacienteId;
  final String? pacienteNombre;
  const GestacionScreen({super.key, this.pacienteId, this.pacienteNombre});
  @override
  State<GestacionScreen> createState() => _GestacionScreenState();
}

class _GestacionScreenState extends State<GestacionScreen> {
  final _semanasCtrl = TextEditingController(text: '28');
  final _edadCtrl    = TextEditingController(text: '24');
  final _presionCtrl = TextEditingController(text: '110/70');
  final _pesoCtrl    = TextEditingController(text: '62');
  final _alturaCtrl  = TextEditingController(text: '27');
  final _fcfCtrl     = TextEditingController(text: '148');

  bool _toxoide     = true;
  bool _acidoFolico = true;
  bool _ecografia   = false;
  bool _hemoglobina = false;

  String _diagnostico  = '';
  String _nivelRiesgo  = '';
  Color  _colorDx      = Colors.green;
  bool   _guardando    = false;

  // ── Selección de paciente ──────────────────────────────────────────────
  int?    _pacienteId;
  String  _pacienteNombre = 'Sin paciente seleccionado';
  List<Map<String, dynamic>> _listaPacientes = [];

  @override
  void initState() {
    super.initState();
    _pacienteId     = widget.pacienteId;
    _pacienteNombre = widget.pacienteNombre ?? 'Sin paciente seleccionado';
    _cargarPacientes();
  }

  Future<void> _cargarPacientes() async {
    final lista = await DatabaseHelper.instance.obtenerPacientes();
    setState(() => _listaPacientes = lista);
  }

  Future<void> _seleccionarPaciente() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Seleccionar paciente', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: _listaPacientes.isEmpty
              ? const Center(child: Text('No hay pacientes registrados.\nVe a la pestaña Pacientes y registra uno primero.',
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  itemCount: _listaPacientes.length,
                  itemBuilder: (_, i) {
                    final p = _listaPacientes[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _kPink.withOpacity(0.2),
                        child: Text((p['nombre'] as String)[0].toUpperCase(),
                            style: const TextStyle(color: _kPink, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(p['nombre'] ?? '', style: const TextStyle(color: Colors.white)),
                      subtitle: Text('${p['vereda'] ?? ''} · ${p['municipio'] ?? ''}',
                          style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      onTap: () {
                        setState(() {
                          _pacienteId     = p['id'];
                          _pacienteNombre = p['nombre'];
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _analizarYGuardar() async {
    // 1 — Calcular diagnóstico
    final presionSist = int.tryParse(_presionCtrl.text.split('/').first) ?? 0;
    final semanas     = int.tryParse(_semanasCtrl.text) ?? 0;

    String dx; String nivel;
    if (presionSist >= 140) {
      dx    = '⚠️ Presión elevada ($presionSist mmHg). Riesgo de preeclampsia. Remisión inmediata a ginecobstetricia.';
      nivel = 'urgente';
      _colorDx = Colors.red;
    } else if (!_hemoglobina) {
      dx    = '🩸 Hemoglobina baja detectada. Reforzar suplementación con hierro + vitamina C.';
      nivel = 'alerta';
      _colorDx = Colors.orange;
    } else if (!_ecografia && semanas >= 18) {
      dx    = '📋 Ecografía de 2.° trimestre pendiente. Programar cita con imágenes.';
      nivel = 'alerta';
      _colorDx = Colors.orange;
    } else {
      dx    = '✅ Control prenatal estable. Semana $semanas — Continuar seguimiento mensual.';
      nivel = 'normal';
      _colorDx = Colors.green;
    }

    setState(() { _diagnostico = dx; _nivelRiesgo = nivel; });

    // 2 — Guardar en SQLite si hay paciente seleccionado
    if (_pacienteId != null) {
      setState(() => _guardando = true);
      final datos = {
        'semanas':      _semanasCtrl.text,
        'edad':         _edadCtrl.text,
        'presion':      _presionCtrl.text,
        'peso':         _pesoCtrl.text,
        'altura_uter':  _alturaCtrl.text,
        'fcf':          _fcfCtrl.text,
        'toxoide':      _toxoide,
        'acido_folico': _acidoFolico,
        'ecografia':    _ecografia,
        'hemoglobina':  _hemoglobina,
      };
      await DatabaseHelper.instance.insertarConsulta({
        'paciente_id':  _pacienteId,
        'modulo':       'Gestación',
        'fecha':        DateTime.now().toIso8601String(),
        'datos_json':   jsonEncode(datos),
        'diagnostico':  dx,
        'nivel_riesgo': nivel,
      });
      setState(() => _guardando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Control guardado para $_pacienteNombre ✓'),
          backgroundColor: _kPink,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('⚠️ Selecciona un paciente para guardar la consulta'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  void _remitir() {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: _kCard,
      title: const Text('Remitir a ginecobstetricia', style: TextStyle(color: Colors.white)),
      content: const Text('¿Confirmas la remisión de esta paciente a ginecobstetricia?', style: TextStyle(color: Colors.white70)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _kPink),
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('Remisión generada exitosamente'),
              backgroundColor: _kPink, behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ));
          },
          child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }

  @override
  void dispose() {
    for (final c in [_semanasCtrl, _edadCtrl, _presionCtrl, _pesoCtrl, _alturaCtrl, _fcfCtrl]) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kPink, foregroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => Navigator.pop(context)),
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Gestación', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text('Control prenatal · DISPERSALUD IA', style: TextStyle(color: Colors.white70, fontSize: 11)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(children: [

          // ── Selector de paciente ──────────────────────────────────────
          GestureDetector(
            onTap: _seleccionarPaciente,
            child: Container(
              width: double.infinity, padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _pacienteId != null ? _kPink.withOpacity(0.15) : _kCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _pacienteId != null ? _kPink : Colors.white24),
              ),
              child: Row(children: [
                Icon(_pacienteId != null ? Icons.person_rounded : Icons.person_add_outlined,
                    color: _pacienteId != null ? _kPink : Colors.white38, size: 22),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_pacienteId != null ? 'Paciente seleccionado' : 'Seleccionar paciente',
                      style: TextStyle(color: _pacienteId != null ? _kPink : Colors.white54, fontSize: 11)),
                  Text(_pacienteNombre,
                      style: TextStyle(color: _pacienteId != null ? Colors.white : Colors.white38,
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ])),
                Icon(Icons.chevron_right, color: _pacienteId != null ? _kPink : Colors.white24, size: 20),
              ]),
            ),
          ),
          const SizedBox(height: 14),

          // ── Datos de la gestante ───────────────────────────────────────
          _Card(titulo: 'Datos de la gestante', child: Column(children: [
            Row(children: [
              Expanded(child: _Campo(label: 'Semanas de gestación', controller: _semanasCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _Campo(label: 'Edad (años)', controller: _edadCtrl)),
            ]),
          ])),
          const SizedBox(height: 14),

          // ── Signos vitales ─────────────────────────────────────────────
          _Card(titulo: 'Signos vitales y control', child: Column(children: [
            _Campo(label: 'Tensión arterial (sistólica/diastólica)', controller: _presionCtrl),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _Campo(label: 'Peso (kg)', controller: _pesoCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _Campo(label: 'Altura uterina (cm)', controller: _alturaCtrl)),
            ]),
            const SizedBox(height: 12),
            _Campo(label: 'Frecuencia cardiaca fetal (lpm)', controller: _fcfCtrl),
          ])),
          const SizedBox(height: 14),

          // ── Lista de chequeo ───────────────────────────────────────────
          _Card(titulo: 'Lista de chequeo prenatal', child: Column(children: [
            _CheckItem(texto: 'Toxoide tetánico aplicado — dosis 2 completa', activo: _toxoide, color: Colors.green, onChanged: (v) => setState(() => _toxoide = v)),
            _CheckItem(texto: 'Ácido fólico + hierro suministrado', activo: _acidoFolico, color: Colors.green, onChanged: (v) => setState(() => _acidoFolico = v)),
            _CheckItem(texto: 'Ecografía 2.° trimestre realizada', activo: _ecografia, color: Colors.orange, onChanged: (v) => setState(() => _ecografia = v)),
            _CheckItem(texto: 'Hemoglobina en rango normal (≥11 g/dL)', activo: _hemoglobina, color: Colors.orange, onChanged: (v) => setState(() => _hemoglobina = v)),
          ])),
          const SizedBox(height: 14),

          // ── Diagnóstico IA ─────────────────────────────────────────────
          if (_diagnostico.isNotEmpty)
            Container(
              width: double.infinity, padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _colorDx.withOpacity(0.12), borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _colorDx.withOpacity(0.5)),
              ),
              child: Text(_diagnostico, style: TextStyle(color: _colorDx, fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          const SizedBox(height: 20),

          // ── Botón analizar y guardar ───────────────────────────────────
          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              onPressed: _guardando ? null : _analizarYGuardar,
              icon: _guardando
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.psychology_outlined, color: Colors.white),
              label: Text(_guardando ? 'Guardando...' : 'Analizar y guardar',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: _kPink,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, height: 52,
            child: OutlinedButton.icon(
              onPressed: _remitir,
              icon: const Icon(Icons.local_hospital_outlined, color: Colors.white70),
              label: const Text('Remitir a ginecobstetricia', style: TextStyle(color: Colors.white70, fontSize: 15)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String titulo; final Widget child;
  const _Card({required this.titulo, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(titulo, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16), child,
    ]),
  );
}

class _Campo extends StatelessWidget {
  final String label; final TextEditingController controller;
  const _Campo({required this.label, required this.controller});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
    const SizedBox(height: 4),
    TextField(controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        filled: true, fillColor: _kBorder,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
    ),
  ]);
}

class _CheckItem extends StatelessWidget {
  final String texto; final bool activo; final Color color; final ValueChanged<bool> onChanged;
  const _CheckItem({required this.texto, required this.activo, required this.color, required this.onChanged});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: GestureDetector(onTap: () => onChanged(!activo), child: Row(children: [
      Icon(activo ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          color: activo ? color : Colors.white24, size: 20),
      const SizedBox(width: 10),
      Expanded(child: Text(texto, style: TextStyle(color: activo ? Colors.white : Colors.white38, fontSize: 13))),
    ])),
  );
}
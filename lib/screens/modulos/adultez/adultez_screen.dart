import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';
import '../../../database/database_helper.dart';

const Color _kColor = Color(0xFF0F6E56);

class AdultezScreen extends StatefulWidget {
  final int?    pacienteId;
  final String? pacienteNombre;
  const AdultezScreen({super.key, this.pacienteId, this.pacienteNombre});
  @override
  State<AdultezScreen> createState() => _AdultezScreenState();
}

class _AdultezScreenState extends State<AdultezScreen> {
  final _nombreCtrl    = TextEditingController(text: '');
  final _edadCtrl      = TextEditingController(text: '45 años');
  final _presionCtrl   = TextEditingController(text: '138/88');
  final _glucemiaCtrl  = TextEditingController(text: '112');
  final _pesoCtrl      = TextEditingController(text: '82');
  final _tallaCtrl     = TextEditingController(text: '170');
  final _colesterolCtrl= TextEditingController(text: '210');
  final _cinturaCtrl   = TextEditingController(text: '96');

  bool _hipertension     = true;
  bool _diabetes         = false;
  bool _adherenciaTto    = true;
  bool _fumador          = false;
  bool _ejercicioRegular = false;
  bool _papOmamografia   = false;
  bool _influenza        = true;

  String _diagnostico = '';
  // ignore: unused_field
  String _nivelRiesgo = '';
  Color  _colorDx     = Colors.green;
  bool   _guardando   = false;

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
      isScrollControlled: true,
      backgroundColor: DT(context).card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final dc = DT(ctx);
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          maxChildSize: 0.90,
          minChildSize: 0.35,
          builder: (_, scrollCtrl) => Column(children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: dc.border, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text('Seleccionar paciente',
                  style: TextStyle(
                      color: dc.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: _listaPacientes.isEmpty
                  ? Center(
                      child: Text(
                        'No hay pacientes.\nRegistra uno en la pestaña Pacientes.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: dc.textHint),
                      ))
                  : ListView.builder(
                      controller: scrollCtrl,
                      itemCount: _listaPacientes.length,
                      itemBuilder: (_, i) {
                        final p = _listaPacientes[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _kColor.withValues(alpha: 0.2),
                            child: Text(
                              (p['nombre'] as String)[0].toUpperCase(),
                              style: const TextStyle(
                                  color: _kColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(p['nombre'] ?? '',
                              style: TextStyle(color: dc.textPrimary)),
                          subtitle: Text(
                            '${p['vereda'] ?? ''} · ${p['municipio'] ?? ''}',
                            style: TextStyle(color: dc.textHint, fontSize: 12),
                          ),
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
          ]),
        );
      },
    );
  }

  Future<void> _analizarYGuardar() async {
    final presion    = int.tryParse(_presionCtrl.text.split('/').first) ?? 0;
    final glucemia   = double.tryParse(_glucemiaCtrl.text)   ?? 0;
    final colesterol = double.tryParse(_colesterolCtrl.text) ?? 0;
    final peso       = double.tryParse(_pesoCtrl.text)       ?? 0;
    final talla      = double.tryParse(_tallaCtrl.text)      ?? 1;
    final imc        = talla > 0 ? peso / ((talla / 100) * (talla / 100)) : 0;

    String dx; String nivel; Color color;

    if (presion >= 160) {
      dx    = '🚨 Crisis hipertensiva ($presion mmHg). Remisión de urgencia inmediata.';
      nivel = 'urgente'; color = Colors.red;
    } else if (glucemia >= 200) {
      dx    = '🩸 Glucemia muy elevada ($glucemia mg/dL). Riesgo de descompensación diabética. Remitir.';
      nivel = 'urgente'; color = Colors.red;
    } else if (presion >= 140 && !_adherenciaTto) {
      dx    = '⚠️ HTA no controlada + baja adherencia. Reforzar tratamiento farmacológico.';
      nivel = 'alerta'; color = Colors.orange;
    } else if (glucemia >= 126 && !_diabetes) {
      dx    = '🩸 Glucemia $glucemia mg/dL. Probable diabetes tipo 2. Solicitar HbA1c.';
      nivel = 'alerta'; color = Colors.orange;
    } else if (imc >= 30) {
      dx    = '⚖️ Obesidad (IMC ${imc.toStringAsFixed(1)}). Alto riesgo cardiovascular. Plan de ejercicio y dieta.';
      nivel = 'alerta'; color = Colors.orange;
    } else if (colesterol > 240) {
      dx    = '🫀 Colesterol elevado ($colesterol mg/dL). Reforzar estatinas y dieta cardioprotectora.';
      nivel = 'alerta'; color = Colors.orange;
    } else {
      dx    = '✅ Adulto con factores controlados. Continuar seguimiento semestral.';
      nivel = 'normal'; color = Colors.green;
    }

    setState(() { _diagnostico = dx; _nivelRiesgo = nivel; _colorDx = color; });

    if (_pacienteId != null) {
      setState(() => _guardando = true);
      final datos = {
        'nombre':          _nombreCtrl.text,
        'edad':            _edadCtrl.text,
        'presion':         _presionCtrl.text,
        'glucemia':        _glucemiaCtrl.text,
        'peso':            _pesoCtrl.text,
        'talla':           _tallaCtrl.text,
        'colesterol':      _colesterolCtrl.text,
        'cintura':         _cinturaCtrl.text,
        'hipertension':    _hipertension,
        'diabetes':        _diabetes,
        'adherenciaTto':   _adherenciaTto,
        'fumador':         _fumador,
        'ejercicioRegular':_ejercicioRegular,
        'papOmamografia':  _papOmamografia,
        'influenza':       _influenza,
      };
      await DatabaseHelper.instance.insertarConsulta({
        'paciente_id':  _pacienteId,
        'modulo':       'Adultez',
        'fecha':        DateTime.now().toIso8601String(),
        'datos_json':   jsonEncode(datos),
        'diagnostico':  dx,
        'nivel_riesgo': nivel,
      });
      setState(() => _guardando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Consulta guardada para $_pacienteNombre ✓'),
          backgroundColor: _kColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('⚠️ Selecciona un paciente para guardar la consulta'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  void dispose() {
    for (final c in [_nombreCtrl, _edadCtrl, _presionCtrl, _glucemiaCtrl,
                     _pesoCtrl, _tallaCtrl, _colesterolCtrl, _cinturaCtrl])
      c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dt = DT(context);
    return Scaffold(
      backgroundColor: dt.bg,
      appBar: AppBar(
        backgroundColor: _kColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Adultez',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          Text('29–59 años · Enfermedades crónicas · DISPERSALUD IA',
              style: TextStyle(color: Colors.white70, fontSize: 11)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(children: [

          // ── Selector paciente ──────────────────────────────────────
          GestureDetector(
            onTap: _seleccionarPaciente,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _pacienteId != null
                    ? _kColor.withValues(alpha: 0.15)
                    : dt.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: _pacienteId != null ? _kColor : dt.border),
              ),
              child: Row(children: [
                Icon(
                  _pacienteId != null
                      ? Icons.person_rounded
                      : Icons.person_add_outlined,
                  color: _pacienteId != null ? _kColor : dt.textHint,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                    _pacienteId != null
                        ? 'Paciente seleccionado'
                        : 'Seleccionar paciente',
                    style: TextStyle(
                        color: _pacienteId != null ? _kColor : dt.textSecondary,
                        fontSize: 11),
                  ),
                  Text(
                    _pacienteNombre,
                    style: TextStyle(
                        color: _pacienteId != null
                            ? dt.textPrimary
                            : dt.textHint,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                ])),
                Icon(Icons.chevron_right,
                    color: _pacienteId != null ? _kColor : dt.textHint,
                    size: 20),
              ]),
            ),
          ),
          const SizedBox(height: 14),

          // ── Datos del paciente ─────────────────────────────────────
          _Card(titulo: 'Datos del paciente', child: Column(children: [
            Row(children: [
              Expanded(child: _Campo(label: 'Nombre completo', controller: _nombreCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _Campo(label: 'Edad', controller: _edadCtrl)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _Campo(label: 'Presión arterial', controller: _presionCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _Campo(label: 'Glucemia (mg/dL)', controller: _glucemiaCtrl)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _Campo(label: 'Peso (kg)', controller: _pesoCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _Campo(label: 'Talla (cm)', controller: _tallaCtrl)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _Campo(label: 'Colesterol total (mg/dL)', controller: _colesterolCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _Campo(label: 'Cintura (cm)', controller: _cinturaCtrl)),
            ]),
          ])),
          const SizedBox(height: 14),

          // ── Lista de chequeo ───────────────────────────────────────
          _Card(titulo: 'Lista de chequeo', child: Column(children: [
            _CheckItem(texto: 'Hipertensión arterial diagnosticada',  activo: _hipertension,     color: Colors.orange, onChanged: (v) => setState(() => _hipertension = v)),
            _CheckItem(texto: 'Diabetes mellitus tipo 2',             activo: _diabetes,         color: Colors.orange, onChanged: (v) => setState(() => _diabetes = v)),
            _CheckItem(texto: 'Buena adherencia al tratamiento',      activo: _adherenciaTto,    color: Colors.green,  onChanged: (v) => setState(() => _adherenciaTto = v)),
            _CheckItem(texto: 'Fumador activo',                       activo: _fumador,          color: Colors.red,    onChanged: (v) => setState(() => _fumador = v)),
            _CheckItem(texto: 'Realiza actividad física regular',     activo: _ejercicioRegular, color: Colors.green,  onChanged: (v) => setState(() => _ejercicioRegular = v)),
            _CheckItem(texto: 'Citología/PAP o mamografía vigente',   activo: _papOmamografia,   color: Colors.blue,   onChanged: (v) => setState(() => _papOmamografia = v)),
            _CheckItem(texto: 'Influenza anual aplicada',             activo: _influenza,        color: Colors.green,  onChanged: (v) => setState(() => _influenza = v)),
          ])),

          // ── Diagnóstico IA ─────────────────────────────────────────
          if (_diagnostico.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _colorDx.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _colorDx.withValues(alpha: 0.5)),
              ),
              child: Text(_diagnostico,
                  style: TextStyle(
                      color: _colorDx,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ),
          ],
          const SizedBox(height: 20),

          // ── Botones ────────────────────────────────────────────────
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              onPressed: _guardando ? null : _analizarYGuardar,
              icon: _guardando
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.psychology_outlined, color: Colors.white),
              label: Text(
                _guardando ? 'Guardando...' : 'Analizar y guardar',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, height: 52,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: Icon(Icons.local_hospital_outlined, color: dt.textSecondary),
              label: Text('Remitir a medicina interna',
                  style: TextStyle(color: dt.textSecondary, fontSize: 15)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: dt.border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final String titulo;
  final Widget child;
  const _Card({required this.titulo, required this.child});

  @override
  Widget build(BuildContext context) {
    final dt = DT(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dt.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dt.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titulo,
            style: TextStyle(
                color: dt.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        child,
      ]),
    );
  }
}

class _Campo extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const _Campo({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    final dt = DT(context); // ← definido aquí, en su propio build
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: dt.textHint, fontSize: 11)),
      const SizedBox(height: 4),
      TextField(
        controller: controller,
        style: TextStyle(
            color: dt.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          filled: true,
          fillColor: dt.border.withValues(alpha: 0.4),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
        ),
      ),
    ]);
  }
}

class _CheckItem extends StatelessWidget {
  final String texto;
  final bool activo;
  final Color color;
  final ValueChanged<bool> onChanged;
  const _CheckItem({
    required this.texto,
    required this.activo,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dt = DT(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => onChanged(!activo),
        child: Row(children: [
          Icon(
            activo
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: activo ? color : dt.border,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(texto,
                style: TextStyle(
                    color: activo ? dt.textPrimary : dt.textHint,
                    fontSize: 13)),
          ),
        ]),
      ),
    );
  }
}
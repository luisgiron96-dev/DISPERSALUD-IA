import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';
import '../../../database/database_helper.dart';

const Color _kColor = Color(0xFF854F0B);

class PrimeraInfanciaScreen extends StatefulWidget {
  final int?    pacienteId;
  final String? pacienteNombre;
  const PrimeraInfanciaScreen({super.key, this.pacienteId, this.pacienteNombre});
  @override
  State<PrimeraInfanciaScreen> createState() => _PrimeraInfanciaScreenState();
}

class _PrimeraInfanciaScreenState extends State<PrimeraInfanciaScreen> {
  final _nombreCtrl    = TextEditingController(text: '');
  final _edadCtrl      = TextEditingController(text: '2 años');
  final _pesoCtrl      = TextEditingController(text: '12.5');
  final _tallaCtrl     = TextEditingController(text: '87');
  final _tempCtrl      = TextEditingController(text: '36.5');
  final _perimCefCtrl  = TextEditingController(text: '48');

  bool _caminaOcorre    = true;
  bool _habla2palabras  = true;
  bool _senala          = true;
  bool _pentavalente    = true;
  bool _srp             = true;
  bool _varicela        = false;
  bool _micronutrientes = true;

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
                  style: TextStyle(color: dc.textPrimary, fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: _listaPacientes.isEmpty
                  ? Center(child: Text(
                      'No hay pacientes.\nRegistra uno en la pestaña Pacientes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: dc.textHint)))
                  : ListView.builder(
                      controller: scrollCtrl,
                      itemCount: _listaPacientes.length,
                      itemBuilder: (_, i) {
                        final p = _listaPacientes[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _kColor.withValues(alpha: 0.2),
                            child: Text((p['nombre'] as String)[0].toUpperCase(),
                                style: const TextStyle(color: _kColor,
                                    fontWeight: FontWeight.bold)),
                          ),
                          title: Text(p['nombre'] ?? '',
                              style: TextStyle(color: dc.textPrimary)),
                          subtitle: Text(
                              '${p['vereda'] ?? ''} · ${p['municipio'] ?? ''}',
                              style: TextStyle(color: dc.textHint, fontSize: 12)),
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
    final temp  = double.tryParse(_tempCtrl.text)  ?? 36.5;
    final peso  = double.tryParse(_pesoCtrl.text)  ?? 0;
    final talla = double.tryParse(_tallaCtrl.text) ?? 1;
    final imc   = talla > 0 ? peso / ((talla / 100) * (talla / 100)) : 0;
    String dx; String nivel; Color color;
    if (temp > 38.0) {
      dx = '🌡️ Fiebre ${temp}°C. Evaluar causa, hidratación y antipiréticos según peso.';
      nivel = 'urgente'; color = Colors.red;
    } else if (imc < 14) {
      dx = '⚠️ Posible desnutrición. Peso/talla bajo. Referir a nutrición y programa ICBF.';
      nivel = 'alerta'; color = Colors.orange;
    } else if (!_srp || !_pentavalente) {
      dx = '💉 Esquema de vacunación incompleto. Programar jornada urgente.';
      nivel = 'alerta'; color = Colors.orange;
    } else if (!_caminaOcorre || !_habla2palabras) {
      dx = '🧒 Posible retraso en hitos del desarrollo. Referir a valoración infantil.';
      nivel = 'alerta'; color = Colors.orange;
    } else {
      dx = '✅ Niño/a con desarrollo adecuado. Continuar controles de crecimiento.';
      nivel = 'normal'; color = Colors.green;
    }
    setState(() { _diagnostico = dx; _nivelRiesgo = nivel; _colorDx = color; });
    if (_pacienteId != null) {
      setState(() => _guardando = true);
      await DatabaseHelper.instance.insertarConsulta({
        'paciente_id': _pacienteId, 'modulo': 'Primera infancia',
        'fecha': DateTime.now().toIso8601String(),
        'datos_json': jsonEncode({'nombre': _nombreCtrl.text, 'edad': _edadCtrl.text,
          'peso': _pesoCtrl.text, 'talla': _tallaCtrl.text, 'temp': _tempCtrl.text,
          'perimCef': _perimCefCtrl.text, 'caminaOcorre': _caminaOcorre,
          'habla2palabras': _habla2palabras, 'senala': _senala,
          'pentavalente': _pentavalente, 'srp': _srp, 'varicela': _varicela,
          'micronutrientes': _micronutrientes}),
        'diagnostico': dx, 'nivel_riesgo': nivel,
      });
      setState(() => _guardando = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Consulta guardada para $_pacienteNombre ✓'),
        backgroundColor: _kColor, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('⚠️ Selecciona un paciente para guardar la consulta'),
        backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating));
    }
  }

  @override
  void dispose() {
    for (final c in [_nombreCtrl, _edadCtrl, _pesoCtrl, _tallaCtrl, _tempCtrl, _perimCefCtrl]) c.dispose();
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
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Primera Infancia',
              style: const TextStyle(color: Colors.white, fontSize: 17,
                  fontWeight: FontWeight.bold)),
          const Text('0–5 años · Crecimiento · DISPERSALUD IA',
              style: TextStyle(color: Colors.white70, fontSize: 11)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(children: [

          GestureDetector(
            onTap: _seleccionarPaciente,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _pacienteId != null
                    ? _kColor.withValues(alpha: 0.15) : dt.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: _pacienteId != null ? _kColor : dt.border),
              ),
              child: Row(children: [
                Icon(_pacienteId != null
                    ? Icons.person_rounded : Icons.person_add_outlined,
                    color: _pacienteId != null ? _kColor : dt.textHint,
                    size: 22),
                const SizedBox(width: 12),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_pacienteId != null
                      ? 'Paciente seleccionado' : 'Seleccionar paciente',
                      style: TextStyle(
                          color: _pacienteId != null ? _kColor : dt.textSecondary,
                          fontSize: 11)),
                  Text(_pacienteNombre,
                      style: TextStyle(
                          color: _pacienteId != null
                              ? dt.textPrimary : dt.textHint,
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ])),
                Icon(Icons.chevron_right,
                    color: _pacienteId != null ? _kColor : dt.textHint,
                    size: 20),
              ]),
            ),
          ),
          const SizedBox(height: 14),

          _Card(titulo: 'Datos del paciente', child: Column(children: [
            Row(children: [
              Expanded(child: _Campo(label: 'Nombre completo', controller: _nombreCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _Campo(label: 'Edad', controller: _edadCtrl)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _Campo(label: 'Peso (kg)', controller: _pesoCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _Campo(label: 'Talla (cm)', controller: _tallaCtrl)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _Campo(label: 'Temperatura (°C)', controller: _tempCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _Campo(label: 'Perímetro cefálico (cm)', controller: _perimCefCtrl)),
            ]),
          ])),
          const SizedBox(height: 14),

          _Card(titulo: 'Lista de chequeo', child: Column(children: [
            _CheckItem(texto: 'Camina y corre sin apoyo',            activo: _caminaOcorre,   color: Colors.green,  onChanged: (v) => setState(() => _caminaOcorre = v)),
            _CheckItem(texto: 'Dice al menos 2 palabras juntas',      activo: _habla2palabras, color: Colors.green,  onChanged: (v) => setState(() => _habla2palabras = v)),
            _CheckItem(texto: 'Señala objetos e imita acciones',      activo: _senala,         color: Colors.green,  onChanged: (v) => setState(() => _senala = v)),
            _CheckItem(texto: 'Pentavalente (3 dosis completas)',     activo: _pentavalente,   color: Colors.green,  onChanged: (v) => setState(() => _pentavalente = v)),
            _CheckItem(texto: 'SRP — triple viral (1 año)',           activo: _srp,            color: Colors.green,  onChanged: (v) => setState(() => _srp = v)),
            _CheckItem(texto: 'Varicela aplicada',                    activo: _varicela,       color: Colors.orange, onChanged: (v) => setState(() => _varicela = v)),
            _CheckItem(texto: 'Micronutrientes suministrados',        activo: _micronutrientes,color: Colors.green,  onChanged: (v) => setState(() => _micronutrientes = v)),
          ])),

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
                  style: TextStyle(color: _colorDx, fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ),
          ],
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              onPressed: _guardando ? null : _analizarYGuardar,
              icon: _guardando
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.psychology_outlined, color: Colors.white),
              label: Text(_guardando ? 'Guardando...' : 'Analizar y guardar',
                  style: const TextStyle(color: Colors.white, fontSize: 16,
                      fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14))),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, height: 52,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: Icon(Icons.local_hospital_outlined, color: dt.textSecondary),
              label: Text('Remitir a pediatría',
                  style: TextStyle(color: dt.textSecondary, fontSize: 15)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: dt.border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14))),
            ),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

// ── Widgets auxiliares — cada uno define su propio dt = DT(context) ──────────

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
            style: TextStyle(color: dt.textPrimary, fontSize: 16,
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
    final dt = DT(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: dt.textHint, fontSize: 11)),
      const SizedBox(height: 4),
      TextField(
        controller: controller,
        style: TextStyle(color: dt.textPrimary, fontSize: 14,
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
  const _CheckItem({required this.texto, required this.activo,
      required this.color, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final dt = DT(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => onChanged(!activo),
        child: Row(children: [
          Icon(activo
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
              color: activo ? color : dt.border, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(texto,
              style: TextStyle(
                  color: activo ? dt.textPrimary : dt.textHint,
                  fontSize: 13))),
        ]),
      ),
    );
  }
}
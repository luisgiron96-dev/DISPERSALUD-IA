import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';
import '../../../database/database_helper.dart';

const Color _kColor  = Color(0xFF3B6D11);
const Color _kBg     = Color(0xFF111111);
const Color _kCard   = Color(0xFF1E1E1E);
const Color _kBorder = Color(0xFF2A2A2A);

class JuventudScreen extends StatefulWidget {
  final int?    pacienteId;
  final String? pacienteNombre;
  const JuventudScreen({super.key, this.pacienteId, this.pacienteNombre});
  @override
  State<JuventudScreen> createState() => _JuventudScreenState();
}

class _JuventudScreenState extends State<JuventudScreen> {
  final _nombreCtrl = TextEditingController(text: '');
  final _edadCtrl = TextEditingController(text: '22 años');
  final _presionCtrl = TextEditingController(text: '118/76');
  final _glucemiaCtrl = TextEditingController(text: '88');
  final _pesoCtrl = TextEditingController(text: '70');
  final _tallaCtrl = TextEditingController(text: '170');

  bool _vph = true;
  bool _hepatitisB = true;
  bool _tamizajeITS = false;
  bool _anticoncepcion = false;
  bool _tabacoOSustancias = false;
  bool _actividadFisica = false;
  bool _influenza = false;

  String _diagnostico = '';
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
      builder: (ctx) {
        final _dc = Theme.of(ctx).extension<DispersaludColors>()!;
        return Column(children: [
        const Padding(padding: EdgeInsets.all(16),
          child: Text('Seleccionar paciente', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
        Expanded(
          child: _listaPacientes.isEmpty
            ? Center(child: Text('No hay pacientes.\nRegistra uno en la pestaña Pacientes.',
                  textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).extension<DispersaludColors>()!.textHint)))
            : ListView.builder(
                itemCount: _listaPacientes.length,
                itemBuilder: (_, i) {
                  final p = _listaPacientes[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _kColor.withOpacity(0.2),
                      child: Text((p['nombre'] as String)[0].toUpperCase(),
                          style: const TextStyle(color: _kColor, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(p['nombre'] ?? '', style: const TextStyle(color: Colors.white)),
                    subtitle: Text('${p['vereda'] ?? ''} · ${p['municipio'] ?? ''}',
                        style: TextStyle(color: Theme.of(context).extension<DispersaludColors>()!.textHint, fontSize: 12)),
                    onTap: () {
                      setState(() { _pacienteId = p['id']; _pacienteNombre = p['nombre']; });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
        ),
      ]),
    );
  }

  Future<void> _analizarYGuardar() async {
    // ── Diagnóstico IA ────────────────────────────────────────────────

    final presion   = int.tryParse(_presionCtrl.text.split('/').first) ?? 0;
    final glucemia  = double.tryParse(_glucemiaCtrl.text) ?? 0;
    final peso  = double.tryParse(_pesoCtrl.text) ?? 0;
    final talla = double.tryParse(_tallaCtrl.text) ?? 1;
    final imc   = talla > 0 ? peso / ((talla/100) * (talla/100)) : 0;
    String _dx; String _nivel; Color _color;
    if (presion >= 140) {
      _dx = '⚠️ Presión arterial elevada ($presion mmHg). Evaluar hipertensión. Remisión médica.';
      _nivel = 'urgente'; _color = Colors.red;
    } else if (glucemia >= 126) {
      _dx = '🩸 Glucemia elevada (${glucemia} mg/dL). Riesgo de diabetes. Solicitar HbA1c.';
      _nivel = 'urgente'; _color = Colors.red;
    } else if (_tabacoOSustancias) {
      _dx = '🚭 Consumo de sustancias. Orientar a programa de cesación y prevención.';
      _nivel = 'alerta'; _color = Colors.orange;
    } else if (imc >= 25) {
      _dx = '⚖️ IMC ${imc.toStringAsFixed(1)} — Sobrepeso. Promover actividad física y dieta saludable.';
      _nivel = 'alerta'; _color = Colors.orange;
    } else {
      _dx = '✅ Joven saludable. Continuar controles anuales y reforzar hábitos.';
      _nivel = 'normal'; _color = Colors.green;
    }

    setState(() { _diagnostico = _dx; _nivelRiesgo = _nivel; _colorDx = _color; });

    if (_pacienteId != null) {
      setState(() => _guardando = true);
      final datos = {
        'nombre': _nombreCtrl.text,
        'edad': _edadCtrl.text,
        'presion': _presionCtrl.text,
        'glucemia': _glucemiaCtrl.text,
        'peso': _pesoCtrl.text,
        'talla': _tallaCtrl.text,
        'vph': _vph,
        'hepatitisB': _hepatitisB,
        'tamizajeITS': _tamizajeITS,
        'anticoncepcion': _anticoncepcion,
        'tabacoOSustancias': _tabacoOSustancias,
        'actividadFisica': _actividadFisica,
        'influenza': _influenza,
      };
      await DatabaseHelper.instance.insertarConsulta({
        'paciente_id':  _pacienteId,
        'modulo':       'Juventud',
        'fecha':        DateTime.now().toIso8601String(),
        'datos_json':   jsonEncode(datos),
        'diagnostico':  _dx,
        'nivel_riesgo': _nivel,
      });
      setState(() => _guardando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Consulta guardada para $_pacienteNombre ✓'),
          backgroundColor: _kColor, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('⚠️ Selecciona un paciente para guardar la consulta'),
          backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose(); _edadCtrl.dispose(); _presionCtrl.dispose(); _glucemiaCtrl.dispose(); _pesoCtrl.dispose(); _tallaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).extension<DispersaludColors>()!.bg,
      appBar: AppBar(
        backgroundColor: _kColor, foregroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => Navigator.pop(context)),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Juventud', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          Text('18–28 años · Prevención y bienestar · DISPERSALUD IA', style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(children: [

          // Selector paciente
          GestureDetector(
            onTap: _seleccionarPaciente,
            child: Container(
              width: double.infinity, padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _pacienteId != null ? _kColor.withOpacity(0.15) : _kCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _pacienteId != null ? _kColor : Colors.white24),
              ),
              child: Row(children: [
                Icon(_pacienteId != null ? Icons.person_rounded : Icons.person_add_outlined,
                    color: _pacienteId != null ? _kColor : Colors.white38, size: 22),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_pacienteId != null ? 'Paciente seleccionado' : 'Seleccionar paciente',
                      style: TextStyle(color: _pacienteId != null ? _kColor : Colors.white54, fontSize: 11)),
                  Text(_pacienteNombre,
                      style: TextStyle(color: _pacienteId != null ? Colors.white : Colors.white38,
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ])),
                Icon(Icons.chevron_right, color: _pacienteId != null ? _kColor : Colors.white24, size: 20),
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
          ])),
          const SizedBox(height: 14),

          _Card(titulo: 'Lista de chequeo', child: Column(children: [
            _CheckItem(texto: 'Vacuna VPH aplicada', activo: _vph, color: Colors.green, onChanged: (v) => setState(() => _vph = v)),
            _CheckItem(texto: 'Hepatitis B esquema completo', activo: _hepatitisB, color: Colors.green, onChanged: (v) => setState(() => _hepatitisB = v)),
            _CheckItem(texto: 'Tamizaje ITS / VIH realizado', activo: _tamizajeITS, color: Colors.orange, onChanged: (v) => setState(() => _tamizajeITS = v)),
            _CheckItem(texto: 'Asesoría en anticoncepción', activo: _anticoncepcion, color: Colors.blue, onChanged: (v) => setState(() => _anticoncepcion = v)),
            _CheckItem(texto: 'Consumo de tabaco o sustancias', activo: _tabacoOSustancias, color: Colors.red, onChanged: (v) => setState(() => _tabacoOSustancias = v)),
            _CheckItem(texto: 'Realiza actividad física regular', activo: _actividadFisica, color: Colors.green, onChanged: (v) => setState(() => _actividadFisica = v)),
            _CheckItem(texto: 'Influenza anual aplicada', activo: _influenza, color: Colors.blue, onChanged: (v) => setState(() => _influenza = v)),
          ])),

          if (_diagnostico.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: _colorDx.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14), border: Border.all(color: _colorDx.withOpacity(0.5))),
              child: Text(_diagnostico, style: TextStyle(color: _colorDx, fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          ],
          const SizedBox(height: 20),

          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              onPressed: _guardando ? null : _analizarYGuardar,
              icon: _guardando
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.psychology_outlined, color: Colors.white),
              label: Text(_guardando ? 'Guardando...' : 'Analizar y guardar',
                  style: TextStyle(color: Theme.of(context).extension<DispersaludColors>()!.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: _kColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, height: 52,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.local_hospital_outlined, color: Colors.white70),
              label: const Text('Remitir a medicina general', style: TextStyle(color: Colors.white70, fontSize: 15)),
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
    decoration: BoxDecoration(color: Theme.of(context).extension<DispersaludColors>()!.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).extension<DispersaludColors>()!.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(titulo, style: TextStyle(color: Theme.of(context).extension<DispersaludColors>()!.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 14), child,
    ]),
  );
}
class _Campo extends StatelessWidget {
  final String label; final TextEditingController controller;
  const _Campo({required this.label, required this.controller});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: TextStyle(color: Theme.of(context).extension<DispersaludColors>()!.textHint, fontSize: 11)),
    const SizedBox(height: 4),
    TextField(controller: controller,
      style: TextStyle(color: Theme.of(context).extension<DispersaludColors>()!.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        filled: true, fillColor: Theme.of(context).extension<DispersaludColors>()!.border.withOpacity(0.4),
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
          color: activo ? color : Theme.of(context).extension<DispersaludColors>()!.border, size: 20),
      const SizedBox(width: 10),
      Expanded(child: Text(texto, style: TextStyle(color: activo ? Theme.of(context).extension<DispersaludColors>()!.textPrimary : Theme.of(context).extension<DispersaludColors>()!.textHint, fontSize: 13))),
    ])),
  );
}
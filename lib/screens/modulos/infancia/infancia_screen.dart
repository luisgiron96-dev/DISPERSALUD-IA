import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../database/database_helper.dart';

const Color _kColor  = Color(0xFF185FA5);
const Color _kBg     = Color(0xFF111111);
const Color _kCard   = Color(0xFF1E1E1E);
const Color _kBorder = Color(0xFF2A2A2A);

class InfanciaScreen extends StatefulWidget {
  final int?    pacienteId;
  final String? pacienteNombre;
  const InfanciaScreen({super.key, this.pacienteId, this.pacienteNombre});
  @override
  State<InfanciaScreen> createState() => _InfanciaScreenState();
}

class _InfanciaScreenState extends State<InfanciaScreen> {
  final _nombreCtrl = TextEditingController(text: '');
  final _edadCtrl = TextEditingController(text: '8 años');
  final _pesoCtrl = TextEditingController(text: '26');
  final _tallaCtrl = TextEditingController(text: '128');
  final _tempCtrl = TextEditingController(text: '36.6');
  final _presionCtrl = TextEditingController(text: '100/65');

  bool _leeYEscribe = true;
  bool _atencion = true;
  bool _visionOk = true;
  bool _audicionOk = true;
  bool _cariesActivas = false;
  bool _cepillado = true;
  bool _srp2 = true;

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
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(children: [
        const Padding(padding: EdgeInsets.all(16),
          child: Text('Seleccionar paciente', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
        Expanded(
          child: _listaPacientes.isEmpty
            ? const Center(child: Text('No hay pacientes.\nRegistra uno en la pestaña Pacientes.',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)))
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
                        style: const TextStyle(color: Colors.white54, fontSize: 12)),
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

    final temp  = double.tryParse(_tempCtrl.text) ?? 36.5;
    final peso  = double.tryParse(_pesoCtrl.text) ?? 0;
    final talla = double.tryParse(_tallaCtrl.text) ?? 1;
    final imc   = talla > 0 ? peso / ((talla/100) * (talla/100)) : 0;
    String _dx; String _nivel; Color _color;
    if (temp > 38.0) {
      _dx = '🌡️ Fiebre ${temp}°C. Evaluar causa infecciosa y antipirético.';
      _nivel = 'urgente'; _color = Colors.red;
    } else if (imc < 14.5) {
      _dx = '⚠️ Bajo peso escolar. Referir a nutrición y valorar contexto familiar.';
      _nivel = 'alerta'; _color = Colors.orange;
    } else if (!_visionOk) {
      _dx = '👁️ Posible alteración visual. Referir a optometría.';
      _nivel = 'alerta'; _color = Colors.orange;
    } else if (!_leeYEscribe || !_atencion) {
      _dx = '📚 Posible dificultad de aprendizaje. Referir a psicología escolar.';
      _nivel = 'alerta'; _color = Colors.orange;
    } else if (_cariesActivas) {
      _dx = '🦷 Caries detectadas. Referir a odontología preventiva.';
      _nivel = 'alerta'; _color = Colors.orange;
    } else {
      _dx = '✅ Escolar saludable. IMC adecuado. Continuar controles anuales.';
      _nivel = 'normal'; _color = Colors.green;
    }

    setState(() { _diagnostico = _dx; _nivelRiesgo = _nivel; _colorDx = _color; });

    if (_pacienteId != null) {
      setState(() => _guardando = true);
      final datos = {
        'nombre': _nombreCtrl.text,
        'edad': _edadCtrl.text,
        'peso': _pesoCtrl.text,
        'talla': _tallaCtrl.text,
        'temp': _tempCtrl.text,
        'presion': _presionCtrl.text,
        'leeYEscribe': _leeYEscribe,
        'atencion': _atencion,
        'visionOk': _visionOk,
        'audicionOk': _audicionOk,
        'cariesActivas': _cariesActivas,
        'cepillado': _cepillado,
        'srp2': _srp2,
      };
      await DatabaseHelper.instance.insertarConsulta({
        'paciente_id':  _pacienteId,
        'modulo':       'Infancia',
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
    _nombreCtrl.dispose(); _edadCtrl.dispose(); _pesoCtrl.dispose(); _tallaCtrl.dispose(); _tempCtrl.dispose(); _presionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kColor, foregroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => Navigator.pop(context)),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Infancia', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          Text('6–11 años · Salud escolar · DISPERSALUD IA', style: const TextStyle(color: Colors.white70, fontSize: 11)),
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
              Expanded(child: _Campo(label: 'Peso (kg)', controller: _pesoCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _Campo(label: 'Talla (cm)', controller: _tallaCtrl)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _Campo(label: 'Temperatura (°C)', controller: _tempCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _Campo(label: 'Presión arterial', controller: _presionCtrl)),
            ]),
          ])),
          const SizedBox(height: 14),

          _Card(titulo: 'Lista de chequeo', child: Column(children: [
            _CheckItem(texto: 'Lee y escribe acorde a su grado', activo: _leeYEscribe, color: Colors.green, onChanged: (v) => setState(() => _leeYEscribe = v)),
            _CheckItem(texto: 'Atención y concentración adecuada', activo: _atencion, color: Colors.green, onChanged: (v) => setState(() => _atencion = v)),
            _CheckItem(texto: 'Visión normal (sin dificultad)', activo: _visionOk, color: Colors.green, onChanged: (v) => setState(() => _visionOk = v)),
            _CheckItem(texto: 'Audición normal', activo: _audicionOk, color: Colors.green, onChanged: (v) => setState(() => _audicionOk = v)),
            _CheckItem(texto: 'Presencia de caries activas', activo: _cariesActivas, color: Colors.red, onChanged: (v) => setState(() => _cariesActivas = v)),
            _CheckItem(texto: 'Cepillado 2 veces al día', activo: _cepillado, color: Colors.green, onChanged: (v) => setState(() => _cepillado = v)),
            _CheckItem(texto: 'SRP 2.ª dosis completada', activo: _srp2, color: Colors.green, onChanged: (v) => setState(() => _srp2 = v)),
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
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: _kColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, height: 52,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.local_hospital_outlined, color: Colors.white70),
              label: const Text('Remitir a pediatría', style: TextStyle(color: Colors.white70, fontSize: 15)),
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
      const SizedBox(height: 14), child,
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
      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
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
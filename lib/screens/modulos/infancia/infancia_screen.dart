import 'package:flutter/material.dart';

const Color _kBlue   = Color(0xFF185FA5);
const Color _kBg     = Color(0xFF111111);
const Color _kCard   = Color(0xFF1E1E1E);
const Color _kBorder = Color(0xFF2A2A2A);

class InfanciaScreen extends StatefulWidget {
  const InfanciaScreen({super.key});
  @override
  State<InfanciaScreen> createState() => _InfanciaScreenState();
}

class _InfanciaScreenState extends State<InfanciaScreen> {
  final _nombreCtrl   = TextEditingController(text: 'Valentina Ríos');
  final _edadCtrl     = TextEditingController(text: '8 años');
  final _acudienteCtrl= TextEditingController(text: 'Rosa Ríos');
  final _pesoCtrl     = TextEditingController(text: '26');
  final _tallaCtrl    = TextEditingController(text: '128');
  final _tempCtrl     = TextEditingController(text: '36.6');
  final _presionCtrl  = TextEditingController(text: '100/65');

  // Desarrollo escolar
  bool _leeEscribe    = true;
  bool _atencion      = true;
  bool _relaciona     = true;
  bool _bullyingNo    = true;

  // Vacunación
  bool _srp2          = true;
  bool _vph1          = false;
  bool _influenza     = false;
  bool _td            = true;

  // Salud oral
  bool _caries        = false;
  bool _cepillado     = true;
  bool _fluoruro      = false;

  // Agudeza visual
  bool _visionOk      = true;
  bool _audicionOk    = true;

  String _diagnostico = '';
  Color  _colorDx     = Colors.green;

  double get _imc {
    final p = double.tryParse(_pesoCtrl.text) ?? 0;
    final t = (double.tryParse(_tallaCtrl.text) ?? 1) / 100;
    return t > 0 ? p / (t * t) : 0;
  }

  String get _imcEstado {
    final i = _imc;
    if (i < 14.5) return 'Bajo peso';
    if (i < 19)   return 'Normal';
    if (i < 22)   return 'Sobrepeso';
    return 'Obesidad';
  }

  Color get _imcColor {
    final s = _imcEstado;
    if (s == 'Normal')    return Colors.green;
    if (s == 'Bajo peso') return Colors.red;
    return Colors.orange;
  }

  void _guardar() {
    final temp = double.tryParse(_tempCtrl.text) ?? 36.6;
    if (temp > 38.0) {
      _diagnostico = '🌡️ Fiebre ${temp}°C. Evaluar causa infecciosa y manejo antipirético.';
      _colorDx = Colors.red;
    } else if (_imcEstado == 'Bajo peso') {
      _diagnostico = '⚠️ Bajo peso para la edad. Referir a nutrición y valorar contexto familiar.';
      _colorDx = Colors.red;
    } else if (!_visionOk) {
      _diagnostico = '👁️ Posible alteración visual. Referir a optometría o valoración oftalmológica.';
      _colorDx = Colors.orange;
    } else if (!_leeEscribe || !_atencion) {
      _diagnostico = '📚 Posible dificultad de aprendizaje. Referir a psicología escolar.';
      _colorDx = Colors.orange;
    } else if (_caries) {
      _diagnostico = '🦷 Caries detectadas. Referir a odontología preventiva y reforzar higiene oral.';
      _colorDx = Colors.orange;
    } else {
      _diagnostico = '✅ Niño/a escolar saludable. IMC adecuado. Continuar controles anuales.';
      _colorDx = Colors.green;
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Control de infancia guardado'),
      backgroundColor: _kBlue,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  void dispose() {
    _nombreCtrl.dispose(); _edadCtrl.dispose(); _acudienteCtrl.dispose();
    _pesoCtrl.dispose(); _tallaCtrl.dispose(); _tempCtrl.dispose(); _presionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBlue,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18), onPressed: () => Navigator.pop(context)),
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Infancia · 6–11 años', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          Text('Salud escolar · DISPERSALUD IA', style: TextStyle(color: Colors.white70, fontSize: 11)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(children: [

          _Card(titulo: 'Datos del escolar', child: Column(children: [
            _Campo(label: 'Nombre completo', controller: _nombreCtrl),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _Campo(label: 'Edad', controller: _edadCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _Campo(label: 'Acudiente', controller: _acudienteCtrl)),
            ]),
          ])),
          const SizedBox(height: 14),

          _Card(titulo: 'Antropometría y signos vitales', child: Column(children: [
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
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: _imcColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: _imcColor.withOpacity(0.3))),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('IMC calculado', style: TextStyle(color: Colors.white70, fontSize: 13)),
                Row(children: [
                  Text(_imc > 0 ? _imc.toStringAsFixed(1) : '--', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  _Badge(texto: _imcEstado, color: _imcColor),
                ]),
              ]),
            ),
          ])),
          const SizedBox(height: 14),

          _Card(titulo: 'Desarrollo escolar y social', child: Column(children: [
            _CheckItem(texto: 'Lee y escribe acorde a su grado', activo: _leeEscribe, color: Colors.green, onChanged: (v) => setState(() => _leeEscribe = v)),
            _CheckItem(texto: 'Atención y concentración adecuada', activo: _atencion, color: Colors.green, onChanged: (v) => setState(() => _atencion = v)),
            _CheckItem(texto: 'Se relaciona bien con compañeros', activo: _relaciona, color: Colors.green, onChanged: (v) => setState(() => _relaciona = v)),
            _CheckItem(texto: 'Sin reporte de matoneo / bullying', activo: _bullyingNo, color: Colors.green, onChanged: (v) => setState(() => _bullyingNo = v)),
          ])),
          const SizedBox(height: 14),

          _Card(titulo: 'Agudeza visual y auditiva', child: Column(children: [
            _CheckItem(texto: 'Visión normal (sin dificultad para ver)', activo: _visionOk, color: Colors.green, onChanged: (v) => setState(() => _visionOk = v)),
            _CheckItem(texto: 'Audición normal (responde al llamado)', activo: _audicionOk, color: Colors.green, onChanged: (v) => setState(() => _audicionOk = v)),
          ])),
          const SizedBox(height: 14),

          _Card(titulo: 'Salud oral', child: Column(children: [
            _CheckItem(texto: 'Presencia de caries activas', activo: _caries, color: Colors.red, onChanged: (v) => setState(() => _caries = v)),
            _CheckItem(texto: 'Cepillado 2 veces al día', activo: _cepillado, color: Colors.green, onChanged: (v) => setState(() => _cepillado = v)),
            _CheckItem(texto: 'Aplicación de fluoruro', activo: _fluoruro, color: Colors.blue, onChanged: (v) => setState(() => _fluoruro = v)),
          ])),
          const SizedBox(height: 14),

          _Card(titulo: 'Vacunación escolar', child: Column(children: [
            _CheckItem(texto: 'SRP 2.ª dosis (5 años)', activo: _srp2, color: Colors.green, onChanged: (v) => setState(() => _srp2 = v)),
            _CheckItem(texto: 'VPH 1.ª dosis (niñas 9 años)', activo: _vph1, color: Colors.orange, onChanged: (v) => setState(() => _vph1 = v)),
            _CheckItem(texto: 'Td (difteria-tétanos) refuerzo', activo: _td, color: Colors.green, onChanged: (v) => setState(() => _td = v)),
            _CheckItem(texto: 'Influenza anual', activo: _influenza, color: Colors.blue, onChanged: (v) => setState(() => _influenza = v)),
          ])),

          if (_diagnostico.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: _colorDx.withOpacity(0.12), borderRadius: BorderRadius.circular(14), border: Border.all(color: _colorDx.withOpacity(0.5))),
              child: Text(_diagnostico, style: TextStyle(color: _colorDx, fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          ],
          const SizedBox(height: 20),

          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              onPressed: _guardar,
              icon: const Icon(Icons.save_outlined, color: Colors.white),
              label: const Text('Guardar control escolar', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: _kBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, height: 52,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.local_hospital_outlined, color: Colors.white70),
              label: const Text('Remitir a pediatría', style: TextStyle(color: Colors.white70, fontSize: 15)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
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
    TextField(controller: controller, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11), filled: true, fillColor: _kBorder, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
  ]);
}
class _Badge extends StatelessWidget {
  final String texto; final Color color;
  const _Badge({required this.texto, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(color: color.withOpacity(0.18), borderRadius: BorderRadius.circular(20)),
    child: Text(texto, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
  );
}
class _CheckItem extends StatelessWidget {
  final String texto; final bool activo; final Color color; final ValueChanged<bool> onChanged;
  const _CheckItem({required this.texto, required this.activo, required this.color, required this.onChanged});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: GestureDetector(onTap: () => onChanged(!activo), child: Row(children: [
      Icon(activo ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: activo ? color : Colors.white24, size: 20),
      const SizedBox(width: 10),
      Expanded(child: Text(texto, style: TextStyle(color: activo ? Colors.white : Colors.white38, fontSize: 13))),
    ])),
  );
}
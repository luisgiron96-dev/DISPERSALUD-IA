import 'package:flutter/material.dart';

const Color _kTeal   = Color(0xFF0F6E56);
const Color _kBg     = Color(0xFF111111);
const Color _kCard   = Color(0xFF1E1E1E);
const Color _kBorder = Color(0xFF2A2A2A);

class AdultezScreen extends StatefulWidget {
  const AdultezScreen({super.key});
  @override
  State<AdultezScreen> createState() => _AdultezScreenState();
}

class _AdultezScreenState extends State<AdultezScreen> {
  final _nombreCtrl   = TextEditingController(text: 'Jorge Patiño');
  final _edadCtrl     = TextEditingController(text: '45 años');
  final _presionCtrl  = TextEditingController(text: '138/88');
  final _glucemiaCtrl = TextEditingController(text: '112');
  final _pesoCtrl     = TextEditingController(text: '82');
  final _tallaCtrl    = TextEditingController(text: '170');
  final _colesterolCtrl = TextEditingController(text: '210');
  final _cinCtrl      = TextEditingController(text: '96');

  // Enfermedades cronicas
  bool _hipertension  = true;
  bool _diabetes      = false;
  bool _dislipidemia  = true;
  bool _epoc          = false;

  // Medicamentos
  bool _tomaMetformina = false;
  bool _tomaAntihipert = true;
  bool _tomaAstatina   = true;
  bool _adherencia     = true;

  // Habitos
  bool _fuma          = false;
  bool _alcohol       = false;
  bool _ejercicio     = false;
  bool _dietaSana     = false;

  // Tamizajes
  bool _colonoscopia  = false;
  bool _mamografia    = false;
  bool _pap           = false;
  bool _ecografiaAbd  = false;

  String _diagnostico = '';
  Color  _colorDx     = Colors.green;

  double get _imc {
    final p = double.tryParse(_pesoCtrl.text) ?? 0;
    final t = (double.tryParse(_tallaCtrl.text) ?? 1) / 100;
    return t > 0 ? p / (t * t) : 0;
  }

  String get _imcEstado {
    final i = _imc;
    if (i < 18.5) return 'Bajo peso';
    if (i < 25)   return 'Normal';
    if (i < 30)   return 'Sobrepeso';
    if (i < 35)   return 'Obesidad I';
    return 'Obesidad II';
  }

  Color get _imcColor {
    final s = _imcEstado;
    if (s == 'Normal')    return Colors.green;
    if (s == 'Bajo peso') return Colors.blue;
    if (s == 'Sobrepeso') return Colors.orange;
    return Colors.red;
  }

  void _guardar() {
    final presion   = int.tryParse(_presionCtrl.text.split('/').first) ?? 0;
    final glucemia  = double.tryParse(_glucemiaCtrl.text) ?? 0;
    final colesterol = double.tryParse(_colesterolCtrl.text) ?? 0;
    final cin       = double.tryParse(_cinCtrl.text) ?? 0;

    if (presion >= 160) {
      _diagnostico = '🚨 Crisis hipertensiva (${_presionCtrl.text}). Remisión de urgencia inmediata.';
      _colorDx = Colors.red;
    } else if (glucemia >= 200) {
      _diagnostico = '🩸 Glucemia muy elevada ($glucemia mg/dL). Riesgo de descompensación diabética. Remitir.';
      _colorDx = Colors.red;
    } else if (presion >= 140 && !_adherencia) {
      _diagnostico = '⚠️ Hipertensión no controlada + baja adherencia. Reforzar tratamiento farmacológico.';
      _colorDx = Colors.orange;
    } else if (glucemia >= 126 && !_diabetes) {
      _diagnostico = '🩸 Glucemia en ayunas $glucemia mg/dL. Probable diabetes tipo 2. Solicitar HbA1c.';
      _colorDx = Colors.orange;
    } else if (_imc >= 30 || cin > 102) {
      _diagnostico = '⚖️ Obesidad abdominal detectada. Alto riesgo cardiovascular. Plan de ejercicio y dieta.';
      _colorDx = Colors.orange;
    } else if (colesterol > 240) {
      _diagnostico = '🫀 Colesterol elevado ($colesterol mg/dL). Reforzar estatinas y dieta cardioprotectora.';
      _colorDx = Colors.orange;
    } else {
      _diagnostico = '✅ Adulto con factores de riesgo controlados. Continuar seguimiento semestral.';
      _colorDx = Colors.green;
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Control de adultez guardado'),
      backgroundColor: _kTeal,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  void dispose() {
    _nombreCtrl.dispose(); _edadCtrl.dispose(); _presionCtrl.dispose();
    _glucemiaCtrl.dispose(); _pesoCtrl.dispose(); _tallaCtrl.dispose();
    _colesterolCtrl.dispose(); _cinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kTeal,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18), onPressed: () => Navigator.pop(context)),
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Adultez · 29–59 años', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          Text('Enfermedades crónicas · DISPERSALUD IA', style: TextStyle(color: Colors.white70, fontSize: 11)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(children: [

          _Card(titulo: 'Datos del adulto', child: Row(children: [
            Expanded(child: _Campo(label: 'Nombre completo', controller: _nombreCtrl)),
            const SizedBox(width: 12),
            Expanded(child: _Campo(label: 'Edad', controller: _edadCtrl)),
          ])),
          const SizedBox(height: 14),

          _Card(titulo: 'Signos vitales y métricas', child: Column(children: [
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
              Expanded(child: _Campo(label: 'Cintura (cm)', controller: _cinCtrl)),
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

          _Card(titulo: 'Enfermedades crónicas diagnosticadas', child: Column(children: [
            _CheckItem(texto: 'Hipertensión arterial', activo: _hipertension, color: Colors.orange, onChanged: (v) => setState(() => _hipertension = v)),
            _CheckItem(texto: 'Diabetes mellitus tipo 2', activo: _diabetes, color: Colors.orange, onChanged: (v) => setState(() => _diabetes = v)),
            _CheckItem(texto: 'Dislipidemia', activo: _dislipidemia, color: Colors.orange, onChanged: (v) => setState(() => _dislipidemia = v)),
            _CheckItem(texto: 'EPOC / asma', activo: _epoc, color: Colors.orange, onChanged: (v) => setState(() => _epoc = v)),
          ])),
          const SizedBox(height: 14),

          _Card(titulo: 'Medicamentos y adherencia', child: Column(children: [
            _CheckItem(texto: 'Toma metformina / hipoglucemiante', activo: _tomaMetformina, color: Colors.blue, onChanged: (v) => setState(() => _tomaMetformina = v)),
            _CheckItem(texto: 'Toma antihipertensivo', activo: _tomaAntihipert, color: Colors.blue, onChanged: (v) => setState(() => _tomaAntihipert = v)),
            _CheckItem(texto: 'Toma estatina (colesterol)', activo: _tomaAstatina, color: Colors.blue, onChanged: (v) => setState(() => _tomaAstatina = v)),
            _CheckItem(texto: 'Buena adherencia al tratamiento', activo: _adherencia, color: Colors.green, onChanged: (v) => setState(() => _adherencia = v)),
          ])),
          const SizedBox(height: 14),

          _Card(titulo: 'Hábitos y estilo de vida', child: Column(children: [
            _CheckItem(texto: 'Fumador activo', activo: _fuma, color: Colors.red, onChanged: (v) => setState(() => _fuma = v)),
            _CheckItem(texto: 'Consumo de alcohol frecuente', activo: _alcohol, color: Colors.orange, onChanged: (v) => setState(() => _alcohol = v)),
            _CheckItem(texto: 'Realiza actividad física regular', activo: _ejercicio, color: Colors.green, onChanged: (v) => setState(() => _ejercicio = v)),
            _CheckItem(texto: 'Dieta saludable (frutas, verduras)', activo: _dietaSana, color: Colors.green, onChanged: (v) => setState(() => _dietaSana = v)),
          ])),
          const SizedBox(height: 14),

          _Card(titulo: 'Tamizajes preventivos', child: Column(children: [
            _CheckItem(texto: 'Colonoscopia (> 50 años)', activo: _colonoscopia, color: Colors.blue, onChanged: (v) => setState(() => _colonoscopia = v)),
            _CheckItem(texto: 'Mamografía (mujeres > 40 años)', activo: _mamografia, color: Colors.blue, onChanged: (v) => setState(() => _mamografia = v)),
            _CheckItem(texto: 'Citología / PAP vigente', activo: _pap, color: Colors.blue, onChanged: (v) => setState(() => _pap = v)),
            _CheckItem(texto: 'Ecografía abdominal', activo: _ecografiaAbd, color: Colors.blue, onChanged: (v) => setState(() => _ecografiaAbd = v)),
          ])),

          if (_diagnostico.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(width: double.infinity, padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: _colorDx.withOpacity(0.12), borderRadius: BorderRadius.circular(14), border: Border.all(color: _colorDx.withOpacity(0.5))),
              child: Text(_diagnostico, style: TextStyle(color: _colorDx, fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          ],
          const SizedBox(height: 20),

          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              onPressed: _guardar,
              icon: const Icon(Icons.save_outlined, color: Colors.white),
              label: const Text('Guardar control adulto', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: _kTeal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, height: 52,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.local_hospital_outlined, color: Colors.white70),
              label: const Text('Remitir a medicina interna', style: TextStyle(color: Colors.white70, fontSize: 15)),
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
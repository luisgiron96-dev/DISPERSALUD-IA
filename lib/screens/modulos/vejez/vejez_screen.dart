import 'package:flutter/material.dart';

const Color _kGray   = Color(0xFF5F5E5A);
const Color _kBg     = Color(0xFF111111);
const Color _kCard   = Color(0xFF1E1E1E);
const Color _kBorder = Color(0xFF2A2A2A);

class VejezScreen extends StatefulWidget {
  const VejezScreen({super.key});
  @override
  State<VejezScreen> createState() => _VejezScreenState();
}

class _VejezScreenState extends State<VejezScreen> {
  final _nombreCtrl   = TextEditingController(text: 'Carmen Ospina');
  final _edadCtrl     = TextEditingController(text: '72 años');
  final _cuidadorCtrl = TextEditingController(text: 'Luis Ospina (hijo)');
  final _presionCtrl  = TextEditingController(text: '145/88');
  final _glucemiaCtrl = TextEditingController(text: '118');
  final _pesoCtrl     = TextEditingController(text: '61');
  final _tallaCtrl    = TextEditingController(text: '155');
  final _spo2Ctrl     = TextEditingController(text: '96');
  final _fcCtrl       = TextEditingController(text: '72');

  // Funcionalidad — Escala de Barthel simplificada
  bool _camina        = true;
  bool _come          = true;
  bool _bano          = false;
  bool _vestido       = true;
  bool _continencia   = true;

  // Cognicion — Mini-Mental simplificado
  int _miniMental     = 22;

  // Polifarmacia
  bool _medicamentos5mas = true;
  bool _adherencia    = true;
  bool _efectosAdver  = false;

  // Caidas
  bool _caidaUltimo   = true;
  bool _auxiliarMarcha = false;
  bool _alfombrasRiesgo = true;

  // Vacunacion
  bool _influenza     = true;
  bool _neumococo     = false;
  bool _covid         = true;
  bool _td            = false;

  // Red de apoyo
  bool _redFamiliar   = true;
  bool _soledad       = false;
  bool _maltrato      = false;

  String _diagnostico = '';
  Color  _colorDx     = Colors.green;

  double get _imc {
    final p = double.tryParse(_pesoCtrl.text) ?? 0;
    final t = (double.tryParse(_tallaCtrl.text) ?? 1) / 100;
    return t > 0 ? p / (t * t) : 0;
  }

  void _guardar() {
    final presion  = int.tryParse(_presionCtrl.text.split('/').first) ?? 0;
    final spo2     = int.tryParse(_spo2Ctrl.text) ?? 98;

    if (_maltrato) {
      _diagnostico = '🚨 Sospecha de maltrato al adulto mayor. Activar ruta de protección ICBF / Comisaría.';
      _colorDx = Colors.red;
    } else if (presion >= 160) {
      _diagnostico = '🚨 Hipertensión severa (${_presionCtrl.text}). Remisión urgente. Riesgo de ACV.';
      _colorDx = Colors.red;
    } else if (spo2 < 92) {
      _diagnostico = '😮‍💨 SpO2 $spo2% — Hipoxemia. Evaluar dificultad respiratoria y remitir urgente.';
      _colorDx = Colors.red;
    } else if (_miniMental < 18) {
      _diagnostico = '🧠 Mini-Mental $_miniMental/30 — Posible deterioro cognitivo moderado. Referir a neurología.';
      _colorDx = Colors.red;
    } else if (_caidaUltimo) {
      _diagnostico = '⚠️ Caída en el último año reportada. Evaluar riesgo de fractura y adaptar el hogar.';
      _colorDx = Colors.orange;
    } else if (!_bano || !_camina) {
      _diagnostico = '🧓 Limitación funcional detectada. Evaluar necesidad de cuidador y terapia ocupacional.';
      _colorDx = Colors.orange;
    } else if (_miniMental < 24) {
      _diagnostico = '🧠 Mini-Mental $_miniMental/30 — Deterioro cognitivo leve. Seguimiento trimestral.';
      _colorDx = Colors.orange;
    } else {
      _diagnostico = '✅ Adulto mayor con funcionalidad conservada. Continuar controles semestrales.';
      _colorDx = Colors.green;
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Control de vejez guardado'),
      backgroundColor: _kGray,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  void dispose() {
    _nombreCtrl.dispose(); _edadCtrl.dispose(); _cuidadorCtrl.dispose();
    _presionCtrl.dispose(); _glucemiaCtrl.dispose(); _pesoCtrl.dispose();
    _tallaCtrl.dispose(); _spo2Ctrl.dispose(); _fcCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kGray,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18), onPressed: () => Navigator.pop(context)),
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Vejez · 60 años o más', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          Text('Cuidado del adulto mayor · DISPERSALUD IA', style: TextStyle(color: Colors.white70, fontSize: 11)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(children: [

          _Card(titulo: 'Datos del adulto mayor', child: Column(children: [
            _Campo(label: 'Nombre completo', controller: _nombreCtrl),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _Campo(label: 'Edad', controller: _edadCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _Campo(label: 'Cuidador / familiar', controller: _cuidadorCtrl)),
            ]),
          ])),
          const SizedBox(height: 14),

          _Card(titulo: 'Signos vitales', child: Column(children: [
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
              Expanded(child: _Campo(label: 'SpO2 (%)', controller: _spo2Ctrl)),
              const SizedBox(width: 12),
              Expanded(child: _Campo(label: 'Frec. cardíaca (lpm)', controller: _fcCtrl)),
            ]),
          ])),
          const SizedBox(height: 14),

          _Card(titulo: 'Cognición — Mini-Mental', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Evaluación cognitiva breve (orientación, memoria, lenguaje)', style: TextStyle(color: Colors.white60, fontSize: 12)),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Puntaje:', style: TextStyle(color: Colors.white60, fontSize: 13)),
              Row(children: [
                IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.white38), onPressed: () => setState(() { if (_miniMental > 0) _miniMental--; })),
                Text('$_miniMental / 30', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.white38), onPressed: () => setState(() { if (_miniMental < 30) _miniMental++; })),
              ]),
              _Badge(
                texto: _miniMental >= 24 ? 'Normal' : _miniMental >= 18 ? 'Leve' : 'Moderado',
                color: _miniMental >= 24 ? Colors.green : _miniMental >= 18 ? Colors.orange : Colors.red,
              ),
            ]),
          ])),
          const SizedBox(height: 14),

          _Card(titulo: 'Funcionalidad — Escala Barthel', child: Column(children: [
            _CheckItem(texto: 'Camina sin asistencia', activo: _camina, color: Colors.green, onChanged: (v) => setState(() => _camina = v)),
            _CheckItem(texto: 'Come solo / sin ayuda', activo: _come, color: Colors.green, onChanged: (v) => setState(() => _come = v)),
            _CheckItem(texto: 'Se bana de forma independiente', activo: _bano, color: Colors.orange, onChanged: (v) => setState(() => _bano = v)),
            _CheckItem(texto: 'Se viste solo', activo: _vestido, color: Colors.green, onChanged: (v) => setState(() => _vestido = v)),
            _CheckItem(texto: 'Control de esfinteres (continencia)', activo: _continencia, color: Colors.green, onChanged: (v) => setState(() => _continencia = v)),
          ])),
          const SizedBox(height: 14),

          _Card(titulo: 'Riesgo de caidas', child: Column(children: [
            _CheckItem(texto: 'Caida en el ultimo ano reportada', activo: _caidaUltimo, color: Colors.red, onChanged: (v) => setState(() => _caidaUltimo = v)),
            _CheckItem(texto: 'Usa auxiliar de marcha (baston/caminador)', activo: _auxiliarMarcha, color: Colors.blue, onChanged: (v) => setState(() => _auxiliarMarcha = v)),
            _CheckItem(texto: 'Alfombras / pisos con riesgo en hogar', activo: _alfombrasRiesgo, color: Colors.orange, onChanged: (v) => setState(() => _alfombrasRiesgo = v)),
          ])),
          const SizedBox(height: 14),

          _Card(titulo: 'Polifarmacia', child: Column(children: [
            _CheckItem(texto: 'Toma 5 o mas medicamentos diarios', activo: _medicamentos5mas, color: Colors.orange, onChanged: (v) => setState(() => _medicamentos5mas = v)),
            _CheckItem(texto: 'Buena adherencia al tratamiento', activo: _adherencia, color: Colors.green, onChanged: (v) => setState(() => _adherencia = v)),
            _CheckItem(texto: 'Efectos adversos reportados', activo: _efectosAdver, color: Colors.red, onChanged: (v) => setState(() => _efectosAdver = v)),
          ])),
          const SizedBox(height: 14),

          _Card(titulo: 'Vacunacion adulto mayor', child: Column(children: [
            _CheckItem(texto: 'Influenza anual', activo: _influenza, color: Colors.green, onChanged: (v) => setState(() => _influenza = v)),
            _CheckItem(texto: 'Neumococo (una vez > 65 anos)', activo: _neumococo, color: Colors.orange, onChanged: (v) => setState(() => _neumococo = v)),
            _CheckItem(texto: 'COVID-19 refuerzo vigente', activo: _covid, color: Colors.green, onChanged: (v) => setState(() => _covid = v)),
            _CheckItem(texto: 'Td (tetanos-difteria)', activo: _td, color: Colors.blue, onChanged: (v) => setState(() => _td = v)),
          ])),
          const SizedBox(height: 14),

          _Card(titulo: 'Red de apoyo y proteccion', child: Column(children: [
            _CheckItem(texto: 'Cuenta con red familiar activa', activo: _redFamiliar, color: Colors.green, onChanged: (v) => setState(() => _redFamiliar = v)),
            _CheckItem(texto: 'Reporte de soledad o abandono', activo: _soledad, color: Colors.orange, onChanged: (v) => setState(() => _soledad = v)),
            _CheckItem(texto: 'Sospecha de maltrato al adulto mayor', activo: _maltrato, color: Colors.red, onChanged: (v) => setState(() => _maltrato = v)),
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
              label: const Text('Guardar control adulto mayor', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: _kGray, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, height: 52,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.local_hospital_outlined, color: Colors.white70),
              label: const Text('Remitir a geriatria', style: TextStyle(color: Colors.white70, fontSize: 15)),
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
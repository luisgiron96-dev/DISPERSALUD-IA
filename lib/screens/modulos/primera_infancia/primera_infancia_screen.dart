import 'package:flutter/material.dart';

const Color _kAmbar      = Color(0xFF854F0B);
const Color _kAmbarLight = Color(0xFFFAEEDA);
const Color _kBg         = Color(0xFF111111);
const Color _kCard       = Color(0xFF1E1E1E);
const Color _kBorder     = Color(0xFF2A2A2A);

class PrimeraInfanciaScreen extends StatefulWidget {
  const PrimeraInfanciaScreen({super.key});
  @override
  State<PrimeraInfanciaScreen> createState() => _PrimeraInfanciaScreenState();
}

class _PrimeraInfanciaScreenState extends State<PrimeraInfanciaScreen> {
  // ── Controladores ─────────────────────────────────────────────────────
  final _nombreCtrl    = TextEditingController(text: 'Sebastián Torres');
  final _edadCtrl      = TextEditingController(text: '2 años 4 meses');
  final _acudienteCtrl = TextEditingController(text: 'María Torres');
  final _pesoCtrl      = TextEditingController(text: '12.5');
  final _tallaCtrl     = TextEditingController(text: '87');
  final _perCtrl       = TextEditingController(text: '48');
  final _tempCtrl      = TextEditingController(text: '36.5');

  // ── Desarrollo ────────────────────────────────────────────────────────
  bool _camina     = true;
  bool _habla2pal  = true;
  bool _senala     = true;
  bool _juegaImita = false;
  bool _controlEsfinteres = false;

  // ── Vacunación ────────────────────────────────────────────────────────
  bool _bcg        = true;
  bool _hepatitisB = true;
  bool _pentavalente = true;
  bool _srp        = true;
  bool _varicela   = false;
  bool _influenza  = false;

  // ── Nutrición ─────────────────────────────────────────────────────────
  bool _lactanciaMaterna = false;
  bool _alimentosVariados = true;
  bool _micronutrientes   = true;

  // ── Diagnóstico IA ────────────────────────────────────────────────────
  String _diagnostico = '';
  Color  _colorDx     = Colors.green;

  double get _peso   => double.tryParse(_pesoCtrl.text) ?? 0;
  double get _talla  => double.tryParse(_tallaCtrl.text) ?? 1;
  double get _perc   => double.tryParse(_perCtrl.text) ?? 0;
  double get _temp   => double.tryParse(_tempCtrl.text) ?? 36.5;

  // Peso/talla simplificado para 2-5 años
  String get _estadoNutricional {
    final pt = _peso / (_talla / 100 * _talla / 100);
    if (pt < 14)   return 'Desnutrición';
    if (pt < 18.5) return 'Normal';
    if (pt < 25)   return 'Sobrepeso';
    return 'Obesidad';
  }

  Color get _colorNutricional {
    final s = _estadoNutricional;
    if (s == 'Normal') return Colors.green;
    if (s == 'Desnutrición') return Colors.red;
    return Colors.orange;
  }

  void _guardar() {
    if (_temp > 38.0) {
      _diagnostico = '🌡️ Temperatura ${_temp}°C — Fiebre. Evaluar causa, hidratación y antipiréticos según peso.';
      _colorDx = Colors.red;
    } else if (_estadoNutricional == 'Desnutrición') {
      _diagnostico = '⚠️ Posible desnutrición. Peso/talla bajo. Referir a nutrición y programa ICBF.';
      _colorDx = Colors.red;
    } else if (!_srp || !_pentavalente) {
      _diagnostico = '💉 Esquema de vacunación incompleto. Programar jornada de vacunación urgente.';
      _colorDx = Colors.orange;
    } else if (!_habla2pal || !_camina) {
      _diagnostico = '🧒 Posible retraso en hitos del desarrollo. Referir a valoración de desarrollo infantil.';
      _colorDx = Colors.orange;
    } else {
      _diagnostico = '✅ Niño con desarrollo adecuado para su edad. Continuar controles de crecimiento.';
      _colorDx = Colors.green;
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Control de primera infancia guardado'),
      backgroundColor: _kAmbar,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  void dispose() {
    _nombreCtrl.dispose(); _edadCtrl.dispose(); _acudienteCtrl.dispose();
    _pesoCtrl.dispose(); _tallaCtrl.dispose(); _perCtrl.dispose(); _tempCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kAmbar,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Primera infancia · 0–5 años', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            Text('Crecimiento y desarrollo · DISPERSALUD IA', style: TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(children: [

          // ── CARD 1: Datos del niño ──────────────────────────────────────
          _Card(titulo: 'Datos del niño / niña', child: Column(children: [
            _Campo(label: 'Nombre completo', controller: _nombreCtrl),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _Campo(label: 'Edad', controller: _edadCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _Campo(label: 'Acudiente', controller: _acudienteCtrl)),
            ]),
          ])),

          const SizedBox(height: 14),

          // ── CARD 2: Antropometría ───────────────────────────────────────
          _Card(titulo: 'Antropometría y signos vitales', child: Column(children: [
            Row(children: [
              Expanded(child: _Campo(label: 'Peso (kg)', controller: _pesoCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _Campo(label: 'Talla (cm)', controller: _tallaCtrl)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _Campo(label: 'Perímetro cefálico (cm)', controller: _perCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _Campo(label: 'Temperatura (°C)', controller: _tempCtrl)),
            ]),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _colorNutricional.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _colorNutricional.withOpacity(0.3)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Estado nutricional', style: TextStyle(color: Colors.white70, fontSize: 13)),
                _Badge(texto: _estadoNutricional, color: _colorNutricional),
              ]),
            ),
          ])),

          const SizedBox(height: 14),

          // ── CARD 3: Hitos del desarrollo ────────────────────────────────
          _Card(titulo: 'Hitos del desarrollo (2 años)', child: Column(children: [
            _CheckItem(texto: 'Camina y corre sin apoyo', activo: _camina, color: Colors.green, onChanged: (v) => setState(() => _camina = v)),
            _CheckItem(texto: 'Dice al menos 2 palabras juntas', activo: _habla2pal, color: Colors.green, onChanged: (v) => setState(() => _habla2pal = v)),
            _CheckItem(texto: 'Señala objetos e imita acciones', activo: _senala, color: Colors.green, onChanged: (v) => setState(() => _senala = v)),
            _CheckItem(texto: 'Juego simbólico (imita adultos)', activo: _juegaImita, color: Colors.orange, onChanged: (v) => setState(() => _juegaImita = v)),
            _CheckItem(texto: 'Control de esfínteres iniciado', activo: _controlEsfinteres, color: Colors.orange, onChanged: (v) => setState(() => _controlEsfinteres = v)),
          ])),

          const SizedBox(height: 14),

          // ── CARD 4: Vacunación ──────────────────────────────────────────
          _Card(titulo: 'Esquema de vacunación', child: Column(children: [
            _CheckItem(texto: 'BCG — recién nacido', activo: _bcg, color: Colors.green, onChanged: (v) => setState(() => _bcg = v)),
            _CheckItem(texto: 'Hepatitis B — al nacer', activo: _hepatitisB, color: Colors.green, onChanged: (v) => setState(() => _hepatitisB = v)),
            _CheckItem(texto: 'Pentavalente (3 dosis)', activo: _pentavalente, color: Colors.green, onChanged: (v) => setState(() => _pentavalente = v)),
            _CheckItem(texto: 'SRP — triple viral (1 año)', activo: _srp, color: Colors.green, onChanged: (v) => setState(() => _srp = v)),
            _CheckItem(texto: 'Varicela (1 año)', activo: _varicela, color: Colors.orange, onChanged: (v) => setState(() => _varicela = v)),
            _CheckItem(texto: 'Influenza anual', activo: _influenza, color: Colors.blue, onChanged: (v) => setState(() => _influenza = v)),
          ])),

          const SizedBox(height: 14),

          // ── CARD 5: Nutrición ───────────────────────────────────────────
          _Card(titulo: 'Alimentación y nutrición', child: Column(children: [
            _CheckItem(texto: 'Lactancia materna exclusiva (< 6 meses)', activo: _lactanciaMaterna, color: Colors.green, onChanged: (v) => setState(() => _lactanciaMaterna = v)),
            _CheckItem(texto: 'Alimentación variada y complementaria', activo: _alimentosVariados, color: Colors.green, onChanged: (v) => setState(() => _alimentosVariados = v)),
            _CheckItem(texto: 'Micronutrientes suministrados (Vitam. A, hierro)', activo: _micronutrientes, color: Colors.green, onChanged: (v) => setState(() => _micronutrientes = v)),
          ])),

          // ── Diagnóstico IA ──────────────────────────────────────────────
          if (_diagnostico.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: _colorDx.withOpacity(0.12), borderRadius: BorderRadius.circular(14), border: Border.all(color: _colorDx.withOpacity(0.5))),
              child: Text(_diagnostico, style: TextStyle(color: _colorDx, fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          ],

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              onPressed: _guardar,
              icon: const Icon(Icons.save_outlined, color: Colors.white),
              label: const Text('Guardar control de crecimiento', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: _kAmbar, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, height: 52,
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

// ─── Widgets reutilizables ─────────────────────────────────────────────────
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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      const SizedBox(height: 4),
      TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11), filled: true, fillColor: _kBorder, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
      ),
    ],
  );
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
    child: GestureDetector(
      onTap: () => onChanged(!activo),
      child: Row(children: [
        Icon(activo ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: activo ? color : Colors.white24, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(texto, style: TextStyle(color: activo ? Colors.white : Colors.white38, fontSize: 13))),
      ]),
    ),
  );
}
import 'package:flutter/material.dart';

const Color _kPurple = Color(0xFF534AB7);
const Color _kBg     = Color(0xFF111111);
const Color _kCard   = Color(0xFF1E1E1E);
const Color _kBorder = Color(0xFF2A2A2A);

class AdolescenciaScreen extends StatefulWidget {
  const AdolescenciaScreen({super.key});
  @override
  State<AdolescenciaScreen> createState() => _AdolescenciaScreenState();
}

class _AdolescenciaScreenState extends State<AdolescenciaScreen> {
  final _nombreCtrl  = TextEditingController(text: 'Daniela Morales');
  final _edadCtrl    = TextEditingController(text: '15 años');
  final _pesoCtrl    = TextEditingController(text: '52');
  final _tallaCtrl   = TextEditingController(text: '160');
  final _presionCtrl = TextEditingController(text: '110/70');
  final _tempCtrl    = TextEditingController(text: '36.7');

  // Salud sexual
  bool _vph           = true;
  bool _its           = false;
  bool _anticoncepcion= false;
  bool _inicioSexual  = false;

  // Salud mental — PHQ-9
  int _phq9 = 3;

  // Consumo sustancias
  bool _tabaco  = false;
  bool _alcohol = false;
  bool _otras   = false;

  // Violencia / entorno
  bool _violenciaNo   = true;
  bool _redApoyoSi    = true;

  // Vacunacion
  bool _vph2    = false;
  bool _td      = true;
  bool _influenza = false;

  String _diagnostico = '';
  Color  _colorDx     = Colors.green;

  double get _imc {
    final p = double.tryParse(_pesoCtrl.text) ?? 0;
    final t = (double.tryParse(_tallaCtrl.text) ?? 1) / 100;
    return t > 0 ? p / (t * t) : 0;
  }

  String get _imcEstado {
    final i = _imc;
    if (i < 16)   return 'Bajo peso severo';
    if (i < 18.5) return 'Bajo peso';
    if (i < 25)   return 'Normal';
    if (i < 30)   return 'Sobrepeso';
    return 'Obesidad';
  }

  Color get _imcColor {
    final s = _imcEstado;
    if (s == 'Normal')    return Colors.green;
    if (s.contains('Bajo')) return Colors.red;
    return Colors.orange;
  }

  void _guardar() {
    final presion = int.tryParse(_presionCtrl.text.split('/').first) ?? 0;
    if (_phq9 >= 15) {
      _diagnostico = '🧠 PHQ-9: $_phq9/27 — Depresión moderada a severa. Remisión urgente a salud mental.';
      _colorDx = Colors.red;
    } else if (!_violenciaNo) {
      _diagnostico = '🚨 Reporte de violencia. Activar ruta de atención integral y notificar a ICBF.';
      _colorDx = Colors.red;
    } else if (presion >= 130) {
      _diagnostico = '⚠️ Presión elevada para la edad. Descartar hipertensión secundaria.';
      _colorDx = Colors.orange;
    } else if (_phq9 >= 10) {
      _diagnostico = '🧠 PHQ-9: $_phq9/27 — Depresión leve-moderada. Consejería psicológica recomendada.';
      _colorDx = Colors.orange;
    } else if (_tabaco || _otras) {
      _diagnostico = '🚭 Consumo de sustancias reportado. Orientar a programa de prevención y cesación.';
      _colorDx = Colors.orange;
    } else if (_imcEstado.contains('Bajo')) {
      _diagnostico = '⚖️ IMC bajo. Evaluar trastorno alimentario (anorexia/bulimia). Referir a nutrición.';
      _colorDx = Colors.orange;
    } else {
      _diagnostico = '✅ Adolescente saludable. Reforzar proyecto de vida y hábitos saludables.';
      _colorDx = Colors.green;
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Control de adolescencia guardado'),
      backgroundColor: _kPurple,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  void dispose() {
    _nombreCtrl.dispose(); _edadCtrl.dispose(); _pesoCtrl.dispose();
    _tallaCtrl.dispose(); _presionCtrl.dispose(); _tempCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kPurple,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18), onPressed: () => Navigator.pop(context)),
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Adolescencia · 12–17 años', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          Text('Salud sexual y mental · DISPERSALUD IA', style: TextStyle(color: Colors.white70, fontSize: 11)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(children: [

          _Card(titulo: 'Datos del adolescente', child: Column(children: [
            Row(children: [
              Expanded(child: _Campo(label: 'Nombre completo', controller: _nombreCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _Campo(label: 'Edad', controller: _edadCtrl)),
            ]),
          ])),
          const SizedBox(height: 14),

          _Card(titulo: 'Signos vitales y antropometría', child: Column(children: [
            Row(children: [
              Expanded(child: _Campo(label: 'Peso (kg)', controller: _pesoCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _Campo(label: 'Talla (cm)', controller: _tallaCtrl)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _Campo(label: 'Presión arterial', controller: _presionCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _Campo(label: 'Temperatura (°C)', controller: _tempCtrl)),
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

          _Card(titulo: 'Salud mental — PHQ-9', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('¿Con qué frecuencia ha sentido tristeza, desesperanza o poco interés en actividades?', style: TextStyle(color: Colors.white60, fontSize: 12)),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Puntaje PHQ-9:', style: TextStyle(color: Colors.white60, fontSize: 13)),
              Row(children: [
                IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.white38), onPressed: () => setState(() { if (_phq9 > 0) _phq9--; })),
                Text('$_phq9 / 27', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.white38), onPressed: () => setState(() { if (_phq9 < 27) _phq9++; })),
              ]),
              _Badge(
                texto: _phq9 < 5 ? 'Sin síntomas' : _phq9 < 10 ? 'Leve' : _phq9 < 15 ? 'Moderado' : 'Severo',
                color: _phq9 < 5 ? Colors.green : _phq9 < 10 ? Colors.yellow : _phq9 < 15 ? Colors.orange : Colors.red,
              ),
            ]),
          ])),
          const SizedBox(height: 14),

          _Card(titulo: 'Salud sexual y reproductiva', child: Column(children: [
            _CheckItem(texto: 'VPH 1.ª dosis aplicada', activo: _vph, color: Colors.green, onChanged: (v) => setState(() => _vph = v)),
            _CheckItem(texto: 'VPH 2.ª dosis aplicada', activo: _vph2, color: Colors.orange, onChanged: (v) => setState(() => _vph2 = v)),
            _CheckItem(texto: 'Tamizaje ITS / VIH realizado', activo: _its, color: Colors.orange, onChanged: (v) => setState(() => _its = v)),
            _CheckItem(texto: 'Asesoría en anticoncepción', activo: _anticoncepcion, color: Colors.blue, onChanged: (v) => setState(() => _anticoncepcion = v)),
            _CheckItem(texto: 'Inicio de vida sexual activa', activo: _inicioSexual, color: Colors.orange, onChanged: (v) => setState(() => _inicioSexual = v)),
          ])),
          const SizedBox(height: 14),

          _Card(titulo: 'Entorno y violencia', child: Column(children: [
            _CheckItem(texto: 'Sin reporte de violencia (física/sexual/psicológica)', activo: _violenciaNo, color: Colors.green, onChanged: (v) => setState(() => _violenciaNo = v)),
            _CheckItem(texto: 'Cuenta con red de apoyo familiar', activo: _redApoyoSi, color: Colors.green, onChanged: (v) => setState(() => _redApoyoSi = v)),
          ])),
          const SizedBox(height: 14),

          _Card(titulo: 'Consumo de sustancias', child: Column(children: [
            _CheckItem(texto: 'Tabaco / cigarrillo electrónico', activo: _tabaco, color: Colors.red, onChanged: (v) => setState(() => _tabaco = v)),
            _CheckItem(texto: 'Alcohol (consumo frecuente)', activo: _alcohol, color: Colors.orange, onChanged: (v) => setState(() => _alcohol = v)),
            _CheckItem(texto: 'Otras sustancias psicoactivas', activo: _otras, color: Colors.red, onChanged: (v) => setState(() => _otras = v)),
          ])),
          const SizedBox(height: 14),

          _Card(titulo: 'Vacunación adolescente', child: Column(children: [
            _CheckItem(texto: 'Td (tétanos-difteria) refuerzo', activo: _td, color: Colors.green, onChanged: (v) => setState(() => _td = v)),
            _CheckItem(texto: 'Influenza anual', activo: _influenza, color: Colors.blue, onChanged: (v) => setState(() => _influenza = v)),
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
              label: const Text('Guardar control adolescente', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: _kPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, height: 52,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.psychology_outlined, color: Colors.white70),
              label: const Text('Remitir a salud mental', style: TextStyle(color: Colors.white70, fontSize: 15)),
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
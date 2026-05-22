import 'package:flutter/material.dart';

const Color _kGreen      = Color(0xFF3B6D11);
const Color _kGreenLight = Color(0xFFEAF3DE);
const Color _kBg         = Color(0xFF111111);
const Color _kCard       = Color(0xFF1E1E1E);
const Color _kBorder     = Color(0xFF2A2A2A);

class JuventudScreen extends StatefulWidget {
  const JuventudScreen({super.key});
  @override
  State<JuventudScreen> createState() => _JuventudScreenState();
}

class _JuventudScreenState extends State<JuventudScreen> {
  // ── Controladores ─────────────────────────────────────────────────────
  final _nombreCtrl    = TextEditingController(text: 'Carlos Muñoz');
  final _edadCtrl      = TextEditingController(text: '22 años');
  final _presionCtrl   = TextEditingController(text: '118/76');
  final _glucemiaCtrl  = TextEditingController(text: '88');
  final _pesoCtrl      = TextEditingController(text: '70');
  final _tallaCtrl     = TextEditingController(text: '1.75');

  // ── Salud mental PHQ-9 simplificado ───────────────────────────────────
  int _phq9 = 0;

  // ── Chequeos ──────────────────────────────────────────────────────────
  bool _vph        = true;
  bool _hepatitisB = true;
  bool _influenza  = false;
  bool _its        = false;
  bool _anticonceptivos = false;

  // ── Consumo de sustancias ─────────────────────────────────────────────
  bool _tabaco   = false;
  bool _alcohol  = false;
  bool _otras    = false;

  // ── Diagnóstico IA ────────────────────────────────────────────────────
  String _diagnostico = '';
  Color  _colorDx     = Colors.green;

  double get _imc {
    final peso  = double.tryParse(_pesoCtrl.text) ?? 0;
    final talla = double.tryParse(_tallaCtrl.text) ?? 1;
    return talla > 0 ? peso / (talla * talla) : 0;
  }

  String get _imcEstado {
    final i = _imc;
    if (i < 18.5) return 'Bajo peso';
    if (i < 25)   return 'Normal';
    if (i < 30)   return 'Sobrepeso';
    return 'Obesidad';
  }

  Color get _imcColor {
    final i = _imc;
    if (i < 18.5 || i >= 30) return Colors.red;
    if (i >= 25)              return Colors.orange;
    return Colors.green;
  }

  void _guardar() {
    final presionSist = int.tryParse(_presionCtrl.text.split('/').first) ?? 0;
    final glucemia    = double.tryParse(_glucemiaCtrl.text) ?? 0;

    if (presionSist >= 140) {
      _diagnostico = '⚠️ Presión arterial elevada. Evaluar hipertensión en joven. Remisión médica.';
      _colorDx = Colors.red;
    } else if (glucemia >= 126) {
      _diagnostico = '🩸 Glucemia en ayunas elevada. Riesgo de diabetes. Solicitar HbA1c.';
      _colorDx = Colors.red;
    } else if (_phq9 >= 10) {
      _diagnostico = '🧠 Puntaje PHQ-9 elevado (${_phq9}/27). Posible depresión moderada. Referir a salud mental.';
      _colorDx = Colors.orange;
    } else if (_tabaco || _otras) {
      _diagnostico = '🚭 Consumo de sustancias detectado. Orientar hacia programa de cesación.';
      _colorDx = Colors.orange;
    } else if (_imc >= 25) {
      _diagnostico = '⚖️ IMC: ${_imc.toStringAsFixed(1)} — ${_imcEstado}. Promover actividad física y dieta saludable.';
      _colorDx = Colors.orange;
    } else {
      _diagnostico = '✅ Joven saludable. Continuar controles anuales y reforzar hábitos saludables.';
      _colorDx = Colors.green;
    }

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Consulta de juventud guardada'),
        backgroundColor: _kGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    _nombreCtrl.dispose(); _edadCtrl.dispose(); _presionCtrl.dispose();
    _glucemiaCtrl.dispose(); _pesoCtrl.dispose(); _tallaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kGreen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Juventud · 18–28 años', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            Text('Prevención y bienestar · DISPERSALUD IA', style: TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [

            // ── CARD 1: Datos personales ─────────────────────────────────
            _Card(titulo: 'Datos del joven', child: Column(children: [
              Row(children: [
                Expanded(child: _Campo(label: 'Nombre completo', controller: _nombreCtrl)),
                const SizedBox(width: 12),
                Expanded(child: _Campo(label: 'Edad', controller: _edadCtrl)),
              ]),
            ])),

            const SizedBox(height: 14),

            // ── CARD 2: Signos vitales ────────────────────────────────────
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
                Expanded(child: _Campo(label: 'Talla (m)', controller: _tallaCtrl)),
              ]),
              const SizedBox(height: 14),
              // IMC calculado
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: _imcColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: _imcColor.withOpacity(0.3))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('IMC calculado', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Row(children: [
                      Text(_imc > 0 ? _imc.toStringAsFixed(1) : '--', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(width: 8),
                      _Badge(texto: _imcEstado, color: _imcColor),
                    ]),
                  ],
                ),
              ),
            ])),

            const SizedBox(height: 14),

            // ── CARD 3: Salud sexual y reproductiva ───────────────────────
            _Card(titulo: 'Salud sexual y reproductiva', child: Column(children: [
              _CheckItem(texto: 'Vacuna VPH aplicada', activo: _vph, color: Colors.green, onChanged: (v) => setState(() => _vph = v)),
              _CheckItem(texto: 'Hepatitis B esquema completo', activo: _hepatitisB, color: Colors.green, onChanged: (v) => setState(() => _hepatitisB = v)),
              _CheckItem(texto: 'Tamizaje ITS / VIH realizado', activo: _its, color: Colors.orange, onChanged: (v) => setState(() => _its = v)),
              _CheckItem(texto: 'Asesoría en anticoncepción', activo: _anticonceptivos, color: Colors.orange, onChanged: (v) => setState(() => _anticonceptivos = v)),
            ])),

            const SizedBox(height: 14),

            // ── CARD 4: Salud mental PHQ-9 ────────────────────────────────
            _Card(titulo: 'Tamizaje salud mental — PHQ-9', child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Durante las últimas 2 semanas, ¿con qué frecuencia ha sentido poco interés o tristeza?',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Puntaje PHQ-9:', style: TextStyle(color: Colors.white60, fontSize: 13)),
                    Row(children: [
                      IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.white38), onPressed: () => setState(() { if (_phq9 > 0) _phq9--; })),
                      Text('$_phq9 / 27', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.white38), onPressed: () => setState(() { if (_phq9 < 27) _phq9++; })),
                    ]),
                    _Badge(
                      texto: _phq9 < 5 ? 'Sin síntomas' : _phq9 < 10 ? 'Leve' : _phq9 < 15 ? 'Moderado' : 'Severo',
                      color: _phq9 < 5 ? Colors.green : _phq9 < 10 ? Colors.yellow : Colors.orange,
                    ),
                  ],
                ),
              ],
            )),

            const SizedBox(height: 14),

            // ── CARD 5: Consumo de sustancias ─────────────────────────────
            _Card(titulo: 'Consumo de sustancias', child: Column(children: [
              _CheckItem(texto: 'Tabaco / cigarrillo', activo: _tabaco, color: Colors.red, onChanged: (v) => setState(() => _tabaco = v)),
              _CheckItem(texto: 'Alcohol (consumo de riesgo)', activo: _alcohol, color: Colors.orange, onChanged: (v) => setState(() => _alcohol = v)),
              _CheckItem(texto: 'Otras sustancias psicoactivas', activo: _otras, color: Colors.red, onChanged: (v) => setState(() => _otras = v)),
            ])),

            // ── Vacunación ────────────────────────────────────────────────
            const SizedBox(height: 14),
            _Card(titulo: 'Vacunación joven', child: Column(children: [
              _CheckItem(texto: 'Influenza anual aplicada', activo: _influenza, color: Colors.blue, onChanged: (v) => setState(() => _influenza = v)),
            ])),

            // ── Diagnóstico IA ────────────────────────────────────────────
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
                label: const Text('Guardar consulta', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: _kGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
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
import 'package:flutter/material.dart';

// ─── Colores ───────────────────────────────────────────────────────────────
const Color _kPink      = Color(0xFF8E2C52);
const Color _kPinkLight = Color(0xFFFBEAF0);
const Color _kBg        = Color(0xFF111111);
const Color _kCard      = Color(0xFF1E1E1E);
const Color _kBorder    = Color(0xFF2A2A2A);

class GestacionScreen extends StatefulWidget {
  const GestacionScreen({super.key});
  @override
  State<GestacionScreen> createState() => _GestacionScreenState();
}

class _GestacionScreenState extends State<GestacionScreen> {
  // ── Controladores ─────────────────────────────────────────────────────
  final _nombreCtrl   = TextEditingController(text: 'Lucía Rodríguez');
  final _semanasCtrl  = TextEditingController(text: '28 semanas');
  final _edadCtrl     = TextEditingController(text: '24 años');
  final _presionCtrl  = TextEditingController(text: '110/70');
  final _pesoCtrl     = TextEditingController(text: '62');
  final _alturaCtrl   = TextEditingController(text: '27');
  final _fcfCtrl      = TextEditingController(text: '148');

  // ── Estado de chequeo ─────────────────────────────────────────────────
  bool _toxoide   = true;
  bool _acidoFolico = true;
  bool _ecografia = false;
  bool _hemoglobina = false;

  // ── Lógica de diagnóstico IA ───────────────────────────────────────────
  String _diagnostico = '';
  Color  _colorDx     = Colors.green;

  void _guardar() {
    final presionSist = int.tryParse(_presionCtrl.text.split('/').first) ?? 0;
    final semanas     = int.tryParse(_semanasCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final peso        = double.tryParse(_pesoCtrl.text) ?? 0;

    if (presionSist >= 140) {
      _diagnostico = '⚠️ Presión elevada. Riesgo de preeclampsia. Remisión inmediata a ginecobstetricia.';
      _colorDx = Colors.red;
    } else if (!_hemoglobina) {
      _diagnostico = '🩸 Hemoglobina baja detectada. Reforzar suplementación con hierro + vitamina C.';
      _colorDx = Colors.orange;
    } else if (!_ecografia && semanas >= 18) {
      _diagnostico = '📋 Ecografía de 2.° trimestre pendiente. Programar cita con imágenes.';
      _colorDx = Colors.orange;
    } else {
      _diagnostico = '✅ Control prenatal estable. Semana $semanas — Continuar seguimiento mensual.';
      _colorDx = Colors.green;
    }

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Control prenatal guardado correctamente'),
        backgroundColor: _kPink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _remitir() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kCard,
        title: const Text('Remitir a ginecobstetricia', style: TextStyle(color: Colors.white)),
        content: const Text(
          '¿Confirmas la remisión de esta paciente a ginecobstetricia?\n\nSe generará una nota de remisión en el historial.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kPink),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Remisión generada exitosamente'),
                  backgroundColor: _kPink,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nombreCtrl.dispose(); _semanasCtrl.dispose(); _edadCtrl.dispose();
    _presionCtrl.dispose(); _pesoCtrl.dispose(); _alturaCtrl.dispose();
    _fcfCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kPink,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gestación', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Control prenatal · DISPERSALUD IA', style: TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [

            // ── CARD 1: Datos de la gestante ────────────────────────────
            _Card(
              titulo: 'Datos de la gestante',
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _Campo(label: 'Semanas de gestación', controller: _semanasCtrl)),
                      const SizedBox(width: 12),
                      Expanded(child: _Campo(label: 'Edad', controller: _edadCtrl)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _Campo(label: 'Nombre', controller: _nombreCtrl),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── CARD 2: Signos vitales ───────────────────────────────────
            _Card(
              titulo: 'Signos vitales y control',
              child: Column(
                children: [
                  // Tensión arterial editable
                  Row(
                    children: [
                      Expanded(child: _Campo(label: 'Tensión arterial (sistólica/diastólica)', controller: _presionCtrl)),
                      const SizedBox(width: 8),
                      _Badge(
                        texto: int.tryParse(_presionCtrl.text.split('/').first) != null &&
                               int.parse(_presionCtrl.text.split('/').first) >= 140
                            ? 'Alta'
                            : 'Normal',
                        color: int.tryParse(_presionCtrl.text.split('/').first) != null &&
                               int.parse(_presionCtrl.text.split('/').first) >= 140
                            ? Colors.red
                            : Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _FilaVital(label: 'Peso materno',      valor: '62 kg',   detalle: '(+2 kg/mes)',  estado: 'Normal',    color: Colors.green),
                  const SizedBox(height: 10),
                  _FilaVital(label: 'Altura uterina',    valor: '27 cm',   detalle: '',              estado: 'Adecuada',  color: Colors.green),
                  const SizedBox(height: 10),
                  _FilaVital(label: 'Frecuencia fetal',  valor: '148 lpm', detalle: '',              estado: '',          color: Colors.green),
                  const SizedBox(height: 10),
                  _FilaVital(label: 'Movimientos fetales', valor: 'Presentes', detalle: '',           estado: 'OK',        color: Colors.green),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── CARD 3: Lista de chequeo ─────────────────────────────────
            _Card(
              titulo: 'Lista de chequeo prenatal',
              child: Column(
                children: [
                  _CheckItem(
                    texto: 'Toxoide tetánico aplicado — dosis 2 completa',
                    activo: _toxoide,
                    color: Colors.green,
                    onChanged: (v) => setState(() => _toxoide = v),
                  ),
                  _CheckItem(
                    texto: 'Ácido fólico + hierro suministrado',
                    activo: _acidoFolico,
                    color: Colors.green,
                    onChanged: (v) => setState(() => _acidoFolico = v),
                  ),
                  _CheckItem(
                    texto: 'Ecografía 28 semanas — pendiente remisión',
                    activo: _ecografia,
                    color: Colors.orange,
                    onChanged: (v) => setState(() => _ecografia = v),
                  ),
                  _CheckItem(
                    texto: 'Hemoglobina — resultado 10.8 g/dL, anemia leve',
                    activo: _hemoglobina,
                    color: Colors.orange,
                    onChanged: (v) => setState(() => _hemoglobina = v),
                  ),
                ],
              ),
            ),

            // ── Diagnóstico IA ───────────────────────────────────────────
            if (_diagnostico.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _colorDx.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _colorDx.withOpacity(0.5)),
                ),
                child: Text(_diagnostico, style: TextStyle(color: _colorDx, fontSize: 14, fontWeight: FontWeight.w500)),
              ),
            ],

            const SizedBox(height: 20),

            // ── Botón guardar ────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _guardar,
                icon: const Icon(Icons.save_outlined, color: Colors.white),
                label: const Text('Guardar control prenatal', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPink,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Botón remitir ────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _remitir,
                icon: const Icon(Icons.local_hospital_outlined, color: Colors.white70),
                label: const Text('Remitir a ginecobstetricia', style: TextStyle(color: Colors.white70, fontSize: 15)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
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
  final String titulo;
  final Widget child;
  const _Card({required this.titulo, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const _Campo({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: true,
            fillColor: _kBorder,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}

class _FilaVital extends StatelessWidget {
  final String label, valor, detalle, estado;
  final Color color;
  const _FilaVital({required this.label, required this.valor, required this.detalle, required this.estado, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13)),
        Row(
          children: [
            Text(valor, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            if (detalle.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(detalle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
            if (estado.isNotEmpty) ...[
              const SizedBox(width: 8),
              _Badge(texto: estado, color: color),
            ],
          ],
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String texto;
  final Color color;
  const _Badge({required this.texto, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.18), borderRadius: BorderRadius.circular(20)),
      child: Text(texto, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

class _CheckItem extends StatelessWidget {
  final String texto;
  final bool activo;
  final Color color;
  final ValueChanged<bool> onChanged;
  const _CheckItem({required this.texto, required this.activo, required this.color, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => onChanged(!activo),
        child: Row(
          children: [
            Icon(activo ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: activo ? color : Colors.white24, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(texto, style: TextStyle(color: activo ? Colors.white : Colors.white38, fontSize: 13))),
          ],
        ),
      ),
    );
  }
}
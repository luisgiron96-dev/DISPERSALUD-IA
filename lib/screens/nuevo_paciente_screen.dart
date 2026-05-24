import 'package:flutter/material.dart';
import '../database/database_helper.dart';

const Color _kBg     = Color(0xFF111111);
const Color _kCard   = Color(0xFF1E1E1E);
const Color _kVerde  = Color(0xFF1D9E75);
const Color _kBorder = Color(0xFF2A2A2A);

class NuevoPacienteScreen extends StatefulWidget {
  const NuevoPacienteScreen({super.key});
  @override
  State<NuevoPacienteScreen> createState() => _NuevoPacienteScreenState();
}

class _NuevoPacienteScreenState extends State<NuevoPacienteScreen> {
  final _nombreCtrl    = TextEditingController();
  final _docCtrl       = TextEditingController();
  final _fechaNacCtrl  = TextEditingController();
  final _veredaCtrl    = TextEditingController();
  final _municipioCtrl = TextEditingController();
  final _telefonoCtrl  = TextEditingController();

  String _sexo   = 'Femenino';
  String _modulo = 'Gestación';
  bool   _guardando = false;

  final List<String> _modulos = [
    'Gestación', 'Primera infancia', 'Infancia',
    'Adolescencia', 'Juventud', 'Adultez', 'Vejez',
  ];

  Future<void> _guardar() async {
    if (_nombreCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('El nombre es obligatorio'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    setState(() => _guardando = true);
    await DatabaseHelper.instance.insertarPaciente({
      'nombre':    _nombreCtrl.text.trim(),
      'documento': _docCtrl.text.trim(),
      'fecha_nac': _fechaNacCtrl.text.trim(),
      'sexo':      _sexo,
      'vereda':    _veredaCtrl.text.trim(),
      'municipio': _municipioCtrl.text.trim(),
      'telefono':  _telefonoCtrl.text.trim(),
      'modulo':    _modulo,
      'fecha_reg': DateTime.now().toIso8601String(),
    });
    setState(() => _guardando = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${_nombreCtrl.text.trim()} registrado correctamente'),
        backgroundColor: _kVerde,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    for (final c in [_nombreCtrl, _docCtrl, _fechaNacCtrl,
                     _veredaCtrl, _municipioCtrl, _telefonoCtrl]) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg, foregroundColor: Colors.white,
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Nuevo paciente', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text('Registro local · sin internet', style: TextStyle(color: Colors.white54, fontSize: 12)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [

          _Card(titulo: '👤 Datos personales', child: Column(children: [
            _Campo(label: 'Nombre completo *', controller: _nombreCtrl),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _Campo(label: 'N.° documento', controller: _docCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _Campo(label: 'Fecha de nacimiento', controller: _fechaNacCtrl, hint: 'dd/mm/aaaa')),
            ]),
            const SizedBox(height: 12),
            _DropField(label: 'Sexo biológico', value: _sexo,
                options: const ['Femenino', 'Masculino', 'Intersexual'],
                onChanged: (v) => setState(() => _sexo = v!)),
          ])),
          const SizedBox(height: 14),

          _Card(titulo: '📍 Ubicación', child: Column(children: [
            _Campo(label: 'Vereda', controller: _veredaCtrl, hint: 'Ej: El Palmar'),
            const SizedBox(height: 12),
            _Campo(label: 'Municipio', controller: _municipioCtrl, hint: 'Ej: Popayán'),
            const SizedBox(height: 12),
            _Campo(label: 'Teléfono / celular', controller: _telefonoCtrl, hint: 'Opcional'),
          ])),
          const SizedBox(height: 14),

          _Card(titulo: '🏥 Módulo de atención', child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Selecciona el ciclo de vida principal del paciente',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: _modulos.map((m) {
              final sel = m == _modulo;
              return GestureDetector(
                onTap: () => setState(() => _modulo = m),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: sel ? _kVerde : _kBorder,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? _kVerde : Colors.white24),
                  ),
                  child: Text(m, style: TextStyle(
                    color: sel ? Colors.white : Colors.white60,
                    fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                  )),
                ),
              );
            }).toList()),
          ])),
          const SizedBox(height: 20),

          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: _guardando
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_outlined, color: Colors.white),
              label: Text(_guardando ? 'Guardando...' : 'Registrar paciente',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kVerde,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
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
      Text(titulo, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
      const SizedBox(height: 14), child,
    ]),
  );
}

class _Campo extends StatelessWidget {
  final String label; final TextEditingController controller; final String? hint;
  const _Campo({required this.label, required this.controller, this.hint});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
    const SizedBox(height: 4),
    TextField(controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
        isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        filled: true, fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    ),
  ]);
}

class _DropField extends StatelessWidget {
  final String label, value; final List<String> options; final ValueChanged<String?> onChanged;
  const _DropField({required this.label, required this.value, required this.options, required this.onChanged});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
    const SizedBox(height: 4),
    Container(padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(10)),
      child: DropdownButton<String>(value: value, isExpanded: true, underline: const SizedBox(),
        dropdownColor: _kCard, style: const TextStyle(color: Colors.white, fontSize: 14),
        items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
        onChanged: onChanged,
      ),
    ),
  ]);
}
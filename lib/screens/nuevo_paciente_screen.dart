import 'package:flutter/material.dart';
import '../database/database_helper.dart';

const Color _kBg     = Color(0xFF111111);
const Color _kCard   = Color(0xFF1E1E1E);
const Color _kVerde  = Color(0xFF1D9E75);
const Color _kBorder = Color(0xFF2A2A2A);

// ════════════════════════════════════════════════════════════════════
// DATOS CAUCA — Municipios y sus veredas
// ════════════════════════════════════════════════════════════════════
const Map<String, List<String>> _kCauca = {
  'Popayán': [
    'El Tablazo', 'La Rejada', 'El Sendero', 'Pisojé Alto', 'Pisojé Bajo',
    'La Yunga', 'El Charco', 'Calibío', 'Las Piedras', 'Poblazón',
    'La Olla', 'Figueroa', 'Julumito', 'Santa Rosa', 'Río Blanco',
  ],
  'Santander de Quilichao': [
    'El Turco', 'La Chapa', 'La Balsa', 'Mandivá', 'Loma Gruesa',
    'Dominguillo', 'El Palmar', 'Agua Bonita', 'La Cuchilla', 'Cabecera',
    'San Antonio', 'La Isla', 'Quinamayó', 'El Tajo', 'Yarumales',
  ],
  'Puerto Tejada': [
    'Cabecera Municipal', 'El Tiple', 'La Paila Naya', 'Guachené',
    'Villa Rica', 'La Pradera', 'Agua Azul',
  ],
  'Caloto': [
    'La Agustina', 'El Palo', 'Crucero', 'Tóez', 'El Guanábano',
    'Corinto', 'Honduras', 'La Herradura', 'La Palmera', 'San Rafael',
  ],
  'Corinto': [
    'Cabecera', 'El Barranco', 'La Quebrada', 'Potrerito', 'San Marcos',
    'La Victoria', 'El Ceibal', 'Guayabal', 'La Bodega',
  ],
  'Miranda': [
    'Cabecera', 'El Ortigal', 'La Elvira', 'El Pílamo', 'San Isidro',
    'La Alsacia', 'Tierranova', 'La Dominga',
  ],
  'Silvia': [
    'Pitayó', 'Quichaya', 'Tumburao', 'Usenda', 'Ambaló',
    'La Campana', 'El Rincón', 'Pueblillo', 'Cacique',
  ],
  'Inzá': [
    'Turminá', 'Tóez', 'San Andrés', 'Pedregal', 'La Laguna',
    'El Rosal', 'Guanacas', 'Yaquivá', 'La Ceja',
  ],
  'Páez': [
    'Belalcázar', 'Irlanda', 'Cohetando', 'Avirama', 'Togoima',
    'Ricaurte', 'La Troja', 'Chinas', 'San Luis',
  ],
  'Toribío': [
    'Tacueyó', 'San Francisco', 'Cabecera', 'La Palma', 'El Palo',
    'Chimicanguaz', 'La Esperanza',
  ],
  'El Tambo': [
    'Cabecera', 'La Estación', 'Santa Rosa', 'Melchor', 'San Joaquín',
    'La Playa', 'Cerro Gordo', 'El Cairo', 'Cuatro Esquinas',
  ],
  'Bolívar': [
    'Cabecera', 'San Lorenzo', 'El Ceral', 'Lerma', 'Almaguer',
    'San Sebastián', 'La Laja', 'Pancitará',
  ],
  'La Vega': [
    'Cabecera', 'El Carmelo', 'Descanse', 'San Miguel', 'Altamira',
    'La Caldera', 'Mindalá',
  ],
  'Guapi': [
    'Cabecera', 'San José de Naya', 'El Chuare', 'Limones',
    'Boca de Naya', 'Quiroga', 'Chamón',
  ],
  'Timbiquí': [
    'Cabecera', 'Coteje', 'Chanzará', 'Soledad', 'Guangüí',
    'Belén de Iguana', 'Brazo Largo',
  ],
  'López de Micay': [
    'Cabecera', 'Angostura', 'Puerto Médico', 'El Coco',
    'Punta Soldado', 'Riosucio',
  ],
  'Sucre': [
    'Cabecera', 'La Quebrada', 'Belén', 'San Pedro', 'La Sierra',
  ],
  'La Sierra': [
    'Cabecera', 'El Crucero', 'Melchor', 'San Joaquín', 'El Rosal',
  ],
  'Balboa': [
    'Cabecera', 'San Joaquín', 'La Carbonera', 'El Palmar', 'Quebradón',
  ],
  'Patía (El Bordo)': [
    'El Bordo', 'Olaya Herrera', 'La Fonda', 'Mojarras', 'La Fría',
    'San Juan', 'Piedra Sentada',
  ],
  'Mercaderes': [
    'Cabecera', 'El Estrecho', 'Berruecos', 'La Lupa', 'San Pablo',
  ],
  'Florencia': [
    'Cabecera', 'El Carmelo', 'La Palma', 'Quilcacé', 'San Joaquín',
  ],
  'Puracé': [
    'Coconuco', 'Paletará', 'Puracé', 'San Juan de Descanse', 'La Mina',
  ],
  'Sotará': [
    'Paispamba', 'El Crucero', 'La Palma', 'San Ignacio', 'El Charco',
  ],
  'Totoró': [
    'Cabecera', 'Polindara', 'San Juan', 'Paniquitá', 'Las Delicias',
  ],
  'Piendamó': [
    'Cabecera', 'Tunía', 'El Cofre', 'La Carbonera', 'Lame',
  ],
  'Morales': [
    'Cabecera', 'La Palma', 'La Selva', 'El Jardín', 'San Isidro',
  ],
  'Cajibío': [
    'Cabecera', 'El Recuerdo', 'La Pedregosa', 'Ortega', 'Dinde',
  ],
  'Rosas': [
    'Cabecera', 'La Llanada', 'El Salado', 'La Venta', 'Cañaveral',
  ],
  'Almaguer': [
    'Cabecera', 'San Lorenzo', 'Caquiona', 'El Rosal', 'Pancitará',
  ],
};

class NuevoPacienteScreen extends StatefulWidget {
  final Map<String, dynamic>? pacienteEditar;
  const NuevoPacienteScreen({super.key, this.pacienteEditar});
  @override
  State<NuevoPacienteScreen> createState() => _NuevoPacienteScreenState();
}

class _NuevoPacienteScreenState extends State<NuevoPacienteScreen> {
  final _nombreCtrl   = TextEditingController();
  final _docCtrl      = TextEditingController();
  final _telefonoCtrl = TextEditingController();

  String  _sexo         = 'Femenino';
  String  _modulo       = 'Gestación';
  String? _municipio;
  String? _vereda;
  DateTime? _fechaNac;
  bool    _guardando    = false;

  bool get _esEdicion => widget.pacienteEditar != null;
  int? get _idEdicion => widget.pacienteEditar?['id'] as int?;

  List<String> get _municipios => _kCauca.keys.toList()..sort();
  List<String> get _veredas =>
      _municipio != null ? (_kCauca[_municipio] ?? []) : [];

  final List<String> _modulos = [
    'Gestación', 'Primera infancia', 'Infancia',
    'Adolescencia', 'Juventud', 'Adultez', 'Vejez',
  ];

  @override
  void initState() {
    super.initState();
    if (_esEdicion) {
      final p = widget.pacienteEditar!;
      _nombreCtrl.text   = p['nombre']   ?? '';
      _docCtrl.text      = p['documento'] ?? '';
      _telefonoCtrl.text = p['telefono'] ?? '';
      _sexo   = (p['sexo']   as String?)?.isNotEmpty == true ? p['sexo']   : 'Femenino';
      _modulo = (p['modulo'] as String?)?.isNotEmpty == true ? p['modulo'] : 'Gestación';
      if (!_modulos.contains(_modulo)) _modulo = 'Gestación';
      if (!['Femenino', 'Masculino', 'Intersexual'].contains(_sexo)) _sexo = 'Femenino';

      // Municipio y vereda
      final mun = p['municipio'] as String?;
      final ver = p['vereda']   as String?;
      if (mun != null && _kCauca.containsKey(mun)) {
        _municipio = mun;
        if (ver != null && (_kCauca[mun]?.contains(ver) ?? false)) {
          _vereda = ver;
        }
      }

      // Fecha de nacimiento
      final fn = p['fecha_nac'] as String?;
      if (fn != null && fn.isNotEmpty) {
        try {
          // Soporta tanto dd/mm/yyyy como yyyy-mm-dd
          if (fn.contains('/')) {
            final parts = fn.split('/');
            _fechaNac = DateTime(
                int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
          } else {
            _fechaNac = DateTime.parse(fn);
          }
        } catch (_) {}
      }
    }
  }

  // ── Selector de fecha ────────────────────────────────────────────
  Future<void> _seleccionarFecha() async {
    final hoy = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaNac ?? DateTime(hoy.year - 25, hoy.month, hoy.day),
      firstDate: DateTime(1920),
      lastDate: hoy,
      locale: const Locale('es', 'CO'),
      helpText: 'Fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _kVerde,
            onPrimary: Colors.white,
            surface: Color(0xFF1E1E1E),
            onSurface: Colors.white,
          ),
          dialogBackgroundColor: const Color(0xFF111111),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _fechaNac = picked);
  }

  String get _fechaTexto {
    if (_fechaNac == null) return 'Seleccionar fecha';
    return '${_fechaNac!.day.toString().padLeft(2, '0')}/'
        '${_fechaNac!.month.toString().padLeft(2, '0')}/'
        '${_fechaNac!.year}';
  }

  // ── Guardar ──────────────────────────────────────────────────────
  Future<void> _guardar() async {
    if (_nombreCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('El nombre es obligatorio'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _guardando = true);

    final datos = {
      'nombre':    _nombreCtrl.text.trim(),
      'documento': _docCtrl.text.trim(),
      'fecha_nac': _fechaNac != null ? _fechaTexto : '',
      'sexo':      _sexo,
      'vereda':    _vereda   ?? '',
      'municipio': _municipio ?? '',
      'telefono':  _telefonoCtrl.text.trim(),
      'modulo':    _modulo,
    };

    if (_esEdicion) {
      await DatabaseHelper.instance.actualizarPaciente(_idEdicion!, datos);
    } else {
      await DatabaseHelper.instance.insertarPaciente({
        ...datos,
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    setState(() => _guardando = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_esEdicion
            ? '${_nombreCtrl.text.trim()} actualizado correctamente ✓'
            : '${_nombreCtrl.text.trim()} registrado correctamente ✓'),
        backgroundColor: _kVerde,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    for (final c in [_nombreCtrl, _docCtrl, _telefonoCtrl]) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg, foregroundColor: Colors.white,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_esEdicion ? 'Editar paciente' : 'Nuevo paciente',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text(
            _esEdicion
                ? 'Modificar datos · ${widget.pacienteEditar!['nombre'] ?? ''}'
                : 'Registro local · sin internet',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [

          // ── Datos personales ───────────────────────────────────────
          _Card(titulo: '👤 Datos personales', child: Column(children: [
            _Campo(label: 'Nombre completo *', controller: _nombreCtrl),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _Campo(label: 'N.° documento', controller: _docCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _FechaCampo(
                label: 'Fecha de nacimiento',
                texto: _fechaTexto,
                onTap: _seleccionarFecha,
              )),
            ]),
            const SizedBox(height: 12),
            _DropField(
              label: 'Sexo biológico',
              value: _sexo,
              options: const ['Femenino', 'Masculino', 'Intersexual'],
              onChanged: (v) => setState(() => _sexo = v!),
            ),
          ])),
          const SizedBox(height: 14),

          // ── Ubicación ─────────────────────────────────────────────
          _Card(titulo: '📍 Ubicación — Cauca', child: Column(children: [
            // Municipio
            _DropFieldSearch(
              label: 'Municipio',
              hint: 'Seleccionar municipio...',
              value: _municipio,
              options: _municipios,
              onChanged: (v) => setState(() {
                _municipio = v;
                _vereda = null; // resetea vereda al cambiar municipio
              }),
            ),
            const SizedBox(height: 12),
            // Vereda — deshabilitada hasta seleccionar municipio
            _DropFieldSearch(
              label: 'Vereda',
              hint: _municipio == null
                  ? 'Primero selecciona un municipio'
                  : 'Seleccionar vereda...',
              value: _vereda,
              options: _veredas,
              enabled: _municipio != null,
              onChanged: (v) => setState(() => _vereda = v),
            ),
            const SizedBox(height: 12),
            _Campo(
              label: 'Teléfono / celular',
              controller: _telefonoCtrl,
              hint: 'Opcional',
            ),
          ])),
          const SizedBox(height: 14),

          // ── Módulo ────────────────────────────────────────────────
          _Card(titulo: '🏥 Módulo de atención', child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Ciclo de vida principal del paciente',
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
                    fontSize: 13,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                  )),
                ),
              );
            }).toList()),
          ])),
          const SizedBox(height: 20),

          // ── Botón guardar ─────────────────────────────────────────
          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: _guardando
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Icon(_esEdicion ? Icons.edit_outlined : Icons.save_outlined,
                      color: Colors.white),
              label: Text(
                _guardando
                    ? (_esEdicion ? 'Actualizando...' : 'Guardando...')
                    : (_esEdicion ? 'Guardar cambios' : 'Registrar paciente'),
                style: const TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kVerde,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// WIDGETS AUXILIARES
// ════════════════════════════════════════════════════════════════════

class _Card extends StatelessWidget {
  final String titulo;
  final Widget child;
  const _Card({required this.titulo, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _kCard,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white10),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(titulo, style: const TextStyle(
          color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
      const SizedBox(height: 14),
      child,
    ]),
  );
}

class _Campo extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  const _Campo({required this.label, required this.controller, this.hint});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
    const SizedBox(height: 4),
    TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        filled: true, fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
      ),
    ),
  ]);
}

// Campo de fecha — abre el DatePicker al tocarlo
class _FechaCampo extends StatelessWidget {
  final String label;
  final String texto;
  final VoidCallback onTap;
  const _FechaCampo(
      {required this.label, required this.texto, required this.onTap});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
    const SizedBox(height: 4),
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Expanded(child: Text(texto,
              style: TextStyle(
                color: texto == 'Seleccionar fecha'
                    ? Colors.white24
                    : Colors.white,
                fontSize: 14,
              ))),
          const Icon(Icons.calendar_today_outlined,
              color: _kVerde, size: 16),
        ]),
      ),
    ),
  ]);
}

// Dropdown con lista de opciones (municipios / veredas)
class _DropFieldSearch extends StatelessWidget {
  final String label;
  final String hint;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  const _DropFieldSearch({
    required this.label,
    required this.hint,
    required this.value,
    required this.options,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
    const SizedBox(height: 4),
    GestureDetector(
      onTap: enabled && options.isNotEmpty
          ? () => _abrirSelector(context)
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: enabled
              ? const Color(0xFF2A2A2A)
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Expanded(child: Text(
            value ?? hint,
            style: TextStyle(
              color: value != null ? Colors.white : Colors.white24,
              fontSize: 14,
            ),
          )),
          Icon(Icons.arrow_drop_down,
              color: enabled ? _kVerde : Colors.white24, size: 20),
        ]),
      ),
    ),
  ]);

  void _abrirSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _SelectorSheet(
        titulo: label,
        opciones: options,
        seleccionado: value,
        onSeleccionar: (v) {
          Navigator.pop(context);
          onChanged(v);
        },
      ),
    );
  }
}

// Bottom sheet con lista buscable
class _SelectorSheet extends StatefulWidget {
  final String titulo;
  final List<String> opciones;
  final String? seleccionado;
  final ValueChanged<String> onSeleccionar;
  const _SelectorSheet({
    required this.titulo,
    required this.opciones,
    required this.seleccionado,
    required this.onSeleccionar,
  });
  @override
  State<_SelectorSheet> createState() => _SelectorSheetState();
}

class _SelectorSheetState extends State<_SelectorSheet> {
  final _buscarCtrl = TextEditingController();
  List<String> _filtradas = [];

  @override
  void initState() {
    super.initState();
    _filtradas = widget.opciones;
    _buscarCtrl.addListener(() {
      final q = _buscarCtrl.text.toLowerCase();
      setState(() {
        _filtradas = q.isEmpty
            ? widget.opciones
            : widget.opciones
                .where((o) => o.toLowerCase().contains(q))
                .toList();
      });
    });
  }

  @override
  void dispose() { _buscarCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, scrollCtrl) => Column(children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: 10, bottom: 6),
          width: 36, height: 4,
          decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2)),
        ),
        // Título
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(widget.titulo,
              style: const TextStyle(color: Colors.white,
                  fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        // Buscador
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          child: TextField(
            controller: _buscarCtrl,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Buscar...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
              filled: true, fillColor: const Color(0xFF2A2A2A),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
            ),
          ),
        ),
        // Lista
        Expanded(
          child: ListView.builder(
            controller: scrollCtrl,
            itemCount: _filtradas.length,
            itemBuilder: (_, i) {
              final op = _filtradas[i];
              final sel = op == widget.seleccionado;
              return ListTile(
                dense: true,
                title: Text(op,
                    style: TextStyle(
                      color: sel ? _kVerde : Colors.white,
                      fontWeight:
                          sel ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 14,
                    )),
                trailing: sel
                    ? const Icon(Icons.check, color: _kVerde, size: 18)
                    : null,
                onTap: () => widget.onSeleccionar(op),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _DropField extends StatelessWidget {
  final String label, value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  const _DropField(
      {required this.label,
      required this.value,
      required this.options,
      required this.onChanged});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(10)),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: _kCard,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            items: options
                .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ]);
}
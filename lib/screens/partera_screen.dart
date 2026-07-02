// ignore_for_file: use_build_context_synchronously
// lib/screens/partera_screen.dart  —  DISPERSALUD IA  —  "Modo Partera"
// v4-unified: dos canales IA · motivos clínicos · chips signos · eval obstétrica
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../database/database_helper.dart';
import '../services/connectivity_service.dart';
import '../services/ia_service.dart';

const _kFondo       = Color(0xFF0A130B);
const _kCard        = Color(0xFF101D11);
const _kCardAlt     = Color(0xFF182414);
const _kVerde       = Color(0xFF2ECC71);
const _kRosa        = Color(0xFFE8729A);
const _kRosaOsc     = Color(0xFFB8456E);
const _kMorado      = Color(0xFF7C4FD6);
const _kMoradoClaro = Color(0xFF9B6FCF);
const _kAzul        = Color(0xFF3FA9D6);
const _kNaranja     = Color(0xFFEF9F27);
const _kTeal        = Color(0xFF3FB6A8);
const _kBorder      = Color(0xFF24332A);
const _kTexto       = Color(0xFFE8F5E9);
const _kTextoSec    = Color(0xFFB2DFDB);
const _kTextoHint   = Color(0xFF6F9A78);
const _kRojo        = Color(0xFFE24B4A);

// ── Motivos de consulta clínicos ─────────────────────────────────────────────
const _kMotivos = [
  'Control prenatal de rutina',
  'Sangrado vaginal',
  'Dolor abdominal',
  'Cefalea intensa',
  'Visión borrosa o manchas',
  'Edema en manos o cara',
  'Disminución de movimientos fetales',
  'Fiebre o escalofríos',
  'Vómitos persistentes',
  'Presión arterial elevada',
  'Amenaza de parto prematuro',
  'Ruptura de membranas',
  'Consulta de puerperio',
  'Otro motivo',
];

// ── Signos de alarma ─────────────────────────────────────────────────────────
const _kSignos = [
  'Sin signos de alarma',
  'Sangrado vaginal',
  'Dolor abdominal intenso',
  'Cefalea severa',
  'Visión borrosa',
  'Edema en manos/cara',
  'Disminución mov. fetal',
  'Fiebre ≥ 38°C',
  'Presión ≥ 140/90',
  'Pérdida de líquido amniótico',
  'Convulsiones',
];

class ParteraScreen extends StatefulWidget {
  const ParteraScreen({super.key});
  @override
  State<ParteraScreen> createState() => _ParteraScreenState();
}

class _ParteraScreenState extends State<ParteraScreen> {
  bool _online   = false;
  bool _cargando = true;
  StreamSubscription<bool>? _connSub;

  // ── Gestantes ──────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _gestantes   = [];
  Map<String, dynamic>?      _gestanteSel;

  final _nombreCtrl   = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _semanasCtrl  = TextEditingController();
  String _ubicacionSel = 'Pueblo Nasa';

  // ── Consulta actual ────────────────────────────────────────────────────────
  DateTime _fechaConsulta  = DateTime.now();
  String   _tipAtencion    = 'Sabedora / Partera';
  String?  _motivoSel;
  final    _motivoOtroCtrl  = TextEditingController();
  final    _presionCtrl     = TextEditingController();
  final    _pesoCtrl        = TextEditingController();
  final    _semanasConsCtrl = TextEditingController();

  // ── Evaluación obstétrica (valores registrables) ───────────────────────────
  String _frecuenciaFetal   = '';
  String _alturaUterina     = '';
  String _presionObstetrica = '';
  String _pesoGestante      = '';
  String _examenes          = '';
  String _observacionesObs  = '';

  // ── Valoración obstétrica ──────────────────────────────────────────────────
  String?            _signoSel;
  final List<String> _signosRegistrados = [];

  // ── CANAL A — análisis en la card ─────────────────────────────────────────
  bool   _analizandoIA      = false;
  String _resultadoAnalisis = '';
  bool   _analisisVisible   = false;

  // ── CANAL B — chat libre con FAB ──────────────────────────────────────────
  bool   _chatVisible  = false;
  final  _chatCtrl     = TextEditingController();
  final  _chatScroll   = ScrollController();
  final  List<Map<String, String>> _chatMensajes = [];
  bool   _chatEnviando = false;

  static const _ubicaciones = [
    'Pueblo Nasa', 'Cali', 'Popayán', 'Buenaventura',
    'Palmira', 'Tuluá', 'Otro',
  ];
  static const _tiposAtencion = [
    'Sabedora / Partera', 'Médico/a', 'Enfermera/o', 'Promotor/a de salud',
  ];

  @override
  void initState() {
    super.initState();
    _initConn();
    _cargarGestantes();
    _chatMensajes.add({
      'rol':   'ia',
      'texto': '👶 Hola, soy DISPERSALUD IA.\n'
               'Pregúntame lo que necesites sobre salud materna: signos de alarma, '
               'medicamentos, protocolos, cuándo remitir...\n\n'
               'Para analizar a una gestante específica usa el botón "Analizar con IA" ↑',
    });
  }

  Future<void> _initConn() async {
    _online = await ConnectivityService.instance.verificarAhora();
    if (mounted) setState(() {});
    _connSub = ConnectivityService.instance.cambios.listen((v) {
      if (mounted) setState(() => _online = v);
    });
  }

  Future<void> _cargarGestantes() async {
    setState(() => _cargando = true);
    final todos = await DatabaseHelper.instance.obtenerPacientes();
    final lista = todos.where((p) {
      final sexo = (p['sexo'] as String? ?? '').toLowerCase();
      final mod  = (p['modulo'] as String? ?? '').toLowerCase();
      return sexo.contains('femenino') ||
             mod.contains('gestaci') ||
             mod.contains('partera');
    }).toList();
    if (mounted) setState(() { _gestantes = lista; _cargando = false; });
  }

  @override
  void dispose() {
    _connSub?.cancel();
    for (final c in [
      _nombreCtrl, _telefonoCtrl, _semanasCtrl,
      _motivoOtroCtrl, _presionCtrl, _pesoCtrl,
      _semanasConsCtrl, _chatCtrl,
    ]) { c.dispose(); }
    _chatScroll.dispose();
    super.dispose();
  }

  // ── Seleccionar gestante y autocompletar datos ────────────────────────────
  void _seleccionarGestante(String nombre) {
    final g = _gestantes.firstWhere((x) => x['nombre'] == nombre);
    setState(() {
      _gestanteSel = g;
      _telefonoCtrl.text = g['telefono'] ?? '';
      final semanas = g['semanas'] ?? g['datos_json'] ?? '';
      if (semanas is String && semanas.isNotEmpty && !semanas.startsWith('{')) {
        _semanasCtrl.text     = semanas;
        _semanasConsCtrl.text = semanas;
      }
      final muni = g['municipio'] ?? g['vereda'] ?? '';
      if (_ubicaciones.contains(muni)) _ubicacionSel = muni;
    });
  }

  Future<void> _registrarGestante() async {
    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      _snack('Ingresa el nombre de la gestante', color: _kRojo);
      return;
    }
    final Map<String, dynamic> datos = {
      'nombre':    nombre,
      'telefono':  _telefonoCtrl.text.trim(),
      'sexo':      'Femenino',
      'municipio': _ubicacionSel,
      'modulo':    'gestacion',
      'edad':      '',
    };
    final id = await DatabaseHelper.instance.insertarPaciente(datos);
    datos['id'] = id;
    await _cargarGestantes();
    setState(() {
      _gestanteSel = datos;
      _nombreCtrl.clear();
      _telefonoCtrl.clear();
      _semanasCtrl.clear();
    });
    _snack('✓ Gestante registrada correctamente');
  }

  // ── CANAL A: análisis — resultado solo en la card ─────────────────────────
  Future<void> _analizarIA() async {
    final nombre = _gestanteSel?['nombre'] ?? _nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      _snack('Selecciona o registra una gestante primero', color: _kNaranja);
      return;
    }
    if (!_online) {
      _snack('Necesitas conexión a internet para el análisis IA', color: _kNaranja);
      return;
    }
    setState(() { _analizandoIA = true; _analisisVisible = true; _resultadoAnalisis = ''; });

    final semanas = _semanasConsCtrl.text.trim().isNotEmpty
        ? _semanasConsCtrl.text.trim() : _semanasCtrl.text.trim();
    final motivo  = _motivoSel == 'Otro motivo'
        ? _motivoOtroCtrl.text.trim() : (_motivoSel ?? '');
    final presion = _presionCtrl.text.trim().isNotEmpty
        ? _presionCtrl.text.trim()
        : _presionObstetrica;
    final peso = _pesoCtrl.text.trim().isNotEmpty
        ? _pesoCtrl.text.trim()
        : _pesoGestante;
    final signos = _signosRegistrados.isNotEmpty
        ? _signosRegistrados.join(', ') : 'ninguno';

    final prompt =
        'Gestante: $nombre. '
        '${semanas.isNotEmpty ? "Semanas: $semanas. " : ""}'
        '${motivo.isNotEmpty ? "Motivo de consulta: $motivo. " : ""}'
        '${_frecuenciaFetal.isNotEmpty ? "FCF: $_frecuenciaFetal. " : ""}'
        '${_alturaUterina.isNotEmpty ? "Altura uterina: $_alturaUterina cm. " : ""}'
        '${presion.isNotEmpty ? "Presión arterial: $presion mmHg. " : ""}'
        '${peso.isNotEmpty ? "Peso: $peso kg. " : ""}'
        '${_examenes.isNotEmpty ? "Exámenes: $_examenes. " : ""}'
        '${_observacionesObs.isNotEmpty ? "Observaciones: $_observacionesObs. " : ""}'
        'Ubicación: $_ubicacionSel. '
        'Atendida por: $_tipAtencion. '
        'Signos de alarma: $signos.\n\n'
        'Como IA de salud materna para zonas rurales de Colombia, proporciona: '
        '1) Evaluación del estado actual según los datos. '
        '2) Riesgos a vigilar. '
        '3) Recomendaciones concretas (incluyendo si debe remitirse a urgencias). '
        'Responde en español claro y conciso.';

    final resp = await IaService.instance.consultar(prompt);
    if (mounted) setState(() { _resultadoAnalisis = resp; _analizandoIA = false; });
  }

  // ── CANAL B: chat libre ───────────────────────────────────────────────────
  Future<void> _chatEnviar() async {
    final txt = _chatCtrl.text.trim();
    if (txt.isEmpty) return;
    if (!_online) {
      _snack('Necesitas conexión a internet para el chat IA', color: _kNaranja);
      return;
    }
    setState(() {
      _chatMensajes.add({'rol': 'usuario', 'texto': txt});
      _chatCtrl.clear();
      _chatEnviando = true;
    });
    _scrollChat();

    final nombreGest = _gestanteSel?['nombre'] ?? _nombreCtrl.text.trim();
    final semanas    = _semanasConsCtrl.text.trim().isNotEmpty
        ? _semanasConsCtrl.text.trim() : _semanasCtrl.text.trim();
    final ctx = nombreGest.isNotEmpty
        ? 'Promotor consultando sobre gestante "$nombreGest"'
          '${semanas.isNotEmpty ? " ($semanas semanas)" : ""}. '
          'Pregunta: $txt'
        : 'Promotor de salud o partera en Colombia. Pregunta: $txt';

    final resp = await IaService.instance.consultar(ctx);
    if (mounted) {
      setState(() { _chatMensajes.add({'rol': 'ia', 'texto': resp}); _chatEnviando = false; });
      _scrollChat();
    }
  }

  void _scrollChat() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_chatScroll.hasClients) {
      _chatScroll.animateTo(_chatScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  });

  Future<void> _guardarConsulta() async {
    final nombre = _gestanteSel?['nombre'] ?? _nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      _snack('Selecciona o registra una gestante primero', color: _kRojo);
      return;
    }
    final motivo = _motivoSel == 'Otro motivo'
        ? _motivoOtroCtrl.text.trim() : (_motivoSel ?? '');
    await DatabaseHelper.instance.insertarConsulta({
      'paciente_id':   _gestanteSel?['id'],
      'nombre':        nombre,
      'modulo':        'gestacion',
      'semanas':       _semanasConsCtrl.text.trim(),
      'presion':       _presionCtrl.text.trim().isNotEmpty
          ? _presionCtrl.text.trim() : _presionObstetrica,
      'peso':          _pesoCtrl.text.trim().isNotEmpty
          ? _pesoCtrl.text.trim() : _pesoGestante,
      'nivel_riesgo':  _signosRegistrados.any((s) => s != 'Sin signos de alarma')
          ? 'alto' : 'estable',
      'observaciones': motivo,
      'datos_json': [
        if (_frecuenciaFetal.isNotEmpty)   'FCF: $_frecuenciaFetal',
        if (_alturaUterina.isNotEmpty)     'AU: $_alturaUterina cm',
        if (_presionObstetrica.isNotEmpty) 'PA: $_presionObstetrica',
        if (_pesoGestante.isNotEmpty)      'Peso: $_pesoGestante kg',
        if (_examenes.isNotEmpty)          'Exámenes: $_examenes',
        if (_observacionesObs.isNotEmpty)  'Obs: $_observacionesObs',
        if (_signosRegistrados.isNotEmpty) 'Signos: ${_signosRegistrados.join(", ")}',
      ].join(' | '),
    });
    _snack('✓ Consulta guardada correctamente');
  }

  void _whatsapp() async {
    final tel = (_gestanteSel?['telefono'] ?? _telefonoCtrl.text).toString().trim();
    if (tel.isEmpty) { _snack('Sin número de WhatsApp registrado', color: _kNaranja); return; }
    final num = tel.replaceAll(RegExp(r'[^\d]'), '');
    final uri = Uri.parse('https://wa.me/57$num');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _seleccionarFecha() async {
    final d = await showDatePicker(
      context: context, initialDate: _fechaConsulta,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: _kVerde)),
        child: child!,
      ),
    );
    if (d != null) setState(() => _fechaConsulta = d);
  }

  void _snack(String msg, {Color? color}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg), backgroundColor: color ?? _kVerde,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));

  String get _fechaFmt {
    const m = ['ene','feb','mar','abr','may','jun',
                'jul','ago','sep','oct','nov','dic'];
    return '${_fechaConsulta.day} ${m[_fechaConsulta.month-1]} ${_fechaConsulta.year}';
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final bp = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: _kFondo,
      // ── FAB circular con gradiente (Canal B) ─────────────────────────
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: bp > 0 ? 60 : 50),
        child: GestureDetector(
          onTap: () => setState(() => _chatVisible = !_chatVisible),
          child: Container(
            width: 58, height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                  colors: [_kMorado, Color(0xFF3A1D6E)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [
                BoxShadow(color: _kMorado.withOpacity(0.5), blurRadius: 16),
              ],
            ),
            child: Icon(
              _chatVisible ? Icons.close_rounded : Icons.smart_toy_rounded,
              color: Colors.white, size: 26),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Stack(children: [
        SafeArea(child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(14, 12, 14, 110 + bp),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildHeader(),
            const SizedBox(height: 16),

            // ── Gestante + Análisis IA (2 col en tablet) ──────────────
            LayoutBuilder(builder: (_, c) {
              if (c.maxWidth > 600) {
                return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: _cardGestante()),
                  const SizedBox(width: 12),
                  Expanded(child: _cardAnalisisIA()),
                ]);
              }
              return Column(children: [
                _cardGestante(),
                const SizedBox(height: 12),
                _cardAnalisisIA(),
              ]);
            }),
            const SizedBox(height: 14),
            _cardConsulta(),
            const SizedBox(height: 14),
            _cardEvaluacion(),
            const SizedBox(height: 14),
            _cardValoracion(),
            const SizedBox(height: 14),
            _cardAcciones(),
          ]),
        )),

        // ── Panel chat libre (Canal B) ─────────────────────────────────
        if (_chatVisible)
          Positioned(
            bottom: 90 + bp, right: 12, left: 12,
            child: _panelChat(),
          ),
      ]),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(width: 56, height: 56,
          decoration: BoxDecoration(
              color: _kRosa.withOpacity(0.1), shape: BoxShape.circle,
              border: Border.all(color: _kRosa.withOpacity(0.3))),
          child: const Icon(Icons.pregnant_woman_rounded, color: _kRosa, size: 30)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.favorite_rounded, color: _kRosa, size: 11),
          SizedBox(width: 4),
          Text('Modo Partera',
              style: TextStyle(color: _kRosa, fontSize: 11, fontWeight: FontWeight.w700)),
        ]),
        const Text('Partera DISPERSALUD 💗',
            style: TextStyle(color: _kTexto, fontSize: 17, fontWeight: FontWeight.bold)),
        const Text('Acompañamos cada vida que nace. 🍃',
            style: TextStyle(color: _kTextoHint, fontSize: 10.5)),
      ])),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: _online ? _kVerde.withOpacity(0.15) : _kNaranja.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _online ? _kVerde : _kNaranja)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 6, height: 6,
              decoration: BoxDecoration(
                  color: _online ? _kVerde : _kNaranja, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(_online ? 'Online' : 'Offline',
              style: TextStyle(
                  color: _online ? _kVerde : _kNaranja,
                  fontSize: 10, fontWeight: FontWeight.w700)),
        ]),
      ),
    ],
  );

  // ── Card Gestante ─────────────────────────────────────────────────────────

  Widget _cardGestante() => _card(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Container(width: 34, height: 34,
            decoration: const BoxDecoration(color: _kRosa, shape: BoxShape.circle),
            child: const Icon(Icons.pregnant_woman_rounded, color: Colors.white, size: 18)),
        const SizedBox(width: 8),
        const Text('Gestante',
            style: TextStyle(color: _kTexto, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(width: 6),
        const Icon(Icons.eco_rounded, color: _kVerde, size: 14),
      ]),
      const SizedBox(height: 12),

      _dropdown(
        valor: _gestanteSel?['nombre'] as String?,
        hint: 'Seleccionar gestante existente...',
        items: _gestantes.map((g) => g['nombre'] as String).toList(),
        onChanged: (v) { if (v != null) _seleccionarGestante(v); },
        icono: Icons.person_outline_rounded,
      ),

      // Info de la gestante seleccionada
      if (_gestanteSel != null) ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: _kVerde.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kVerde.withOpacity(0.25))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.check_circle_rounded, color: _kVerde, size: 14),
              const SizedBox(width: 6),
              Expanded(child: Text(_gestanteSel!['nombre'] ?? '',
                  style: const TextStyle(
                      color: _kVerde, fontSize: 12, fontWeight: FontWeight.bold))),
            ]),
            if ((_gestanteSel!['telefono'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.call_outlined, color: _kTextoHint, size: 12),
                const SizedBox(width: 5),
                Text(_gestanteSel!['telefono'].toString(),
                    style: const TextStyle(color: _kTextoSec, fontSize: 11)),
              ]),
            ],
            if ((_gestanteSel!['municipio'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.location_on_outlined, color: _kTextoHint, size: 12),
                const SizedBox(width: 5),
                Text(_gestanteSel!['municipio'].toString(),
                    style: const TextStyle(color: _kTextoSec, fontSize: 11)),
              ]),
            ],
          ]),
        ),
      ],

      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: Divider(color: _kBorder)),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text('o registra una nueva',
              style: TextStyle(color: _kRosa.withOpacity(0.8), fontSize: 10))),
        Expanded(child: Divider(color: _kBorder)),
      ]),
      const SizedBox(height: 10),
      _campo(_nombreCtrl, 'Nombre completo', Icons.person_outline_rounded),
      const SizedBox(height: 8),
      _campo(_telefonoCtrl, 'Teléfono (WhatsApp)', Icons.call_outlined,
          tipo: TextInputType.phone),
      const SizedBox(height: 8),
      _campo(_semanasCtrl, 'Semanas de gestación', Icons.calendar_month_outlined,
          tipo: TextInputType.number),
      const SizedBox(height: 8),
      _dropdown(
        valor: _ubicacionSel, hint: 'Ubicación', items: _ubicaciones,
        onChanged: (v) => setState(() => _ubicacionSel = v ?? _ubicacionSel),
        icono: Icons.location_on_outlined,
      ),
      const SizedBox(height: 10),
      SizedBox(width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _registrarGestante,
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
          label: const Text('Registrar gestante',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          style: ElevatedButton.styleFrom(
              backgroundColor: _kRosaOsc,
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
        ),
      ),
    ],
  ));

  // ── Card Análisis IA (Canal A) ────────────────────────────────────────────

  Widget _cardAnalisisIA() => _card(
    border: Border.all(color: _kMorado.withOpacity(0.4)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 36, height: 36,
            decoration: BoxDecoration(
                color: _kMorado, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 18)),
        const SizedBox(width: 10),
        const Expanded(child: Text('Análisis IA de la gestante',
            style: TextStyle(
                color: _kMoradoClaro, fontSize: 14, fontWeight: FontWeight.bold))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
              color: _kVerde.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20)),
          child: Text(_online ? 'Groq' : 'Offline',
              style: TextStyle(
                  color: _online ? _kVerde : _kNaranja,
                  fontSize: 9, fontWeight: FontWeight.bold)),
        ),
      ]),
      const SizedBox(height: 10),
      if (!_online)
        Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
              color: _kNaranja.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kNaranja.withOpacity(0.4))),
          child: const Row(children: [
            Icon(Icons.wifi_off_rounded, color: _kNaranja, size: 14),
            SizedBox(width: 8),
            Expanded(child: Text(
                'Sin internet — el análisis Groq no está disponible. '
                'El motor local sí funciona offline.',
                style: TextStyle(color: _kNaranja, fontSize: 11))),
          ]),
        ),
      const Text(
        'Completa los datos de la gestante y el motivo de consulta, '
        'luego pulsa Analizar para recibir orientación clínica detallada.',
        style: TextStyle(color: _kTextoSec, fontSize: 11.5, height: 1.4),
      ),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _analizandoIA ? null : _analizarIA,
          icon: _analizandoIA
              ? const SizedBox(width: 14, height: 14,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.analytics_rounded, color: Colors.white, size: 16),
          label: Text(_analizandoIA ? 'Analizando...' : 'Analizar con IA',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          style: ElevatedButton.styleFrom(
              backgroundColor: _kMorado,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        ),
      ),

      // ── Resultado del análisis (inline) ──────────────────────────────
      if (_analisisVisible) ...[
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: _kCardAlt, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kMorado.withOpacity(0.35))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.article_outlined, color: _kMoradoClaro, size: 14),
              const SizedBox(width: 6),
              const Text('Resultado del análisis',
                  style: TextStyle(
                      color: _kMoradoClaro, fontSize: 11, fontWeight: FontWeight.bold)),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _analisisVisible = false),
                child: const Icon(Icons.close_rounded, color: _kTextoHint, size: 14)),
            ]),
            const SizedBox(height: 8),
            if (_analizandoIA)
              const Row(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(width: 14, height: 14,
                    child: CircularProgressIndicator(
                        color: _kMoradoClaro, strokeWidth: 2)),
                SizedBox(width: 10),
                Text('Generando análisis...',
                    style: TextStyle(color: _kTextoHint, fontSize: 11)),
              ])
            else
              Text(
                _resultadoAnalisis.isEmpty
                    ? 'Pulsa "Analizar con IA" para ver el resultado aquí.'
                    : _resultadoAnalisis,
                style: const TextStyle(
                    color: _kTextoSec, fontSize: 11.5, height: 1.5)),
          ]),
        ),
      ],
      const SizedBox(height: 10),
      const Divider(color: _kBorder),
      const SizedBox(height: 6),
      Row(children: [
        const Icon(Icons.chat_bubble_outline_rounded, color: _kTextoHint, size: 13),
        const SizedBox(width: 6),
        const Expanded(child: Text(
            'Para preguntas libres usa el botón  •  abajo a la derecha',
            style: TextStyle(color: _kTextoHint, fontSize: 10.5))),
        Container(width: 22, height: 22,
            decoration: const BoxDecoration(color: _kMorado, shape: BoxShape.circle),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 13)),
      ]),
    ]),
  );

  // ── Card Consulta actual — motivo clínico seleccionable ───────────────────

  Widget _cardConsulta() => _card(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Row(children: [
        Icon(Icons.event_note_rounded, color: _kVerde, size: 18),
        SizedBox(width: 8),
        Text('Consulta actual',
            style: TextStyle(color: _kTexto, fontSize: 14, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 12),

      // Fecha
      GestureDetector(
        onTap: _seleccionarFecha,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
              color: _kFondo, borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kBorder)),
          child: Row(children: [
            const Icon(Icons.calendar_today_outlined, color: _kVerde, size: 14),
            const SizedBox(width: 8),
            Expanded(child: Text(_fechaFmt,
                style: const TextStyle(
                    color: _kTexto, fontSize: 12, fontWeight: FontWeight.w600))),
            const Icon(Icons.chevron_right_rounded, color: _kTextoHint, size: 16),
          ]),
        ),
      ),
      const SizedBox(height: 10),

      _label('Tipo de atención'),
      _dropdown(
        valor: _tipAtencion, hint: 'Tipo de atención',
        items: _tiposAtencion,
        onChanged: (v) => setState(() => _tipAtencion = v ?? _tipAtencion),
        icono: Icons.badge_outlined,
      ),
      const SizedBox(height: 10),

      _label('Motivo de consulta'),
      _dropdown(
        valor: _motivoSel, hint: 'Selecciona el motivo...', items: _kMotivos,
        onChanged: (v) => setState(() => _motivoSel = v),
        icono: Icons.medical_information_outlined,
        color: _kRosa,
      ),
      if (_motivoSel == 'Otro motivo') ...[
        const SizedBox(height: 8),
        _campo(_motivoOtroCtrl, 'Describe el motivo de consulta...', Icons.edit_outlined),
      ],
      const SizedBox(height: 10),

      _label('Semanas de gestación (en esta consulta)'),
      _campo(_semanasConsCtrl, 'Ej: 28', Icons.calendar_month_outlined,
          tipo: TextInputType.number),
      const SizedBox(height: 10),

      _label('Datos clínicos rápidos (opcional)'),
      Row(children: [
        Expanded(child: _campo(_presionCtrl, 'Presión (ej: 120/80)',
            Icons.water_drop_rounded)),
        const SizedBox(width: 8),
        Expanded(child: _campo(_pesoCtrl, 'Peso (kg)',
            Icons.monitor_weight_outlined, tipo: TextInputType.number)),
      ]),
    ],
  ));

  // ── Card Evaluación obstétrica — valores registrables ─────────────────────

  Widget _cardEvaluacion() => _card(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Row(children: [
        Icon(Icons.eco_rounded, color: _kVerde, size: 18),
        SizedBox(width: 8),
        Text('Evaluación de la gestación',
            style: TextStyle(color: _kTexto, fontSize: 14, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 4),
      const Text('Toca cada ítem para registrar el valor',
          style: TextStyle(color: _kTextoHint, fontSize: 10)),
      const SizedBox(height: 12),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 10, crossAxisSpacing: 10,
        childAspectRatio: 0.90,
        children: [
          _evalItem(
            Icons.favorite_rounded, 'Frecuencia\nfetal', _kRosa, _frecuenciaFetal,
            () => _mostrarInputObstetrico(
              titulo: 'Frecuencia cardíaca fetal',
              hint: 'Ej: 145 lpm',
              valorActual: _frecuenciaFetal,
              teclado: TextInputType.number,
              onGuardar: (v) => setState(() => _frecuenciaFetal = v),
            ),
          ),
          _evalItem(
            Icons.height_rounded, 'Altura\nuterina', _kMorado, _alturaUterina,
            () => _mostrarInputObstetrico(
              titulo: 'Altura uterina',
              hint: 'Ej: 28 cm',
              valorActual: _alturaUterina,
              teclado: TextInputType.number,
              onGuardar: (v) => setState(() => _alturaUterina = v),
            ),
          ),
          _evalItem(
            Icons.water_drop_rounded, 'Presión\narterial', _kAzul, _presionObstetrica,
            () => _mostrarInputObstetrico(
              titulo: 'Presión arterial',
              hint: 'Ej: 120/80 mmHg',
              valorActual: _presionObstetrica,
              teclado: TextInputType.text,
              onGuardar: (v) => setState(() => _presionObstetrica = v),
            ),
          ),
          _evalItem(
            Icons.monitor_weight_outlined, 'Peso\ngestante', _kVerde, _pesoGestante,
            () => _mostrarInputObstetrico(
              titulo: 'Peso de la gestante',
              hint: 'Ej: 65 kg',
              valorActual: _pesoGestante,
              teclado: TextInputType.number,
              onGuardar: (v) => setState(() => _pesoGestante = v),
            ),
          ),
          _evalItem(
            Icons.science_outlined, 'Exámenes\nrealizados', _kNaranja, _examenes,
            () => _mostrarInputObstetrico(
              titulo: 'Exámenes realizados',
              hint: 'Ej: Hemograma, Ecografía...',
              valorActual: _examenes,
              teclado: TextInputType.text,
              opciones: [
                'Hemograma', 'Ecografía', 'Parcial de orina',
                'Glucemia', 'VIH / Sífilis', 'Toxoplasma',
              ],
              onGuardar: (v) => setState(() => _examenes = v),
            ),
          ),
          _evalItem(
            Icons.description_outlined, 'Observaciones', _kTeal, _observacionesObs,
            () => _mostrarInputObstetrico(
              titulo: 'Observaciones clínicas',
              hint: 'Anotaciones adicionales...',
              valorActual: _observacionesObs,
              teclado: TextInputType.multiline,
              onGuardar: (v) => setState(() => _observacionesObs = v),
            ),
          ),
        ],
      ),
    ],
  ));

  // Ítem del grid con checkmark y valor registrado (doc 2)
  Widget _evalItem(IconData icono, String label, Color color,
      String valor, VoidCallback onTap) {
    final tiene = valor.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: tiene ? color.withOpacity(0.18) : color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: tiene ? color.withOpacity(0.7) : color.withOpacity(0.3)),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Stack(alignment: Alignment.topRight, children: [
            Container(width: 36, height: 36,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.18), shape: BoxShape.circle),
                child: Icon(icono, color: color, size: 18)),
            if (tiene)
              Container(width: 14, height: 14,
                  decoration: const BoxDecoration(
                      color: Color(0xFF2ECC71), shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 10)),
          ]),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center,
              style: TextStyle(
                  color: color, fontSize: 9,
                  fontWeight: FontWeight.w700, height: 1.2)),
          if (tiene) ...[
            const SizedBox(height: 3),
            Text(valor, textAlign: TextAlign.center,
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: color, fontSize: 9,
                    fontWeight: FontWeight.w900, height: 1.1)),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('Toca para\nregistrar',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: color.withOpacity(0.5),
                      fontSize: 7.5, height: 1.2)),
            ),
        ]),
      ),
    );
  }

  // Bottom sheet para capturar un valor de evaluación (doc 2)
  Future<void> _mostrarInputObstetrico({
    required String titulo,
    required String hint,
    required String valorActual,
    required TextInputType teclado,
    required ValueChanged<String> onGuardar,
    List<String>? opciones,
  }) async {
    final ctrl = TextEditingController(text: valorActual);
    String? opcionSel =
        opciones != null && opciones.contains(valorActual) ? valorActual : null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 36, height: 4,
                decoration: BoxDecoration(
                    color: _kBorder,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 14),
            Row(children: [
              const Icon(Icons.edit_rounded, color: _kVerde, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(titulo,
                  style: const TextStyle(
                      color: _kTexto, fontSize: 15, fontWeight: FontWeight.bold))),
            ]),
            const SizedBox(height: 14),

            // Opciones rápidas (si las hay)
            if (opciones != null) ...[
              Wrap(spacing: 8, runSpacing: 8,
                children: opciones.map((op) {
                  final sel = opcionSel == op;
                  return GestureDetector(
                    onTap: () => setModal(() => opcionSel = op),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: sel ? _kVerde.withOpacity(0.2) : _kFondo,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: sel ? _kVerde : _kBorder),
                      ),
                      child: Text(op, style: TextStyle(
                          color: sel ? _kVerde : _kTextoHint,
                          fontSize: 12,
                          fontWeight: sel
                              ? FontWeight.bold : FontWeight.normal)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(children: [
                const Expanded(child: Divider(color: _kBorder)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('o escribe',
                      style: const TextStyle(color: _kTextoHint, fontSize: 10))),
                const Expanded(child: Divider(color: _kBorder)),
              ]),
              const SizedBox(height: 10),
            ],

            // Campo de texto
            TextField(
              controller: ctrl,
              keyboardType: teclado,
              autofocus: opciones == null,
              maxLines: teclado == TextInputType.multiline ? 3 : 1,
              style: const TextStyle(color: _kTexto, fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: _kTextoHint, fontSize: 12),
                filled: true, fillColor: _kFondo,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _kBorder)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _kBorder)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _kVerde)),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final val = ctrl.text.trim().isNotEmpty
                      ? ctrl.text.trim() : (opcionSel ?? '');
                  Navigator.pop(ctx);
                  if (val.isNotEmpty) onGuardar(val);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: _kVerde,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                child: const Text('Guardar',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Card Valoración obstétrica — chips removibles ─────────────────────────

  Widget _cardValoracion() => _card(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Container(width: 30, height: 30,
            decoration: const BoxDecoration(color: _kRosa, shape: BoxShape.circle),
            child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 15)),
        const SizedBox(width: 8),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Valoración obstétrica',
                style: TextStyle(color: _kTexto, fontSize: 14, fontWeight: FontWeight.bold)),
            Text('Signos de alarma a registrar en esta consulta',
                style: TextStyle(color: _kTextoHint, fontSize: 10.5)),
          ])),
      ]),
      const SizedBox(height: 12),
      _dropdown(
        valor: _signoSel, hint: 'Seleccionar signo...', items: _kSignos,
        onChanged: (v) {
          if (v == null) return;
          setState(() {
            _signoSel = v;
            if (!_signosRegistrados.contains(v)) _signosRegistrados.add(v);
          });
        },
        icono: Icons.medical_information_outlined,
        color: _kRojo,
      ),
      const SizedBox(height: 10),

      if (_signosRegistrados.isNotEmpty) ...[
        const Text('Registrados en esta consulta:',
            style: TextStyle(color: _kTextoHint, fontSize: 10)),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6,
          children: _signosRegistrados.map((s) {
            final esAlarma = s != 'Sin signos de alarma';
            return Chip(
              label: Text(s, style: TextStyle(
                  color: esAlarma ? _kRojo : _kVerde, fontSize: 10)),
              backgroundColor: esAlarma
                  ? _kRojo.withOpacity(0.12) : _kVerde.withOpacity(0.12),
              side: BorderSide(
                  color: esAlarma
                      ? _kRojo.withOpacity(0.4) : _kVerde.withOpacity(0.4)),
              deleteIcon: Icon(Icons.close_rounded, size: 14,
                  color: esAlarma ? _kRojo : _kVerde),
              onDeleted: () => setState(() => _signosRegistrados.remove(s)),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
      ] else ...[
        Row(children: [
          Container(width: 7, height: 7,
              decoration: const BoxDecoration(
                  color: _kVerde, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          const Text('Sin signos de alarma registrados',
              style: TextStyle(
                  color: _kVerde, fontSize: 11.5, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 10),
      ],

      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: _kRosa.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kRosa.withOpacity(0.3))),
        child: const Row(children: [
          Icon(Icons.info_outline_rounded, color: _kRosa, size: 16),
          SizedBox(width: 8),
          Expanded(child: Text(
              'Identificar a tiempo los signos de alarma protege dos vidas.',
              style: TextStyle(
                  color: _kRosa, fontSize: 11.5,
                  fontStyle: FontStyle.italic, height: 1.3))),
        ]),
      ),
    ],
  ));

  // ── Card Acciones rápidas ─────────────────────────────────────────────────

  Widget _cardAcciones() => _card(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Row(children: [
        Icon(Icons.eco_rounded, color: _kVerde, size: 18),
        SizedBox(width: 8),
        Text('Acciones rápidas',
            style: TextStyle(color: _kTexto, fontSize: 14, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _accion(Icons.chat_rounded,
            'WhatsApp', const Color(0xFF25D366), _whatsapp)),
        const SizedBox(width: 8),
        Expanded(child: _accion(Icons.save_outlined,
            'Guardar',  _kTeal,    _guardarConsulta)),
        const SizedBox(width: 8),
        Expanded(child: _accion(Icons.event_available_outlined,
            'Cita',     _kNaranja, _seleccionarFecha)),
        const SizedBox(width: 8),
        Expanded(child: _accion(Icons.analytics_rounded,
            'Analizar', _kMorado,  _analizarIA)),
        const SizedBox(width: 8),
        Expanded(child: _accion(Icons.smart_toy_rounded,
            'Chat IA',  _kRosa,
            () => setState(() => _chatVisible = !_chatVisible))),
      ]),
    ],
  ));

  Widget _accion(IconData icono, String label, Color color, VoidCallback fn) =>
      GestureDetector(
        onTap: fn,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.4))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icono, color: color, size: 18),
            const SizedBox(height: 5),
            Text(label, textAlign: TextAlign.center,
                style: TextStyle(color: color, fontSize: 9,
                    fontWeight: FontWeight.bold, height: 1.2)),
          ]),
        ),
      );

  // ── Panel chat libre (Canal B) ────────────────────────────────────────────

  Widget _panelChat() => Container(
    height: 390,
    decoration: BoxDecoration(
        color: _kCard, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kMorado.withOpacity(0.5), width: 1.5),
        boxShadow: [BoxShadow(
            color: _kMorado.withOpacity(0.28), blurRadius: 24, spreadRadius: 2)]),
    child: Column(children: [
      // Header
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [_kMorado, Color(0xFF3A1D6E)]),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Row(children: [
          const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          const Expanded(child: Text('Chat IA — Preguntas libres',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
          if (_online)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10)),
              child: const Text('Groq activo',
                  style: TextStyle(color: Colors.white70, fontSize: 9)),
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _chatVisible = false),
            child: const Icon(Icons.close_rounded, color: Colors.white70, size: 18)),
        ]),
      ),

      // Mensajes
      Expanded(child: ListView.builder(
        controller: _chatScroll,
        padding: const EdgeInsets.all(10),
        itemCount: _chatMensajes.length + (_chatEnviando ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == _chatMensajes.length) {
            return Align(alignment: Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                    color: _kCardAlt,
                    borderRadius: BorderRadius.circular(10)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(
                          color: _kMoradoClaro, strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text('Escribiendo...',
                      style: TextStyle(color: _kTextoHint, fontSize: 11)),
                ])));
          }
          final msg  = _chatMensajes[i];
          final isIA = msg['rol'] == 'ia';
          return Align(
            alignment: isIA ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72),
              decoration: BoxDecoration(
                color: isIA ? _kCardAlt : _kMorado.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isIA ? _kBorder : _kMorado.withOpacity(0.4)),
              ),
              child: Text(msg['texto'] ?? '',
                  style: TextStyle(
                      color: isIA ? _kTextoSec : _kTexto,
                      fontSize: 11, height: 1.4)),
            ),
          );
        },
      )),

      // Input
      Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
        child: Row(children: [
          Expanded(child: TextField(
            controller: _chatCtrl,
            style: const TextStyle(color: _kTexto, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Pregunta sobre salud materna...',
              hintStyle: const TextStyle(color: _kTextoHint, fontSize: 11),
              filled: true, fillColor: _kFondo,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _kBorder)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _kBorder)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _kMorado)),
            ),
            onSubmitted: (_) => _chatEnviar(),
          )),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _chatEnviando ? null : _chatEnviar,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                  color: _chatEnviando ? _kBorder : _kMorado,
                  shape: BoxShape.circle),
              child: _chatEnviando
                  ? const Padding(padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ]),
      ),
    ]),
  );

  // ── Helpers UI ────────────────────────────────────────────────────────────

  Widget _card({required Widget child, Border? border}) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
        color: _kCard, borderRadius: BorderRadius.circular(16),
        border: border ?? Border.all(color: _kBorder)),
    child: child,
  );

  Widget _label(String txt) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(txt, style: const TextStyle(color: _kTextoHint, fontSize: 10)),
  );

  Widget _campo(TextEditingController ctrl, String hint, IconData icono,
      {TextInputType tipo = TextInputType.text}) =>
      TextField(
        controller: ctrl, keyboardType: tipo,
        style: const TextStyle(color: _kTexto, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _kTextoHint, fontSize: 12),
          prefixIcon: Icon(icono, color: _kTextoHint, size: 17),
          filled: true, fillColor: _kFondo,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kRosa)),
        ),
      );

  Widget _dropdown({
    required String? valor,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icono,
    Color? color,
  }) =>
      Theme(
        data: ThemeData(brightness: Brightness.dark, canvasColor: _kCardAlt),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
              color: _kFondo, borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color?.withOpacity(0.4) ?? _kBorder)),
          child: DropdownButton<String>(
            value: items.contains(valor) ? valor : null,
            isExpanded: true, isDense: true,
            underline: const SizedBox(), dropdownColor: _kCardAlt,
            hint: Row(children: [
              Icon(icono, color: _kTextoHint, size: 15),
              const SizedBox(width: 8),
              Text(hint, style: const TextStyle(color: _kTextoHint, fontSize: 12)),
            ]),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _kTextoHint),
            style: const TextStyle(color: _kTexto, fontSize: 13),
            selectedItemBuilder: (_) => items.map((o) => Align(
                alignment: Alignment.centerLeft,
                child: Row(children: [
                  Icon(icono, color: color ?? _kVerde, size: 15),
                  const SizedBox(width: 8),
                  Expanded(child: Text(o, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _kTexto, fontSize: 13))),
                ]))).toList(),
            items: items.map((o) => DropdownMenuItem(value: o,
                child: Text(o, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: onChanged,
          ),
        ),
      );
}
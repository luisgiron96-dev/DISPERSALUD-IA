// ignore_for_file: use_build_context_synchronously
// lib/screens/partera_screen.dart  —  DISPERSALUD IA  —  "Modo Partera"
// Panel de gestión gestante/partera con IA flotante funcional (Groq)
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
const _kVerdeOsc    = Color(0xFF1A7A42);
const _kRosa        = Color(0xFFE8729A);
const _kRosaOsc     = Color(0xFFB8456E);
const _kMorado      = Color(0xFF7C4FD6);
const _kMoradoClaro = Color(0xFF9B6FCF);
const _kAzul        = Color(0xFF3FA9D6);
const _kNaranja     = Color(0xFFEF9F27);
const _kAmarillo    = Color(0xFFD6B53F);
const _kTeal        = Color(0xFF3FB6A8);
const _kBorder      = Color(0xFF24332A);
const _kTexto       = Color(0xFFE8F5E9);
const _kTextoSec    = Color(0xFFB2DFDB);
const _kTextoHint   = Color(0xFF6F9A78);
const _kRojo        = Color(0xFFE24B4A);

class ParteraScreen extends StatefulWidget {
  const ParteraScreen({super.key});
  @override
  State<ParteraScreen> createState() => _ParteraScreenState();
}

class _ParteraScreenState extends State<ParteraScreen> {
  bool   _online   = false;
  bool   _cargando = true;
  StreamSubscription<bool>? _connSub;
  int    _tabIdx   = 0;

  // Gestantes
  List<Map<String, dynamic>> _gestantes   = [];
  Map<String, dynamic>?      _gestanteSel;

  // Form nueva gestante
  final _nombreCtrl   = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _semanasCtrl  = TextEditingController();
  String _ubicacionSel = 'Pueblo Nasa';

  // Consulta actual
  DateTime _fechaConsulta  = DateTime.now();
  String   _estadoCivilSel = 'Sabedora / Partera';
  final    _motivoCtrl     = TextEditingController();

  // Evaluación / Valoración
  String?            _signosAlarma;
  final List<String> _alertasRegistradas = [];

  // IA — panel flotante
  bool   _iaVisible    = false;
  final  _iaCtrl       = TextEditingController();
  final  List<Map<String, String>> _mensajesIA = [];
  bool   _enviandoIA   = false;
  bool   _analizandoIA = false;

  // ScrollController para auto-scroll del chat
  final _chatScroll = ScrollController();

  static const List<String> _ubicaciones = [
    'Pueblo Nasa', 'Cali', 'Popayán', 'Buenaventura',
    'Palmira', 'Tuluá', 'Otro',
  ];
  static const List<String> _estadosCiviles = [
    'Sabedora / Partera', 'Médico/a', 'Enfermera/o', 'Promotor/a de salud',
  ];

  @override
  void initState() {
    super.initState();
    _initConn();
    _cargarGestantes();
    _mensajesIA.add({
      'rol':   'ia',
      'texto': '👶 Soy DISPERSALUD IA — especializada en salud materna. '
               'Completa los datos de la gestante y el motivo de consulta, '
               'luego pulsa Analizar con IA para recibir orientación clínica, '
               'o escríbeme directamente cualquier pregunta.',
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
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _semanasCtrl.dispose();
    _motivoCtrl.dispose();
    _iaCtrl.dispose();
    _chatScroll.dispose();
    super.dispose();
  }

  // ── Acciones ──────────────────────────────────────────────────────────────

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

  // ── IA: análisis completo de la gestante ─────────────────────────────────

  Future<void> _analizarIA() async {
    if (_gestanteSel == null && _nombreCtrl.text.trim().isEmpty) {
      _snack('Selecciona o registra una gestante primero', color: _kNaranja);
      return;
    }
    if (!_online) {
      _snack('Se necesita conexión a internet para usar la IA', color: _kNaranja);
      return;
    }
    setState(() { _analizandoIA = true; _iaVisible = true; });

    final nombre  = _gestanteSel?['nombre'] ?? _nombreCtrl.text.trim();
    final semanas = _semanasCtrl.text.trim();
    final motivo  = _motivoCtrl.text.trim();

    final contexto =
        'Paciente gestante: $nombre. '
        '${semanas.isNotEmpty ? "Semanas de gestación: $semanas. " : ""}'
        '${motivo.isNotEmpty ? "Motivo de consulta: $motivo. " : ""}'
        'Ubicación: $_ubicacionSel. '
        'Atendida por: $_estadoCivilSel. '
        '${_signosAlarma != null && _signosAlarma != "Sin signos de alarma" ? "Signos de alarma detectados: $_signosAlarma." : "Sin signos de alarma registrados."}';

    _mensajesIA.add({
      'rol':   'usuario',
      'texto': '🩺 Analiza el estado de esta gestante y dame orientación clínica.',
    });
    _scrollChat();

    final prompt =
        '$contexto\n\n'
        'Como IA de salud materna especializada en zonas rurales de Colombia, '
        'proporciona: 1) Una evaluación breve del estado de la gestante, '
        '2) Posibles riesgos a vigilar según las semanas de gestación y los datos, '
        '3) Recomendaciones prácticas para el promotor o partera. '
        'Responde en español, de forma clara y concisa.';

    final resp = await IaService.instance.consultar(prompt);

    if (mounted) {
      setState(() {
        _mensajesIA.add({'rol': 'ia', 'texto': resp});
        _analizandoIA = false;
      });
      _scrollChat();
    }
  }

  // ── IA: mensaje libre del promotor ───────────────────────────────────────

  Future<void> _enviarMensajeIA() async {
    final txt = _iaCtrl.text.trim();
    if (txt.isEmpty) return;
    if (!_online) {
      _snack('Se necesita conexión a internet para usar la IA', color: _kNaranja);
      return;
    }

    setState(() {
      _mensajesIA.add({'rol': 'usuario', 'texto': txt});
      _iaCtrl.clear();
      _enviandoIA = true;
    });
    _scrollChat();

    // Contexto de la gestante actual para enriquecer las respuestas
    final nombreGest = _gestanteSel?['nombre'] ?? _nombreCtrl.text.trim();
    final contexto = nombreGest.isNotEmpty
        ? 'Contexto: consulta de salud materna en zona rural de Colombia. '
          'Gestante: $nombreGest. '
          '${_semanasCtrl.text.isNotEmpty ? "Semanas: ${_semanasCtrl.text}. " : ""}'
          'Pregunta del promotor de salud: $txt'
        : 'Contexto: consulta de salud materna y atención de partera en Colombia. '
          'Pregunta: $txt';

    final resp = await IaService.instance.consultar(contexto);

    if (mounted) {
      setState(() {
        _mensajesIA.add({'rol': 'ia', 'texto': resp});
        _enviandoIA = false;
      });
      _scrollChat();
    }
  }

  void _scrollChat() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScroll.hasClients) {
        _chatScroll.animateTo(
          _chatScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _guardarReporte() async {
    final nombre = _gestanteSel?['nombre'] ?? _nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      _snack('Selecciona o registra una gestante primero', color: _kRojo);
      return;
    }
    await DatabaseHelper.instance.insertarConsulta({
      'paciente_id':   _gestanteSel?['id'],
      'nombre':        nombre,
      'modulo':        'gestacion',
      'observaciones': _motivoCtrl.text.trim(),
    });
    _snack('✓ Reporte de consulta guardado');
  }

  void _whatsapp() async {
    final tel = (_gestanteSel?['telefono'] as String? ?? _telefonoCtrl.text).trim();
    if (tel.isEmpty) {
      _snack('Sin número de WhatsApp registrado', color: _kNaranja);
      return;
    }
    final num = tel.replaceAll(RegExp(r'[^\d]'), '');
    final uri = Uri.parse('https://wa.me/57$num');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _seleccionarSignoAlarma(String signo) => setState(() {
    _signosAlarma = signo;
    if (!_alertasRegistradas.contains(signo)) _alertasRegistradas.add(signo);
  });

  Future<void> _seleccionarFecha() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _fechaConsulta,
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
    const meses = ['ene','feb','mar','abr','may','jun',
                   'jul','ago','sep','oct','nov','dic'];
    return '${_fechaConsulta.day} ${meses[_fechaConsulta.month-1]} ${_fechaConsulta.year}';
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _kFondo,
      // ── Botón IA flotante ─────────────────────────────────────────────
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: bottomPad > 0 ? 70 : 60),
        child: FloatingActionButton.extended(
          onPressed: () => setState(() => _iaVisible = !_iaVisible),
          backgroundColor: _kMorado,
          elevation: 6,
          icon: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
          label: Text(
            _iaVisible ? 'Cerrar IA' : 'Consultar IA',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Stack(children: [
        SafeArea(
          child: Column(children: [
            Expanded(child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  14, 12, 14, 100 + bottomPad),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildHeader(),
                const SizedBox(height: 16),
                // ── Gestante + IA (2 columnas en tablet) ─────────────
                LayoutBuilder(builder: (ctx, c) {
                  if (c.maxWidth > 600) {
                    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: _cardGestante()),
                      const SizedBox(width: 12),
                      Expanded(child: _cardIA()),
                    ]);
                  }
                  return Column(children: [
                    _cardGestante(),
                    const SizedBox(height: 12),
                    _cardIA(),
                  ]);
                }),
                const SizedBox(height: 14),
                _cardConsultaActual(),
                const SizedBox(height: 14),
                _cardEvaluacionGestacion(),
                const SizedBox(height: 14),
                _cardValoracionObstetrica(),
                const SizedBox(height: 14),
                _cardAccionesRapidas(),
              ]),
            )),
          ]),
        ),

        // ── Bottom nav fijo ───────────────────────────────────────────
        Positioned(left: 0, right: 0, bottom: 0, child: _bottomNav()),

        // ── Panel IA flotante ─────────────────────────────────────────
        if (_iaVisible)
          Positioned(
            bottom: 130 + bottomPad,
            right: 12, left: 12,
            child: _chatIAPanel(),
          ),
      ]),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          color: _kRosa.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: _kRosa.withOpacity(0.3)),
        ),
        child: const Icon(Icons.pregnant_woman_rounded, color: _kRosa, size: 30),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [
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
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _online ? _kVerde.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _online ? _kVerde : Colors.orange),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 6, height: 6,
                decoration: BoxDecoration(
                    color: _online ? _kVerde : Colors.orange,
                    shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(_online ? 'Online' : 'Offline',
                style: TextStyle(
                    color: _online ? _kVerde : Colors.orange,
                    fontSize: 10, fontWeight: FontWeight.w700)),
          ]),
        ),
      ]),
    ],
  );

  // ── Card Gestante ──────────────────────────────────────────────────────

  Widget _cardGestante() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
        color: _kCard, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
      _dropdownDecorado(
        valor: _gestanteSel?['nombre'] as String?,
        hint: 'Seleccionar gestante...',
        items: _gestantes.map((g) => g['nombre'] as String).toList(),
        onChanged: (v) => setState(() =>
            _gestanteSel = _gestantes.firstWhere((g) => g['nombre'] == v)),
        icono: Icons.person_outline_rounded,
      ),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: Divider(color: _kBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text('o registra una nueva',
              style: TextStyle(color: _kRosa.withOpacity(0.8), fontSize: 10)),
        ),
        Expanded(child: Divider(color: _kBorder)),
      ]),
      const SizedBox(height: 10),
      _campoTexto(_nombreCtrl, 'Nombre completo', Icons.person_outline_rounded),
      const SizedBox(height: 8),
      _campoTexto(_telefonoCtrl, 'Teléfono (WhatsApp)', Icons.call_outlined,
          tipo: TextInputType.phone),
      const SizedBox(height: 8),
      _campoTexto(_semanasCtrl, 'Semanas de gestación (opcional)',
          Icons.calendar_month_outlined, tipo: TextInputType.number),
      const SizedBox(height: 8),
      _dropdownDecorado(
        valor: _ubicacionSel, hint: 'Ubicación', items: _ubicaciones,
        onChanged: (v) => setState(() => _ubicacionSel = v ?? _ubicacionSel),
        icono: Icons.location_on_outlined,
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _registrarGestante,
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
          label: const Text('Registrar gestante',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          style: ElevatedButton.styleFrom(
              backgroundColor: _kRosaOsc,
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        ),
      ),
    ]),
  );

  // ── Card IA Dispersalud ─────────────────────────────────────────────────

  Widget _cardIA() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _kCard, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _kMorado.withOpacity(0.4)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 36, height: 36,
            decoration: BoxDecoration(
                color: _kMorado, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18)),
        const SizedBox(width: 10),
        const Text('IA DISPERSALUD',
            style: TextStyle(color: _kMoradoClaro, fontSize: 14, fontWeight: FontWeight.bold)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
              color: _kVerde.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20)),
          child: const Text('Groq',
              style: TextStyle(color: _kVerde, fontSize: 9, fontWeight: FontWeight.bold)),
        ),
      ]),
      const SizedBox(height: 10),
      const Text(
        'Completa los datos de la gestante y el motivo de consulta, '
        'luego pulsa Analizar para recibir orientación clínica personalizada.',
        style: TextStyle(color: _kTextoSec, fontSize: 11.5, height: 1.4),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _analizandoIA ? null : _analizarIA,
          icon: _analizandoIA
              ? const SizedBox(width: 14, height: 14,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
          label: Text(_analizandoIA ? 'Analizando...' : 'Analizar con IA',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          style: ElevatedButton.styleFrom(
              backgroundColor: _kMorado,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        ),
      ),
      const SizedBox(height: 10),
      _iaListItem(Icons.shield_outlined, 'Orientación personalizada',
          () => setState(() => _iaVisible = true)),
      _iaListItem(Icons.warning_amber_rounded, 'Riesgos y alertas',
          () => setState(() => _iaVisible = true)),
      _iaListItem(Icons.auto_fix_high_rounded, 'Recomendaciones clínicas',
          () => setState(() => _iaVisible = true)),
    ]),
  );

  Widget _iaListItem(IconData icono, String texto, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(children: [
            Icon(icono, color: _kMoradoClaro, size: 15),
            const SizedBox(width: 8),
            Expanded(child: Text(texto,
                style: const TextStyle(color: _kTextoSec, fontSize: 12.5))),
            const Icon(Icons.chevron_right_rounded, color: _kTextoHint, size: 16),
          ]),
        ),
      );

  // ── Card Consulta actual ─────────────────────────────────────────────────

  Widget _cardConsultaActual() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
        color: _kCard, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [
        Icon(Icons.event_note_rounded, color: _kVerde, size: 18),
        SizedBox(width: 8),
        Text('Consulta actual',
            style: TextStyle(color: _kTexto, fontSize: 14, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: _seleccionarFecha,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
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
      _dropdownDecorado(
          valor: _estadoCivilSel, hint: 'Tipo de atención',
          items: _estadosCiviles,
          onChanged: (v) => setState(() => _estadoCivilSel = v ?? _estadoCivilSel),
          icono: Icons.badge_outlined),
      const SizedBox(height: 10),
      TextField(
        controller: _motivoCtrl, maxLines: 2,
        style: const TextStyle(color: _kTexto, fontSize: 12),
        decoration: InputDecoration(
          hintText: 'Describe el motivo de la consulta...',
          hintStyle: const TextStyle(color: _kTextoHint, fontSize: 11),
          filled: true, fillColor: _kFondo,
          contentPadding: const EdgeInsets.all(12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kVerde)),
        ),
      ),
    ]),
  );

  // ── Card Evaluación de la gestación ──────────────────────────────────────

  Widget _cardEvaluacionGestacion() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
        color: _kCard, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [
        Icon(Icons.eco_rounded, color: _kVerde, size: 18),
        SizedBox(width: 8),
        Text('Evaluación de la gestación',
            style: TextStyle(color: _kTexto, fontSize: 14, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 14),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 10, crossAxisSpacing: 10,
        childAspectRatio: 0.95,
        children: [
          _evalItem(Icons.favorite_rounded,        'Frecuencia\nfetal',     _kRosa),
          _evalItem(Icons.height_rounded,          'Altura\nuterina',       _kMorado),
          _evalItem(Icons.water_drop_rounded,      'Presión\narterial',     _kAzul),
          _evalItem(Icons.monitor_weight_outlined, 'Peso\ngestante',        _kVerde),
          _evalItem(Icons.science_outlined,        'Exámenes\nrealizados',  _kNaranja),
          _evalItem(Icons.description_outlined,    'Observaciones',         _kTeal),
        ],
      ),
    ]),
  );

  Widget _evalItem(IconData icono, String label, Color color) => GestureDetector(
    onTap: () => _snack('Registrar $label'),
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 36, height: 36,
            decoration: BoxDecoration(color: color.withOpacity(0.18), shape: BoxShape.circle),
            child: Icon(icono, color: color, size: 18)),
        const SizedBox(height: 6),
        Text(label, textAlign: TextAlign.center,
            style: TextStyle(color: color, fontSize: 9.5,
                fontWeight: FontWeight.w700, height: 1.2)),
      ]),
    ),
  );

  // ── Card Valoración obstétrica ───────────────────────────────────────────

  Widget _cardValoracionObstetrica() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
        color: _kCard, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 30, height: 30,
            decoration: const BoxDecoration(color: _kRosa, shape: BoxShape.circle),
            child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 15)),
        const SizedBox(width: 8),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Valoración obstétrica',
              style: TextStyle(color: _kTexto, fontSize: 14, fontWeight: FontWeight.bold)),
          Text('Datos clínicos y signos de alarma',
              style: TextStyle(color: _kTextoHint, fontSize: 10.5)),
        ])),
      ]),
      const SizedBox(height: 12),
      _dropdownDecorado(
        valor: _signosAlarma,
        hint: 'Seleccionar valoración...',
        items: const [
          'Sangrado vaginal', 'Dolor abdominal intenso', 'Cefalea severa',
          'Visión borrosa', 'Edema en manos/cara', 'Disminución mov. fetal',
          'Fiebre', 'Sin signos de alarma',
        ],
        onChanged: (v) { if (v != null) _seleccionarSignoAlarma(v); },
        icono: Icons.medical_information_outlined,
      ),
      const SizedBox(height: 10),
      Row(children: [
        Container(width: 7, height: 7,
            decoration: BoxDecoration(
                color: _alertasRegistradas.isEmpty ? _kVerde : _kRojo,
                shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Expanded(child: Text(
            _alertasRegistradas.isEmpty
                ? 'Sin signos de alarma registrados'
                : _alertasRegistradas.join(', '),
            style: TextStyle(
                color: _alertasRegistradas.isEmpty ? _kVerde : _kRojo,
                fontSize: 11.5, fontWeight: FontWeight.w600))),
      ]),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: _kRosa.withOpacity(0.08), borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kRosa.withOpacity(0.3))),
        child: const Row(children: [
          Icon(Icons.info_outline_rounded, color: _kRosa, size: 16),
          SizedBox(width: 8),
          Expanded(child: Text(
              'Identificar a tiempo los signos de alarma protege dos vidas.',
              style: TextStyle(color: _kRosa, fontSize: 11.5,
                  fontStyle: FontStyle.italic, height: 1.3))),
        ]),
      ),
    ]),
  );

  // ── Card Acciones rápidas ────────────────────────────────────────────────

  Widget _cardAccionesRapidas() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
        color: _kCard, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [
        Icon(Icons.eco_rounded, color: _kVerde, size: 18),
        SizedBox(width: 8),
        Text('Acciones rápidas',
            style: TextStyle(color: _kTexto, fontSize: 14, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _accionBtn(Icons.chat_rounded,         'WhatsApp',    const Color(0xFF25D366), _whatsapp)),
        const SizedBox(width: 8),
        Expanded(child: _accionBtn(Icons.note_alt_outlined,   'Notas',       _kTeal,    () => _snack('Notas de consulta'))),
        const SizedBox(width: 8),
        Expanded(child: _accionBtn(Icons.event_available_outlined, 'Cita',   _kNaranja, _seleccionarFecha)),
        const SizedBox(width: 8),
        Expanded(child: _accionBtn(Icons.description_outlined,'Reporte',     _kMorado,  _guardarReporte)),
        const SizedBox(width: 8),
        Expanded(child: _accionBtn(Icons.smart_toy_rounded,   'IA',          _kRosa,
            () => setState(() => _iaVisible = !_iaVisible))),
      ]),
    ]),
  );

  Widget _accionBtn(IconData icono, String label, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
              color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12),
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

  // ── Bottom Nav interno ───────────────────────────────────────────────────

  Widget _bottomNav() {
    final items = [
      ('Inicio',    Icons.home_rounded),
      ('Gestantes', Icons.people_outline_rounded),
      ('Alertas',   Icons.notifications_outlined),
      ('Historial', Icons.assignment_outlined),
      ('Perfil',    Icons.person_outline_rounded),
    ];
    return SafeArea(
      top: false,
      child: Container(
        color: _kCard,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: List.generate(items.length, (i) {
            final activo = i == _tabIdx;
            final (label, icono) = items[i];
            return Expanded(child: GestureDetector(
              onTap: () => setState(() => _tabIdx = i),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(icono, color: activo ? _kRosa : _kTextoHint, size: 20),
                const SizedBox(height: 3),
                Text(label, style: TextStyle(
                    color: activo ? _kRosa : _kTextoHint, fontSize: 9,
                    fontWeight: activo ? FontWeight.bold : FontWeight.normal)),
              ]),
            ));
          }),
        ),
      ),
    );
  }

  // ── Panel chat IA flotante ────────────────────────────────────────────────

  Widget _chatIAPanel() => Container(
    height: 360,
    decoration: BoxDecoration(
      color: _kCard,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _kMorado.withOpacity(0.5), width: 1.5),
      boxShadow: [BoxShadow(
          color: _kMorado.withOpacity(0.25), blurRadius: 24, spreadRadius: 2)],
    ),
    child: Column(children: [
      // Header del chat
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [_kMorado, Color(0xFF3A1D6E)]),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Row(children: [
          const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          const Expanded(child: Text('IA DISPERSALUD — Salud Materna',
              style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.bold, fontSize: 12))),
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
            onTap: () => setState(() => _iaVisible = false),
            child: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
          ),
        ]),
      ),

      // Mensajes
      Expanded(child: ListView.builder(
        controller: _chatScroll,
        padding: const EdgeInsets.all(10),
        itemCount: _mensajesIA.length + (_enviandoIA || _analizandoIA ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == _mensajesIA.length) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                    color: _kCardAlt, borderRadius: BorderRadius.circular(10)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(
                          color: _kMoradoClaro, strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text('Analizando...',
                      style: TextStyle(color: _kTextoHint, fontSize: 11)),
                ]),
              ),
            );
          }
          final m    = _mensajesIA[i];
          final isIA = m['rol'] == 'ia';
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
              child: Text(m['texto'] ?? '',
                  style: TextStyle(
                      color: isIA ? _kTextoSec : _kTexto,
                      fontSize: 11, height: 1.4)),
            ),
          );
        },
      )),

      // Input de mensaje
      Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
        child: Row(children: [
          Expanded(child: TextField(
            controller: _iaCtrl,
            style: const TextStyle(color: _kTexto, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Pregunta sobre salud materna...',
              hintStyle: const TextStyle(color: _kTextoHint, fontSize: 11),
              filled: true, fillColor: _kFondo,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _kBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _kBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _kMorado)),
            ),
            onSubmitted: (_) => _enviarMensajeIA(),
          )),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _enviandoIA ? null : _enviarMensajeIA,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                  color: _enviandoIA ? _kBorder : _kMorado,
                  shape: BoxShape.circle),
              child: _enviandoIA
                  ? const Padding(
                      padding: EdgeInsets.all(10),
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

  Widget _campoTexto(TextEditingController ctrl, String hint, IconData icono,
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

  Widget _dropdownDecorado({
    required String? valor,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icono,
  }) =>
      Theme(
        data: ThemeData(brightness: Brightness.dark, canvasColor: _kCardAlt),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
              color: _kFondo, borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kBorder)),
          child: DropdownButton<String>(
            value: items.contains(valor) ? valor : null,
            isExpanded: true, isDense: true,
            underline: const SizedBox(),
            dropdownColor: _kCardAlt,
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
                  Icon(icono, color: _kVerde, size: 15),
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
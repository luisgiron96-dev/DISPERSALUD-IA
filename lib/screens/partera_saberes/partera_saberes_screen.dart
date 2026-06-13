import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_theme.dart';
import '../../database/database_helper.dart';
import '../../services/ia_service.dart';
import '../../services/connectivity_service.dart';

// ════════════════════════════════════════════════════════════════════════════
//  partera_saberes_screen.dart — DISPERSALUD IA
//  Salud Integral Ancestral: Partería + Saberes Ancestrales en una sola pantalla
// ════════════════════════════════════════════════════════════════════════════

// ── Colores ──────────────────────────────────────────────────────────────────
const _kVerde      = Color(0xFF1D9E75);
const _kVerdeBI    = Color(0xFF2ECC71);
const _kVerdeOsc   = Color(0xFF1A7A42);
const _kFondo      = Color(0xFF0D1A0F);
const _kCard       = Color(0xFF132015);
const _kCardAlt    = Color(0xFF1A2B1C);
const _kBorder     = Color(0xFF2A3D2C);
const _kTexto      = Color(0xFFE8F5E9);
const _kTextoS     = Color(0xFFB2DFDB);
const _kTextoH     = Color(0xFF7AAB84);
const _kRosa       = Color(0xFF993556);
const _kMorado     = Color(0xFF534AB7);
const _kMoradoC    = Color(0xFF9B6FCF);
const _kNaranja    = Color(0xFFEF9F27);
const _kRojo       = Color(0xFFE24B4A);
const _kDorado     = Color(0xFFC9A227);

// ── Plantas medicinales ───────────────────────────────────────────────────────
class _Planta {
  final String nombre, uso, preparacion;
  final IconData icono;
  final Color color;
  const _Planta({required this.nombre, required this.uso,
      required this.preparacion, required this.icono, required this.color});
}

const _kPlantas = [
  _Planta(nombre: 'Manzanilla', uso: 'Cólicos y malestares estomacales',
    preparacion: 'Infusión – 1 taza\n2 veces al día',
    icono: Icons.local_florist, color: Color(0xFFDEB887)),
  _Planta(nombre: 'Hierbabuena', uso: 'Náuseas y digestión',
    preparacion: 'Infusión – 1 taza\ndespués de comidas',
    icono: Icons.spa, color: _kVerdeBI),
  _Planta(nombre: 'Ruda', uso: 'Limpieza energética y mal de aire',
    preparacion: 'Baño – 3 veces\npor semana',
    icono: Icons.eco, color: Color(0xFF6B8E23)),
  _Planta(nombre: 'Toronjil', uso: 'Ansiedad y nervios',
    preparacion: 'Infusión – 1 taza\nantes de dormir',
    icono: Icons.spa, color: Color(0xFF90EE90)),
  _Planta(nombre: 'Caléndula', uso: 'Inflamaciones y heridas',
    preparacion: 'Lavado o infusión\nuso externo',
    icono: Icons.local_florist, color: Color(0xFFFF8C00)),
];

const _kMotivos = [
  'Dolor abdominal', 'Náuseas', 'Embarazo',
  'Fiebre', 'Mal de ojo', 'Espanto', 'Otro',
];

const _kDesequilibrios = [
  'Frío en el cuerpo', 'Calor corporal', 'Susto o espanto',
  'Mal de ojo', 'Desequilibrio espiritual', 'Dolor de vientre',
  'Tristeza del alma', 'Fiebre espiritual', 'Otro',
];

const _kRecomPartera = [
  'Mantener reposo relativo',
  'Beber abundante agua tibia',
  'Alimentación balanceada',
  'Asistir al control prenatal cada 2 semanas',
  'Estar atenta a signos de alarma',
];

const _kSignosAlarma = [
  'Sangrado vaginal',
  'Dolor abdominal intenso',
  'Fiebre mayor a 38°C',
  'Pérdida de líquido',
  'Disminución de movimientos fetales',
];

// ════════════════════════════════════════════════════════════════════════════
class ParteraSaberesScreen extends StatefulWidget {
  const ParteraSaberesScreen({super.key});
  @override
  State<ParteraSaberesScreen> createState() => _ParteraSaberesState();
}

class _ParteraSaberesState extends State<ParteraSaberesScreen> {
  // Conectividad
  bool _online = false;
  StreamSubscription<bool>? _connSub;

  // Datos reales BD
  List<Map<String, dynamic>> _pacientes   = [];
  List<Map<String, dynamic>> _parteras    = [];
  List<Map<String, dynamic>> _historial   = [];
  bool _cargando = true;

  // Selección
  Map<String, dynamic>? _pacienteSel;
  Map<String, dynamic>? _parteraSel;

  // Formulario consulta
  String _motivoSel    = '';
  String _desequilSel  = '';
  String _semanas      = '';
  final _notasCtrl = TextEditingController();

  // IA
  String? _respuestaIA;
  String? _nivelRiesgo;
  bool _analizando = false;
  bool _iaExpandida = false;
  final List<Map<String, String>> _chatIA = [];
  final _chatCtrl = TextEditingController();
  bool _enviandoIA = false;

  // Guardar
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _initConn();
    _cargar();
    _chatIA.add({
      'rol': 'ia',
      'texto': '🌿 Soy DISPERSALUD IA. Selecciona paciente, partera y motivo de consulta para un análisis integral.',
    });
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _notasCtrl.dispose();
    _chatCtrl.dispose();
    super.dispose();
  }

  Future<void> _initConn() async {
    _online = await ConnectivityService.instance.verificarAhora();
    if (mounted) setState(() {});
    _connSub = ConnectivityService.instance.cambios
        .listen((v) { if (mounted) setState(() => _online = v); });
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final pacs  = await DatabaseHelper.instance.obtenerPacientes();
    final esps  = await DatabaseHelper.instance.obtenerEspecialistas();
    final hoy   = await DatabaseHelper.instance.consultasRecientes(limit: 6);

    final parts = esps.where((e) {
      final cat = (e['categoria_id'] as String? ?? '').toLowerCase();
      final esp = (e['especialidad']  as String? ?? '').toLowerCase();
      return cat.contains('ginec') || cat.contains('obste') ||
             esp.contains('parter') || esp.contains('matrona') ||
             esp.contains('ginec')  || esp.contains('obste');
    }).toList();

    if (!mounted) return;
    setState(() {
      _pacientes = pacs;
      _parteras  = parts;
      _historial = hoy;
      _cargando  = false;
    });
  }

  // ── IA Análisis ───────────────────────────────────────────────────────────
  Future<void> _analizarIA() async {
    final nombre  = _pacienteSel?['nombre'] as String? ?? 'Paciente';
    final partera = _parteraSel?['nombre']  as String? ?? 'Sin partera';
    final sem     = _semanas.isNotEmpty ? ', $_semanas semanas de gestación' : '';
    final deseq   = _desequilSel.isNotEmpty ? 'Desequilibrio: $_desequilSel.' : '';

    setState(() { _analizando = true; _respuestaIA = null; });

    final pregunta =
      'Consulta Salud Integral Ancestral. Paciente: $nombre$sem. '
      'Partera/Sabedora: $partera. Motivo: $_motivoSel. $deseq '
      'Indica: 1) Nivel riesgo (Bajo/Moderado/Alto/Urgente) '
      '2) Compatibilidad medicina ancestral+occidental '
      '3) Recomendación principal. Breve, en español colombiano.';

    final resp = await IaService.instance.consultar(pregunta);

    String nivel = 'MODERADO';
    final rl = resp.toLowerCase();
    if (rl.contains('urgente') || rl.contains('emergencia')) nivel = 'URGENTE';
    else if (rl.contains('alto')) nivel = 'ALTO';
    else if (rl.contains('bajo'))  nivel = 'BAJO';

    if (mounted) setState(() {
      _respuestaIA  = resp;
      _nivelRiesgo  = nivel;
      _analizando   = false;
      _iaExpandida  = true;
    });
  }

  Future<void> _enviarChatIA() async {
    final txt = _chatCtrl.text.trim();
    if (txt.isEmpty) return;
    setState(() {
      _chatIA.add({'rol': 'usuario', 'texto': txt});
      _chatCtrl.clear();
      _enviandoIA = true;
    });
    final contexto = _pacienteSel != null
        ? 'Paciente: ${_pacienteSel!['nombre']}. Motivo: $_motivoSel. '
        : '';
    final resp = await IaService.instance.consultar('$contexto$txt');
    if (mounted) setState(() {
      _chatIA.add({'rol': 'ia', 'texto': resp});
      _enviandoIA = false;
    });
  }

  // ── Guardar consulta ──────────────────────────────────────────────────────
  Future<void> _guardar() async {
    if (_pacienteSel == null) { _snack('Selecciona un paciente'); return; }
    setState(() => _guardando = true);
    await DatabaseHelper.instance.insertarConsulta({
      'paciente_id':   _pacienteSel!['id'],
      'nombre':        _pacienteSel!['nombre'],
      'modulo':        'Salud Integral Ancestral',
      'diagnostico':   _desequilSel.isNotEmpty ? _desequilSel : _motivoSel,
      'observaciones': 'Partera: ${_parteraSel?['nombre'] ?? '-'}. '
                       'Motivo: $_motivoSel. Notas: ${_notasCtrl.text}. '
                       'IA: ${_respuestaIA ?? 'Sin análisis'}',
      'nivel_riesgo':  _nivelRiesgo ?? 'estable',
      'fecha':         DateTime.now().toIso8601String(),
    });
    if (mounted) {
      setState(() => _guardando = false);
      _snack('✅ Consulta registrada exitosamente');
      _cargar();
    }
  }

  // ── Llamar partera ────────────────────────────────────────────────────────
  Future<void> _llamar() async {
    final tel = (_parteraSel?['telefono'] as String? ?? '').trim();
    if (tel.isEmpty) { _snack('Sin número de teléfono'); return; }
    final uri = Uri.parse('tel:${tel.replaceAll(RegExp(r'[\s\-\(\)]'), '')}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  // ── WhatsApp partera ──────────────────────────────────────────────────────
  Future<void> _whatsApp() async {
    String num = (_parteraSel?['telefono'] as String? ?? '')
        .replaceAll(RegExp(r'[^\d]'), '');
    if (num.length == 10) num = '57$num';
    if (num.isEmpty) { _snack('Sin número registrado'); return; }
    final msg = Uri.encodeComponent(
      'Hola ${_parteraSel?['nombre'] ?? ''}, contacto desde DISPERSALUD IA '
      'para atención de ${_pacienteSel?['nombre'] ?? 'paciente'}. 🌿');
    final uri = Uri.parse('https://wa.me/$num?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── Agendar visita ────────────────────────────────────────────────────────
  Future<void> _agendar() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (_, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: _kVerdeBI)),
        child: child!,
      ),
    );
    if (fecha != null && mounted) {
      final m = ['ene','feb','mar','abr','may','jun',
                  'jul','ago','sep','oct','nov','dic'];
      _snack('✅ Visita agendada: ${fecha.day} ${m[fecha.month-1]} ${fecha.year}');
    }
  }

  // ── Registrar visita domiciliaria ─────────────────────────────────────────
  Future<void> _visitaDomiciliaria() async {
    if (_pacienteSel == null) { _snack('Selecciona un paciente primero'); return; }
    setState(() => _guardando = true);
    await DatabaseHelper.instance.insertarConsulta({
      'paciente_id':   _pacienteSel!['id'],
      'nombre':        _pacienteSel!['nombre'],
      'modulo':        'Salud Integral Ancestral',
      'diagnostico':   'Visita domiciliaria',
      'observaciones': 'Visita domiciliaria registrada. ${_notasCtrl.text}',
      'nivel_riesgo':  'estable',
      'fecha':         DateTime.now().toIso8601String(),
    });
    if (mounted) {
      setState(() => _guardando = false);
      _snack('✅ Visita domiciliaria registrada');
      _cargar();
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: _kVerdeOsc,
        behavior: SnackBarBehavior.floating));

  Color _colorNivel(String? n) {
    switch (n) {
      case 'URGENTE': return _kRojo;
      case 'ALTO':    return Colors.orange;
      case 'BAJO':    return _kVerdeBI;
      default:        return _kNaranja;
    }
  }

  String _fechaHoy() {
    final n = DateTime.now();
    const m = ['ene','feb','mar','abr','may','jun',
                'jul','ago','sep','oct','nov','dic'];
    return '${n.day} ${m[n.month-1]} ${n.year}';
  }

  String _formatFecha(String? f) {
    if (f == null || f.isEmpty) return '';
    try {
      final dt = DateTime.parse(f);
      const m = ['ene','feb','mar','abr','may','jun',
                  'jul','ago','sep','oct','nov','dic'];
      return '${dt.day} ${m[dt.month-1]} ${dt.year}';
    } catch (_) { return f; }
  }

  // ════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kFondo,
      bottomNavigationBar: _bottomBar(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _kMorado,
        tooltip: 'IA DISPERSALUD',
        onPressed: () => _mostrarChatIA(),
        child: const Icon(Icons.smart_toy_rounded,
            color: Colors.white, size: 24),
      ),
      body: SafeArea(
        child: Column(children: [
          _header(),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: _kVerdeBI))
                : RefreshIndicator(
                    color: _kVerdeBI,
                    onRefresh: _cargar,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── PACIENTE + PARTERA ─────────────────────
                          Row(crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _cardPaciente()),
                              const SizedBox(width: 10),
                              Expanded(child: _cardPartera()),
                            ]),
                          const SizedBox(height: 12),

                          // ── MOTIVO DE CONSULTA ─────────────────────
                          _cardMotivo(),
                          const SizedBox(height: 12),

                          // ── DIAGNÓSTICO + PLANTAS ──────────────────
                          Row(crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _cardDiagnostico()),
                              const SizedBox(width: 10),
                              Expanded(child: _cardPlantas()),
                            ]),
                          const SizedBox(height: 12),

                          // ── RECOMENDACIONES PARTERA ────────────────
                          _cardRecomPartera(),
                          const SizedBox(height: 12),

                          // ── IA DISPERSALUD ─────────────────────────
                          _cardIA(),
                          const SizedBox(height: 12),

                          // ── SIGNOS ALARMA + HISTORIAL ──────────────
                          Row(crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _cardSignosAlarma()),
                              const SizedBox(width: 10),
                              Expanded(child: _cardHistorial()),
                            ]),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
          ),
        ]),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────────────────────────────────
  Widget _header() => Container(
    padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF0A1A0C), Color(0xFF132015)],
        begin: Alignment.topCenter, end: Alignment.bottomCenter),
      border: Border(bottom: BorderSide(color: _kBorder)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
                color: _kCard, borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kBorder)),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: _kTexto, size: 16),
          ),
        ),
        const SizedBox(width: 10),
        const Icon(Icons.eco_rounded, color: _kVerdeBI, size: 22),
        const SizedBox(width: 8),
        const Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Salud Integral Ancestral',
              style: TextStyle(color: _kTexto, fontSize: 17,
                  fontWeight: FontWeight.bold)),
          Text('Partería + Saberes Ancestrales',
              style: TextStyle(color: _kVerdeBI, fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ])),
        // Badge online
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
              color: _online ? _kVerdeBI.withOpacity(0.15) : _kCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _online ? _kVerdeBI : _kBorder)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(_online ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                color: _online ? _kVerdeBI : Colors.orange, size: 12),
            const SizedBox(width: 4),
            Text(_online ? 'En línea' : 'Offline',
                style: TextStyle(
                    color: _online ? _kVerdeBI : Colors.orange,
                    fontSize: 10, fontWeight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(width: 8),
        // Campana
        Stack(children: [
          Container(width: 34, height: 34,
              decoration: BoxDecoration(color: _kCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kBorder)),
              child: const Icon(Icons.notifications_outlined,
                  color: _kTextoS, size: 18)),
          Positioned(top: 4, right: 4,
              child: Container(width: 12, height: 12,
                  decoration: const BoxDecoration(
                      color: _kRojo, shape: BoxShape.circle),
                  child: const Center(child: Text('3',
                      style: TextStyle(color: Colors.white, fontSize: 7,
                          fontWeight: FontWeight.bold))))),
        ]),
      ]),
      const SizedBox(height: 4),
      const Padding(
        padding: EdgeInsets.only(left: 42),
        child: Text('Atención integral para la salud de nuestra comunidad',
            style: TextStyle(color: _kTextoH, fontSize: 10)),
      ),
    ]),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // CARD PACIENTE (GESTANTE)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _cardPaciente() => _Card(
    borde: _kRosa.withOpacity(0.4),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.person_rounded, color: _kRosa, size: 14),
        const SizedBox(width: 6),
        const Text('Paciente (Gestante)',
            style: TextStyle(color: _kRosa, fontSize: 11,
                fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 10),
      // Avatar
      Row(children: [
        Container(width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_kRosa, Color(0xFF6B1A3A)]),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(child: Text(
                _pacienteSel != null
                    ? (_pacienteSel!['nombre'] as String? ?? 'P')
                        .split(' ').first[0].toUpperCase()
                    : '?',
                style: const TextStyle(color: Colors.white,
                    fontSize: 20, fontWeight: FontWeight.bold)))),
        const SizedBox(width: 8),
        Expanded(child: Text(
            _pacienteSel?['nombre'] as String? ?? 'Sin seleccionar',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _kTexto, fontSize: 12,
                fontWeight: FontWeight.bold))),
      ]),
      const SizedBox(height: 10),
      // Selector
      DropdownButtonFormField<Map<String, dynamic>>(
        value: _pacienteSel,
        dropdownColor: _kCardAlt,
        style: const TextStyle(color: _kTexto, fontSize: 11),
        hint: const Text('Seleccionar paciente...',
            style: TextStyle(color: _kTextoH, fontSize: 10)),
        decoration: _inputDeco('Paciente'),
        items: _pacientes.map((p) => DropdownMenuItem(
          value: p,
          child: Text(p['nombre'] as String? ?? '',
              overflow: TextOverflow.ellipsis),
        )).toList(),
        onChanged: (p) => setState(() => _pacienteSel = p),
      ),
      if (_pacienteSel != null) ...[
        const SizedBox(height: 8),
        _infoFila(Icons.calendar_today_outlined,
            _pacienteSel!['fecha_nacimiento'] as String? ?? 'Sin edad'),
        _infoFila(Icons.favorite_border_rounded,
            _semanas.isNotEmpty ? '$_semanas semanas de gestación'
                : (_pacienteSel!['modulo'] as String? ?? '')),
        _infoFila(Icons.location_on_outlined,
            '${_pacienteSel!['vereda'] ?? ''} ${_pacienteSel!['municipio'] ?? ''}'.trim()),
        _infoFila(Icons.health_and_safety_outlined,
            _pacienteSel!['regimen'] as String? ?? 'EPS-S'),
        _infoFila(Icons.phone_outlined,
            _pacienteSel!['telefono'] as String? ?? 'Sin teléfono'),
      ],
    ]),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // CARD PARTERA / SABEDORA
  // ─────────────────────────────────────────────────────────────────────────
  Widget _cardPartera() => _Card(
    borde: _kVerdeBI.withOpacity(0.3),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.star_rounded, color: _kVerdeBI, size: 14),
        const SizedBox(width: 6),
        const Text('Partera / Sabedora',
            style: TextStyle(color: _kVerdeBI, fontSize: 11,
                fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 10),
      // Avatar
      Row(children: [
        Container(width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_kVerdeOsc, _kVerdeBI]),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(child: Text(
                _parteraSel != null
                    ? (_parteraSel!['nombre'] as String? ?? 'P')
                        .split(' ').first[0].toUpperCase()
                    : '🌿',
                style: const TextStyle(color: Colors.white,
                    fontSize: 20, fontWeight: FontWeight.bold)))),
        const SizedBox(width: 8),
        Expanded(child: Text(
            _parteraSel?['nombre'] as String? ?? 'Sin seleccionar',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _kTexto, fontSize: 12,
                fontWeight: FontWeight.bold))),
      ]),
      const SizedBox(height: 10),
      if (_parteras.isEmpty)
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/especialistas'),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _kVerdeOsc.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _kVerdeBI.withOpacity(0.3))),
            child: const Text('+ Agregar partera en Especialistas',
                textAlign: TextAlign.center,
                style: TextStyle(color: _kVerdeBI, fontSize: 10)),
          ),
        )
      else
        DropdownButtonFormField<Map<String, dynamic>>(
          value: _parteraSel,
          dropdownColor: _kCardAlt,
          style: const TextStyle(color: _kTexto, fontSize: 11),
          hint: const Text('Seleccionar partera...',
              style: TextStyle(color: _kTextoH, fontSize: 10)),
          decoration: _inputDeco('Partera'),
          items: _parteras.map((p) => DropdownMenuItem(
            value: p,
            child: Text(p['nombre'] as String? ?? '',
                overflow: TextOverflow.ellipsis),
          )).toList(),
          onChanged: (p) => setState(() => _parteraSel = p),
        ),
      if (_parteraSel != null) ...[
        const SizedBox(height: 8),
        _infoFila(Icons.star_outline, _parteraSel!['especialidad'] as String? ?? 'Partera Tradicional'),
        _infoFila(Icons.work_outline, '${_parteraSel!['anios_exp'] ?? 0} años de experiencia'),
        _infoFila(Icons.location_on_outlined, _parteraSel!['ciudad'] as String? ?? ''),
        _infoFila(Icons.phone_outlined, _parteraSel!['telefono'] as String? ?? ''),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: _kVerdeBI.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _kVerdeBI.withOpacity(0.4))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 6, height: 6,
                decoration: const BoxDecoration(
                    color: _kVerdeBI, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            const Text('Disponible', style: TextStyle(
                color: _kVerdeBI, fontSize: 10, fontWeight: FontWeight.w600)),
          ]),
        ),
      ],
    ]),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // MOTIVO DE CONSULTA
  // ─────────────────────────────────────────────────────────────────────────
  Widget _cardMotivo() => _Card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 28, height: 28,
            decoration: BoxDecoration(color: _kMorado.withOpacity(0.2),
                shape: BoxShape.circle),
            child: const Icon(Icons.medical_services_outlined,
                color: _kMoradoC, size: 14)),
        const SizedBox(width: 8),
        const Text('Motivo de consulta',
            style: TextStyle(color: _kTexto, fontSize: 13,
                fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 10),
      Wrap(spacing: 6, runSpacing: 6, children: _kMotivos.map((m) {
        final sel = m == _motivoSel;
        return GestureDetector(
          onTap: () => setState(() => _motivoSel = m),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: sel ? _kMorado : _kCardAlt,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: sel ? _kMoradoC : _kBorder,
                    width: sel ? 1.5 : 1)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (sel) ...[
                const Icon(Icons.check_rounded,
                    color: Colors.white, size: 10),
                const SizedBox(width: 4),
              ],
              Text(m, style: TextStyle(
                  color: sel ? Colors.white : _kTextoS,
                  fontSize: 11,
                  fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
            ]),
          ),
        );
      }).toList()),
      const SizedBox(height: 10),
      // Semanas gestación
      Row(children: [
        const Icon(Icons.pregnant_woman_rounded, color: _kRosa, size: 14),
        const SizedBox(width: 6),
        const Text('Semanas de gestación (opcional):',
            style: TextStyle(color: _kTextoH, fontSize: 10)),
        const SizedBox(width: 8),
        SizedBox(width: 60, child: TextField(
          keyboardType: TextInputType.number,
          style: const TextStyle(color: _kTexto, fontSize: 12),
          decoration: _inputDeco('0'),
          onChanged: (v) => setState(() => _semanas = v),
        )),
      ]),
    ]),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // DIAGNÓSTICO TRADICIONAL
  // ─────────────────────────────────────────────────────────────────────────
  Widget _cardDiagnostico() => _Card(
    borde: _kVerdeBI.withOpacity(0.2),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _tituloSeccion(Icons.eco_rounded, 'Diagnóstico tradicional', _kVerdeBI),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: _kFondo, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kBorder)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Desequilibrio identificado',
              style: TextStyle(color: _kTextoH, fontSize: 9.5)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _desequilSel.isEmpty ? null : _desequilSel,
            dropdownColor: _kCardAlt,
            style: const TextStyle(color: _kTexto, fontSize: 11),
            hint: const Text('Seleccionar...',
                style: TextStyle(color: _kTextoH, fontSize: 10)),
            decoration: _inputDeco('Desequilibrio'),
            items: _kDesequilibrios.map((d) => DropdownMenuItem(
              value: d,
              child: Text(d, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11)),
            )).toList(),
            onChanged: (v) => setState(() => _desequilSel = v ?? ''),
          ),
          if (_desequilSel.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.spa_rounded, color: _kVerdeBI, size: 16),
              const SizedBox(width: 6),
              Expanded(child: Text(_desequilSel,
                  style: const TextStyle(color: _kVerdeBI,
                      fontWeight: FontWeight.bold, fontSize: 11))),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Text('Nivel:  ',
                  style: TextStyle(color: _kTextoH, fontSize: 10)),
              Text(_nivelRiesgo ?? 'Moderado',
                  style: TextStyle(
                      color: _colorNivel(_nivelRiesgo),
                      fontWeight: FontWeight.bold, fontSize: 10)),
            ]),
          ],
        ]),
      ),
    ]),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // PLANTAS MEDICINALES
  // ─────────────────────────────────────────────────────────────────────────
  Widget _cardPlantas() => _Card(
    borde: _kVerdeBI.withOpacity(0.2),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _tituloSeccion(Icons.local_florist_rounded,
          'Recomendaciones ancestrales', _kVerdeBI),
      const SizedBox(height: 8),
      // Encabezado tabla
      Row(children: [
        const SizedBox(width: 28),
        Expanded(child: Text('Hierba / Planta',
            style: TextStyle(color: _kVerdeBI, fontSize: 8.5,
                fontWeight: FontWeight.bold))),
        Expanded(child: Text('Uso tradicional',
            style: TextStyle(color: _kVerdeBI, fontSize: 8.5,
                fontWeight: FontWeight.bold))),
        Expanded(child: Text('Preparación',
            style: TextStyle(color: _kVerdeBI, fontSize: 8.5,
                fontWeight: FontWeight.bold))),
      ]),
      const SizedBox(height: 6),
      Divider(color: _kBorder, height: 1),
      ..._kPlantas.map((p) => _filaPlanta(p)),
    ]),
  );

  Widget _filaPlanta(_Planta p) => GestureDetector(
    onTap: () => _verPreparacion(p),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 22, height: 22,
            decoration: BoxDecoration(
                color: p.color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(p.icono, color: p.color, size: 11)),
        const SizedBox(width: 6),
        Expanded(child: Text(p.nombre, style: const TextStyle(
            color: _kTexto, fontSize: 10, fontWeight: FontWeight.w600))),
        Expanded(child: Text(p.uso, style: const TextStyle(
            color: _kTextoS, fontSize: 9, height: 1.3))),
        Expanded(child: Text(p.preparacion, style: const TextStyle(
            color: _kTextoH, fontSize: 9, height: 1.3))),
      ]),
    ),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // RECOMENDACIONES PARTERA
  // ─────────────────────────────────────────────────────────────────────────
  Widget _cardRecomPartera() => _Card(
    borde: _kRosa.withOpacity(0.2),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _tituloSeccion(Icons.favorite_rounded, 'Recomendaciones de la partera', _kRosa),
      const SizedBox(height: 8),
      ..._kRecomPartera.map((r) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 18, height: 18,
              decoration: BoxDecoration(
                  color: _kVerdeBI.withOpacity(0.15), shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded,
                  color: _kVerdeBI, size: 10)),
          const SizedBox(width: 8),
          Expanded(child: Text(r, style: const TextStyle(
              color: _kTextoS, fontSize: 11, height: 1.3))),
        ]),
      )),
    ]),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // IA DISPERSALUD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _cardIA() => _Card(
    borde: _kMorado.withOpacity(0.4),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_kMorado, _kMoradoC]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.smart_toy_rounded,
                color: Colors.white, size: 20)),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.auto_awesome, color: _kMoradoC, size: 12),
            SizedBox(width: 4),
            Text('IA DISPERSALUD',
                style: TextStyle(color: _kMoradoC, fontSize: 13,
                    fontWeight: FontWeight.bold)),
          ]),
          const Text('Análisis integral de la atención',
              style: TextStyle(color: _kTextoH, fontSize: 9.5)),
        ]),
        const Spacer(),
        GestureDetector(
          onTap: _analizarIA,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_kMorado, Color(0xFF3A1D6E)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _analizando
                  ? const SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.auto_awesome,
                      color: Colors.white, size: 14),
              const SizedBox(width: 6),
              Text(_analizando ? 'Analizando...' : 'Ver análisis completo',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 11, fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
      ]),

      if (_respuestaIA != null) ...[
        const SizedBox(height: 12),
        // Bullets de análisis
        ...[
          'Riesgo materno actual:',
          'Embarazo: ${_semanas.isNotEmpty ? '$_semanas semanas' : 'Ver datos'}',
          'Signos vitales dentro de rangos normales',
          'Recomendación: Continuar seguimiento y vigilar signos de alarma',
        ].asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 5, height: 5, margin: const EdgeInsets.only(top: 5),
                decoration: const BoxDecoration(
                    color: _kVerdeBI, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(child: e.key == 0
                ? Row(children: [
                    Text(e.value, style: const TextStyle(
                        color: _kTextoS, fontSize: 10)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: _colorNivel(_nivelRiesgo).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: _colorNivel(_nivelRiesgo))),
                      child: Text(_nivelRiesgo ?? 'MODERADO',
                          style: TextStyle(
                              color: _colorNivel(_nivelRiesgo),
                              fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ])
                : Text(e.value, style: const TextStyle(
                    color: _kTextoS, fontSize: 10, height: 1.3))),
          ]),
        )),
      ] else ...[
        const SizedBox(height: 10),
        Text(
          'Selecciona paciente, partera y motivo de consulta,\n'
          'luego pulsa "Ver análisis completo".',
          style: const TextStyle(
              color: _kTextoH, fontSize: 10, height: 1.5),
        ),
      ],
    ]),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // SIGNOS DE ALARMA
  // ─────────────────────────────────────────────────────────────────────────
  Widget _cardSignosAlarma() => _Card(
    borde: _kRojo.withOpacity(0.3),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _tituloSeccion(Icons.warning_rounded, 'Signos de alarma', _kRojo),
      const SizedBox(height: 8),
      ..._kSignosAlarma.map((s) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Container(width: 14, height: 14,
              decoration: BoxDecoration(
                  border: Border.all(color: _kRojo, width: 1.5),
                  shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(s, style: const TextStyle(
              color: _kTextoS, fontSize: 10, height: 1.3))),
        ]),
      )),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: () => _mostrarGuiaSignos(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
              color: _kRojo.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _kRojo.withOpacity(0.4))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.menu_book_rounded, color: _kRojo, size: 14),
            const SizedBox(width: 6),
            const Text('Ver guía completa de signos',
                style: TextStyle(color: _kRojo, fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    ]),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // HISTORIAL
  // ─────────────────────────────────────────────────────────────────────────
  Widget _cardHistorial() => _Card(
    borde: _kVerdeBI.withOpacity(0.2),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _tituloSeccion(Icons.calendar_month_rounded,
          'Historial de consultas', _kVerdeBI),
      const SizedBox(height: 8),
      if (_historial.isEmpty)
        const Text('Sin consultas registradas',
            style: TextStyle(color: _kTextoH, fontSize: 10))
      else
        ..._historial.take(4).map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Timeline dot
            Column(children: [
              Container(width: 10, height: 10,
                  decoration: const BoxDecoration(
                      color: _kVerdeBI, shape: BoxShape.circle)),
              Container(width: 1, height: 20,
                  color: _kBorder),
            ]),
            const SizedBox(width: 8),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_formatFecha(c['fecha'] as String?),
                  style: const TextStyle(color: _kTexto, fontSize: 10,
                      fontWeight: FontWeight.w600)),
              Text(c['diagnostico'] as String? ?? c['modulo'] as String? ?? '',
                  style: const TextStyle(color: _kTextoS, fontSize: 9.5),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              if (c['observaciones'] != null)
                Text((c['observaciones'] as String).split('.').first,
                    style: const TextStyle(color: _kTextoH, fontSize: 9),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
          ]),
        )),
      const SizedBox(height: 4),
      GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/historial'),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Ver historial completo',
              style: TextStyle(color: _kVerdeBI, fontSize: 10,
                  fontWeight: FontWeight.w600)),
          SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, color: _kVerdeBI, size: 14),
        ]),
      ),
    ]),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // BOTTOM BAR DE ACCIONES
  // ─────────────────────────────────────────────────────────────────────────
  Widget _bottomBar() => Container(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
    decoration: const BoxDecoration(
        color: _kCard,
        border: Border(top: BorderSide(color: _kBorder))),
    child: Row(children: [
      // Registrar nueva consulta
      Expanded(
        flex: 3,
        child: GestureDetector(
          onTap: _guardar,
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_kVerdeOsc, _kVerdeBI]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _guardando
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.add_rounded,
                      color: Colors.white, size: 18),
              const SizedBox(width: 6),
              const Text('Registrar nueva consulta',
                  style: TextStyle(color: Colors.white,
                      fontWeight: FontWeight.bold, fontSize: 11)),
            ]),
          ),
        ),
      ),
      const SizedBox(width: 6),
      // Visita domiciliaria
      Expanded(
        flex: 2,
        child: GestureDetector(
          onTap: _visitaDomiciliaria,
          child: Container(
            height: 44,
            decoration: BoxDecoration(
                color: _kCardAlt, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kBorder)),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center,
                children: [
              Icon(Icons.home_outlined, color: _kTextoS, size: 15),
              SizedBox(width: 4),
              Flexible(child: Text('Registrar visita domiciliaria',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _kTextoS, fontSize: 9.5),
                  maxLines: 2)),
            ]),
          ),
        ),
      ),
      const SizedBox(width: 6),
      // Agregar nota rápida
      Expanded(
        flex: 2,
        child: GestureDetector(
          onTap: _mostrarNotaRapida,
          child: Container(
            height: 44,
            decoration: BoxDecoration(
                color: _kCardAlt, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kBorder)),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center,
                children: [
              Icon(Icons.edit_note_rounded, color: _kTextoS, size: 15),
              SizedBox(width: 4),
              Flexible(child: Text('Agregar nota rápida',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _kTextoS, fontSize: 9.5),
                  maxLines: 2)),
            ]),
          ),
        ),
      ),
    ]),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // MODALES / BOTTOM SHEETS
  // ─────────────────────────────────────────────────────────────────────────
  void _mostrarChatIA() => showModalBottomSheet(
    context: context, isScrollControlled: true,
    backgroundColor: _kCard,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => StatefulBuilder(builder: (ctx, setS) => SizedBox(
      height: MediaQuery.of(ctx).size.height * 0.75,
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [_kMorado, Color(0xFF3A1D6E)]),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(children: [
            const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('IA DISPERSALUD', style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold,
                  fontSize: 14)),
              Text('Salud Integral Ancestral', style: TextStyle(
                  color: Colors.white70, fontSize: 10)),
            ])),
            Container(width: 8, height: 8,
                decoration: BoxDecoration(
                    color: _online ? _kVerdeBI : Colors.orange,
                    shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(_online ? 'Groq' : 'Offline',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 9)),
          ]),
        ),
        // Mensajes
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _chatIA.length + (_enviandoIA ? 1 : 0),
          itemBuilder: (_, i) {
            if (i == _chatIA.length) return Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _kCardAlt,
                    borderRadius: BorderRadius.circular(10)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(
                          color: _kMoradoC, strokeWidth: 2)),
                  const SizedBox(width: 8),
                  const Text('Analizando...',
                      style: TextStyle(color: _kTextoH, fontSize: 11)),
                ]),
              ),
            );
            final m = _chatIA[i];
            final esIA = m['rol'] == 'ia';
            return Align(
              alignment: esIA ? Alignment.centerLeft : Alignment.centerRight,
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7),
                decoration: BoxDecoration(
                    color: esIA ? _kCardAlt : _kMorado.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: esIA ? _kBorder : _kMorado.withOpacity(0.4))),
                child: Text(m['texto'] ?? '', style: TextStyle(
                    color: esIA ? _kTextoS : _kTexto,
                    fontSize: 11, height: 1.4)),
              ),
            );
          },
        )),
        // Input
        Container(
          padding: EdgeInsets.fromLTRB(12, 6, 12,
              MediaQuery.of(ctx).viewInsets.bottom + 10),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _chatCtrl,
              style: const TextStyle(color: _kTexto, fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Pregunta sobre el paciente...',
                hintStyle: const TextStyle(color: _kTextoH, fontSize: 11),
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
              onSubmitted: (_) async {
                await _enviarChatIA();
                setS(() {});
              },
            )),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                await _enviarChatIA();
                setS(() {});
              },
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                    color: _enviandoIA ? _kBorder : _kMorado,
                    shape: BoxShape.circle),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
          ]),
        ),
      ]),
    )),
  );

  void _verPreparacion(_Planta p) => showModalBottomSheet(
    context: context,
    backgroundColor: _kCard,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(p.icono, color: p.color, size: 24),
          const SizedBox(width: 10),
          Text(p.nombre, style: const TextStyle(
              color: _kTexto, fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 14),
        const Text('Uso tradicional:', style: TextStyle(
            color: _kVerdeBI, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 4),
        Text(p.uso, style: const TextStyle(color: _kTextoS, fontSize: 13)),
        const SizedBox(height: 12),
        const Text('Preparación:', style: TextStyle(
            color: _kVerdeBI, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 4),
        Text(p.preparacion, style: const TextStyle(
            color: _kTextoS, fontSize: 13, height: 1.5)),
        const SizedBox(height: 14),
        const Text('⚠️ Consultar siempre con la sabedora o partera local '
            'antes de administrar plantas medicinales.',
            style: TextStyle(color: Colors.orange, fontSize: 11, height: 1.4)),
      ]),
    ),
  );

  void _mostrarGuiaSignos() => showModalBottomSheet(
    context: context,
    backgroundColor: _kCard,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => DraggableScrollableSheet(
      expand: false, initialChildSize: 0.6,
      builder: (_, ctrl) => ListView(
        controller: ctrl, padding: const EdgeInsets.all(20),
        children: [
          const Text('Guía completa de signos de alarma',
              style: TextStyle(color: _kTexto, fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Remitir de inmediato ante cualquiera de estos signos:',
              style: TextStyle(color: _kTextoH, fontSize: 12)),
          const SizedBox(height: 14),
          ...[
            ('Sangrado vaginal', 'Cualquier sangrado durante el embarazo es una emergencia. No esperar.'),
            ('Dolor abdominal intenso', 'Puede indicar desprendimiento de placenta o parto prematuro.'),
            ('Fiebre mayor a 38°C', 'Buscar foco infeccioso. Si >39°C: remisión urgente.'),
            ('Pérdida de líquido', 'Puede indicar ruptura de membranas. Evitar infecciones.'),
            ('Disminución de movimientos fetales', 'Contar movimientos. Menos de 10 en 2h: emergencia.'),
            ('Presión ≥ 140/90 + cefalea', 'Sospecha preeclampsia. Remisión URGENTE.'),
            ('Convulsiones', 'Eclampsia. EMERGENCIA ABSOLUTA. Llamar a urgencias.'),
            ('Vómito persistente', 'Hiperemesis gravídica. Riesgo de deshidratación severa.'),
          ].map((e) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: _kRojo.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kRojo.withOpacity(0.3))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              const Icon(Icons.warning_rounded, color: _kRojo, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.$1, style: const TextStyle(
                    color: _kTexto, fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 2),
                Text(e.$2, style: const TextStyle(
                    color: _kTextoS, fontSize: 11, height: 1.3)),
              ])),
            ]),
          )),
        ],
      ),
    ),
  );

  void _mostrarNotaRapida() => showModalBottomSheet(
    context: context, isScrollControlled: true,
    backgroundColor: _kCard,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16,
          MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Agregar nota rápida', style: TextStyle(
            color: _kTexto, fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextField(
          controller: _notasCtrl, maxLines: 4,
          style: const TextStyle(color: _kTexto, fontSize: 12),
          decoration: _inputDeco('Escribe una observación rápida...'),
        ),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: _kVerdeBI,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
          onPressed: () { Navigator.pop(context); _snack('✅ Nota guardada'); },
          child: const Text('Guardar nota',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        )),
      ]),
    ),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS UI
  // ─────────────────────────────────────────────────────────────────────────
  Widget _tituloSeccion(IconData icono, String titulo, Color color) =>
      Row(children: [
        Icon(icono, color: color, size: 15),
        const SizedBox(width: 6),
        Expanded(child: Text(titulo, style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.bold))),
      ]);

  Widget _infoFila(IconData icono, String valor) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(children: [
      Icon(icono, color: _kTextoH, size: 11),
      const SizedBox(width: 5),
      Expanded(child: Text(valor, style: const TextStyle(
          color: _kTextoS, fontSize: 10), overflow: TextOverflow.ellipsis)),
    ]),
  );

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: _kTextoH, fontSize: 10),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    filled: true, fillColor: _kFondo,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _kBorder)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _kBorder)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _kVerdeBI)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET CARD REUTILIZABLE
// ─────────────────────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  final Color? borde;
  const _Card({required this.child, this.borde});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF132015),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borde ?? const Color(0xFF2A3D2C)),
    ),
    child: child,
  );
}

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../../database/database_helper.dart';
import '../../services/ia_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/pdf_service.dart';

// ════════════════════════════════════════════════════════════════════════════
//  partera_saberes_screen.dart — DISPERSALUD IA
//  Salud Integral Materna y Ancestral: Partería + Saberes Ancestrales + IA
// ════════════════════════════════════════════════════════════════════════════

// ── Colores ──────────────────────────────────────────────────────────────────
const _kVerde      = Color(0xFF1D9E75);
const _kVerdeBI    = Color(0xFF2ECC71);
const _kVerdeOsc   = Color(0xFF1A7A42);
const _kFondo      = Color(0xFF0B1410);
const _kCard       = Color(0xFF11201A);
const _kCardAlt    = Color(0xFF152419);
const _kBorder     = Color(0xFF22372A);
const _kTexto      = Color(0xFFE8F5E9);
const _kTextoS     = Color(0xFFA9C9B0);
const _kTextoH     = Color(0xFF6E9279);
const _kRosa       = Color(0xFF993556);
const _kMorado     = Color(0xFF534AB7);
const _kMoradoC    = Color(0xFF9B6FCF);
const _kNaranja    = Color(0xFFEF9F27);
const _kRojo       = Color(0xFFE24B4A);
const _kDorado     = Color(0xFFC9A227);
const _kAzul       = Color(0xFF3D8BCF);

// ─────────────────────────────────────────────────────────────────────────────
// BIBLIOTECA DE PLANTAS — ampliada con categorías por síntoma
// ─────────────────────────────────────────────────────────────────────────────
class _Planta {
  final String nombre, nombreCientifico, preparacion, dosis, usoAncestral,
      contraindicaciones;
  final List<String> categorias;
  final Color color;
  const _Planta({
    required this.nombre,
    required this.nombreCientifico,
    required this.preparacion,
    required this.dosis,
    required this.usoAncestral,
    required this.contraindicaciones,
    required this.categorias,
    required this.color,
  });
}

const _kCategoriasPlantas = [
  'Todas', 'Náuseas', 'Fiebre', 'Dolor', 'Lactancia', 'Postparto', 'Ansiedad',
];

const _kPlantas = [
  _Planta(
    nombre: 'Manzanilla', nombreCientifico: 'Matricaria chamomilla',
    preparacion: 'Infusión', dosis: '1 taza, 2 veces al día',
    usoAncestral: 'Náuseas, cólicos, digestión, malestares estomacales',
    contraindicaciones: 'No administrar en altas cantidades en embarazo de alto riesgo.',
    categorias: ['Náuseas', 'Dolor'],
    color: Color(0xFFDEB887),
  ),
  _Planta(
    nombre: 'Hierbabuena', nombreCientifico: 'Mentha spicata',
    preparacion: 'Infusión', dosis: '1 taza después de comidas',
    usoAncestral: 'Náuseas, digestión lenta, gases',
    contraindicaciones: 'Evitar en exceso si hay reflujo severo.',
    categorias: ['Náuseas'],
    color: _kVerdeBI,
  ),
  _Planta(
    nombre: 'Toronjil', nombreCientifico: 'Melissa officinalis',
    preparacion: 'Infusión', dosis: '1 taza antes de dormir',
    usoAncestral: 'Ansiedad, nervios, insomnio leve',
    contraindicaciones: 'No combinar con sedantes sin supervisión.',
    categorias: ['Ansiedad'],
    color: Color(0xFF90EE90),
  ),
  _Planta(
    nombre: 'Caléndula', nombreCientifico: 'Calendula officinalis',
    preparacion: 'Lavado o infusión', dosis: 'Uso externo, 2 veces al día',
    usoAncestral: 'Inflamaciones, heridas, grietas en pezones',
    contraindicaciones: 'Solo uso externo durante lactancia.',
    categorias: ['Postparto', 'Lactancia'],
    color: Color(0xFFFF8C00),
  ),
  _Planta(
    nombre: 'Jengibre', nombreCientifico: 'Zingiber officinale',
    preparacion: 'Infusión o masticado', dosis: '1 trozo pequeño, 2 veces al día',
    usoAncestral: 'Náuseas matutinas, mareo, digestión',
    contraindicaciones: 'Evitar en exceso si hay riesgo de sangrado.',
    categorias: ['Náuseas', 'Dolor'],
    color: Color(0xFFE3A857),
  ),
  _Planta(
    nombre: 'Sauco', nombreCientifico: 'Sambucus nigra',
    preparacion: 'Infusión', dosis: '1 taza, 3 veces al día',
    usoAncestral: 'Fiebre, gripa, resfriado',
    contraindicaciones: 'No usar flores verdes ni en exceso.',
    categorias: ['Fiebre'],
    color: Color(0xFF7E57C2),
  ),
  _Planta(
    nombre: 'Eucalipto', nombreCientifico: 'Eucalyptus globulus',
    preparacion: 'Vapor o infusión', dosis: 'Inhalación 10 min, 1 vez al día',
    usoAncestral: 'Fiebre, congestión, malestar respiratorio',
    contraindicaciones: 'No usar en niños menores de 2 años.',
    categorias: ['Fiebre'],
    color: Color(0xFF4FA98C),
  ),
  _Planta(
    nombre: 'Hinojo', nombreCientifico: 'Foeniculum vulgare',
    preparacion: 'Infusión', dosis: '1 taza, 2 veces al día',
    usoAncestral: 'Producción de leche materna, gases del bebé',
    contraindicaciones: 'Consultar con partera antes de uso prolongado.',
    categorias: ['Lactancia'],
    color: Color(0xFF8BC34A),
  ),
  _Planta(
    nombre: 'Anís estrellado', nombreCientifico: 'Illicium verum',
    preparacion: 'Infusión', dosis: '1 taza después de comidas',
    usoAncestral: 'Producción de leche, cólicos del lactante',
    contraindicaciones: 'No confundir con anís japonés (tóxico).',
    categorias: ['Lactancia', 'Dolor'],
    color: Color(0xFFD4A574),
  ),
  _Planta(
    nombre: 'Cola de caballo', nombreCientifico: 'Equisetum arvense',
    preparacion: 'Infusión', dosis: '1 taza al día',
    usoAncestral: 'Recuperación postparto, retención de líquidos',
    contraindicaciones: 'No usar más de 2 semanas continuas.',
    categorias: ['Postparto'],
    color: Color(0xFF5D8AA8),
  ),
  _Planta(
    nombre: 'Valeriana', nombreCientifico: 'Valeriana officinalis',
    preparacion: 'Infusión', dosis: '1 taza antes de dormir',
    usoAncestral: 'Ansiedad, estrés postparto, insomnio',
    contraindicaciones: 'No combinar con otros sedantes.',
    categorias: ['Ansiedad'],
    color: Color(0xFFB39DDB),
  ),
  _Planta(
    nombre: 'Romero', nombreCientifico: 'Rosmarinus officinalis',
    preparacion: 'Infusión o baño', dosis: '1 taza o baño 1 vez al día',
    usoAncestral: 'Dolor muscular, fatiga, circulación',
    contraindicaciones: 'Evitar en cantidades altas durante embarazo.',
    categorias: ['Dolor'],
    color: Color(0xFF6B8E5A),
  ),
];

const _kPlantasNoRecomendadas = [
  ('Ruda', 'Puede provocar contracciones uterinas', Icons.warning_amber_rounded),
  ('Poleo', 'Puede provocar abortos espontáneos', Icons.warning_amber_rounded),
  ('Artemisa', 'Puede provocar contracciones', Icons.warning_amber_rounded),
  ('Higuerilla', 'Tóxica en embarazo', Icons.dangerous_rounded),
];

const _kMotivos = [
  'Dolor abdominal', 'Náuseas', 'Control prenatal',
  'Fiebre', 'Mal de ojo', 'Espanto', 'Postparto', 'Otro',
];

const _kDesequilibrios = [
  'Frío en el cuerpo', 'Calor corporal', 'Susto o espanto',
  'Mal de ojo', 'Desequilibrio espiritual', 'Dolor de vientre',
  'Tristeza del alma', 'Fiebre espiritual', 'Otro',
];

const _kRecomPartera = [
  'Reposo relativo',
  'Beber abundante agua de panela y limón',
  'Alimentación balanceada con alimentos propios',
  'Control prenatal cada 2 semanas',
  'Estar atenta a signos de alarma',
  'Baño de hierbas tibias para relajación',
];

const _kSignosAlarma = [
  'Sangrado vaginal',
  'Dolor abdominal intenso',
  'Fiebre mayor a 38°C',
  'Pérdida de líquido',
  'Disminución de mov. fetales',
];

const _kSemanasControl = [12, 16, 20, 24, 28, 32, 36, 40];

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
  List<Map<String, dynamic>> _pacientes = [];
  List<Map<String, dynamic>> _parteras  = [];
  List<Map<String, dynamic>> _historial = [];
  bool _cargando = true;

  // Selección
  Map<String, dynamic>? _pacienteSel;
  Map<String, dynamic>? _parteraSel;

  // Formulario consulta
  String _motivoSel    = '';
  String _desequilSel  = '';
  final _notasCtrl = TextEditingController();

  // Biblioteca de plantas
  String _categoriaPlantaSel = 'Todas';
  final _buscarPlantaCtrl = TextEditingController();
  String _buscarPlanta = '';

  // Controles gestacionales realizados — calculado desde consultas reales
  int _semanasActuales = 0;
  List<Map<String, dynamic>> _consultasPaciente = [];

  // Audio (notas de voz)
  final _recorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  bool _grabando = false;
  bool _reproduciendo = false;
  String? _audioPath;
  Duration _audioPos = Duration.zero;
  Duration _audioDur = Duration.zero;

  // Foto evidencia
  String? _fotoPath;
  final _picker = ImagePicker();

  // IA
  String? _respuestaIA;
  String? _nivelRiesgo;
  bool _analizando = false;
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
      'texto': '🌿 Soy DISPERSALUD IA. Selecciona paciente, partera y motivo '
          'de consulta para un análisis integral.',
    });

    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _audioPos = p);
    });
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _audioDur = d);
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() { _reproduciendo = false; _audioPos = Duration.zero; });
    });
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _notasCtrl.dispose();
    _chatCtrl.dispose();
    _buscarPlantaCtrl.dispose();
    _recorder.dispose();
    _audioPlayer.dispose();
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
    final pacs = await DatabaseHelper.instance.obtenerPacientes();
    final esps = await DatabaseHelper.instance.obtenerEspecialistas();
    final hoy  = await DatabaseHelper.instance.consultasRecientes(limit: 6);

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
      _historial = hoy.where((h) =>
          (h['modulo'] as String? ?? '').contains('Salud Integral') ||
          (h['modulo'] as String? ?? '').contains('Ancestral')).toList();
      if (_historial.isEmpty) _historial = hoy;
      _cargando = false;
    });
  }

  // ── IA Análisis ───────────────────────────────────────────────────────────
  Future<void> _analizarIA() async {
    final nombre  = _pacienteSel?['nombre'] as String? ?? 'Paciente';
    final partera = _parteraSel?['nombre']  as String? ?? 'Sin partera';
    final sem     = ', $_semanasActuales semanas de gestación';
    final deseq   = _desequilSel.isNotEmpty ? 'Desequilibrio: $_desequilSel.' : '';
    final motivo  = _motivoSel.isNotEmpty ? _motivoSel : 'Control general';

    setState(() { _analizando = true; _respuestaIA = null; });

    final pregunta =
      'Consulta Salud Integral Materna y Ancestral. Paciente: $nombre$sem. '
      'Partera/Sabedora: $partera. Motivo: $motivo. $deseq '
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
      _respuestaIA = resp;
      _nivelRiesgo = nivel;
      _analizando  = false;
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
    final pacienteId = _pacienteSel!['id'] as int;
    await DatabaseHelper.instance.insertarConsulta({
      'paciente_id':   pacienteId,
      'nombre':        _pacienteSel!['nombre'],
      'modulo':        'Salud Integral Ancestral',
      'diagnostico':   _desequilSel.isNotEmpty ? _desequilSel : _motivoSel,
      'observaciones': 'Partera: ${_parteraSel?['nombre'] ?? '-'}. '
                       'Motivo: $_motivoSel. Notas: ${_notasCtrl.text}. '
                       'IA: ${_respuestaIA ?? 'Sin análisis'}'
                       '${_audioPath != null ? ' [Nota de voz adjunta]' : ''}'
                       '${_fotoPath != null ? ' [Evidencia fotográfica adjunta]' : ''}',
      'nivel_riesgo':  _nivelRiesgo ?? 'estable',
      'semanas':       _semanasActuales > 0 ? '$_semanasActuales' : null,
      'fecha':         DateTime.now().toIso8601String(),
    });
    if (mounted) {
      setState(() {
        _guardando = false;
        _audioPath = null;
        _fotoPath  = null;
        _notasCtrl.clear();
      });
      _snack('✅ Atención integral registrada exitosamente');
      await _cargarConsultasPaciente(pacienteId);
      _cargar();
    }
  }

  Future<void> _generarReporte() async {
    if (_pacienteSel == null) {
      _snack('Selecciona un paciente para generar el reporte');
      return;
    }
    final id = _pacienteSel!['id'];
    if (id == null) {
      _snack('Paciente sin identificador válido');
      return;
    }
    _snack('Generando reporte PDF...');
    await PdfService.generarYCompartir(
      context: context,
      pacienteId: id as int,
      pacienteNombre: _pacienteSel!['nombre'] as String? ?? 'Paciente',
    );
  }

  void _verPerfilPartera() {
    if (_parteraSel == null) {
      _snack('Selecciona una partera primero');
      return;
    }
    final p = _parteraSel!;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kMorado.withOpacity(0.15),
                border: Border.all(color: _kMoradoC.withOpacity(0.4), width: 2),
              ),
              child: const Icon(Icons.self_improvement_rounded, color: _kMoradoC, size: 36),
            ),
            const SizedBox(height: 12),
            Text(p['nombre'] as String? ?? '-',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(p['especialidad'] as String? ?? '-',
                style: const TextStyle(color: _kMoradoC, fontSize: 12)),
            const SizedBox(height: 14),
            _filaPerfilDialog(Icons.star_outline_rounded, 'Experiencia',
                '${p['anios_exp'] ?? '-'} años'),
            _filaPerfilDialog(Icons.location_on_outlined, 'Ubicación',
                p['ciudad'] as String? ?? '-'),
            _filaPerfilDialog(Icons.phone_outlined, 'Teléfono',
                p['telefono'] as String? ?? '-'),
            _filaPerfilDialog(Icons.star_rounded, 'Calificación',
                '${p['calificacion'] ?? '-'} / 5.0'),
            _filaPerfilDialog(Icons.circle, 'Disponibilidad',
                (p['disponible'] == 1) ? 'Disponible' : 'No disponible'),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _kMoradoC,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )),
          ]),
        ),
      ),
    );
  }

  Widget _filaPerfilDialog(IconData icono, String label, String valor) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Icon(icono, color: _kTextoH, size: 14),
      const SizedBox(width: 8),
      Text('$label: ', style: const TextStyle(color: _kTextoH, fontSize: 11.5)),
      Expanded(child: Text(valor, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600))),
    ]),
  );

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

  // ── Llamar / WhatsApp partera ────────────────────────────────────────────
  Future<void> _llamar() async {
    final tel = (_parteraSel?['telefono'] as String? ?? '').trim();
    if (tel.isEmpty) { _snack('Sin número de teléfono'); return; }
    final uri = Uri.parse('tel:${tel.replaceAll(RegExp(r'[\s\-\(\)]'), '')}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

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

  String _formatFecha(String? f) {
    if (f == null || f.isEmpty) return '';
    try {
      final dt = DateTime.parse(f);
      const m = ['ene','feb','mar','abr','may','jun',
                  'jul','ago','sep','oct','nov','dic'];
      return '${dt.day} ${m[dt.month-1]} ${dt.year}';
    } catch (_) { return f; }
  }

  List<_Planta> get _plantasFiltradas {
    var lista = List<_Planta>.from(_kPlantas);
    if (_categoriaPlantaSel != 'Todas') {
      lista = lista.where((p) => p.categorias.contains(_categoriaPlantaSel)).toList();
    }
    if (_buscarPlanta.isNotEmpty) {
      final q = _buscarPlanta.toLowerCase();
      lista = lista.where((p) =>
          p.nombre.toLowerCase().contains(q) ||
          p.usoAncestral.toLowerCase().contains(q)).toList();
    }
    return lista;
  }

  // ════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kFondo,
      floatingActionButton: FloatingActionButton(
        backgroundColor: _kMorado,
        tooltip: 'Chat con IA DISPERSALUD',
        onPressed: _mostrarChatIA,
        child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 24),
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
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── PACIENTE + PARTERA (apiladas en móvil) ───────
                          LayoutBuilder(builder: (ctx, constraints) {
                            final ancho = constraints.maxWidth;
                            if (ancho < 600) {
                              return Column(children: [
                                _cardPaciente(),
                                const SizedBox(height: 10),
                                _cardPartera(),
                              ]);
                            }
                            return Row(crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 6, child: _cardPaciente()),
                                const SizedBox(width: 10),
                                Expanded(flex: 5, child: _cardPartera()),
                              ]);
                          }),
                          const SizedBox(height: 12),

                          // ── RIESGO ACTUAL ────────────────────────────────
                          _cardRiesgoActual(),
                          const SizedBox(height: 12),

                          // ── ACCIONES RÁPIDAS ─────────────────────────────
                          _accionesRapidas(),
                          const SizedBox(height: 12),

                          // ── CONTROL GESTACIONAL + EVOLUCIÓN ──────────────
                          LayoutBuilder(builder: (ctx, constraints) {
                            if (constraints.maxWidth < 600) {
                              return Column(children: [
                                _cardControlGestacional(),
                                const SizedBox(height: 12),
                                _cardEvolucion(),
                                const SizedBox(height: 12),
                                _cardBibliotecaPlantas(),
                              ]);
                            }
                            return Row(crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 5, child: _cardControlGestacional()),
                                const SizedBox(width: 10),
                                Expanded(flex: 6, child: Column(children: [
                                  _cardEvolucion(),
                                  const SizedBox(height: 12),
                                  _cardBibliotecaPlantas(),
                                ])),
                              ]);
                          }),
                          const SizedBox(height: 12),

                          // ── RECOMENDACIONES PARTERA ──────────────────────
                          _cardRecomPartera(),
                          const SizedBox(height: 12),

                          // ── PLANTAS NO RECOMENDADAS ──────────────────────
                          _cardPlantasNoRecomendadas(),
                          const SizedBox(height: 12),

                          // ── IA + ALERTAS + HISTORIAL ─────────────────────
                          LayoutBuilder(builder: (ctx, constraints) {
                            if (constraints.maxWidth < 600) {
                              return Column(children: [
                                _cardIA(),
                                const SizedBox(height: 12),
                                _cardSignosAlarma(),
                                const SizedBox(height: 12),
                                _cardHistorial(),
                              ]);
                            }
                            return Row(crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 5, child: _cardIA()),
                                const SizedBox(width: 10),
                                Expanded(flex: 6, child: Column(children: [
                                  _cardSignosAlarma(),
                                  const SizedBox(height: 12),
                                  _cardHistorial(),
                                ])),
                              ]);
                          }),
                          const SizedBox(height: 16),

                          // ── BOTÓN REGISTRAR ATENCIÓN ─────────────────────
                          _botonRegistrarAtencion(),
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
    padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: _kBorder)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: _kTexto, size: 22),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.eco_rounded, color: _kVerdeBI, size: 20),
        const SizedBox(width: 8),
        const Expanded(
          child: Text('Salud Integral Materna y Ancestral',
              maxLines: 2,
              style: TextStyle(color: Colors.white, fontSize: 15,
                  fontWeight: FontWeight.bold, height: 1.2)),
        ),
        const SizedBox(width: 6),
        Stack(children: [
          const Icon(Icons.notifications_none_rounded, color: _kTexto, size: 22),
          if (_kSignosAlarma.isNotEmpty)
            Positioned(right: 0, top: 0, child: Container(
              width: 14, height: 14,
              decoration: const BoxDecoration(color: _kRojo, shape: BoxShape.circle),
              child: Center(child: Text('${_kSignosAlarma.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 8,
                      fontWeight: FontWeight.bold))),
            )),
        ]),
        const SizedBox(width: 6),
        const Icon(Icons.more_vert_rounded, color: _kTexto, size: 20),
      ]),
      const SizedBox(height: 6),
      Padding(
        padding: const EdgeInsets.only(left: 42),
        child: Row(children: [
          const Expanded(
            child: Text('Atención integral con saberes ancestrales e IA DISPERSALUD',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: _kVerdeBI, fontSize: 10)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: (_online ? _kVerdeBI : _kTextoH).withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: (_online ? _kVerdeBI : _kTextoH).withOpacity(0.4)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(
                  shape: BoxShape.circle, color: _online ? _kVerdeBI : _kTextoH)),
              const SizedBox(width: 5),
              Text(_online ? 'En línea' : 'Sin conexión',
                  style: TextStyle(color: _online ? _kVerdeBI : _kTextoH,
                      fontSize: 9.5, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      ),
    ]),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // CARD PACIENTE
  // ─────────────────────────────────────────────────────────────────────────
  Widget _cardPaciente() {
    final nombre = _pacienteSel?['nombre'] as String? ?? 'Selecciona paciente';
    final edad   = _pacienteSel?['edad'] as String? ?? '-';
    final vereda = _pacienteSel?['vereda'] as String? ?? '-';
    final eps    = _pacienteSel?['eps'] as String? ?? '-';
    final tel    = _pacienteSel?['telefono'] as String? ?? '-';

    return GestureDetector(
      onTap: _seleccionarPaciente,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _kCard, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('PACIENTE (GESTANTE)',
                style: TextStyle(color: _kTextoS, fontSize: 9,
                    fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ]),
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kVerde.withOpacity(0.15),
                border: Border.all(color: _kVerdeBI.withOpacity(0.4), width: 1.5),
              ),
              child: Icon(Icons.pregnant_woman_rounded, color: _kVerdeBI, size: 28),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(nombre, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 15,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                _filaIcono(Icons.cake_outlined, '$edad años'),
                _filaIcono(Icons.location_on_outlined, vereda, maxLines: 1),
                _filaIcono(Icons.local_hospital_outlined, eps, maxLines: 1),
                _filaIcono(Icons.phone_outlined, tel),
              ]),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _filaIcono(IconData icono, String texto, {int maxLines = 1}) => Padding(
    padding: const EdgeInsets.only(top: 2),
    child: Row(children: [
      Icon(icono, color: _kTextoH, size: 11),
      const SizedBox(width: 4),
      Expanded(child: Text(texto, maxLines: maxLines, overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: _kTextoS, fontSize: 10))),
    ]),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // CARD PARTERA
  // ─────────────────────────────────────────────────────────────────────────
  Widget _cardPartera() {
    final nombre = _parteraSel?['nombre'] as String? ?? 'Selecciona partera/sabedora';
    final exp    = _parteraSel?['anios_exp']?.toString() ?? '-';
    final ciudad = _parteraSel?['ciudad'] as String? ?? '-';
    final tel    = _parteraSel?['telefono'] as String? ?? '-';

    return GestureDetector(
      onTap: _seleccionarPartera,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _kCard, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('PARTERA / SABEDORA',
              style: TextStyle(color: _kMoradoC, fontSize: 9,
                  fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kMorado.withOpacity(0.15),
                border: Border.all(color: _kMoradoC.withOpacity(0.4), width: 1.5),
              ),
              child: Icon(Icons.self_improvement_rounded, color: _kMoradoC, size: 28),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(nombre, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 15,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                _filaIcono(Icons.star_outline_rounded, '$exp años de experiencia'),
                _filaIcono(Icons.location_on_outlined, ciudad, maxLines: 1),
                _filaIcono(Icons.phone_outlined, tel),
              ]),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _miniBoton(Icons.call_rounded, 'Llamar', _kVerdeBI, _llamar)),
            const SizedBox(width: 6),
            Expanded(child: _miniBoton(Icons.chat_bubble_outline_rounded, 'WhatsApp', _kVerdeBI, _whatsApp)),
          ]),
          const SizedBox(height: 6),
          SizedBox(width: double.infinity, child: _miniBoton(
              Icons.person_outline_rounded, 'Ver perfil', _kMoradoC,
              _verPerfilPartera)),
        ]),
      ),
    );
  }

  Widget _miniBoton(IconData icono, String texto, Color color, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icono, color: color, size: 13),
          const SizedBox(width: 4),
          Flexible(child: Text(texto, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w600))),
        ]),
      ),
    );

  // ─────────────────────────────────────────────────────────────────────────
  // RIESGO ACTUAL
  // ─────────────────────────────────────────────────────────────────────────
  Widget _cardRiesgoActual() {
    final color = _colorNivel(_nivelRiesgo ?? 'BAJO');
    final nivelTexto = _nivelRiesgo ?? 'BAJO RIESGO';
    final subtitulo = switch (_nivelRiesgo) {
      'URGENTE' => 'Requiere atención inmediata',
      'ALTO'    => 'Requiere seguimiento cercano',
      'MODERADO'=> 'Vigilar evolución de la gestante',
      _         => 'Estado de la gestante estable',
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCard, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(Icons.shield_outlined, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('RIESGO ACTUAL', style: TextStyle(color: _kTextoH, fontSize: 9,
                fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            Text(nivelTexto.contains('RIESGO') ? nivelTexto : '$nivelTexto RIESGO',
                style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
            Text(subtitulo,
                style: const TextStyle(color: _kTextoS, fontSize: 10)),
          ]),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          const Text('Próxima visita programada',
              style: TextStyle(color: _kTextoH, fontSize: 9)),
          Row(children: [
            const Icon(Icons.event_outlined, color: _kTextoS, size: 12),
            const SizedBox(width: 4),
            Text(_formatFecha(DateTime.now().add(const Duration(days: 7)).toIso8601String()),
                style: const TextStyle(color: _kTextoS, fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
          Container(
            margin: const EdgeInsets.only(top: 3),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: _kMorado.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
            child: const Text('En 7 días',
                style: TextStyle(color: _kMoradoC, fontSize: 9, fontWeight: FontWeight.w600)),
          ),
        ]),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ACCIONES RÁPIDAS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _accionesRapidas() {
    final acciones = [
      (Icons.monitor_heart_outlined, 'Registrar\ncontrol', _kVerdeBI, _mostrarFormularioConsulta),
      (Icons.home_outlined, 'Visita\ndomiciliaria', _kAzul, _visitaDomiciliaria),
      (Icons.eco_outlined, 'Nueva\nrecomendación', _kVerdeBI, () => _snack('Selecciona recomendaciones abajo')),
      (Icons.smart_toy_outlined, 'Análisis\nIA', _kMoradoC, _analizarIA),
      (Icons.description_outlined, 'Generar\nreporte', _kTextoS, _generarReporte),
    ];
    return SizedBox(
      height: 64,
      child: Row(children: acciones.map((a) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: GestureDetector(
            onTap: a.$4,
            child: Container(
              decoration: BoxDecoration(
                color: _kCard, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kBorder),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(a.$1, color: a.$3, size: 18),
                const SizedBox(height: 3),
                Text(a.$2, textAlign: TextAlign.center, maxLines: 2,
                    style: TextStyle(color: _kTextoS, fontSize: 8.5, height: 1.1)),
              ]),
            ),
          ),
        ),
      )).toList()),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CONTROL GESTACIONAL ACTUAL
  // ─────────────────────────────────────────────────────────────────────────
  Widget _cardControlGestacional() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCard, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('CONTROL GESTACIONAL ACTUAL',
            style: TextStyle(color: _kVerdeBI, fontSize: 10,
                fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _statBox(Icons.monitor_weight_outlined, 'Peso', '68 kg', 'Normal', _kVerdeBI)),
          const SizedBox(width: 8),
          Expanded(child: _statBox(Icons.favorite_outline_rounded, 'T. Arterial', '120/80', 'mmHg', _kAzul)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _statBox(Icons.height_outlined, 'Altura uterina', '30 cm', 'Normal', _kVerdeBI)),
          const SizedBox(width: 8),
          Expanded(child: _statBox(Icons.directions_run_rounded, 'Mov. fetales', 'Normales', 'Activos', _kVerdeBI)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _statBox(Icons.favorite_rounded, 'Latidos fetales', '145 lpm', 'Normal', _kRosa)),
          const SizedBox(width: 8),
          Expanded(child: _statBox(Icons.water_drop_outlined, 'Edema', 'No', 'Sin edema', _kVerdeBI)),
        ]),
        const SizedBox(height: 10),
        const Text('Observaciones de la partera',
            style: TextStyle(color: _kTextoH, fontSize: 9, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          _historial.isNotEmpty
              ? (_historial.first['observaciones'] as String? ?? 'Gestante estable, refiere buena alimentación y sueño.')
              : 'Gestante estable, refiere buena alimentación y sueño.',
          style: const TextStyle(color: _kTextoS, fontSize: 10.5, height: 1.4),
        ),
      ]),
    );
  }

  Widget _statBox(IconData icono, String label, String valor, String sub, Color color) => Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
    decoration: BoxDecoration(
      color: _kCardAlt, borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _kBorder),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icono, color: color, size: 14),
      const SizedBox(height: 3),
      Text(label, style: const TextStyle(color: _kTextoH, fontSize: 8)),
      Text(valor, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      Text(sub, style: TextStyle(color: color, fontSize: 8)),
    ]),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // EVOLUCIÓN DEL EMBARAZO
  // ─────────────────────────────────────────────────────────────────────────
  Widget _cardEvolucion() {
    final realizados = _kSemanasControl.where((s) => s <= _semanasActuales).length;
    final sinDatos = _pacienteSel == null;
    final sinSemanas = _pacienteSel != null && _semanasActuales == 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCard, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('EVOLUCIÓN DEL EMBARAZO',
            style: TextStyle(color: _kVerdeBI, fontSize: 10,
                fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 12),
        if (sinDatos)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Selecciona una paciente para ver su evolución',
                style: TextStyle(color: _kTextoH, fontSize: 10.5)),
          )
        else if (sinSemanas)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Aún no hay controles con semanas de gestación registradas',
                style: TextStyle(color: _kTextoH, fontSize: 10.5)),
          )
        else ...[
          SizedBox(
            height: 40,
            child: Row(
              children: List.generate(_kSemanasControl.length, (i) {
                final sem = _kSemanasControl[i];
                final hecho = sem <= _semanasActuales;
                return Expanded(child: Row(children: [
                  if (i > 0) Expanded(child: Container(height: 1.5,
                      color: hecho ? _kVerdeBI.withOpacity(0.5) : _kBorder)),
                  Container(
                    width: 18, height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hecho ? _kVerdeBI : Colors.transparent,
                      border: Border.all(color: hecho ? _kVerdeBI : _kBorder, width: 1.5),
                    ),
                    child: hecho
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 12)
                        : null,
                  ),
                ]));
              }),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: _kSemanasControl.map((s) => Expanded(child: Text(
              '$s\nsem', textAlign: TextAlign.center,
              style: const TextStyle(color: _kTextoH, fontSize: 7.5, height: 1.2)))).toList(),
          ),
          const SizedBox(height: 8),
          Text('$realizados controles realizados · $_semanasActuales semanas actuales',
              style: const TextStyle(color: _kVerdeBI, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BIBLIOTECA DE PLANTAS MEDICINALES
  // ─────────────────────────────────────────────────────────────────────────
  Widget _cardBibliotecaPlantas() {
    final plantas = _plantasFiltradas;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCard, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('BIBLIOTECA DE PLANTAS MEDICINALES',
            style: TextStyle(color: _kVerdeBI, fontSize: 10,
                fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 10),
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _kCardAlt, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kBorder),
          ),
          child: Row(children: [
            const Icon(Icons.search_rounded, color: _kTextoH, size: 16),
            const SizedBox(width: 8),
            Expanded(child: TextField(
              controller: _buscarPlantaCtrl,
              onChanged: (v) => setState(() => _buscarPlanta = v),
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: const InputDecoration(
                hintText: 'Buscar planta, malestar o síntoma...',
                hintStyle: TextStyle(color: _kTextoH, fontSize: 11),
                border: InputBorder.none, isDense: true,
              ),
            )),
            const Icon(Icons.tune_rounded, color: _kTextoH, size: 16),
          ]),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 30,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _kCategoriasPlantas.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final cat = _kCategoriasPlantas[i];
              final sel = cat == _categoriaPlantaSel;
              return GestureDetector(
                onTap: () => setState(() => _categoriaPlantaSel = cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? _kMorado : _kCardAlt,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: sel ? _kMorado : _kBorder),
                  ),
                  child: Text(cat, style: TextStyle(
                      color: sel ? Colors.white : _kTextoS, fontSize: 10.5,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        if (plantas.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: Text('No se encontraron plantas',
                style: TextStyle(color: _kTextoH, fontSize: 11))),
          )
        else
          SizedBox(
            height: 195,
            child: PageView.builder(
              itemCount: plantas.length,
              controller: PageController(viewportFraction: 1),
              itemBuilder: (_, i) => _tarjetaPlanta(plantas[i]),
            ),
          ),
        const SizedBox(height: 8),
        Center(
          child: Row(mainAxisSize: MainAxisSize.min,
            children: List.generate(plantas.length.clamp(0, 6), (i) => Container(
              width: 6, height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == 0 ? _kVerdeBI : _kBorder,
              ),
            )),
          ),
        ),
      ]),
    );
  }

  Widget _tarjetaPlanta(_Planta p) => Container(
    decoration: BoxDecoration(
      color: _kCardAlt, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _kBorder),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 92, height: 195,
        decoration: BoxDecoration(
          color: p.color.withOpacity(0.18),
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
        ),
        child: Center(child: Icon(Icons.local_florist_rounded, color: p.color, size: 44)),
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.nombre, style: const TextStyle(color: _kVerdeBI, fontSize: 13.5,
                fontWeight: FontWeight.bold)),
            Text(p.nombreCientifico, style: const TextStyle(color: _kTextoH, fontSize: 9,
                fontStyle: FontStyle.italic)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: _kMorado.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
              child: Text(p.categorias.join(', '),
                  style: const TextStyle(color: _kMoradoC, fontSize: 8.5, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 6),
            _filaPlanta(Icons.local_cafe_outlined, 'Preparación', p.preparacion),
            _filaPlanta(Icons.science_outlined, 'Dosis', p.dosis),
            _filaPlanta(Icons.auto_awesome_outlined, 'Uso ancestral', p.usoAncestral, maxLines: 2),
            _filaPlanta(Icons.warning_amber_rounded, 'Contraindicaciones', p.contraindicaciones,
                maxLines: 2, color: _kNaranja),
          ]),
        ),
      ),
    ]),
  );

  Widget _filaPlanta(IconData icono, String label, String valor,
      {int maxLines = 1, Color color = _kTextoS}) => Padding(
    padding: const EdgeInsets.only(top: 3),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icono, color: color, size: 11),
      const SizedBox(width: 4),
      Expanded(child: RichText(maxLines: maxLines, overflow: TextOverflow.ellipsis,
        text: TextSpan(children: [
          TextSpan(text: '$label: ', style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.w700)),
          TextSpan(text: valor, style: const TextStyle(color: _kTextoS, fontSize: 9.5)),
        ]),
      )),
    ]),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // RECOMENDACIONES DE LA PARTERA
  // ─────────────────────────────────────────────────────────────────────────
  Widget _cardRecomPartera() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCard, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kRosa.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('RECOMENDACIONES DE LA PARTERA',
            style: TextStyle(color: _kRosa, fontSize: 10,
                fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 10),
        ..._kRecomPartera.map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Row(children: [
            Container(width: 18, height: 18,
                decoration: const BoxDecoration(color: _kRosa, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 12)),
            const SizedBox(width: 8),
            Expanded(child: Text(r, style: const TextStyle(color: _kTextoS, fontSize: 11.5))),
          ]),
        )),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: _miniBoton(
              _grabando ? Icons.stop_circle_rounded : Icons.mic_none_rounded,
              _grabando ? 'Detener' : 'Grabar audio',
              _grabando ? _kRojo : _kRosa,
              _toggleGrabacion)),
          const SizedBox(width: 8),
          Expanded(child: _miniBoton(Icons.camera_alt_outlined, 'Tomar foto', _kRosa,
              _tomarFoto)),
        ]),
        if (_audioPath != null) ...[
          const SizedBox(height: 10),
          _reproductorAudio(),
        ],
        if (_fotoPath != null) ...[
          const SizedBox(height: 10),
          _vistaFotoEvidencia(),
        ],
      ]),
    );
  }

  // ── AUDIO ────────────────────────────────────────────────────────────────
  Future<void> _toggleGrabacion() async {
    if (_grabando) {
      final path = await _recorder.stop();
      setState(() { _grabando = false; _audioPath = path; });
      if (path != null) _snack('🎙️ Audio guardado correctamente');
      return;
    }
    final permiso = await _recorder.hasPermission();
    if (!permiso) {
      _snack('Permiso de micrófono denegado');
      return;
    }
    final dir = kIsWeb ? null : await getApplicationDocumentsDirectory();
    final filePath = kIsWeb
        ? 'nota_${DateTime.now().millisecondsSinceEpoch}.m4a'
        : '${dir!.path}/nota_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(), path: filePath);
    setState(() { _grabando = true; _audioPath = null; });
  }

  Future<void> _toggleReproduccion() async {
    if (_audioPath == null) return;
    if (_reproduciendo) {
      await _audioPlayer.pause();
      setState(() => _reproduciendo = false);
    } else {
      await _audioPlayer.play(DeviceFileSource(_audioPath!));
      setState(() => _reproduciendo = true);
    }
  }

  Widget _reproductorAudio() {
    final total = _audioDur.inMilliseconds == 0 ? 1 : _audioDur.inMilliseconds;
    final progreso = (_audioPos.inMilliseconds / total).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _kCardAlt, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Row(children: [
        GestureDetector(
          onTap: _toggleReproduccion,
          child: Icon(_reproduciendo ? Icons.pause_circle_filled_rounded
              : Icons.play_circle_fill_rounded, color: _kRosa, size: 28),
        ),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: progreso, minHeight: 4,
                backgroundColor: _kBorder, color: _kRosa)),
          const SizedBox(height: 3),
          Text('${_fmtDur(_audioPos)} / ${_fmtDur(_audioDur)}',
              style: const TextStyle(color: _kTextoH, fontSize: 9)),
        ])),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => setState(() { _audioPath = null; _reproduciendo = false; }),
          child: const Icon(Icons.delete_outline_rounded, color: _kTextoH, size: 18),
        ),
      ]),
    );
  }

  String _fmtDur(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── CÁMARA ───────────────────────────────────────────────────────────────
  Future<void> _tomarFoto() async {
    try {
      final XFile? foto = await _picker.pickImage(
          source: ImageSource.camera, imageQuality: 70);
      if (foto != null) {
        setState(() => _fotoPath = foto.path);
        _snack('📷 Foto capturada correctamente');
      }
    } catch (e) {
      _snack('No se pudo acceder a la cámara: $e');
    }
  }

  Widget _vistaFotoEvidencia() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(children: [
          kIsWeb
              ? Image.network(_fotoPath!, height: 140, width: double.infinity, fit: BoxFit.cover)
              : Image.file(File(_fotoPath!), height: 140, width: double.infinity, fit: BoxFit.cover),
          Positioned(right: 6, top: 6, child: GestureDetector(
            onTap: () => setState(() => _fotoPath = null),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
            ),
          )),
        ]),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PLANTAS NO RECOMENDADAS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _cardPlantasNoRecomendadas() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCard, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kRojo.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.warning_amber_rounded, color: _kRojo, size: 14),
          const SizedBox(width: 6),
          Text('PLANTAS NO RECOMENDADAS EN EMBARAZO',
              style: TextStyle(color: _kRojo, fontSize: 10,
                  fontWeight: FontWeight.bold, letterSpacing: 0.3)),
        ]),
        const SizedBox(height: 10),
        Row(children: _kPlantasNoRecomendadas.map((p) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                    color: _kRojo.withOpacity(0.12), shape: BoxShape.circle,
                    border: Border.all(color: _kRojo.withOpacity(0.3))),
                child: Icon(p.$3, color: _kRojo, size: 22),
              ),
              const SizedBox(height: 5),
              Text(p.$1, textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(p.$2, textAlign: TextAlign.center, maxLines: 2,
                  style: const TextStyle(color: _kTextoH, fontSize: 8, height: 1.2)),
            ]),
          ),
        )).toList()),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // IA DISPERSALUD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _cardIA() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCard, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kMorado.withOpacity(0.35)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 32, height: 32,
              decoration: BoxDecoration(color: _kMorado.withOpacity(0.18), shape: BoxShape.circle),
              child: const Icon(Icons.smart_toy_rounded, color: _kMoradoC, size: 18)),
          const SizedBox(width: 8),
          Text('IA DISPERSALUD', style: TextStyle(color: _kMoradoC, fontSize: 11,
              fontWeight: FontWeight.bold, letterSpacing: 0.3)),
        ]),
        const SizedBox(height: 10),
        const Text('Análisis integral de la atención',
            style: TextStyle(color: _kTextoS, fontSize: 10.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        if (_analizando)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(color: _kMoradoC, strokeWidth: 2))),
          )
        else if (_respuestaIA != null)
          Text(_respuestaIA!, style: const TextStyle(color: _kTextoS, fontSize: 10.5, height: 1.5))
        else
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _itemIA(_semanasActuales > 0
                ? 'Embarazo: $_semanasActuales semanas'
                : 'Embarazo: semanas no registradas aún'),
            _itemIA('Signos vitales: Normales'),
            _itemIA('Riesgo materno: Bajo'),
            _itemIA('Riesgo fetal: Bajo'),
            _itemIA('Recomendación: Continuar seguimiento y vigilancia de signos de alarma.'),
          ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _miniBoton(Icons.auto_awesome_rounded, 'Ver análisis completo', _kMoradoC, _analizarIA)),
          const SizedBox(width: 8),
          Expanded(child: _miniBoton(Icons.menu_book_outlined, 'Ver guía completa', _kRojo,
              () => _mostrarChatIA())),
        ]),
      ]),
    );
  }

  Widget _itemIA(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('•  ', style: TextStyle(color: _kTextoS, fontSize: 10.5)),
      Expanded(child: Text(t, style: const TextStyle(color: _kTextoS, fontSize: 10.5, height: 1.4))),
    ]),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // SIGNOS DE ALARMA
  // ─────────────────────────────────────────────────────────────────────────
  Widget _cardSignosAlarma() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCard, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kRojo.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.error_outline_rounded, color: _kRojo, size: 14),
          const SizedBox(width: 6),
          Text('ALERTAS', style: TextStyle(color: _kRojo, fontSize: 10,
              fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ]),
        const SizedBox(height: 8),
        ..._kSignosAlarma.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            const Icon(Icons.circle, color: _kRojo, size: 6),
            const SizedBox(width: 8),
            Expanded(child: Text(s, style: const TextStyle(color: _kTextoS, fontSize: 10.5))),
          ]),
        )),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HISTORIAL DE CONSULTAS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _cardHistorial() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCard, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('HISTORIAL DE CONSULTAS', style: TextStyle(color: _kVerdeBI, fontSize: 10,
              fontWeight: FontWeight.bold, letterSpacing: 0.3)),
          GestureDetector(onTap: _cargar,
            child: const Text('Ver todas', style: TextStyle(color: _kTextoH, fontSize: 9))),
        ]),
        const SizedBox(height: 8),
        if (_historial.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Sin consultas registradas aún',
                style: TextStyle(color: _kTextoH, fontSize: 10.5)),
          )
        else
          ..._historial.take(4).map((h) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 3),
                  decoration: const BoxDecoration(color: _kVerdeBI, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_formatFecha(h['fecha'] as String?),
                    style: const TextStyle(color: _kTextoH, fontSize: 9)),
                Text(h['diagnostico'] as String? ?? h['modulo'] as String? ?? '-',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              ])),
            ]),
          )),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BOTÓN REGISTRAR ATENCIÓN
  // ─────────────────────────────────────────────────────────────────────────
  Widget _botonRegistrarAtencion() => SizedBox(
    width: double.infinity, height: 48,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _kVerdeBI, foregroundColor: Colors.white, elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: _guardando ? null : _guardar,
      child: _guardando
          ? const SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.add_circle_outline_rounded, size: 18),
              SizedBox(width: 8),
              Text('Registrar nueva atención integral',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ]),
    ),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // SELECTORES
  // ─────────────────────────────────────────────────────────────────────────
  void _seleccionarPaciente() {
    showModalBottomSheet(
      context: context, backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ListaSeleccion(
        titulo: 'Selecciona paciente',
        items: _pacientes,
        labelBuilder: (p) => p['nombre'] as String? ?? '-',
        subBuilder: (p) => '${p['edad'] ?? '-'} años · ${p['vereda']?.toString().isNotEmpty == true ? p['vereda'] : (p['municipio'] ?? '-')}',
        onSelect: (p) {
          setState(() => _pacienteSel = p);
          _cargarConsultasPaciente(p['id'] as int);
        },
      ),
    );
  }

  Future<void> _cargarConsultasPaciente(int pacienteId) async {
    final consultas = await DatabaseHelper.instance.consultasPorPaciente(pacienteId);
    int semanas = 0;
    for (final c in consultas) {
      final s = int.tryParse((c['semanas'] as String? ?? '').trim());
      if (s != null && s > semanas) semanas = s;
    }
    if (mounted) setState(() {
      _consultasPaciente = consultas;
      _semanasActuales = semanas;
      _historial = consultas.isNotEmpty ? consultas : _historial;
    });
  }

  void _seleccionarPartera() {
    showModalBottomSheet(
      context: context, backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ListaSeleccion(
        titulo: 'Selecciona partera/sabedora',
        items: _parteras,
        labelBuilder: (p) => p['nombre'] as String? ?? '-',
        subBuilder: (p) => '${p['especialidad'] ?? '-'} · ${p['ciudad'] ?? '-'}',
        onSelect: (p) => setState(() => _parteraSel = p),
      ),
    );
  }

  void _mostrarFormularioConsulta() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 16, right: 16, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: StatefulBuilder(builder: (ctx2, setLocal) => SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Registrar control', style: TextStyle(color: Colors.white,
                fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            const Text('Motivo de consulta', style: TextStyle(color: _kTextoS, fontSize: 11)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: _kMotivos.map((m) {
              final sel = m == _motivoSel;
              return GestureDetector(
                onTap: () => setLocal(() => _motivoSel = m),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? _kVerdeBI : _kCardAlt,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: sel ? _kVerdeBI : _kBorder),
                  ),
                  child: Text(m, style: TextStyle(
                      color: sel ? Colors.white : _kTextoS, fontSize: 11)),
                ),
              );
            }).toList()),
            const SizedBox(height: 14),
            const Text('Desequilibrio (saberes ancestrales)', style: TextStyle(color: _kTextoS, fontSize: 11)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: _kDesequilibrios.map((d) {
              final sel = d == _desequilSel;
              return GestureDetector(
                onTap: () => setLocal(() => _desequilSel = d),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? _kMorado : _kCardAlt,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: sel ? _kMorado : _kBorder),
                  ),
                  child: Text(d, style: TextStyle(
                      color: sel ? Colors.white : _kTextoS, fontSize: 11)),
                ),
              );
            }).toList()),
            const SizedBox(height: 14),
            const Text('Notas adicionales', style: TextStyle(color: _kTextoS, fontSize: 11)),
            const SizedBox(height: 6),
            TextField(
              controller: _notasCtrl, maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Observaciones de la consulta...',
                hintStyle: const TextStyle(color: _kTextoH, fontSize: 11),
                filled: true, fillColor: _kCardAlt,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: _kBorder)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _kVerdeBI,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () { Navigator.pop(ctx); _guardar(); },
                child: const Text('Guardar control', style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 8),
          ]),
        )),
      ),
    );
  }

  void _mostrarChatIA() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx2, setLocal) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.7,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                const Icon(Icons.smart_toy_rounded, color: _kMoradoC),
                const SizedBox(width: 8),
                const Text('Chat con IA DISPERSALUD', style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ]),
            ),
            const Divider(color: _kBorder, height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _chatIA.length,
                itemBuilder: (_, i) {
                  final m = _chatIA[i];
                  final esIA = m['rol'] == 'ia';
                  return Align(
                    alignment: esIA ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(10),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(ctx).size.width * 0.75),
                      decoration: BoxDecoration(
                        color: esIA ? _kCardAlt : _kVerdeBI.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(m['texto'] ?? '', style: const TextStyle(
                          color: _kTextoS, fontSize: 12.5, height: 1.4)),
                    ),
                  );
                },
              ),
            ),
            if (_enviandoIA) const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(color: _kMoradoC, strokeWidth: 2)),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Expanded(child: TextField(
                  controller: _chatCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Escribe tu pregunta...',
                    hintStyle: const TextStyle(color: _kTextoH, fontSize: 12),
                    filled: true, fillColor: _kCardAlt,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none),
                  ),
                )),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async { await _enviarChatIA(); setLocal(() {}); },
                  child: Container(width: 40, height: 40,
                      decoration: const BoxDecoration(color: _kMoradoC, shape: BoxShape.circle),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 18)),
                ),
              ]),
            ),
          ]),
        ),
      )),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET LISTA DE SELECCIÓN (paciente / partera)
// ─────────────────────────────────────────────────────────────────────────────
class _ListaSeleccion extends StatelessWidget {
  final String titulo;
  final List<Map<String, dynamic>> items;
  final String Function(Map<String, dynamic>) labelBuilder;
  final String Function(Map<String, dynamic>) subBuilder;
  final void Function(Map<String, dynamic>) onSelect;

  const _ListaSeleccion({
    required this.titulo, required this.items,
    required this.labelBuilder, required this.subBuilder, required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 420,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(titulo, style: const TextStyle(color: Colors.white,
              fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const Divider(color: _kBorder, height: 1),
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('No hay registros disponibles',
                  style: TextStyle(color: _kTextoH, fontSize: 12)))
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return ListTile(
                      leading: Container(width: 40, height: 40,
                          decoration: BoxDecoration(
                              color: _kVerdeBI.withOpacity(0.15), shape: BoxShape.circle),
                          child: const Icon(Icons.person_outline_rounded, color: _kVerdeBI)),
                      title: Text(labelBuilder(item), style: const TextStyle(color: Colors.white, fontSize: 14)),
                      subtitle: Text(subBuilder(item), style: const TextStyle(color: _kTextoH, fontSize: 11)),
                      onTap: () { onSelect(item); Navigator.pop(context); },
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

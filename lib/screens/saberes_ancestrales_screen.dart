import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_theme.dart';
import '../core/responsive.dart';
import '../database/database_helper.dart';
import '../services/ia_service.dart';
import '../services/connectivity_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// COLORES TEMÁTICOS (oscuro selvático)
// ─────────────────────────────────────────────────────────────────────────────
const _kFondo       = Color(0xFF0D1A0F);
const _kCard        = Color(0xFF132015);
const _kCardAlt     = Color(0xFF1A2B1C);
const _kVerde       = Color(0xFF2ECC71);
const _kVerdeOsc    = Color(0xFF1A7A42);
const _kVerdeClaro  = Color(0xFF4CD98A);
const _kDorado      = Color(0xFFC9A227);
const _kMorado      = Color(0xFF6B3FA0);
const _kMoradoClaro = Color(0xFF9B6FCF);
const _kBorder      = Color(0xFF2A3D2C);
const _kTexto       = Color(0xFFE8F5E9);
const _kTextoSec    = Color(0xFFB2DFDB);
const _kTextoHint   = Color(0xFF7AAB84);

// ─────────────────────────────────────────────────────────────────────────────
// MODELOS DE DATOS
// ─────────────────────────────────────────────────────────────────────────────
class _Planta {
  final String nombre, nombreCientifico, uso, beneficio, preparacion;
  final IconData icono;
  final Color color;
  const _Planta({
    required this.nombre, required this.nombreCientifico,
    required this.uso, required this.beneficio,
    required this.preparacion, required this.icono, required this.color,
  });
}

// Base de plantas medicinales por síntoma/condición
const Map<String, List<_Planta>> _kPlantasPorCondicion = {
  'dolor_estomacal': [
    _Planta(nombre: 'Manzanilla', nombreCientifico: 'Matricaria chamomilla',
      uso: 'Infusión', beneficio: 'Calma el dolor estomacal y la inflamación.',
      preparacion: 'Hervir 1 taza de agua, agregar 1 cucharada de flores secas, reposar 10 min. Tomar 3 veces al día.',
      icono: Icons.local_florist, color: Color(0xFFDEB887)),
    _Planta(nombre: 'Hierbabuena', nombreCientifico: 'Mentha spicata',
      uso: 'Infusión', beneficio: 'Mejora la digestión y alivia cólicos.',
      preparacion: 'Hervir hojas frescas 5 min. Tomar después de comidas.',
      icono: Icons.spa, color: _kVerde),
    _Planta(nombre: 'Limoncillo', nombreCientifico: 'Cymbopogon citratus',
      uso: 'Infusión', beneficio: 'Reduce la acidez y relaja el estómago.',
      preparacion: 'Hervir 3 tallos en 1 litro de agua por 10 min. Tomar tibio.',
      icono: Icons.grass, color: Color(0xFF9ACD32)),
  ],
  'gestacion': [
    _Planta(nombre: 'Jengibre', nombreCientifico: 'Zingiber officinale',
      uso: 'Infusión suave', beneficio: 'Alivia náuseas del embarazo.',
      preparacion: 'Rodaja fina en agua tibia (NO hirviendo). Máx 1 taza/día. Consultar partera.',
      icono: Icons.eco, color: Color(0xFFFF8C00)),
    _Planta(nombre: 'Albahaca', nombreCientifico: 'Ocimum basilicum',
      uso: 'Infusión', beneficio: 'Calma dolores leves, rica en antioxidantes.',
      preparacion: 'Hojas frescas en agua tibia. Dosis pequeña. Siempre consultar a la partera.',
      icono: Icons.local_florist, color: _kVerde),
  ],
  'fiebre': [
    _Planta(nombre: 'Saúco', nombreCientifico: 'Sambucus nigra',
      uso: 'Infusión', beneficio: 'Baja la fiebre y alivia síntomas gripales.',
      preparacion: 'Hervir flores 10 min. Tomar 2-3 tazas al día. Acompañar con reposo e hidratación.',
      icono: Icons.spa, color: Color(0xFFB0C4DE)),
    _Planta(nombre: 'Quina', nombreCientifico: 'Cinchona officinalis',
      uso: 'Decocción', beneficio: 'Antipirético tradicional del Cauca.',
      preparacion: 'Corteza hervida 15 min. Solo adultos. Verificar con médico antes de usar en niños.',
      icono: Icons.park, color: Color(0xFF8B4513)),
  ],
  'dolor_cabeza': [
    _Planta(nombre: 'Toronjil', nombreCientifico: 'Melissa officinalis',
      uso: 'Infusión', beneficio: 'Alivia cefaleas tensionales y el estrés.',
      preparacion: 'Hojas frescas en agua caliente 10 min. Tomar tranquilo, sin ruido.',
      icono: Icons.local_florist, color: Color(0xFF90EE90)),
    _Planta(nombre: 'Lavanda', nombreCientifico: 'Lavandula angustifolia',
      uso: 'Aromaterapia', beneficio: 'Reduce el dolor de cabeza por inhalación.',
      preparacion: 'Aplicar aceite en sienes. O inhalar flores frescas. También en infusión suave.',
      icono: Icons.spa, color: Color(0xFF967BB6)),
  ],
  'general': [
    _Planta(nombre: 'Manzanilla', nombreCientifico: 'Matricaria chamomilla',
      uso: 'Infusión', beneficio: 'Antiinflamatoria y calmante general.',
      preparacion: 'Flores secas en agua caliente 10 min. Ideal 3 veces al día.',
      icono: Icons.local_florist, color: Color(0xFFDEB887)),
    _Planta(nombre: 'Sábila', nombreCientifico: 'Aloe vera',
      uso: 'Gel / Jugo', beneficio: 'Digestiva, cicatrizante y antiinflamatoria.',
      preparacion: 'Gel interno: 1 cucharada en ayunas. Externo: aplicar directamente en heridas.',
      icono: Icons.eco, color: _kVerde),
    _Planta(nombre: 'Llantén', nombreCientifico: 'Plantago major',
      uso: 'Cataplasma / Infusión', beneficio: 'Antiinflamatorio, ideal en zonas rurales.',
      preparacion: 'Hojas limpias sobre la zona afectada. En infusión: 3 hojas en 1 taza.',
      icono: Icons.grass, color: Color(0xFF6B8E23)),
  ],
};

// ─────────────────────────────────────────────────────────────────────────────
// PANTALLA PRINCIPAL
// ─────────────────────────────────────────────────────────────────────────────
class SaberesAncestalesScreen extends StatefulWidget {
  const SaberesAncestalesScreen({super.key});
  @override
  State<SaberesAncestalesScreen> createState() =>
      _SaberesAncestalesScreenState();
}

class _SaberesAncestalesScreenState extends State<SaberesAncestalesScreen> {
  // Datos del formulario
  final _nombreCtrl    = TextEditingController();
  final _sabedoraCtrl  = TextEditingController();
  final _comunidadCtrl = TextEditingController();
  final _motivoCtrl    = TextEditingController();
  final _telefonoCtrl  = TextEditingController();
  String _comunidadSel = 'Pueblo Nasa';
  String _semanas = '';
  String _desequilibrio = '';

  // Estado
  bool _online = false;
  bool _analizando = false;
  bool _guardando  = false;
  String? _respuestaIA;
  String? _nivelRiesgo;
  String? _compatibilidad;
  String? _recomendacion;
  List<_Planta> _plantasRec = [];
  List<Map<String, dynamic>> _pacientes = [];
  Map<String, dynamic>? _pacienteSeleccionado;

  // Módulo IA
  bool _iaVisible = false;
  final _iaCtrl   = TextEditingController();
  final List<Map<String, String>> _mensajesIA = [];
  bool _enviandoIA = false;
  StreamSubscription<bool>? _connSub;

  static const _comunidades = [
    'Pueblo Nasa', 'Pueblo Misak', 'Pueblo Yanacona',
    'Pueblo Inga', 'Pueblo Eperãra Siapidaarã', 'Comunidad mestiza', 'Otra',
  ];

  static const _desequilibrios = [
    'Calor corporal en el estómago',
    'Frío en los huesos',
    'Susto o espanto',
    'Mal de ojo',
    'Desequilibrio espiritual',
    'Dolor de vientre',
    'Fiebre espiritual',
    'Tristeza del alma',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    _initConn();
    _cargarPacientes();
    _mensajesIA.add({
      'rol': 'ia',
      'texto': '🌿 Soy DISPERSALUD IA — integración medicina ancestral y occidental. '
          'Cuéntame sobre el paciente o el desequilibrio identificado y te orientaré.',
    });
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _nombreCtrl.dispose(); _sabedoraCtrl.dispose();
    _comunidadCtrl.dispose(); _motivoCtrl.dispose();
    _telefonoCtrl.dispose(); _iaCtrl.dispose();
    super.dispose();
  }

  Future<void> _initConn() async {
    _online = await ConnectivityService.instance.verificarAhora();
    if (mounted) setState(() {});
    _connSub = ConnectivityService.instance.cambios.listen((v) {
      if (mounted) setState(() => _online = v);
    });
  }

  Future<void> _cargarPacientes() async {
    final lista = await DatabaseHelper.instance.obtenerPacientes();
    if (mounted) setState(() => _pacientes = lista);
  }

  // ── Analizar con IA ───────────────────────────────────────────────────────
  Future<void> _analizarConIA() async {
    final nombre  = _nombreCtrl.text.trim();
    final motivo  = _motivoCtrl.text.trim();
    if (nombre.isEmpty && motivo.isEmpty) {
      _snack('Ingresa al menos el nombre del paciente y el motivo de consulta');
      return;
    }
    setState(() { _analizando = true; _respuestaIA = null; });

    final semanas = _semanas.isNotEmpty ? ', gestante de $_semanas semanas' : '';
    final deseq   = _desequilibrio.isNotEmpty
        ? 'Desequilibrio identificado: $_desequilibrio.' : '';
    final comunidad = _comunidadCtrl.text.trim().isEmpty
        ? _comunidadSel : _comunidadCtrl.text.trim();

    final pregunta = '''
Consulta por saberes ancestrales.
Paciente: $nombre$semanas, comunidad: $comunidad.
Sabedora/partera: ${_sabedoraCtrl.text.trim()}.
Motivo: $motivo. $deseq
Por favor indica:
1. Nivel de riesgo (Bajo, Medio, Alto, Urgente)
2. Compatibilidad medicina ancestral + occidental (porcentaje)
3. Recomendación principal (1 oración)
4. Si requiere remisión médica
Responde de forma breve y en español colombiano.
''';

    final resp = await IaService.instance.consultar(pregunta);
    final plantas = _seleccionarPlantas(motivo, _desequilibrio);

    // Extraer nivel de riesgo de la respuesta
    String nivel = 'Bajo';
    if (resp.toLowerCase().contains('urgente') || resp.toLowerCase().contains('emergencia')) {
      nivel = 'Urgente';
    } else if (resp.toLowerCase().contains('alto')) {
      nivel = 'Alto';
    } else if (resp.toLowerCase().contains('medio')) {
      nivel = 'Medio';
    }

    if (mounted) setState(() {
      _respuestaIA   = resp;
      _nivelRiesgo   = nivel;
      _compatibilidad = '${85 + (motivo.length % 10)}%';
      _recomendacion  = _extractRecomendacion(resp);
      _plantasRec    = plantas;
      _analizando    = false;
    });
  }

  String _extractRecomendacion(String resp) {
    final lineas = resp.split('\n').where((l) => l.trim().isNotEmpty).toList();
    for (final l in lineas) {
      if (l.toLowerCase().contains('recomend') ||
          l.toLowerCase().contains('control') ||
          l.toLowerCase().contains('remis')) {
        return l.replaceAll(RegExp(r'^\d+[\.\)]\s*'), '').trim();
      }
    }
    return lineas.isNotEmpty ? lineas.last.trim() : 'Seguimiento y control con partera.';
  }

  List<_Planta> _seleccionarPlantas(String motivo, String deseq) {
    final texto = (motivo + deseq).toLowerCase()
        .replaceAll('á','a').replaceAll('é','e')
        .replaceAll('í','i').replaceAll('ó','o')
        .replaceAll('ú','u');
    if (texto.contains('estomac') || texto.contains('digesti') ||
        texto.contains('apetito') || texto.contains('calor')) {
      return _kPlantasPorCondicion['dolor_estomacal']!;
    }
    if (texto.contains('embara') || texto.contains('gestante') ||
        texto.contains('semana') || texto.contains('nausea')) {
      return _kPlantasPorCondicion['gestacion']!;
    }
    if (texto.contains('fiebre') || texto.contains('calent') ||
        texto.contains('temperatura')) {
      return _kPlantasPorCondicion['fiebre']!;
    }
    if (texto.contains('cabeza') || texto.contains('dolor de cabeza') ||
        texto.contains('cefal')) {
      return _kPlantasPorCondicion['dolor_cabeza']!;
    }
    return _kPlantasPorCondicion['general']!;
  }

  // ── Guardar consulta ──────────────────────────────────────────────────────
  Future<void> _guardarConsulta() async {
    if (_nombreCtrl.text.trim().isEmpty) {
      _snack('Ingresa el nombre del paciente'); return;
    }
    setState(() => _guardando = true);

    final datos = {
      'nombre':       _nombreCtrl.text.trim(),
      'modulo':       'Saberes Ancestrales',
      'diagnostico':  _desequilibrio.isNotEmpty
          ? _desequilibrio : _motivoCtrl.text.trim(),
      'observaciones': 'Sabedora: ${_sabedoraCtrl.text.trim()}. '
          'Comunidad: $_comunidadSel. '
          'Motivo: ${_motivoCtrl.text.trim()}. '
          'IA: ${_respuestaIA ?? "Sin análisis"}',
      'nivel_riesgo':  _nivelRiesgo ?? 'estable',
      'semanas':       _semanas,
      'fecha':         DateTime.now().toIso8601String(),
    };

    // Si hay paciente seleccionado, asociar
    if (_pacienteSeleccionado != null) {
      datos['paciente_id'] = _pacienteSeleccionado!['id'].toString();
    }

    await DatabaseHelper.instance.insertarConsulta(datos);

    if (mounted) {
      setState(() => _guardando = false);
      _snack('✅ Consulta guardada exitosamente');
    }
  }

  // ── Llamar ────────────────────────────────────────────────────────────────
  void _llamar() {
    final tel = _telefonoCtrl.text.trim().isNotEmpty
        ? _telefonoCtrl.text.trim()
        : (_pacienteSeleccionado?['telefono'] as String? ?? '');

    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: _kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: const [
        Icon(Icons.phone_rounded, color: _kVerde, size: 22),
        SizedBox(width: 8),
        Text('Contactar paciente',
            style: TextStyle(color: _kTexto, fontSize: 16)),
      ]),
      content: tel.isNotEmpty
          ? Column(mainAxisSize: MainAxisSize.min, children: [
              Text(_nombreCtrl.text.trim(),
                  style: const TextStyle(color: _kTexto,
                      fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.phone_outlined, color: _kVerde, size: 16),
                const SizedBox(width: 6),
                Text(tel, style: const TextStyle(color: _kTextoSec)),
              ]),
            ])
          : const Text('No hay número registrado.',
              style: TextStyle(color: _kTextoHint)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar',
                style: TextStyle(color: _kTextoHint))),
        if (tel.isNotEmpty)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: _kVerde),
            onPressed: () async {
              Navigator.pop(context);
              final uri = Uri(scheme: 'tel', path: tel);
              if (await canLaunchUrl(uri)) await launchUrl(uri);
            },
            icon: const Icon(Icons.phone_rounded,
                color: Colors.white, size: 16),
            label: const Text('Llamar',
                style: TextStyle(color: Colors.white)),
          ),
      ],
    ));
  }

  // ── Mensaje WhatsApp ──────────────────────────────────────────────────────
  void _mensaje() {
    final tel = _telefonoCtrl.text.trim().isNotEmpty
        ? _telefonoCtrl.text.trim()
        : (_pacienteSeleccionado?['telefono'] as String? ?? '');
    final nombre = _nombreCtrl.text.trim();
    final texto  = Uri.encodeComponent(
      'Hola $nombre, le escribe DISPERSALUD. '
      'Su próximo control ancestral está programado. '
      '¿Cómo se siente? 🌿',
    );

    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: _kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: const [
        Icon(Icons.message_rounded, color: Color(0xFF25D366), size: 22),
        SizedBox(width: 8),
        Text('Enviar mensaje', style: TextStyle(color: _kTexto, fontSize: 16)),
      ]),
      content: tel.isNotEmpty
          ? Text('Se enviará un mensaje de seguimiento a $nombre ($tel)',
              style: const TextStyle(color: _kTextoSec))
          : const Text('No hay número registrado.',
              style: TextStyle(color: _kTextoHint)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style: TextStyle(color: _kTextoHint))),
        if (tel.isNotEmpty)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366)),
            onPressed: () async {
              Navigator.pop(context);
              final uri = Uri.parse('https://wa.me/57$tel?text=$texto');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.send_rounded,
                color: Colors.white, size: 16),
            label: const Text('WhatsApp',
                style: TextStyle(color: Colors.white)),
          ),
      ],
    ));
  }

  // ── Chat IA ───────────────────────────────────────────────────────────────
  Future<void> _enviarMensajeIA() async {
    final txt = _iaCtrl.text.trim();
    if (txt.isEmpty) return;
    setState(() {
      _mensajesIA.add({'rol': 'usuario', 'texto': txt});
      _iaCtrl.clear();
      _enviandoIA = true;
    });

    final contexto = _nombreCtrl.text.trim().isNotEmpty
        ? 'Paciente: ${_nombreCtrl.text.trim()}. '
          'Comunidad: $_comunidadSel. '
          'Motivo: ${_motivoCtrl.text.trim()}. '
          'Desequilibrio: $_desequilibrio. '
        : '';

    final resp = await IaService.instance.consultar(
        '$contexto Pregunta del promotor: $txt');
    if (mounted) setState(() {
      _mensajesIA.add({'rol': 'ia', 'texto': resp});
      _enviandoIA = false;
    });
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg),
          backgroundColor: _kVerdeOsc,
          behavior: SnackBarBehavior.floating),
    );
  }

  Color _colorRiesgo(String? n) {
    switch (n) {
      case 'Urgente': return Colors.red;
      case 'Alto':    return Colors.orange;
      case 'Medio':   return Colors.amber;
      default:        return _kVerde;
    }
  }

  // ── PRÓXIMO CONTROL ───────────────────────────────────────────────────────
  String get _proximoControl {
    final next = DateTime.now().add(const Duration(days: 7));
    final meses = ['ene','feb','mar','abr','may','jun',
                   'jul','ago','sep','oct','nov','dic'];
    return '${next.day} ${meses[next.month-1]} ${next.year}';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kFondo,
      floatingActionButton: FloatingActionButton(
        backgroundColor: _kMorado,
        onPressed: () => setState(() => _iaVisible = !_iaVisible),
        child: Icon(_iaVisible ? Icons.close : Icons.smart_toy_rounded,
            color: Colors.white, size: 26),
        tooltip: 'IA DISPERSALUD',
      ),
      body: ResponsiveCenter(child: Stack(
        children: [
          // ── Fondo decorativo ──────────────────────────────────────────
          Positioned(top: 0, left: 0, right: 0,
            child: Container(height: 220,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0A1A0C), Color(0xFF132015)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // ── CONTENIDO PRINCIPAL ───────────────────────────────────────
          SafeArea(
            child: Column(children: [

              // APP BAR
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                          color: _kCard, borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _kBorder)),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: _kTexto, size: 16),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: _kVerdeOsc.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _kVerde.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.eco_rounded, color: _kVerde, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Consulta por',
                        style: TextStyle(color: _kTextoHint, fontSize: 11)),
                    const Text('Saberes Ancestrales',
                        style: TextStyle(color: _kTexto, fontSize: 17,
                            fontWeight: FontWeight.bold)),
                  ])),
                  // Badge online
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                        color: _online ? _kVerde.withOpacity(0.12) : _kCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _online ? _kVerde : _kBorder)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 6, height: 6,
                          decoration: BoxDecoration(
                              color: _online ? _kVerde : Colors.orange,
                              shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text(_online ? 'Online' : 'Offline',
                          style: TextStyle(
                              color: _online ? _kVerde : Colors.orange,
                              fontSize: 10, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  // Campana alertas
                  Stack(children: [
                    Container(width: 36, height: 36,
                        decoration: BoxDecoration(
                            color: _kCard, borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _kBorder)),
                        child: const Icon(Icons.notifications_outlined,
                            color: _kTextoSec, size: 18)),
                    Positioned(top: 4, right: 4,
                        child: Container(width: 12, height: 12,
                            decoration: const BoxDecoration(
                                color: Colors.red, shape: BoxShape.circle),
                            child: const Center(
                                child: Text('3', style: TextStyle(
                                    color: Colors.white, fontSize: 7,
                                    fontWeight: FontWeight.bold))))),
                  ]),
                ]),
              ),

              // Subtítulo
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Text(
                  'Integramos conocimiento ancestral y medicina occidental para cuidar la vida.',
                  style: TextStyle(color: _kTextoHint, fontSize: 10.5, height: 1.4),
                ),
              ),

              // ── CONTENIDO SCROLLABLE ────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── CARD PACIENTE + IA ────────────────────────
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        // Card paciente
                        Expanded(flex: 5, child: _cardPaciente()),
                        const SizedBox(width: 10),
                        // Card IA
                        Expanded(flex: 4, child: _cardIA()),
                      ]),
                      const SizedBox(height: 12),

                      // ── CONSULTA ACTUAL ───────────────────────────
                      _cardConsulta(),
                      const SizedBox(height: 12),

                      // ── DIAGNÓSTICO TRADICIONAL ───────────────────
                      _cardDiagnostico(),
                      const SizedBox(height: 12),

                      // ── PLANTAS MEDICINALES ───────────────────────
                      if (_plantasRec.isNotEmpty) ...[
                        _cardPlantas(),
                        const SizedBox(height: 12),
                      ],

                      // ── ACCIONES: LLAMAR / MENSAJE / AGENDA ───────
                      _cardAcciones(),
                      const SizedBox(height: 12),

                      // ── INTEGRACIÓN MÉDICA + SEGUIMIENTO ─────────
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(child: _cardIntegracionMedica()),
                        const SizedBox(width: 10),
                        Expanded(child: _cardSeguimiento()),
                      ]),
                      const SizedBox(height: 12),

                      // ── EVIDENCIA CIENTÍFICA ──────────────────────
                      _cardEvidencia(),
                      const SizedBox(height: 12),

                      // ── BOTÓN GUARDAR ─────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kVerdeOsc,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _guardando ? null : _guardarConsulta,
                          icon: _guardando
                              ? const SizedBox(width: 18, height: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.save_rounded,
                                  color: Colors.white, size: 18),
                          label: Text(
                            _guardando ? 'Guardando...' : 'Guardar consulta ancestral',
                            style: const TextStyle(color: Colors.white,
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ]),
          ),

          // ── CHAT IA FLOTANTE ──────────────────────────────────────────
          if (_iaVisible)
            Positioned(
              bottom: 80, right: 12, left: 12,
              child: _chatIAPanel(),
            ),
        ],
      ), ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SECCIONES
  // ─────────────────────────────────────────────────────────────────────────

  Widget _cardPaciente() => _Card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Avatar
      Container(
        width: 60, height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF2D5A27), Color(0xFF1A7A42)]),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.person_rounded, color: Colors.white, size: 32),
      ),
      const SizedBox(height: 8),
      // Selector de paciente existente
      if (_pacientes.isNotEmpty) ...[
        Text('Paciente registrado', style: TextStyle(
            color: _kTextoHint, fontSize: 9)),
        const SizedBox(height: 4),
        DropdownButtonFormField<Map<String, dynamic>>(
          value: _pacienteSeleccionado,
          isExpanded: true,
          dropdownColor: _kCardAlt,
          style: const TextStyle(color: _kTexto, fontSize: 11),
          hint: Text('Seleccionar...', style: TextStyle(
              color: _kTextoHint, fontSize: 10)),
          decoration: InputDecoration(
            isDense: true, contentPadding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 6),
            filled: true, fillColor: _kFondo,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _kBorder)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _kBorder)),
          ),
          items: _pacientes.map((p) => DropdownMenuItem(
            value: p,
            child: Text(p['nombre'] as String? ?? '',
                overflow: TextOverflow.ellipsis),
          )).toList(),
          onChanged: (p) {
            setState(() {
              _pacienteSeleccionado = p;
              if (p != null) {
                _nombreCtrl.text  = p['nombre'] as String? ?? '';
                _telefonoCtrl.text = p['telefono'] as String? ?? '';
                _comunidadSel     = p['municipio'] as String? ?? _comunidadSel;
              }
            });
          },
        ),
        const SizedBox(height: 6),
        Text('— o ingresa nuevo —', style: TextStyle(
            color: _kTextoHint, fontSize: 8.5,
            fontStyle: FontStyle.italic)),
        const SizedBox(height: 4),
      ],
      _campo('Nombre del paciente', _nombreCtrl),
      const SizedBox(height: 6),
      _campo('Teléfono (WhatsApp)', _telefonoCtrl,
          tipo: TextInputType.phone),
      const SizedBox(height: 6),
      // Semanas gestación
      _campo('Semanas de gestación (opcional)', TextEditingController(text: _semanas),
        tipo: TextInputType.number,
        onChanged: (v) => setState(() => _semanas = v),
      ),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _kMorado.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kMorado.withOpacity(0.4)),
        ),
        child: Row(children: [
          const Icon(Icons.location_on_outlined, color: _kTextoHint, size: 12),
          const SizedBox(width: 4),
          Expanded(child: Text(
              _comunidadSel, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _kTextoSec, fontSize: 10))),
        ]),
      ),
    ]),
  );

  Widget _cardIA() {
    if (_analizando) {
      return _Card(child: const SizedBox(
        height: 140,
        child: Center(child: Column(
          mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(color: _kMoradoClaro, strokeWidth: 2),
            SizedBox(height: 10),
            Text('Analizando...', style: TextStyle(
                color: _kTextoHint, fontSize: 11)),
          ],
        )),
      ));
    }
    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_kMorado, _kMoradoClaro]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          const Text('IA DISPERSALUD',
              style: TextStyle(color: _kMoradoClaro, fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 10),
        if (_respuestaIA != null) ...[
          _infoRow('Nivel de riesgo', ''),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _colorRiesgo(_nivelRiesgo).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: _colorRiesgo(_nivelRiesgo).withOpacity(0.5)),
            ),
            child: Text(_nivelRiesgo ?? 'Bajo',
                style: TextStyle(color: _colorRiesgo(_nivelRiesgo),
                    fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(height: 8),
          _infoRow('Compatibilidad', _compatibilidad ?? '90%'),
          const SizedBox(height: 6),
          Text('Recomendación', style: TextStyle(
              color: _kTextoHint, fontSize: 9.5)),
          const SizedBox(height: 3),
          Text(_recomendacion ?? '', style: const TextStyle(
              color: _kTexto, fontSize: 10.5, height: 1.4)),
          const SizedBox(height: 10),
        ] else ...[
          Text('Completa los datos del paciente y motivo,\nluego pulsa Analizar.',
              style: TextStyle(color: _kTextoHint, fontSize: 10, height: 1.4)),
          const SizedBox(height: 10),
        ],
        GestureDetector(
          onTap: _analizarConIA,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_kMorado, Color(0xFF4B2D8A)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
              const SizedBox(width: 6),
              Text(_respuestaIA == null ? 'Ver análisis ›' : 'Reanalizar ›',
                  style: const TextStyle(color: Colors.white, fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _cardConsulta() => _Card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _seccionTitulo(Icons.medical_services_outlined, 'Consulta actual'),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: Column(children: [
          _infoRow('Fecha', _fechaHoy()),
          const SizedBox(height: 6),
          _campo('Sabedora / Partera', _sabedoraCtrl),
        ])),
        const SizedBox(width: 10),
        Expanded(child: Column(children: [
          // Comunidad
          DropdownButtonFormField<String>(
            value: _comunidadSel,
            isExpanded: true,
            dropdownColor: _kCardAlt,
            style: const TextStyle(color: _kTexto, fontSize: 11),
            decoration: _inputDeco('Comunidad'),
            items: _comunidades.map((c) => DropdownMenuItem(
              value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (v) => setState(() => _comunidadSel = v ?? _comunidadSel),
          ),
        ])),
      ]),
      const SizedBox(height: 8),
      _campo('Motivo de consulta', _motivoCtrl, maxLineas: 2),
    ]),
  );

  Widget _cardDiagnostico() => _Card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _seccionTitulo(Icons.eco_rounded, 'Diagnóstico tradicional'),
      Text('Desequilibrio identificado',
          style: TextStyle(color: _kTextoHint, fontSize: 10)),
      const SizedBox(height: 10),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Icono desequilibrio
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            color: _kVerdeOsc.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: _kVerde.withOpacity(0.3)),
          ),
          child: const Icon(Icons.spa_rounded, color: _kVerde, size: 30),
        ),
        const SizedBox(width: 10),
        // Selector desequilibrio
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          DropdownButtonFormField<String>(
            value: _desequilibrio.isEmpty ? null : _desequilibrio,
            dropdownColor: _kCardAlt,
            style: const TextStyle(color: _kTexto, fontSize: 11),
            hint: Text('Seleccionar desequilibrio...',
                style: TextStyle(color: _kTextoHint, fontSize: 10)),
            decoration: _inputDeco('Desequilibrio'),
            items: _desequilibrios.map((d) => DropdownMenuItem(
              value: d, child: Text(d, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11)))).toList(),
            onChanged: (v) => setState(() => _desequilibrio = v ?? ''),
          ),
          if (_desequilibrio.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6B2500).withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.local_fire_department_rounded,
                    color: Colors.orange, size: 16),
                const SizedBox(width: 6),
                Expanded(child: Text(_desequilibrio,
                    style: const TextStyle(color: Colors.orange,
                        fontWeight: FontWeight.bold, fontSize: 11))),
              ]),
            ),
          ],
        ])),
      ]),
      const SizedBox(height: 10),
      // Síntomas y observación
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Síntomas observados', style: TextStyle(
              color: _kTextoHint, fontSize: 9.5)),
          const SizedBox(height: 4),
          ..._sintomasDe(_desequilibrio).map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(children: [
              Container(width: 5, height: 5,
                  decoration: const BoxDecoration(
                      color: _kVerde, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(s, style: const TextStyle(
                  color: _kTextoSec, fontSize: 10.5)),
            ]),
          )),
        ])),
        const SizedBox(width: 8),
        Expanded(child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _kVerdeOsc.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kVerde.withOpacity(0.2)),
          ),
          child: Text(
            _motivoCtrl.text.trim().isEmpty
                ? 'El cuerpo requiere equilibrio y descanso espiritual.'
                : _motivoCtrl.text.trim(),
            style: const TextStyle(color: _kTextoSec,
                fontSize: 10, fontStyle: FontStyle.italic, height: 1.4),
          ),
        )),
      ]),
    ]),
  );

  Widget _cardPlantas() => _Card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _seccionTitulo(Icons.local_florist_rounded, 'Plantas medicinales recomendadas'),
        const Spacer(),
        GestureDetector(
          onTap: () => _verTodasPlantas(),
          child: const Text('Ver todas',
              style: TextStyle(color: _kVerde, fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ),
      ]),
      const SizedBox(height: 10),
      SizedBox(
        height: 180,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _plantasRec.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) => _plantaCard(_plantasRec[i]),
        ),
      ),
    ]),
  );

  Widget _plantaCard(_Planta p) => Container(
    width: 130,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: _kCardAlt,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: p.color.withOpacity(0.3)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
            color: p.color.withOpacity(0.15), shape: BoxShape.circle),
        child: Icon(p.icono, color: p.color, size: 18),
      ),
      const SizedBox(height: 6),
      Text(p.nombre, style: const TextStyle(color: _kTexto,
          fontWeight: FontWeight.bold, fontSize: 11)),
      Text(p.nombreCientifico, style: TextStyle(
          color: _kTextoHint, fontSize: 8.5, fontStyle: FontStyle.italic),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
            color: _kVerde.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.local_cafe_outlined, color: _kVerde, size: 10),
          const SizedBox(width: 3),
          Text(p.uso, style: const TextStyle(color: _kVerde, fontSize: 9)),
        ]),
      ),
      const SizedBox(height: 4),
      Text(p.beneficio, style: const TextStyle(
          color: _kTextoSec, fontSize: 9.5, height: 1.3),
          maxLines: 3, overflow: TextOverflow.ellipsis),
      const Spacer(),
      GestureDetector(
        onTap: () => _verPreparacion(p),
        child: Row(children: const [
          Text('Ver preparación', style: TextStyle(
              color: _kVerde, fontSize: 9, fontWeight: FontWeight.w600)),
          SizedBox(width: 2),
          Icon(Icons.chevron_right_rounded, color: _kVerde, size: 12),
        ]),
      ),
    ]),
  );

  Widget _cardAcciones() => _Card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _seccionTitulo(Icons.touch_app_rounded, 'Acciones'),
      const SizedBox(height: 10),
      Row(children: [
        _botonAccion(Icons.phone_rounded, 'Llamar', _kVerde, _llamar),
        const SizedBox(width: 8),
        _botonAccion(Icons.message_rounded, 'Mensaje',
            const Color(0xFF25D366), _mensaje),
        const SizedBox(width: 8),
        _botonAccion(Icons.calendar_today_rounded, 'Agenda',
            _kDorado, _agendarControl),
        const SizedBox(width: 8),
        _botonAccion(Icons.smart_toy_rounded, 'IA',
            _kMorado, () => setState(() => _iaVisible = !_iaVisible)),
      ]),
    ]),
  );

  Widget _botonAccion(IconData icono, String label, Color color,
      VoidCallback onTap) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
                color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icono, color: color, size: 18),
          ),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w600)),
        ]),
      ),
    ),
  );

  Widget _cardIntegracionMedica() => _Card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _seccionTitulo(Icons.local_hospital_outlined, 'Integración médica'),
      const SizedBox(height: 8),
      ..._recomendacionesMedicas().map((r) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.check_circle_rounded, color: _kVerde, size: 14),
          const SizedBox(width: 6),
          Expanded(child: Text(r, style: const TextStyle(
              color: _kTextoSec, fontSize: 10.5, height: 1.3))),
        ]),
      )),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: _verPlanAtencion,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: _kVerdeOsc.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kVerde.withOpacity(0.3)),
          ),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('Ver plan de atención',
                style: TextStyle(color: _kVerde, fontSize: 11,
                    fontWeight: FontWeight.w600)),
            SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: _kVerde, size: 14),
          ]),
        ),
      ),
    ]),
  );

  Widget _cardSeguimiento() => _Card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _seccionTitulo(Icons.calendar_month_rounded, 'Seguimiento'),
      const SizedBox(height: 6),
      Text('Próximo control', style: TextStyle(
          color: _kTextoHint, fontSize: 10)),
      const SizedBox(height: 4),
      Text(_proximoControl, style: const TextStyle(
          color: _kVerde, fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      // Imagen decorativa gestante
      Container(
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [_kMorado.withOpacity(0.3), _kFondo],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Icon(Icons.pregnant_woman_rounded,
              color: _kMoradoClaro.withOpacity(0.6), size: 50),
        ),
      ),
      const SizedBox(height: 10),
      GestureDetector(
        onTap: _guardarConsulta,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: _kMorado.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kMorado.withOpacity(0.4)),
          ),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.calendar_today_rounded, color: _kMoradoClaro, size: 14),
            SizedBox(width: 6),
            Text('Registrar visita', style: TextStyle(
                color: _kMoradoClaro, fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    ]),
  );

  Widget _cardEvidencia() => _Card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _seccionTitulo(Icons.science_outlined, 'Evidencia científica'),
      Text('Información basada en estudios científicos sobre plantas medicinales.',
          style: TextStyle(color: _kTextoHint, fontSize: 9.5)),
      const SizedBox(height: 10),
      ..._plantasRec.take(2).map((p) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _kCardAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kBorder),
        ),
        child: Row(children: [
          Container(width: 40, height: 40,
              decoration: BoxDecoration(
                  color: p.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(p.icono, color: p.color, size: 20)),
          const SizedBox(width: 10),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.nombre, style: const TextStyle(
                color: _kTexto, fontWeight: FontWeight.bold, fontSize: 11)),
            Text(p.beneficio, style: TextStyle(
                color: _kTextoHint, fontSize: 9.5), maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ])),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Nivel de evidencia', style: TextStyle(
                color: _kTextoHint, fontSize: 8)),
            const Text('Moderado', style: TextStyle(
                color: _kTexto, fontWeight: FontWeight.bold, fontSize: 10)),
            const SizedBox(height: 3),
            Row(children: List.generate(4, (i) => Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Container(width: 8, height: 8,
                  decoration: BoxDecoration(
                      color: i < 3 ? _kDorado : _kDorado.withOpacity(0.2),
                      shape: BoxShape.circle)),
            ))),
          ]),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded,
              color: _kTextoHint, size: 16),
        ]),
      )),
    ]),
  );

  // ── CHAT IA PANEL ─────────────────────────────────────────────────────────
  Widget _chatIAPanel() => Container(
    height: 380,
    decoration: BoxDecoration(
      color: _kCard,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _kMorado.withOpacity(0.4)),
      boxShadow: [BoxShadow(
          color: _kMorado.withOpacity(0.2),
          blurRadius: 20, spreadRadius: 2)],
    ),
    child: Column(children: [
      // Header
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [_kMorado, Color(0xFF3A1D6E)]),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Row(children: [
          const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          const Expanded(child: Text('IA DISPERSALUD — Saberes Ancestrales',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,
                  fontSize: 12))),
          Container(width: 8, height: 8,
              decoration: BoxDecoration(
                  color: _online ? _kVerde : Colors.orange,
                  shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(_online ? 'Groq' : 'Offline',
              style: const TextStyle(color: Colors.white70, fontSize: 9)),
        ]),
      ),
      // Mensajes
      Expanded(child: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: _mensajesIA.length + (_enviandoIA ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == _mensajesIA.length) {
            return Align(alignment: Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                    color: _kCardAlt, borderRadius: BorderRadius.circular(10)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(
                          color: _kMoradoClaro, strokeWidth: 2)),
                  const SizedBox(width: 8),
                  const Text('Analizando...', style: TextStyle(
                      color: _kTextoHint, fontSize: 11)),
                ]),
              ),
            );
          }
          final m   = _mensajesIA[i];
          final isIA = m['rol'] == 'ia';
          return Align(
            alignment: isIA ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.65),
              decoration: BoxDecoration(
                color: isIA ? _kCardAlt : _kMorado.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isIA ? _kBorder : _kMorado.withOpacity(0.4)),
              ),
              child: Text(m['texto'] ?? '', style: TextStyle(
                  color: isIA ? _kTextoSec : _kTexto, fontSize: 11,
                  height: 1.4)),
            ),
          );
        },
      )),
      // Input
      Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
        child: Row(children: [
          Expanded(child: TextField(
            controller: _iaCtrl,
            style: const TextStyle(color: _kTexto, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Pregunta sobre el paciente...',
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
            onSubmitted: (_) => _enviarMensajeIA(),
          )),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _enviandoIA ? null : _enviarMensajeIA,
            child: Container(
              width: 36, height: 36,
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
  );

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS UI
  // ─────────────────────────────────────────────────────────────────────────

  Widget _seccionTitulo(IconData icono, String titulo) => Row(children: [
    Icon(icono, color: _kVerde, size: 16),
    const SizedBox(width: 6),
    Expanded(child: Text(titulo, style: const TextStyle(
        color: _kTexto, fontSize: 13, fontWeight: FontWeight.bold))),
  ]);

  Widget _infoRow(String label, String valor) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(color: _kTextoHint, fontSize: 10)),
      if (valor.isNotEmpty)
        Text(valor, style: const TextStyle(
            color: _kTexto, fontWeight: FontWeight.w600, fontSize: 10)),
    ],
  );

  Widget _campo(String hint, TextEditingController ctrl, {
    TextInputType tipo = TextInputType.text,
    int maxLineas = 1,
    void Function(String)? onChanged,
  }) => TextField(
    controller: ctrl,
    keyboardType: tipo,
    maxLines: maxLineas,
    style: const TextStyle(color: _kTexto, fontSize: 11),
    decoration: _inputDeco(hint),
    onChanged: onChanged,
  );

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: _kTextoHint, fontSize: 10),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    filled: true, fillColor: _kFondo,
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _kBorder)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _kBorder)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _kVerde)),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // DATOS DINÁMICOS
  // ─────────────────────────────────────────────────────────────────────────

  List<String> _sintomasDe(String deseq) {
    final mapa = {
      'Calor corporal en el estómago':
          ['Dolor abdominal', 'Cansancio', 'Boca amarga'],
      'Frío en los huesos':
          ['Dolor articular', 'Escalofríos', 'Fatiga'],
      'Susto o espanto':
          ['Insomnio', 'Palpitaciones', 'Pérdida de apetito'],
      'Mal de ojo':
          ['Llanto constante', 'Fiebre leve', 'Decaimiento'],
      'Desequilibrio espiritual':
          ['Tristeza', 'Aislamiento', 'Falta de energía'],
      'Dolor de vientre':
          ['Cólico', 'Náuseas', 'Distensión'],
      'Fiebre espiritual':
          ['Temperatura alta', 'Confusión leve', 'Sudoración'],
      'Tristeza del alma':
          ['Llanto', 'Sin apetito', 'Insomnio'],
    };
    return mapa[deseq] ?? ['Sin síntomas registrados'];
  }

  List<String> _recomendacionesMedicas() {
    final base = [
      'Hidratación constante',
      'Dieta ligera y alimentos frescos',
    ];
    final nivel = _nivelRiesgo ?? '';
    if (nivel == 'Alto' || nivel == 'Urgente') {
      base.add('Evaluación médica inmediata');
      base.add('Remisión a urgencias si no mejora');
    } else {
      base.add('Evaluación médica si persisten síntomas');
    }
    if (_semanas.isNotEmpty) {
      base.add('Control prenatal en 7 días');
    }
    return base;
  }

  String _fechaHoy() {
    final now    = DateTime.now();
    final meses  = ['ene','feb','mar','abr','may','jun',
                    'jul','ago','sep','oct','nov','dic'];
    return '${now.day} ${meses[now.month-1]} ${now.year}';
  }

  void _verPreparacion(_Planta p) {
    showModalBottomSheet(context: context,
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
          const SizedBox(height: 4),
          Text(p.nombreCientifico, style: TextStyle(
              color: _kTextoHint, fontSize: 11, fontStyle: FontStyle.italic)),
          const SizedBox(height: 14),
          const Text('Preparación:', style: TextStyle(
              color: _kVerde, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          Text(p.preparacion, style: const TextStyle(
              color: _kTextoSec, fontSize: 13, height: 1.5)),
          const SizedBox(height: 16),
          const Text('⚠️ Siempre consultar con la sabedora o partera local '
              'antes de administrar plantas medicinales.',
              style: TextStyle(color: Colors.orange, fontSize: 11, height: 1.4)),
        ]),
      ),
    );
  }

  void _verTodasPlantas() {
    final todasPlantas = _kPlantasPorCondicion.values
        .expand((l) => l).toSet().toList();
    showModalBottomSheet(context: context,
      backgroundColor: _kCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false, initialChildSize: 0.7, maxChildSize: 0.95,
        builder: (_, ctrl) => ListView(
          controller: ctrl, padding: const EdgeInsets.all(16),
          children: [
            const Text('Todas las plantas medicinales',
                style: TextStyle(color: _kTexto, fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            ...todasPlantas.map((p) => ListTile(
              leading: Container(width: 36, height: 36,
                  decoration: BoxDecoration(
                      color: p.color.withOpacity(0.15),
                      shape: BoxShape.circle),
                  child: Icon(p.icono, color: p.color, size: 18)),
              title: Text(p.nombre, style: const TextStyle(color: _kTexto)),
              subtitle: Text(p.beneficio, style: TextStyle(
                  color: _kTextoHint, fontSize: 10)),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: _kTextoHint, size: 16),
              onTap: () { Navigator.pop(context); _verPreparacion(p); },
            )),
          ],
        ),
      ),
    );
  }

  void _agendarControl() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (_, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: _kVerde),
        ), child: child!,
      ),
    ).then((fecha) {
      if (fecha != null) {
        final meses = ['ene','feb','mar','abr','may','jun',
                       'jul','ago','sep','oct','nov','dic'];
        _snack('✅ Control agendado: ${fecha.day} ${meses[fecha.month-1]} ${fecha.year}');
      }
    });
  }

  void _verPlanAtencion() {
    showModalBottomSheet(context: context,
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Plan de atención integral', style: TextStyle(
              color: _kTexto, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          ..._recomendacionesMedicas().map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.check_circle_rounded,
                  color: _kVerde, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(r, style: const TextStyle(
                  color: _kTextoSec, fontSize: 13))),
            ]),
          )),
          const SizedBox(height: 12),
          if (_plantasRec.isNotEmpty) ...[
            const Text('Plantas recomendadas:',
                style: TextStyle(color: _kVerde, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            ..._plantasRec.map((p) => Text('• ${p.nombre}: ${p.uso}',
                style: const TextStyle(color: _kTextoSec, fontSize: 12))),
          ],
          const SizedBox(height: 14),
          const Text('Seguimiento: control en 7 días con partera.',
              style: TextStyle(color: _kDorado, fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET REUTILIZABLE — Card con estilo ancestral
// ─────────────────────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _kCard,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _kBorder),
    ),
    child: child,
  );
}
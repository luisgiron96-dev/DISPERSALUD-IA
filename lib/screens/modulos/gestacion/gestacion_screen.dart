import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../database/database_helper.dart';

// ─── Paleta ───────────────────────────────────────────────────────────────
const Color _kPink   = Color(0xFF8E2C52);
const Color _kBg     = Color(0xFF111111);
const Color _kCard   = Color(0xFF1E1E1E);
const Color _kBorder = Color(0xFF2A2A2A);

// ─── Rangos clínicos reales (OPS / Ministerio de Salud Colombia) ──────────
class _Rangos {
  // Presión arterial en gestación
  static bool esHipertensionGestacional(int sist, int diast) =>
      sist >= 140 || diast >= 90;
  static bool esCrisisHipertensiva(int sist, int diast) =>
      sist >= 160 || diast >= 110;

  // FCF normal: 110–160 lpm (ACOG 2021)
  static bool fcfNormal(int fcf) => fcf >= 110 && fcf <= 160;
  static bool fcfBradicardia(int fcf) => fcf < 110;
  static bool fcfTaquicardia(int fcf) => fcf > 160;

  // Altura uterina normal por semanas (tabla Fescina/CLAP)
  // AU esperada (cm) ≈ semanas − 4 (entre sem 20–36) con ±2 cm de tolerancia
  static String evaluarAU(int semanas, double au) {
    if (semanas < 20) return 'normal';
    final esperada = semanas - 4.0;
    if (au < esperada - 2) return 'pequeño';
    if (au > esperada + 2) return 'grande';
    return 'normal';
  }

  // Hemoglobina en gestación (OMS): < 11 g/dL = anemia
  static bool anemiaGestacional(double hb) => hb < 11.0;
  static bool anemiaSevera(double hb) => hb < 7.0;

  // Ganancia de peso según IMC pregestacional (IOM 2009)
  static String evaluarGananciaPeso(double pesoActual, double pesoInicial,
      int semanas, String imc) {
    if (semanas < 14 || pesoInicial <= 0) return 'sin datos';
    final ganancia = pesoActual - pesoInicial;
    final semanasDesde14 = semanas - 14;
    if (semanasDesde14 <= 0) return 'normal';
    double minSem, maxSem;
    switch (imc) {
      case 'bajo':    minSem = 0.44; maxSem = 0.58; break;
      case 'normal':  minSem = 0.35; maxSem = 0.50; break;
      case 'sobrepeso': minSem = 0.23; maxSem = 0.33; break;
      case 'obesidad':  minSem = 0.17; maxSem = 0.27; break;
      default:          return 'sin datos';
    }
    final minTotal = minSem * semanasDesde14;
    final maxTotal = maxSem * semanasDesde14;
    if (ganancia < minTotal) return 'insuficiente';
    if (ganancia > maxTotal) return 'excesiva';
    return 'adecuada';
  }
}

// ─── Widget principal ─────────────────────────────────────────────────────
class GestacionScreen extends StatefulWidget {
  final int?    pacienteId;
  final String? pacienteNombre;
  const GestacionScreen({super.key, this.pacienteId, this.pacienteNombre});
  @override
  State<GestacionScreen> createState() => _GestacionScreenState();
}

class _GestacionScreenState extends State<GestacionScreen> {
  // ── Controladores ────────────────────────────────────────────────────────
  final _semanasCtrl    = TextEditingController();
  final _edadCtrl       = TextEditingController();
  final _sistolicaCtrl  = TextEditingController();
  final _diastolicaCtrl = TextEditingController();
  final _pesoCtrl       = TextEditingController();
  final _tallaCtrl      = TextEditingController();
  final _auCtrl         = TextEditingController();
  final _fcfCtrl        = TextEditingController();
  final _hbCtrl         = TextEditingController();
  final _pesoInicialCtrl= TextEditingController();
  final _obsCtrl        = TextEditingController();

  // ── Estado clínico ───────────────────────────────────────────────────────
  String _paridad       = 'Primigesta';
  String _imcPre        = 'normal';
  bool   _toxoide       = false;
  bool   _acidoFolico   = false;
  bool   _hierro        = false;
  bool   _calcio        = false;
  bool   _ecografia1T   = false;
  bool   _ecografia2T   = false;
  bool   _ecografia3T   = false;
  bool   _vdrl          = false;
  bool   _hiv           = false;
  bool   _orina         = false;
  bool   _cefalea       = false;
  bool   _edemaFacial   = false;
  bool   _visionBorrosa = false;
  bool   _epigastralgia = false;
  bool   _sangrado      = false;
  bool   _movFetal      = true;

  // ── Paciente ─────────────────────────────────────────────────────────────
  int?    _pacienteId;
  String  _pacienteNombre = 'Sin paciente seleccionado';
  List<Map<String, dynamic>> _listaPacientes = [];

  // ── Resultado ────────────────────────────────────────────────────────────
  List<_Hallazgo> _hallazgos = [];
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _pacienteId     = widget.pacienteId;
    _pacienteNombre = widget.pacienteNombre ?? 'Sin paciente seleccionado';
    _cargarPacientes();
  }

  Future<void> _cargarPacientes() async {
    final lista = await DatabaseHelper.instance.obtenerPacientes();
    if (mounted) setState(() => _listaPacientes = lista);
  }

  // ─── Selección de paciente ───────────────────────────────────────────────
  Future<void> _seleccionarPaciente() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: _kCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, ctrl) => Column(children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Seleccionar paciente',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: _listaPacientes.isEmpty
                ? const Center(
                    child: Text('No hay pacientes registrados.\nVe a Pacientes y registra uno primero.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54)))
                : ListView.builder(
                    controller: ctrl,
                    itemCount: _listaPacientes.length,
                    itemBuilder: (_, i) {
                      final p = _listaPacientes[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _kPink.withOpacity(0.2),
                          child: Text(
                            (p['nombre'] as String? ?? '?')[0].toUpperCase(),
                            style: const TextStyle(color: _kPink, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(p['nombre'] ?? '', style: const TextStyle(color: Colors.white)),
                        subtitle: Text('${p['vereda'] ?? ''} · ${p['municipio'] ?? ''}',
                            style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        onTap: () {
                          setState(() {
                            _pacienteId     = p['id'] as int?;
                            _pacienteNombre = p['nombre'] ?? '';
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }

  // ─── Motor de análisis clínico ───────────────────────────────────────────
  List<_Hallazgo> _calcularHallazgos() {
    final hallazgos = <_Hallazgo>[];
    final semanas   = int.tryParse(_semanasCtrl.text.trim()) ?? 0;
    final sist      = int.tryParse(_sistolicaCtrl.text.trim()) ?? 0;
    final diast     = int.tryParse(_diastolicaCtrl.text.trim()) ?? 0;
    final fcf       = int.tryParse(_fcfCtrl.text.trim()) ?? 0;
    final au        = double.tryParse(_auCtrl.text.trim()) ?? 0;
    final hb        = double.tryParse(_hbCtrl.text.trim()) ?? 0;
    final peso      = double.tryParse(_pesoCtrl.text.trim()) ?? 0;
    final pesoIni   = double.tryParse(_pesoInicialCtrl.text.trim()) ?? 0;

    // 1 ── Presión arterial
    if (_sangrado && sist >= 140) {
      hallazgos.add(_Hallazgo.rojo(
        '🚨 ECLAMPSIA INMINENTE',
        'Sangrado + HTA severa. REMISIÓN DE EMERGENCIA INMEDIATA a ginecología. '
        'No dejar sola a la paciente. Activar ambulancia.',
      ));
    } else if (_cefalea && _visionBorrosa && sist >= 140) {
      hallazgos.add(_Hallazgo.rojo(
        '🚨 PREECLAMPSIA SEVERA',
        'PA $sist/$diast + cefalea + visión borrosa. Criterios de preeclampsia severa. '
        'REMISIÓN URGENTE. Administrar sulfato de magnesio si disponible y antihipertensivo.',
      ));
    } else if (_Rangos.esCrisisHipertensiva(sist, diast)) {
      hallazgos.add(_Hallazgo.rojo(
        '🚨 CRISIS HIPERTENSIVA GESTACIONAL',
        'PA $sist/$diast. Iniciar antihipertensivo de acción rápida (labetalol o nifedipino). '
        'Remisión urgente a hospital.',
      ));
    } else if (_Rangos.esHipertensionGestacional(sist, diast)) {
      hallazgos.add(_Hallazgo.naranja(
        '⚠️ Hipertensión gestacional',
        'PA $sist/$diast ≥ 140/90 mmHg después de semana 20. '
        'Iniciar vigilancia estricta. Solicitar proteinuria. Control en 48–72 horas.',
      ));
    } else if (sist > 0 && diast > 0) {
      hallazgos.add(_Hallazgo.verde(
        '✅ Tensión arterial normal',
        'PA $sist/$diast mmHg — dentro de rangos normales para gestación.',
      ));
    }

    // 2 ── Síntomas de alarma
    if (_epigastralgia) {
      hallazgos.add(_Hallazgo.rojo(
        '🚨 Epigastralgia — signo de preeclampsia severa',
        'Dolor en barra epigástrico. Evaluar junto a TA y proteinuria. '
        'Si PA ≥ 140/90 + epigastralgia: PREECLAMPSIA SEVERA — remisión inmediata.',
      ));
    }
    if (_edemaFacial) {
      hallazgos.add(_Hallazgo.naranja(
        '⚠️ Edema facial',
        'Edema en cara es signo de alarma en gestación. Evaluar PA, proteinuria y cefalea. '
        'Diferenciarlo del edema fisiológico de miembros inferiores.',
      ));
    }
    if (_sangrado && semanas < 20) {
      hallazgos.add(_Hallazgo.rojo(
        '🚨 Sangrado antes de semana 20',
        'Descartar amenaza de aborto, aborto en curso o embarazo ectópico. '
        'REMISIÓN URGENTE. No administrar oxitocina.',
      ));
    } else if (_sangrado && semanas >= 20) {
      hallazgos.add(_Hallazgo.rojo(
        '🚨 Sangrado después de semana 20',
        'Descartar placenta previa o desprendimiento prematuro de placenta. '
        'EMERGENCIA OBSTÉTRICA — remisión inmediata.',
      ));
    }
    if (!_movFetal && semanas >= 28) {
      hallazgos.add(_Hallazgo.rojo(
        '🚨 Ausencia de movimiento fetal',
        'Movimientos fetales ausentes después de semana 28. '
        'Realizar perfil biofísico urgente. REMISIÓN INMEDIATA.',
      ));
    }

    // 3 ── FCF
    if (fcf > 0) {
      if (_Rangos.fcfBradicardia(fcf)) {
        hallazgos.add(_Hallazgo.rojo(
          '🚨 Bradicardia fetal ($fcf lpm)',
          'FCF < 110 lpm. Sufrimiento fetal agudo. REMISIÓN URGENTE a ginecología.',
        ));
      } else if (_Rangos.fcfTaquicardia(fcf)) {
        hallazgos.add(_Hallazgo.naranja(
          '⚠️ Taquicardia fetal ($fcf lpm)',
          'FCF > 160 lpm. Puede indicar infección materna, fiebre o hipoxia fetal. '
          'Evaluar temperatura materna y estado general.',
        ));
      } else {
        hallazgos.add(_Hallazgo.verde(
          '✅ FCF normal ($fcf lpm)',
          'Frecuencia cardiaca fetal en rango normal (110–160 lpm).',
        ));
      }
    }

    // 4 ── Altura uterina
    if (au > 0 && semanas >= 20) {
      final evalAU = _Rangos.evaluarAU(semanas, au);
      if (evalAU == 'pequeño') {
        hallazgos.add(_Hallazgo.naranja(
          '⚠️ AU menor a lo esperado para $semanas semanas',
          'AU $au cm — esperada ~${semanas - 4} ± 2 cm. '
          'Descartar restricción del crecimiento intrauterino (RCIU). '
          'Solicitar ecografía con Doppler.',
        ));
      } else if (evalAU == 'grande') {
        hallazgos.add(_Hallazgo.naranja(
          '⚠️ AU mayor a lo esperado para $semanas semanas',
          'AU $au cm — esperada ~${semanas - 4} ± 2 cm. '
          'Descartar macrosomía, polihidramnios o embarazo múltiple.',
        ));
      } else {
        hallazgos.add(_Hallazgo.verde(
          '✅ Altura uterina adecuada',
          'AU $au cm — concordante con $semanas semanas.',
        ));
      }
    }

    // 5 ── Hemoglobina
    if (hb > 0) {
      if (_Rangos.anemiaSevera(hb)) {
        hallazgos.add(_Hallazgo.rojo(
          '🚨 Anemia severa (Hb ${hb.toStringAsFixed(1)} g/dL)',
          'Hb < 7 g/dL. Riesgo de parto pretérmino y muerte fetal. '
          'Transfusión puede ser necesaria. REMISIÓN URGENTE.',
        ));
      } else if (_Rangos.anemiaGestacional(hb)) {
        hallazgos.add(_Hallazgo.naranja(
          '⚠️ Anemia gestacional (Hb ${hb.toStringAsFixed(1)} g/dL)',
          'Hb entre 7–11 g/dL. Iniciar sulfato ferroso 300 mg/día + vitamina C. '
          'Control de hemoglobina en 4 semanas. Reforzar alimentación rica en hierro.',
        ));
      } else {
        hallazgos.add(_Hallazgo.verde(
          '✅ Hemoglobina normal (${hb.toStringAsFixed(1)} g/dL)',
          'Hb ≥ 11 g/dL — dentro del rango normal para gestación.',
        ));
      }
    }

    // 6 ── Ganancia de peso
    if (peso > 0 && pesoIni > 0 && semanas >= 14) {
      final eval = _Rangos.evaluarGananciaPeso(peso, pesoIni, semanas, _imcPre);
      if (eval == 'insuficiente') {
        hallazgos.add(_Hallazgo.naranja(
          '⚠️ Ganancia de peso insuficiente',
          'Ganancia ${(peso - pesoIni).toStringAsFixed(1)} kg a la semana $semanas. '
          'Por debajo de lo recomendado según IMC pregestacional ($_imcPre). '
          'Reforzar consejería nutricional. Evaluar náuseas y vómitos.',
        ));
      } else if (eval == 'excesiva') {
        hallazgos.add(_Hallazgo.naranja(
          '⚠️ Ganancia de peso excesiva',
          'Ganancia ${(peso - pesoIni).toStringAsFixed(1)} kg a la semana $semanas. '
          'Por encima de lo recomendado. Riesgo de macrosomía y diabetes gestacional. '
          'Consejería nutricional y actividad física adaptada.',
        ));
      } else if (eval == 'adecuada') {
        hallazgos.add(_Hallazgo.verde(
          '✅ Ganancia de peso adecuada',
          'Ganancia ${(peso - pesoIni).toStringAsFixed(1)} kg — dentro del rango recomendado.',
        ));
      }
    }

    // 7 ── Suplementación
    final suplementosFaltantes = <String>[];
    if (!_acidoFolico) suplementosFaltantes.add('ácido fólico');
    if (!_hierro)      suplementosFaltantes.add('hierro');
    if (!_calcio)      suplementosFaltantes.add('calcio');
    if (suplementosFaltantes.isNotEmpty) {
      hallazgos.add(_Hallazgo.naranja(
        '⚠️ Suplementación incompleta',
        'Faltan: ${suplementosFaltantes.join(', ')}. '
        'Según protocolo MINSALUD: ácido fólico 0.4 mg/día, sulfato ferroso 60 mg/día, '
        'calcio 1000 mg/día en zonas de riesgo de preeclampsia.',
      ));
    }

    // 8 ── Exámenes
    final examenesFaltantes = <String>[];
    if (!_vdrl)  examenesFaltantes.add('VDRL/sífilis');
    if (!_hiv)   examenesFaltantes.add('VIH');
    if (!_orina) examenesFaltantes.add('uroanálisis');
    if (semanas >= 18 && !_ecografia2T) examenesFaltantes.add('eco 2.° trimestre');
    if (semanas >= 32 && !_ecografia3T) examenesFaltantes.add('eco 3.° trimestre');
    if (examenesFaltantes.isNotEmpty) {
      hallazgos.add(_Hallazgo.naranja(
        '📋 Exámenes pendientes',
        'Faltan: ${examenesFaltantes.join(', ')}. '
        'Programar en la próxima consulta o en el nivel de atención correspondiente.',
      ));
    }

    // 9 ── Vacunación
    if (!_toxoide) {
      hallazgos.add(_Hallazgo.naranja(
        '💉 Toxoide tetánico pendiente',
        'Administrar toxoide tetánico/diftérico (Td) a partir de la semana 14–16. '
        'Esquema: 2 dosis con intervalo de 4 semanas si no ha sido vacunada.',
      ));
    }

    // 10 ── Si todo está bien
    if (hallazgos.every((h) => h.nivel == 'verde')) {
      hallazgos.insert(0, _Hallazgo.verde(
        '✅ Control prenatal sin hallazgos de alarma',
        'Gestante en semana $semanas sin signos de riesgo identificados. '
        'Continuar controles según RIAS: cada 4 semanas hasta semana 28, '
        'cada 2 semanas hasta semana 36, y semanal desde semana 36 hasta el parto.',
      ));
    }

    return hallazgos;
  }

  // ─── Guardar consulta ────────────────────────────────────────────────────
  Future<void> _analizarYGuardar() async {
    final hallazgos = _calcularHallazgos();
    setState(() => _hallazgos = hallazgos);

    if (_pacienteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('⚠️ Selecciona un paciente para guardar la consulta'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    setState(() => _guardando = true);

    final nivelRiesgo = hallazgos.any((h) => h.nivel == 'rojo')
        ? 'urgente'
        : hallazgos.any((h) => h.nivel == 'naranja')
            ? 'alerta'
            : 'normal';

    final diagnosticoTexto = hallazgos.map((h) => '${h.titulo}: ${h.detalle}').join(' | ');

    final datos = {
      'semanas':         _semanasCtrl.text.trim(),
      'edad_materna':    _edadCtrl.text.trim(),
      'paridad':         _paridad,
      'pa_sistolica':    _sistolicaCtrl.text.trim(),
      'pa_diastolica':   _diastolicaCtrl.text.trim(),
      'peso_actual':     _pesoCtrl.text.trim(),
      'peso_inicial':    _pesoInicialCtrl.text.trim(),
      'talla':           _tallaCtrl.text.trim(),
      'imc_pregestacional': _imcPre,
      'altura_uterina':  _auCtrl.text.trim(),
      'fcf':             _fcfCtrl.text.trim(),
      'hemoglobina':     _hbCtrl.text.trim(),
      'toxoide':         _toxoide,
      'acido_folico':    _acidoFolico,
      'hierro':          _hierro,
      'calcio':          _calcio,
      'ecografia_1t':    _ecografia1T,
      'ecografia_2t':    _ecografia2T,
      'ecografia_3t':    _ecografia3T,
      'vdrl':            _vdrl,
      'hiv':             _hiv,
      'orina':           _orina,
      'cefalea':         _cefalea,
      'edema_facial':    _edemaFacial,
      'vision_borrosa':  _visionBorrosa,
      'epigastralgia':   _epigastralgia,
      'sangrado':        _sangrado,
      'mov_fetal':       _movFetal,
      'observaciones':   _obsCtrl.text.trim(),
    };

    await DatabaseHelper.instance.insertarConsulta({
      'paciente_id':  _pacienteId,
      'modulo':       'Gestación',
      'fecha':        DateTime.now().toIso8601String(),
      'semanas':      _semanasCtrl.text.trim(),
      'presion':      '${_sistolicaCtrl.text.trim()}/${_diastolicaCtrl.text.trim()}',
      'peso':         _pesoCtrl.text.trim(),
      'talla':        _tallaCtrl.text.trim(),
      'datos_json':   jsonEncode(datos),
      'diagnostico':  diagnosticoTexto,
      'nivel_riesgo': nivelRiesgo,
      'observaciones':_obsCtrl.text.trim(),
    });

    setState(() => _guardando = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Control prenatal guardado para $_pacienteNombre ✓'),
        backgroundColor: nivelRiesgo == 'urgente' ? Colors.red : _kPink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  // ─── Remisión ────────────────────────────────────────────────────────────
  void _remitir() {
    final tieneUrgente = _hallazgos.any((h) => h.nivel == 'rojo');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kCard,
        title: Text(
          tieneUrgente ? '🚨 Remisión de emergencia' : 'Remitir a ginecobstetricia',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          tieneUrgente
              ? 'Esta paciente tiene hallazgos de EMERGENCIA. '
                '¿Confirmas la remisión URGENTE a ginecobstetricia?\n\n'
                'Se generará nota de remisión en el historial.'
              : '¿Confirmas la remisión de $_pacienteNombre a ginecobstetricia?\n\n'
                'Se generará nota de remisión en el historial.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: tieneUrgente ? Colors.red : _kPink),
            onPressed: () {
              Navigator.pop(context);
              if (_pacienteId != null) {
                DatabaseHelper.instance.insertarAlerta({
                  'modulo':   'Gestación',
                  'paciente': _pacienteNombre,
                  'mensaje':  'Remisión a ginecobstetricia — ${_hallazgos.isNotEmpty ? _hallazgos.first.titulo : "Control prenatal"}',
                  'nivel':    tieneUrgente ? 'urgente' : 'alerta',
                  'resuelta': 0,
                });
              }
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('Remisión registrada en alertas ✓'),
                backgroundColor: _kPink,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ));
            },
            child: const Text('Confirmar remisión', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (final c in [
      _semanasCtrl, _edadCtrl, _sistolicaCtrl, _diastolicaCtrl,
      _pesoCtrl, _tallaCtrl, _auCtrl, _fcfCtrl, _hbCtrl,
      _pesoInicialCtrl, _obsCtrl,
    ]) c.dispose();
    super.dispose();
  }

  // ─── UI ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kPink,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Gestación', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text('Control prenatal · Protocolos MINSALUD Colombia',
              style: TextStyle(color: Colors.white70, fontSize: 11)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(children: [

          // ── Selector de paciente ─────────────────────────────────────
          GestureDetector(
            onTap: _seleccionarPaciente,
            child: Container(
              width: double.infinity, padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _pacienteId != null ? _kPink.withOpacity(0.15) : _kCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _pacienteId != null ? _kPink : Colors.white24),
              ),
              child: Row(children: [
                Icon(_pacienteId != null ? Icons.person_rounded : Icons.person_add_outlined,
                    color: _pacienteId != null ? _kPink : Colors.white38, size: 22),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_pacienteId != null ? 'Paciente seleccionada' : 'Seleccionar paciente',
                      style: TextStyle(color: _pacienteId != null ? _kPink : Colors.white54, fontSize: 11)),
                  Text(_pacienteNombre,
                      style: TextStyle(color: _pacienteId != null ? Colors.white : Colors.white38,
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ])),
                Icon(Icons.chevron_right,
                    color: _pacienteId != null ? _kPink : Colors.white24, size: 20),
              ]),
            ),
          ),
          const SizedBox(height: 14),

          // ── Datos de la gestante ─────────────────────────────────────
          _Seccion(titulo: '👤 Datos de la gestante', children: [
            Row(children: [
              Expanded(child: _Campo(label: 'Semanas de gestación', ctrl: _semanasCtrl, tipo: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _Campo(label: 'Edad materna (años)', ctrl: _edadCtrl, tipo: TextInputType.number)),
            ]),
            const SizedBox(height: 12),
            _DropdownField(
              label: 'Paridad',
              value: _paridad,
              opciones: const ['Primigesta', 'Multigesta (2-4 partos)', 'Gran multigesta (≥5 partos)'],
              onChanged: (v) => setState(() => _paridad = v!),
            ),
          ]),
          const SizedBox(height: 14),

          // ── Signos vitales ───────────────────────────────────────────
          _Seccion(titulo: '❤️ Signos vitales', children: [
            Row(children: [
              Expanded(child: _Campo(label: 'PA sistólica (mmHg)', ctrl: _sistolicaCtrl, tipo: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _Campo(label: 'PA diastólica (mmHg)', ctrl: _diastolicaCtrl, tipo: TextInputType.number)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _Campo(label: 'FCF (lpm)', ctrl: _fcfCtrl, tipo: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _Campo(label: 'Hemoglobina (g/dL)', ctrl: _hbCtrl, tipo: const TextInputType.numberWithOptions(decimal: true))),
            ]),
          ]),
          const SizedBox(height: 14),

          // ── Medidas antropométricas ──────────────────────────────────
          _Seccion(titulo: '📏 Medidas antropométricas', children: [
            Row(children: [
              Expanded(child: _Campo(label: 'Peso actual (kg)', ctrl: _pesoCtrl, tipo: const TextInputType.numberWithOptions(decimal: true))),
              const SizedBox(width: 12),
              Expanded(child: _Campo(label: 'Peso pregestacional (kg)', ctrl: _pesoInicialCtrl, tipo: const TextInputType.numberWithOptions(decimal: true))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _Campo(label: 'Talla (cm)', ctrl: _tallaCtrl, tipo: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _Campo(label: 'Altura uterina (cm)', ctrl: _auCtrl, tipo: const TextInputType.numberWithOptions(decimal: true))),
            ]),
            const SizedBox(height: 12),
            _DropdownField(
              label: 'IMC pregestacional',
              value: _imcPre,
              opciones: const ['bajo', 'normal', 'sobrepeso', 'obesidad'],
              onChanged: (v) => setState(() => _imcPre = v!),
            ),
          ]),
          const SizedBox(height: 14),

          // ── Signos de alarma ─────────────────────────────────────────
          _Seccion(titulo: '🚨 Signos de alarma', children: [
            _Check(texto: 'Cefalea intensa (no cede con analgésicos)', activo: _cefalea, color: Colors.red, onChanged: (v) => setState(() => _cefalea = v)),
            _Check(texto: 'Visión borrosa o fotopsias', activo: _visionBorrosa, color: Colors.red, onChanged: (v) => setState(() => _visionBorrosa = v)),
            _Check(texto: 'Edema facial o de manos', activo: _edemaFacial, color: Colors.red, onChanged: (v) => setState(() => _edemaFacial = v)),
            _Check(texto: 'Epigastralgia / dolor en barra', activo: _epigastralgia, color: Colors.red, onChanged: (v) => setState(() => _epigastralgia = v)),
            _Check(texto: 'Sangrado vaginal activo', activo: _sangrado, color: Colors.red, onChanged: (v) => setState(() => _sangrado = v)),
            _Check(texto: 'Movimientos fetales presentes (≥semana 28)', activo: _movFetal, color: Colors.green, onChanged: (v) => setState(() => _movFetal = v)),
          ]),
          const SizedBox(height: 14),

          // ── Suplementación ───────────────────────────────────────────
          _Seccion(titulo: '💊 Suplementación', children: [
            _Check(texto: 'Ácido fólico 0.4 mg/día', activo: _acidoFolico, color: Colors.green, onChanged: (v) => setState(() => _acidoFolico = v)),
            _Check(texto: 'Sulfato ferroso 60 mg/día', activo: _hierro, color: Colors.green, onChanged: (v) => setState(() => _hierro = v)),
            _Check(texto: 'Calcio 1000 mg/día', activo: _calcio, color: Colors.green, onChanged: (v) => setState(() => _calcio = v)),
            _Check(texto: 'Toxoide tetánico/diftérico (Td) — 2 dosis', activo: _toxoide, color: Colors.green, onChanged: (v) => setState(() => _toxoide = v)),
          ]),
          const SizedBox(height: 14),

          // ── Exámenes paraclínicos ────────────────────────────────────
          _Seccion(titulo: '🔬 Paraclínicos realizados', children: [
            _Check(texto: 'Ecografía 1.° trimestre (< sem 14)', activo: _ecografia1T, color: Colors.green, onChanged: (v) => setState(() => _ecografia1T = v)),
            _Check(texto: 'Ecografía 2.° trimestre (sem 18–24)', activo: _ecografia2T, color: Colors.green, onChanged: (v) => setState(() => _ecografia2T = v)),
            _Check(texto: 'Ecografía 3.° trimestre (sem 30–34)', activo: _ecografia3T, color: Colors.green, onChanged: (v) => setState(() => _ecografia3T = v)),
            _Check(texto: 'VDRL / Sífilis', activo: _vdrl, color: Colors.green, onChanged: (v) => setState(() => _vdrl = v)),
            _Check(texto: 'VIH', activo: _hiv, color: Colors.green, onChanged: (v) => setState(() => _hiv = v)),
            _Check(texto: 'Uroanálisis / urocultivo', activo: _orina, color: Colors.green, onChanged: (v) => setState(() => _orina = v)),
          ]),
          const SizedBox(height: 14),

          // ── Observaciones ────────────────────────────────────────────
          _Seccion(titulo: '📝 Observaciones del promotor', children: [
            TextField(
              controller: _obsCtrl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Condiciones del domicilio, acceso a servicios, red de apoyo familiar...',
                hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                filled: true, fillColor: _kBorder,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ]),
          const SizedBox(height: 14),

          // ── Resultados ───────────────────────────────────────────────
          if (_hallazgos.isNotEmpty) ...[
            ..._hallazgos.map((h) => _TarjetaHallazgo(hallazgo: h)),
            const SizedBox(height: 8),
          ],

          // ── Botones ──────────────────────────────────────────────────
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              onPressed: _guardando ? null : _analizarYGuardar,
              icon: _guardando
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.psychology_outlined, color: Colors.white),
              label: Text(_guardando ? 'Guardando...' : 'Analizar y guardar control',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPink,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, height: 52,
            child: OutlinedButton.icon(
              onPressed: _remitir,
              icon: const Icon(Icons.local_hospital_outlined, color: Colors.white70),
              label: const Text('Remitir a ginecobstetricia',
                  style: TextStyle(color: Colors.white70, fontSize: 15)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 28),
        ]),
      ),
    );
  }
}

// ─── Modelo de hallazgo clínico ───────────────────────────────────────────
class _Hallazgo {
  final String nivel; // 'rojo' | 'naranja' | 'verde'
  final String titulo;
  final String detalle;

  const _Hallazgo({required this.nivel, required this.titulo, required this.detalle});

  factory _Hallazgo.rojo(String t, String d)    => _Hallazgo(nivel: 'rojo',    titulo: t, detalle: d);
  factory _Hallazgo.naranja(String t, String d) => _Hallazgo(nivel: 'naranja', titulo: t, detalle: d);
  factory _Hallazgo.verde(String t, String d)   => _Hallazgo(nivel: 'verde',   titulo: t, detalle: d);

  Color get color {
    switch (nivel) {
      case 'rojo':    return Colors.red;
      case 'naranja': return Colors.orange;
      default:        return Colors.green;
    }
  }
}

// ─── Widgets reutilizables ────────────────────────────────────────────────
class _TarjetaHallazgo extends StatelessWidget {
  final _Hallazgo hallazgo;
  const _TarjetaHallazgo({required this.hallazgo});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: hallazgo.color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: hallazgo.color.withOpacity(0.5)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(hallazgo.titulo,
          style: TextStyle(color: hallazgo.color, fontSize: 14, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      Text(hallazgo.detalle,
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.45)),
    ]),
  );
}

class _Seccion extends StatelessWidget {
  final String titulo;
  final List<Widget> children;
  const _Seccion({required this.titulo, required this.children});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF1E1E1E),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white10),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(titulo,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
      const SizedBox(height: 14),
      ...children,
    ]),
  );
}

class _Campo extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final TextInputType? tipo;
  const _Campo({required this.label, required this.ctrl, this.tipo});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
    const SizedBox(height: 4),
    TextField(
      controller: ctrl,
      keyboardType: tipo,
      inputFormatters: tipo == TextInputType.number ||
              tipo == const TextInputType.numberWithOptions(decimal: true)
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
          : null,
      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        filled: true, fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    ),
  ]);
}

class _DropdownField extends StatelessWidget {
  final String label, value;
  final List<String> opciones;
  final ValueChanged<String?> onChanged;
  const _DropdownField({required this.label, required this.value, required this.opciones, required this.onChanged});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
    const SizedBox(height: 4),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(10)),
      child: DropdownButton<String>(
        value: value, isExpanded: true, underline: const SizedBox(),
        dropdownColor: const Color(0xFF1E1E1E),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        items: opciones.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
        onChanged: onChanged,
      ),
    ),
  ]);
}

class _Check extends StatelessWidget {
  final String texto;
  final bool activo;
  final Color color;
  final ValueChanged<bool> onChanged;
  const _Check({required this.texto, required this.activo, required this.color, required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: GestureDetector(
      onTap: () => onChanged(!activo),
      child: Row(children: [
        Icon(
          activo ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          color: activo ? color : Colors.white24, size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(texto,
            style: TextStyle(color: activo ? Colors.white : Colors.white38, fontSize: 13))),
      ]),
    ),
  );
}
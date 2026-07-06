import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_theme.dart';
import '../core/responsive.dart';
import '../database/database_helper.dart';
import '../services/pdf_service.dart';

const Color _kVerdeHC = Color(0xFF1D9E75);

// ─────────────────────────────────────────────────────────────────────────────
// PANTALLA PRINCIPAL — Historia Clínica
// ─────────────────────────────────────────────────────────────────────────────
class HistoriaClinicaScreen extends StatefulWidget {
  final int?    pacienteId;
  final String? nombrePaciente;
  const HistoriaClinicaScreen({super.key, this.pacienteId, this.nombrePaciente});

  @override
  State<HistoriaClinicaScreen> createState() => _HistoriaClinicaScreenState();
}

class _HistoriaClinicaScreenState extends State<HistoriaClinicaScreen> {
  int  _tabActual        = 0;
  bool _guardando        = false;
  bool _exportando       = false;
  bool _hayDatosGuardados = false;

  // ── 0 — IDENTIFICACIÓN ───────────────────────────────────────────────────
  final _nombres         = TextEditingController();
  final _apellidos       = TextEditingController();
  String _tipoDoc        = 'Cédula de Ciudadanía';
  final _numDoc          = TextEditingController();
  final _fechaNac        = TextEditingController();
  final _edadCtrl        = TextEditingController();
  String _sexo           = '';
  String _estadoCivil    = '';
  String _grupoSanguineo = '';
  String _rh             = '';
  final _ocupacion       = TextEditingController();
  String _escolaridad    = '';
  final _direccion       = TextEditingController();
  final _ciudad          = TextEditingController();
  final _departamento    = TextEditingController();
  final _telefono        = TextEditingController();
  final _celular         = TextEditingController();
  final _correo          = TextEditingController();
  final _contactoNombre  = TextEditingController();
  final _contactoParent  = TextEditingController();
  final _contactoTel     = TextEditingController();
  String _tipoAfiliacion = 'Subsidiado';
  final _eps             = TextEditingController();
  final _numAfiliacion   = TextEditingController();

  // ── 1 — ANAMNESIS ────────────────────────────────────────────────────────
  final _motivoConsulta   = TextEditingController();
  final _enfermedadActual = TextEditingController();

  // ── 2 — ANTECEDENTES ────────────────────────────────────────────────────
  final _antPatologicos    = TextEditingController();
  final _antQuirurgicos    = TextEditingController();
  final _antTraumaticos    = TextEditingController();
  final _antAlergicos      = TextEditingController();
  final _antFarmacologicos = TextEditingController();
  final _antHospitalarios  = TextEditingController();
  final _antToxicologicos  = TextEditingController();
  final _inmunizaciones    = TextEditingController();
  final _antFamiliares     = TextEditingController();

  // ── 3 — GINECO-OBSTÉTRICO ───────────────────────────────────────────────
  final _menarquia      = TextEditingController();
  final _cicloMenstrual = TextEditingController();
  final _fur            = TextEditingController();
  final _gestaciones    = TextEditingController(text: '0');
  final _partos         = TextEditingController(text: '0');
  final _cesareas       = TextEditingController(text: '0');
  final _abortos        = TextEditingController(text: '0');
  final _planificacion  = TextEditingController();

  // ── 4 — REVISIÓN POR SISTEMAS ───────────────────────────────────────────
  final _sintGenerales     = TextEditingController();
  final _pielFaneras       = TextEditingController();
  final _ojos              = TextEditingController();
  final _oidos             = TextEditingController();
  final _respiratorio      = TextEditingController();
  final _cardiovascular    = TextEditingController();
  final _gastrointestinal  = TextEditingController();
  final _genitourinario    = TextEditingController();
  final _osteomuscular     = TextEditingController();
  final _neurologico       = TextEditingController();
  final _endocrino         = TextEditingController();
  final _hematologico      = TextEditingController();

  // ── 5 — EXAMEN FÍSICO ───────────────────────────────────────────────────
  final _presionArterial   = TextEditingController();
  final _frecCardiaca      = TextEditingController(); // sin tilde — sin late
  final _frecRespiratoria  = TextEditingController();
  final _temperatura       = TextEditingController();
  final _peso              = TextEditingController();
  final _talla             = TextEditingController();
  String _imc              = '';
  final _estadoGeneral     = TextEditingController();
  final _cabeza            = TextEditingController();
  final _cuello            = TextEditingController();
  final _torax             = TextEditingController();
  final _abdomen           = TextEditingController();
  final _extremidades      = TextEditingController();
  final _examNeurologico   = TextEditingController();

  // ── 6 — DIAGNÓSTICO ─────────────────────────────────────────────────────
  final _impresionDx    = TextEditingController();
  final _planManejo     = TextEditingController();
  final _ordenesLab     = TextEditingController();
  final _formulaMedica  = TextEditingController();
  final _imagenesRx     = TextEditingController();
  final _recomendaciones = TextEditingController();

  // ── 6b — REMISIÓN / TELEORIENTACIÓN ─────────────────────────────────────
  String _teleModalidad    = '';
  String _teleEspecialidad = '';

  static const List<(String, IconData)> _kModalidadesTele = [
    ('Telemedicina',        Icons.medical_services_outlined),
    ('Teleenfermería',      Icons.healing_outlined),
    ('Tele Bacteriología',  Icons.biotech_outlined),
    ('Tele Psicología',     Icons.psychology_outlined),
    ('Tele Fisioterapia',   Icons.accessibility_new_outlined),
    ('Tele Odontología',    Icons.medical_information_outlined),
    ('Tele Trabajo Social', Icons.groups_outlined),
    ('Tele Especialista',   Icons.local_hospital_outlined),
  ];

  static const List<String> _kEspecialidadesTele = [
    'Pediatría',
    'Medicina Interna',
    'Ginecología y Obstetricia',
    'Cardiología',
    'Dermatología',
    'Neurología',
    'Psiquiatría',
    'Ortopedia y Traumatología',
    'Otorrinolaringología',
    'Oftalmología',
    'Endocrinología',
    'Nutrición y Dietética',
    'Urología',
    'Geriatría',
    'Cirugía General',
    'Medicina Familiar',
    'Infectología',
    'Nefrología',
    'Neumología',
    'Gastroenterología',
  ];

  // ── Tabs ──────────────────────────────────────────────────────────────────
  static const List<(String, IconData)> _kTabs = [
    ('Identificación', Icons.person_outlined),
    ('Anamnesis',      Icons.medical_information_outlined),
    ('Antecedentes',   Icons.history_edu_rounded),
    ('Gineco-Obst.',   Icons.pregnant_woman_rounded),
    ('Rev. Sistemas',  Icons.manage_search_rounded),
    ('Examen Físico',  Icons.monitor_heart_outlined),
    ('Diagnóstico',    Icons.assignment_outlined),
  ];

  // ── Lista de todos los controladores para dispose/limpiar ────────────────
  List<TextEditingController> get _todos => [
    _nombres, _apellidos, _numDoc, _fechaNac, _edadCtrl, _ocupacion,
    _direccion, _ciudad, _departamento, _telefono, _celular, _correo,
    _contactoNombre, _contactoParent, _contactoTel, _eps, _numAfiliacion,
    _motivoConsulta, _enfermedadActual,
    _antPatologicos, _antQuirurgicos, _antTraumaticos, _antAlergicos,
    _antFarmacologicos, _antHospitalarios, _antToxicologicos,
    _inmunizaciones, _antFamiliares,
    _menarquia, _cicloMenstrual, _fur,
    _gestaciones, _partos, _cesareas, _abortos, _planificacion,
    _sintGenerales, _pielFaneras, _ojos, _oidos, _respiratorio,
    _cardiovascular, _gastrointestinal, _genitourinario, _osteomuscular,
    _neurologico, _endocrino, _hematologico,
    _presionArterial, _frecCardiaca, _frecRespiratoria, _temperatura,
    _peso, _talla, _estadoGeneral, _cabeza, _cuello, _torax,
    _abdomen, _extremidades, _examNeurologico,
    _impresionDx, _planManejo, _ordenesLab, _formulaMedica,
    _imagenesRx, _recomendaciones,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.nombrePaciente != null) {
      final p = widget.nombrePaciente!.split(' ');
      _nombres.text   = p.first;
      _apellidos.text = p.length > 1 ? p.skip(1).join(' ') : '';
    }
    _peso.addListener(_calcIMC);
    _talla.addListener(_calcIMC);
    if (widget.pacienteId != null) _cargarDatos();
  }

  @override
  void dispose() {
    for (final c in _todos) c.dispose();
    super.dispose();
  }

  void _calcIMC() {
    final p = double.tryParse(_peso.text);
    final t = double.tryParse(_talla.text);
    if (p != null && t != null && t > 0) {
      final tm = t / 100;
      if (mounted) setState(() => _imc = (p / (tm * tm)).toStringAsFixed(1));
    } else {
      if (mounted) setState(() => _imc = '');
    }
  }

  String _imcLabel(String s) {
    final v = double.tryParse(s) ?? 0;
    if (v < 18.5) return 'Bajo peso';
    if (v < 25.0) return 'Normal';
    if (v < 30.0) return 'Sobrepeso';
    return 'Obesidad';
  }

  // ── Cargar datos previos de BD ───────────────────────────────────────────
  Future<void> _cargarDatos() async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.execute('''
        CREATE TABLE IF NOT EXISTS historia_clinica (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          paciente_id INTEGER,
          datos_json TEXT,
          fecha TEXT
        )
      ''');
      final rows = await db.query(
        'historia_clinica',
        where: 'paciente_id = ?',
        whereArgs: [widget.pacienteId],
        orderBy: 'fecha DESC',
        limit: 1,
      );
      if (rows.isNotEmpty) {
        final data = json.decode(rows.first['datos_json'] as String? ?? '{}') as Map;
        _llenar(data);
        if (mounted) setState(() => _hayDatosGuardados = true);
      }
    } catch (_) {}
  }

  void _llenar(Map d) {
    _nombres.text          = d['nombres']            ?? '';
    _apellidos.text        = d['apellidos']          ?? '';
    _tipoDoc               = d['tipo_doc']            ?? 'Cédula de Ciudadanía';
    _numDoc.text           = d['num_doc']             ?? '';
    _fechaNac.text         = d['fecha_nac']           ?? '';
    _edadCtrl.text         = d['edad']               ?? '';
    _sexo                  = d['sexo']               ?? '';
    _estadoCivil           = d['estado_civil']        ?? '';
    _grupoSanguineo        = d['grupo_sanguineo']     ?? '';
    _rh                    = d['rh']                 ?? '';
    _ocupacion.text        = d['ocupacion']           ?? '';
    _escolaridad           = d['escolaridad']         ?? '';
    _direccion.text        = d['direccion']           ?? '';
    _ciudad.text           = d['ciudad']             ?? '';
    _departamento.text     = d['departamento']        ?? '';
    _telefono.text         = d['telefono']            ?? '';
    _celular.text          = d['celular']             ?? '';
    _correo.text           = d['correo']             ?? '';
    _contactoNombre.text   = d['contacto_nombre']     ?? '';
    _contactoParent.text   = d['contacto_parent']     ?? '';
    _contactoTel.text      = d['contacto_tel']        ?? '';
    _tipoAfiliacion        = d['tipo_afiliacion']     ?? 'Subsidiado';
    _eps.text              = d['eps']                ?? '';
    _numAfiliacion.text    = d['num_afiliacion']      ?? '';
    _motivoConsulta.text   = d['motivo']             ?? '';
    _enfermedadActual.text = d['enfermedad']          ?? '';
    _antPatologicos.text   = d['ant_patologicos']     ?? '';
    _antQuirurgicos.text   = d['ant_quirurgicos']     ?? '';
    _antTraumaticos.text   = d['ant_traumaticos']     ?? '';
    _antAlergicos.text     = d['ant_alergicos']       ?? '';
    _antFarmacologicos.text= d['ant_farmacologicos']  ?? '';
    _antHospitalarios.text = d['ant_hospitalarios']   ?? '';
    _antToxicologicos.text = d['ant_toxicologicos']   ?? '';
    _inmunizaciones.text   = d['inmunizaciones']      ?? '';
    _antFamiliares.text    = d['ant_familiares']      ?? '';
    _menarquia.text        = d['menarquia']           ?? '';
    _cicloMenstrual.text   = d['ciclo_menstrual']     ?? '';
    _fur.text              = d['fur']                ?? '';
    _gestaciones.text      = d['gestaciones']         ?? '0';
    _partos.text           = d['partos']             ?? '0';
    _cesareas.text         = d['cesareas']            ?? '0';
    _abortos.text          = d['abortos']             ?? '0';
    _planificacion.text    = d['planificacion']       ?? '';
    _sintGenerales.text    = d['sint_generales']      ?? '';
    _pielFaneras.text      = d['piel_faneras']        ?? '';
    _ojos.text             = d['ojos']               ?? '';
    _oidos.text            = d['oidos']              ?? '';
    _respiratorio.text     = d['respiratorio']        ?? '';
    _cardiovascular.text   = d['cardiovascular']      ?? '';
    _gastrointestinal.text = d['gastrointestinal']    ?? '';
    _genitourinario.text   = d['genitourinario']      ?? '';
    _osteomuscular.text    = d['osteomuscular']       ?? '';
    _neurologico.text      = d['neurologico']         ?? '';
    _endocrino.text        = d['endocrino']           ?? '';
    _hematologico.text     = d['hematologico']        ?? '';
    _presionArterial.text  = d['presion']             ?? '';
    _frecCardiaca.text     = d['frec_cardiaca']       ?? '';
    _frecRespiratoria.text = d['frec_resp']           ?? '';
    _temperatura.text      = d['temperatura']         ?? '';
    _peso.text             = d['peso']               ?? '';
    _talla.text            = d['talla']              ?? '';
    _imc                   = d['imc']                ?? '';
    _estadoGeneral.text    = d['estado_general']      ?? '';
    _cabeza.text           = d['cabeza']             ?? '';
    _cuello.text           = d['cuello']             ?? '';
    _torax.text            = d['torax']              ?? '';
    _abdomen.text          = d['abdomen']             ?? '';
    _extremidades.text     = d['extremidades']        ?? '';
    _examNeurologico.text  = d['exam_neuro']          ?? '';
    _impresionDx.text      = d['impresion_dx']        ?? '';
    _planManejo.text       = d['plan_manejo']         ?? '';
    _ordenesLab.text       = d['ordenes_lab']         ?? '';
    _formulaMedica.text    = d['formula_medica']      ?? '';
    _imagenesRx.text       = d['imagenes_rx']         ?? '';
    _recomendaciones.text  = d['recomendaciones']     ?? '';
    _teleModalidad          = d['tele_modalidad']     ?? '';
    _teleEspecialidad       = d['tele_especialidad']  ?? '';
    setState(() {});
  }

  Map<String, dynamic> _recolectar() => {
    'nombres': _nombres.text,           'apellidos': _apellidos.text,
    'tipo_doc': _tipoDoc,               'num_doc': _numDoc.text,
    'fecha_nac': _fechaNac.text,        'edad': _edadCtrl.text,
    'sexo': _sexo,                      'estado_civil': _estadoCivil,
    'grupo_sanguineo': _grupoSanguineo, 'rh': _rh,
    'ocupacion': _ocupacion.text,       'escolaridad': _escolaridad,
    'direccion': _direccion.text,       'ciudad': _ciudad.text,
    'departamento': _departamento.text, 'telefono': _telefono.text,
    'celular': _celular.text,           'correo': _correo.text,
    'contacto_nombre': _contactoNombre.text,
    'contacto_parent': _contactoParent.text,
    'contacto_tel': _contactoTel.text,
    'tipo_afiliacion': _tipoAfiliacion, 'eps': _eps.text,
    'num_afiliacion': _numAfiliacion.text,
    'motivo': _motivoConsulta.text,     'enfermedad': _enfermedadActual.text,
    'ant_patologicos': _antPatologicos.text,
    'ant_quirurgicos': _antQuirurgicos.text,
    'ant_traumaticos': _antTraumaticos.text,
    'ant_alergicos': _antAlergicos.text,
    'ant_farmacologicos': _antFarmacologicos.text,
    'ant_hospitalarios': _antHospitalarios.text,
    'ant_toxicologicos': _antToxicologicos.text,
    'inmunizaciones': _inmunizaciones.text,
    'ant_familiares': _antFamiliares.text,
    'menarquia': _menarquia.text,       'ciclo_menstrual': _cicloMenstrual.text,
    'fur': _fur.text,                   'gestaciones': _gestaciones.text,
    'partos': _partos.text,             'cesareas': _cesareas.text,
    'abortos': _abortos.text,           'planificacion': _planificacion.text,
    'sint_generales': _sintGenerales.text,
    'piel_faneras': _pielFaneras.text,  'ojos': _ojos.text,
    'oidos': _oidos.text,               'respiratorio': _respiratorio.text,
    'cardiovascular': _cardiovascular.text,
    'gastrointestinal': _gastrointestinal.text,
    'genitourinario': _genitourinario.text,
    'osteomuscular': _osteomuscular.text,
    'neurologico': _neurologico.text,   'endocrino': _endocrino.text,
    'hematologico': _hematologico.text,
    'presion': _presionArterial.text,   'frec_cardiaca': _frecCardiaca.text,
    'frec_resp': _frecRespiratoria.text,'temperatura': _temperatura.text,
    'peso': _peso.text,                 'talla': _talla.text,
    'imc': _imc,                        'estado_general': _estadoGeneral.text,
    'cabeza': _cabeza.text,             'cuello': _cuello.text,
    'torax': _torax.text,               'abdomen': _abdomen.text,
    'extremidades': _extremidades.text, 'exam_neuro': _examNeurologico.text,
    'impresion_dx': _impresionDx.text,  'plan_manejo': _planManejo.text,
    'ordenes_lab': _ordenesLab.text,    'formula_medica': _formulaMedica.text,
    'imagenes_rx': _imagenesRx.text,    'recomendaciones': _recomendaciones.text,
    'tele_modalidad': _teleModalidad,   'tele_especialidad': _teleEspecialidad,
  };

  // ── Guardar ──────────────────────────────────────────────────────────────
  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      final db      = await DatabaseHelper.instance.database;
      final jsonStr = json.encode(_recolectar());

      await DatabaseHelper.instance.guardarHistoriaClinica(
          widget.pacienteId, jsonStr);

      // Sincronizar datos básicos en tabla pacientes
      if (widget.pacienteId != null) {
        await db.update(
          'pacientes',
          {
            'nombre':      '${_nombres.text} ${_apellidos.text}'.trim(),
            'documento':   _numDoc.text,
            'fecha_nac':   _fechaNac.text,
            'sexo':        _sexo,
            'telefono':    _celular.text,
            'eps':         _eps.text,
            'departamento': _departamento.text,
            'municipio':   _ciudad.text,
          },
          where: 'id = ?',
          whereArgs: [widget.pacienteId],
        );
      }

      if (mounted) {
        setState(() { _guardando = false; _hayDatosGuardados = true; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Historia clínica guardada correctamente'),
          ]),
          backgroundColor: _kVerdeHC,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  // ── Exportar a PDF ───────────────────────────────────────────────────────
  Future<void> _exportarPdf() async {
    final nombreCompleto = '${_nombres.text} ${_apellidos.text}'.trim();
    if (nombreCompleto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Ingresa al menos el nombre del paciente antes de exportar'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _exportando = true);
    try {
      await PdfService.generarHistoriaClinicaPdf(
        context: context,
        pacienteNombre: nombreCompleto,
        datos: _recolectar(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al generar PDF: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  // ── Limpiar ──────────────────────────────────────────────────────────────
  void _limpiarTodo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DT(context).card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Limpiar todo?'),
        content: const Text(
            'Se borrarán los campos. Los datos ya guardados no se eliminan.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              for (final c in _todos) c.clear();
              setState(() {
                _sexo = ''; _estadoCivil = ''; _grupoSanguineo = '';
                _rh = ''; _escolaridad = ''; _tipoAfiliacion = 'Subsidiado';
                _imc = '';
                _gestaciones.text = '0'; _partos.text = '0';
                _cesareas.text = '0';    _abortos.text = '0';
                _teleModalidad = ''; _teleEspecialidad = '';
              });
            },
            child: const Text('Limpiar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final dt = DT(context);
    return Scaffold(
      backgroundColor: dt.bg,
      body: Column(children: [
        _buildHeader(dt),
        _buildTabs(dt),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: KeyedSubtree(
              key: ValueKey(_tabActual),
              child: ResponsiveCenter(maxWidth: 800, child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: [
                  _buildIdentificacion(dt),
                  _buildAnamnesis(dt),
                  _buildAntecedentes(dt),
                  _buildGinecoObst(dt),
                  _buildRevSistemas(dt),
                  _buildExamenFisico(dt),
                  _buildDiagnostico(dt),
                ][_tabActual],
              ), ),
            ),
          ),
        ),
      ]),
      bottomNavigationBar: _buildBottomBar(dt),
    );
  }

  // ── HEADER ───────────────────────────────────────────────────────────────
  Widget _buildHeader(DispersaludColors dt) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A5240), Color(0xFF1D9E75)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.assignment_rounded,
                        color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('Historia Clínica',
                        style: TextStyle(color: Colors.white,
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ]),
                  Text(
                    widget.nombrePaciente != null
                        ? 'Paciente: ${widget.nombrePaciente}'
                        : 'Registro completo · formato colombiano',
                    style: const TextStyle(
                        color: Color(0xFF9FE1CB), fontSize: 11),
                  ),
                ],
              ),
            ),
            if (_hayDatosGuardados)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white30),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_circle_rounded,
                      color: Color(0xFF9FE1CB), size: 14),
                  SizedBox(width: 4),
                  Text('Guardada',
                      style: TextStyle(color: Color(0xFF9FE1CB),
                          fontSize: 11, fontWeight: FontWeight.w600)),
                ]),
              ),
          ]),
        ),
      ),
    );
  }

  // ── TABS ─────────────────────────────────────────────────────────────────
  Widget _buildTabs(DispersaludColors dt) {
    return Container(
      color: dt.card,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: _kTabs.asMap().entries.map((e) {
            final activo = _tabActual == e.key;
            return GestureDetector(
              onTap: () => setState(() => _tabActual = e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: activo ? _kVerdeHC : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: activo ? _kVerdeHC : dt.border,
                      width: 1.2),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(e.value.$2,
                      color: activo ? Colors.white : dt.textHint,
                      size: 14),
                  const SizedBox(width: 5),
                  Text(e.value.$1,
                      style: TextStyle(
                        color: activo ? Colors.white : dt.textSecondary,
                        fontSize: 12,
                        fontWeight: activo
                            ? FontWeight.w700
                            : FontWeight.normal,
                      )),
                ]),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── BOTTOM BAR ───────────────────────────────────────────────────────────
  Widget _buildBottomBar(DispersaludColors dt) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: dt.card,
        border: Border(top: BorderSide(color: dt.border)),
      ),
      child: Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _limpiarTodo,
            icon: const Icon(Icons.delete_outline_rounded,
                color: Colors.red, size: 18),
            label: const Text('Limpiar Todo',
                style: TextStyle(color: Colors.red, fontSize: 13)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _guardando ? null : _guardar,
            icon: _guardando
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.save_rounded, size: 18),
            label: Text(
                _guardando ? 'Guardando...' : 'Guardar Cambios',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kVerdeHC,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _exportando ? null : _exportarPdf,
          child: Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFB0413E).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFFB0413E).withOpacity(0.3)),
            ),
            child: _exportando
                ? const Padding(
                    padding: EdgeInsets.all(13),
                    child: CircularProgressIndicator(
                        color: Color(0xFFB0413E), strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_outlined,
                    color: Color(0xFFB0413E), size: 20),
          ),
        ),
        if (_tabActual < _kTabs.length - 1) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _tabActual++),
            child: Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: _kVerdeHC.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kVerdeHC.withOpacity(0.3)),
              ),
              child: const Icon(Icons.arrow_forward_rounded,
                  color: _kVerdeHC, size: 20),
            ),
          ),
        ],
      ]),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // SECCIONES
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildIdentificacion(DispersaludColors dt) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _hcTitulo('Datos de Identificación del Paciente',
          Icons.person_outlined, dt),
      Row(children: [
        Expanded(child: _hcCampo('Nombres *', 'Nombres completos', _nombres, dt)),
        const SizedBox(width: 12),
        Expanded(child: _hcCampo('Apellidos *', 'Apellidos completos', _apellidos, dt)),
      ]),
      Row(children: [
        Expanded(flex: 2, child: _hcDropdown('Tipo de Documento *', _tipoDoc,
            ['Cédula de Ciudadanía', 'Tarjeta de Identidad', 'Registro Civil',
             'Cédula Extranjería', 'Pasaporte', 'NUIP', 'Sin documento'],
            (v) => setState(() => _tipoDoc = v!), dt)),
        const SizedBox(width: 12),
        Expanded(child: _hcCampo('N° Documento *', 'Número', _numDoc, dt,
            tipo: TextInputType.number)),
        const SizedBox(width: 12),
        Expanded(child: _hcCampo('Fecha Nacimiento *', 'dd/mm/aaaa',
            _fechaNac, dt)),
      ]),
      Row(children: [
        Expanded(child: _hcCampo('Edad', 'Años', _edadCtrl, dt,
            tipo: TextInputType.number)),
        const SizedBox(width: 12),
        Expanded(child: _hcDropdown('Sexo *', _sexo,
            ['', 'Masculino', 'Femenino', 'Intersexual'],
            (v) => setState(() => _sexo = v!), dt, hint: 'Seleccione')),
        const SizedBox(width: 12),
        Expanded(child: _hcDropdown('Estado Civil', _estadoCivil,
            ['', 'Soltero/a', 'Casado/a', 'Unión libre',
             'Separado/a', 'Divorciado/a', 'Viudo/a'],
            (v) => setState(() => _estadoCivil = v!), dt,
            hint: 'Seleccione')),
        const SizedBox(width: 12),
        Expanded(child: Row(children: [
          Expanded(child: _hcDropdown('G.S.', _grupoSanguineo,
              ['', 'A', 'B', 'AB', 'O'],
              (v) => setState(() => _grupoSanguineo = v!), dt, hint: 'GS')),
          const SizedBox(width: 6),
          Expanded(child: _hcDropdown('Rh', _rh, ['', '+', '-'],
              (v) => setState(() => _rh = v!), dt, hint: 'Rh')),
        ])),
      ]),
      Row(children: [
        Expanded(child: _hcCampo('Ocupación', 'Ocupación actual', _ocupacion, dt)),
        const SizedBox(width: 12),
        Expanded(child: _hcDropdown('Escolaridad', _escolaridad,
            ['', 'Sin escolaridad', 'Primaria incompleta', 'Primaria completa',
             'Secundaria incompleta', 'Secundaria completa',
             'Técnico/Tecnólogo', 'Universitario', 'Posgrado'],
            (v) => setState(() => _escolaridad = v!), dt,
            hint: 'Seleccione')),
      ]),
      const SizedBox(height: 16),
      _hcTitulo('Datos de Contacto', Icons.location_on_outlined, dt),
      _hcCampo('Dirección de Residencia', 'Dirección completa', _direccion, dt),
      Row(children: [
        Expanded(child: _hcCampo('Ciudad / Municipio', 'Ciudad', _ciudad, dt)),
        const SizedBox(width: 12),
        Expanded(child: _hcCampo('Departamento', 'Departamento', _departamento, dt)),
        const SizedBox(width: 12),
        Expanded(child: _hcCampo('Teléfono fijo', 'Teléfono', _telefono, dt,
            tipo: TextInputType.phone)),
      ]),
      Row(children: [
        Expanded(child: _hcCampo('Celular', 'Número celular', _celular, dt,
            tipo: TextInputType.phone)),
        const SizedBox(width: 12),
        Expanded(child: _hcCampo('Correo Electrónico', 'correo@ejemplo.com',
            _correo, dt, tipo: TextInputType.emailAddress)),
      ]),
      const SizedBox(height: 16),
      _hcTitulo('Contacto de Emergencia', Icons.emergency_rounded, dt),
      Row(children: [
        Expanded(child: _hcCampo('Nombre Completo', 'Nombre del contacto',
            _contactoNombre, dt)),
        const SizedBox(width: 12),
        Expanded(child: _hcCampo('Parentesco', 'Relación', _contactoParent, dt)),
        const SizedBox(width: 12),
        Expanded(child: _hcCampo('Teléfono', 'Número de contacto',
            _contactoTel, dt, tipo: TextInputType.phone)),
      ]),
      const SizedBox(height: 16),
      _hcTitulo('Datos del Régimen de Salud',
          Icons.health_and_safety_outlined, dt),
      Row(children: [
        Expanded(child: _hcDropdown('Tipo de Afiliación', _tipoAfiliacion,
            ['Contributivo', 'Subsidiado', 'No asegurado', 'Especial',
             'Vinculado'],
            (v) => setState(() => _tipoAfiliacion = v!), dt)),
        const SizedBox(width: 12),
        Expanded(child: _hcCampo('EPS', 'Nombre de la EPS', _eps, dt)),
        const SizedBox(width: 12),
        Expanded(child: _hcCampo('N° Afiliación', 'Número', _numAfiliacion, dt)),
      ]),
      _hcAviso(dt),
    ]);
  }

  Widget _buildAnamnesis(DispersaludColors dt) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _hcTitulo('Anamnesis', Icons.medical_information_outlined, dt,
          sub: 'Motivo de consulta y enfermedad actual'),
      _hcGrande('Motivo de Consulta *',
          'Describa el motivo de la consulta', _motivoConsulta, dt,
          minLines: 3),
      _hcGrande('Enfermedad Actual',
          'Describa la enfermedad actual con cronología, síntomas, evolución...',
          _enfermedadActual, dt, minLines: 5),
      _hcAviso(dt),
    ]);
  }

  Widget _buildAntecedentes(DispersaludColors dt) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _hcTitulo('Antecedentes Personales', Icons.history_edu_rounded, dt),
      _hcGrande('Antecedentes Patológicos',
          'Enfermedades previas (HTA, DM, asma, etc.)', _antPatologicos, dt),
      _hcGrande('Antecedentes Quirúrgicos',
          'Cirugías previas con fechas', _antQuirurgicos, dt),
      _hcGrande('Antecedentes Traumáticos',
          'Traumas o accidentes previos', _antTraumaticos, dt),
      _hcGrande('Antecedentes Alérgicos',
          'Alergias a medicamentos, alimentos, otros', _antAlergicos, dt),
      _hcGrande('Antecedentes Farmacológicos',
          'Medicamentos que toma actualmente', _antFarmacologicos, dt),
      _hcGrande('Antecedentes Hospitalarios',
          'Hospitalizaciones previas', _antHospitalarios, dt),
      _hcGrande('Antecedentes Toxicológicos',
          'Consumo de tabaco, alcohol, drogas', _antToxicologicos, dt),
      _hcGrande('Inmunizaciones', 'Vacunas recibidas', _inmunizaciones, dt),
      const SizedBox(height: 16),
      _hcTitulo('Antecedentes Familiares', Icons.family_restroom_rounded, dt),
      _hcGrande('Antecedentes Familiares',
          'Enfermedades en familiares de primer grado: HTA, DM, cáncer, cardiovasculares, etc.',
          _antFamiliares, dt, minLines: 4),
      _hcAviso(dt),
    ]);
  }

  Widget _buildGinecoObst(DispersaludColors dt) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _hcTitulo('Antecedentes Gineco-Obstétricos',
          Icons.pregnant_woman_rounded, dt,
          sub: 'Solo para pacientes de sexo femenino'),
      Row(children: [
        Expanded(child: _hcCampo('Menarquia (años)',
            'Edad primera menstruación', _menarquia, dt,
            tipo: TextInputType.number)),
        const SizedBox(width: 12),
        Expanded(child: _hcCampo('Ciclo Menstrual',
            'Ej: Regular 28 días', _cicloMenstrual, dt)),
        const SizedBox(width: 12),
        Expanded(child: _hcCampo('FUR', 'dd/mm/aaaa', _fur, dt)),
      ]),
      const SizedBox(height: 8),
      _hcTitulo('Fórmula Obstétrica (G-P-C-A)',
          Icons.calculate_outlined, dt, small: true),
      Row(children: [
        Expanded(child: _hcNum('Gestaciones (G)', _gestaciones, dt)),
        const SizedBox(width: 12),
        Expanded(child: _hcNum('Partos (P)', _partos, dt)),
        const SizedBox(width: 12),
        Expanded(child: _hcNum('Cesáreas (C)', _cesareas, dt)),
        const SizedBox(width: 12),
        Expanded(child: _hcNum('Abortos (A)', _abortos, dt)),
      ]),
      _hcCampo('Método de Planificación Familiar',
          'Método anticonceptivo actual', _planificacion, dt),
      _hcAviso(dt),
    ]);
  }

  Widget _buildRevSistemas(DispersaludColors dt) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _hcTitulo('Revisión por Sistemas', Icons.manage_search_rounded, dt,
          sub: 'Registre síntomas relevantes por cada sistema'),
      _hcGrande('Síntomas Generales',
          'Fiebre, fatiga, pérdida de peso, astenia, adinamia',
          _sintGenerales, dt),
      _hcGrande('Piel y Faneras',
          'Erupciones, cambios de color, prurito, cambios en uñas o cabello',
          _pielFaneras, dt),
      _hcGrande('Ojos', 'Cambios en visión, dolor, enrojecimiento, secreción',
          _ojos, dt),
      _hcGrande('Oídos, Nariz, Garganta',
          'Dolor de oído, rinorrea, epistaxis, dolor de garganta', _oidos, dt),
      _hcGrande('Sistema Respiratorio',
          'Tos, disnea, sibilancias, dolor torácico, expectoración',
          _respiratorio, dt),
      _hcGrande('Sistema Cardiovascular',
          'Palpitaciones, dolor precordial, disnea de esfuerzo, edema',
          _cardiovascular, dt),
      _hcGrande('Sistema Gastrointestinal',
          'Náuseas, vómito, diarrea, estreñimiento, dolor abdominal',
          _gastrointestinal, dt),
      _hcGrande('Sistema Genitourinario',
          'Disuria, hematuria, poliuria, incontinencia, secreciones',
          _genitourinario, dt),
      _hcGrande('Sistema Osteomuscular',
          'Dolor articular, rigidez, limitación al movimiento',
          _osteomuscular, dt),
      _hcGrande('Sistema Neurológico',
          'Cefalea, mareos, convulsiones, parestesias, debilidad',
          _neurologico, dt),
      _hcGrande('Sistema Endocrino',
          'Poliuria, polidipsia, intolerancia al calor/frío', _endocrino, dt),
      _hcGrande('Sistema Hematológico',
          'Hematomas, sangrados, adenopatías', _hematologico, dt),
      _hcAviso(dt),
    ]);
  }

  Widget _buildExamenFisico(DispersaludColors dt) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _hcTitulo('Examen Físico', Icons.monitor_heart_outlined, dt),
      _hcTitulo('Signos Vitales y Antropometría',
          Icons.favorite_border_rounded, dt, small: true),
      Row(children: [
        Expanded(child: _hcCampo('Presión Arterial', '120/80 mmHg',
            _presionArterial, dt)),
        const SizedBox(width: 12),
        Expanded(child: _hcCampo('Frec. Cardíaca', '70 lpm',
            _frecCardiaca, dt, tipo: TextInputType.number)),
        const SizedBox(width: 12),
        Expanded(child: _hcCampo('Frec. Respiratoria', '16 rpm',
            _frecRespiratoria, dt, tipo: TextInputType.number)),
        const SizedBox(width: 12),
        Expanded(child: _hcCampo('Temperatura', '36.5 °C',
            _temperatura, dt, tipo: TextInputType.number)),
      ]),
      Row(children: [
        Expanded(child: _hcCampo('Peso (kg)', '70', _peso, dt,
            tipo: TextInputType.number)),
        const SizedBox(width: 12),
        Expanded(child: _hcCampo('Talla (cm)', '170', _talla, dt,
            tipo: TextInputType.number)),
        const SizedBox(width: 12),
        Expanded(child: _hcIMC(dt)),
        const SizedBox(width: 12),
        const Expanded(child: SizedBox()),
      ]),
      const SizedBox(height: 8),
      _hcGrande('Estado General',
          'Apariencia general, estado de conciencia, actitud, facies',
          _estadoGeneral, dt),
      _hcGrande('Cabeza y Cuero Cabelludo',
          'Normocéfalo, sin masas ni lesiones', _cabeza, dt),
      _hcGrande('Cuello',
          'Simétrico, sin adenopatías, tiroides normal', _cuello, dt),
      _hcGrande('Tórax (Pulmones y Corazón)',
          'Murmullo vesicular conservado, ruidos cardíacos rítmicos',
          _torax, dt),
      _hcGrande('Abdomen',
          'Blando, depresible, no doloroso, sin masas', _abdomen, dt),
      _hcGrande('Extremidades',
          'Simétricas, sin edema, pulsos presentes', _extremidades, dt),
      _hcGrande('Neurológico',
          'Consciente, orientado, fuerza y sensibilidad conservadas',
          _examNeurologico, dt),
      _hcAviso(dt),
    ]);
  }

  Widget _buildDiagnostico(DispersaludColors dt) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _hcTitulo('Impresión Diagnóstica y Plan de Manejo',
          Icons.assignment_outlined, dt),
      _hcGrande('Impresión Diagnóstica *',
          'Diagnóstico principal y diferenciales con códigos CIE-10',
          _impresionDx, dt, minLines: 3),
      _hcGrande('Plan de Manejo', 'Plan terapéutico general',
          _planManejo, dt, minLines: 3),
      const SizedBox(height: 16),
      _hcTitulo('Órdenes Médicas', Icons.edit_note_rounded, dt),
      _hcGrande('Órdenes de Laboratorio',
          'Cuadro hemático, glicemia, pruebas hepáticas, etc.',
          _ordenesLab, dt),
      _hcGrande('Fórmula Médica',
          'Medicamentos con dosis, vía y frecuencia',
          _formulaMedica, dt, minLines: 3),
      _hcGrande('Órdenes de Imágenes Diagnósticas',
          'Radiografías, ecografías, TAC, resonancias, etc.',
          _imagenesRx, dt),
      _hcGrande('Recomendaciones y Educación al Paciente',
          'Indicaciones generales, signos de alarma, cuidados en casa',
          _recomendaciones, dt, minLines: 3),
      const SizedBox(height: 16),
      _hcTitulo('Remisión / Teleorientación', Icons.wifi_tethering_rounded, dt,
          sub: 'Selecciona el servicio remoto al que se remite al paciente'),
      _hcSelectorTele(dt),
      if (_teleModalidad == 'Tele Especialista') ...[
        const SizedBox(height: 4),
        _hcSelectorEspecialidad(dt),
      ],
      _hcAviso(dt),
    ]);
  }

  // ── Selector de modalidad de teleorientación ────────────────────────────
  Widget _hcSelectorTele(DispersaludColors dt) {
    final seleccionado = _kModalidadesTele
        .where((m) => m.$1 == _teleModalidad)
        .toList();
    final icono = seleccionado.isNotEmpty
        ? seleccionado.first.$2
        : Icons.expand_more_rounded;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Servicio de Teleorientación',
            style: TextStyle(
                color: dt.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _abrirSelectorTele(dt),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: dt.bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: _teleModalidad.isNotEmpty
                      ? _kVerdeHC.withOpacity(0.5)
                      : dt.border),
            ),
            child: Row(children: [
              Icon(icono,
                  size: 18,
                  color: _teleModalidad.isNotEmpty
                      ? _kVerdeHC
                      : dt.textHint),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _teleModalidad.isEmpty
                      ? 'Toca para elegir un servicio…'
                      : _teleModalidad,
                  style: TextStyle(
                      color: _teleModalidad.isEmpty
                          ? dt.textHint
                          : dt.textPrimary,
                      fontSize: 13,
                      fontWeight: _teleModalidad.isEmpty
                          ? FontWeight.normal
                          : FontWeight.w600),
                ),
              ),
              Icon(Icons.unfold_more_rounded, size: 18, color: dt.textHint),
            ]),
          ),
        ),
      ]),
    );
  }

  void _abrirSelectorTele(DispersaludColors dt) {
    showModalBottomSheet(
      context: context,
      backgroundColor: dt.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx, scrollCtrl) => Column(children: [
          const SizedBox(height: 10),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: dt.border, borderRadius: BorderRadius.circular(4)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Servicio de Teleorientación',
                style: TextStyle(
                    color: dt.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _kModalidadesTele.length,
              itemBuilder: (ctx, i) {
                final (nombre, icono) = _kModalidadesTele[i];
                final activo = nombre == _teleModalidad;
                return ListTile(
                  onTap: () {
                    setState(() {
                      _teleModalidad = nombre;
                      if (nombre != 'Tele Especialista') {
                        _teleEspecialidad = '';
                      }
                    });
                    Navigator.pop(ctx);
                  },
                  leading: Icon(icono,
                      color: activo ? _kVerdeHC : dt.textHint),
                  title: Text(nombre,
                      style: TextStyle(
                          color: dt.textPrimary,
                          fontSize: 13.5,
                          fontWeight:
                              activo ? FontWeight.w700 : FontWeight.w500)),
                  trailing: nombre == 'Tele Especialista'
                      ? Icon(Icons.chevron_right_rounded,
                          size: 18, color: dt.textHint)
                      : (activo
                          ? const Icon(Icons.check_circle_rounded,
                              color: _kVerdeHC, size: 20)
                          : null),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  tileColor: activo ? _kVerdeHC.withOpacity(0.07) : null,
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  // ── Selector de especialidad (sub-opciones de Tele Especialista) ────────
  Widget _hcSelectorEspecialidad(DispersaludColors dt) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, left: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 3, height: 14,
            decoration: BoxDecoration(
                color: _kVerdeHC, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 8),
          Text('Especialidad',
              style: TextStyle(
                  color: dt.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ]),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _abrirSelectorEspecialidad(dt),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: dt.bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: _teleEspecialidad.isNotEmpty
                      ? _kVerdeHC.withOpacity(0.5)
                      : dt.border),
            ),
            child: Row(children: [
              Icon(Icons.local_hospital_outlined,
                  size: 18,
                  color: _teleEspecialidad.isNotEmpty
                      ? _kVerdeHC
                      : dt.textHint),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _teleEspecialidad.isEmpty
                      ? 'Toca para elegir una especialidad…'
                      : _teleEspecialidad,
                  style: TextStyle(
                      color: _teleEspecialidad.isEmpty
                          ? dt.textHint
                          : dt.textPrimary,
                      fontSize: 13,
                      fontWeight: _teleEspecialidad.isEmpty
                          ? FontWeight.normal
                          : FontWeight.w600),
                ),
              ),
              Icon(Icons.unfold_more_rounded, size: 18, color: dt.textHint),
            ]),
          ),
        ),
      ]),
    );
  }

  void _abrirSelectorEspecialidad(DispersaludColors dt) {
    showModalBottomSheet(
      context: context,
      backgroundColor: dt.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollCtrl) => Column(children: [
          const SizedBox(height: 10),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: dt.border, borderRadius: BorderRadius.circular(4)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Especialidad — Tele Especialista',
                style: TextStyle(
                    color: dt.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _kEspecialidadesTele.length,
              itemBuilder: (ctx, i) {
                final nombre = _kEspecialidadesTele[i];
                final activo = nombre == _teleEspecialidad;
                return ListTile(
                  onTap: () {
                    setState(() => _teleEspecialidad = nombre);
                    Navigator.pop(ctx);
                  },
                  leading: Icon(Icons.medical_information_outlined,
                      color: activo ? _kVerdeHC : dt.textHint),
                  title: Text(nombre,
                      style: TextStyle(
                          color: dt.textPrimary,
                          fontSize: 13.5,
                          fontWeight:
                              activo ? FontWeight.w700 : FontWeight.w500)),
                  trailing: activo
                      ? const Icon(Icons.check_circle_rounded,
                          color: _kVerdeHC, size: 20)
                      : null,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  tileColor: activo ? _kVerdeHC.withOpacity(0.07) : null,
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  // ── Widget IMC con color dinámico ────────────────────────────────────────
  Widget _hcIMC(DispersaludColors dt) {
    Color color = _kVerdeHC;
    final label = _imc.isNotEmpty ? _imcLabel(_imc) : '';
    if (label == 'Bajo peso') color = const Color(0xFF185FA5);
    if (label == 'Sobrepeso') color = const Color(0xFFEF9F27);
    if (label == 'Obesidad')  color = const Color(0xFFE24B4A);
    final v = double.tryParse(_imc) ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('IMC', style: TextStyle(
            color: dt.textSecondary, fontSize: 12,
            fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: v > 0 ? color.withOpacity(0.08) : dt.bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: v > 0 ? color.withOpacity(0.4) : dt.border),
          ),
          child: Column(children: [
            Text(_imc.isNotEmpty ? _imc : '—',
                style: TextStyle(
                    color: v > 0 ? color : dt.textHint,
                    fontSize: 16, fontWeight: FontWeight.bold)),
            if (label.isNotEmpty)
              Text(label, style: TextStyle(
                  color: color, fontSize: 9, fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FUNCIONES Y WIDGETS AUXILIARES — fuera de la clase (top-level)
// ─────────────────────────────────────────────────────────────────────────────

Widget _hcTitulo(String titulo, IconData icono, DispersaludColors dt,
    {String? sub, bool small = false}) {
  return Padding(
    padding: EdgeInsets.only(bottom: small ? 10 : 14, top: small ? 8 : 0),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icono, color: _kVerdeHC, size: small ? 16 : 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(titulo, style: TextStyle(
              color: dt.textPrimary,
              fontSize: small ? 13 : 15,
              fontWeight: FontWeight.w700)),
        ),
      ]),
      if (sub != null) ...[
        const SizedBox(height: 3),
        Text(sub, style: TextStyle(color: dt.textHint, fontSize: 11)),
      ],
      const SizedBox(height: 6),
      Divider(height: 1, color: dt.border),
    ]),
  );
}

Widget _hcCampo(String label, String hint, TextEditingController ctrl,
    DispersaludColors dt, {TextInputType tipo = TextInputType.text}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(
          color: dt.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        keyboardType: tipo,
        style: TextStyle(color: dt.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: dt.textHint, fontSize: 12),
          filled: true, fillColor: dt.bg,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 11),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: dt.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: dt.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: _kVerdeHC, width: 1.5)),
        ),
      ),
    ]),
  );
}

Widget _hcGrande(String label, String hint, TextEditingController ctrl,
    DispersaludColors dt, {int minLines = 2}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(
          color: dt.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        minLines: minLines, maxLines: null,
        style: TextStyle(color: dt.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: dt.textHint, fontSize: 12),
          filled: true, fillColor: dt.bg,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 11),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: dt.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: dt.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: _kVerdeHC, width: 1.5)),
        ),
      ),
    ]),
  );
}

Widget _hcNum(String label, TextEditingController ctrl, DispersaludColors dt) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(
          color: dt.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        style: TextStyle(color: dt.textPrimary, fontSize: 16,
            fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          filled: true, fillColor: dt.bg,
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: dt.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: dt.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: _kVerdeHC, width: 1.5)),
        ),
      ),
    ]),
  );
}

Widget _hcDropdown(String label, String valor, List<String> opciones,
    ValueChanged<String?> onChange, DispersaludColors dt,
    {String hint = ''}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(
          color: dt.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        value: valor.isEmpty ? null : valor,
        hint: Text(hint.isEmpty ? label : hint,
            style: TextStyle(color: dt.textHint, fontSize: 12)),
        onChanged: onChange,
        style: TextStyle(color: dt.textPrimary, fontSize: 13),
        dropdownColor: dt.card,
        isExpanded: true,
        decoration: InputDecoration(
          filled: true, fillColor: dt.bg,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 11),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: dt.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: dt.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: _kVerdeHC, width: 1.5)),
        ),
        items: opciones.map((o) => DropdownMenuItem(
          value: o.isEmpty ? null : o,
          child: Text(o.isEmpty ? '—' : o,
              style: TextStyle(color: dt.textPrimary, fontSize: 13)),
        )).toList(),
      ),
    ]),
  );
}

Widget _hcAviso(DispersaludColors dt) {
  return Container(
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _kVerdeHC.withOpacity(0.06),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _kVerdeHC.withOpacity(0.2)),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.info_outline_rounded, color: _kVerdeHC, size: 14),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          'Información Importante — Esta historia clínica se almacena '
          'localmente en tu dispositivo. Los datos son privados y no se '
          'envían a ningún servidor. Recuerda guardar los cambios regularmente.',
          style: TextStyle(
              color: dt.textSecondary, fontSize: 10, height: 1.5),
        ),
      ),
    ]),
  );
}
// ignore_for_file: use_build_context_synchronously
// lib/screens/ficha_formulario_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/app_theme.dart';
import '../core/responsive.dart';
import '../database/database_helper.dart';

DispersaludColors _c(BuildContext ctx) =>
    Theme.of(ctx).extension<DispersaludColors>() ?? DispersaludColors.dark;

const _kAzulINS    = Color(0xFF003A8C);
const _kAzulClaro  = Color(0xFF1565C0);
const _kVerdeINS   = Color(0xFF1D9E75);
const _kGrisHeader = Color(0xFFE8EAF0);
const _kLinea      = Color(0xFFCCCCCC);
const _kRojo       = Color(0xFFE24B4A);

enum TipoCampo { texto, numero, fecha, opciones, multiLinea, siNo, radio3, checkboxes }

typedef _TipoCampo = TipoCampo;

class Campo {
  final String       clave, etiqueta;
  final TipoCampo    tipo;
  final List<String> opciones;
  final bool         requerido;
  final String?      hint;
  const Campo({
    required this.clave,
    required this.etiqueta,
    this.tipo      = TipoCampo.texto,
    this.opciones  = const [],
    this.requerido = false,
    this.hint,
  });
}
typedef _Campo = Campo;

class Seccion {
  final String       titulo;
  final List<Campo>  campos;
  const Seccion({required this.titulo, required this.campos});
}
typedef _Seccion = Seccion;

const _secPaciente = Seccion(titulo: '1. Datos del Paciente', campos: [
  Campo(clave: 'nombre_paciente',    etiqueta: 'Nombre completo', requerido: true),
  Campo(clave: 'tipo_doc',           etiqueta: 'Tipo de documento',
      tipo: TipoCampo.opciones,
      opciones: ['CC','TI','RC','CE','PA','NUI','MS','AS','CN','CD']),
  Campo(clave: 'num_doc',            etiqueta: 'Número de documento'),
  Campo(clave: 'fecha_nacimiento',   etiqueta: 'Fecha de nacimiento', tipo: TipoCampo.fecha),
  Campo(clave: 'edad',               etiqueta: 'Edad', tipo: TipoCampo.numero),
  Campo(clave: 'unidad_edad',        etiqueta: 'Unidad de edad',
      tipo: TipoCampo.opciones, opciones: ['Años','Meses','Días','Horas']),
  Campo(clave: 'sexo',               etiqueta: 'Sexo',
      tipo: TipoCampo.opciones, opciones: ['Masculino','Femenino','Indeterminado']),
  Campo(clave: 'pertenencia_etnica', etiqueta: 'Pertenencia étnica',
      tipo: TipoCampo.opciones,
      opciones: ['Indígena','ROM','Raizal','Palenquero','Afrocolombiano','Otro']),
  Campo(clave: 'estrato',            etiqueta: 'Estrato',
      tipo: TipoCampo.opciones, opciones: ['0','1','2','3','4','5','6']),
  Campo(clave: 'departamento',       etiqueta: 'Departamento de residencia'),
  Campo(clave: 'municipio',          etiqueta: 'Municipio de residencia', requerido: true),
  Campo(clave: 'direccion',          etiqueta: 'Dirección / Barrio / Vereda'),
  Campo(clave: 'telefono',           etiqueta: 'Teléfono', tipo: TipoCampo.numero),
  Campo(clave: 'ocupacion',          etiqueta: 'Ocupación'),
  Campo(clave: 'regimen_salud',      etiqueta: 'Régimen de salud',
      tipo: TipoCampo.opciones,
      opciones: ['Contributivo','Subsidiado','Excepción','Especial','No asegurado']),
  Campo(clave: 'nombre_aseguradora', etiqueta: 'Nombre aseguradora'),
]);

const _secNotificacion = Seccion(titulo: '2. Datos de Notificación', campos: [
  Campo(clave: 'cod_ups',               etiqueta: 'Código UPS', tipo: TipoCampo.numero),
  Campo(clave: 'nombre_ups',            etiqueta: 'Nombre UPS notificante', requerido: true),
  Campo(clave: 'tipo_ups',              etiqueta: 'Tipo UPS',
      tipo: TipoCampo.opciones, opciones: ['IPS','Laboratorio','Banco de sangre','Otro']),
  Campo(clave: 'fecha_consulta',        etiqueta: 'Fecha de consulta',    tipo: TipoCampo.fecha, requerido: true),
  Campo(clave: 'fecha_notificacion',    etiqueta: 'Fecha de notificación',tipo: TipoCampo.fecha, requerido: true),
  Campo(clave: 'semana_epidemiologica', etiqueta: 'Semana epidemiológica',tipo: TipoCampo.numero),
  Campo(clave: 'nombre_notificador',    etiqueta: 'Nombre del notificador'),
  Campo(clave: 'cargo_notificador',     etiqueta: 'Cargo del notificador'),
]);

const _secClinica = Seccion(titulo: '3. Datos Clínicos', campos: [
  Campo(clave: 'fecha_inicio_sintomas',    etiqueta: 'Fecha inicio síntomas',   tipo: TipoCampo.fecha),
  Campo(clave: 'tipo_caso',                etiqueta: 'Tipo de caso',
      tipo: TipoCampo.opciones,
      opciones: ['Sospechoso','Probable','Confirmado laboratorio',
                 'Confirmado clínico','Confirmado nexo epidemiológico','Descartado']),
  Campo(clave: 'hospitalizacion',          etiqueta: '¿Hospitalizado?',          tipo: TipoCampo.siNo),
  Campo(clave: 'fecha_hospitalizacion',    etiqueta: 'Fecha hospitalización',    tipo: TipoCampo.fecha),
  Campo(clave: 'condicion_final',          etiqueta: 'Condición final',
      tipo: TipoCampo.opciones, opciones: ['Vivo','Muerto']),
  Campo(clave: 'causa_muerte',             etiqueta: 'Causa de muerte (si aplica)'),
]);

const _secLab = Seccion(titulo: '4. Laboratorio', campos: [
  Campo(clave: 'muestra_tomada',   etiqueta: '¿Muestra tomada?',   tipo: TipoCampo.siNo),
  Campo(clave: 'tipo_muestra',     etiqueta: 'Tipo de muestra',
      tipo: TipoCampo.opciones,
      opciones: ['Sangre','Suero','Orina','Heces','LCR','Hisopado','Biopsia','Otra']),
  Campo(clave: 'fecha_muestra',    etiqueta: 'Fecha de muestra',   tipo: TipoCampo.fecha),
  Campo(clave: 'resultado_lab',    etiqueta: 'Resultado',
      tipo: TipoCampo.opciones,
      opciones: ['Positivo','Negativo','En proceso','Indeterminado','No aplica']),
  Campo(clave: 'prueba_realizada', etiqueta: 'Prueba realizada',   hint: 'PCR, ELISA, cultivo...'),
  Campo(clave: 'laboratorio',      etiqueta: 'Laboratorio que procesó'),
]);

const _secTratamiento = Seccion(titulo: '5. Tratamiento', campos: [
  Campo(clave: 'tratamiento',         etiqueta: 'Tratamiento instaurado',   tipo: TipoCampo.multiLinea),
  Campo(clave: 'fecha_inicio_tto',    etiqueta: 'Fecha inicio tratamiento', tipo: TipoCampo.fecha),
  Campo(clave: 'seguimiento',         etiqueta: 'Plan de seguimiento',      tipo: TipoCampo.multiLinea),
  Campo(clave: 'nexo_epidemiologico', etiqueta: 'Nexo epidemiológico',      tipo: TipoCampo.multiLinea),
]);

const _secObs = Seccion(titulo: '6. Observaciones', campos: [
  Campo(clave: 'observaciones', etiqueta: 'Observaciones generales', tipo: TipoCampo.multiLinea),
]);

const Map<String, Seccion> _especificos = {
  'DEN': Seccion(titulo: 'Clínica Dengue', campos: [
    Campo(clave: 'fiebre',      etiqueta: 'Fiebre',             tipo: TipoCampo.siNo),
    Campo(clave: 'cefalea',     etiqueta: 'Cefalea retrocular', tipo: TipoCampo.siNo),
    Campo(clave: 'mialgia',     etiqueta: 'Mialgia/Artralgia',  tipo: TipoCampo.siNo),
    Campo(clave: 'exantema',    etiqueta: 'Exantema',           tipo: TipoCampo.siNo),
    Campo(clave: 'sangrado',    etiqueta: 'Sangrado',           tipo: TipoCampo.siNo),
    Campo(clave: 'tipo_dengue', etiqueta: 'Clasificación final',
        tipo: TipoCampo.opciones,
        opciones: ['Sin signos de alarma','Con signos de alarma','Grave']),
    Campo(clave: 'serotipo',    etiqueta: 'Serotipo',
        tipo: TipoCampo.opciones,
        opciones: ['DENV-1','DENV-2','DENV-3','DENV-4','No determinado']),
  ]),
  'CHIK': Seccion(titulo: 'Clínica Chikunguña', campos: [
    Campo(clave: 'fiebre_chik',   etiqueta: 'Fiebre > 38.5°C',  tipo: TipoCampo.siNo),
    Campo(clave: 'artralgia',     etiqueta: 'Artralgia intensa', tipo: TipoCampo.siNo),
    Campo(clave: 'exantema_chik', etiqueta: 'Exantema',         tipo: TipoCampo.siNo),
    Campo(clave: 'fase',          etiqueta: 'Fase',
        tipo: TipoCampo.opciones, opciones: ['Aguda','Subaguda','Crónica']),
  ]),
  'ZIKA': Seccion(titulo: 'Clínica Zika', campos: [
    Campo(clave: 'embarazada',    etiqueta: '¿Gestante?',             tipo: TipoCampo.siNo),
    Campo(clave: 'sem_gestacion', etiqueta: 'Semanas gestación',      tipo: TipoCampo.numero),
    Campo(clave: 'exantema_zika', etiqueta: 'Exantema pruriginoso',   tipo: TipoCampo.siNo),
    Campo(clave: 'microcefalia',  etiqueta: '¿Microcefalia RN?',      tipo: TipoCampo.siNo),
  ]),
  'MAL': Seccion(titulo: 'Clínica Malaria', campos: [
    Campo(clave: 'especie',      etiqueta: 'Especie Plasmodium',
        tipo: TipoCampo.opciones,
        opciones: ['P. falciparum','P. vivax','P. malariae','Mixto','No determinado']),
    Campo(clave: 'parasitemia',  etiqueta: 'Parasitemia (parásitos/µL)', tipo: TipoCampo.numero),
    Campo(clave: 'tipo_malaria', etiqueta: 'Tipo de malaria',
        tipo: TipoCampo.opciones, opciones: ['No complicada','Complicada/Grave']),
    Campo(clave: 'antimalárico', etiqueta: 'Antimalárico administrado'),
  ]),
  'TUB': Seccion(titulo: 'Clínica Tuberculosis', campos: [
    Campo(clave: 'tipo_tb',      etiqueta: 'Tipo de TB',
        tipo: TipoCampo.opciones, opciones: ['Pulmonar','Extrapulmonar','Miliar']),
    Campo(clave: 'baciloscopia', etiqueta: 'Baciloscopia',
        tipo: TipoCampo.opciones, opciones: ['+1','+2','+3','Negativo','No realizada']),
    Campo(clave: 'cultivo_tb',   etiqueta: 'Cultivo',
        tipo: TipoCampo.opciones, opciones: ['Positivo','Negativo','No realizado']),
    Campo(clave: 'sensibilidad', etiqueta: 'Sensibilidad (DST)',
        tipo: TipoCampo.opciones, opciones: ['Sensible','MDR','XDR','No realizada']),
    Campo(clave: 'vih_tb',       etiqueta: 'Coinfección VIH',
        tipo: TipoCampo.opciones, opciones: ['Positivo','Negativo','Desconocido']),
    Campo(clave: 'contactos',    etiqueta: 'N° contactos', tipo: TipoCampo.numero),
  ]),
  'VIH': Seccion(titulo: 'Clínica VIH/SIDA', campos: [
    Campo(clave: 'estadio',        etiqueta: 'Estadio OMS',
        tipo: TipoCampo.opciones, opciones: ['I','II','III','IV']),
    Campo(clave: 'cd4',            etiqueta: 'CD4 (cel/mm³)',         tipo: TipoCampo.numero),
    Campo(clave: 'carga_viral',    etiqueta: 'Carga viral (copias/mL)', tipo: TipoCampo.numero),
    Campo(clave: 'via_transmision',etiqueta: 'Vía de transmisión',
        tipo: TipoCampo.opciones,
        opciones: ['Sexual','Parenteral','Vertical','Desconocida']),
    Campo(clave: 'tar',            etiqueta: '¿En TAR?',              tipo: TipoCampo.siNo),
    Campo(clave: 'esquema_tar',    etiqueta: 'Esquema TAR'),
  ]),
  'IRA': Seccion(titulo: 'Clínica IRA', campos: [
    Campo(clave: 'tipo_ira',     etiqueta: 'Tipo IRA',
        tipo: TipoCampo.opciones,
        opciones: ['IRA alta','Neumonía','Bronquiolitis','Influenza','COVID-19','Otra']),
    Campo(clave: 'fr_minuto',    etiqueta: 'Frecuencia respiratoria/min', tipo: TipoCampo.numero),
    Campo(clave: 'saturacion',   etiqueta: 'Saturación O₂ (%)',           tipo: TipoCampo.numero),
    Campo(clave: 'requirio_uci', etiqueta: '¿Requirió UCI?',              tipo: TipoCampo.siNo),
    Campo(clave: 'ventilacion',  etiqueta: '¿Ventilación mecánica?',      tipo: TipoCampo.siNo),
  ]),
  'EDA': Seccion(titulo: 'Clínica EDA', campos: [
    Campo(clave: 'num_deposiciones', etiqueta: 'N° deposiciones/día', tipo: TipoCampo.numero),
    Campo(clave: 'tipo_deposicion',  etiqueta: 'Tipo de deposición',
        tipo: TipoCampo.opciones,
        opciones: ['Líquida','Con moco','Con sangre','Con moco y sangre']),
    Campo(clave: 'deshidratacion',   etiqueta: 'Deshidratación',
        tipo: TipoCampo.opciones,
        opciones: ['Sin deshidratación','Leve-moderada','Grave']),
    Campo(clave: 'vomito',           etiqueta: '¿Vómito?',            tipo: TipoCampo.siNo),
    Campo(clave: 'brote',            etiqueta: '¿Asociado a brote?',  tipo: TipoCampo.siNo),
  ]),
  'MME': Seccion(titulo: 'Mortalidad Materna', campos: [
    Campo(clave: 'momento_muerte',  etiqueta: 'Momento de la muerte',
        tipo: TipoCampo.opciones,
        opciones: ['Durante embarazo','Durante parto',
                   'Dentro de 42 días puerperio','Entre 43 días y 1 año']),
    Campo(clave: 'sem_gest_mm',     etiqueta: 'Semanas de gestación',     tipo: TipoCampo.numero),
    Campo(clave: 'num_controles',   etiqueta: 'N° controles prenatales',  tipo: TipoCampo.numero),
    Campo(clave: 'causa_directa',   etiqueta: 'Causa directa',
        tipo: TipoCampo.opciones,
        opciones: ['Hemorragia','Hipertensión/Eclampsia','Sepsis','Aborto','Otra']),
    Campo(clave: 'evitabilidad',    etiqueta: '¿Muerte evitable?',
        tipo: TipoCampo.opciones, opciones: ['Evitable','No evitable','No determinado']),
  ]),
  'SFILIS': Seccion(titulo: 'Sífilis Gestacional/Congénita', campos: [
    Campo(clave: 'tipo_sifilis',  etiqueta: 'Tipo',
        tipo: TipoCampo.opciones, opciones: ['Gestacional','Congénita']),
    Campo(clave: 'sem_diagnos',   etiqueta: 'Semanas al diagnóstico',   tipo: TipoCampo.numero),
    Campo(clave: 'trat_prenatal', etiqueta: '¿Tratamiento prenatal?',   tipo: TipoCampo.siNo),
    Campo(clave: 'tto_pareja',    etiqueta: '¿Pareja tratada?',         tipo: TipoCampo.siNo),
    Campo(clave: 'vdrl_titulo',   etiqueta: 'Título VDRL'),
  ]),
};

List<Seccion> _seccionesParaFicha(String codigo) {
  final base = [_secPaciente, _secNotificacion, _secClinica, _secLab, _secTratamiento];
  final esp  = _especificos[codigo];
  if (esp != null) return [...base.sublist(0,2), esp, ...base.sublist(2), _secObs];
  return [...base, _secObs];
}

// ═══════════════════════════════════════════════════════════════════════════
//  PANTALLA
// ═══════════════════════════════════════════════════════════════════════════
class FichaFormularioScreen extends StatefulWidget {
  final String codigoFicha, nombreFicha, emojiFicha;
  final Color  colorFicha;
  final int?   fichaId;
  final Map<String, dynamic> datosPaciente;

  const FichaFormularioScreen({
    super.key,
    required this.codigoFicha,
    required this.nombreFicha,
    required this.colorFicha,
    required this.emojiFicha,
    this.fichaId,
    this.datosPaciente = const {},
  });

  @override
  State<FichaFormularioScreen> createState() => _FichaFormularioScreenState();
}

class _FichaFormularioScreenState extends State<FichaFormularioScreen> {
  final Map<String, TextEditingController> _ctrls     = {};
  final Map<String, String>                _dropdowns = {};
  final Map<String, String>                _radios    = {};
  bool  _guardando  = false;
  bool  _exportando = false;
  int   _seccionIdx = 0;
  late  List<Seccion> _secciones;

  @override
  void initState() {
    super.initState();
    _secciones = _seccionesParaFicha(widget.codigoFicha);
    for (final sec in _secciones) {
      for (final c in sec.campos) {
        switch (c.tipo) {
          case TipoCampo.opciones:
            _dropdowns[c.clave] = c.opciones.isNotEmpty ? c.opciones.first : '';
          case TipoCampo.siNo:
            _radios[c.clave] = '';
          case TipoCampo.radio3:
            _radios[c.clave] = '';
          default:
            _ctrls[c.clave] = TextEditingController();
        }
      }
    }
    if (widget.fichaId != null) {
      _cargarDatos();
    } else if (widget.datosPaciente.isNotEmpty) {
      _precargarPaciente();
    }
  }

  void _precargarPaciente() {
    final p = widget.datosPaciente;
    void set(String clave, String? valor) {
      if (valor != null && valor.isNotEmpty && _ctrls.containsKey(clave)) {
        _ctrls[clave]!.text = valor;
      }
    }
    set('nombre_paciente', p['nombre']       as String?);
    set('num_doc',         p['documento']    as String?);
    set('fecha_nacimiento',p['fecha_nac']    as String?);
    set('municipio',       p['municipio']    as String?);
    set('departamento',    p['departamento'] as String?);
    set('telefono',        p['telefono']     as String?);
    set('nombre_aseguradora', p['eps']       as String?);
    final sexo = p['sexo'] as String?;
    if (sexo != null && sexo.isNotEmpty && _dropdowns.containsKey('sexo')) {
      _dropdowns['sexo'] = sexo;
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) c.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    final data = await DatabaseHelper.instance.obtenerFicha(widget.fichaId!);
    if (data == null || !mounted) return;
    final extra = jsonDecode(data['datos_json'] as String? ?? '{}') as Map<String, dynamic>;
    setState(() {
      extra.forEach((key, val) {
        final v = val.toString();
        if (_ctrls.containsKey(key))          _ctrls[key]!.text = v;
        else if (_dropdowns.containsKey(key)) _dropdowns[key] = v;
        else if (_radios.containsKey(key))    _radios[key] = v;
      });
    });
  }

  Map<String, dynamic> _recolectar() {
    final m = <String, dynamic>{};
    _ctrls.forEach((k, v)     => m[k] = v.text.trim());
    _dropdowns.forEach((k, v) => m[k] = v);
    _radios.forEach((k, v)    => m[k] = v);
    return m;
  }

  Future<void> _guardar() async {
    final nombre = _ctrls['nombre_paciente']?.text.trim() ?? '';
    if (nombre.isEmpty) { _snack('Ingresa el nombre del paciente', color: _kRojo); return; }
    setState(() => _guardando = true);
    final datos = _recolectar();
    final registro = {
      'codigo_evento':      widget.codigoFicha,
      'nombre_evento':      widget.nombreFicha,
      'estado':             'completa',
      'datos_json':         jsonEncode(datos),
      'nombre_paciente':    nombre,
      'municipio':          _ctrls['municipio']?.text.trim() ?? '',
      'fecha_notificacion': _ctrls['fecha_notificacion']?.text.trim() ?? '',
      'nivel_urgencia':     'normal',
    };
    try {
      if (widget.fichaId != null) {
        await DatabaseHelper.instance.actualizarFicha(widget.fichaId!, registro);
      } else {
        await DatabaseHelper.instance.insertarFicha(registro);
      }
      if (mounted) { _snack('✅ Ficha guardada'); Navigator.pop(context, true); }
    } catch (e) {
      if (mounted) _snack('Error: $e', color: _kRojo);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  // ── PDF mejorado con tabla ──────────────────────────────────────────────
  Future<void> _exportarPDF() async {
    setState(() => _exportando = true);
    try {
      final datos = _recolectar();
      final pdf   = pw.Document();
      final now   = DateTime.now();
      final fechaGen =
          '${now.day.toString().padLeft(2,"0")}/${now.month.toString().padLeft(2,"0")}/${now.year} '
          '${now.hour.toString().padLeft(2,"0")}:${now.minute.toString().padLeft(2,"0")}';

      // ── Cargar logos ───────────────────────────────────────────────────
      pw.MemoryImage? logoDisper, logoColombia, logoSalud, logoIns, logoSivigila;
      try {
        logoDisper   = pw.MemoryImage((await rootBundle.load('assets/logo_dispersalud.png')).buffer.asUint8List());
        logoColombia = pw.MemoryImage((await rootBundle.load('assets/logos_ins/logo_colombia.png')).buffer.asUint8List());
        logoSalud    = pw.MemoryImage((await rootBundle.load('assets/logos_ins/logo_salud.png')).buffer.asUint8List());
        logoIns      = pw.MemoryImage((await rootBundle.load('assets/logos_ins/logo_ins.png')).buffer.asUint8List());
        logoSivigila = pw.MemoryImage((await rootBundle.load('assets/logos_ins/logo_sivigila.png')).buffer.asUint8List());
      } catch (_) {}

      // ── Colores ────────────────────────────────────────────────────────
      final azul      = PdfColor.fromHex('003A8C');
      final verdeAcc  = PdfColor.fromHex('1D9E75');
      final grisLinea = PdfColor.fromHex('E0E4EC');
      final grisTexto = PdfColor.fromHex('555555');
      final grisClaro = PdfColor.fromHex('F7F8FA');
      final rojoPDF   = PdfColor.fromHex('E24B4A');
      final bold      = pw.Font.helveticaBold();
      final regular   = pw.Font.helvetica();

      // ── Generar una página por sección ────────────────────────────────
      for (int si = 0; si < _secciones.length; si++) {
        final sec = _secciones[si];

        pdf.addPage(pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(32, 28, 32, 24),
          build: (_) {
            // ── ENCABEZADO estilo imagen 2 ──────────────────────────────
            // Fila 1: Logo DISPERSALUD grande | línea | "Formulario de Recolección" + nombre ficha + código
            final encabezado = pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColor.fromHex('DDDDDD'), width: 0.5),
              ),
              child: pw.Column(children: [
                // Banda superior: logos izquierda + info derecha
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      // Logo DISPERSALUD IA grande
                      if (logoDisper != null)
                        pw.Container(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Image(logoDisper, height: 38, width: 38, fit: pw.BoxFit.contain),
                        )
                      else
                        pw.Container(
                          width: 38, height: 38,
                          decoration: pw.BoxDecoration(color: verdeAcc, borderRadius: pw.BorderRadius.circular(6)),
                          child: pw.Center(
                            child: pw.Text('D', style: pw.TextStyle(font: bold, color: PdfColors.white, fontSize: 20)),
                          ),
                        ),
                      pw.SizedBox(width: 8),
                      // Texto DISPERSALUD IA
                      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                        pw.Text('DISPERSALUD', style: pw.TextStyle(font: bold, fontSize: 14, color: azul, letterSpacing: 1)),
                        pw.Row(children: [
                          pw.Text('IA', style: pw.TextStyle(font: bold, fontSize: 14, color: verdeAcc)),
                        ]),
                        pw.Text('SALUD INTELIGENTE. DONDE MÁS SE NECESITA.',
                            style: pw.TextStyle(font: regular, fontSize: 5.5, color: grisTexto, letterSpacing: 0.3)),
                      ]),
                      pw.SizedBox(width: 20),
                      // Línea vertical divisoria
                      pw.Container(width: 0.8, height: 44, color: PdfColor.fromHex('CCCCCC')),
                      pw.SizedBox(width: 20),
                      // Info: "Formulario de Recolección" + nombre + código
                      pw.Expanded(child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text('Formulario de Recolección',
                              style: pw.TextStyle(font: regular, fontSize: 8, color: grisTexto)),
                          pw.SizedBox(height: 3),
                          pw.Text(widget.nombreFicha,
                              style: pw.TextStyle(font: bold, fontSize: 15, color: azul)),
                          pw.SizedBox(height: 4),
                          pw.Row(children: [
                            pw.Text('Código: ', style: pw.TextStyle(font: regular, fontSize: 7.5, color: grisTexto)),
                            pw.Text(widget.codigoFicha, style: pw.TextStyle(font: bold, fontSize: 7.5, color: PdfColors.black)),
                            pw.SizedBox(width: 12),
                            pw.Text('|', style: pw.TextStyle(font: regular, fontSize: 7.5, color: grisTexto)),
                            pw.SizedBox(width: 12),
                            pw.Text('Versión: 2024', style: pw.TextStyle(font: regular, fontSize: 7.5, color: grisTexto)),
                          ]),
                        ],
                      )),
                      // Logo SIVIGILA
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColor.fromHex('BBBBBB'), width: 0.5),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Row(children: [
                          if (logoSivigila != null)
                            pw.Image(logoSivigila, height: 18, fit: pw.BoxFit.contain)
                          else
                            pw.Text('SIVIGILA', style: pw.TextStyle(font: bold, fontSize: 8, color: azul)),
                        ]),
                      ),
                    ],
                  ),
                ),
                // Línea separadora
                pw.Divider(color: PdfColor.fromHex('DDDDDD'), height: 0.5),
                // Fila 2: logos institucionales Colombia + Salud + INS
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (logoColombia != null) ...[
                        pw.Image(logoColombia, height: 22, fit: pw.BoxFit.contain),
                        pw.SizedBox(width: 14),
                      ],
                      if (logoSalud != null) ...[
                        pw.Image(logoSalud, height: 20, fit: pw.BoxFit.contain),
                        pw.SizedBox(width: 14),
                      ],
                      if (logoIns != null) ...[
                        pw.Container(width: 0.6, height: 22, color: PdfColor.fromHex('CCCCCC')),
                        pw.SizedBox(width: 14),
                        pw.Image(logoIns, height: 22, fit: pw.BoxFit.contain),
                      ],
                    ],
                  ),
                ),
              ]),
            );

            // ── CABECERA SECCIÓN (verde oscuro) ─────────────────────────
            final cabSeccion = pw.Container(
              margin: const pw.EdgeInsets.only(top: 14),
              decoration: pw.BoxDecoration(color: verdeAcc),
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: pw.Row(children: [
                pw.Expanded(child: pw.Text(
                  sec.titulo.toUpperCase(),
                  style: pw.TextStyle(font: bold, color: PdfColors.white, fontSize: 9, letterSpacing: 0.4),
                )),
                pw.Text(
                  '${si + 1} / ${_secciones.length}',
                  style: pw.TextStyle(font: regular, color: const PdfColor(1, 1, 1, 0.85), fontSize: 8),
                ),
              ]),
            );

            // ── TABLA DE CAMPOS ──────────────────────────────────────────
            final tabla = pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColor.fromHex('CCCCCC'), width: 0.6),
              ),
              child: pw.Table(
                columnWidths: const {
                  0: pw.FlexColumnWidth(2.5),
                  1: pw.FlexColumnWidth(4.5),
                },
                children: sec.campos.asMap().entries.map((entry) {
                  final idx   = entry.key;
                  final campo = entry.value;
                  final val   = datos[campo.clave]?.toString() ?? '';
                  final bgRow = idx.isEven ? grisClaro : PdfColors.white;

                  String display;
                  if (campo.tipo == TipoCampo.siNo) {
                    display = val == 'si' ? '✓  Sí'
                            : val == 'no' ? '✗  No'
                            : '—';
                  } else {
                    display = val.isEmpty ? '—' : val;
                  }

                  final esVacio     = val.isEmpty;
                  final esRequerido = campo.requerido && esVacio;

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: bgRow),
                    children: [
                      // Columna etiqueta
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: pw.BoxDecoration(
                          border: pw.Border(
                            right: pw.BorderSide(color: PdfColor.fromHex('DDDDDD'), width: 0.5),
                            bottom: pw.BorderSide(color: PdfColor.fromHex('EEEEEE'), width: 0.3),
                          ),
                        ),
                        child: pw.Row(children: [
                          pw.Expanded(child: pw.Text(
                            campo.etiqueta,
                            style: pw.TextStyle(font: regular, fontSize: 8, color: PdfColors.grey800),
                          )),
                          if (campo.requerido)
                            pw.Text(' *', style: pw.TextStyle(font: bold, fontSize: 9, color: rojoPDF)),
                        ]),
                      ),
                      // Columna valor
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(color: PdfColor.fromHex('EEEEEE'), width: 0.3),
                          ),
                        ),
                        child: pw.Text(
                          display,
                          style: pw.TextStyle(
                            font: (esVacio || esRequerido) ? regular : bold,
                            fontSize: 8.5,
                            color: esRequerido
                                ? rojoPDF
                                : esVacio
                                    ? PdfColors.grey400
                                    : PdfColors.black,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            );

            // ── PIE DE PÁGINA ────────────────────────────────────────────
            final pie = pw.Column(children: [
              pw.SizedBox(height: 6),
              pw.Divider(color: PdfColor.fromHex('DDDDDD'), height: 0.5),
              pw.SizedBox(height: 5),
              pw.Row(children: [
                pw.Container(
                  width: 7, height: 7,
                  decoration: pw.BoxDecoration(color: verdeAcc, borderRadius: pw.BorderRadius.circular(4)),
                ),
                pw.SizedBox(width: 5),
                pw.Text('DISPERSALUD IA',
                    style: pw.TextStyle(font: bold, fontSize: 7, color: verdeAcc)),
                pw.SizedBox(width: 6),
                pw.Text('  Formulario SIVIGILA',
                    style: pw.TextStyle(font: regular, fontSize: 7, color: grisTexto)),
                pw.SizedBox(width: 4),
                pw.Text('  Instituto Nacional de Salud',
                    style: pw.TextStyle(font: regular, fontSize: 7, color: grisTexto)),
                pw.SizedBox(width: 4),
                pw.Text('  Colombia',
                    style: pw.TextStyle(font: regular, fontSize: 7, color: grisTexto)),
                pw.Spacer(),
                pw.Text(
                  'Pág. ${si + 1} de ${_secciones.length}  |  Generado: $fechaGen',
                  style: pw.TextStyle(font: regular, fontSize: 6.5, color: grisTexto),
                ),
              ]),
            ]);

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                encabezado,
                cabSeccion,
                tabla,
                pw.Spacer(),
                pie,
              ],
            );
          },
        ));
      }

      await Printing.layoutPdf(
        onLayout: (_) => pdf.save(),
        name: 'SIVIGILA_${widget.codigoFicha}_${now.year}${now.month.toString().padLeft(2,"0")}${now.day.toString().padLeft(2,"0")}.pdf',
      );
      if (mounted) _snack('✅ PDF generado correctamente');
    } catch (e) {
      if (mounted) _snack('Error PDF: $e', color: _kRojo);
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  void _snack(String msg, {Color? color}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg), backgroundColor: color ?? _kVerdeINS,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));

  // ── Iconos por sección (para los tabs) ──────────────────────────────────
  static const List<IconData> _kTabIconos = [
    Icons.person_outline_rounded,
    Icons.business_rounded,
    Icons.medical_information_outlined,
    Icons.history_edu_rounded,
    Icons.biotech_outlined,
    Icons.monitor_heart_outlined,
    Icons.check_circle_outline_rounded,
  ];

  IconData _iconoSeccion(int i) {
    if (i < _kTabIconos.length) return _kTabIconos[i];
    return Icons.article_outlined;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  BUILD — nuevo diseño profesional
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    const bgForm   = Colors.white;
    const txtForm  = Color(0xFF1A1A2E);
    const borde    = Color(0xFFE0E4F0);
    final progress = (_seccionIdx + 1) / _secciones.length;
    final pct      = ((progress) * 100).toInt();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FB),
      appBar: AppBar(
        backgroundColor: _kAzulINS,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8)),
            child: Image.asset('assets/logo_dispersalud.png',
                height: 24, width: 24, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.local_hospital_rounded,
                    color: Colors.white, size: 20)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Formulario de Recolección',
                style: const TextStyle(color: Colors.white60, fontSize: 9.5,
                    fontWeight: FontWeight.w500)),
            Text(widget.nombreFicha,
                style: const TextStyle(color: Colors.white, fontSize: 13,
                    fontWeight: FontWeight.bold),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
        ]),
        actions: [
          // Logo SIVIGILA en AppBar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.verified_rounded, color: _kAzulINS, size: 13),
              const SizedBox(width: 3),
              const Text('SIVIGILA', style: TextStyle(
                  color: _kAzulINS, fontSize: 9, fontWeight: FontWeight.bold)),
            ]),
          ),
          // PDF
          IconButton(
            tooltip: 'Exportar PDF',
            icon: _exportando
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 20),
            onPressed: _exportando ? null : _exportarPDF,
          ),
          // Guardar
          IconButton(
            tooltip: 'Guardar',
            icon: _guardando
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.save_rounded, color: Colors.white, size: 20),
            onPressed: _guardando ? null : _guardar,
          ),
        ],
      ),
      body: Column(children: [

        // ── Encabezado institucional con logos ───────────────────────────
        _EncabezadoINS(
            nombreFicha: widget.nombreFicha,
            codigoFicha: widget.codigoFicha),

        // ── Barra de progreso ────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(children: [
            Row(children: [
              Text('Paso ${_seccionIdx + 1} de ${_secciones.length}',
                  style: const TextStyle(color: Color(0xFF555555),
                      fontSize: 11, fontWeight: FontWeight.w500)),
              const Spacer(),
              Text('$pct% completado',
                  style: TextStyle(color: _kAzulINS,
                      fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: const Color(0xFFE0E4F0),
                valueColor: const AlwaysStoppedAnimation<Color>(_kAzulINS),
              ),
            ),
            const SizedBox(height: 8),
          ]),
        ),

        // ── Tabs con íconos ──────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: SizedBox(
            height: 64,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _secciones.length,
              itemBuilder: (_, i) {
                final activo = i == _seccionIdx;
                final completado = i < _seccionIdx;
                final titulo = _secciones[i].titulo
                    .replaceAll(RegExp(r'^\d+\.\s*'), '')
                    .replaceAll('Datos del ', '')
                    .replaceAll('Datos de ', '');
                return GestureDetector(
                  onTap: () => setState(() => _seccionIdx = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: activo
                          ? _kAzulINS
                          : completado
                              ? const Color(0xFFE8F5EE)
                              : const Color(0xFFF5F6FA),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: activo
                            ? _kAzulINS
                            : completado
                                ? _kVerdeINS
                                : const Color(0xFFDDE2F0),
                        width: activo ? 2 : 1,
                      ),
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(_iconoSeccion(i),
                          color: activo
                              ? Colors.white
                              : completado ? _kVerdeINS : const Color(0xFF8898B8),
                          size: 18),
                      const SizedBox(height: 3),
                      Text(titulo,
                          style: TextStyle(
                              color: activo
                                  ? Colors.white
                                  : completado ? _kVerdeINS : const Color(0xFF6677A0),
                              fontSize: 8.5,
                              fontWeight: activo ? FontWeight.bold : FontWeight.normal),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                );
              },
            ),
          ),
        ),

        // ── Formulario ───────────────────────────────────────────────────
        Expanded(
          child: ResponsiveCenter(maxWidth: 800, child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 80),
            child: Container(
              decoration: BoxDecoration(
                color: bgForm,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borde),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Header sección
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _kAzulINS,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(children: [
                    Icon(_iconoSeccion(_seccionIdx), color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      _secciones[_seccionIdx].titulo.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 11,
                          fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    )),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10)),
                      child: Text('${_seccionIdx + 1} / ${_secciones.length}',
                          style: const TextStyle(color: Colors.white,
                              fontSize: 9.5, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                ),

                // Campos
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: _secciones[_seccionIdx].campos
                          .map((c) => _buildCampoModerno(c))
                          .toList()),
                ),

                // Guardado automático hint
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: Row(children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF4CAF50), size: 13),
                    const SizedBox(width: 5),
                    Text('Cambios guardados',
                        style: const TextStyle(color: Color(0xFF4CAF50),
                            fontSize: 10, fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Text('Guardado automático',
                        style: const TextStyle(color: Color(0xFF9AA5BE),
                            fontSize: 10)),
                  ]),
                ),

                // Botones anterior / siguiente
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(children: [
                    if (_seccionIdx > 0) ...[
                      Expanded(child: OutlinedButton.icon(
                        icon: const Icon(Icons.arrow_back_ios_rounded,
                            size: 13, color: _kAzulINS),
                        label: const Text('Anterior',
                            style: TextStyle(color: _kAzulINS, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            side: const BorderSide(color: _kAzulINS, width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        onPressed: () => setState(() => _seccionIdx--),
                      )),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      flex: 2,
                      child: _seccionIdx < _secciones.length - 1
                          ? ElevatedButton.icon(
                              icon: const Icon(Icons.arrow_forward_ios_rounded,
                                  size: 13, color: Colors.white),
                              label: const Text('Siguiente →',
                                  style: TextStyle(color: Colors.white,
                                      fontWeight: FontWeight.bold, fontSize: 14)),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: _kAzulINS, elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10))),
                              onPressed: () => setState(() => _seccionIdx++),
                            )
                          : ElevatedButton.icon(
                              icon: _guardando
                                  ? const SizedBox(width: 16, height: 16,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.save_rounded,
                                      color: Colors.white, size: 16),
                              label: Text(_guardando ? 'Guardando...' : 'Guardar ficha',
                                  style: const TextStyle(color: Colors.white,
                                      fontWeight: FontWeight.bold, fontSize: 14)),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: _kVerdeINS, elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10))),
                              onPressed: _guardando ? null : _guardar,
                            ),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
          ),
        ),
      ]),
    );
  }

  // ── Campo moderno con bordes redondeados ─────────────────────────────────
  Widget _buildCampoModerno(Campo c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Etiqueta
        Row(children: [
          Expanded(child: Text(c.etiqueta,
              style: const TextStyle(color: Color(0xFF3A4A6B),
                  fontSize: 12, fontWeight: FontWeight.w600))),
          if (c.requerido)
            const Text(' *', style: TextStyle(color: _kRojo,
                fontSize: 12, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 6),
        // Campo según tipo
        switch (c.tipo) {
          TipoCampo.siNo       => _buildSiNoModerno(c),
          TipoCampo.radio3     => _buildRadio3Moderno(c),
          TipoCampo.opciones   => _buildDropdownModerno(c),
          TipoCampo.fecha      => _buildFechaModerna(c),
          TipoCampo.multiLinea => _buildTextAreaModerno(c),
          _                    => _buildTextoModerno(c),
        },
      ]),
    );
  }

  static const _borderModerno = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(8)),
    borderSide: BorderSide(color: Color(0xFFDDE2F0)),
  );
  static const _borderFocus = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(8)),
    borderSide: BorderSide(color: _kAzulINS, width: 1.5),
  );

  Widget _buildTextoModerno(Campo c) {
    final ctrl = _ctrls[c.clave] ??= TextEditingController();
    return TextField(
      controller: ctrl,
      keyboardType: c.tipo == TipoCampo.numero
          ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Color(0xFF1A1A2E), fontSize: 13),
      decoration: InputDecoration(
        hintText: c.hint ?? 'Ingrese ${c.etiqueta.toLowerCase()}',
        hintStyle: const TextStyle(color: Color(0xFFBCC4D8), fontSize: 12),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        filled: true,
        fillColor: const Color(0xFFFAFBFD),
        border: _borderModerno,
        enabledBorder: _borderModerno,
        focusedBorder: _borderFocus,
      ),
    );
  }

  Widget _buildTextAreaModerno(Campo c) {
    final ctrl = _ctrls[c.clave] ??= TextEditingController();
    return TextField(
      controller: ctrl,
      maxLines: 3,
      style: const TextStyle(color: Color(0xFF1A1A2E), fontSize: 13),
      decoration: InputDecoration(
        hintText: c.hint ?? 'Ingrese ${c.etiqueta.toLowerCase()}...',
        hintStyle: const TextStyle(color: Color(0xFFBCC4D8), fontSize: 12),
        isDense: true,
        contentPadding: const EdgeInsets.all(12),
        filled: true,
        fillColor: const Color(0xFFFAFBFD),
        border: _borderModerno,
        enabledBorder: _borderModerno,
        focusedBorder: _borderFocus,
      ),
    );
  }

  Widget _buildFechaModerna(Campo c) {
    final ctrl = _ctrls[c.clave] ??= TextEditingController();
    return GestureDetector(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1920),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
                colorScheme: const ColorScheme.light(primary: _kAzulINS)),
            child: child!,
          ),
        );
        if (d != null) {
          ctrl.text = '${d.day.toString().padLeft(2,"0")}/${d.month.toString().padLeft(2,"0")}/${d.year}';
          setState(() {});
        }
      },
      child: AbsorbPointer(
        child: TextField(
          controller: ctrl,
          style: const TextStyle(color: Color(0xFF1A1A2E), fontSize: 13),
          decoration: InputDecoration(
            hintText: 'dd/mm/aaaa',
            hintStyle: const TextStyle(color: Color(0xFFBCC4D8), fontSize: 12),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: true,
            fillColor: const Color(0xFFFAFBFD),
            border: _borderModerno,
            enabledBorder: _borderModerno,
            focusedBorder: _borderFocus,
            suffixIcon: const Icon(Icons.calendar_today_outlined,
                color: _kAzulINS, size: 17),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownModerno(Campo c) {
    // Campo sexo → botones especiales
    if (c.clave == 'sexo') return _buildSexoModerno(c);
    final val = _dropdowns[c.clave] ?? c.opciones.first;
    return Theme(
      data: ThemeData(brightness: Brightness.light, canvasColor: Colors.white),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFAFBFD),
          border: Border.all(color: const Color(0xFFDDE2F0)),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: c.opciones.contains(val) ? val : c.opciones.first,
            isExpanded: true,
            isDense: true,
            dropdownColor: Colors.white,
            style: const TextStyle(color: Color(0xFF1A1A2E), fontSize: 13),
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: _kAzulINS, size: 20),
            selectedItemBuilder: (_) => c.opciones
                .map((o) => Align(alignment: Alignment.centerLeft,
                    child: Text(o, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF1A1A2E), fontSize: 13))))
                .toList(),
            items: c.opciones
                .map((o) => DropdownMenuItem(value: o,
                    child: Text(o, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF1A1A2E), fontSize: 13))))
                .toList(),
            onChanged: (v) => setState(() => _dropdowns[c.clave] = v ?? ''),
          ),
        ),
      ),
    );
  }

  // Sexo: botones tipo toggle como en la imagen
  Widget _buildSexoModerno(Campo c) {
    final sel = _dropdowns[c.clave] ?? '';
    return Row(children: [
      Expanded(child: GestureDetector(
        onTap: () => setState(() => _dropdowns[c.clave] = 'Femenino'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: sel == 'Femenino' ? _kAzulINS : const Color(0xFFFAFBFD),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: sel == 'Femenino' ? _kAzulINS : const Color(0xFFDDE2F0),
                width: 1.5),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.person_rounded,
                color: sel == 'Femenino' ? Colors.white : const Color(0xFF8898B8),
                size: 16),
            const SizedBox(width: 6),
            Text('Femenino', style: TextStyle(
                color: sel == 'Femenino' ? Colors.white : const Color(0xFF6677A0),
                fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
        ),
      )),
      const SizedBox(width: 8),
      Expanded(child: GestureDetector(
        onTap: () => setState(() => _dropdowns[c.clave] = 'Masculino'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: sel == 'Masculino' ? _kAzulINS : const Color(0xFFFAFBFD),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: sel == 'Masculino' ? _kAzulINS : const Color(0xFFDDE2F0),
                width: 1.5),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.person_outline_rounded,
                color: sel == 'Masculino' ? Colors.white : const Color(0xFF8898B8),
                size: 16),
            const SizedBox(width: 6),
            Text('Masculino', style: TextStyle(
                color: sel == 'Masculino' ? Colors.white : const Color(0xFF6677A0),
                fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
        ),
      )),
    ]);
  }

  Widget _buildSiNoModerno(Campo c) {
    final sel = _radios[c.clave] ?? '';
    return Row(children: [
      for (final op in [('si', '✓  Sí'), ('no', '✗  No')]) ...[
        GestureDetector(
          onTap: () => setState(() => _radios[c.clave] = op.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            decoration: BoxDecoration(
              color: sel == op.$1 ? _kAzulINS : const Color(0xFFFAFBFD),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: sel == op.$1 ? _kAzulINS : const Color(0xFFDDE2F0),
                  width: 1.5),
            ),
            child: Text(op.$2, style: TextStyle(
                color: sel == op.$1 ? Colors.white : const Color(0xFF6677A0),
                fontSize: 12.5, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    ]);
  }

  Widget _buildRadio3Moderno(Campo c) {
    final sel  = _radios[c.clave] ?? '';
    final opts = c.opciones.isNotEmpty
        ? c.opciones : ['1. Sí', '2. No', '3. No sabe'];
    return Wrap(spacing: 8, runSpacing: 8,
        children: opts.map((op) => GestureDetector(
          onTap: () => setState(() => _radios[c.clave] = op),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: sel == op ? _kAzulINS : const Color(0xFFFAFBFD),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: sel == op ? _kAzulINS : const Color(0xFFDDE2F0),
                  width: 1.5),
            ),
            child: Text(op, style: TextStyle(
                color: sel == op ? Colors.white : const Color(0xFF6677A0),
                fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        )).toList());
  }

  Widget _buildCampoINS(Campo c, Color txtColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(c.etiqueta,
              style: TextStyle(color: txtColor, fontSize: 11.5, fontWeight: FontWeight.w600))),
          if (c.requerido)
            const Text(' *', style: TextStyle(color: _kRojo, fontSize: 12, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 4),
        switch (c.tipo) {
          TipoCampo.siNo       => _buildRadioSiNo(c, txtColor),
          TipoCampo.radio3     => _buildRadio3(c, txtColor,
              opciones: c.opciones.isNotEmpty ? c.opciones : ['1. Si','2. No','3. No sabe']),
          TipoCampo.opciones   => _buildOpcionesINS(c, txtColor),
          TipoCampo.fecha      => _buildFechaINS(c, txtColor),
          TipoCampo.multiLinea => _buildTextAreaINS(c, txtColor),
          _                    => _buildTextoINS(c, txtColor),
        },
      ]),
    );
  }

  Widget _buildTextoINS(Campo c, Color txtColor) {
    final ctrl = _ctrls[c.clave] ??= TextEditingController();
    return TextField(
      controller: ctrl,
      keyboardType: c.tipo == TipoCampo.numero ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: txtColor, fontSize: 13),
      decoration: InputDecoration(
        hintText: c.hint ?? '',
        hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 6),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _kLinea)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _kAzulINS, width: 1.5)),
      ),
    );
  }

  Widget _buildTextAreaINS(Campo c, Color txtColor) {
    final ctrl = _ctrls[c.clave] ??= TextEditingController();
    return Container(
      decoration: BoxDecoration(border: Border.all(color: _kLinea)),
      child: TextField(
        controller: ctrl,
        maxLines: 3,
        style: TextStyle(color: txtColor, fontSize: 13),
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.all(8),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildFechaINS(Campo c, Color txtColor) {
    final ctrl = _ctrls[c.clave] ??= TextEditingController();
    return GestureDetector(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
                colorScheme: const ColorScheme.light(primary: _kAzulINS)),
            child: child!,
          ),
        );
        if (d != null) {
          ctrl.text = '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
        }
      },
      child: AbsorbPointer(
        child: TextField(
          controller: ctrl,
          style: TextStyle(color: txtColor, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'dd/mm/aaaa',
            hintStyle: const TextStyle(color: Color(0xFFBBBBBB)),
            suffixIcon: const Icon(Icons.calendar_today_outlined, color: _kAzulINS, size: 16),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 6),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _kLinea)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _kAzulINS, width: 1.5)),
          ),
        ),
      ),
    );
  }

  Widget _buildRadioSiNo(Campo c, Color txtColor) {
    final sel = _radios[c.clave] ?? '';
    return Row(children: [
      _RadioOpcion(label: '1. Si', clave: c.clave, valor: 'si', seleccion: sel,
          color: _kAzulINS, txtColor: txtColor,
          onTap: () => setState(() => _radios[c.clave] = 'si')),
      const SizedBox(width: 20),
      _RadioOpcion(label: '2. No', clave: c.clave, valor: 'no', seleccion: sel,
          color: _kAzulINS, txtColor: txtColor,
          onTap: () => setState(() => _radios[c.clave] = 'no')),
    ]);
  }

  Widget _buildRadio3(Campo c, Color txtColor, {required List<String> opciones}) {
    final sel = _radios[c.clave] ?? '';
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: opciones.map((op) => _RadioOpcion(
        label: op, clave: c.clave, valor: op, seleccion: sel,
        color: _kAzulINS, txtColor: txtColor,
        onTap: () => setState(() => _radios[c.clave] = op),
      )).toList(),
    );
  }

  // ── FIX: Dropdown siempre blanco con texto negro ────────────────────────
  Widget _buildOpcionesINS(Campo c, Color txtColor) {
    final val = _dropdowns[c.clave] ?? c.opciones.first;
    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        canvasColor: Colors.white,
      ),
      child: Container(
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _kLinea))),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: c.opciones.contains(val) ? val : c.opciones.first,
            isExpanded: true,
            isDense: true,
            dropdownColor: Colors.white,
            style: const TextStyle(color: Color(0xFF111111), fontSize: 13),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _kAzulINS),
            selectedItemBuilder: (_) => c.opciones
                .map((o) => Align(
                      alignment: Alignment.centerLeft,
                      child: Text(o,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFF111111), fontSize: 13)),
                    ))
                .toList(),
            items: c.opciones
                .map((o) => DropdownMenuItem(
                      value: o,
                      child: Text(o,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFF111111), fontSize: 13)),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _dropdowns[c.clave] = v ?? ''),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  ENCABEZADO INSTITUCIONAL INS
// ═══════════════════════════════════════════════════════════════════════════
class _EncabezadoINS extends StatelessWidget {
  final String nombreFicha, codigoFicha;
  const _EncabezadoINS({required this.nombreFicha, required this.codigoFicha});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(children: [
        Container(
  color: Colors.white,
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  child: Row(children: [
    Image.asset('assets/logo_dispersalud.png', height: 36, width: 36),
    const SizedBox(width: 10),
    Container(width: 1, height: 40, color: const Color(0xFFDDDDDD)),
    const SizedBox(width: 14),
    Image.asset('assets/logos_ins/logo_colombia.png', height: 26),
    const SizedBox(width: 10),
    Image.asset('assets/logos_ins/logo_salud.png', height: 22),
    const SizedBox(width: 10),
    Image.asset('assets/logos_ins/logo_ins.png', height: 26),
    const Spacer(),
    Image.asset('assets/logos_ins/logo_sivigila.png', height: 28),
  ]),
),
        Container(
          width: double.infinity,
          color: const Color(0xFFF0F4FF),
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: const Text(
            'SISTEMA NACIONAL DE VIGILANCIA EN SALUD PÚBLICA – Subsistema de información Sivigila\nFormulario de recolección',
            textAlign: TextAlign.center,
            style: TextStyle(color: _kAzulINS, fontSize: 9.5, fontWeight: FontWeight.w500, height: 1.4),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: Colors.white,
          child: Text(nombreFicha,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF111111), fontSize: 14, fontWeight: FontWeight.bold)),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(bottom: 6),
          color: Colors.white,
          child: Text('Código: SIVIGILA-$codigoFicha  •  Versión: 2024',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF666666), fontSize: 9)),
        ),
        const Divider(height: 1, color: Color(0xFFCCCCCC)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  WIDGET: Radio opción estilo INS
// ═══════════════════════════════════════════════════════════════════════════
class _RadioOpcion extends StatelessWidget {
  final String  label, clave, valor, seleccion;
  final Color   color, txtColor;
  final VoidCallback onTap;

  const _RadioOpcion({
    required this.label,    required this.clave,
    required this.valor,    required this.seleccion,
    required this.color,    required this.txtColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sel = seleccion == valor;
    return GestureDetector(
      onTap: onTap,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 16, height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: sel ? color : const Color(0xFF888888), width: 1.5),
            color: sel ? color : Colors.transparent,
          ),
          child: sel
              ? const Center(child: Icon(Icons.circle, size: 6, color: Colors.white))
              : null,
        ),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(
            color: sel ? color : txtColor,
            fontSize: 12,
            fontWeight: sel ? FontWeight.w700 : FontWeight.normal)),
      ]),
    );
  }
}
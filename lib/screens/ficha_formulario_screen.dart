// ignore_for_file: use_build_context_synchronously
// lib/screens/ficha_formulario_screen.dart
//
// Formulario SIVIGILA — DISPERSALUD IA
// Diseño fiel al formulario oficial del INS:
//   • Encabezado institucional (Colombia Potencia de la Vida, Salud, INS, SIVIGILA)
//   • Secciones con borde azul y cabecera gris tipo tabla
//   • Campos de texto con línea inferior (estilo formulario papel)
//   • Radio horizontal para opciones (1. Sí  2. No  3. No sabe)
//   • Checkboxes para grupos poblacionales
//   • Fondo blanco con tipografía formal

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/app_theme.dart';
import '../database/database_helper.dart';

DispersaludColors _c(BuildContext ctx) =>
    Theme.of(ctx).extension<DispersaludColors>() ?? DispersaludColors.dark;

// ── Colores institucionales INS ──────────────────────────────────────────────
const _kAzulINS    = Color(0xFF003A8C);   // azul oscuro INS
const _kAzulClaro  = Color(0xFF1565C0);   // azul sección header
const _kVerdeINS   = Color(0xFF1D9E75);   // verde DISPERSALUD
const _kGrisHeader = Color(0xFFE8EAF0);   // gris cabecera sección
const _kLinea      = Color(0xFFCCCCCC);   // línea campo
const _kRojo       = Color(0xFFE24B4A);

// ═══════════════════════════════════════════════════════════════════════════
//  MODELO DE CAMPO (público para mme_secciones.dart)
// ═══════════════════════════════════════════════════════════════════════════
enum TipoCampo { texto, numero, fecha, opciones, multiLinea, siNo, radio3, checkboxes }

// Alias privado para compatibilidad interna
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
// Alias privado
typedef _Campo = Campo;

class Seccion {
  final String       titulo;
  final List<Campo>  campos;
  const Seccion({required this.titulo, required this.campos});
}
typedef _Seccion = Seccion;

// ── Secciones comunes ─────────────────────────────────────────────────────────
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

// ── Campos específicos por evento ─────────────────────────────────────────────
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
//  PANTALLA — Formulario estilo INS
// ═══════════════════════════════════════════════════════════════════════════
class FichaFormularioScreen extends StatefulWidget {
  final String codigoFicha, nombreFicha, emojiFicha;
  final Color  colorFicha;
  final int?   fichaId;

  const FichaFormularioScreen({
    super.key,
    required this.codigoFicha,
    required this.nombreFicha,
    required this.colorFicha,
    required this.emojiFicha,
    this.fichaId,
  });

  @override
  State<FichaFormularioScreen> createState() => _FichaFormularioScreenState();
}

class _FichaFormularioScreenState extends State<FichaFormularioScreen> {
  final Map<String, TextEditingController> _ctrls    = {};
  final Map<String, String>                _dropdowns = {};
  final Map<String, String>                _radios    = {};   // clave → valor seleccionado
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
            _radios[c.clave] = '';          // vacío = sin marcar
          case TipoCampo.radio3:
            _radios[c.clave] = '';
          default:
            _ctrls[c.clave] = TextEditingController();
        }
      }
    }
    if (widget.fichaId != null) _cargarDatos();
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
        if (_ctrls.containsKey(key))      _ctrls[key]!.text = v;
        else if (_dropdowns.containsKey(key)) _dropdowns[key] = v;
        else if (_radios.containsKey(key)) _radios[key] = v;
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

  Future<void> _exportarPDF() async {
    setState(() => _exportando = true);
    try {
      final datos = _recolectar();
      final pdf   = pw.Document();

      for (final sec in _secciones) {
        pdf.addPage(pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          build: (_) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _pdfEncabezado(),
              pw.SizedBox(height: 10),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                color: PdfColor.fromHex('003A8C'),
                child: pw.Text(sec.titulo,
                    style: pw.TextStyle(
                        color: PdfColors.white, fontSize: 10,
                        fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 6),
              ...sec.campos.map((c) => _pdfCampo(c, datos)),
              pw.Spacer(),
              pw.Divider(color: PdfColors.grey400),
              pw.Text('DISPERSALUD IA  •  Formulario SIVIGILA  •  Instituto Nacional de Salud — Colombia',
                  style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
            ],
          ),
        ));
      }
      await Printing.layoutPdf(onLayout: (_) => pdf.save());
      if (mounted) _snack('✅ PDF generado');
    } catch (e) {
      if (mounted) _snack('Error PDF: $e', color: _kRojo);
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  // ── PDF helpers ──────────────────────────────────────────────────────────
  pw.Widget _pdfEncabezado() => pw.Container(
    width: double.infinity,
    decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
    child: pw.Column(children: [
      pw.Container(
        color: PdfColor.fromHex('003A8C'),
        padding: const pw.EdgeInsets.all(8),
        child: pw.Row(children: [
          pw.Text('🇨🇴  SISTEMA NACIONAL DE VIGILANCIA EN SALUD PÚBLICA',
              style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.Spacer(),
          pw.Text('SIVIGILA', style: pw.TextStyle(color: PdfColors.white, fontSize: 11, fontWeight: pw.FontWeight.bold)),
        ]),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
          pw.Text('Formulario de recolección', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          pw.SizedBox(height: 2),
          pw.Text(widget.nombreFicha,
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center),
          pw.Text('Código: ${widget.codigoFicha}  •  Generado: ${DateTime.now().toString().substring(0,16)}',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ]),
      ),
    ]),
  );

  pw.Widget _pdfCampo(Campo c, Map<String, dynamic> datos) {
    final val = datos[c.clave]?.toString() ?? '';
    final displayVal = val.isEmpty ? '___________________________' : val;
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.SizedBox(
          width: 200,
          child: pw.Text(c.etiqueta,
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
        ),
        pw.Expanded(child: pw.Container(
          decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey500, width: 0.5))),
          child: pw.Text(
            c.tipo == TipoCampo.siNo
                ? (val == 'si' ? '☑ Sí  ☐ No' : val == 'no' ? '☐ Sí  ☑ No' : '☐ Sí  ☐ No')
                : displayVal,
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
        )),
      ]),
    );
  }

  void _snack(String msg, {Color? color}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg), backgroundColor: color ?? _kVerdeINS,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));

  // ═══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final dc  = _c(context);
    // Usamos fondo blanco para simular el formulario de papel
    const bgForm  = Colors.white;
    const txtForm = Color(0xFF111111);
    const borde   = Color(0xFFDDDDDD);

    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        backgroundColor: _kAzulINS,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.nombreFicha,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('Formulario SIVIGILA  •  Código: ${widget.codigoFicha}',
              style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ]),
        actions: [
          IconButton(
            tooltip: 'Exportar PDF',
            icon: _exportando
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
            onPressed: _exportando ? null : _exportarPDF,
          ),
          IconButton(
            tooltip: 'Guardar ficha',
            icon: _guardando
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.save_rounded, color: Colors.white),
            onPressed: _guardando ? null : _guardar,
          ),
        ],
      ),
      body: Column(children: [

        // ── Encabezado institucional INS ──────────────────────────────────
        _EncabezadoINS(
          nombreFicha: widget.nombreFicha,
          codigoFicha: widget.codigoFicha,
        ),

        // ── Tabs de secciones ─────────────────────────────────────────────
        Container(
          color: _kAzulINS,
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            itemCount: _secciones.length,
            itemBuilder: (_, i) {
              final activo = i == _seccionIdx;
              return GestureDetector(
                onTap: () => setState(() => _seccionIdx = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: activo ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                        color: activo ? Colors.white : Colors.white38),
                  ),
                  child: Center(child: Text(
                    '${i + 1}',
                    style: TextStyle(
                        color: activo ? _kAzulINS : Colors.white,
                        fontSize: 12, fontWeight: FontWeight.bold),
                  )),
                ),
              );
            },
          ),
        ),

        // ── Cuerpo del formulario ─────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Container(
              decoration: BoxDecoration(
                color: bgForm,
                border: Border.all(color: borde),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Cabecera de sección (fondo azul oscuro)
                Container(
                  width: double.infinity,
                  color: _kAzulINS,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(children: [
                    Expanded(child: Text(
                      _secciones[_seccionIdx].titulo.toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11,
                          fontWeight: FontWeight.bold, letterSpacing: 0.3),
                    )),
                    Text(
                      '${_seccionIdx + 1} / ${_secciones.length}',
                      style: const TextStyle(color: Colors.white60, fontSize: 10),
                    ),
                  ]),
                ),

                // Campos de la sección
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _secciones[_seccionIdx].campos
                        .map((c) => _buildCampoINS(c, txtForm))
                        .toList(),
                  ),
                ),

                // Navegación
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  child: Row(children: [
                    if (_seccionIdx > 0) ...[
                      Expanded(child: OutlinedButton.icon(
                        icon: const Icon(Icons.arrow_back_ios_rounded, size: 13),
                        label: const Text('Anterior'),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: _kAzulINS,
                            side: const BorderSide(color: _kAzulINS),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
                        onPressed: () => setState(() => _seccionIdx--),
                      )),
                      const SizedBox(width: 8),
                    ],
                    Expanded(child: _seccionIdx < _secciones.length - 1
                        ? ElevatedButton.icon(
                            icon: const Icon(Icons.arrow_forward_ios_rounded,
                                size: 13, color: Colors.white),
                            label: const Text('Siguiente sección',
                                style: TextStyle(color: Colors.white, fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: _kAzulINS,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
                            onPressed: () => setState(() => _seccionIdx++),
                          )
                        : ElevatedButton.icon(
                            icon: _guardando
                                ? const SizedBox(width: 16, height: 16,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.save_rounded,
                                    color: Colors.white, size: 18),
                            label: Text(
                              _guardando ? 'Guardando...' : 'Guardar ficha',
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: _kVerdeINS,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4))),
                            onPressed: _guardando ? null : _guardar,
                          )),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  BUILDERS DE CAMPO — estilo formulario oficial INS
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildCampoINS(Campo c, Color txtColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Etiqueta del campo
        Row(children: [
          Expanded(child: Text(
            c.etiqueta,
            style: TextStyle(
                color: txtColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w600),
          )),
          if (c.requerido)
            const Text(' *', style: TextStyle(color: _kRojo, fontSize: 12, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 4),

        // Contenido según tipo
        switch (c.tipo) {
          TipoCampo.siNo     => _buildRadioSiNo(c, txtColor),
          TipoCampo.radio3   => _buildRadio3(c, txtColor,
              opciones: c.opciones.isNotEmpty ? c.opciones : ['1. Si','2. No','3. No sabe']),
          TipoCampo.opciones => _buildOpcionesINS(c, txtColor),
          TipoCampo.fecha    => _buildFechaINS(c, txtColor),
          TipoCampo.multiLinea => _buildTextAreaINS(c, txtColor),
          _                  => _buildTextoINS(c, txtColor),
        },
      ]),
    );
  }

  // ── Texto simple con línea inferior ────────────────────────────────────────
  Widget _buildTextoINS(Campo c, Color txtColor) {
    final ctrl = _ctrls[c.clave] ??= TextEditingController();
    return TextField(
      controller: ctrl,
      keyboardType: c.tipo == TipoCampo.numero
          ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: txtColor, fontSize: 13),
      decoration: InputDecoration(
        hintText: c.hint ?? '',
        hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 6),
        enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: _kLinea)),
        focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: _kAzulINS, width: 1.5)),
      ),
    );
  }

  // ── Texto multilínea ───────────────────────────────────────────────────────
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

  // ── Fecha con selector ─────────────────────────────────────────────────────
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
          ctrl.text =
              '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
        }
      },
      child: AbsorbPointer(
        child: TextField(
          controller: ctrl,
          style: TextStyle(color: txtColor, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'dd/mm/aaaa',
            hintStyle: const TextStyle(color: Color(0xFFBBBBBB)),
            suffixIcon: const Icon(Icons.calendar_today_outlined,
                color: _kAzulINS, size: 16),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 6),
            enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: _kLinea)),
            focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: _kAzulINS, width: 1.5)),
          ),
        ),
      ),
    );
  }

  // ── Radio horizontal Sí / No (estilo INS) ─────────────────────────────────
  Widget _buildRadioSiNo(Campo c, Color txtColor) {
    final sel = _radios[c.clave] ?? '';
    return Row(children: [
      _RadioOpcion(label: '1. Si',  clave: c.clave, valor: 'si',  seleccion: sel,
          color: _kAzulINS, txtColor: txtColor,
          onTap: () => setState(() => _radios[c.clave] = 'si')),
      const SizedBox(width: 20),
      _RadioOpcion(label: '2. No',  clave: c.clave, valor: 'no',  seleccion: sel,
          color: _kAzulINS, txtColor: txtColor,
          onTap: () => setState(() => _radios[c.clave] = 'no')),
    ]);
  }

  // ── Radio horizontal con 3+ opciones numeradas ─────────────────────────────
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

  // ── Dropdown estilo línea inferior ─────────────────────────────────────────
  Widget _buildOpcionesINS(Campo c, Color txtColor) {
    final val = _dropdowns[c.clave] ?? c.opciones.first;
    return Container(
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _kLinea))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: c.opciones.contains(val) ? val : c.opciones.first,
          isExpanded: true,
          isDense: true,
          style: TextStyle(color: txtColor, fontSize: 13),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _kAzulINS),
          items: c.opciones.map((o) => DropdownMenuItem(
              value: o,
              child: Text(o, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: txtColor, fontSize: 13)))).toList(),
          onChanged: (v) => setState(() => _dropdowns[c.clave] = v ?? ''),
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
        // Franja superior azul con logos institucionales
        Container(
          color: _kAzulINS,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            // Texto "Colombia Potencia de la Vida"
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4)),
              child: const Column(children: [
                Text('🇨🇴', style: TextStyle(fontSize: 16)),
                Text('COLOMBIA', style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)),
                Text('POTENCIA', style: TextStyle(color: Colors.white, fontSize: 6)),
                Text('DE LA VIDA', style: TextStyle(color: Colors.white, fontSize: 6)),
              ]),
            ),
            const SizedBox(width: 8),
            // Salud
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(4)),
              child: const Text('Salud', style: TextStyle(
                  color: _kAzulINS, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            // INS
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(4)),
              child: const Column(children: [
                Text('INS', style: TextStyle(
                    color: _kAzulINS, fontSize: 10, fontWeight: FontWeight.bold)),
                Text('INSTITUTO\nNACIONAL\nDE SALUD',
                    style: TextStyle(color: _kAzulINS, fontSize: 5),
                    textAlign: TextAlign.center),
              ]),
            ),
            const Spacer(),
            // SIVIGILA
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(4)),
              child: const Column(children: [
                Text('SIVIGILA', style: TextStyle(
                    color: _kAzulINS, fontSize: 11, fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
                Text('S U I T E', style: TextStyle(
                    color: _kAzulClaro, fontSize: 7, letterSpacing: 2)),
              ]),
            ),
          ]),
        ),

        // Subtítulo del sistema
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

        // Nombre de la ficha
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: Colors.white,
          child: Text(
            nombreFicha,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Color(0xFF111111), fontSize: 14,
                fontWeight: FontWeight.bold),
          ),
        ),

        // Código FOR
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(bottom: 6),
          color: Colors.white,
          child: Text(
            'Código: SIVIGILA-$codigoFicha  •  Versión: 2024',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF666666), fontSize: 9),
          ),
        ),

        const Divider(height: 1, color: Color(0xFFCCCCCC)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  WIDGET: Radio opción estilo INS (○ 1. Si)
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
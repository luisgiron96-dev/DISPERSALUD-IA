// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/app_theme.dart';
import '../database/database_helper.dart';

DispersaludColors _c(BuildContext ctx) =>
    Theme.of(ctx).extension<DispersaludColors>() ?? DispersaludColors.dark;

const _kVerde   = Color(0xFF1D9E75);
const _kRojo    = Color(0xFFE24B4A);
const _kAzul    = Color(0xFF185FA5);

// ═══════════════════════════════════════════════════════════════════════════
//  MODELO DE CAMPO
// ═══════════════════════════════════════════════════════════════════════════
enum _TipoCampo { texto, numero, fecha, opciones, multiLinea, siNo }

class _Campo {
  final String clave, etiqueta;
  final _TipoCampo tipo;
  final List<String> opciones;
  final bool requerido;
  final String? hint;
  const _Campo({
    required this.clave,
    required this.etiqueta,
    this.tipo = _TipoCampo.texto,
    this.opciones = const [],
    this.requerido = false,
    this.hint,
  });
}

class _Seccion {
  final String titulo;
  final List<_Campo> campos;
  const _Seccion({required this.titulo, required this.campos});
}

// ── Secciones comunes ─────────────────────────────────────────────────────
const _secPaciente = _Seccion(titulo: '1. Datos del Paciente', campos: [
  _Campo(clave: 'nombre_paciente',    etiqueta: 'Nombre completo', requerido: true),
  _Campo(clave: 'tipo_doc',           etiqueta: 'Tipo de documento',
      tipo: _TipoCampo.opciones,
      opciones: ['CC','TI','RC','CE','PA','NUI','MS','AS','CN','CD']),
  _Campo(clave: 'num_doc',            etiqueta: 'Número de documento'),
  _Campo(clave: 'fecha_nacimiento',   etiqueta: 'Fecha de nacimiento', tipo: _TipoCampo.fecha),
  _Campo(clave: 'edad',               etiqueta: 'Edad', tipo: _TipoCampo.numero),
  _Campo(clave: 'unidad_edad',        etiqueta: 'Unidad de edad',
      tipo: _TipoCampo.opciones, opciones: ['Años','Meses','Días','Horas']),
  _Campo(clave: 'sexo',               etiqueta: 'Sexo',
      tipo: _TipoCampo.opciones, opciones: ['Masculino','Femenino','Indeterminado']),
  _Campo(clave: 'pertenencia_etnica', etiqueta: 'Pertenencia étnica',
      tipo: _TipoCampo.opciones,
      opciones: ['Indígena','ROM','Raizal','Palenquero','Afrocolombiano','Otro']),
  _Campo(clave: 'estrato',            etiqueta: 'Estrato',
      tipo: _TipoCampo.opciones, opciones: ['0','1','2','3','4','5','6']),
  _Campo(clave: 'departamento',       etiqueta: 'Departamento de residencia'),
  _Campo(clave: 'municipio',          etiqueta: 'Municipio de residencia', requerido: true),
  _Campo(clave: 'direccion',          etiqueta: 'Dirección / Barrio / Vereda'),
  _Campo(clave: 'telefono',           etiqueta: 'Teléfono', tipo: _TipoCampo.numero),
  _Campo(clave: 'ocupacion',          etiqueta: 'Ocupación'),
  _Campo(clave: 'regimen_salud',      etiqueta: 'Régimen de salud',
      tipo: _TipoCampo.opciones,
      opciones: ['Contributivo','Subsidiado','Excepción','Especial','No asegurado']),
  _Campo(clave: 'nombre_aseguradora', etiqueta: 'Nombre aseguradora'),
]);

const _secNotificacion = _Seccion(titulo: '2. Datos de Notificación', campos: [
  _Campo(clave: 'cod_ups',            etiqueta: 'Código UPS', tipo: _TipoCampo.numero),
  _Campo(clave: 'nombre_ups',         etiqueta: 'Nombre UPS notificante', requerido: true),
  _Campo(clave: 'tipo_ups',           etiqueta: 'Tipo UPS',
      tipo: _TipoCampo.opciones, opciones: ['IPS','Laboratorio','Banco de sangre','Otro']),
  _Campo(clave: 'fecha_consulta',     etiqueta: 'Fecha de consulta', tipo: _TipoCampo.fecha, requerido: true),
  _Campo(clave: 'fecha_notificacion', etiqueta: 'Fecha de notificación', tipo: _TipoCampo.fecha, requerido: true),
  _Campo(clave: 'semana_epidemiologica', etiqueta: 'Semana epidemiológica', tipo: _TipoCampo.numero),
  _Campo(clave: 'nombre_notificador', etiqueta: 'Nombre del notificador'),
  _Campo(clave: 'cargo_notificador',  etiqueta: 'Cargo del notificador'),
]);

const _secClinica = _Seccion(titulo: '3. Datos Clínicos', campos: [
  _Campo(clave: 'fecha_inicio_sintomas', etiqueta: 'Fecha inicio síntomas', tipo: _TipoCampo.fecha),
  _Campo(clave: 'tipo_caso',          etiqueta: 'Tipo de caso',
      tipo: _TipoCampo.opciones,
      opciones: ['Sospechoso','Probable','Confirmado laboratorio',
                 'Confirmado clínico','Confirmado nexo epidemiológico','Descartado']),
  _Campo(clave: 'hospitalizacion',    etiqueta: '¿Hospitalizado?', tipo: _TipoCampo.siNo),
  _Campo(clave: 'fecha_hospitalizacion', etiqueta: 'Fecha hospitalización', tipo: _TipoCampo.fecha),
  _Campo(clave: 'condicion_final',    etiqueta: 'Condición final',
      tipo: _TipoCampo.opciones, opciones: ['Vivo','Muerto']),
  _Campo(clave: 'causa_muerte',       etiqueta: 'Causa de muerte (si aplica)'),
]);

const _secLab = _Seccion(titulo: '4. Laboratorio', campos: [
  _Campo(clave: 'muestra_tomada',     etiqueta: '¿Muestra tomada?', tipo: _TipoCampo.siNo),
  _Campo(clave: 'tipo_muestra',       etiqueta: 'Tipo de muestra',
      tipo: _TipoCampo.opciones,
      opciones: ['Sangre','Suero','Orina','Heces','LCR','Hisopado','Biopsia','Otra']),
  _Campo(clave: 'fecha_muestra',      etiqueta: 'Fecha de muestra', tipo: _TipoCampo.fecha),
  _Campo(clave: 'resultado_lab',      etiqueta: 'Resultado',
      tipo: _TipoCampo.opciones,
      opciones: ['Positivo','Negativo','En proceso','Indeterminado','No aplica']),
  _Campo(clave: 'prueba_realizada',   etiqueta: 'Prueba realizada', hint: 'PCR, ELISA, cultivo...'),
  _Campo(clave: 'laboratorio',        etiqueta: 'Laboratorio que procesó'),
]);

const _secTratamiento = _Seccion(titulo: '5. Tratamiento', campos: [
  _Campo(clave: 'tratamiento',        etiqueta: 'Tratamiento instaurado', tipo: _TipoCampo.multiLinea),
  _Campo(clave: 'fecha_inicio_tto',   etiqueta: 'Fecha inicio tratamiento', tipo: _TipoCampo.fecha),
  _Campo(clave: 'seguimiento',        etiqueta: 'Plan de seguimiento', tipo: _TipoCampo.multiLinea),
  _Campo(clave: 'nexo_epidemiologico',etiqueta: 'Nexo epidemiológico', tipo: _TipoCampo.multiLinea),
]);

const _secObs = _Seccion(titulo: '6. Observaciones', campos: [
  _Campo(clave: 'observaciones', etiqueta: 'Observaciones generales', tipo: _TipoCampo.multiLinea),
]);

// ── Campos específicos por evento ─────────────────────────────────────────
const Map<String, _Seccion> _especificos = {
  'DEN': _Seccion(titulo: 'Clínica Dengue', campos: [
    _Campo(clave: 'fiebre',      etiqueta: 'Fiebre',              tipo: _TipoCampo.siNo),
    _Campo(clave: 'cefalea',     etiqueta: 'Cefalea retrocular',  tipo: _TipoCampo.siNo),
    _Campo(clave: 'mialgia',     etiqueta: 'Mialgia/Artralgia',   tipo: _TipoCampo.siNo),
    _Campo(clave: 'exantema',    etiqueta: 'Exantema',            tipo: _TipoCampo.siNo),
    _Campo(clave: 'sangrado',    etiqueta: 'Sangrado',            tipo: _TipoCampo.siNo),
    _Campo(clave: 'tipo_dengue', etiqueta: 'Clasificación final',
        tipo: _TipoCampo.opciones,
        opciones: ['Sin signos de alarma','Con signos de alarma','Grave']),
    _Campo(clave: 'serotipo',    etiqueta: 'Serotipo',
        tipo: _TipoCampo.opciones,
        opciones: ['DENV-1','DENV-2','DENV-3','DENV-4','No determinado']),
  ]),
  'CHIK': _Seccion(titulo: 'Clínica Chikunguña', campos: [
    _Campo(clave: 'fiebre_chik',   etiqueta: 'Fiebre > 38.5°C',   tipo: _TipoCampo.siNo),
    _Campo(clave: 'artralgia',     etiqueta: 'Artralgia intensa',  tipo: _TipoCampo.siNo),
    _Campo(clave: 'exantema_chik', etiqueta: 'Exantema',          tipo: _TipoCampo.siNo),
    _Campo(clave: 'fase',          etiqueta: 'Fase',
        tipo: _TipoCampo.opciones, opciones: ['Aguda','Subaguda','Crónica']),
  ]),
  'ZIKA': _Seccion(titulo: 'Clínica Zika', campos: [
    _Campo(clave: 'embarazada',    etiqueta: '¿Gestante?',         tipo: _TipoCampo.siNo),
    _Campo(clave: 'sem_gestacion', etiqueta: 'Semanas gestación',  tipo: _TipoCampo.numero),
    _Campo(clave: 'exantema_zika', etiqueta: 'Exantema pruriginoso', tipo: _TipoCampo.siNo),
    _Campo(clave: 'microcefalia',  etiqueta: '¿Microcefalia RN?', tipo: _TipoCampo.siNo),
  ]),
  'MAL': _Seccion(titulo: 'Clínica Malaria', campos: [
    _Campo(clave: 'especie',       etiqueta: 'Especie Plasmodium',
        tipo: _TipoCampo.opciones,
        opciones: ['P. falciparum','P. vivax','P. malariae','Mixto','No determinado']),
    _Campo(clave: 'parasitemia',   etiqueta: 'Parasitemia (parásitos/µL)', tipo: _TipoCampo.numero),
    _Campo(clave: 'tipo_malaria',  etiqueta: 'Tipo de malaria',
        tipo: _TipoCampo.opciones, opciones: ['No complicada','Complicada/Grave']),
    _Campo(clave: 'antimalárico',  etiqueta: 'Antimalárico administrado'),
  ]),
  'TUB': _Seccion(titulo: 'Clínica Tuberculosis', campos: [
    _Campo(clave: 'tipo_tb',       etiqueta: 'Tipo de TB',
        tipo: _TipoCampo.opciones, opciones: ['Pulmonar','Extrapulmonar','Miliar']),
    _Campo(clave: 'baciloscopia',  etiqueta: 'Baciloscopia',
        tipo: _TipoCampo.opciones, opciones: ['+1','+2','+3','Negativo','No realizada']),
    _Campo(clave: 'cultivo_tb',    etiqueta: 'Cultivo',
        tipo: _TipoCampo.opciones, opciones: ['Positivo','Negativo','No realizado']),
    _Campo(clave: 'sensibilidad',  etiqueta: 'Sensibilidad (DST)',
        tipo: _TipoCampo.opciones, opciones: ['Sensible','MDR','XDR','No realizada']),
    _Campo(clave: 'vih_tb',        etiqueta: 'Coinfección VIH',
        tipo: _TipoCampo.opciones, opciones: ['Positivo','Negativo','Desconocido']),
    _Campo(clave: 'contactos',     etiqueta: 'N° contactos', tipo: _TipoCampo.numero),
  ]),
  'VIH': _Seccion(titulo: 'Clínica VIH/SIDA', campos: [
    _Campo(clave: 'estadio',       etiqueta: 'Estadio OMS',
        tipo: _TipoCampo.opciones, opciones: ['I','II','III','IV']),
    _Campo(clave: 'cd4',           etiqueta: 'CD4 (cel/mm³)',      tipo: _TipoCampo.numero),
    _Campo(clave: 'carga_viral',   etiqueta: 'Carga viral (copias/mL)', tipo: _TipoCampo.numero),
    _Campo(clave: 'via_transmision', etiqueta: 'Vía de transmisión',
        tipo: _TipoCampo.opciones, opciones: ['Sexual','Parenteral','Vertical','Desconocida']),
    _Campo(clave: 'tar',           etiqueta: '¿En TAR?',           tipo: _TipoCampo.siNo),
    _Campo(clave: 'esquema_tar',   etiqueta: 'Esquema TAR'),
  ]),
  'IRA': _Seccion(titulo: 'Clínica IRA', campos: [
    _Campo(clave: 'tipo_ira',      etiqueta: 'Tipo IRA',
        tipo: _TipoCampo.opciones,
        opciones: ['IRA alta','Neumonía','Bronquiolitis','Influenza','COVID-19','Otra']),
    _Campo(clave: 'fr_minuto',     etiqueta: 'Frecuencia respiratoria/min', tipo: _TipoCampo.numero),
    _Campo(clave: 'saturacion',    etiqueta: 'Saturación O₂ (%)',  tipo: _TipoCampo.numero),
    _Campo(clave: 'requirio_uci',  etiqueta: '¿Requirió UCI?',    tipo: _TipoCampo.siNo),
    _Campo(clave: 'ventilacion',   etiqueta: '¿Ventilación mecánica?', tipo: _TipoCampo.siNo),
  ]),
  'EDA': _Seccion(titulo: 'Clínica EDA', campos: [
    _Campo(clave: 'num_deposiciones', etiqueta: 'N° deposiciones/día', tipo: _TipoCampo.numero),
    _Campo(clave: 'tipo_deposicion', etiqueta: 'Tipo de deposición',
        tipo: _TipoCampo.opciones,
        opciones: ['Líquida','Con moco','Con sangre','Con moco y sangre']),
    _Campo(clave: 'deshidratacion', etiqueta: 'Deshidratación',
        tipo: _TipoCampo.opciones,
        opciones: ['Sin deshidratación','Leve-moderada','Grave']),
    _Campo(clave: 'vomito',         etiqueta: '¿Vómito?',          tipo: _TipoCampo.siNo),
    _Campo(clave: 'brote',          etiqueta: '¿Asociado a brote?',tipo: _TipoCampo.siNo),
  ]),
  'MME': _Seccion(titulo: 'Mortalidad Materna', campos: [
    _Campo(clave: 'momento_muerte', etiqueta: 'Momento de la muerte',
        tipo: _TipoCampo.opciones,
        opciones: ['Durante embarazo','Durante parto','Dentro de 42 días puerperio','Entre 43 días y 1 año']),
    _Campo(clave: 'sem_gest_mm',    etiqueta: 'Semanas de gestación', tipo: _TipoCampo.numero),
    _Campo(clave: 'num_controles',  etiqueta: 'N° controles prenatales', tipo: _TipoCampo.numero),
    _Campo(clave: 'causa_directa',  etiqueta: 'Causa directa',
        tipo: _TipoCampo.opciones,
        opciones: ['Hemorragia','Hipertensión/Eclampsia','Sepsis','Aborto','Otra']),
    _Campo(clave: 'evitabilidad',   etiqueta: '¿Muerte evitable?',
        tipo: _TipoCampo.opciones, opciones: ['Evitable','No evitable','No determinado']),
  ]),
  'SFILIS': _Seccion(titulo: 'Sífilis Gestacional/Congénita', campos: [
    _Campo(clave: 'tipo_sifilis',   etiqueta: 'Tipo',
        tipo: _TipoCampo.opciones, opciones: ['Gestacional','Congénita']),
    _Campo(clave: 'sem_diagnos',    etiqueta: 'Semanas al diagnóstico', tipo: _TipoCampo.numero),
    _Campo(clave: 'trat_prenatal',  etiqueta: '¿Tratamiento prenatal?', tipo: _TipoCampo.siNo),
    _Campo(clave: 'tto_pareja',     etiqueta: '¿Pareja tratada?',      tipo: _TipoCampo.siNo),
    _Campo(clave: 'vdrl_titulo',    etiqueta: 'Título VDRL'),
  ]),
};

List<_Seccion> _seccionesParaFicha(String codigo) {
  final base = [_secPaciente, _secNotificacion, _secClinica, _secLab, _secTratamiento];
  final esp  = _especificos[codigo];
  if (esp != null) return [...base.sublist(0,2), esp, ...base.sublist(2), _secObs];
  return [...base, _secObs];
}

// ═══════════════════════════════════════════════════════════════════════════
//  PANTALLA FORMULARIO
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
  final Map<String, TextEditingController> _ctrls     = {};
  final Map<String, String>               _dropdowns  = {};
  final Map<String, bool>                 _bools      = {};
  bool  _guardando  = false;
  bool  _exportando = false;
  int   _seccionIdx = 0;
  late  List<_Seccion> _secciones;

  @override
  void initState() {
    super.initState();
    _secciones = _seccionesParaFicha(widget.codigoFicha);
    for (final sec in _secciones) {
      for (final c in sec.campos) {
        if (c.tipo == _TipoCampo.opciones) {
          _dropdowns[c.clave] = c.opciones.isNotEmpty ? c.opciones.first : '';
        } else if (c.tipo == _TipoCampo.siNo) {
          _bools[c.clave] = false;
        } else {
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
        else if (_bools.containsKey(key)) _bools[key] = v == 'true';
      });
    });
  }

  Map<String, dynamic> _recolectar() {
    final m = <String, dynamic>{};
    _ctrls.forEach((k, v)    => m[k] = v.text.trim());
    _dropdowns.forEach((k, v) => m[k] = v);
    _bools.forEach((k, v)    => m[k] = v.toString());
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
      final datos  = _recolectar();
      final pdf    = pw.Document();
      final color  = PdfColor.fromInt(widget.colorFicha.value);

      for (final sec in _secciones) {
        pdf.addPage(pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          build: (_) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                    color: color, borderRadius: pw.BorderRadius.circular(6)),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('DISPERSALUD IA  •  Ficha Epidemiológica SIVIGILA',
                      style: pw.TextStyle(color: PdfColors.white, fontSize: 9)),
                  pw.SizedBox(height: 4),
                  pw.Text('${widget.emojiFicha}  ${widget.nombreFicha}  [${widget.codigoFicha}]',
                      style: pw.TextStyle(color: PdfColors.white, fontSize: 13,
                          fontWeight: pw.FontWeight.bold)),
                  pw.Text('Impreso: ${DateTime.now().toString().substring(0,16)}',
                      style: pw.TextStyle(color: PdfColors.white, fontSize: 8)),
                ]),
              ),
              pw.SizedBox(height: 12),
              pw.Text(sec.titulo,
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: color)),
              pw.Divider(color: color, thickness: 1),
              pw.SizedBox(height: 8),
              ...(_agrupar2(sec.campos).map((par) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Row(children: par.map((c) => pw.Expanded(child:
                  pw.Container(
                    margin: const pw.EdgeInsets.only(right: 6),
                    padding: const pw.EdgeInsets.all(7),
                    decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: pw.BorderRadius.circular(4)),
                    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                      pw.Text(c.etiqueta,
                          style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                      pw.SizedBox(height: 2),
                      pw.Text(_valCampo(c, datos),
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    ]),
                  )
                )).toList()),
              ))),
              pw.Spacer(),
              pw.Text('Generado por DISPERSALUD IA — Protocolo SIVIGILA Colombia',
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

  String _valCampo(_Campo c, Map<String, dynamic> datos) {
    final v = datos[c.clave];
    if (v == null || v.toString().isEmpty) return '—';
    if (c.tipo == _TipoCampo.siNo) return v == 'true' ? 'Sí' : 'No';
    return v.toString();
  }

  List<List<_Campo>> _agrupar2(List<_Campo> campos) {
    final r = <List<_Campo>>[];
    for (var i = 0; i < campos.length; i += 2) {
      r.add(i + 1 < campos.length ? [campos[i], campos[i+1]] : [campos[i]]);
    }
    return r;
  }

  void _snack(String msg, {Color? color}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg), backgroundColor: color ?? _kVerde,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));

  @override
  Widget build(BuildContext context) {
    final dc  = _c(context);
    final col = widget.colorFicha;

    return Scaffold(
      backgroundColor: dc.bg,
      appBar: AppBar(
        backgroundColor: dc.bg, elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: dc.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.nombreFicha,
              style: TextStyle(color: dc.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('Código: ${widget.codigoFicha}  •  SIVIGILA',
              style: TextStyle(color: col, fontSize: 10)),
        ]),
        actions: [
          IconButton(
            tooltip: 'Exportar PDF',
            icon: _exportando
                ? SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: col, strokeWidth: 2))
                : const Icon(Icons.picture_as_pdf_rounded, color: _kRojo),
            onPressed: _exportando ? null : _exportarPDF,
          ),
          IconButton(
            tooltip: 'Guardar',
            icon: _guardando
                ? SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: col, strokeWidth: 2))
                : Icon(Icons.save_rounded, color: col),
            onPressed: _guardando ? null : _guardar,
          ),
        ],
      ),
      body: Column(children: [
        // Pestañas de secciones
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            itemCount: _secciones.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final activo = i == _seccionIdx;
              return GestureDetector(
                onTap: () => setState(() => _seccionIdx = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: activo ? col : dc.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: activo ? col : dc.border),
                  ),
                  child: Center(child: Text('${i+1}',
                      style: TextStyle(
                          color: activo ? Colors.white : dc.textHint,
                          fontSize: 12, fontWeight: FontWeight.bold))),
                ),
              );
            },
          ),
        ),
        // Título de sección
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
          child: Row(children: [
            Container(width: 4, height: 18,
                decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Expanded(child: Text(_secciones[_seccionIdx].titulo,
                style: TextStyle(color: dc.textPrimary, fontSize: 13, fontWeight: FontWeight.bold))),
            Text('${_seccionIdx+1}/${_secciones.length}',
                style: TextStyle(color: dc.textHint, fontSize: 11)),
          ]),
        ),
        // Campos
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
            children: [
              ..._secciones[_seccionIdx].campos.map((c) => _buildCampo(c, dc, col)),
              const SizedBox(height: 16),
              Row(children: [
                if (_seccionIdx > 0) ...[
                  Expanded(child: OutlinedButton.icon(
                    icon: Icon(Icons.arrow_back_ios_rounded, size: 13, color: col),
                    label: Text('Anterior', style: TextStyle(color: col)),
                    style: OutlinedButton.styleFrom(
                        side: BorderSide(color: col),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: () => setState(() => _seccionIdx--),
                  )),
                  const SizedBox(width: 8),
                ],
                Expanded(child: _seccionIdx < _secciones.length - 1
                    ? ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Colors.white),
                        label: const Text('Siguiente', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: col,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        onPressed: () => setState(() => _seccionIdx++),
                      )
                    : ElevatedButton.icon(
                        icon: _guardando
                            ? const SizedBox(width: 16, height: 16,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.save_rounded, color: Colors.white, size: 18),
                        label: Text(_guardando ? 'Guardando...' : 'Guardar ficha',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(backgroundColor: col,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        onPressed: _guardando ? null : _guardar,
                      )),
              ]),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildCampo(_Campo c, DispersaludColors dc, Color col) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(c.etiqueta,
              style: TextStyle(color: dc.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          if (c.requerido)
            Text(' *', style: const TextStyle(color: _kRojo, fontSize: 12, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 5),
        if (c.tipo == _TipoCampo.siNo)     _buildSiNo(c, dc, col)
        else if (c.tipo == _TipoCampo.opciones) _buildDropdown(c, dc)
        else _buildTextField(c, dc, col),
      ]),
    );
  }

  Widget _buildTextField(_Campo c, DispersaludColors dc, Color col) {
    final ctrl = _ctrls[c.clave] ??= TextEditingController();
    return TextField(
      controller: ctrl,
      maxLines: c.tipo == _TipoCampo.multiLinea ? 3 : 1,
      keyboardType: c.tipo == _TipoCampo.numero ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: dc.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: c.hint ?? (c.tipo == _TipoCampo.fecha ? 'DD/MM/AAAA' : ''),
        hintStyle: TextStyle(color: dc.textHint, fontSize: 12),
        filled: true, fillColor: dc.card,
        suffixIcon: c.tipo == _TipoCampo.fecha
            ? GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                          colorScheme: ColorScheme.dark(primary: col)),
                      child: child!,
                    ),
                  );
                  if (d != null) {
                    ctrl.text =
                        '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
                  }
                },
                child: Icon(Icons.calendar_today_outlined, color: dc.textHint, size: 18),
              )
            : null,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: col, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildDropdown(_Campo c, DispersaludColors dc) {
    final val = _dropdowns[c.clave] ?? c.opciones.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: dc.card, borderRadius: BorderRadius.circular(10)),
      child: DropdownButton<String>(
        value: c.opciones.contains(val) ? val : c.opciones.first,
        isExpanded: true, underline: const SizedBox(),
        dropdownColor: dc.card,
        style: TextStyle(color: dc.textPrimary, fontSize: 14),
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: dc.textHint),
        items: c.opciones.map((o) =>
            DropdownMenuItem(value: o, child: Text(o, overflow: TextOverflow.ellipsis))).toList(),
        onChanged: (v) => setState(() => _dropdowns[c.clave] = v ?? ''),
      ),
    );
  }

  Widget _buildSiNo(_Campo c, DispersaludColors dc, Color col) {
    final val = _bools[c.clave] ?? false;
    return Row(children: [
      Expanded(child: GestureDetector(
        onTap: () => setState(() => _bools[c.clave] = true),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: val ? col.withOpacity(0.15) : dc.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: val ? col : dc.border)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.check_circle_rounded, size: 16, color: val ? col : dc.textHint),
            const SizedBox(width: 6),
            Text('Sí', style: TextStyle(color: val ? col : dc.textHint, fontWeight: FontWeight.w600)),
          ]),
        ),
      )),
      const SizedBox(width: 8),
      Expanded(child: GestureDetector(
        onTap: () => setState(() => _bools[c.clave] = false),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: !val ? _kRojo.withOpacity(0.12) : dc.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: !val ? _kRojo : dc.border)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.cancel_rounded, size: 16, color: !val ? _kRojo : dc.textHint),
            const SizedBox(width: 6),
            Text('No', style: TextStyle(color: !val ? _kRojo : dc.textHint, fontWeight: FontWeight.w600)),
          ]),
        ),
      )),
    ]);
  }
}

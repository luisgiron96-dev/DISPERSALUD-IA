import 'dart:typed_data';
import 'package:excel/excel.dart';
import '../database/database_helper.dart';
import 'excel_downloader_stub.dart'
    if (dart.library.html) 'excel_downloader_web.dart'
    if (dart.library.io)   'excel_downloader_mobile.dart';

// ════════════════════════════════════════════════════════════════════════════
//  excel_service.dart  —  DISPERSALUD IA
//  API compatible con excel ^2.1.0
//  En v2.x appendRow recibe List<dynamic> con strings directos
// ════════════════════════════════════════════════════════════════════════════

class ExcelService {
  ExcelService._();
  static final ExcelService instance = ExcelService._();

  Future<String> exportarTodo() async {
    final db = DatabaseHelper.instance;

    final pacientes     = await db.obtenerPacientes();
    final consultas     = await db.obtenerConsultas();
    final alertas       = await db.obtenerAlertas(soloActivas: false);
    final especialistas = await db.obtenerEspecialistas();

    final excel = Excel.createExcel();

    _hojaResumen(excel, pacientes, consultas, alertas);
    _hojaPacientes(excel, pacientes);
    _hojaConsultas(excel, consultas, pacientes);
    _hojaSignosVitales(excel, consultas, pacientes);
    _hojaAlertas(excel, alertas);
    _hojaEspecialistas(excel, especialistas);
    _hojaHistoriaClinica(excel, pacientes, consultas);
    _hojaMedicamentos(excel);

    // Eliminar hoja vacía por defecto
    // En v2.1.0 delete no funciona — se renombra en su lugar
    try { excel.rename('Sheet1', 'Portada'); } catch (_) {}

    final bytes  = Uint8List.fromList(excel.save()!);
    final nombre = 'DISPERSALUD_${DateTime.now().toString().substring(0, 10)}.xlsx';
    return descargarExcel(bytes, nombre);
  }

  // ── Hoja 1 — Resumen general ─────────────────────────────────────────────
  void _hojaResumen(Excel excel, List<Map<String, dynamic>> pacientes,
      List<Map<String, dynamic>> consultas, List<Map<String, dynamic>> alertas) {
    final s = excel['Resumen General'];
    final f = DateTime.now();
    final fecha =
        '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}  '
        '${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}';

    s.appendRow(['DISPERSALUD IA — Reporte generado: $fecha']);
    s.appendRow(['']);
    s.appendRow(['INDICADOR', 'VALOR']);
    s.appendRow(['Total pacientes',   '${pacientes.length}']);
    s.appendRow(['Total consultas',   '${consultas.length}']);
    s.appendRow(['Alertas activas',   '${alertas.where((a) => a['resuelta'] == 0).length}']);
    s.appendRow(['Alertas resueltas', '${alertas.where((a) => a['resuelta'] == 1).length}']);
    s.appendRow(['']);
    s.appendRow(['PACIENTES POR MÓDULO', 'CANTIDAD']);

    final modulos = <String, int>{};
    for (final p in pacientes) {
      final m = '${p['modulo'] ?? 'Sin módulo'}';
      modulos[m] = (modulos[m] ?? 0) + 1;
    }
    for (final e in modulos.entries) {
      s.appendRow([e.key, '${e.value}']);
    }

    s.appendRow(['']);
    s.appendRow(['CONSULTAS POR NIVEL DE RIESGO', 'CANTIDAD']);
    final riesgos = <String, int>{};
    for (final c in consultas) {
      final r = '${c['nivel_riesgo'] ?? 'estable'}';
      riesgos[r] = (riesgos[r] ?? 0) + 1;
    }
    for (final e in riesgos.entries) {
      s.appendRow([e.key, '${e.value}']);
    }
  }

  // ── Hoja 2 — Pacientes ───────────────────────────────────────────────────
  void _hojaPacientes(Excel excel, List<Map<String, dynamic>> pacientes) {
    final s = excel['Pacientes'];
    s.appendRow(['ID', 'Nombre completo', 'Documento', 'Fecha nacimiento',
      'Sexo', 'Edad', 'Departamento', 'Municipio', 'Vereda',
      'Teléfono', 'EPS', 'Módulo', 'Acudiente', 'Fecha registro']);
    for (final p in pacientes) {
      s.appendRow([
        '${p['id'] ?? ''}',
        '${p['nombre'] ?? ''}',
        '${p['documento'] ?? ''}',
        '${p['fecha_nac'] ?? ''}',
        '${p['sexo'] ?? ''}',
        '${p['edad'] ?? ''}',
        '${p['departamento'] ?? ''}',
        '${p['municipio'] ?? ''}',
        '${p['vereda'] ?? ''}',
        '${p['telefono'] ?? ''}',
        '${p['eps'] ?? ''}',
        '${p['modulo'] ?? ''}',
        '${p['acudiente'] ?? ''}',
        '${p['created_at'] ?? ''}',
      ]);
    }
  }

  // ── Hoja 3 — Consultas y diagnósticos ────────────────────────────────────
  void _hojaConsultas(Excel excel, List<Map<String, dynamic>> consultas,
      List<Map<String, dynamic>> pacientes) {
    final s = excel['Consultas'];
    s.appendRow(['ID', 'Paciente', 'Módulo', 'Fecha',
      'Diagnóstico', 'Nivel de riesgo', 'Observaciones', 'Sincronizado']);
    final mapPac = {for (final p in pacientes) p['id']: p['nombre']};
    for (final c in consultas) {
      s.appendRow([
        '${c['id'] ?? ''}',
        '${mapPac[c['paciente_id']] ?? c['nombre'] ?? ''}',
        '${c['modulo'] ?? ''}',
        '${c['fecha'] ?? ''}',
        '${c['diagnostico'] ?? ''}',
        '${c['nivel_riesgo'] ?? 'estable'}',
        '${c['observaciones'] ?? ''}',
        c['sincronizado'] == 1 ? 'Sí' : 'No',
      ]);
    }
  }

  // ── Hoja 4 — Signos vitales ──────────────────────────────────────────────
  void _hojaSignosVitales(Excel excel, List<Map<String, dynamic>> consultas,
      List<Map<String, dynamic>> pacientes) {
    final s = excel['Signos Vitales'];
    s.appendRow(['Paciente', 'Módulo', 'Fecha',
      'Presión arterial', 'Glucemia', 'Peso (kg)', 'Talla (cm)',
      'Temperatura (°C)', 'SpO2 (%)', 'FC (lpm)', 'IMC',
      'Semanas gestación', 'Nivel riesgo']);
    final mapPac = {for (final p in pacientes) p['id']: p['nombre']};
    for (final c in consultas) {
      final tieneSignos = [c['presion'], c['glucemia'], c['peso'],
        c['talla'], c['temperatura'], c['spo2'], c['fc']]
          .any((v) => v != null && v.toString().isNotEmpty);
      if (!tieneSignos) continue;
      s.appendRow([
        '${mapPac[c['paciente_id']] ?? c['nombre'] ?? ''}',
        '${c['modulo'] ?? ''}',
        '${c['fecha'] ?? ''}',
        '${c['presion'] ?? ''}',
        '${c['glucemia'] ?? ''}',
        '${c['peso'] ?? ''}',
        '${c['talla'] ?? ''}',
        '${c['temperatura'] ?? ''}',
        '${c['spo2'] ?? ''}',
        '${c['fc'] ?? ''}',
        '${c['imc'] ?? ''}',
        '${c['semanas'] ?? ''}',
        '${c['nivel_riesgo'] ?? ''}',
      ]);
    }
  }

  // ── Hoja 5 — Alertas ─────────────────────────────────────────────────────
  void _hojaAlertas(Excel excel, List<Map<String, dynamic>> alertas) {
    final s = excel['Alertas'];
    s.appendRow(['ID', 'Paciente', 'Módulo', 'Mensaje', 'Nivel', 'Estado', 'Fecha']);
    for (final a in alertas) {
      s.appendRow([
        '${a['id'] ?? ''}',
        '${a['paciente'] ?? ''}',
        '${a['modulo'] ?? ''}',
        '${a['mensaje'] ?? ''}',
        '${a['nivel'] ?? ''}',
        a['resuelta'] == 1 ? 'Resuelta' : 'Activa',
        '${a['fecha'] ?? ''}',
      ]);
    }
  }

  // ── Hoja 6 — Especialistas ───────────────────────────────────────────────
  void _hojaEspecialistas(Excel excel, List<Map<String, dynamic>> especialistas) {
    final s = excel['Especialistas'];
    s.appendRow(['Nombre', 'Especialidad', 'Teléfono', 'Municipio',
      'Correo', 'Dirección', 'Horario', 'Notas']);
    for (final e in especialistas) {
      s.appendRow([
        '${e['nombre'] ?? ''}',
        '${e['especialidad'] ?? ''}',
        '${e['telefono'] ?? ''}',
        '${e['municipio'] ?? ''}',
        '${e['correo'] ?? ''}',
        '${e['direccion'] ?? ''}',
        '${e['horario'] ?? ''}',
        '${e['notas'] ?? ''}',
      ]);
    }
  }

  // ── Hoja 7 — Historia Clínica completa por paciente ────────────────────────
  void _hojaHistoriaClinica(Excel excel, List<Map<String, dynamic>> pacientes,
      List<Map<String, dynamic>> consultas) {
    final s = excel['Historia Clinica'];

    // Encabezados
    s.appendRow([
      'Paciente', 'Documento', 'Fecha Nacimiento', 'Sexo', 'Edad',
      'Departamento', 'Municipio', 'Vereda', 'Telefono', 'EPS',
      'Modulo', 'Acudiente',
      // Datos de la consulta
      'Fecha Consulta', 'Diagnostico', 'Nivel Riesgo', 'Observaciones',
      // Signos vitales
      'Presion', 'Glucemia', 'Peso (kg)', 'Talla (cm)',
      'Temperatura (C)', 'SpO2 (%)', 'FC (lpm)', 'IMC', 'Semanas Gestacion',
    ]);

    // Agrupar consultas por paciente
    final mapConsultas = <int, List<Map<String, dynamic>>>{};
    for (final c in consultas) {
      final pid = c['paciente_id'] as int? ?? 0;
      mapConsultas[pid] = [...(mapConsultas[pid] ?? []), c];
    }

    for (final p in pacientes) {
      final pid   = p['id'] as int? ?? 0;
      final consPac = mapConsultas[pid] ?? [];

      if (consPac.isEmpty) {
        // Paciente sin consultas — fila con datos básicos
        s.appendRow([
          '${p['nombre'] ?? ''}',
          '${p['documento'] ?? ''}',
          '${p['fecha_nac'] ?? ''}',
          '${p['sexo'] ?? ''}',
          '${p['edad'] ?? ''}',
          '${p['departamento'] ?? ''}',
          '${p['municipio'] ?? ''}',
          '${p['vereda'] ?? ''}',
          '${p['telefono'] ?? ''}',
          '${p['eps'] ?? ''}',
          '${p['modulo'] ?? ''}',
          '${p['acudiente'] ?? ''}',
          'Sin consultas', '', '', '', '', '', '', '', '', '', '', '', '',
        ]);
      } else {
        // Una fila por cada consulta del paciente
        for (final c in consPac) {
          s.appendRow([
            '${p['nombre'] ?? ''}',
            '${p['documento'] ?? ''}',
            '${p['fecha_nac'] ?? ''}',
            '${p['sexo'] ?? ''}',
            '${p['edad'] ?? ''}',
            '${p['departamento'] ?? ''}',
            '${p['municipio'] ?? ''}',
            '${p['vereda'] ?? ''}',
            '${p['telefono'] ?? ''}',
            '${p['eps'] ?? ''}',
            '${p['modulo'] ?? ''}',
            '${p['acudiente'] ?? ''}',
            '${c['fecha'] ?? ''}',
            '${c['diagnostico'] ?? ''}',
            '${c['nivel_riesgo'] ?? 'estable'}',
            '${c['observaciones'] ?? ''}',
            '${c['presion'] ?? ''}',
            '${c['glucemia'] ?? ''}',
            '${c['peso'] ?? ''}',
            '${c['talla'] ?? ''}',
            '${c['temperatura'] ?? ''}',
            '${c['spo2'] ?? ''}',
            '${c['fc'] ?? ''}',
            '${c['imc'] ?? ''}',
            '${c['semanas'] ?? ''}',
          ]);
        }
      }
    }
  }

  // ── Hoja 8 — Esquemas de medicamentos ────────────────────────────────────
  void _hojaMedicamentos(Excel excel) {
    final s = excel['Medicamentos'];
    s.appendRow(['Medicamento', 'Categoría', 'Presentaciones',
      'Indicaciones', 'Dosis adultos', 'Dosis niños',
      'Contraindicaciones', 'Alertas']);
    for (final m in _catalogo()) {
      final dosis   = m['dosis'] as List? ?? [];
      final dosisAd = dosis.firstWhere(
          (d) => (d['grupo'] as String).toLowerCase().contains('adult'),
          orElse: () => <String, String>{});
      final dosisNi = dosis.firstWhere(
          (d) => (d['grupo'] as String).toLowerCase().contains('ni'),
          orElse: () => <String, String>{});
      s.appendRow([
        '${m['nombre'] ?? ''}',
        '${m['categoria'] ?? ''}',
        (m['presentaciones'] as List?)?.join(', ') ?? '',
        '${m['indicaciones'] ?? ''}',
        dosisAd.isNotEmpty ? '${dosisAd['dosis']} — ${dosisAd['max']}' : '',
        dosisNi.isNotEmpty ? '${dosisNi['dosis']} — ${dosisNi['max']}' : '',
        '${m['contraindicaciones'] ?? ''}',
        '${m['alertas'] ?? ''}',
      ]);
    }
  }

  List<Map<String, dynamic>> _catalogo() => [
    { 'nombre': 'Acetaminofén (Paracetamol)', 'categoria': 'Analgésico / Antipirético',
      'presentaciones': ['Tabletas 500 mg', 'Jarabe 150 mg/5 mL', 'Gotas 100 mg/mL'],
      'indicaciones': 'Fiebre, dolor leve a moderado.',
      'dosis': [{'grupo': 'Adultos', 'dosis': '500-1000 mg cada 6-8 h', 'max': 'Max 4 g/dia'},
                {'grupo': 'Ninos', 'dosis': '10-15 mg/kg cada 6-8 h', 'max': 'Max 60 mg/kg/dia'}],
      'contraindicaciones': 'Insuficiencia hepatica grave.',
      'alertas': 'No superar dosis maxima. Riesgo de hepatotoxicidad.' },
    { 'nombre': 'Ibuprofeno', 'categoria': 'AINE / Analgesico',
      'presentaciones': ['Tabletas 400 mg', 'Suspension 200 mg/5 mL'],
      'indicaciones': 'Dolor, fiebre, inflamacion.',
      'dosis': [{'grupo': 'Adultos', 'dosis': '400-600 mg cada 6-8 h', 'max': 'Max 2.4 g/dia'},
                {'grupo': 'Ninos', 'dosis': '5-10 mg/kg cada 6-8 h', 'max': 'Max 40 mg/kg/dia'}],
      'contraindicaciones': 'Ulcera peptica, insuficiencia renal, embarazo tercer trimestre.',
      'alertas': 'Administrar con alimentos.' },
    { 'nombre': 'Amoxicilina', 'categoria': 'Antibiotico - Penicilina',
      'presentaciones': ['Capsulas 500 mg', 'Suspension 250 mg/5 mL'],
      'indicaciones': 'Infecciones respiratorias, urinarias, otitis.',
      'dosis': [{'grupo': 'Adultos', 'dosis': '500 mg cada 8 h', 'max': '3 g/dia'},
                {'grupo': 'Ninos', 'dosis': '25-45 mg/kg/dia cada 8 h', 'max': 'Segun peso'}],
      'contraindicaciones': 'Alergia a penicilinas.',
      'alertas': 'Completar esquema. Verificar alergia previa.' },
    { 'nombre': 'Metformina', 'categoria': 'Antidiabetico oral',
      'presentaciones': ['Tabletas 500 mg', 'Tabletas 850 mg'],
      'indicaciones': 'Diabetes mellitus tipo 2.',
      'dosis': [{'grupo': 'Adultos', 'dosis': '500-850 mg con comidas', 'max': 'Max 2550 mg/dia'}],
      'contraindicaciones': 'Insuficiencia renal severa.',
      'alertas': 'Suspender 48h antes de contraste.' },
    { 'nombre': 'Losartan', 'categoria': 'Antihipertensivo - ARA II',
      'presentaciones': ['Tabletas 50 mg', 'Tabletas 100 mg'],
      'indicaciones': 'Hipertension arterial.',
      'dosis': [{'grupo': 'Adultos', 'dosis': '50 mg una vez al dia', 'max': 'Max 100 mg/dia'}],
      'contraindicaciones': 'Embarazo.',
      'alertas': 'Monitorear potasio y funcion renal.' },
    { 'nombre': 'Salbutamol', 'categoria': 'Broncodilatador',
      'presentaciones': ['Inhalador 100 mcg/dosis'],
      'indicaciones': 'Crisis asmatica, broncoespasmo.',
      'dosis': [{'grupo': 'Adultos', 'dosis': '2 inhalaciones cada 4-6 h', 'max': 'Segun necesidad'},
                {'grupo': 'Ninos', 'dosis': '1-2 inhalaciones cada 4-6 h', 'max': 'Segun peso'}],
      'contraindicaciones': 'Hipersensibilidad.',
      'alertas': 'Uso excesivo indica mal control del asma.' },
    { 'nombre': 'Sulfato ferroso', 'categoria': 'Suplemento de hierro',
      'presentaciones': ['Tabletas 300 mg', 'Jarabe 25 mg/mL'],
      'indicaciones': 'Anemia ferropenica.',
      'dosis': [{'grupo': 'Adultos', 'dosis': '300 mg 2-3 veces al dia', 'max': 'Segun indicacion'},
                {'grupo': 'Ninos', 'dosis': '3-6 mg/kg/dia', 'max': 'Segun peso'}],
      'contraindicaciones': 'Hemocromatosis.',
      'alertas': 'Tomar con vitamina C. Oscurece las heces.' },
    { 'nombre': 'Acido folico', 'categoria': 'Vitamina B9',
      'presentaciones': ['Tabletas 1 mg', 'Tabletas 5 mg'],
      'indicaciones': 'Prevencion defectos tubo neural.',
      'dosis': [{'grupo': 'Embarazadas', 'dosis': '0.4-1 mg/dia', 'max': '5 mg/dia'},
                {'grupo': 'Adultos', 'dosis': '1 mg/dia', 'max': '5 mg/dia'}],
      'contraindicaciones': 'Alergia al farmaco.',
      'alertas': 'Iniciar 1 mes antes del embarazo.' },
    { 'nombre': 'Omeprazol', 'categoria': 'Inhibidor bomba de protones',
      'presentaciones': ['Capsulas 20 mg', 'Capsulas 40 mg'],
      'indicaciones': 'Ulcera peptica, ERGE, gastritis.',
      'dosis': [{'grupo': 'Adultos', 'dosis': '20-40 mg/dia en ayunas', 'max': '40 mg/dia'}],
      'contraindicaciones': 'Hipersensibilidad.',
      'alertas': 'Puede reducir absorcion de otros farmacos.' },
    { 'nombre': 'Hidroclorotiazida', 'categoria': 'Diuretico tiazidico',
      'presentaciones': ['Tabletas 25 mg', 'Tabletas 50 mg'],
      'indicaciones': 'Hipertension, edema.',
      'dosis': [{'grupo': 'Adultos', 'dosis': '25-50 mg/dia', 'max': '100 mg/dia'}],
      'contraindicaciones': 'Anuria.',
      'alertas': 'Monitorear electrolitos.' },
  ];
}
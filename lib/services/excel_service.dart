import 'dart:typed_data';
import 'package:excel/excel.dart';
import '../database/database_helper.dart';
import 'excel_downloader_stub.dart'
    if (dart.library.html) 'excel_downloader_web.dart'
    if (dart.library.io)   'excel_downloader_mobile.dart';

// ════════════════════════════════════════════════════════════════════════════
//  excel_service.dart  —  DISPERSALUD IA
//  Exporta toda la información a un .xlsx con 6 hojas
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
    _hojaMedicamentos(excel);

    excel.delete('Sheet1');

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

    s.appendRow([TextCellValue('DISPERSALUD IA — Reporte generado: $fecha')]);
    s.appendRow([TextCellValue('')]);
    s.appendRow([TextCellValue('INDICADOR'), TextCellValue('VALOR')]);
    s.appendRow([TextCellValue('Total pacientes'),   TextCellValue('${pacientes.length}')]);
    s.appendRow([TextCellValue('Total consultas'),   TextCellValue('${consultas.length}')]);
    s.appendRow([TextCellValue('Alertas activas'),   TextCellValue('${alertas.where((a) => a['resuelta'] == 0).length}')]);
    s.appendRow([TextCellValue('Alertas resueltas'), TextCellValue('${alertas.where((a) => a['resuelta'] == 1).length}')]);
    s.appendRow([TextCellValue('')]);

    s.appendRow([TextCellValue('PACIENTES POR MÓDULO'), TextCellValue('CANTIDAD')]);
    final modulos = <String, int>{};
    for (final p in pacientes) {
      final m = '${p['modulo'] ?? 'Sin módulo'}';
      modulos[m] = (modulos[m] ?? 0) + 1;
    }
    for (final e in modulos.entries) {
      s.appendRow([TextCellValue(e.key), TextCellValue('${e.value}')]);
    }

    s.appendRow([TextCellValue('')]);
    s.appendRow([TextCellValue('CONSULTAS POR NIVEL DE RIESGO'), TextCellValue('CANTIDAD')]);
    final riesgos = <String, int>{};
    for (final c in consultas) {
      final r = '${c['nivel_riesgo'] ?? 'estable'}';
      riesgos[r] = (riesgos[r] ?? 0) + 1;
    }
    for (final e in riesgos.entries) {
      s.appendRow([TextCellValue(e.key), TextCellValue('${e.value}')]);
    }
    _autoAncho(s, 2);
  }

  // ── Hoja 2 — Pacientes ───────────────────────────────────────────────────
  void _hojaPacientes(Excel excel, List<Map<String, dynamic>> pacientes) {
    final s = excel['Pacientes'];
    _encabezado(s, ['ID', 'Nombre completo', 'Documento', 'Fecha nacimiento',
      'Sexo', 'Edad', 'Departamento', 'Municipio', 'Vereda',
      'Teléfono', 'EPS', 'Módulo', 'Acudiente', 'Fecha registro']);
    for (final p in pacientes) {
      s.appendRow([
        TextCellValue('${p['id'] ?? ''}'),
        TextCellValue('${p['nombre'] ?? ''}'),
        TextCellValue('${p['documento'] ?? ''}'),
        TextCellValue('${p['fecha_nac'] ?? ''}'),
        TextCellValue('${p['sexo'] ?? ''}'),
        TextCellValue('${p['edad'] ?? ''}'),
        TextCellValue('${p['departamento'] ?? ''}'),
        TextCellValue('${p['municipio'] ?? ''}'),
        TextCellValue('${p['vereda'] ?? ''}'),
        TextCellValue('${p['telefono'] ?? ''}'),
        TextCellValue('${p['eps'] ?? ''}'),
        TextCellValue('${p['modulo'] ?? ''}'),
        TextCellValue('${p['acudiente'] ?? ''}'),
        TextCellValue('${p['created_at'] ?? ''}'),
      ]);
    }
    _autoAncho(s, 14);
  }

  // ── Hoja 3 — Consultas y diagnósticos ────────────────────────────────────
  void _hojaConsultas(Excel excel, List<Map<String, dynamic>> consultas,
      List<Map<String, dynamic>> pacientes) {
    final s = excel['Consultas y Diagnósticos'];
    _encabezado(s, ['ID Consulta', 'Paciente', 'Módulo', 'Fecha',
      'Diagnóstico', 'Nivel de riesgo', 'Observaciones', 'Sincronizado']);
    final mapPac = {for (final p in pacientes) p['id']: p['nombre']};
    for (final c in consultas) {
      s.appendRow([
        TextCellValue('${c['id'] ?? ''}'),
        TextCellValue('${mapPac[c['paciente_id']] ?? c['nombre'] ?? ''}'),
        TextCellValue('${c['modulo'] ?? ''}'),
        TextCellValue('${c['fecha'] ?? ''}'),
        TextCellValue('${c['diagnostico'] ?? ''}'),
        TextCellValue('${c['nivel_riesgo'] ?? 'estable'}'),
        TextCellValue('${c['observaciones'] ?? ''}'),
        TextCellValue(c['sincronizado'] == 1 ? 'Sí' : 'No'),
      ]);
    }
    _autoAncho(s, 8);
  }

  // ── Hoja 4 — Signos vitales ──────────────────────────────────────────────
  void _hojaSignosVitales(Excel excel, List<Map<String, dynamic>> consultas,
      List<Map<String, dynamic>> pacientes) {
    final s = excel['Signos Vitales'];
    _encabezado(s, ['Paciente', 'Módulo', 'Fecha',
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
        TextCellValue('${mapPac[c['paciente_id']] ?? c['nombre'] ?? ''}'),
        TextCellValue('${c['modulo'] ?? ''}'),
        TextCellValue('${c['fecha'] ?? ''}'),
        TextCellValue('${c['presion'] ?? ''}'),
        TextCellValue('${c['glucemia'] ?? ''}'),
        TextCellValue('${c['peso'] ?? ''}'),
        TextCellValue('${c['talla'] ?? ''}'),
        TextCellValue('${c['temperatura'] ?? ''}'),
        TextCellValue('${c['spo2'] ?? ''}'),
        TextCellValue('${c['fc'] ?? ''}'),
        TextCellValue('${c['imc'] ?? ''}'),
        TextCellValue('${c['semanas'] ?? ''}'),
        TextCellValue('${c['nivel_riesgo'] ?? ''}'),
      ]);
    }
    _autoAncho(s, 13);
  }

  // ── Hoja 5 — Alertas ─────────────────────────────────────────────────────
  void _hojaAlertas(Excel excel, List<Map<String, dynamic>> alertas) {
    final s = excel['Alertas'];
    _encabezado(s, ['ID', 'Paciente', 'Módulo', 'Mensaje', 'Nivel', 'Estado', 'Fecha']);
    for (final a in alertas) {
      s.appendRow([
        TextCellValue('${a['id'] ?? ''}'),
        TextCellValue('${a['paciente'] ?? ''}'),
        TextCellValue('${a['modulo'] ?? ''}'),
        TextCellValue('${a['mensaje'] ?? ''}'),
        TextCellValue('${a['nivel'] ?? ''}'),
        TextCellValue(a['resuelta'] == 1 ? 'Resuelta' : 'Activa'),
        TextCellValue('${a['fecha'] ?? ''}'),
      ]);
    }
    _autoAncho(s, 7);
  }

  // ── Hoja 6 — Especialistas ───────────────────────────────────────────────
  void _hojaEspecialistas(Excel excel, List<Map<String, dynamic>> especialistas) {
    final s = excel['Especialistas'];
    _encabezado(s, ['Nombre', 'Especialidad', 'Teléfono', 'Municipio',
      'Correo', 'Dirección', 'Horario', 'Notas']);
    for (final e in especialistas) {
      s.appendRow([
        TextCellValue('${e['nombre'] ?? ''}'),
        TextCellValue('${e['especialidad'] ?? ''}'),
        TextCellValue('${e['telefono'] ?? ''}'),
        TextCellValue('${e['municipio'] ?? ''}'),
        TextCellValue('${e['correo'] ?? ''}'),
        TextCellValue('${e['direccion'] ?? ''}'),
        TextCellValue('${e['horario'] ?? ''}'),
        TextCellValue('${e['notas'] ?? ''}'),
      ]);
    }
    _autoAncho(s, 8);
  }

  // ── Hoja 7 — Esquemas de medicamentos ────────────────────────────────────
  void _hojaMedicamentos(Excel excel) {
    final s = excel['Esquemas Medicamentos'];
    _encabezado(s, ['Medicamento', 'Categoría', 'Presentaciones',
      'Indicaciones', 'Dosis adultos', 'Dosis niños',
      'Contraindicaciones', 'Alertas / Precauciones']);
    for (final m in _catalogo()) {
      final dosis   = m['dosis'] as List? ?? [];
      final dosisAd = dosis.firstWhere(
          (d) => (d['grupo'] as String).toLowerCase().contains('adult'),
          orElse: () => <String, String>{});
      final dosisNi = dosis.firstWhere(
          (d) => (d['grupo'] as String).toLowerCase().contains('ni'),
          orElse: () => <String, String>{});
      s.appendRow([
        TextCellValue('${m['nombre'] ?? ''}'),
        TextCellValue('${m['categoria'] ?? ''}'),
        TextCellValue((m['presentaciones'] as List?)?.join(', ') ?? ''),
        TextCellValue('${m['indicaciones'] ?? ''}'),
        TextCellValue(dosisAd.isNotEmpty ? '${dosisAd['dosis']} — ${dosisAd['max']}' : ''),
        TextCellValue(dosisNi.isNotEmpty ? '${dosisNi['dosis']} — ${dosisNi['max']}' : ''),
        TextCellValue('${m['contraindicaciones'] ?? ''}'),
        TextCellValue('${m['alertas'] ?? ''}'),
      ]);
    }
    _autoAncho(s, 8);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  void _encabezado(Sheet s, List<String> cols) =>
      s.appendRow(cols.map((c) => TextCellValue(c)).toList());

  void _autoAncho(Sheet s, int cols) {
    for (int i = 0; i < cols; i++) s.setColumnWidth(i, 24.0);
  }

  List<Map<String, dynamic>> _catalogo() => [
    { 'nombre': 'Acetaminofén (Paracetamol)', 'categoria': 'Analgésico / Antipirético',
      'presentaciones': ['Tabletas 500 mg', 'Jarabe 150 mg/5 mL', 'Gotas 100 mg/mL'],
      'indicaciones': 'Fiebre, dolor leve a moderado.',
      'dosis': [{'grupo': 'Adultos', 'dosis': '500–1000 mg cada 6–8 h', 'max': 'Máx 4 g/día'},
                {'grupo': 'Niños', 'dosis': '10–15 mg/kg cada 6–8 h', 'max': 'Máx 60 mg/kg/día'}],
      'contraindicaciones': 'Insuficiencia hepática grave.',
      'alertas': 'No superar dosis máxima. Riesgo de hepatotoxicidad.' },
    { 'nombre': 'Ibuprofeno', 'categoria': 'AINE / Analgésico',
      'presentaciones': ['Tabletas 400 mg', 'Suspensión 200 mg/5 mL'],
      'indicaciones': 'Dolor, fiebre, inflamación.',
      'dosis': [{'grupo': 'Adultos', 'dosis': '400–600 mg cada 6–8 h', 'max': 'Máx 2.4 g/día'},
                {'grupo': 'Niños', 'dosis': '5–10 mg/kg cada 6–8 h', 'max': 'Máx 40 mg/kg/día'}],
      'contraindicaciones': 'Úlcera péptica, insuficiencia renal, embarazo tercer trimestre.',
      'alertas': 'Administrar con alimentos.' },
    { 'nombre': 'Amoxicilina', 'categoria': 'Antibiótico – Penicilina',
      'presentaciones': ['Cápsulas 500 mg', 'Suspensión 250 mg/5 mL'],
      'indicaciones': 'Infecciones respiratorias, urinarias, otitis.',
      'dosis': [{'grupo': 'Adultos', 'dosis': '500 mg cada 8 h', 'max': '3 g/día'},
                {'grupo': 'Niños', 'dosis': '25–45 mg/kg/día cada 8 h', 'max': 'Según peso'}],
      'contraindicaciones': 'Alergia a penicilinas.',
      'alertas': 'Completar esquema. Verificar alergia previa.' },
    { 'nombre': 'Metformina', 'categoria': 'Antidiabético oral',
      'presentaciones': ['Tabletas 500 mg', 'Tabletas 850 mg'],
      'indicaciones': 'Diabetes mellitus tipo 2.',
      'dosis': [{'grupo': 'Adultos', 'dosis': '500–850 mg con comidas', 'max': 'Máx 2550 mg/día'}],
      'contraindicaciones': 'Insuficiencia renal severa.',
      'alertas': 'Suspender 48h antes de contraste.' },
    { 'nombre': 'Losartán', 'categoria': 'Antihipertensivo – ARA II',
      'presentaciones': ['Tabletas 50 mg', 'Tabletas 100 mg'],
      'indicaciones': 'Hipertensión arterial.',
      'dosis': [{'grupo': 'Adultos', 'dosis': '50 mg una vez al día', 'max': 'Máx 100 mg/día'}],
      'contraindicaciones': 'Embarazo.',
      'alertas': 'Monitorear potasio y función renal.' },
    { 'nombre': 'Salbutamol', 'categoria': 'Broncodilatador',
      'presentaciones': ['Inhalador 100 mcg/dosis'],
      'indicaciones': 'Crisis asmática, broncoespasmo.',
      'dosis': [{'grupo': 'Adultos', 'dosis': '2 inhalaciones cada 4–6 h', 'max': 'Según necesidad'},
                {'grupo': 'Niños', 'dosis': '1–2 inhalaciones cada 4–6 h', 'max': 'Según peso'}],
      'contraindicaciones': 'Hipersensibilidad.',
      'alertas': 'Uso excesivo indica mal control del asma.' },
    { 'nombre': 'Sulfato ferroso', 'categoria': 'Suplemento de hierro',
      'presentaciones': ['Tabletas 300 mg', 'Jarabe 25 mg/mL'],
      'indicaciones': 'Anemia ferropénica.',
      'dosis': [{'grupo': 'Adultos', 'dosis': '300 mg 2–3 veces al día', 'max': 'Según indicación'},
                {'grupo': 'Niños', 'dosis': '3–6 mg/kg/día', 'max': 'Según peso'}],
      'contraindicaciones': 'Hemocromatosis.',
      'alertas': 'Tomar con vitamina C. Oscurece las heces.' },
    { 'nombre': 'Ácido fólico', 'categoria': 'Vitamina B9',
      'presentaciones': ['Tabletas 1 mg', 'Tabletas 5 mg'],
      'indicaciones': 'Prevención defectos tubo neural.',
      'dosis': [{'grupo': 'Embarazadas', 'dosis': '0.4–1 mg/día', 'max': '5 mg/día'},
                {'grupo': 'Adultos', 'dosis': '1 mg/día', 'max': '5 mg/día'}],
      'contraindicaciones': 'Alergia al fármaco.',
      'alertas': 'Iniciar 1 mes antes del embarazo.' },
    { 'nombre': 'Omeprazol', 'categoria': 'Inhibidor bomba de protones',
      'presentaciones': ['Cápsulas 20 mg', 'Cápsulas 40 mg'],
      'indicaciones': 'Úlcera péptica, ERGE, gastritis.',
      'dosis': [{'grupo': 'Adultos', 'dosis': '20–40 mg/día en ayunas', 'max': '40 mg/día'}],
      'contraindicaciones': 'Hipersensibilidad.',
      'alertas': 'Puede reducir absorción de otros fármacos.' },
    { 'nombre': 'Hidroclorotiazida', 'categoria': 'Diurético tiazídico',
      'presentaciones': ['Tabletas 25 mg', 'Tabletas 50 mg'],
      'indicaciones': 'Hipertensión, edema.',
      'dosis': [{'grupo': 'Adultos', 'dosis': '25–50 mg/día', 'max': '100 mg/día'}],
      'contraindicaciones': 'Anuria.',
      'alertas': 'Monitorear electrolitos.' },
  ];
}
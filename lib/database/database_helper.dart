import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';
import '../services/security_service.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('dispersalud.db');
    return _database!;
  }

  // ── CAMBIO 1: versión 8 → 9 ─────────────────────────────────────────────
  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return await openDatabase(filePath,
          version: 9, onCreate: _createDB, onUpgrade: _upgradeDB);
    }
    final dbPath = await getDatabasesPath();
    final path   = join(dbPath, filePath);
    return await openDatabase(path,
        version: 9, onCreate: _createDB, onUpgrade: _upgradeDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pacientes (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre       TEXT NOT NULL,
        documento    TEXT,
        fecha_nac    TEXT,
        sexo         TEXT,
        edad         TEXT,
        departamento TEXT,
        municipio    TEXT,
        vereda       TEXT,
        telefono     TEXT,
        eps          TEXT,
        modulo       TEXT,
        acudiente     TEXT,
        sincronizado  INTEGER DEFAULT 0,
        created_at    TEXT DEFAULT (datetime('now','localtime'))
      )
    ''');

    await db.execute('''
      CREATE TABLE consultas (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        paciente_id   INTEGER,
        nombre        TEXT,
        modulo        TEXT NOT NULL,
        fecha         TEXT DEFAULT (datetime('now','localtime')),
        presion       TEXT,
        glucemia      TEXT,
        peso          TEXT,
        talla         TEXT,
        temperatura   TEXT,
        spo2          TEXT,
        fc            TEXT,
        semanas       TEXT,
        imc           TEXT,
        diagnostico   TEXT,
        nivel_riesgo  TEXT DEFAULT 'estable',
        observaciones TEXT,
        datos_json    TEXT,
        datos_extra   TEXT,
        sincronizado  INTEGER DEFAULT 0,
        firma_png        TEXT,
        firma_profesional TEXT,
        firma_fecha       TEXT,
        FOREIGN KEY (paciente_id) REFERENCES pacientes(id)
      )
    ''');

    // ── CAMBIO 2: tabla alertas con columnas nuevas ──────────────────────
    await db.execute('''
      CREATE TABLE alertas (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        modulo           TEXT,
        paciente         TEXT,
        mensaje          TEXT,
        nivel            TEXT,
        resuelta         INTEGER DEFAULT 0,
        sincronizado     INTEGER DEFAULT 0,
        auto             INTEGER DEFAULT 0,
        codigo_sivigila  TEXT,
        fecha            TEXT DEFAULT (datetime('now','localtime'))
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS especialistas (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre           TEXT NOT NULL,
        especialidad     TEXT NOT NULL,
        ciudad           TEXT,
        telefono         TEXT,
        proximo_horario  TEXT,
        categoria_id     TEXT DEFAULT 'medicina_interna',
        calificacion     REAL  DEFAULT 4.5,
        anios_exp        INTEGER DEFAULT 1,
        disponible       INTEGER DEFAULT 1,
        foto_path        TEXT    DEFAULT '',
        created_at       TEXT DEFAULT (datetime('now','localtime'))
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS fichas_epidemiologicas (
        id                  INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo_evento       TEXT NOT NULL,
        nombre_evento       TEXT NOT NULL,
        estado              TEXT DEFAULT 'borrador',
        exportado           INTEGER DEFAULT 0,
        datos_json          TEXT,
        nombre_paciente     TEXT,
        municipio           TEXT,
        fecha_notificacion  TEXT,
        nivel_urgencia      TEXT DEFAULT 'normal',
        firma_png           TEXT,
        firma_profesional   TEXT,
        firma_fecha         TEXT,
        created_at          TEXT DEFAULT (datetime('now','localtime')),
        updated_at          TEXT DEFAULT (datetime('now','localtime'))
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try { await db.execute('ALTER TABLE pacientes ADD COLUMN documento TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE pacientes ADD COLUMN fecha_nac TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE pacientes ADD COLUMN sexo TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE pacientes ADD COLUMN vereda TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE pacientes ADD COLUMN municipio TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE pacientes ADD COLUMN telefono TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE consultas ADD COLUMN datos_json TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE consultas ADD COLUMN nivel_riesgo TEXT DEFAULT "estable"'); } catch (_) {}
      try { await db.execute('ALTER TABLE consultas ADD COLUMN nombre TEXT'); } catch (_) {}
    }
    if (oldVersion < 3) {
      try { await db.execute('ALTER TABLE pacientes ADD COLUMN departamento TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE pacientes ADD COLUMN eps TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE consultas ADD COLUMN sincronizado INTEGER DEFAULT 0'); } catch (_) {}
    }
    if (oldVersion < 4) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS especialistas (
            id               INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre           TEXT NOT NULL,
            especialidad     TEXT NOT NULL,
            ciudad           TEXT,
            telefono         TEXT,
            proximo_horario  TEXT,
            categoria_id     TEXT DEFAULT 'medicina_interna',
            calificacion     REAL  DEFAULT 4.5,
            anios_exp        INTEGER DEFAULT 1,
            disponible       INTEGER DEFAULT 1,
            created_at       TEXT DEFAULT (datetime('now','localtime'))
          )
        ''');
      } catch (_) {}
      try { await db.execute('ALTER TABLE especialistas ADD COLUMN foto_path TEXT DEFAULT ""'); } catch (_) {}
    }
    if (oldVersion < 6) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS fichas_epidemiologicas (
            id                  INTEGER PRIMARY KEY AUTOINCREMENT,
            codigo_evento       TEXT NOT NULL,
            nombre_evento       TEXT NOT NULL,
            estado              TEXT DEFAULT 'borrador',
            exportado           INTEGER DEFAULT 0,
            datos_json          TEXT,
            nombre_paciente     TEXT,
            municipio           TEXT,
            fecha_notificacion  TEXT,
            nivel_urgencia      TEXT DEFAULT 'normal',
            created_at          TEXT DEFAULT (datetime('now','localtime')),
            updated_at          TEXT DEFAULT (datetime('now','localtime'))
          )
        ''');
      } catch (_) {}
    }
    if (oldVersion < 7) {
      try { await db.execute('ALTER TABLE consultas ADD COLUMN firma_png TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE consultas ADD COLUMN firma_profesional TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE consultas ADD COLUMN firma_fecha TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE fichas_epidemiologicas ADD COLUMN firma_png TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE fichas_epidemiologicas ADD COLUMN firma_profesional TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE fichas_epidemiologicas ADD COLUMN firma_fecha TEXT'); } catch (_) {}
    }
    if (oldVersion < 8) {
      try { await db.execute('ALTER TABLE pacientes ADD COLUMN sincronizado INTEGER DEFAULT 0'); } catch (_) {}
    }
    // ── CAMBIO 3: upgrade v8 → v9 — columnas SIVIGILA en alertas ────────
    if (oldVersion < 9) {
      try { await db.execute('ALTER TABLE alertas ADD COLUMN sincronizado INTEGER DEFAULT 0'); } catch (_) {}
      try { await db.execute('ALTER TABLE alertas ADD COLUMN auto INTEGER DEFAULT 0'); } catch (_) {}
      try { await db.execute('ALTER TABLE alertas ADD COLUMN codigo_sivigila TEXT'); } catch (_) {}
    }
  }

  SecurityService get _sec => SecurityService.instance;

  // ════════════════════════════════════════════════════════════════════
  // PACIENTES
  // ════════════════════════════════════════════════════════════════════

  Future<int> insertarPaciente(Map<String, dynamic> data) async {
    final db      = await database;
    final cifrado = _sec.cifrarPaciente(data);
    return await db.insert('pacientes', cifrado,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> obtenerPacientes() async {
    final db   = await database;
    final rows = await db.query('pacientes', orderBy: 'created_at DESC');
    return rows.map(_sec.descifrarPaciente).toList().cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>?> obtenerPaciente(int id) async {
    final db     = await database;
    final result = await db.query('pacientes',
        where: 'id = ?', whereArgs: [id], limit: 1);
    if (result.isEmpty) return null;
    return _sec.descifrarPaciente(result.first);
  }

  Future<List<Map<String, dynamic>>> buscarPacientes(String nombre) async {
    final db   = await database;
    final rows = await db.query('pacientes',
        where: 'nombre LIKE ?', whereArgs: ['%$nombre%']);
    return rows.map(_sec.descifrarPaciente).toList().cast<Map<String, dynamic>>();
  }

  Future<int> eliminarPaciente(int id) async {
    final db = await database;
    return await db.delete('pacientes', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> actualizarPaciente(int id, Map<String, dynamic> data) async {
    final db      = await database;
    final cifrado = _sec.cifrarPaciente(data);
    return await db.update('pacientes', cifrado,
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> totalPacientes() async {
    final db = await database;
    final r  = await db.rawQuery('SELECT COUNT(*) as total FROM pacientes');
    return Sqflite.firstIntValue(r) ?? 0;
  }

  // ════════════════════════════════════════════════════════════════════
  // CONSULTAS
  // ════════════════════════════════════════════════════════════════════

  Future<int> insertarConsulta(Map<String, dynamic> data) async {
    final db      = await database;
    final cifrado = _sec.cifrarConsulta(data);
    return await db.insert('consultas', cifrado,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> obtenerConsultas({String? modulo}) async {
    final db = await database;
    List<Map<String, dynamic>> rows;
    if (modulo != null) {
      rows = await db.query('consultas',
          where: 'modulo = ?', whereArgs: [modulo], orderBy: 'fecha DESC');
    } else {
      rows = await db.query('consultas', orderBy: 'fecha DESC');
    }
    return rows.map(_sec.descifrarConsulta).toList().cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> consultasDePaciente(int pacienteId) async {
    final db   = await database;
    final rows = await db.query('consultas',
        where: 'paciente_id = ?', whereArgs: [pacienteId], orderBy: 'fecha DESC');
    return rows.map(_sec.descifrarConsulta).toList().cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> consultasPorPaciente(int pacienteId) =>
      consultasDePaciente(pacienteId);

  Future<int> totalConsultasHoy() async {
    final db  = await database;
    final hoy = DateTime.now().toIso8601String().substring(0, 10);
    final r   = await db.rawQuery(
        "SELECT COUNT(*) as total FROM consultas WHERE fecha LIKE '$hoy%'");
    return Sqflite.firstIntValue(r) ?? 0;
  }

  Future<int> totalConsultas() async {
    final db = await database;
    final r  = await db.rawQuery('SELECT COUNT(*) as total FROM consultas');
    return Sqflite.firstIntValue(r) ?? 0;
  }

  Future<List<Map<String, dynamic>>> consultasRecientes({int limit = 5}) async {
    final db   = await database;
    final rows = await db.rawQuery('''
      SELECT c.id, c.modulo, c.fecha, c.diagnostico, c.nivel_riesgo,
             COALESCE(c.nombre, p.nombre, 'Sin nombre') AS nombre
      FROM consultas c
      LEFT JOIN pacientes p ON c.paciente_id = p.id
      ORDER BY c.fecha DESC LIMIT $limit
    ''');
    return rows.map((r) {
      final m = Map<String, dynamic>.from(r);
      m['diagnostico'] = _sec.descifrar(m['diagnostico'] as String?);
      return m;
    }).toList().cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> consultasUrgentesRecientes() async {
    final db   = await database;
    final rows = await db.rawQuery('''
      SELECT c.id, c.modulo, c.fecha, c.diagnostico, c.nivel_riesgo,
             COALESCE(c.nombre, p.nombre, 'Sin nombre') AS nombre
      FROM consultas c
      LEFT JOIN pacientes p ON c.paciente_id = p.id
      WHERE c.nivel_riesgo IN ('urgente','alerta')
      ORDER BY c.fecha DESC LIMIT 10
    ''');
    return rows.map((r) {
      final m = Map<String, dynamic>.from(r);
      m['diagnostico'] = _sec.descifrar(m['diagnostico'] as String?);
      return m;
    }).toList().cast<Map<String, dynamic>>();
  }

  // ════════════════════════════════════════════════════════════════════
  // ALERTAS
  // ════════════════════════════════════════════════════════════════════

  Future<int> insertarAlerta(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('alertas', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> obtenerAlertas({bool soloActivas = true}) async {
    final db = await database;
    if (soloActivas) {
      return await db.query('alertas',
          where: 'resuelta = ?', whereArgs: [0], orderBy: 'fecha DESC');
    }
    return await db.query('alertas', orderBy: 'fecha DESC');
  }

  Future<int> resolverAlerta(int id) async {
    final db = await database;
    return await db.update('alertas', {'resuelta': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> totalAlertasActivas() async {
    final db = await database;
    final r  = await db.rawQuery(
        'SELECT COUNT(*) as total FROM alertas WHERE resuelta = 0');
    return Sqflite.firstIntValue(r) ?? 0;
  }

  // ════════════════════════════════════════════════════════════════════
  // ESPECIALISTAS
  // ════════════════════════════════════════════════════════════════════

  Future<int> insertarEspecialista(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('especialistas', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> obtenerEspecialistas() async {
    final db = await database;
    return await db.query('especialistas', orderBy: 'nombre ASC');
  }

  Future<int> actualizarEspecialista(int id, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update('especialistas', data,
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> eliminarEspecialista(int id) async {
    final db = await database;
    return await db.delete('especialistas',
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> totalEspecialistas() async {
    final db = await database;
    final r  = await db.rawQuery(
        'SELECT COUNT(*) as total FROM especialistas');
    return Sqflite.firstIntValue(r) ?? 0;
  }

  Future<int> totalEspecialistasDisponibles() async {
    final db = await database;
    final r  = await db.rawQuery(
        'SELECT COUNT(*) as total FROM especialistas WHERE disponible = 1');
    return Sqflite.firstIntValue(r) ?? 0;
  }

  // ════════════════════════════════════════════════════════════════════
  // RESUMEN Y GRÁFICAS
  // ════════════════════════════════════════════════════════════════════

  Future<Map<String, int>> resumenGeneral() async {
    final db        = await database;
    final pacientes = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM pacientes')) ?? 0;
    final consultas = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM consultas')) ?? 0;
    final alertas   = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM alertas WHERE resuelta=0')) ?? 0;
    return {'pacientes': pacientes, 'consultas': consultas, 'alertas': alertas};
  }

  Future<Map<String, int>> consultasPorModulo() async {
    final db   = await database;
    final rows = await db.rawQuery(
        'SELECT modulo, COUNT(*) as total FROM consultas GROUP BY modulo ORDER BY total DESC');
    final map = <String, int>{};
    for (final r in rows) {
      map[(r['modulo'] as String? ?? 'Otro').trim()] = (r['total'] as int?) ?? 0;
    }
    return map;
  }

  Future<List<Map<String, dynamic>>> consultasUltimosDias({int dias = 7}) async {
    final db   = await database;
    final rows = await db.rawQuery('''
      SELECT date(fecha) AS dia, COUNT(*) AS total FROM consultas
      WHERE fecha >= date('now', '-${dias - 1} days')
      GROUP BY dia ORDER BY dia ASC
    ''');
    return rows;
  }

  Future<Map<String, int>> distribucionRiesgo() async {
    final db   = await database;
    final rows = await db.rawQuery(
        "SELECT COALESCE(LOWER(nivel_riesgo),'estable') as nivel, COUNT(*) as total FROM consultas GROUP BY nivel");
    final map = <String, int>{};
    for (final r in rows) {
      map[r['nivel'] as String? ?? 'estable'] = (r['total'] as int?) ?? 0;
    }
    return map;
  }

  // ════════════════════════════════════════════════════════════════════
  // SINCRONIZACIÓN OFFLINE → ONLINE
  // ════════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> obtenerConsultasPendientesSync() async {
    final db = await database;
    try {
      final rows = await db.rawQuery('''
        SELECT c.*, p.nombre as nombre_paciente
        FROM consultas c
        LEFT JOIN pacientes p ON c.paciente_id = p.id
        WHERE (c.sincronizado IS NULL OR c.sincronizado = 0)
        ORDER BY c.fecha DESC
        LIMIT 50
      ''');
      return rows.map(_sec.descifrarConsulta).toList().cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> marcarConsultaSincronizada(dynamic id) async {
    final db = await database;
    await db.update(
      'consultas',
      {'sincronizado': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, Map<String, int>>> estadosPorModulo() async {
    final db = await database;

    final rowsAlertas = await db.rawQuery('''
      SELECT modulo,
             SUM(CASE WHEN LOWER(nivel_riesgo) IN ('urgente','alerta') THEN 1 ELSE 0 END) AS alertas,
             SUM(CASE WHEN sincronizado IS NULL OR sincronizado = 0    THEN 1 ELSE 0 END) AS pendientes
      FROM consultas
      GROUP BY modulo
    ''');

    final map = <String, Map<String, int>>{};
    for (final r in rowsAlertas) {
      final modulo = (r['modulo'] as String? ?? 'Otro').trim();
      map[modulo] = {
        'alertas':    (r['alertas']    as int?) ?? 0,
        'pendientes': (r['pendientes'] as int?) ?? 0,
      };
    }
    return map;
  }

  Future<int> totalPendientesSync() async {
    final db = await database;
    try {
      final r = await db.rawQuery(
          'SELECT COUNT(*) as total FROM consultas '
          'WHERE sincronizado IS NULL OR sincronizado = 0');
      return Sqflite.firstIntValue(r) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  // ════════════════════════════════════════════════════════════════════
  // FICHAS EPIDEMIOLÓGICAS (SIVIGILA)
  // ════════════════════════════════════════════════════════════════════

  Future<int> insertarFicha(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('fichas_epidemiologicas', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> actualizarFicha(int id, Map<String, dynamic> data) async {
    final db = await database;
    data['updated_at'] = DateTime.now().toIso8601String();
    return await db.update('fichas_epidemiologicas', data,
        where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> obtenerFicha(int id) async {
    final db   = await database;
    final rows = await db.query('fichas_epidemiologicas',
        where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, dynamic>>> obtenerFichas({String? codigoEvento}) async {
    final db = await database;
    if (codigoEvento != null && codigoEvento.isNotEmpty) {
      return await db.query('fichas_epidemiologicas',
          where: 'codigo_evento = ?', whereArgs: [codigoEvento],
          orderBy: 'created_at DESC');
    }
    return await db.query('fichas_epidemiologicas', orderBy: 'created_at DESC');
  }

  Future<int> eliminarFicha(int id) async {
    final db = await database;
    return await db.delete('fichas_epidemiologicas',
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> totalFichas({String? estado}) async {
    final db = await database;
    if (estado != null) {
      return Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM fichas_epidemiologicas WHERE estado = ?',
          [estado])) ?? 0;
    }
    return Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM fichas_epidemiologicas')) ?? 0;
  }

  // ════════════════════════════════════════════════════════════════════
  // SYNC CON SUPABASE
  // ════════════════════════════════════════════════════════════════════

  /// Pacientes que aún no se han subido a Supabase
  Future<List<Map<String, dynamic>>> obtenerPacientesPendientesSync() async {
    final db = await database;
    try {
      final rows = await db.query('pacientes',
          where: 'sincronizado = 0 OR sincronizado IS NULL');
      return rows
          .map(_sec.descifrarPaciente)
          .toList()
          .cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  /// Marca un paciente como ya sincronizado con Supabase
  Future<void> marcarPacienteSincronizado(dynamic id) async {
    final db = await database;
    try {
      await db.update('pacientes', {'sincronizado': 1},
          where: 'id = ?', whereArgs: [id]);
    } catch (_) {}
  }

  // ── CAMBIO 4: métodos de alertas ahora funcionales ───────────────────────

  /// Alertas pendientes de sincronización (sincronizado = 0)
  Future<List<Map<String, dynamic>>> obtenerAlertasPendientesSync() async {
    final db = await database;
    try {
      return await db.query(
        'alertas',
        where:   'sincronizado = 0 OR sincronizado IS NULL',
        orderBy: 'fecha DESC',
        limit:   100,
      );
    } catch (_) {
      return await db.query('alertas', orderBy: 'fecha DESC', limit: 50);
    }
  }

  /// Marca una alerta como sincronizada con Supabase
  Future<void> marcarAlertaSincronizada(dynamic id) async {
    final db = await database;
    try {
      await db.update(
        'alertas',
        {'sincronizado': 1},
        where:     'id = ?',
        whereArgs: [id],
      );
    } catch (_) {}
  }

  /// Guarda una alerta con campos SIVIGILA completos
  Future<int> guardarAlertaCompleta({
    required String modulo,
    required String paciente,
    required String mensaje,
    required String nivel,
    bool    auto           = false,
    String? codigoSivigila,
  }) async {
    final db = await database;
    return await db.insert('alertas', {
      'modulo':          modulo,
      'paciente':        paciente,
      'mensaje':         mensaje,
      'nivel':           nivel,
      'resuelta':        0,
      'sincronizado':    0,
      'auto':            auto ? 1 : 0,
      'codigo_sivigila': codigoSivigila,
      'fecha':           DateTime.now().toIso8601String(),
    });
  }

  /// Fichas epidemiológicas pendientes (estado != 'sincronizado')
  Future<List<Map<String, dynamic>>> obtenerFichasPendientesSync() async {
    final db = await database;
    try {
      return await db.query('fichas_epidemiologicas',
          where:   "estado != 'sincronizado'",
          orderBy: 'created_at DESC',
          limit:   50);
    } catch (_) {
      return [];
    }
  }

  /// Marca una ficha como sincronizada con Supabase
  Future<void> marcarFichaSincronizada(dynamic id) async {
    final db = await database;
    try {
      await db.update(
        'fichas_epidemiologicas',
        {'estado': 'sincronizado', 'exportado': 1,
         'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (_) {}
  }

  // ════════════════════════════════════════════════════════════════════
  // CIERRE
  // ════════════════════════════════════════════════════════════════════

  Future<void> cerrarDB() async {
    final db = await database;
    db.close();
  }
}
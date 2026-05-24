import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('dispersalud.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 2,
        onCreate: _createDB, onUpgrade: _upgradeDB);
  }

  Future _createDB(Database db, int version) async {
    // ── Pacientes (campos completos) ─────────────────────────────────
    await db.execute('''
      CREATE TABLE pacientes (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre      TEXT NOT NULL,
        documento   TEXT,
        fecha_nac   TEXT,
        sexo        TEXT,
        edad        TEXT,
        vereda      TEXT,
        municipio   TEXT,
        telefono    TEXT,
        modulo      TEXT,
        acudiente   TEXT,
        created_at  TEXT DEFAULT (datetime('now','localtime'))
      )
    ''');

    // ── Consultas ────────────────────────────────────────────────────
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
        FOREIGN KEY (paciente_id) REFERENCES pacientes(id)
      )
    ''');

    // ── Alertas ──────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE alertas (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        modulo      TEXT,
        paciente    TEXT,
        mensaje     TEXT,
        nivel       TEXT,
        resuelta    INTEGER DEFAULT 0,
        fecha       TEXT DEFAULT (datetime('now','localtime'))
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Agregar columnas nuevas a pacientes si vienen de v1
      try { await db.execute('ALTER TABLE pacientes ADD COLUMN documento TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE pacientes ADD COLUMN fecha_nac TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE pacientes ADD COLUMN sexo TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE pacientes ADD COLUMN vereda TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE pacientes ADD COLUMN municipio TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE pacientes ADD COLUMN telefono TEXT'); } catch (_) {}
      // Agregar datos_json a consultas si no existe
      try { await db.execute('ALTER TABLE consultas ADD COLUMN datos_json TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE consultas ADD COLUMN nivel_riesgo TEXT DEFAULT "estable"'); } catch (_) {}
      try { await db.execute('ALTER TABLE consultas ADD COLUMN nombre TEXT'); } catch (_) {}
    }
  }

  // ════════════════════════════════════════════════════════════════════
  // PACIENTES
  // ════════════════════════════════════════════════════════════════════

  Future<int> insertarPaciente(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('pacientes', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> obtenerPacientes() async {
    final db = await database;
    return await db.query('pacientes', orderBy: 'created_at DESC');
  }

  /// Obtener un paciente por ID — usado por HistorialScreen
  Future<Map<String, dynamic>?> obtenerPaciente(int id) async {
    final db = await database;
    final result = await db.query('pacientes',
        where: 'id = ?', whereArgs: [id], limit: 1);
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> buscarPacientes(String nombre) async {
    final db = await database;
    return await db.query('pacientes',
        where: 'nombre LIKE ?', whereArgs: ['%$nombre%']);
  }

  Future<int> eliminarPaciente(int id) async {
    final db = await database;
    return await db.delete('pacientes', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> totalPacientes() async {
    final db = await database;
    final r = await db.rawQuery('SELECT COUNT(*) as total FROM pacientes');
    return Sqflite.firstIntValue(r) ?? 0;
  }

  // ════════════════════════════════════════════════════════════════════
  // CONSULTAS
  // ════════════════════════════════════════════════════════════════════

  Future<int> insertarConsulta(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('consultas', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> obtenerConsultas({String? modulo}) async {
    final db = await database;
    if (modulo != null) {
      return await db.query('consultas',
          where: 'modulo = ?', whereArgs: [modulo], orderBy: 'fecha DESC');
    }
    return await db.query('consultas', orderBy: 'fecha DESC');
  }

  /// Consultas de un paciente específico — usado por HistorialScreen
  Future<List<Map<String, dynamic>>> consultasDePaciente(int pacienteId) async {
    final db = await database;
    return await db.query('consultas',
        where: 'paciente_id = ?',
        whereArgs: [pacienteId],
        orderBy: 'fecha DESC');
  }

  /// Alias para compatibilidad
  Future<List<Map<String, dynamic>>> consultasPorPaciente(int pacienteId) =>
      consultasDePaciente(pacienteId);

  /// Consultas de HOY — usado por DashboardScreen
  Future<int> totalConsultasHoy() async {
    final db = await database;
    final hoy = DateTime.now().toIso8601String().substring(0, 10);
    final r = await db.rawQuery(
        "SELECT COUNT(*) as total FROM consultas WHERE fecha LIKE '$hoy%'");
    return Sqflite.firstIntValue(r) ?? 0;
  }

  Future<int> totalConsultas() async {
    final db = await database;
    final r = await db.rawQuery('SELECT COUNT(*) as total FROM consultas');
    return Sqflite.firstIntValue(r) ?? 0;
  }

  /// Últimas N consultas para el dashboard
  Future<List<Map<String, dynamic>>> consultasRecientes({int limit = 5}) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        c.id,
        c.modulo,
        c.fecha,
        c.diagnostico,
        c.nivel_riesgo,
        COALESCE(c.nombre, p.nombre, 'Sin nombre') AS nombre
      FROM consultas c
      LEFT JOIN pacientes p ON c.paciente_id = p.id
      ORDER BY c.fecha DESC
      LIMIT $limit
    ''');
  }

  // ════════════════════════════════════════════════════════════════════
  // ALERTAS
  // ════════════════════════════════════════════════════════════════════

  Future<int> insertarAlerta(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('alertas', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> obtenerAlertas(
      {bool soloActivas = true}) async {
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
    final r = await db.rawQuery(
        'SELECT COUNT(*) as total FROM alertas WHERE resuelta = 0');
    return Sqflite.firstIntValue(r) ?? 0;
  }

  // ════════════════════════════════════════════════════════════════════
  // RESUMEN GENERAL
  // ════════════════════════════════════════════════════════════════════

  Future<Map<String, int>> resumenGeneral() async {
    final db = await database;
    final pacientes = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM pacientes')) ?? 0;
    final consultas = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM consultas')) ?? 0;
    final alertas   = Sqflite.firstIntValue(await db
            .rawQuery('SELECT COUNT(*) FROM alertas WHERE resuelta=0')) ?? 0;
    return {'pacientes': pacientes, 'consultas': consultas, 'alertas': alertas};
  }

  Future<void> cerrarDB() async {
    final db = await database;
    db.close();
  }
}
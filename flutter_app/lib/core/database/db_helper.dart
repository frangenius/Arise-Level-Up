import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Helper para manejar la base de datos SQLite de LEVEL UP.
/// Utiliza el patrón Singleton para garantizar una única instancia.
class DbHelper {
  DbHelper._();
  static final DbHelper instance = DbHelper._();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'level_up.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  /// Crear tablas de la base de datos en la primera instalación
  Future<void> _createTables(Database db, int version) async {
    // Tabla de misiones
    await db.execute('''
      CREATE TABLE missions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        type TEXT NOT NULL DEFAULT 'diaria',
        difficulty TEXT NOT NULL DEFAULT 'normal',
        duration_minutes INTEGER NOT NULL DEFAULT 15,
        attribute TEXT NOT NULL DEFAULT 'discipline',
        reward_xp INTEGER NOT NULL DEFAULT 30,
        reward_gold INTEGER NOT NULL DEFAULT 20,
        completed INTEGER NOT NULL DEFAULT 0,
        time_spent INTEGER NOT NULL DEFAULT 0,
        date_created TEXT NOT NULL,
        date_completed TEXT
      )
    ''');

    // Tabla de inventario
    await db.execute('''
      CREATE TABLE inventory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id TEXT NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        rarity TEXT NOT NULL DEFAULT 'comun',
        icon TEXT NOT NULL,
        description TEXT,
        quantity INTEGER NOT NULL DEFAULT 1,
        equipped INTEGER NOT NULL DEFAULT 0,
        upgrade_level INTEGER NOT NULL DEFAULT 0,
        stats_json TEXT
      )
    ''');

    // Tabla de historial de atributos
    await db.execute('''
      CREATE TABLE attribute_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        attribute TEXT NOT NULL,
        amount INTEGER NOT NULL,
        description TEXT,
        timestamp INTEGER NOT NULL
      )
    ''');

    // Tabla de registro del calendario
    await db.execute('''
      CREATE TABLE calendar (
        date TEXT PRIMARY KEY,
        status TEXT NOT NULL DEFAULT 'incomplete',
        xp_gained INTEGER NOT NULL DEFAULT 0,
        minutes_spent INTEGER NOT NULL DEFAULT 0,
        stats_json TEXT
      )
    ''');

    // Tabla de logros
    await db.execute('''
      CREATE TABLE achievements (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        reward_description TEXT,
        completed INTEGER NOT NULL DEFAULT 0,
        date_completed TEXT
      )
    ''');

    // Tabla de portales semanales completados
    await db.execute('''
      CREATE TABLE portal_runs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        portal_rank TEXT NOT NULL,
        date_started TEXT NOT NULL,
        date_completed TEXT,
        result TEXT NOT NULL DEFAULT 'in_progress',
        stages_completed INTEGER NOT NULL DEFAULT 0,
        xp_gained INTEGER NOT NULL DEFAULT 0,
        gold_gained INTEGER NOT NULL DEFAULT 0,
        loot_json TEXT
      )
    ''');

    // Insertar logros predeterminados
    await _insertDefaultAchievements(db);
  }

  Future<void> _insertDefaultAchievements(Database db) async {
    final achievements = [
      {'id': 'primer_paso', 'name': 'Primer Paso', 'description': 'Completar la calibración inicial del Sistema.', 'reward_description': '+100 Oro'},
      {'id': 'primera_mision', 'name': 'Primer Combate', 'description': 'Completar tu primera misión diaria.', 'reward_description': 'Poción Pequeña x3'},
      {'id': 'racha_7', 'name': 'Disciplina de Hierro', 'description': 'Mantener una racha de 7 días consecutivos.', 'reward_description': '+50 Oro + Receta: Peto de Cuero'},
      {'id': 'racha_30', 'name': 'Rey de las Rachas', 'description': 'Mantener una racha de 30 días consecutivos.', 'reward_description': '+15 AP Pasivo (Título)'},
      {'id': 'nivel_10', 'name': 'Cazador D', 'description': 'Alcanzar el Nivel 10.', 'reward_description': '+200 Oro'},
      {'id': 'nivel_25', 'name': 'Cazador C', 'description': 'Alcanzar el Nivel 25.', 'reward_description': 'Espada de Plata'},
      {'id': 'nivel_50', 'name': 'Cazador B', 'description': 'Alcanzar el Nivel 50.', 'reward_description': 'Daga de las Sombras'},
      {'id': 'nivel_100', 'name': 'Cazador A - Legendario', 'description': 'Alcanzar el Nivel 100.', 'reward_description': '+50 AP Pasivo (Título: Legendario)'},
      {'id': 'primer_portal', 'name': 'Explorador de Portales', 'description': 'Completar con éxito un Portal Semanal.', 'reward_description': '+250 Oro'},
      {'id': 'dragon_slayer', 'name': 'Dragon Slayer', 'description': 'Derrotar al Dragón Azul en el Portal Rango S.', 'reward_description': '+30 AP + Corona del Primer Hunter'},
      {'id': 'coleccionista_50', 'name': 'Coleccionista', 'description': 'Obtener 50 objetos diferentes en el inventario.', 'reward_description': '+10 AP Pasivo'},
      {'id': 'mil_misiones', 'name': 'Guerrero Eterno', 'description': 'Completar 1000 misiones en el Sistema.', 'reward_description': 'Título: Guerrero Eterno + +30 AP'},
    ];

    for (final ach in achievements) {
      await db.insert('achievements', ach, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migraciones futuras se manejan aquí
  }

  // ============================================================
  // CRUD - MISIONES
  // ============================================================

  Future<int> insertMission(Map<String, dynamic> mission) async {
    final db = await database;
    return db.insert('missions', mission, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getMissions({String? type, String? date}) async {
    final db = await database;
    String where = '';
    List<dynamic> args = [];

    if (type != null) {
      where += 'type = ?';
      args.add(type);
    }
    if (date != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'date_created = ?';
      args.add(date);
    }

    return db.query('missions', where: where.isEmpty ? null : where, whereArgs: args.isEmpty ? null : args, orderBy: 'id DESC');
  }

  Future<int> updateMission(Map<String, dynamic> mission) async {
    final db = await database;
    return db.update('missions', mission, where: 'id = ?', whereArgs: [mission['id']]);
  }

  Future<int> deleteMission(int id) async {
    final db = await database;
    return db.delete('missions', where: 'id = ?', whereArgs: [id]);
  }

  // ============================================================
  // CRUD - INVENTARIO
  // ============================================================

  Future<int> insertInventoryItem(Map<String, dynamic> item) async {
    final db = await database;
    return db.insert('inventory', item, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getInventory({String? type}) async {
    final db = await database;
    return db.query(
      'inventory',
      where: type != null ? 'type = ?' : null,
      whereArgs: type != null ? [type] : null,
    );
  }

  Future<int> updateInventoryItem(Map<String, dynamic> item) async {
    final db = await database;
    return db.update('inventory', item, where: 'id = ?', whereArgs: [item['id']]);
  }

  Future<int> deleteInventoryItem(int id) async {
    final db = await database;
    return db.delete('inventory', where: 'id = ?', whereArgs: [id]);
  }

  // ============================================================
  // CRUD - HISTORIAL DE ATRIBUTOS
  // ============================================================

  Future<int> insertAttributeHistory(String attribute, int amount, String description) async {
    final db = await database;
    final now = DateTime.now();
    return db.insert('attribute_history', {
      'date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      'attribute': attribute,
      'amount': amount,
      'description': description,
      'timestamp': now.millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String, dynamic>>> getAttributeHistory({int limit = 50}) async {
    final db = await database;
    return db.query('attribute_history', orderBy: 'timestamp DESC', limit: limit);
  }

  // ============================================================
  // CRUD - CALENDARIO
  // ============================================================

  Future<int> upsertCalendarEntry(Map<String, dynamic> entry) async {
    final db = await database;
    return db.insert('calendar', entry, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getCalendar({String? yearMonth}) async {
    final db = await database;
    if (yearMonth != null) {
      return db.query('calendar', where: 'date LIKE ?', whereArgs: ['$yearMonth%'], orderBy: 'date ASC');
    }
    return db.query('calendar', orderBy: 'date ASC');
  }

  Future<Map<String, dynamic>?> getCalendarByDate(String date) async {
    final db = await database;
    final results = await db.query('calendar', where: 'date = ?', whereArgs: [date]);
    return results.isEmpty ? null : results.first;
  }

  // ============================================================
  // CRUD - LOGROS
  // ============================================================

  Future<List<Map<String, dynamic>>> getAchievements() async {
    final db = await database;
    return db.query('achievements', orderBy: 'completed ASC');
  }

  Future<int> completeAchievement(String id) async {
    final db = await database;
    final now = DateTime.now();
    return db.update(
      'achievements',
      {'completed': 1, 'date_completed': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // CRUD - PORTALES
  // ============================================================

  Future<int> insertPortalRun(Map<String, dynamic> run) async {
    final db = await database;
    return db.insert('portal_runs', run);
  }

  Future<int> updatePortalRun(Map<String, dynamic> run) async {
    final db = await database;
    return db.update('portal_runs', run, where: 'id = ?', whereArgs: [run['id']]);
  }

  Future<List<Map<String, dynamic>>> getPortalRuns() async {
    final db = await database;
    return db.query('portal_runs', orderBy: 'date_started DESC');
  }
}

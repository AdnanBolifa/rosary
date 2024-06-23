import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'tasbih_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasbihs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tasbih_id INTEGER,
        count INTEGER,
        FOREIGN KEY (tasbih_id) REFERENCES tasbihs (id)
      )
    ''');
  }

  Future<int> addTasbih(String text) async {
    Database db = await database;
    return await db.insert('tasbihs', {'text': text});
  }

  Future<List<Map<String, dynamic>>> getTasbihs() async {
    Database db = await database;
    return await db.query('tasbihs');
  }

  Future<void> addHistory(int tasbihId, int count) async {
    Database db = await database;
    await db.insert('history', {'tasbih_id': tasbihId, 'count': count});
  }

  Future<int> getTasbihCount(int tasbihId) async {
    Database db = await database;
    var result = await db.rawQuery(
        'SELECT SUM(count) as total FROM history WHERE tasbih_id = ?',
        [tasbihId]);
    return result[0]['total'] != null ? result[0]['total'] as int : 0;
  }

  Future<List<Map<String, dynamic>>> getTasbihHistory(int tasbihId) async {
    Database db = await database;
    return await db
        .query('history', where: 'tasbih_id = ?', whereArgs: [tasbihId]);
  }

  Future<void> resetTasbihHistory(int tasbihId) async {
    Database db = await database;
    await db.delete('history', where: 'tasbih_id = ?', whereArgs: [tasbihId]);
  }
}

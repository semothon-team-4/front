import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// 옷장 데이터를 기기 로컬 DB(SQLite)에 저장합니다.
class WardrobeDB {
  static Database? _db;

  static Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'wardrobe.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE clothes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            grade TEXT NOT NULL,
            desc TEXT,
            imagePath TEXT,
            lastCare TEXT,
            createdAt TEXT NOT NULL
          )
        ''');
      },
    );
  }

  /// 의류 추가
  static Future<int> insertClothing(Map<String, dynamic> item) async {
    final db = await database;
    return db.insert('clothes', {
      ...item,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  /// 전체 의류 목록 조회
  static Future<List<Map<String, dynamic>>> getAllClothes() async {
    final db = await database;
    return db.query('clothes', orderBy: 'createdAt DESC');
  }

  /// 의류 수정 (등급/설명 업데이트)
  static Future<void> updateClothing(int id, Map<String, dynamic> data) async {
    final db = await database;
    await db.update('clothes', data, where: 'id = ?', whereArgs: [id]);
  }

  /// 의류 삭제
  static Future<void> deleteClothing(int id) async {
    final db = await database;
    await db.delete('clothes', where: 'id = ?', whereArgs: [id]);
  }
}

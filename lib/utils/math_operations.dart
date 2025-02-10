import 'package:sqflite/sqflite.dart';
import '../models_for_api/math_model_api.dart';
import 'database_setup.dart';

class MathOperations {
  final DatabaseSetup _databaseSetup = DatabaseSetup();

  Future<void> insertItem(MathModelApi item) async {
    final Database db = await _databaseSetup.database;
    await db.insert(
      'math_items',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<MathModelApi>> getAllItems() async {
    final Database db = await _databaseSetup.database;
    final List<Map<String, dynamic>> maps = await db.query('math_items');
    return List.generate(maps.length, (i) => MathModelApi.fromMap(maps[i]));
  }

  Future<List<MathModelApi>> getItemsByLevel(int level) async {
    final Database db = await _databaseSetup.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'math_items',
      where: 'level = ?',
      whereArgs: [level],
    );
    return List.generate(maps.length, (i) => MathModelApi.fromMap(maps[i]));
  }

  Future<void> deleteAllItems() async {
    final Database db = await _databaseSetup.database;
    await db.delete('math_items');
  }
}

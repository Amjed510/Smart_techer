
import 'package:sqflite/sqflite.dart';
import 'package:teatcher_smarter/models_for_api/sentence_model.dart';

import 'database_setup.dart';

class DatabaseSentensOperations {
  final DatabaseSetup _databaseSetup = DatabaseSetup();

  Future<Database> get _db async => await _databaseSetup.database;

  // Insert a new sentence into the database
  Future<void> InsertSentens(SentenceModel sentens) async {
    try {
      final db = await _db;
      await db.insert('sentens', sentens.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      print('Successfully inserted sentence: ${sentens.toString()}');
    } catch (e) {
      print('Error inserting sentence: $e');
      rethrow;
    }
  }

  // Fetch all sentences from the database
  Future<List<SentenceModel>> FetchSentens() async {
    try {
      final db = await _db;
      final List<Map<String, dynamic>> maps = await db.query('sentens');
      print('Fetched ${maps.length} sentences from database');

      return List.generate(maps.length, (index) {
        try {
          return SentenceModel(
            id: maps[index]['id'] ?? 0,
            text: maps[index]['text'] ?? '',
            level: maps[index]['level'] ?? 0,
          );
        } catch (e) {
          print('Error parsing sentence at index $index: $e');
          // Return a default sentence in case of parsing error
          return SentenceModel(
            id: 0,
            text: 'Error loading sentence',
            level: 0,
          );
        }
      });
    } catch (e) {
      print('Error fetching sentences: $e');
      return []; // Return empty list on error
    }
  }

  // Update an existing sentence in the database
  Future<void> UpdateSentens(SentenceModel sentens) async {
    try {
      final db = await _db;
      await db.update(
        'sentens',
        sentens.toMap(),
        where: 'id = ?',
        whereArgs: [sentens.id],
      );
      print('Successfully updated sentence: ${sentens.toString()}');
    } catch (e) {
      print('Error updating sentence: $e');
      rethrow;
    }
  }

  // Delete a sentence from the database by its ID
  Future<void> DeleteSentens(int id) async {
    try {
      final db = await _db;
      await db.delete(
        'sentens',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('Successfully deleted sentence with ID: $id');
    } catch (e) {
      print('Error deleting sentence: $e');
      rethrow;
    }
  }

  // Clear all sentences and insert new ones in a single transaction
  Future<void> clearAndInsertsentens(List<SentenceModel> sentens) async {
    try {
      final db = await _db;

      await db.transaction((txn) async {
        final batch = txn.batch();

        for (final item in sentens) {
          final existingItem = await txn.query(
            'sentens',
            where: 'id = ?',
            whereArgs: [item.id],
          );

          if (existingItem.isNotEmpty) {
            batch.update(
              'sentens',
              {
                'text': item.text,
                'level': item.level,
              },
              where: 'id = ?',
              whereArgs: [item.id],
            );
          } else {
            batch.insert('sentens', {
              'id': item.id,
              'text': item.text,
              'level': item.level,
            });
          }
        }

        await batch.commit(noResult: true);
        print('Successfully inserted ${sentens.length} sentences');
      });
    } catch (e) {
      print('Error in batch insert: $e');
      rethrow;
    }
  }
}

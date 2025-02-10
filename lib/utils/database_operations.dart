import 'package:sqflite/sqflite.dart';
import 'package:teatcher_smarter/models/level_ar.dart';
import 'package:teatcher_smarter/models_for_api/word_model.dart';

import 'database_setup.dart';

class DatabaseOperations {
  final DatabaseSetup _dbInit = DatabaseSetup();

  // دالة مساعدة للوصول إلى قاعدة البيانات
  Future<Database> get _db async => await _dbInit.database;

  // دالة لإدراج عنصر جديد في جدول 'items'
  Future<void> insertItem(WordModel item) async {
    final db = await _db;
    await db.insert(
      'items',
      item.toMap(),
      conflictAlgorithm:
          ConflictAlgorithm.replace, // استبدال العنصر إذا كان موجودًا
    );
  }

  // دالة لحفظ قائمة من العناصر في جدول 'items'
  Future<void> saveItems(List<WordModel> items) async {
    final db = await _db;
    await db.transaction((txn) async {
      // حذف جميع العناصر الموجودة في الجدول
      await txn.delete('items');

      // إدراج العناصر الجديدة
      for (var item in items) {
        await txn.insert(
          'items',
          item.toMap(),
          conflictAlgorithm:
              ConflictAlgorithm.replace, // استبدال العنصر إذا كان موجودًا
        );
      }
    });
  }

  // دالة لجلب جميع العناصر من جدول 'items'
  Future<List<WordModel>> fetchItems() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query('items');

    return List.generate(maps.length, (index) {
      return WordModel(
        id: maps[index]['id'],
        text: maps[index]['text'],
        image: maps[index]['image'] ?? "",
        level: maps[index]['level'],
      );
    });
  }

  // دالة لتحديث عنصر موجود في جدول 'items'
  Future<void> updateItem(WordModel item) async {
    final db = await _db;
    await db.update(
      'items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  // دالة لحذف عنصر من جدول 'items'
  Future<void> deleteItem(int id) async {
    final db = await _db;
    await db.delete(
      'items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // دالة لحذف جميع العناصر من جدول 'items'
  Future<void> clearItems() async {
    final db = await _db;
    await db.delete('items');
  }

  // دالة لحذف جميع العناصر وإدراج عناصر جديدة في معاملة واحدة
  Future<void> clearAndInsertItems(List<WordModel> items) async {
    final db = await _db;

    await db.transaction((txn) async {
      final batch = txn.batch();
      // batch.delete('items'); // يمكن إزالة هذا السطر إذا كنت تريد تحديث العناصر الموجودة فقط
      for (final item in items) {
        final existingItem = await txn.query(
          'items',
          where: 'id = ?',
          whereArgs: [item.id],
        );

        // تحديث العنصر إذا كان موجودًا أو إدراجه إذا لم يكن موجودًا
        if (existingItem.isNotEmpty) {
          batch.update(
            'items',
            {
              'text': item.text,
              'image': item.image,
              'level': item.level,
            },
            where: 'id = ?',
            whereArgs: [item.id],
          );
        } else {
          batch.insert('items', {
            'id': item.id,
            'text': item.text,
            'image': item.image,
            'level': item.level,
          });
        }
      }

      await batch.commit(noResult: true);
    });
  }

  // دالة لحفظ تقدم المستخدم في الرياضيات
  Future<void> saveProgress({
    required int operation,
    required int level,
    required List<int> completedExamples,
    required bool isCompleted,
    int? lastAccessedWordId =
        null, // جعل lastAccessedWordId اختياريًا مع قيمة افتراضية null
  }) async {
    final db = await _dbInit.database;

    // التحقق من وجود تقدم سابق لنفس العملية والمستوى
    final existing = await db.query(
      'user_progress',
      where: 'operation = ? AND level = ?',
      whereArgs: [operation, level],
    );

    final progress = {
      'operation': operation,
      'level': level,
      'completed_examples': completedExamples.join(','),
      'last_accessed': DateTime.now().millisecondsSinceEpoch,
      'is_completed': isCompleted ? 1 : 0,
      'last_accessed_word_id':
          lastAccessedWordId, //  حفظ lastAccessedWordId حتى لو كان null
    };

    // إدراج تقدم جديد إذا لم يكن موجودًا أو تحديث التقدم الحالي
    if (existing.isEmpty) {
      await db.insert('user_progress', progress);
    } else {
      await db.update(
        'user_progress',
        progress,
        where: 'operation = ? AND level = ?',
        whereArgs: [operation, level],
      );
    }
  }

  // دالة للحصول على تقدم المستخدم في الرياضيات لعملية ومستوى محددين
  Future<Map<String, dynamic>?> getProgress({
    required int operation,
    required int level,
  }) async {
    final db = await _dbInit.database;

    final results = await db.query(
      'user_progress',
      where: 'operation = ? AND level = ?',
      whereArgs: [operation, level],
    );

    if (results.isEmpty) return null;

    final progress = results.first;
    final completedExamples = progress['completed_examples'] as String;

    return {
      'operation': progress['operation'] as int,
      'level': progress['level'] as int,
      'completed_examples': completedExamples.isEmpty
          ? <int>[]
          : completedExamples
              .split(',')
              .map((e) => int.parse(e))
              .toList(), // تحويل النص إلى قائمة أرقام
      'last_accessed':
          DateTime.fromMillisecondsSinceEpoch(progress['last_accessed'] as int),
      'is_completed': progress['is_completed'] == 1,
      'last_accessed_word_id': progress['last_accessed_word_id'] as int?, // إضافة هذا السطر
    };
  }

  // دالة للحصول على جميع العمليات المكتملة في مستوى معين
  Future<List<int>> getCompletedOperations(int level) async {
    final db = await _dbInit.database;

    final results = await db.query(
      'user_progress',
      where: 'level = ? AND is_completed = 1',
      whereArgs: [level],
    );

    return results.map((e) => e['operation'] as int).toList();
  }

  // دالة لحذف تقدم المستخدم في الرياضيات (مثلاً عند إعادة تعيين التطبيق)
  Future<void> clearProgress() async {
    final db = await _dbInit.database;
    await db.delete('user_progress');
  }

  // دوال إدارة تقدم الكلمات:

  // دالة لحفظ تقدم تعلم كلمة
  Future<void> saveWordProgress({
    required int wordId,
    required bool isCorrect,
    bool isMastered = false,
    double? confidenceLevel,
  }) async {
    final db = await _dbInit.database;

    // التحقق من وجود تقدم سابق لنفس الكلمة
    final existing = await db.query(
      'word_progress',
      where: 'word_id = ?',
      whereArgs: [wordId],
    );

    final now = DateTime.now().millisecondsSinceEpoch;

    // إدراج تقدم جديد إذا لم يكن موجودًا أو تحديث التقدم الحالي
    if (existing.isEmpty) {
      await db.insert('word_progress', {
        'word_id': wordId,
        'attempts': 1,
        'correct_attempts': isCorrect ? 1 : 0,
        'last_practiced': now,
        'is_mastered': isMastered ? 1 : 0,
        'confidence_level': confidenceLevel ?? (isCorrect ? 0.2 : 0.0),
      });
    } else {
      final current = existing.first;
      final attempts = (current['attempts'] as int) + 1;
      final correctAttempts =
          (current['correct_attempts'] as int) + (isCorrect ? 1 : 0);

      // حساب مستوى الثقة الجديد
      final newConfidenceLevel = confidenceLevel ??
          ((current['confidence_level'] as double) + (isCorrect ? 0.2 : -0.1))
              .clamp(0.0, 1.0);

      await db.update(
        'word_progress',
        {
          'attempts': attempts,
          'correct_attempts': correctAttempts,
          'last_practiced': now,
          'is_mastered': isMastered ? 1 : 0,
          'confidence_level': newConfidenceLevel,
        },
        where: 'word_id = ?',
        whereArgs: [wordId],
      );
    }
  }

  // دالة للحصول على تقدم تعلم كلمة محددة
  Future<Map<String, dynamic>?> getWordProgress(int wordId) async {
    final db = await _dbInit.database;

    final results = await db.query(
      'word_progress',
      where: 'word_id = ?',
      whereArgs: [wordId],
    );

    if (results.isEmpty) return null;

    final progress = results.first;
    return {
      'word_id': progress['word_id'] as int,
      'attempts': progress['attempts'] as int,
      'correct_attempts': progress['correct_attempts'] as int,
      'last_practiced': DateTime.fromMillisecondsSinceEpoch(
          progress['last_practiced'] as int),
      'is_mastered': progress['is_mastered'] == 1,
      'confidence_level': progress['confidence_level'] as double,
    };
  }

  // دالة للحصول على تقدم تعلم جميع الكلمات
  Future<List<Map<String, dynamic>>> getAllWordsProgress() async {
    final db = await _dbInit.database;

    final results = await db.query('word_progress');

    return results
        .map((progress) => {
              'word_id': progress['word_id'] as int,
              'attempts': progress['attempts'] as int,
              'correct_attempts': progress['correct_attempts'] as int,
              'last_practiced': DateTime.fromMillisecondsSinceEpoch(
                  progress['last_practiced'] as int),
              'is_mastered': progress['is_mastered'] == 1 ? true : false,
              'confidence_level': progress['confidence_level'] as double,
            })
        .toList();
  }

  // دالة لإعادة تعيين تقدم تعلم الكلمات
  Future<void> resetWordProgress() async {
    final db = await _dbInit.database;
    await db.delete('word_progress');
  }

  // دالة لإدراج حرف في جدول 'letters'
  Future<void> insertLetter(Letter letter) async {
    final db = await _dbInit.database;
    await db.insert(
      'letters',
      letter.toMap(),
      conflictAlgorithm:
          ConflictAlgorithm.replace, // استبدال الحرف إذا كان موجودًا
    );
  }

  // دالة لتحديث حرف موجود في جدول 'letters'
  Future<void> updateLetter(Letter letter) async {
    final db = await _dbInit.database;
    await db.update(
      'letters',
      letter.toMap(),
      where: 'character = ?',
      whereArgs: [letter.character],
    );
  }

  // دالة للحصول على جميع الحروف من جدول 'letters'
  Future<List<Letter>> getLetters() async {
    final db = await _dbInit.database;
    final List<Map<String, dynamic>> maps = await db.query('letters');

    return List.generate(maps.length, (i) {
      return Letter.fromMap(maps[i]);
    });
  }

  // دوال إدارة تقدم الجمل:

  // دالة لحفظ تقدم تعلم جملة
  Future<void> saveSentenceProgress({
    required int sentenceId,
    required bool isCorrect,
    bool isMastered = false,
    double? confidenceLevel,
  }) async {
    final db = await _dbInit.database;

    // التحقق من وجود تقدم سابق لنفس الجملة
    final existing = await db.query(
      'sentence_progress',
      where: 'sentence_id = ?',
      whereArgs: [sentenceId],
    );

    final now = DateTime.now().millisecondsSinceEpoch;

    // إدراج تقدم جديد إذا لم يكن موجودًا أو تحديث التقدم الحالي
    if (existing.isEmpty) {
      await db.insert('sentence_progress', {
        'sentence_id': sentenceId,
        'attempts': 1,
        'correct_attempts': isCorrect ? 1 : 0,
        'last_practiced': now,
        'is_mastered': isMastered ? 1 : 0,
        'confidence_level': confidenceLevel ?? (isCorrect ? 0.2 : 0.0),
      });
    } else {
      final current = existing.first;
      final attempts = (current['attempts'] as int) + 1;
      final correctAttempts =
          (current['correct_attempts'] as int) + (isCorrect ? 1 : 0);

      // حساب مستوى الثقة الجديد
      final newConfidenceLevel = confidenceLevel ??
          ((current['confidence_level'] as double) + (isCorrect ? 0.2 : -0.1))
              .clamp(0.0, 1.0);

      await db.update(
        'sentence_progress',
        {
          'attempts': attempts,
          'correct_attempts': correctAttempts,
          'last_practiced': now,
          'is_mastered': isMastered ? 1 : 0,
          'confidence_level': newConfidenceLevel,
        },
        where: 'sentence_id = ?',
        whereArgs: [sentenceId],
      );
    }
  }

  // دالة للحصول على تقدم تعلم جملة محددة
  Future<Map<String, dynamic>?> getSentenceProgress(int sentenceId) async {
    final db = await _dbInit.database;

    final results = await db.query(
      'sentence_progress',
      where: 'sentence_id = ?',
      whereArgs: [sentenceId],
    );

    if (results.isEmpty) return null;

    final progress = results.first;
    return {
      'sentence_id': progress['sentence_id'] as int,
      'attempts': progress['attempts'] as int,
      'correct_attempts': progress['correct_attempts'] as int,
      'last_practiced': DateTime.fromMillisecondsSinceEpoch(
          progress['last_practiced'] as int),
      'is_mastered': progress['is_mastered'] == 1,
      'confidence_level': progress['confidence_level'] as double,
    };
  }

  // دالة للحصول على تقدم تعلم جميع الجمل
  Future<List<Map<String, dynamic>>> getAllSentencesProgress() async {
    final db = await _dbInit.database;

    final results = await db.query('sentence_progress');

    return results
        .map((progress) => {
              'sentence_id': progress['sentence_id'] as int? ?? 0,
              'attempts': progress['attempts'] as int? ?? 0,
              'correct_attempts': progress['correct_attempts'] as int? ?? 0,
              'last_practiced': progress['last_practiced'] != null
                  ? DateTime.fromMillisecondsSinceEpoch(progress['last_practiced'] as int)
                  : DateTime.now(),
              'is_mastered': progress['is_mastered'] == 1,
              'confidence_level': (progress['confidence_level'] as num?)?.toDouble() ?? 0.0,
            })
        .toList();
  }

  // دالة لإعادة تعيين تقدم تعلم الجمل
  Future<void> resetSentenceProgress() async {
    final db = await _dbInit.database;
    await db.delete('sentence_progress');
  }
}

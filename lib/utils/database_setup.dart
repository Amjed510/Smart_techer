import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseSetup {
  static final DatabaseSetup _instance = DatabaseSetup._internal();
  static Database? _database;

  factory DatabaseSetup() => _instance;

  DatabaseSetup._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'learning_app.db');
    return await openDatabase(
      path,
      version: 4, // تحديث رقم الإصدار
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // من قاعدة البيانات الأولى: جدول الأمثلة الرياضية
    await db.execute('''
      CREATE TABLE IF NOT EXISTS math_examples (
        id INTEGER PRIMARY KEY,
        firstNumber INTEGER,
        secondNumber INTEGER,
        result INTEGER,
        arithmeticOperations INTEGER,
        level INTEGER,
        problemText TEXT,
        isExample INTEGER
      )
    ''');

    // من قاعدة البيانات الأولى: جدول تقدم المستخدم في الرياضيات
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation INTEGER,
        level INTEGER,
        completed_examples TEXT,
        last_accessed INTEGER,
        is_completed INTEGER DEFAULT 0,
        last_accessed_word_id INTEGER
      )
    ''');

    // من قاعدة البيانات الأولى: جدول تقدم تعلم الكلمات
    await db.execute('''
      CREATE TABLE IF NOT EXISTS word_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word_id INTEGER,
        attempts INTEGER DEFAULT 0,
        correct_attempts INTEGER DEFAULT 0,
        last_practiced INTEGER,
        is_mastered INTEGER DEFAULT 0,
        confidence_level REAL DEFAULT 0.0
      )
    ''');

    // من قاعدة البيانات الأولى: جدول الحروف
    await db.execute('''
      CREATE TABLE IF NOT EXISTS letters (
        character TEXT PRIMARY KEY,
        name TEXT,
        stars INTEGER,
        attempts INTEGER,
        status INTEGER
      )
    ''');

    // من قاعدة البيانات الثانية: جدول items
    await db.execute('''
      CREATE TABLE IF NOT EXISTS items (
        id INTEGER PRIMARY KEY,
        text TEXT,
        image TEXT,
        level INTEGER
      )
    ''');

    // من قاعدة البيانات الثانية: جدول sentences
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sentens (
        id INTEGER PRIMARY KEY,
        text TEXT,
        level INTEGER
      )
    ''');

    // من قاعدة البيانات الثانية: جدول math_items
    await db.execute('''
      CREATE TABLE IF NOT EXISTS math_items (
        id INTEGER PRIMARY KEY,
        arithmeticOperations INTEGER,
        num1 INTEGER,
        num2 INTEGER,
        steps TEXT,
        level INTEGER
      )
    ''');

    // جدول تقدم تعلم الجمل
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sentence_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sentence_id INTEGER,
        attempts INTEGER DEFAULT 0,
        correct_attempts INTEGER DEFAULT 0,
        last_practiced INTEGER,
        is_mastered INTEGER DEFAULT 0,
        confidence_level REAL DEFAULT 0.0
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // ترقيات قاعدة البيانات الأولى
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_progress (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          operation INTEGER,
          level INTEGER,
          completed_examples TEXT,
          last_accessed INTEGER,
          is_completed INTEGER DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS word_progress (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          word_id INTEGER,
          attempts INTEGER DEFAULT 0,
          correct_attempts INTEGER DEFAULT 0,
          last_practiced INTEGER,
          is_mastered INTEGER DEFAULT 0,
          confidence_level REAL DEFAULT 0.0
        )
      ''');
    }

    // ترقيات قاعدة البيانات الثانية
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sentens (
          id INTEGER PRIMARY KEY,
          text TEXT,
          level INTEGER
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS math_items (
          id INTEGER PRIMARY KEY,
          arithmeticOperations INTEGER,
          num1 INTEGER,
          num2 INTEGER,
          steps TEXT,
          level INTEGER
        )
      ''');

      // Move sentence_progress table creation to version 3
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sentence_progress (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sentence_id INTEGER,
          attempts INTEGER DEFAULT 0,
          correct_attempts INTEGER DEFAULT 0,
          last_practiced INTEGER,
          is_mastered INTEGER DEFAULT 0,
          confidence_level REAL DEFAULT 0.0
        )
      ''');
    }

    // إضافة عمود last_accessed_word_id إلى جدول user_progress
    if (oldVersion < 4) {
      await db.execute('''
        ALTER TABLE user_progress
        ADD COLUMN last_accessed_word_id INTEGER
      ''');
    }
  }
}

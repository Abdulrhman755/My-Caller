import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io'; // لاستخدام Directory
import 'package:path/path.dart'; // لاستخدام join

// هذا هو النموذج الذي سنخزنه في قاعدة البيانات
class SavedContact {
  final String number;
  final String name;

  SavedContact({required this.number, required this.name});

  // للتحويل إلى Map لإدخاله في قاعدة البيانات
  Map<String, dynamic> toMap() {
    return {
      'number': number,
      'name': name,
    };
  }
}

// هذه الخدمة (Service) هي المسؤولة عن فتح وإنشاء الجدول
class DatabaseService {
  // 1. جعلها Singleton (لضمان فتح قاعدة بيانات واحدة فقط)
  DatabaseService._privateConstructor();
  static final DatabaseService instance = DatabaseService._privateConstructor();

  static Database? _database;
  
  // 2. دالة getter لضمان أن قاعدة البيانات مُهيأة
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // 3. دالة التهيئة (Initialization)
  Future<Database> _initDatabase() async {
    // الحصول على مسار آمن لتخزين قاعدة البيانات
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'contacts.db');
    
    // فتح قاعدة البيانات وإنشاء الجدول
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // 4. دالة الإنشاء (CREATE TABLE)
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE contacts(
        number TEXT PRIMARY KEY, 
        name TEXT NOT NULL
      )
    ''');
  }

  // 5. دالة لإدخال/تحديث اسم
  Future<void> insertContact(SavedContact contact) async {
    final db = await instance.database;
    await db.insert(
      'contacts',
      contact.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace, // إذا كان الرقم موجوداً، قم بتحديث الاسم
    );
  }

  // 6. دالة لجلب اسم معين عن طريق رقمه
  Future<SavedContact?> getContactByNumber(String number) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'contacts',
      where: 'number = ?',
      whereArgs: [number],
    );

    if (maps.isNotEmpty) {
      return SavedContact(
        number: maps.first['number'],
        name: maps.first['name'],
      );
    }
    return null;
  }
}
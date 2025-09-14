import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/doctor.dart';

class AuthDatabaseHelper {
  static final AuthDatabaseHelper _instance = AuthDatabaseHelper._internal();
  static Database? _database;

  AuthDatabaseHelper._internal();

  factory AuthDatabaseHelper() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'doctor_auth.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE doctors (
        id TEXT PRIMARY KEY,
        firstName TEXT NOT NULL,
        lastName TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        specialization TEXT NOT NULL,
        licenseNumber TEXT UNIQUE NOT NULL,
        phone TEXT NOT NULL,
        imagePath TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        isActive INTEGER DEFAULT 1
      )
    ''');

    // Index'ler oluştur
    await db.execute('CREATE INDEX idx_doctor_email ON doctors(email)');
    await db
        .execute('CREATE INDEX idx_doctor_license ON doctors(licenseNumber)');
    await db.execute('CREATE INDEX idx_doctor_active ON doctors(isActive)');
  }

  Future<String> insertDoctor(Doctor doctor) async {
    final db = await database;
    try {
      await db.insert(
        'doctors',
        doctor.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      return doctor.id;
    } catch (e) {
      throw Exception('Doktor kaydı eklenemedi: $e');
    }
  }

  Future<Doctor?> getDoctorById(String id) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'doctors',
        where: 'id = ? AND isActive = ?',
        whereArgs: [id, 1],
      );

      if (maps.isNotEmpty) {
        return Doctor.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Doktor bulunamadı: $e');
    }
  }

  Future<Doctor?> authenticateDoctor(
      String email, String hashedPassword) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'doctors',
        where: 'email = ? AND password = ? AND isActive = ?',
        whereArgs: [email, hashedPassword, 1],
      );

      if (maps.isNotEmpty) {
        return Doctor.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Kimlik doğrulama başarısız: $e');
    }
  }

  Future<bool> isEmailExists(String email) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'doctors',
        where: 'email = ? AND isActive = ?',
        whereArgs: [email, 1],
      );
      return maps.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isLicenseExists(String licenseNumber) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'doctors',
        where: 'licenseNumber = ? AND isActive = ?',
        whereArgs: [licenseNumber, 1],
      );
      return maps.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateDoctor(Doctor doctor) async {
    final db = await database;
    try {
      await db.update(
        'doctors',
        doctor.toMap(),
        where: 'id = ?',
        whereArgs: [doctor.id],
      );
    } catch (e) {
      throw Exception('Doktor güncellenemedi: $e');
    }
  }

  Future<List<Doctor>> getAllDoctors() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'doctors',
        where: 'isActive = ?',
        whereArgs: [1],
        orderBy: 'firstName ASC',
      );

      return List.generate(maps.length, (i) {
        return Doctor.fromMap(maps[i]);
      });
    } catch (e) {
      throw Exception('Doktorlar getirilemedi: $e');
    }
  }

  Future<void> deleteDoctor(String id) async {
    final db = await database;
    try {
      await db.update(
        'doctors',
        {'isActive': 0, 'updatedAt': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Doktor silinemedi: $e');
    }
  }

  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
  }
}

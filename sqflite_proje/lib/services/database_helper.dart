import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/patient.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Veritabanı yolunu daha güvenli bir şekilde al
    final databasesPath = await getDatabasesPath();
    String path = join(
      databasesPath,
      'patient_manager_persistent.db',
    ); // Yeni isim kullan

    if (kDebugMode) {
      debugPrint('Database path: $path');
      // Veritabanı dosyasının var olup olmadığını kontrol et
      bool exists = await databaseExists(path);
      debugPrint('Database exists: $exists');

      // Dosya boyutunu kontrol et
      if (exists) {
        final file = File(path);
        final stat = await file.stat();
        debugPrint('Database size: ${stat.size} bytes');
      }
    }

    // PRODUCTION'DA ASLA VERİTABANINI SİLMEYİN!
    // Bu satırları production'da kullanmayın:
    /*
    if (kDebugMode) {
      // SADECE DEVELOPMENT'ta ve gerektiğinde açın
      // await deleteDatabase(path);
      // debugPrint('Database deleted for testing');
    }
    */

    return await openDatabase(
      path, // Version artırıldı - yeni iyileştirmeler için
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        // Veritabanı açıldığında foreign key desteğini aç
        await db.execute('PRAGMA foreign_keys = ON');
        // WAL mode aktif et - daha iyi performans ve eşzamanlılık
        //await db.execute('PRAGMA journal_mode = WAL');
        // Synchronous modu optimize et
        //await db.execute('PRAGMA synchronous = NORMAL');
        // Auto vacuum aktif et - disk alanı yönetimi için
        //await db.execute('PRAGMA auto_vacuum = INCREMENTAL');

        if (kDebugMode) {
          debugPrint('Database opened successfully with WAL mode');
          // Veritabanı ayarlarını kontrol et
          final walMode = await db.rawQuery("PRAGMA journal_mode");
          final syncMode = await db.rawQuery("PRAGMA synchronous");
          final autoVacuum = await db.rawQuery("PRAGMA auto_vacuum");
          debugPrint('Journal mode: ${walMode.first.values.first}');
          debugPrint('Synchronous mode: ${syncMode.first.values.first}');
          debugPrint('Auto vacuum: ${autoVacuum.first.values.first}');
        }
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      // Transaction kullanarak tüm tabloları güvenli şekilde oluştur
      await db.transaction((txn) async {
        await txn.execute('''
          CREATE TABLE patients (
            id TEXT PRIMARY KEY,
            firstName TEXT NOT NULL,
            lastName TEXT NOT NULL,
            tcNumber TEXT UNIQUE NOT NULL,
            age INTEGER NOT NULL,
            gender TEXT NOT NULL,
            phone TEXT NOT NULL,
            email TEXT,
            address TEXT,
            diagnosis TEXT,
            bloodType TEXT,
            height REAL,
            weight REAL,
            hasChronicDisease INTEGER DEFAULT 0,
            emergencyContact TEXT,
            emergencyPhone TEXT,
            allergies TEXT,
            medications TEXT,
            notes TEXT,
            imagePath TEXT,
            createdAt INTEGER NOT NULL,
            updatedAt INTEGER NOT NULL,
            isActive INTEGER DEFAULT 1,
            doctorName TEXT,
            insuranceNumber TEXT,
            lastVisit INTEGER,
            nextAppointment INTEGER
          )
        ''');

        // Index'ler oluştur - performans için
        await txn.execute(
          'CREATE INDEX idx_patient_name ON patients(firstName, lastName)',
        );
        await txn.execute('CREATE INDEX idx_patient_tc ON patients(tcNumber)');
        await txn.execute(
          'CREATE INDEX idx_patient_diagnosis ON patients(diagnosis)',
        );
        await txn.execute(
          'CREATE INDEX idx_patient_active ON patients(isActive)',
        );
        await txn.execute(
          'CREATE INDEX idx_patient_created ON patients(createdAt)',
        );
        await txn.execute(
          'CREATE INDEX idx_patient_updated ON patients(updatedAt)',
        );
        await txn.execute(
          'CREATE INDEX idx_patient_doctor ON patients(doctorName)',
        );

        // Metadata tablosu oluştur - veritabanı bilgileri için
        await txn.execute('''
          CREATE TABLE db_metadata (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');

        // İlk metadata kayıtları
        final now = DateTime.now().millisecondsSinceEpoch;
        await txn.insert('db_metadata', {
          'key': 'db_version',
          'value': version.toString(),
          'created_at': now,
          'updated_at': now,
        });

        await txn.insert('db_metadata', {
          'key': 'created_at',
          'value': now.toString(),
          'created_at': now,
          'updated_at': now,
        });

        await txn.insert('db_metadata', {
          'key': 'last_backup',
          'value': '0',
          'created_at': now,
          'updated_at': now,
        });
      });

      if (kDebugMode) {
        debugPrint(
          'Database tables created successfully with version $version',
        );
      }
    } catch (e) {
      debugPrint('Error creating database tables: $e');
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      await db.transaction((txn) async {
        if (oldVersion < 2) {
          // Version 1'den 2'ye upgrade - yeni kolonlar ekle
          await _addMissingColumns(txn);
        }

        if (oldVersion < 3) {
          // Version 2'den 3'e upgrade - ek optimizasyonlar
          await txn.execute(
            'CREATE INDEX IF NOT EXISTS idx_patient_updated ON patients(updatedAt)',
          );
          await txn.execute(
            'CREATE INDEX IF NOT EXISTS idx_patient_doctor ON patients(doctorName)',
          );
        }

        if (oldVersion < 4) {
          // Version 3'den 4'e upgrade - metadata tablosu ve yeni kolonlar
          await _createMetadataTable(txn);
          await _addNewColumns(txn);
        }

        // Metadata güncelle
        final now = DateTime.now().millisecondsSinceEpoch;
        await txn.rawUpdate(
          '''
          UPDATE db_metadata 
          SET value = ?, updated_at = ? 
          WHERE key = ?
        ''',
          [newVersion.toString(), now, 'db_version'],
        );
      });

      if (kDebugMode) {
        debugPrint('Database upgraded from $oldVersion to $newVersion');
      }
    } catch (e) {
      debugPrint('Error upgrading database: $e');
      rethrow;
    }
  }

  // Metadata tablosu oluştur
  Future<void> _createMetadataTable(DatabaseExecutor db) async {
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS db_metadata (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');

      final now = DateTime.now().millisecondsSinceEpoch;
      await db.insert('db_metadata', {
        'key': 'created_at',
        'value': now.toString(),
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    } catch (e) {
      debugPrint('Error creating metadata table: $e');
    }
  }

  // Yeni kolonlar ekle
  Future<void> _addNewColumns(DatabaseExecutor db) async {
    try {
      final result = await db.rawQuery("PRAGMA table_info(patients)");
      final columns = result.map((row) => row['name'].toString()).toSet();

      if (!columns.contains('lastVisit')) {
        await db.execute('ALTER TABLE patients ADD COLUMN lastVisit INTEGER');
        if (kDebugMode) debugPrint('lastVisit column added');
      }

      if (!columns.contains('nextAppointment')) {
        await db.execute(
          'ALTER TABLE patients ADD COLUMN nextAppointment INTEGER',
        );
        if (kDebugMode) debugPrint('nextAppointment column added');
      }
    } catch (e) {
      debugPrint('Error adding new columns: $e');
    }
  }

  // Eksik kolonları ekle
  Future<void> _addMissingColumns(DatabaseExecutor db) async {
    try {
      // Mevcut tablo yapısını kontrol et
      final result = await db.rawQuery("PRAGMA table_info(patients)");
      final columns = result.map((row) => row['name'].toString()).toSet();

      // hasChronicDisease kolonu yoksa ekle
      if (!columns.contains('hasChronicDisease')) {
        await db.execute(
          'ALTER TABLE patients ADD COLUMN hasChronicDisease INTEGER DEFAULT 0',
        );
        if (kDebugMode) debugPrint('hasChronicDisease column added');
      }

      // doctorName kolonu yoksa ekle
      if (!columns.contains('doctorName')) {
        await db.execute('ALTER TABLE patients ADD COLUMN doctorName TEXT');
        if (kDebugMode) debugPrint('doctorName column added');
      }

      // insuranceNumber kolonu yoksa ekle
      if (!columns.contains('insuranceNumber')) {
        await db.execute(
          'ALTER TABLE patients ADD COLUMN insuranceNumber TEXT',
        );
        if (kDebugMode) debugPrint('insuranceNumber column added');
      }
    } catch (e) {
      debugPrint('Error adding missing columns: $e');
    }
  }

  Future<String> insertPatient(Patient patient) async {
    final db = await database;
    try {
      await db.transaction((txn) async {
        await txn.insert(
          'patients',
          patient.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });

      if (kDebugMode) {
        debugPrint('Patient inserted: ${patient.fullName} (ID: ${patient.id})');
        // Eklendikten sonra kontrol et
        final inserted = await getPatientById(patient.id);
        if (inserted != null) {
          debugPrint('✅ Patient successfully saved and verified');
        } else {
          debugPrint('❌ Patient insert verification failed');
        }
      }

      return patient.id;
    } catch (e) {
      debugPrint('Error inserting patient: $e');
      throw Exception('Hasta kaydı eklenemedi: $e');
    }
  }

  Future<List<Patient>> getAllPatients({bool activeOnly = true}) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'patients',
        where: activeOnly ? 'isActive = ?' : null,
        whereArgs: activeOnly ? [1] : null,
        orderBy: 'updatedAt DESC',
      );

      final patients = List.generate(maps.length, (i) {
        return Patient.fromMap(maps[i]);
      });

      if (kDebugMode) {
        debugPrint(
          'Retrieved ${patients.length} patients (activeOnly: $activeOnly)',
        );
        if (patients.isNotEmpty) {
          debugPrint('Sample patient: ${patients.first.fullName}');
        }
      }

      return patients;
    } catch (e) {
      debugPrint('Error getting all patients: $e');
      throw Exception('Hastalar getirilemedi: $e');
    }
  }

  Future<Patient?> getPatientById(String id) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'patients',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return Patient.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting patient by id: $e');
      throw Exception('Hasta bulunamadı: $e');
    }
  }

  Future<List<Patient>> searchPatients(String query) async {
    final db = await database;
    try {
      final searchTerm = '%${query.trim()}%';
      final List<Map<String, dynamic>> maps = await db.query(
        'patients',
        where: '''
          isActive = 1 AND (
            firstName LIKE ? OR 
            lastName LIKE ? OR 
            tcNumber LIKE ? OR 
            phone LIKE ? OR 
            diagnosis LIKE ?
          )
        ''',
        whereArgs: [searchTerm, searchTerm, searchTerm, searchTerm, searchTerm],
        orderBy: 'updatedAt DESC',
      );

      return List.generate(maps.length, (i) {
        return Patient.fromMap(maps[i]);
      });
    } catch (e) {
      debugPrint('Error searching patients: $e');
      throw Exception('Arama yapılamadı: $e');
    }
  }

  Future<List<Patient>> filterPatients({
    String? diagnosis,
    String? bloodType,
    String? gender,
    int? minAge,
    int? maxAge,
    bool? hasChronicDisease,
  }) async {
    final db = await database;
    List<String> whereClause = ['isActive = 1'];
    List<dynamic> whereArgs = [];

    if (diagnosis != null && diagnosis.trim().isNotEmpty) {
      whereClause.add('diagnosis LIKE ?');
      whereArgs.add('%${diagnosis.trim()}%');
    }

    if (bloodType != null && bloodType.trim().isNotEmpty) {
      whereClause.add('bloodType = ?');
      whereArgs.add(bloodType.trim());
    }

    if (gender != null && gender.trim().isNotEmpty) {
      whereClause.add('gender = ?');
      whereArgs.add(gender.trim());
    }

    if (minAge != null) {
      whereClause.add('age >= ?');
      whereArgs.add(minAge);
    }

    if (maxAge != null) {
      whereClause.add('age <= ?');
      whereArgs.add(maxAge);
    }

    if (hasChronicDisease != null) {
      whereClause.add('hasChronicDisease = ?');
      whereArgs.add(hasChronicDisease ? 1 : 0);
    }

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'patients',
        where: whereClause.join(' AND '),
        whereArgs: whereArgs,
        orderBy: 'updatedAt DESC',
      );

      return List.generate(maps.length, (i) {
        return Patient.fromMap(maps[i]);
      });
    } catch (e) {
      debugPrint('Error filtering patients: $e');
      throw Exception('Filtreleme yapılamadı: $e');
    }
  }

  Future<void> updatePatient(Patient patient) async {
    final db = await database;
    try {
      final result = await db.transaction((txn) async {
        return await txn.update(
          'patients',
          patient.toMap(),
          where: 'id = ?',
          whereArgs: [patient.id],
        );
      });

      if (result == 0) {
        throw Exception('Hasta bulunamadı');
      }

      if (kDebugMode) {
        debugPrint('Patient updated: ${patient.fullName}');
      }
    } catch (e) {
      debugPrint('Error updating patient: $e');
      throw Exception('Hasta güncellenemedi: $e');
    }
  }

  Future<void> deletePatient(String id) async {
    final db = await database;
    try {
      final result = await db.transaction((txn) async {
        return await txn.update(
          'patients',
          {'isActive': 0, 'updatedAt': DateTime.now().millisecondsSinceEpoch},
          where: 'id = ?',
          whereArgs: [id],
        );
      });

      if (result == 0) {
        throw Exception('Hasta bulunamadı');
      }

      if (kDebugMode) {
        debugPrint('Patient soft deleted: $id');
      }
    } catch (e) {
      debugPrint('Error deleting patient: $e');
      throw Exception('Hasta silinemedi: $e');
    }
  }

  Future<void> permanentDeletePatient(String id) async {
    final db = await database;
    try {
      final result = await db.transaction((txn) async {
        return await txn.delete('patients', where: 'id = ?', whereArgs: [id]);
      });

      if (result == 0) {
        throw Exception('Hasta bulunamadı');
      }

      if (kDebugMode) {
        debugPrint('Patient permanently deleted: $id');
      }
    } catch (e) {
      debugPrint('Error permanently deleting patient: $e');
      throw Exception('Hasta kalıcı olarak silinemedi: $e');
    }
  }

  Future<void> restorePatient(String id) async {
    final db = await database;
    try {
      final result = await db.transaction((txn) async {
        return await txn.update(
          'patients',
          {'isActive': 1, 'updatedAt': DateTime.now().millisecondsSinceEpoch},
          where: 'id = ?',
          whereArgs: [id],
        );
      });

      if (result == 0) {
        throw Exception('Hasta bulunamadı');
      }

      if (kDebugMode) {
        debugPrint('Patient restored: $id');
      }
    } catch (e) {
      debugPrint('Error restoring patient: $e');
      throw Exception('Hasta geri yüklenemedi: $e');
    }
  }

  Future<int> getTotalPatients() async {
    final db = await database;
    try {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM patients WHERE isActive = 1',
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      debugPrint('Error getting total patients: $e');
      return 0;
    }
  }

  Future<Map<String, int>> getStatistics() async {
    final db = await database;
    try {
      // Tüm istatistikleri tek sorguda al - daha performanslı
      final result = await db.rawQuery('''
        SELECT 
          COUNT(*) as total,
          SUM(CASE WHEN gender = "Erkek" THEN 1 ELSE 0 END) as male,
          SUM(CASE WHEN gender = "Kadın" THEN 1 ELSE 0 END) as female,
          SUM(CASE WHEN date(createdAt/1000, "unixepoch") = date("now") THEN 1 ELSE 0 END) as todayAdded,
          SUM(CASE WHEN hasChronicDisease = 1 THEN 1 ELSE 0 END) as chronic
        FROM patients 
        WHERE isActive = 1
      ''');

      if (result.isNotEmpty) {
        final row = result.first;
        return {
          'total': (row['total'] as int?) ?? 0,
          'male': (row['male'] as int?) ?? 0,
          'female': (row['female'] as int?) ?? 0,
          'todayAdded': (row['todayAdded'] as int?) ?? 0,
          'chronic': (row['chronic'] as int?) ?? 0,
        };
      }
    } catch (e) {
      debugPrint('Error getting statistics: $e');
    }

    return {'total': 0, 'male': 0, 'female': 0, 'todayAdded': 0, 'chronic': 0};
  }

  // Veritabanı metadata'sını getir
  Future<Map<String, String>> getMetadata() async {
    final db = await database;
    try {
      final result = await db.query('db_metadata');
      final metadata = <String, String>{};
      for (final row in result) {
        metadata[row['key'] as String] = row['value'] as String;
      }
      return metadata;
    } catch (e) {
      debugPrint('Error getting metadata: $e');
      return {};
    }
  }

  // Metadata güncelle
  Future<void> updateMetadata(String key, String value) async {
    final db = await database;
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.insert('db_metadata', {
        'key': key,
        'value': value,
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint('Error updating metadata: $e');
    }
  }

  // Veritabanının var olup olmadığını kontrol et
  Future<bool> isDatabaseExists() async {
    try {
      String path = join(
        await getDatabasesPath(),
        'patient_manager_persistent.db',
      );
      return await databaseExists(path);
    } catch (e) {
      debugPrint('Error checking database existence: $e');
      return false;
    }
  }

  // Veritabanı boyutunu al
  Future<int> getDatabaseSize() async {
    try {
      String path = join(
        await getDatabasesPath(),
        'patient_manager_persistent.db',
      );
      final file = File(path);
      if (await file.exists()) {
        final stat = await file.stat();
        return stat.size;
      }
      return 0;
    } catch (e) {
      debugPrint('Error getting database size: $e');
      return 0;
    }
  }

  // Veritabanı yolu
  Future<String> getDatabasePath() async {
    try {
      return join(await getDatabasesPath(), 'patient_manager_persistent.db');
    } catch (e) {
      debugPrint('Error getting database path: $e');
      return '';
    }
  }

  // Veritabanı sağlık kontrolü - geliştirilmiş
  Future<Map<String, dynamic>> checkDatabaseHealth() async {
    try {
      final db = await database;
      final health = <String, dynamic>{};

      // Temel sorgu testi
      await db.rawQuery('SELECT COUNT(*) FROM patients LIMIT 1');
      health['basic_query'] = true;

      // Tablo yapısını kontrol et
      final tableInfo = await db.rawQuery("PRAGMA table_info(patients)");
      health['table_exists'] = tableInfo.isNotEmpty;
      health['column_count'] = tableInfo.length;

      // WAL mode kontrolü
      final walMode = await db.rawQuery("PRAGMA journal_mode");
      health['wal_mode'] = walMode.first.values.first;

      // Index kontrolü
      final indexes = await db.rawQuery("PRAGMA index_list(patients)");
      health['index_count'] = indexes.length;

      // Kayıt sayısı
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM patients',
      );
      health['total_records'] = Sqflite.firstIntValue(countResult) ?? 0;

      // Veritabanı boyutu
      health['database_size'] = await getDatabaseSize();

      // Son güncelleme
      final lastUpdate = await db.rawQuery(
        'SELECT MAX(updatedAt) as last_update FROM patients WHERE isActive = 1',
      );
      health['last_update'] = lastUpdate.first['last_update'];

      health['status'] = 'healthy';

      if (kDebugMode) {
        debugPrint('Database health check: ${health.toString()}');
      }

      return health;
    } catch (e) {
      debugPrint('Database health check failed: $e');
      return {'status': 'unhealthy', 'error': e.toString()};
    }
  }

  // Veritabanı güvenli şekilde kapat
  Future<void> closeDatabase() async {
    try {
      if (_database != null) {
        await _database!.close();
        _database = null;
        if (kDebugMode) {
          debugPrint('Database closed successfully');
        }
      }
    } catch (e) {
      debugPrint('Error closing database: $e');
    }
  }

  // Veritabanı bakım işlemleri
  Future<void> performMaintenance() async {
    try {
      final db = await database;

      // WAL checkpoint
      await db.execute('PRAGMA wal_checkpoint(TRUNCATE)');

      // Incremental vacuum
      await db.execute('PRAGMA incremental_vacuum');

      // Analyze - query planner için
      await db.execute('ANALYZE');

      // Son bakım tarihini güncelle
      await updateMetadata(
        'last_maintenance',
        DateTime.now().millisecondsSinceEpoch.toString(),
      );

      if (kDebugMode) {
        debugPrint('Database maintenance completed');
      }
    } catch (e) {
      debugPrint('Error during maintenance: $e');
    }
  }

  // SADECE DEVELOPMENT İÇİN - Production'da kullanmayın!
  Future<void> resetDatabaseForDevelopment() async {
    if (kDebugMode) {
      try {
        String path = join(
          await getDatabasesPath(),
          'patient_manager_persistent.db',
        );
        await closeDatabase();
        if (await databaseExists(path)) {
          await deleteDatabase(path);
          debugPrint('⚠️ Database reset for development');
        }
      } catch (e) {
        debugPrint('Error resetting database: $e');
      }
    } else {
      debugPrint('⚠️ Database reset is only allowed in debug mode');
    }
  }

  // Yedekleme için tüm verileri export et
  Future<List<Map<String, dynamic>>> exportAllData() async {
    final db = await database;
    try {
      final patients = await db.query('patients');
      final metadata = await db.query('db_metadata');

      return [
        {'table': 'patients', 'data': patients},
        {'table': 'db_metadata', 'data': metadata},
      ];
    } catch (e) {
      debugPrint('Error exporting data: $e');
      throw Exception('Veri export edilemedi: $e');
    }
  }
}

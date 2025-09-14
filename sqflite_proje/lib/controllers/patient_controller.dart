import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/patient.dart';
import '../services/database_helper.dart';

class PatientController extends GetxController {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Observable lists
  final RxList<Patient> patients = <Patient>[].obs;
  final RxList<Patient> filteredPatients = <Patient>[].obs;
  final RxList<Patient> deletedPatients = <Patient>[].obs;

  // Loading states
  final RxBool isLoading = false.obs;
  final RxBool isSearching = false.obs;
  final RxBool isFiltering = false.obs;

  // Search and filter
  final RxString searchQuery = ''.obs;
  final RxString selectedDiagnosis = ''.obs;
  final RxString selectedBloodType = ''.obs;
  final RxString selectedGender = ''.obs;
  final RxInt minAge = 0.obs;
  final RxInt maxAge = 100.obs;

  // Statistics
  final RxMap<String, int> statistics = <String, int>{}.obs;

  // Constants
  final List<String> bloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  final List<String> genderOptions = ['Erkek', 'Kadın', 'Diğer'];

  @override
  void onInit() {
    super.onInit();
    loadPatients();
    loadStatistics();

    // Arama ve filtreler değiştikçe listeyi güncelle
    ever(searchQuery, (_) => applySearchAndFilter());
    ever(selectedDiagnosis, (_) => applySearchAndFilter());
    ever(selectedBloodType, (_) => applySearchAndFilter());
    ever(selectedGender, (_) => applySearchAndFilter());
    ever(minAge, (_) => applySearchAndFilter());
    ever(maxAge, (_) => applySearchAndFilter());
  }

  Future<void> loadPatients() async {
    try {
      isLoading.value = true;
      debugPrint('Loading patients...'); // DEBUG

      final patientList = await _dbHelper.getAllPatients();
      patients.assignAll(patientList);
      applySearchAndFilter();

      debugPrint('Loaded ${patientList.length} patients'); // DEBUG
    } catch (e) {
      debugPrint('Load patients error: $e'); // DEBUG
      Get.snackbar(
        'Hata',
        'Hastalar yüklenemedi: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadDeletedPatients() async {
    try {
      isLoading.value = true;
      final allPatients = await _dbHelper.getAllPatients(activeOnly: false);
      deletedPatients.assignAll(
        allPatients.where((patient) => !patient.isActive).toList(),
      );
    } catch (e) {
      Get.snackbar(
        'Hata',
        'Silinmiş hastalar yüklenemedi: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadStatistics() async {
    try {
      final stats = await _dbHelper.getStatistics();
      statistics.assignAll(stats);
      debugPrint('Statistics loaded: $stats'); // DEBUG
    } catch (e) {
      debugPrint('İstatistikler yüklenemedi: $e');
    }
  }

  // DÜZELTİLMİŞ addPatient metodu
  Future<String?> addPatient(Patient patient) async {
    try {
      isLoading.value = true;
      debugPrint('Controller: addPatient başladı'); // DEBUG

      // TC Kimlik kontrolü - veritabanında aynı TC var mı?
      final existingPatients = patients
          .where((p) => p.tcNumber == patient.tcNumber && p.isActive)
          .toList();

      if (existingPatients.isNotEmpty) {
        throw Exception('Bu TC Kimlik numarası ile kayıtlı hasta zaten var');
      }

      // Yeni hasta objesi oluştur - UUID ile
      final newPatient = Patient(
        id: const Uuid().v4(), // UUID ile benzersiz ID
        firstName: patient.firstName,
        lastName: patient.lastName,
        tcNumber: patient.tcNumber,
        age: patient.age,
        gender: patient.gender,
        phone: patient.phone,
        email: patient.email,
        address: patient.address,
        diagnosis: patient.diagnosis,
        bloodType: patient.bloodType,
        height: patient.height,
        weight: patient.weight,
        emergencyContact: patient.emergencyContact,
        emergencyPhone: patient.emergencyPhone,
        allergies: patient.allergies,
        medications: patient.medications,
        notes: patient.notes,
        imagePath: patient.imagePath,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        doctorName: patient.doctorName,
        insuranceNumber: patient.insuranceNumber,
        hasChronicDisease: patient.hasChronicDisease,
        isActive: true, // Aktif olarak ayarla
      );

      debugPrint('Controller: UUID oluşturuldu: ${newPatient.id}'); // DEBUG

      // Veritabanına kaydet
      final id = await _dbHelper.insertPatient(newPatient);
      debugPrint('Controller: Database insert sonucu: $id'); // DEBUG

      if (id == newPatient.id) {
        // Başarıyla kaydedildi, listeye ekle
        patients.insert(0, newPatient);
        applySearchAndFilter();

        // İstatistikleri güncelle
        await loadStatistics();

        debugPrint(
          'Controller: Hasta başarıyla eklendi ve listeler güncellendi',
        ); // DEBUG

        // Bu SnackBar'ı kaldırıyoruz çünkü UI tarafında gösteriliyor
        // Get.snackbar(
        //   'Başarılı',
        //   'Hasta başarıyla eklendi',
        //   snackPosition: SnackPosition.BOTTOM,
        //   backgroundColor: Colors.green,
        //   colorText: Colors.white,
        // );

        return id;
      } else {
        throw Exception('Veritabanına kayıt sırasında ID uyumsuzluğu');
      }
    } catch (e) {
      debugPrint('Controller: addPatient error: $e'); // DEBUG

      // Hata mesajını UI tarafı göstereceği için burada göstermeyelim
      // Get.snackbar(
      //   'Hata',
      //   'Hasta eklenemedi: ${e.toString()}',
      //   snackPosition: SnackPosition.BOTTOM,
      //   backgroundColor: Colors.red,
      //   colorText: Colors.white,
      // );

      // Hatayı tekrar fırlat ki UI tarafında yakalanabilsin
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updatePatient(Patient updatedPatient) async {
    try {
      isLoading.value = true;

      final patient = updatedPatient.copyWith(updatedAt: DateTime.now());
      await _dbHelper.updatePatient(patient);

      final index = patients.indexWhere((p) => p.id == patient.id);
      if (index != -1) {
        patients[index] = patient;
        patients.refresh();
      }

      final filteredIndex = filteredPatients.indexWhere(
        (p) => p.id == patient.id,
      );
      if (filteredIndex != -1) {
        filteredPatients[filteredIndex] = patient;
        filteredPatients.refresh();
      }

      await loadStatistics();

      Get.snackbar(
        'Başarılı',
        'Hasta bilgileri güncellendi',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Hata',
        'Hasta güncellenemedi: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deletePatient(String id) async {
    try {
      await _dbHelper.deletePatient(id);
      patients.removeWhere((patient) => patient.id == id);
      filteredPatients.removeWhere((patient) => patient.id == id);

      await loadStatistics();

      Get.snackbar(
        'Başarılı',
        'Hasta silindi',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        mainButton: TextButton(
          onPressed: () => restorePatient(id),
          child: const Text('Geri Al', style: TextStyle(color: Colors.white)),
        ),
      );
    } catch (e) {
      Get.snackbar(
        'Hata',
        'Hasta silinemedi: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> restorePatient(String id) async {
    try {
      await _dbHelper.restorePatient(id);
      await loadPatients();
      await loadStatistics();

      Get.snackbar(
        'Başarılı',
        'Hasta geri yüklendi',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Hata',
        'Hasta geri yüklenemedi: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> permanentDeletePatient(String id) async {
    try {
      await _dbHelper.permanentDeletePatient(id);
      deletedPatients.removeWhere((patient) => patient.id == id);
      deletedPatients.refresh();

      Get.snackbar(
        'Başarılı',
        'Hasta kalıcı olarak silindi',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Hata',
        'Hasta kalıcı olarak silinemedi: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Arama ve filtreleme kriterlerine göre listeyi günceller
  void applySearchAndFilter() {
    List<Patient> tempList = patients.toList();

    // Arama
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      tempList = tempList.where((p) {
        final fullName = p.fullName.toLowerCase();
        final tcNumber = p.tcNumber.toLowerCase();
        final phone = p.phone.toLowerCase();
        return fullName.contains(query) ||
            tcNumber.contains(query) ||
            phone.contains(query);
      }).toList();
    }

    // Filtreleme
    if (selectedDiagnosis.value.isNotEmpty) {
      tempList = tempList
          .where((p) => p.diagnosis == selectedDiagnosis.value)
          .toList();
    }
    if (selectedBloodType.value.isNotEmpty) {
      tempList = tempList
          .where((p) => p.bloodType == selectedBloodType.value)
          .toList();
    }
    if (selectedGender.value.isNotEmpty) {
      tempList = tempList
          .where((p) => p.gender == selectedGender.value)
          .toList();
    }
    if (minAge.value > 0) {
      tempList = tempList.where((p) => p.age >= minAge.value).toList();
    }
    if (maxAge.value < 100) {
      tempList = tempList.where((p) => p.age <= maxAge.value).toList();
    }

    filteredPatients.assignAll(tempList);
  }

  void clearFilters() {
    selectedDiagnosis.value = '';
    selectedBloodType.value = '';
    selectedGender.value = '';
    minAge.value = 0;
    maxAge.value = 100;
    searchQuery.value = '';
    applySearchAndFilter();
  }

  Patient? getPatientById(String id) {
    try {
      return patients.firstWhere((patient) => patient.id == id);
    } catch (e) {
      return null;
    }
  }

  List<String> getDiagnosesList() {
    final diagnoses = patients
        .where((patient) => patient.diagnosis.isNotEmpty)
        .map((patient) => patient.diagnosis)
        .toSet()
        .toList();
    diagnoses.sort();
    return diagnoses;
  }

  List<Patient> getPatientsWithUpcomingBirthdays() {
    // TODO: Doğum tarihi alanı olmalı, aşağıdaki placeholder'ı gerçek tarihle değiştir
    return patients.where((patient) {
      // Örnek kontrol: yaş > 0 ise al
      return patient.age > 0;
    }).toList();
  }

  Map<String, int> getAgeDistribution() {
    final distribution = <String, int>{
      '0-18': 0,
      '19-30': 0,
      '31-50': 0,
      '51-70': 0,
      '70+': 0,
    };

    for (final patient in patients) {
      if (patient.age <= 18) {
        distribution['0-18'] = (distribution['0-18'] ?? 0) + 1;
      } else if (patient.age <= 30) {
        distribution['19-30'] = (distribution['19-30'] ?? 0) + 1;
      } else if (patient.age <= 50) {
        distribution['31-50'] = (distribution['31-50'] ?? 0) + 1;
      } else if (patient.age <= 70) {
        distribution['51-70'] = (distribution['51-70'] ?? 0) + 1;
      } else {
        distribution['70+'] = (distribution['70+'] ?? 0) + 1;
      }
    }

    return distribution;
  }

  void refreshData() {
    loadPatients();
    loadStatistics();
  }

  // Veritabanı sağlık kontrolü
  Future<Map<String, dynamic>> checkDatabaseHealth() async {
    try {
      return await _dbHelper.checkDatabaseHealth();
    } catch (e) {
      debugPrint('Database health check error: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  @override
  void onClose() {
    // Cleanup if needed
    super.onClose();
  }
}

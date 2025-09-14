import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/doctor.dart';
import '../services/auth_database_helper.dart';

class AuthController extends GetxController {
  final AuthDatabaseHelper _authDbHelper = AuthDatabaseHelper();

  final RxBool isLoading = false.obs;
  final RxBool isLoggedIn = false.obs;
  final Rx<Doctor?> currentDoctor = Rx<Doctor?>(null);
  final RxBool rememberMe = false.obs;

  // Session yönetimi için
  static const String _sessionKey = 'logged_doctor_id';
  static const String _rememberMeKey = 'remember_me';
  static const String _lastLoginKey = 'last_login';

  @override
  void onInit() {
    super.onInit();
    _initializeAuth();
  }

  /// Authentication durumunu kontrol et ve gerekiyorsa restore et
  Future<void> _initializeAuth() async {
    try {
      isLoading.value = true;
      await checkAuthStatus();
    } catch (e) {
      debugPrint('Auth initialization error: $e');
      await _clearSession();
    } finally {
      isLoading.value = false;
    }
  }

  /// Oturum durumunu kontrol et
  Future<void> checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final doctorId = prefs.getString(_sessionKey);
      final rememberMeStatus = prefs.getBool(_rememberMeKey) ?? false;
      final lastLogin = prefs.getInt(_lastLoginKey);

      if (doctorId == null) {
        await _clearSession();
        return;
      }

      // Remember me kontrolü
      if (!rememberMeStatus && lastLogin != null) {
        final lastLoginDate = DateTime.fromMillisecondsSinceEpoch(lastLogin);
        final now = DateTime.now();
        // 24 saat sonra otomatik çıkış yap (remember me seçilmemişse)
        if (now.difference(lastLoginDate).inHours > 24) {
          await _clearSession();
          _showMessage('Oturum süresi dolmuş',
              'Güvenlik nedeniyle çıkış yapıldı', Colors.orange);
          return;
        }
      }

      // Doktor bilgilerini getir
      final doctor = await _authDbHelper.getDoctorById(doctorId);
      if (doctor != null && doctor.isActive) {
        currentDoctor.value = doctor;
        isLoggedIn.value = true;
        rememberMe.value = rememberMeStatus;

        // Son giriş tarihini güncelle
        await prefs.setInt(
            _lastLoginKey, DateTime.now().millisecondsSinceEpoch);
      } else {
        await _clearSession();
        if (doctor != null && !doctor.isActive) {
          _showMessage('Hesap Devre Dışı', 'Hesabınız devre dışı bırakılmış',
              Colors.red);
        }
      }
    } catch (e) {
      debugPrint('Auth check error: $e');
      await _clearSession();
    }
  }

  /// Şifre hash'leme
  String _hashPassword(String password) {
    final bytes = utf8.encode(password + 'doctor_salt_2024'); // Salt eklendi
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// ESNEK ŞİFRE KONTROLÜ - Sadece minimum uzunluk kontrolü
  bool _isPasswordValid(String password) {
    // Sadece minimum 6 karakter kontrolü
    return password.length >= 6;
  }

  /// Şifre güçlülük skoru (opsiyonel bilgi için)
  String _getPasswordStrengthMessage(String password) {
    if (password.length < 6) {
      return 'Şifre en az 6 karakter olmalıdır';
    }

    int score = 0;
    String suggestions = '';

    if (password.length >= 8)
      score++;
    else
      suggestions += '• En az 8 karakter kullanın\n';

    if (password.contains(RegExp(r'[A-Z]')))
      score++;
    else
      suggestions += '• Büyük harf ekleyin\n';

    if (password.contains(RegExp(r'[a-z]')))
      score++;
    else
      suggestions += '• Küçük harf ekleyin\n';

    if (password.contains(RegExp(r'[0-9]')))
      score++;
    else
      suggestions += '• Rakam ekleyin\n';

    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')))
      score++;
    else
      suggestions += '• Özel karakter ekleyin\n';

    if (score <= 1) return 'Zayıf şifre. $suggestions';
    if (score <= 3) return 'Orta güçlükte şifre. $suggestions';
    if (score <= 4) return 'İyi şifre. $suggestions';
    return 'Güçlü şifre!';
  }

  /// Email format kontrolü
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Kayıt işlemi - DÜZELTME: Hata yakalama ve loading durumu iyileştirildi
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String specialization,
    required String licenseNumber,
    required String phone,
  }) async {
    try {
      isLoading.value = true;
      debugPrint('Register işlemi başladı'); // DEBUG

      // Input validasyonları
      if (firstName.trim().isEmpty || lastName.trim().isEmpty) {
        _showMessage('Hata', 'Ad ve soyad alanları boş olamaz', Colors.red);
        return false;
      }

      if (!_isValidEmail(email.trim())) {
        _showMessage('Hata', 'Geçerli bir email adresi girin', Colors.red);
        return false;
      }

      // ESNEK ŞİFRE KONTROLÜ
      if (!_isPasswordValid(password)) {
        _showMessage('Hata', 'Şifre en az 6 karakter olmalıdır', Colors.red);
        return false;
      }

      // Şifre gücü hakkında bilgi ver (zorunlu değil)
      final strengthMessage = _getPasswordStrengthMessage(password);
      if (!strengthMessage.contains('Güçlü')) {
        debugPrint('Şifre gücü: $strengthMessage');
        // İsteğe bağlı: Kullanıcıya bilgi verilebilir ama engellenmez
        _showMessage('Bilgi', 'Şifre gücü: ${strengthMessage.split('.')[0]}',
            Colors.orange,
            duration: 2);
      }

      if (licenseNumber.trim().isEmpty) {
        _showMessage('Hata', 'Lisans numarası boş olamaz', Colors.red);
        return false;
      }

      if (phone.trim().isEmpty) {
        _showMessage('Hata', 'Telefon numarası boş olamaz', Colors.red);
        return false;
      }

      debugPrint(
          'Validasyonlar tamamlandı, database kontrolü başlıyor'); // DEBUG

      // Email kontrolü
      try {
        final emailExists =
            await _authDbHelper.isEmailExists(email.trim().toLowerCase());
        if (emailExists) {
          _showMessage(
              'Hata', 'Bu email adresi zaten kullanılıyor', Colors.red);
          return false;
        }
        debugPrint('Email kontrolü tamamlandı'); // DEBUG
      } catch (e) {
        debugPrint('Email kontrolü hatası: $e');
        _showMessage('Hata', 'Email kontrolü yapılamadı', Colors.red);
        return false;
      }

      // Lisans numarası kontrolü
      try {
        final licenseExists =
            await _authDbHelper.isLicenseExists(licenseNumber.trim());
        if (licenseExists) {
          _showMessage(
              'Hata', 'Bu lisans numarası zaten kullanılıyor', Colors.red);
          return false;
        }
        debugPrint('Lisans kontrolü tamamlandı'); // DEBUG
      } catch (e) {
        debugPrint('Lisans kontrolü hatası: $e');
        _showMessage('Hata', 'Lisans kontrolü yapılamadı', Colors.red);
        return false;
      }

      debugPrint('Doktor nesnesi oluşturuluyor'); // DEBUG

      final newDoctor = Doctor(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: email.trim().toLowerCase(),
        password: _hashPassword(password),
        specialization: specialization.trim(),
        licenseNumber: licenseNumber.trim(),
        phone: phone.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      debugPrint('Database insert işlemi başlıyor'); // DEBUG

      try {
        await _authDbHelper.insertDoctor(newDoctor);
        debugPrint('Database insert başarılı'); // DEBUG

        _showMessage(
          'Başarılı',
          'Hesabınız başarıyla oluşturuldu. Giriş yapabilirsiniz.',
          Colors.green,
        );

        return true;
      } catch (e) {
        debugPrint('Database insert hatası: $e');
        _showMessage('Hata', 'Kayıt işlemi sırasında veritabanı hatası oluştu',
            Colors.red);
        return false;
      }
    } catch (e) {
      debugPrint('Registration error: $e');
      _showMessage(
          'Hata', 'Kayıt işlemi başarısız: ${e.toString()}', Colors.red);
      return false;
    } finally {
      isLoading.value = false;
      debugPrint('Register işlemi tamamlandı, loading false'); // DEBUG
    }
  }

  /// Giriş işlemi - DÜZELTME: Hata yakalama ve loading durumu iyileştirildi
  Future<bool> login(String email, String password,
      {bool remember = false}) async {
    try {
      isLoading.value = true;
      debugPrint('Login işlemi başladı'); // DEBUG

      if (email.trim().isEmpty || password.isEmpty) {
        _showMessage('Hata', 'Email ve şifre alanları boş olamaz', Colors.red);
        return false;
      }

      if (!_isValidEmail(email.trim())) {
        _showMessage('Hata', 'Geçerli bir email adresi girin', Colors.red);
        return false;
      }

      debugPrint('Şifre hash\'leniyor'); // DEBUG
      final hashedPassword = _hashPassword(password);

      debugPrint('Database authentication başlıyor'); // DEBUG

      try {
        final doctor = await _authDbHelper.authenticateDoctor(
          email.trim().toLowerCase(),
          hashedPassword,
        );

        debugPrint(
            'Database authentication tamamlandı: ${doctor != null}'); // DEBUG

        if (doctor != null) {
          debugPrint('Session bilgileri kaydediliyor'); // DEBUG

          // Session bilgilerini kaydet
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_sessionKey, doctor.id);
          await prefs.setBool(_rememberMeKey, remember);
          await prefs.setInt(
              _lastLoginKey, DateTime.now().millisecondsSinceEpoch);

          currentDoctor.value = doctor;
          isLoggedIn.value = true;
          rememberMe.value = remember;

          debugPrint('Session bilgileri kaydedildi, giriş başarılı'); // DEBUG

          _showMessage(
            'Hoş Geldiniz',
            'Hoş geldiniz, Dr. ${doctor.fullName}',
            Colors.green,
          );

          return true;
        } else {
          _showMessage('Hata', 'Email veya şifre hatalı', Colors.red);
          return false;
        }
      } catch (e) {
        debugPrint('Database authentication hatası: $e');
        _showMessage('Hata', 'Giriş işlemi sırasında veritabanı hatası oluştu',
            Colors.red);
        return false;
      }
    } catch (e) {
      debugPrint('Login error: $e');
      _showMessage(
          'Hata', 'Giriş işlemi başarısız: ${e.toString()}', Colors.red);
      return false;
    } finally {
      isLoading.value = false;
      debugPrint('Login işlemi tamamlandı, loading false'); // DEBUG
    }
  }

  /// Çıkış işlemi
  Future<void> logout({bool showMessage = true}) async {
    try {
      await _clearSession();

      if (showMessage) {
        _showMessage('Başarılı', 'Çıkış yapıldı', Colors.orange);
      }
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  /// Session temizleme
  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
      await prefs.remove(_rememberMeKey);
      await prefs.remove(_lastLoginKey);

      currentDoctor.value = null;
      isLoggedIn.value = false;
      rememberMe.value = false;
    } catch (e) {
      debugPrint('Clear session error: $e');
    }
  }

  /// Profil güncelleme
  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    required String specialization,
    required String phone,
    String? imagePath,
  }) async {
    try {
      if (currentDoctor.value == null) {
        _showMessage('Hata', 'Oturum bulunamadı', Colors.red);
        return false;
      }

      isLoading.value = true;

      // Input validasyonları
      if (firstName.trim().isEmpty || lastName.trim().isEmpty) {
        _showMessage('Hata', 'Ad ve soyad alanları boş olamaz', Colors.red);
        return false;
      }

      if (specialization.trim().isEmpty) {
        _showMessage('Hata', 'Uzmanlık alanı boş olamaz', Colors.red);
        return false;
      }

      if (phone.trim().isEmpty) {
        _showMessage('Hata', 'Telefon numarası boş olamaz', Colors.red);
        return false;
      }

      final updatedDoctor = currentDoctor.value!.copyWith(
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        specialization: specialization.trim(),
        phone: phone.trim(),
        imagePath: imagePath,
        updatedAt: DateTime.now(),
      );

      await _authDbHelper.updateDoctor(updatedDoctor);
      currentDoctor.value = updatedDoctor;

      _showMessage('Başarılı', 'Profil bilgileriniz güncellendi', Colors.green);
      return true;
    } catch (e) {
      debugPrint('Update profile error: $e');
      _showMessage(
          'Hata', 'Profil güncellenemedi: ${e.toString()}', Colors.red);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Şifre değiştirme - ESNEK KONTROL
  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    try {
      if (currentDoctor.value == null) {
        _showMessage('Hata', 'Oturum bulunamadı', Colors.red);
        return false;
      }

      isLoading.value = true;

      if (currentPassword.isEmpty || newPassword.isEmpty) {
        _showMessage('Hata', 'Şifre alanları boş olamaz', Colors.red);
        return false;
      }

      // ESNEK ŞİFRE KONTROLÜ
      if (!_isPasswordValid(newPassword)) {
        _showMessage(
            'Hata', 'Yeni şifre en az 6 karakter olmalıdır', Colors.red);
        return false;
      }

      if (currentPassword == newPassword) {
        _showMessage(
            'Hata', 'Yeni şifre mevcut şifre ile aynı olamaz', Colors.red);
        return false;
      }

      final hashedCurrentPassword = _hashPassword(currentPassword);
      if (currentDoctor.value!.password != hashedCurrentPassword) {
        _showMessage('Hata', 'Mevcut şifre yanlış', Colors.red);
        return false;
      }

      final updatedDoctor = currentDoctor.value!.copyWith(
        password: _hashPassword(newPassword),
        updatedAt: DateTime.now(),
      );

      await _authDbHelper.updateDoctor(updatedDoctor);
      currentDoctor.value = updatedDoctor;

      _showMessage('Başarılı', 'Şifreniz başarıyla değiştirildi', Colors.green);
      return true;
    } catch (e) {
      debugPrint('Change password error: $e');
      _showMessage(
          'Hata', 'Şifre değiştirilemedi: ${e.toString()}', Colors.red);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Hesap silme (soft delete)
  Future<bool> deleteAccount(String password) async {
    try {
      if (currentDoctor.value == null) return false;

      isLoading.value = true;

      final hashedPassword = _hashPassword(password);
      if (currentDoctor.value!.password != hashedPassword) {
        _showMessage('Hata', 'Şifre yanlış', Colors.red);
        return false;
      }

      await _authDbHelper.deleteDoctor(currentDoctor.value!.id);
      await _clearSession();

      _showMessage('Başarılı', 'Hesabınız silindi', Colors.orange);
      return true;
    } catch (e) {
      debugPrint('Delete account error: $e');
      _showMessage('Hata', 'Hesap silinemedi: ${e.toString()}', Colors.red);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Mevcut doktor bilgilerini yenile
  Future<void> refreshCurrentDoctor() async {
    try {
      if (currentDoctor.value == null) return;

      final doctor = await _authDbHelper.getDoctorById(currentDoctor.value!.id);
      if (doctor != null && doctor.isActive) {
        currentDoctor.value = doctor;
      } else {
        await logout();
      }
    } catch (e) {
      debugPrint('Refresh doctor error: $e');
    }
  }

  /// Mesaj gösterme helper - duration parametresi eklendi
  void _showMessage(String title, String message, Color backgroundColor,
      {int duration = 3}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: backgroundColor,
      colorText: Colors.white,
      duration: Duration(seconds: duration),
      margin: const EdgeInsets.all(10),
      borderRadius: 8,
    );
  }

  /// Getter'lar
  bool get isAuthenticated => isLoggedIn.value && currentDoctor.value != null;
  Doctor? get doctor => currentDoctor.value;
  String get doctorFullName => currentDoctor.value?.fullName ?? '';
  String get doctorSpecialization => currentDoctor.value?.specialization ?? '';

  @override
  void onClose() {
    super.onClose();
  }
}

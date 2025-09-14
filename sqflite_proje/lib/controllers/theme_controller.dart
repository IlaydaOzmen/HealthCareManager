import 'package:get/get.dart';
import 'package:flutter/material.dart';

class ThemeController extends GetxController {
  var isDark = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initTheme();
  }

  void _initTheme() {
    // Sistem temasını al
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    isDark.value = brightness == Brightness.dark;

    // Temayı uygula
    Get.changeThemeMode(isDark.value ? ThemeMode.dark : ThemeMode.light);
  }

  void toggleTheme() {
    isDark.value = !isDark.value;
    Get.changeThemeMode(isDark.value ? ThemeMode.dark : ThemeMode.light);

    // Kullanıcıya bilgi ver
    Get.snackbar(
      'Tema Değişti',
      isDark.value
          ? 'Karanlık mod etkinleştirildi'
          : 'Aydınlık mod etkinleştirildi',
      backgroundColor: isDark.value ? Colors.grey[800] : Colors.blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }

  void setTheme(bool isDarkMode) {
    isDark.value = isDarkMode;
    Get.changeThemeMode(isDarkMode ? ThemeMode.dark : ThemeMode.light);
  }
}

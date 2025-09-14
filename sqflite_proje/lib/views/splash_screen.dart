import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import 'login_page.dart';
// import 'dashboard_page.dart'; // Ana sayfa import'unu ekleyin

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    try {
      // Splash screen minimum gösterim süresi
      await Future.delayed(const Duration(seconds: 2));

      // AuthController'ın hazır olup olmadığını kontrol et
      final authController = Get.find<AuthController>();

      // Auth durumunu kontrol et
      await authController.checkAuthStatus();

      // Navigator'ı kontrol et
      if (!mounted) return;

      // Auth durumuna göre yönlendirme
      if (authController.isAuthenticated) {
        // Kullanıcı giriş yapmış - ana sayfaya yönlendir
        // Get.offAll(() => const DashboardPage());

        // Ana sayfanız hazır olduğunda yukarıdaki satırı uncomment edin
        // ve aşağıdaki satırı silin:
        Get.offAll(() => const LoginPage());
      } else {
        // Kullanıcı giriş yapmamış - login sayfasına yönlendir
        Get.offAll(() => const LoginPage());
      }
    } catch (e) {
      debugPrint('Splash navigation error: $e');
      // Hata durumunda login sayfasına yönlendir
      Get.offAll(() => const LoginPage());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1A1A1A),
                    const Color(0xFF2C2C2C),
                    const Color(0xFF1976D2).withOpacity(0.3),
                  ]
                : [
                    const Color(0xFF2196F3),
                    const Color(0xFF1976D2),
                    const Color(0xFF0D47A1),
                  ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(isDark ? 0.1 : 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_hospital,
                size: 80,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 30),

            // App Title
            Text(
              'Hasta Yönetim Sistemi',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Doktor Paneli',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 50),

            // Loading Indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),

            const SizedBox(height: 20),

            Text(
              'Yükleniyor...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

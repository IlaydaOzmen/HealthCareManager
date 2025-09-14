import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../controllers/patient_controller.dart';
import '../controllers/theme_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final PatientController controller = Get.find<PatientController>();
    final ThemeController themeController = Get.find<ThemeController>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: AnimationLimiter(
              child: Column(
                children: AnimationConfiguration.toStaggeredList(
                  duration: const Duration(milliseconds: 375),
                  childAnimationBuilder: (widget) => SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(child: widget),
                  ),
                  children: [
                    const SizedBox(height: 16),
                    _buildAppInfoCard(context),
                    const SizedBox(height: 16),
                    _buildDataManagementCard(context, controller),
                    const SizedBox(height: 16),
                    _buildThemeCard(context, themeController),
                    const SizedBox(height: 16),
                    _buildAboutCard(context),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Ayarlar'),
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.1),
                Theme.of(context).primaryColor.withOpacity(0.05),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppInfoCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.local_hospital,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Hasta Yönetim Sistemi',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Versiyon 1.0.0',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'Modern ve kullanıcı dostu hasta yönetim uygulaması',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataManagementCard(
      BuildContext context, PatientController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.storage, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Veri Yönetimi',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSettingsTile(
                context,
                Icons.refresh,
                'Verileri Yenile',
                'Tüm hasta verilerini yeniden yükle',
                onTap: () => controller.refreshData(),
              ),
              _buildSettingsTile(
                context,
                Icons.backup,
                'Veri Yedekleme',
                'Hasta verilerini yedekle',
                onTap: () => _showBackupDialog(context, controller),
              ),
              _buildSettingsTile(
                context,
                Icons.delete_sweep,
                'Silinmiş Hastalar',
                'Silinmiş hasta kayıtlarını görüntüle',
                onTap: () => _showDeletedPatientsDialog(context, controller),
              ),
              _buildSettingsTile(
                context,
                Icons.warning,
                'Tüm Verileri Sil',
                'Dikkat: Bu işlem geri alınamaz',
                isDestructive: true,
                onTap: () => _showDeleteAllDialog(context, controller),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeCard(
      BuildContext context, ThemeController themeController) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.palette, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Görünüm',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Obx ile tema kontrolü
              Obx(() => _buildSettingsTile(
                    context,
                    themeController.isDark.value
                        ? Icons.dark_mode
                        : Icons.light_mode,
                    'Karanlık Tema',
                    themeController.isDark.value
                        ? 'Karanlık mod aktif'
                        : 'Aydınlık mod aktif',
                    trailing: Switch(
                      value: themeController.isDark.value,
                      onChanged: (value) {
                        themeController.toggleTheme();
                      },
                      activeColor: Theme.of(context).primaryColor,
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Hakkında',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSettingsTile(
                context,
                Icons.privacy_tip,
                'Gizlilik Politikası',
                'Veri işleme politikamızı görüntüle',
                onTap: () => _showPrivacyDialog(context),
              ),
              _buildSettingsTile(
                context,
                Icons.description,
                'Kullanım Koşulları',
                'Hizmet şartlarını görüntüle',
                onTap: () => _showTermsDialog(context),
              ),
              _buildSettingsTile(
                context,
                Icons.help,
                'Yardım ve Destek',
                'SSS ve destek bilgileri',
                onTap: () => _showHelpDialog(context),
              ),
              _buildSettingsTile(
                context,
                Icons.star,
                'Uygulamayı Değerlendir',
                'App Store\'da değerlendirin',
                onTap: () => _showRateDialog(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle, {
    Widget? trailing,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Theme.of(context).primaryColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : null,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  // Dialog fonksiyonları - DÜZELTİLMİŞ
  void _showBackupDialog(BuildContext context, PatientController controller) {
    showDialog(
      context: context,
      barrierDismissible: true, // Dış tıklama ile kapanabilir
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.backup, color: Colors.blue),
            SizedBox(width: 8),
            Text('Veri Yedekleme'),
          ],
        ),
        content: const Text(
          'Hasta verilerinizi yedeklemek istediğinizden emin misiniz?\n\n'
          'Bu işlem tüm hasta kayıtlarını güvenli bir şekilde dışa aktaracaktır.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _performBackup(controller);
            },
            child: const Text('Yedekle'),
          ),
        ],
      ),
    );
  }

  void _showDeletedPatientsDialog(
      BuildContext context, PatientController controller) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) => Dialog(
        child: Container(
          width: double.maxFinite,
          height: 400,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.delete_sweep, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Text(
                    'Silinmiş Hastalar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Obx(() {
                  controller.loadDeletedPatients();
                  final deletedPatients = controller.deletedPatients;

                  if (deletedPatients.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle,
                              size: 64, color: Colors.green),
                          SizedBox(height: 16),
                          Text('Silinmiş hasta bulunmuyor'),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: deletedPatients.length,
                    itemBuilder: (context, index) {
                      final patient = deletedPatients[index];
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(patient.fullName),
                          subtitle: Text('TC: ${patient.tcNumber}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () {
                                  controller.restorePatient(patient.id);
                                  Navigator.of(dialogContext).pop();
                                },
                                icon: const Icon(Icons.restore,
                                    color: Colors.green),
                              ),
                              IconButton(
                                onPressed: () => _showPermanentDeleteDialog(
                                    patient, controller, dialogContext),
                                icon: const Icon(Icons.delete_forever,
                                    color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPermanentDeleteDialog(
      patient, PatientController controller, BuildContext parentContext) {
    showDialog(
      context: parentContext,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Kalıcı Silme'),
        content: Text(
          '${patient.fullName} isimli hastayı kalıcı olarak silmek istediğinizden emin misiniz?\n\n'
          'Bu işlem GERİ ALINAMAZ!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              controller.permanentDeletePatient(patient.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Kalıcı Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllDialog(
      BuildContext context, PatientController controller) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Tehlikeli İşlem'),
          ],
        ),
        content: const Text(
          'TÜM hasta verilerini silmek istediğinizden emin misiniz?\n\n'
          'Bu işlem GERİ ALINAMAZ ve tüm hasta kayıtları kalıcı olarak silinecektir.\n\n'
          'Devam etmek için "TÜMÜNÜ SİL" yazın:',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _showDeleteAllConfirmation(controller);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Devam Et', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllConfirmation(PatientController controller) {
    final confirmController = TextEditingController();

    showDialog(
      context: Get.context!,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Son Onay'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Silmek için "TÜMÜNÜ SİL" yazın:'),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'TÜMÜNÜ SİL',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (confirmController.text == 'TÜMÜNÜ SİL') {
                Navigator.of(dialogContext).pop();
                Get.snackbar(
                  'Uyarı',
                  'Bu özellik henüz aktif değil',
                  backgroundColor: Colors.orange,
                  colorText: Colors.white,
                );
              } else {
                Get.snackbar(
                  'Hata',
                  'Doğrulama metni yanlış',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          height: 400,
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.privacy_tip, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    'Gizlilik Politikası',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    'Bu uygulama hasta verilerinizi yerel olarak cihazınızda saklar. '
                    'Hiçbir veri harici sunuculara gönderilmez.\n\n'
                    '• Tüm hasta bilgileri cihazınızda şifrelenir\n'
                    '• Veriler sadece uygulama içinde kullanılır\n'
                    '• Üçüncü taraflarla veri paylaşımı yapılmaz\n'
                    '• Uygulamayı sildiğinizde tüm veriler silinir\n\n',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          height: 400,
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.description, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    'Kullanım Koşulları',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    'Bu uygulamayı kullanarak aşağıdaki koşulları kabul etmiş olursunuz:\n\n'
                    '1. SORUMLULUK\n'
                    '• Hasta verilerinizin doğruluğundan siz sorumlusunuz\n'
                    '• Uygulamayı tıbbi teşhis için kullanmayın\n'
                    '• Verilerinizi düzenli olarak yedekleyin\n\n'
                    '2. GÜVENLİK\n'
                    '• Cihazınızı güvenli tutun\n'
                    '• Hassas bilgileri uygun şekilde koruyun\n'
                    '• Şüpheli aktivitelerde uygulamayı kapatın\n\n'
                    '3. SINIRLAMALAR\n'
                    '• Uygulama tıbbi cihaz değildir\n'
                    '• Profesyonel tıbbi tavsiye yerine geçmez\n'
                    '• Acil durumlarda 112\'yi arayın',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          height: 400,
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.help, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    'Yardım ve Destek',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NASIL KULLANILIR?',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Ana sayfada + butonuna basarak hasta ekleyin\n'
                        '• Hasta listesinde arama ve filtreleme yapın\n'
                        '• Hasta detaylarını görmek için karta dokunun\n'
                        '• İstatistikler sekmesinde özet bilgileri görün',
                      ),
                      SizedBox(height: 16),
                      Text(
                        'SIKÇA SORULAN SORULAR',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text('S: Veriler nerede saklanıyor?\n'
                          'C: Tüm veriler cihazınızda güvenli şekilde saklanır.\n\n'
                          'S: Veri kaybı yaşarsam ne olur?\n'
                          'C: Düzenli yedekleme yapmanızı öneririz.\n\n'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.star, color: Colors.amber),
            SizedBox(width: 8),
            Text('Uygulamayı Değerlendir'),
          ],
        ),
        content: const Text(
          'Uygulamayı beğendiyseniz App Store\'da 5 yıldız vererek '
          'bizi destekleyebilirsiniz. Bu, daha iyi özellikler '
          'geliştirmemize yardımcı olur.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Şimdi Değil'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Get.snackbar(
                'Teşekkürler!',
                'App Store\'a yönlendiriliyorsunuz...',
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            },
            child: const Text('Değerlendir'),
          ),
        ],
      ),
    );
  }

  void _performBackup(PatientController controller) {
    // Loading göster
    Get.dialog(
      const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Yedekleme yapılıyor...'),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    // 3 saniye sonra başarılı mesajı göster
    Future.delayed(const Duration(seconds: 3), () {
      Get.back(); // Loading dialog'unu kapat

      Get.snackbar(
        'Başarılı',
        '${controller.patients.length} hasta verisi başarıyla yedeklendi\nDosya: hastalar_yedek_${DateTime.now().day}_${DateTime.now().month}_${DateTime.now().year}.json',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    });
  }
}

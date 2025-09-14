import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sqflite_proje/controllers/patient_controller.dart';
import '../models/patient.dart';
import '../services/image_service.dart';
import 'edit_patient_page.dart'; // Burada EditPatientPage import edildi

class PatientDetailPage extends StatelessWidget {
  final Patient patient;

  const PatientDetailPage({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(patient.fullName),
        actions: [
          IconButton(
            onPressed: () {
              // Düzenleme sayfasına geçiş yap
              Get.to(() => EditPatientPage(patient: patient));
            },
            icon: const Icon(Icons.edit),
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: const [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Düzenle'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: const [
                    Icon(Icons.share, size: 20),
                    SizedBox(width: 8),
                    Text('Paylaş'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: const [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Sil', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeaderSection(context),
            _buildBasicInfoSection(context),
            _buildContactSection(context),
            _buildMedicalInfoSection(context),
            if (patient.emergencyContact?.isNotEmpty == true ||
                patient.emergencyPhone?.isNotEmpty == true)
              _buildEmergencySection(context),
            if (patient.allergies?.isNotEmpty == true ||
                patient.medications?.isNotEmpty == true ||
                patient.notes?.isNotEmpty == true)
              _buildAdditionalInfoSection(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).scaffoldBackgroundColor,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Hero(
              tag: 'patient_image_${patient.id}',
              child: ImageService.buildImageWidget(
                imagePath: patient.imagePath,
                size: 120,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              patient.fullName,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  patient.gender == 'Erkek' ? Icons.male : Icons.female,
                  color: patient.gender == 'Erkek' ? Colors.blue : Colors.pink,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${patient.age} yaş • ${patient.gender}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
            if (patient.bloodType.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Kan Grubu: ${patient.bloodType}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'Temel Bilgiler',
      icon: Icons.person,
      children: [
        _buildInfoRow('TC Kimlik No', patient.tcNumber),
        _buildInfoRow('Yaş', '${patient.age}'),
        _buildInfoRow('Cinsiyet', patient.gender),
        if (patient.height != null || patient.weight != null) ...[
          _buildInfoRow(
            'Boy/Kilo',
            '${patient.height?.round() ?? '-'} cm / ${patient.weight?.toStringAsFixed(1) ?? '-'} kg',
          ),
          if (patient.bmi != null)
            _buildInfoRow(
              'BMI',
              '${patient.bmi!.toStringAsFixed(1)} (${patient.bmiCategory})',
            ),
        ],
        _buildInfoRow(
          'Kayıt Tarihi',
          DateFormat('dd MMMM yyyy, HH:mm', 'tr').format(patient.createdAt),
        ),
        _buildInfoRow(
          'Son Güncelleme',
          DateFormat('dd MMMM yyyy, HH:mm', 'tr').format(patient.updatedAt),
        ),
      ],
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'İletişim Bilgileri',
      icon: Icons.contact_phone,
      children: [
        _buildInfoRow('Telefon', patient.phone, isPhone: true),
        if (patient.email.isNotEmpty)
          _buildInfoRow('E-posta', patient.email, isEmail: true),
        if (patient.address.isNotEmpty)
          _buildInfoRow('Adres', patient.address, multiline: true),
      ],
    );
  }

  Widget _buildMedicalInfoSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'Tıbbi Bilgiler',
      icon: Icons.medical_services,
      children: [
        if (patient.diagnosis.isNotEmpty)
          _buildInfoRow('Tanı', patient.diagnosis),
        if (patient.bloodType.isNotEmpty)
          _buildInfoRow('Kan Grubu', patient.bloodType),
        if (patient.doctorName?.isNotEmpty == true)
          _buildInfoRow('Doktor', patient.doctorName!),
        if (patient.insuranceNumber?.isNotEmpty == true)
          _buildInfoRow('Sigorta No', patient.insuranceNumber!),
      ],
    );
  }

  Widget _buildEmergencySection(BuildContext context) {
    return _buildSection(
      context,
      title: 'Acil Durum Bilgileri',
      icon: Icons.emergency,
      iconColor: Colors.red,
      children: [
        if (patient.emergencyContact?.isNotEmpty == true)
          _buildInfoRow('İletişim Kişisi', patient.emergencyContact!),
        if (patient.emergencyPhone?.isNotEmpty == true)
          _buildInfoRow('Acil Telefon', patient.emergencyPhone!, isPhone: true),
      ],
    );
  }

  Widget _buildAdditionalInfoSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'Ek Bilgiler',
      icon: Icons.info,
      children: [
        if (patient.allergies?.isNotEmpty == true)
          _buildInfoRow('Alerjiler', patient.allergies!, multiline: true),
        if (patient.medications?.isNotEmpty == true)
          _buildInfoRow('İlaçlar', patient.medications!, multiline: true),
        if (patient.notes?.isNotEmpty == true)
          _buildInfoRow('Notlar', patient.notes!, multiline: true),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: iconColor ?? Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isPhone = false,
    bool isEmail = false,
    bool multiline = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: multiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: isPhone
                  ? () => _makePhoneCall(value)
                  : isEmail
                  ? () => _sendEmail(value)
                  : null,
              child: Text(
                value,
                style: TextStyle(
                  color: (isPhone || isEmail)
                      ? Theme.of(Get.context!).primaryColor
                      : null,
                  decoration: (isPhone || isEmail)
                      ? TextDecoration.underline
                      : null,
                ),
                maxLines: multiline ? null : 1,
                overflow: multiline
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        // Düzenleme sayfasına geçiş yap
        Get.to(() => EditPatientPage(patient: patient));
        break;
      case 'share':
        _sharePatientInfo();
        break;
      case 'delete':
        _showDeleteDialog();
        break;
    }
  }

  void _makePhoneCall(String phoneNumber) {
    Get.snackbar(
      'Telefon',
      'Arama özelliği yakında eklenecek\n$phoneNumber',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  void _sendEmail(String email) {
    Get.snackbar(
      'E-posta',
      'E-posta özelliği yakında eklenecek\n$email',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  void _sharePatientInfo() {
    final info =
        '''
Hasta Bilgileri

Ad Soyad: ${patient.fullName}
TC No: ${patient.tcNumber}
Yaş: ${patient.age}
Cinsiyet: ${patient.gender}
Telefon: ${patient.phone}
${patient.email.isNotEmpty ? 'E-posta: ${patient.email}' : ''}
${patient.bloodType.isNotEmpty ? 'Kan Grubu: ${patient.bloodType}' : ''}
${patient.diagnosis.isNotEmpty ? 'Tanı: ${patient.diagnosis}' : ''}

Kayıt Tarihi: ${DateFormat('dd.MM.yyyy').format(patient.createdAt)}
''';

    Get.snackbar(
      'Paylaş',
      'Paylaşım özelliği yakında eklenecek',
      snackPosition: SnackPosition.BOTTOM,
      messageText: Text(
        info,
        style: const TextStyle(color: Colors.white, fontSize: 12),
        maxLines: 10,
      ),
      duration: const Duration(seconds: 5),
    );
  }

  void _showDeleteDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Hasta Sil'),
        content: Text(
          '${patient.fullName} isimli hastayı silmek istediğinizden emin misiniz?\n\nBu işlem geri alınabilir.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              Get.back(); // Close dialog
              Get.back(); // Go back to list
              Get.find<PatientController>().deletePatient(patient.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}

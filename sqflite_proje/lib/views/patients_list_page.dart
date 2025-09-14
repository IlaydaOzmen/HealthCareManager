import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/patient_controller.dart';
import '../models/patient.dart';
import 'edit_patient_page.dart';

class PatientsListPage extends StatelessWidget {
  const PatientsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final PatientController controller = Get.find<PatientController>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: false,
            snap: true,
            expandedHeight: 120,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Text(
                'Hastalar',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 45,
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          onChanged: (value) =>
                              controller.searchQuery.value = value,
                          decoration: InputDecoration(
                            hintText: 'Hasta ara...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 45,
                      width: 45,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.filter_list,
                            color: Colors.white, size: 20),
                        onPressed: () => _showFilterDialog(context, controller),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Obx(() {
            if (controller.isLoading.value) {
              return const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (controller.filteredPatients.isEmpty) {
              return SliverFillRemaining(
                child: _buildEmptyState(),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final patient = controller.filteredPatients[index];
                    return _buildPatientCard(context, patient, controller);
                  },
                  childCount: controller.filteredPatients.length,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Hasta bulunamadı',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Henüz hiç hasta eklenmemiş\nveya arama kriterlerinize uygun hasta yok',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(
      BuildContext context, Patient patient, PatientController controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            patient.firstName[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          patient.fullName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Yaş: ${patient.age} • ${patient.gender}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              patient.diagnosis.isNotEmpty
                  ? patient.diagnosis
                  : 'Tanı girilmemiş',
              style: TextStyle(
                color: patient.diagnosis.isNotEmpty
                    ? Theme.of(context).primaryColor
                    : Colors.grey[500],
                fontSize: 13,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _navigateToEditPatient(context, patient);
                break;
              case 'delete':
                _showDeleteDialog(context, patient, controller);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Düzenle'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Sil', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () {
          _showPatientDetailDialog(context, patient, controller);
        },
      ),
    );
  }

  void _showPatientDetailDialog(
      BuildContext context, Patient patient, PatientController controller) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600, maxWidth: 400),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 40), // Boşluk için
                          Text(
                            'Hasta Detayları',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            icon: const Icon(Icons.close),
                            iconSize: 24,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        radius: 40,
                        child: Text(
                          patient.firstName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        patient.fullName,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            patient.gender == 'Erkek'
                                ? Icons.male
                                : Icons.female,
                            color: patient.gender == 'Erkek'
                                ? Colors.blue
                                : Colors.pink,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${patient.age} yaş • ${patient.gender}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Content Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Temel Bilgiler
                      _buildPopupSection('Temel Bilgiler', [
                        _buildPopupInfoRow('TC Kimlik No', patient.tcNumber),
                        _buildPopupInfoRow('Telefon', patient.phone),
                        if (patient.email.isNotEmpty)
                          _buildPopupInfoRow('E-posta', patient.email),
                        if (patient.bloodType.isNotEmpty)
                          _buildPopupInfoRow('Kan Grubu', patient.bloodType),
                      ]),

                      const SizedBox(height: 16),

                      // Tıbbi Bilgiler
                      _buildPopupSection('Tıbbi Bilgiler', [
                        _buildPopupInfoRow(
                            'Tanı',
                            patient.diagnosis.isNotEmpty
                                ? patient.diagnosis
                                : 'Tanı girilmemiş'),
                        if (patient.height != null &&
                            patient.weight != null) ...[
                          _buildPopupInfoRow('Boy/Kilo',
                              '${patient.height?.round() ?? '-'} cm / ${patient.weight?.toStringAsFixed(1) ?? '-'} kg'),
                        ],
                        if (patient.doctorName?.isNotEmpty == true)
                          _buildPopupInfoRow('Doktor', patient.doctorName!),
                      ]),

                      const SizedBox(height: 16),

                      // Adres
                      if (patient.address.isNotEmpty)
                        _buildPopupSection('İletişim', [
                          _buildPopupInfoRow('Adres', patient.address,
                              multiline: true),
                        ]),

                      const SizedBox(height: 16),

                      // Acil Durum (varsa)
                      if (patient.emergencyContact?.isNotEmpty == true ||
                          patient.emergencyPhone?.isNotEmpty == true)
                        _buildPopupSection('Acil Durum', [
                          if (patient.emergencyContact?.isNotEmpty == true)
                            _buildPopupInfoRow(
                                'İletişim Kişisi', patient.emergencyContact!),
                          if (patient.emergencyPhone?.isNotEmpty == true)
                            _buildPopupInfoRow(
                                'Acil Telefon', patient.emergencyPhone!),
                        ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPopupSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildPopupInfoRow(String label, String value,
      {bool multiline = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
              maxLines: multiline ? null : 2,
              overflow: multiline ? null : TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context, PatientController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrele'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gender filter
              Obx(() => DropdownButtonFormField<String>(
                    value: controller.selectedGender.value.isEmpty
                        ? null
                        : controller.selectedGender.value,
                    decoration: const InputDecoration(
                      labelText: 'Cinsiyet',
                      border: OutlineInputBorder(),
                    ),
                    items: controller.genderOptions.map((gender) {
                      return DropdownMenuItem(
                        value: gender,
                        child: Text(gender),
                      );
                    }).toList(),
                    onChanged: (value) {
                      controller.selectedGender.value = value ?? '';
                    },
                  )),
              const SizedBox(height: 16),
              // Blood type filter
              Obx(() => DropdownButtonFormField<String>(
                    value: controller.selectedBloodType.value.isEmpty
                        ? null
                        : controller.selectedBloodType.value,
                    decoration: const InputDecoration(
                      labelText: 'Kan Grubu',
                      border: OutlineInputBorder(),
                    ),
                    items: controller.bloodTypes.map((bloodType) {
                      return DropdownMenuItem(
                        value: bloodType,
                        child: Text(bloodType),
                      );
                    }).toList(),
                    onChanged: (value) {
                      controller.selectedBloodType.value = value ?? '';
                    },
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.clearFilters();
              Navigator.pop(context);
            },
            child: const Text('Temizle'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Uygula'),
          ),
        ],
      ),
    );
  }

  void _navigateToEditPatient(BuildContext context, Patient patient) {
    Get.to(
      () => EditPatientPage(patient: patient),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _showDeleteDialog(
      BuildContext context, Patient patient, PatientController controller) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Hasta Sil'),
        content: Text(
            '${patient.fullName} adlı hastayı silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deletePatient(patient.id);
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

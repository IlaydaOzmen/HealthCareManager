import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/patient_controller.dart';
import '../models/patient.dart';

class EditPatientPage extends StatefulWidget {
  final Patient patient;

  const EditPatientPage({super.key, required this.patient});

  @override
  State<EditPatientPage> createState() => _EditPatientPageState();
}

class _EditPatientPageState extends State<EditPatientPage> {
  final _formKey = GlobalKey<FormState>();
  final PatientController _patientController = Get.find<PatientController>();

  // Form controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _tcNumberController;
  late TextEditingController _ageController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _diagnosisController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _emergencyContactController;
  late TextEditingController _emergencyPhoneController;
  late TextEditingController _allergiesController;
  late TextEditingController _medicationsController;
  late TextEditingController _notesController;
  late TextEditingController _doctorNameController;
  late TextEditingController _insuranceNumberController;

  String _selectedGender = '';
  String _selectedBloodType = '';

  // Yeni: kronik hastalık durumu
  bool _hasChronicDisease = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _firstNameController =
        TextEditingController(text: widget.patient.firstName);
    _lastNameController = TextEditingController(text: widget.patient.lastName);
    _tcNumberController = TextEditingController(text: widget.patient.tcNumber);
    _ageController = TextEditingController(text: widget.patient.age.toString());
    _phoneController = TextEditingController(text: widget.patient.phone);
    _emailController = TextEditingController(text: widget.patient.email);
    _addressController = TextEditingController(text: widget.patient.address);
    _diagnosisController =
        TextEditingController(text: widget.patient.diagnosis);
    _heightController =
        TextEditingController(text: widget.patient.height?.toString() ?? '');
    _weightController =
        TextEditingController(text: widget.patient.weight?.toString() ?? '');
    _emergencyContactController =
        TextEditingController(text: widget.patient.emergencyContact ?? '');
    _emergencyPhoneController =
        TextEditingController(text: widget.patient.emergencyPhone ?? '');
    _allergiesController =
        TextEditingController(text: widget.patient.allergies ?? '');
    _medicationsController =
        TextEditingController(text: widget.patient.medications ?? '');
    _notesController = TextEditingController(text: widget.patient.notes ?? '');
    _doctorNameController =
        TextEditingController(text: widget.patient.doctorName ?? '');
    _insuranceNumberController =
        TextEditingController(text: widget.patient.insuranceNumber ?? '');

    _selectedGender = widget.patient.gender;
    _selectedBloodType = widget.patient.bloodType;
    _hasChronicDisease = widget.patient.hasChronicDisease; // kronik hastalık
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _tcNumberController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _diagnosisController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
    _allergiesController.dispose();
    _medicationsController.dispose();
    _notesController.dispose();
    _doctorNameController.dispose();
    _insuranceNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasta Düzenle'),
        actions: [
          Obx(() => _patientController.isLoading.value
              ? const Center(child: CircularProgressIndicator())
              : TextButton.icon(
                  onPressed: _updatePatient,
                  icon: const Icon(Icons.save, color: Colors.blue),
                  label: const Text('Kaydet',
                      style: TextStyle(color: Colors.blue)),
                )),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Kişisel Bilgiler'),
              _buildPersonalInfoSection(),
              const SizedBox(height: 24),
              _buildSectionTitle('İletişim Bilgileri'),
              _buildContactInfoSection(),
              const SizedBox(height: 24),
              _buildSectionTitle('Tıbbi Bilgiler'),
              _buildMedicalInfoSection(),
              const SizedBox(height: 24),

              // Yeni: kronik hastalık checkbox
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: CheckboxListTile(
                    title: const Text('Kronik Hastalık Var mı?'),
                    value: _hasChronicDisease,
                    onChanged: (bool? value) {
                      setState(() {
                        _hasChronicDisease = value ?? false;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Acil Durum'),
              _buildEmergencySection(),
              const SizedBox(height: 24),
              _buildSectionTitle('Ek Bilgiler'),
              _buildAdditionalInfoSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'Ad *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty == true ? 'Ad gerekli' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Soyad *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty == true ? 'Soyad gerekli' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tcNumberController,
              decoration: const InputDecoration(
                labelText: 'TC Kimlik No *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty == true) return 'TC Kimlik No gerekli';
                if (value!.length != 11) return 'TC Kimlik No 11 haneli olmalı';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ageController,
                    decoration: const InputDecoration(
                      labelText: 'Yaş *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value?.isEmpty == true ? 'Yaş gerekli' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedGender.isEmpty ? null : _selectedGender,
                    decoration: const InputDecoration(
                      labelText: 'Cinsiyet *',
                      border: OutlineInputBorder(),
                    ),
                    items: _patientController.genderOptions.map((gender) {
                      return DropdownMenuItem(
                        value: gender,
                        child: Text(gender),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedGender = value ?? ''),
                    validator: (value) =>
                        value?.isEmpty == true ? 'Cinsiyet seçin' : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Telefon *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) =>
                  value?.isEmpty == true ? 'Telefon gerekli' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-posta',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Adres',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _diagnosisController,
              decoration: const InputDecoration(
                labelText: 'Tanı *',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.isEmpty == true ? 'Tanı gerekli' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedBloodType.isEmpty ? null : _selectedBloodType,
              decoration: const InputDecoration(
                labelText: 'Kan Grubu *',
                border: OutlineInputBorder(),
              ),
              items: _patientController.bloodTypes.map((bloodType) {
                return DropdownMenuItem(
                  value: bloodType,
                  child: Text(bloodType),
                );
              }).toList(),
              onChanged: (value) =>
                  setState(() => _selectedBloodType = value ?? ''),
              validator: (value) =>
                  value?.isEmpty == true ? 'Kan grubu seçin' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _heightController,
                    decoration: const InputDecoration(
                      labelText: 'Boy (cm)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: 'Kilo (kg)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _doctorNameController,
              decoration: const InputDecoration(
                labelText: 'Doktor Adı',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _emergencyContactController,
              decoration: const InputDecoration(
                labelText: 'Acil Durum İletişim Kişisi',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emergencyPhoneController,
              decoration: const InputDecoration(
                labelText: 'Acil Durum Telefonu',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _allergiesController,
              decoration: const InputDecoration(
                labelText: 'Alerjiler',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _medicationsController,
              decoration: const InputDecoration(
                labelText: 'Kullandığı İlaçlar',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _insuranceNumberController,
              decoration: const InputDecoration(
                labelText: 'Sigorta Numarası',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notlar',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

// EditPatientPage'deki _updatePatient metodunu güncelleyin

  void _updatePatient() {
    if (_formKey.currentState!.validate()) {
      final updatedPatient = widget.patient.copyWith(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        tcNumber: _tcNumberController.text.trim(),
        age: int.tryParse(_ageController.text.trim()) ?? 0,
        gender: _selectedGender,
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        diagnosis: _diagnosisController.text.trim(),
        bloodType: _selectedBloodType,
        height: double.tryParse(_heightController.text.trim()),
        weight: double.tryParse(_weightController.text.trim()),
        hasChronicDisease: _hasChronicDisease,
        emergencyContact: _emergencyContactController.text.trim().isEmpty
            ? null
            : _emergencyContactController.text.trim(),
        emergencyPhone: _emergencyPhoneController.text.trim().isEmpty
            ? null
            : _emergencyPhoneController.text.trim(),
        allergies: _allergiesController.text.trim().isEmpty
            ? null
            : _allergiesController.text.trim(),
        medications: _medicationsController.text.trim().isEmpty
            ? null
            : _medicationsController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        doctorName: _doctorNameController.text.trim().isEmpty
            ? null
            : _doctorNameController.text.trim(),
        insuranceNumber: _insuranceNumberController.text.trim().isEmpty
            ? null
            : _insuranceNumberController.text.trim(),
        updatedAt: DateTime.now(),
      );

      _patientController.updatePatient(updatedPatient).then((_) {
        // Başarılı güncelleme snackbar'ı
        Get.snackbar(
          'Başarılı',
          'Hasta bilgileri başarıyla güncellendi',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle, color: Colors.white),
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(16),
          borderRadius: 8,
        );

        Get.back(); // Sayfayı kapat
      }).catchError((error) {
        // Hata durumunda snackbar
        Get.snackbar(
          'Hata',
          'Hasta bilgileri güncellenirken bir hata oluştu',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          icon: const Icon(Icons.error, color: Colors.white),
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(16),
          borderRadius: 8,
        );
      });
    }
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/patient_controller.dart';

class FilterPage extends StatefulWidget {
  const FilterPage({super.key});

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  late String selectedGender;
  late String selectedBloodType;
  late String selectedDiagnosis;
  late RangeValues ageRange;
  late TextEditingController searchController; // Arama için controller

  @override
  void initState() {
    super.initState();
    _initializeFilters();
    searchController = TextEditingController(); // Controller'ı başlat
  }

  @override
  void dispose() {
    searchController.dispose(); // Controller'ı temizle
    super.dispose();
  }

  void _initializeFilters() {
    try {
      final PatientController controller = Get.find<PatientController>();
      selectedGender = controller.selectedGender.value;
      selectedBloodType = controller.selectedBloodType.value;
      selectedDiagnosis = controller.selectedDiagnosis.value;
      searchController.text =
          controller.searchQuery.value; // Mevcut arama sorgusunu yükle
      ageRange = RangeValues(
        controller.minAge.value.toDouble(),
        controller.maxAge.value.toDouble(),
      );
    } catch (e) {
      // Controller bulunamazsa default değerler
      selectedGender = '';
      selectedBloodType = '';
      selectedDiagnosis = '';
      searchController.text = '';
      ageRange = const RangeValues(0, 100);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtrele'),
        actions: [
          TextButton(
            onPressed: _clearFilters,
            child: const Text('Temizle'),
          ),
          TextButton(
            onPressed: _applyFilters,
            child: const Text('Uygula'),
          ),
        ],
      ),
      body: GetBuilder<PatientController>(
        builder: (controller) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchFilter(), // Arama filtresi eklendi
                const SizedBox(height: 24),
                _buildGenderFilter(controller),
                const SizedBox(height: 24),
                _buildBloodTypeFilter(controller),
                const SizedBox(height: 24),
                _buildDiagnosisFilter(controller),
                const SizedBox(height: 24),
                _buildAgeRangeFilter(),
                const SizedBox(height: 32),
                _buildApplyButton(),
              ],
            ),
          );
        },
      ),
    );
  }

  // Yeni eklenen arama filtresi
  Widget _buildSearchFilter() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'İsim Arama',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Hasta adı veya soyadı ile ara...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            searchController.clear();
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {}); // Temizle butonunu göstermek için
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderFilter(PatientController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cinsiyet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _buildFilterChip(
                  label: 'Hepsi',
                  isSelected: selectedGender.isEmpty,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        selectedGender = '';
                      });
                    }
                  },
                ),
                ...controller.genderOptions.map((gender) {
                  return _buildFilterChip(
                    label: gender,
                    isSelected: selectedGender == gender,
                    onSelected: (selected) {
                      setState(() {
                        selectedGender = selected ? gender : '';
                      });
                    },
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBloodTypeFilter(PatientController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kan Grubu',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterChip(
                  label: 'Hepsi',
                  isSelected: selectedBloodType.isEmpty,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        selectedBloodType = '';
                      });
                    }
                  },
                ),
                ...controller.bloodTypes.map((bloodType) {
                  return _buildFilterChip(
                    label: bloodType,
                    isSelected: selectedBloodType == bloodType,
                    onSelected: (selected) {
                      setState(() {
                        selectedBloodType = selected ? bloodType : '';
                      });
                    },
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosisFilter(PatientController controller) {
    final diagnoses = controller.getDiagnosesList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tanı',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            if (diagnoses.isEmpty)
              const Text(
                'Henüz tanı girilmiş hasta bulunmuyor',
                style: TextStyle(color: Colors.grey),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterChip(
                    label: 'Hepsi',
                    isSelected: selectedDiagnosis.isEmpty,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          selectedDiagnosis = '';
                        });
                      }
                    },
                  ),
                  ...diagnoses.map((diagnosis) {
                    return _buildFilterChip(
                      label: diagnosis,
                      isSelected: selectedDiagnosis == diagnosis,
                      onSelected: (selected) {
                        setState(() {
                          selectedDiagnosis = selected ? diagnosis : '';
                        });
                      },
                    );
                  }),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgeRangeFilter() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Yaş Aralığı',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${ageRange.start.round()} yaş'),
                Text('${ageRange.end.round()} yaş'),
              ],
            ),
            RangeSlider(
              values: ageRange,
              min: 0,
              max: 100,
              divisions: 20,
              labels: RangeLabels(
                '${ageRange.start.round()}',
                '${ageRange.end.round()}',
              ),
              onChanged: (values) {
                setState(() {
                  ageRange = values;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required Function(bool) onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).primaryColor : null,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildApplyButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _applyFilters,
        icon: const Icon(Icons.filter_alt),
        label: const Text('Filtreleri Uygula'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      selectedGender = '';
      selectedBloodType = '';
      selectedDiagnosis = '';
      searchController.clear(); // Arama alanını temizle
      ageRange = const RangeValues(0, 100);
    });
  }

  void _applyFilters() {
    try {
      final PatientController controller = Get.find<PatientController>();

      controller.selectedGender.value = selectedGender;
      controller.selectedBloodType.value = selectedBloodType;
      controller.selectedDiagnosis.value = selectedDiagnosis;
      controller.searchQuery.value =
          searchController.text; // Arama sorgusunu uygula
      controller.minAge.value = ageRange.start.round();
      controller.maxAge.value = ageRange.end.round();

      controller.applySearchAndFilter();
      Get.back();

      Get.snackbar(
        'Filtre',
        'Filtreler uygulandı',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Hata',
        'Filtre uygulanamadı: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}

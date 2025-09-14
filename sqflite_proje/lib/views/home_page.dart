import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/patient_controller.dart';
import 'patients_list_page.dart';
import 'statistics_page.dart';
import 'settings_page.dart';
import 'add_patient_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _pages = [
    const PatientsListPage(),
    const StatisticsPage(),
    const SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    // Controller'ı kontrol et ve gerekirse yükle
    _initializeController();
  }

  void _initializeController() {
    // Controller zaten main.dart'ta yüklendi, sadece kontrol et
    if (!Get.isRegistered<PatientController>()) {
      Get.put(PatientController(), permanent: true);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey[600],
          items: [
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.people_outline, Icons.people, 0),
              label: 'Hastalar',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.bar_chart_outlined, Icons.bar_chart, 1),
              label: 'İstatistikler',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.settings_outlined, Icons.settings, 2),
              label: 'Ayarlar',
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _addPatient(),
              icon: const Icon(Icons.add),
              label: const Text('Hasta Ekle'),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              elevation: 4,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildNavIcon(IconData outlined, IconData filled, int index) {
    final isSelected = _selectedIndex == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : Colors.transparent,
      ),
      child: Icon(
        isSelected ? filled : outlined,
        size: 24,
        color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
      ),
    );
  }

  void _addPatient() {
    // Controller'ın mevcut olduğunu kontrol et
    if (Get.isRegistered<PatientController>()) {
      Get.to(
        () => const AddPatientPage(),
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 300),
      );
    } else {
      // Controller yoksa önce initialize et
      Get.put(PatientController(), permanent: true);
      Get.to(
        () => const AddPatientPage(),
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 300),
      );
    }
  }
}

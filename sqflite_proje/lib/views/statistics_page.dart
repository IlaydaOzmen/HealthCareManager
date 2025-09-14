import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../controllers/patient_controller.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller'ı al - hata vermeyecek şekilde
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
                    _buildOverviewCards(context),
                    const SizedBox(height: 24),
                    _buildGenderDistribution(context),
                    const SizedBox(height: 24),
                    _buildAgeDistribution(context),
                    const SizedBox(height: 24),
                    _buildBloodTypeDistribution(context),
                    const SizedBox(height: 24),
                    _buildRecentActivity(context),
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
        title: const Text('İstatistikler'),
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
      actions: [
        IconButton(
          onPressed: () {
            try {
              Get.find<PatientController>().loadStatistics();
            } catch (e) {
              debugPrint('Controller error: $e');
            }
          },
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }

  Widget _buildOverviewCards(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GetBuilder<PatientController>(
        builder: (controller) {
          final stats = controller.statistics;
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Toplam Hasta',
                      '${stats['total'] ?? 0}',
                      Icons.people,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Bugün Eklenen',
                      '${stats['todayAdded'] ?? 0}',
                      Icons.add_circle,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Erkek Hasta',
                      '${stats['male'] ?? 0}',
                      Icons.male,
                      Colors.indigo,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Kadın Hasta',
                      '${stats['female'] ?? 0}',
                      Icons.female,
                      Colors.pink,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderDistribution(BuildContext context) {
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
                  Icon(Icons.pie_chart, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Cinsiyet Dağılımı',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GetBuilder<PatientController>(
                builder: (controller) {
                  final stats = controller.statistics;
                  final total = stats['total'] ?? 0;
                  final male = stats['male'] ?? 0;
                  final female = stats['female'] ?? 0;

                  if (total == 0) {
                    return const Center(
                      child: Text('Henüz hasta bulunmuyor'),
                    );
                  }

                  final malePercentage =
                      (male / total * 100).toStringAsFixed(1);
                  final femalePercentage =
                      (female / total * 100).toStringAsFixed(1);

                  return Column(
                    children: [
                      _buildProgressBar(
                        context,
                        'Erkek',
                        male,
                        total,
                        Colors.blue,
                        '$malePercentage%',
                      ),
                      const SizedBox(height: 12),
                      _buildProgressBar(
                        context,
                        'Kadın',
                        female,
                        total,
                        Colors.pink,
                        '$femalePercentage%',
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgeDistribution(BuildContext context) {
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
                  Icon(Icons.bar_chart, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Yaş Dağılımı',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GetBuilder<PatientController>(
                builder: (controller) {
                  final ageDistribution = controller.getAgeDistribution();
                  final total = ageDistribution.values.fold(0, (a, b) => a + b);

                  if (total == 0) {
                    return const Center(
                      child: Text('Henüz hasta bulunmuyor'),
                    );
                  }

                  return Column(
                    children: ageDistribution.entries.map((entry) {
                      final percentage =
                          (entry.value / total * 100).toStringAsFixed(1);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: _buildProgressBar(
                          context,
                          '${entry.key} yaş',
                          entry.value,
                          total,
                          _getAgeGroupColor(entry.key),
                          '$percentage%',
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBloodTypeDistribution(BuildContext context) {
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
                  Icon(Icons.bloodtype, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Kan Grubu Dağılımı',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GetBuilder<PatientController>(
                builder: (controller) {
                  final patients = controller.patients;
                  final bloodTypeCount = <String, int>{};

                  for (final patient in patients) {
                    if (patient.bloodType.isNotEmpty) {
                      bloodTypeCount[patient.bloodType] =
                          (bloodTypeCount[patient.bloodType] ?? 0) + 1;
                    }
                  }

                  if (bloodTypeCount.isEmpty) {
                    return const Center(
                      child:
                          Text('Kan grubu bilgisi girilmiş hasta bulunmuyor'),
                    );
                  }

                  final total = bloodTypeCount.values.fold(0, (a, b) => a + b);

                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: bloodTypeCount.entries.map((entry) {
                      final percentage =
                          (entry.value / total * 100).toStringAsFixed(1);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              entry.key,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${entry.value} (%$percentage)',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
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
                  Icon(Icons.timeline, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Son Aktiviteler',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GetBuilder<PatientController>(
                builder: (controller) {
                  final recentPatients = controller.patients.take(5).toList();

                  if (recentPatients.isEmpty) {
                    return const Center(
                      child: Text('Henüz aktivite bulunmuyor'),
                    );
                  }

                  return Column(
                    children: recentPatients.map((patient) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          child: Icon(
                            Icons.person,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        title: Text(patient.fullName),
                        subtitle: Text(
                            'Son güncelleme: ${_formatDate(patient.updatedAt)}'),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                        onTap: () {
                          // Navigate to patient detail
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(
    BuildContext context,
    String label,
    int value,
    int total,
    Color color,
    String percentage,
  ) {
    final progress = total > 0 ? value / total : 0.0;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        Expanded(
          flex: 3,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$value ($percentage)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  Color _getAgeGroupColor(String ageGroup) {
    switch (ageGroup) {
      case '0-18':
        return Colors.green;
      case '19-30':
        return Colors.blue;
      case '31-50':
        return Colors.orange;
      case '51-70':
        return Colors.red;
      case '70+':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Bugün';
    } else if (difference == 1) {
      return 'Dün';
    } else if (difference < 7) {
      return '$difference gün önce';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}

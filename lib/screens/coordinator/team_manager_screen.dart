import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../models/volunteer.dart';
import '../../services/firebase_service.dart';
import '../../widgets/shared/glass_card.dart';
import '../../widgets/shared/side_nav.dart';
import '../../widgets/shared/top_nav.dart';

class TeamManagerScreen extends StatefulWidget {
  const TeamManagerScreen({super.key});

  @override
  State<TeamManagerScreen> createState() => _TeamManagerScreenState();
}

class _TeamManagerScreenState extends State<TeamManagerScreen> {
  static const List<String> _skillOptions = [
    'Medical',
    'Logistics',
    'Shelter',
    'Food Distribution',
    'Search & Rescue',
    'Counseling',
    'Water & Sanitation',
    'Transport',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const SideNav(activeRoute: '/coordinator/team'),
          Expanded(
            child: Column(
              children: [
                const TopNav(title: 'Team Manager'),
                Expanded(
                  child: StreamBuilder<List<Volunteer>>(
                    stream: FirebaseService.instance.watchVolunteers(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Failed to load volunteers: ${snapshot.error}',
                            style: AppTextStyles.technical(color: AppColors.error),
                          ),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        );
                      }

                      final volunteers = snapshot.data!;
                      final available = volunteers.where((v) => v.isAvailable).length;

                      return Stack(
                        children: [
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Volunteer Registry', style: AppTextStyles.h2())
                                              .animate()
                                              .fade(duration: 350.ms)
                                              .slideX(begin: -0.04),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Live volunteer roster with real availability updates.',
                                            style: AppTextStyles.bodyLg(
                                              color: AppColors.onSurfaceVar,
                                            ),
                                          ).animate().fade(delay: 120.ms),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    _buildStat('TOTAL VOLUNTEERS', '${volunteers.length}', null),
                                    const SizedBox(width: 16),
                                    _buildStat('AVAILABLE NOW', '$available', AppColors.safeGreen),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 520,
                                    childAspectRatio: 1.65,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                                  itemCount: volunteers.length,
                                  itemBuilder: (context, i) =>
                                      _buildVolunteerCard(volunteers[i], i),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            right: 24,
                            bottom: 24,
                            child: FloatingActionButton(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.background,
                              onPressed: _showAddVolunteerDialog,
                              child: const Icon(Icons.person_add_alt_1),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color? color) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.labelCaps(color: AppColors.onSecContainer)),
            const SizedBox(height: 8),
            Text(value, style: AppTextStyles.h2(color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildVolunteerCard(Volunteer v, int index) {
    final availabilityColor = v.isAvailable ? AppColors.safeGreen : AppColors.outline;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      hover: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceVariant,
                ),
                child: const Icon(Icons.person, size: 22, color: AppColors.onSurfaceVar),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v.name,
                      style: AppTextStyles.bodyMd().copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      v.phone.isEmpty ? 'No phone' : v.phone,
                      style: AppTextStyles.technical(color: AppColors.onSecContainer)
                          .copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              Switch(
                value: v.isAvailable,
                activeThumbColor: AppColors.safeGreen,
                onChanged: (value) => _toggleAvailability(v.id, value),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.circle, size: 10, color: availabilityColor),
              const SizedBox(width: 6),
              Text(
                v.isAvailable ? 'AVAILABLE' : 'UNAVAILABLE',
                style: AppTextStyles.labelCaps(color: availabilityColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: v.skills.isEmpty
                ? [
                    Text(
                      'No skills listed',
                      style: AppTextStyles.technical(color: AppColors.outline),
                    ),
                  ]
                : v.skills
                    .map(
                      (s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          s,
                          style: AppTextStyles.technical(color: AppColors.outline)
                              .copyWith(fontSize: 10),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    ).animate().fade(delay: Duration(milliseconds: 200 + (index * 50)));
  }

  Future<void> _toggleAvailability(String volunteerId, bool value) async {
    try {
      await FirebaseService.instance.updateVolunteerAvailability(volunteerId, value);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
          content: Text('Failed to update availability: $e'),
        ),
      );
    }
  }

  Future<void> _showAddVolunteerDialog() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final selectedSkills = <String>{};

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: Text('Add Volunteer', style: AppTextStyles.h3()),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneController,
                        decoration: const InputDecoration(labelText: 'Phone'),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Skills',
                        style: AppTextStyles.labelCaps(color: AppColors.onSecContainer),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _skillOptions.map((skill) {
                          final selected = selectedSkills.contains(skill);
                          return FilterChip(
                            label: Text(skill),
                            selected: selected,
                            onSelected: (value) {
                              setDialogState(() {
                                if (value) {
                                  selectedSkills.add(skill);
                                } else {
                                  selectedSkills.remove(skill);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('Cancel', style: AppTextStyles.labelCaps(color: AppColors.outline)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                  ),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    final scaffoldMessenger = ScaffoldMessenger.of(dialogContext);
                    try {
                      final volunteer = Volunteer(
                        id: 'vol_${DateTime.now().microsecondsSinceEpoch}',
                        name: name,
                        phone: phoneController.text.trim(),
                        skills: selectedSkills.toList(),
                        isAvailable: true,
                        reliabilityScore: 70,
                      );
                      await FirebaseService.instance.addVolunteer(volunteer);
                      if (!context.mounted) return;
                      Navigator.of(dialogContext).pop();
                    } catch (e) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppColors.error,
                          content: Text('Failed to add volunteer: $e'),
                        ),
                      );
                    }
                  },
                  child: Text('Add', style: AppTextStyles.labelCaps(color: AppColors.background)),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
  }
}

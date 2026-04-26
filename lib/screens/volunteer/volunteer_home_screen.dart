import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../models/need_report.dart';
import '../../models/task_assignment.dart';
import '../../services/firebase_service.dart';
import '../../widgets/shared/glass_card.dart';

class VolunteerHomeScreen extends StatefulWidget {
  const VolunteerHomeScreen({super.key});

  @override
  State<VolunteerHomeScreen> createState() => _VolunteerHomeScreenState();
}

class _VolunteerHomeScreenState extends State<VolunteerHomeScreen> {
  String? _volunteerId;

  @override
  void initState() {
    super.initState();
    _loadVolunteerId();
  }

  Future<void> _loadVolunteerId() async {
    final prefs = await SharedPreferences.getInstance();
    final fromPrefs = prefs.getString('volunteer_id');
    final fromAuth = FirebaseAuth.instance.currentUser?.uid;
    if (!mounted) return;
    setState(() {
      _volunteerId = fromPrefs ?? fromAuth ?? 'volunteer_demo';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('CRISIS_COMMAND', style: AppTextStyles.h1().copyWith(fontSize: 20)),
                Row(
                  children: [
                    Text(
                      'Volunteer Dashboard',
                      style: AppTextStyles.technical(color: AppColors.outline),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Back to role selection',
                      onPressed: _backToRoleSelection,
                      icon: const Icon(
                        Icons.logout,
                        color: AppColors.onSurfaceVar,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _volunteerId == null
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : StreamBuilder<List<TaskAssignment>>(
              stream: FirebaseService.instance.watchTasksForVolunteer(
                _volunteerId!,
              ),
              builder: (context, taskSnap) {
                if (taskSnap.hasError) {
                  return Center(
                    child: Text(
                      'Failed to load tasks: ${taskSnap.error}',
                      style: AppTextStyles.technical(color: AppColors.error),
                    ),
                  );
                }
                if (!taskSnap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                final tasks = taskSnap.data!;
                return StreamBuilder<List<NeedReport>>(
                  stream: FirebaseService.instance.watchNeeds(),
                  builder: (context, needSnap) {
                    if (needSnap.hasError) {
                      return Center(
                        child: Text(
                          'Failed to load needs: ${needSnap.error}',
                          style: AppTextStyles.technical(color: AppColors.error),
                        ),
                      );
                    }
                    if (!needSnap.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      );
                    }

                    final needsById = {
                      for (final n in needSnap.data!) n.id: n,
                    };

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Assigned Tasks', style: AppTextStyles.h2())
                              .animate()
                              .fade(duration: 320.ms)
                              .slideX(begin: -0.04),
                          const SizedBox(height: 8),
                          Text(
                            'Live tasks assigned to your volunteer account.',
                            style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVar),
                          ),
                          const SizedBox(height: 20),
                          if (tasks.isEmpty)
                            GlassCard(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                'No tasks assigned yet.',
                                style: AppTextStyles.technical(color: AppColors.outline),
                              ),
                            )
                          else
                            ...tasks.map((task) => _buildTaskCard(task, needsById[task.needId])),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(TaskAssignment task, NeedReport? need) {
    final score = need?.urgencyScore ?? 0;
    final urgencyColor = _urgencyColor(score);
    final urgencyText = score >= 70
        ? 'CRITICAL'
        : (score >= 40 ? 'HIGH' : 'NORMAL');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: urgencyColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    urgencyText,
                    style: AppTextStyles.labelCaps(color: urgencyColor),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  task.status.toUpperCase(),
                  style: AppTextStyles.technical(color: AppColors.outline),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              need?.title.isNotEmpty == true
                  ? need!.title
                  : (task.title ?? 'Need #${task.needId}'),
              style: AppTextStyles.h3(),
            ),
            const SizedBox(height: 8),
            Text(
              need?.description.isNotEmpty == true
                  ? need!.description
                  : task.notes,
              style: AppTextStyles.technical(color: AppColors.onSurfaceVar)
                  .copyWith(height: 1.5),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    onPressed: () => _openMap(need),
                    icon: const Icon(Icons.navigation_outlined, size: 16),
                    label: Text('NAVIGATE', style: AppTextStyles.labelCaps()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.safeGreen,
                      foregroundColor: AppColors.background,
                    ),
                    onPressed: task.status == 'completed'
                        ? null
                        : () => _markComplete(task.id),
                    icon: const Icon(Icons.task_alt, size: 16),
                    label: Text(
                      task.status == 'completed' ? 'COMPLETED' : 'MARK COMPLETE',
                      style: AppTextStyles.labelCaps(color: AppColors.background),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fade(duration: 260.ms);
  }

  Future<void> _openMap(NeedReport? need) async {
    final hasGeo = need?.geoLocation != null;
    final query = hasGeo
        ? '${need!.geoLocation!.latitude},${need.geoLocation!.longitude}'
        : (need?.location ?? '');
    if (query.trim().isEmpty) {
      _showSnack('No location available for navigation.', AppColors.warningAmber);
      return;
    }

    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      _showSnack('Could not open Google Maps.', AppColors.error);
    }
  }

  Future<void> _markComplete(String taskId) async {
    try {
      await FirebaseService.instance.updateTaskStatus(taskId, 'completed');
      _showSnack('Task marked complete.', AppColors.safeGreen);
    } catch (e) {
      _showSnack('Failed to update task: $e', AppColors.error);
    }
  }

  Color _urgencyColor(double score) {
    if (score >= 70) return AppColors.criticalRed;
    if (score >= 40) return AppColors.warningAmber;
    return AppColors.safeGreen;
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
        content: Text(message, style: AppTextStyles.technical()),
      ),
    );
  }

  Future<void> _backToRoleSelection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
    await prefs.remove('volunteer_id');
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    context.go('/login');
  }
}

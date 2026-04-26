import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../models/need_report.dart';
import '../../models/task_assignment.dart';
import '../../models/volunteer.dart';
import '../../services/firebase_service.dart';
import '../../widgets/shared/glass_card.dart';
import '../../widgets/shared/side_nav.dart';
import '../../widgets/shared/top_nav.dart';

class AssignmentsBoardScreen extends StatefulWidget {
  const AssignmentsBoardScreen({super.key});

  @override
  State<AssignmentsBoardScreen> createState() => _AssignmentsBoardScreenState();
}

class _AssignmentsBoardScreenState extends State<AssignmentsBoardScreen> {
  static const _columns = [
    _KanbanColumnMeta(
      key: 'unassigned',
      label: 'UNASSIGNED',
      icon: Icons.inbox_outlined,
    ),
    _KanbanColumnMeta(
      key: 'matched',
      label: 'MATCHED',
      icon: Icons.groups_2_outlined,
    ),
    _KanbanColumnMeta(
      key: 'in_progress',
      label: 'IN PROGRESS',
      icon: Icons.sync,
    ),
    _KanbanColumnMeta(
      key: 'completed',
      label: 'COMPLETED',
      icon: Icons.task_alt,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const SideNav(activeRoute: '/coordinator/assignments'),
          Expanded(
            child: Column(
              children: [
                const TopNav(title: 'Assignment Board'),
                Expanded(
                  child: StreamBuilder<List<TaskAssignment>>(
                    stream: FirebaseService.instance.watchTasks(),
                    builder: (context, taskSnap) {
                      if (taskSnap.hasError) {
                        return _buildError('Failed to load tasks: ${taskSnap.error}');
                      }
                      if (!taskSnap.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        );
                      }

                      return StreamBuilder<List<NeedReport>>(
                        stream: FirebaseService.instance.watchNeeds(),
                        builder: (context, needSnap) {
                          if (needSnap.hasError) {
                            return _buildError(
                              'Failed to load needs: ${needSnap.error}',
                            );
                          }
                          if (!needSnap.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            );
                          }

                          return StreamBuilder<List<Volunteer>>(
                            stream: FirebaseService.instance.watchVolunteers(),
                            builder: (context, volunteerSnap) {
                              if (volunteerSnap.hasError) {
                                return _buildError(
                                  'Failed to load volunteers: ${volunteerSnap.error}',
                                );
                              }
                              if (!volunteerSnap.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                  ),
                                );
                              }

                              final needsById = {
                                for (final need in needSnap.data!) need.id: need,
                              };
                              final volunteersById = {
                                for (final v in volunteerSnap.data!) v.id: v,
                              };
                              final cards = taskSnap.data!
                                  .map(
                                    (task) => _TaskCardData(
                                      task: task,
                                      need: needsById[task.needId],
                                      volunteer: volunteersById[task.volunteerId],
                                    ),
                                  )
                                  .toList();

                              final unresolvedCount = cards
                                  .where((c) => c.columnKey != 'completed')
                                  .length;

                              return SingleChildScrollView(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Kanban Assignment Board',
                                              style: AppTextStyles.h2(),
                                            )
                                                .animate()
                                                .fade(duration: 350.ms)
                                                .slideX(begin: -0.04),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Drag cards between columns to update live status.',
                                              style: AppTextStyles.bodyMd(
                                                color: AppColors.onSurfaceVar,
                                              ),
                                            ).animate().fade(delay: 100.ms),
                                          ],
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.05,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withValues(
                                                alpha: 0.08,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            '$unresolvedCount UNRESOLVED',
                                            style: AppTextStyles.labelCaps(
                                              color: AppColors.criticalRed,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: _columns
                                            .asMap()
                                            .entries
                                            .map((entry) {
                                          final idx = entry.key;
                                          final col = entry.value;
                                          final colCards = cards
                                              .where(
                                                (card) => card.columnKey == col.key,
                                              )
                                              .toList();
                                          return Container(
                                            width: 300,
                                            margin: EdgeInsets.only(
                                              right: idx < _columns.length - 1
                                                  ? 16
                                                  : 0,
                                            ),
                                            child: _buildColumn(col, colCards),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
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

  Widget _buildError(String message) {
    return Center(
      child: Text(
        message,
        style: AppTextStyles.technical(color: AppColors.error),
      ),
    );
  }

  Widget _buildColumn(_KanbanColumnMeta col, List<_TaskCardData> cards) {
    final color = _columnColor(col.key);
    return DragTarget<_TaskCardData>(
      onWillAcceptWithDetails: (details) =>
          details.data.task.status != _statusFromColumn(col.key),
      onAcceptWithDetails: (details) async {
        await _moveTask(details.data.task.id, _statusFromColumn(col.key));
      },
      builder: (context, candidateData, rejectedData) {
        final highlight = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: highlight
                ? color.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: highlight
                  ? color.withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.04),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.22)),
                ),
                child: Row(
                  children: [
                    Icon(col.icon, color: color, size: 16),
                    const SizedBox(width: 8),
                    Text(col.label, style: AppTextStyles.labelCaps(color: color)),
                    const Spacer(),
                    Text(
                      '${cards.length}',
                      style: AppTextStyles.technical(color: color).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              ...cards.map((c) => _buildCard(c)),
              if (cards.isEmpty)
                Container(
                  height: 74,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                  ),
                  child: Text(
                    'Drop tasks here',
                    style: AppTextStyles.technical(color: AppColors.outline),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCard(_TaskCardData card) {
    final urgency = _urgencyLabel(card.need?.urgencyScore ?? 0);
    final urgencyColor = _urgencyColorFromScore(card.need?.urgencyScore ?? 0);

    return Draggable<_TaskCardData>(
      data: card,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: 280, child: _buildCardContent(card, urgency, urgencyColor)),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: _buildCardContent(card, urgency, urgencyColor),
      ),
      child: _buildCardContent(card, urgency, urgencyColor)
          .animate()
          .fade(duration: 220.ms),
    );
  }

  Widget _buildCardContent(
    _TaskCardData card,
    String urgency,
    Color urgencyColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: urgencyColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    urgency.toUpperCase(),
                    style: AppTextStyles.labelCaps(color: urgencyColor)
                        .copyWith(fontSize: 9),
                  ),
                ),
                const Spacer(),
                Text(
                  _elapsed(card.task.assignedAt),
                  style: AppTextStyles.technical(color: AppColors.outline)
                      .copyWith(fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              card.need?.title.isNotEmpty == true
                  ? card.need!.title
                  : (card.task.title ?? 'Need #${card.task.needId}'),
              style: AppTextStyles.bodyMd().copyWith(
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 14, color: AppColors.onSurfaceVar),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    card.volunteer?.name.isNotEmpty == true
                        ? card.volunteer!.name
                        : 'Unassigned',
                    style: AppTextStyles.technical(color: AppColors.onSecContainer)
                        .copyWith(fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _moveTask(String taskId, String status) async {
    try {
      await FirebaseService.instance.updateTaskStatus(taskId, status);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
          content: Text('Failed to update task: $e'),
        ),
      );
    }
  }

  String _statusFromColumn(String key) {
    switch (key) {
      case 'unassigned':
        return 'unassigned';
      case 'matched':
        return 'matched';
      case 'in_progress':
        return 'in_progress';
      case 'completed':
        return 'completed';
      default:
        return 'unassigned';
    }
  }

  Color _columnColor(String key) {
    switch (key) {
      case 'unassigned':
        return AppColors.criticalRed;
      case 'matched':
        return AppColors.warningAmber;
      case 'in_progress':
        return AppColors.primary;
      case 'completed':
        return AppColors.safeGreen;
      default:
        return AppColors.outline;
    }
  }

  String _elapsed(DateTime? assignedAt) {
    if (assignedAt == null) return 'now';
    final diff = DateTime.now().difference(assignedAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  String _urgencyLabel(double score) {
    if (score >= 70) return 'Critical';
    if (score >= 40) return 'High';
    return 'Normal';
  }

  Color _urgencyColorFromScore(double score) {
    if (score >= 70) return AppColors.criticalRed;
    if (score >= 40) return AppColors.warningAmber;
    return AppColors.safeGreen;
  }
}

class _TaskCardData {
  const _TaskCardData({
    required this.task,
    required this.need,
    required this.volunteer,
  });

  final TaskAssignment task;
  final NeedReport? need;
  final Volunteer? volunteer;

  String get columnKey {
    switch (task.status) {
      case 'matched':
        return 'matched';
      case 'in_progress':
        return 'in_progress';
      case 'completed':
        return 'completed';
      default:
        return 'unassigned';
    }
  }
}

class _KanbanColumnMeta {
  const _KanbanColumnMeta({
    required this.key,
    required this.label,
    required this.icon,
  });

  final String key;
  final String label;
  final IconData icon;
}

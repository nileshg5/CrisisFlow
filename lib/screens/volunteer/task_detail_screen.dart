import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../core/mock_data.dart';
import '../../widgets/shared/glass_card.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late final task = mockTasks.firstWhere((t) => t.id == widget.taskId, orElse: () => mockTasks.first);
  bool _isStarted = false;
  final Set<int> _checkedItems = {};

  @override
  void initState() {
    super.initState();
    _isStarted = task.status == 'in_progress';
  }

  void _toggleStart() {
    setState(() => _isStarted = !_isStarted);
  }

  bool get _canComplete => _isStarted && _checkedItems.length == task.checklist.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120), // space for bottom bar
            child: Column(
              children: [
                // Nav layer
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05)),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => context.go('/volunteer/home'),
                      ),
                      const SizedBox(width: 8),
                      Text('CRISIS_COMMAND', style: AppTextStyles.h1().copyWith(fontSize: 20)),
                      const Spacer(),
                      IconButton(icon: const Icon(Icons.notifications_none, color: Colors.white), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.account_circle, color: Colors.white), onPressed: () {}),
                    ],
                  ),
                ),
                
                // Hero / Map Banner — local widget, no network required
                _HeroMapBanner(task: task).animate().fade(duration: 400.ms),

                // Content Grid
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 8,
                            child: Column(
                              children: [
                                GlassCard(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Detailed Instructions', style: AppTextStyles.h3()),
                                      const SizedBox(height: 16),
                                      Text(task.instructions ?? '', style: AppTextStyles.bodyLg(color: AppColors.onSurfaceVar)),
                                      const SizedBox(height: 24),
                                      Row(
                                        children: [
                                          Expanded(child: _buildInfoBox(Icons.location_on, 'DROP-OFF POINT', task.dropOffPoint ?? '')),
                                          const SizedBox(width: 16),
                                          Expanded(child: _buildInfoBox(Icons.schedule, 'ETA DEADLINE', task.etaDeadline ?? '')),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                GlassCard(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Resource Checklist', style: AppTextStyles.h3()),
                                      const SizedBox(height: 16),
                                      ListView.separated(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: task.checklist.length,
                                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                                        itemBuilder: (context, index) {
                                          final isChecked = _checkedItems.contains(index);
                                          return InkWell(
                                            onTap: () {
                                              setState(() {
                                                if (isChecked) {
                                                  _checkedItems.remove(index);
                                                } else {
                                                  _checkedItems.add(index);
                                                }
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.03),
                                                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(isChecked ? Icons.check_box : Icons.check_box_outline_blank, color: isChecked ? AppColors.primary : AppColors.outlineVariant),
                                                  const SizedBox(width: 16),
                                                  Expanded(child: Text(task.checklist[index], style: AppTextStyles.bodyMd())),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 4,
                            child: Column(
                              children: [
                                GlassCard(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('On-Site Contact', style: AppTextStyles.h3()),
                                      const SizedBox(height: 24),
                                      Row(
                                        children: [
                                          Container(
                                            width: 48, height: 48,
                                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 2), color: AppColors.surfaceVariant),
                                            child: const Icon(Icons.person, color: AppColors.onSurfaceVar),
                                          ),
                                          const SizedBox(width: 16),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(task.contactName ?? '', style: AppTextStyles.bodyMd().copyWith(fontWeight: FontWeight.bold)),
                                              Text(task.contactRole ?? '', style: AppTextStyles.technical(color: AppColors.onSurfaceVar)),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.background, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(vertical: 16)),
                                          onPressed: () {},
                                          icon: const Icon(Icons.call, size: 18),
                                          label: Text('CALL COORDINATOR', style: AppTextStyles.labelCaps().copyWith(fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: BorderSide(color: Colors.white.withValues(alpha: 0.2)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(vertical: 16)),
                                          onPressed: () {},
                                          icon: const Icon(Icons.chat_bubble_outline, size: 18),
                                          label: Text('SECURE MESSAGE', style: AppTextStyles.labelCaps().copyWith(fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                GlassCard(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Hazards & Intel', style: AppTextStyles.h3()),
                                      const SizedBox(height: 16),
                                      ...task.hazards.map((h) => Padding(
                                        padding: const EdgeInsets.only(bottom: 16),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Icon(Icons.warning_amber, color: AppColors.error, size: 20),
                                            const SizedBox(width: 12),
                                            Expanded(child: Text(h, style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVar))),
                                          ],
                                        ),
                                      )),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Fixed Bottom Action Bar
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              height: 96,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 30, offset: Offset(0, -10))],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: BorderSide(color: Colors.white.withValues(alpha: 0.1)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 16)),
                          onPressed: () {},
                          icon: const Icon(Icons.check_circle_outline),
                          label: Text('ACCEPT', style: AppTextStyles.labelCaps().copyWith(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: _isStarted ? AppColors.surfaceVariant : AppColors.primary, foregroundColor: _isStarted ? AppColors.outline : AppColors.background, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 16)),
                          onPressed: _isStarted ? null : _toggleStart,
                          icon: Icon(_isStarted ? Icons.sync : Icons.play_arrow),
                          label: Text(_isStarted ? 'IN PROGRESS' : 'START TASK', style: AppTextStyles.labelCaps().copyWith(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _canComplete ? AppColors.primary : AppColors.outlineVariant, 
                            side: BorderSide(color: Colors.white.withValues(alpha: _canComplete ? 0.3 : 0.05)), 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: _canComplete ? () { context.go('/volunteer/home'); } : null,
                          icon: const Icon(Icons.task_alt),
                          label: Text('COMPLETE', style: AppTextStyles.labelCaps().copyWith(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.labelCaps(color: AppColors.onSecContainer)),
                const SizedBox(height: 4),
                Text(value, style: AppTextStyles.bodyMd()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Inline hero map banner — no network needed ────────────────────────────────
class _HeroMapBanner extends StatelessWidget {
  final dynamic task;
  const _HeroMapBanner({required this.task});

  Color get _urgencyColor {
    switch ((task.urgency as String? ?? '').toLowerCase()) {
      case 'critical': return AppColors.criticalRed;
      case 'medium':   return AppColors.warningAmber;
      default:         return AppColors.safeGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      width: double.infinity,
      child: Stack(
        children: [
          // Grid background
          Positioned.fill(
            child: Container(
              color: const Color(0xFF080C0C),
              child: CustomPaint(painter: _MapGridPainter()),
            ),
          ),
          // Heat blob at task location
          Positioned(
            left: 260, top: 60,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_urgencyColor.withValues(alpha: 0.4), _urgencyColor.withValues(alpha: 0)],
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(1, 1), end: const Offset(1.12, 1.12), duration: 2.seconds),
          ),
          // Gradient overlay
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [AppColors.background, Colors.transparent],
                ),
              ),
            ),
          ),
          // Text overlay
          Positioned(
            bottom: 24, left: 32, right: 32,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _urgencyColor.withValues(alpha: 0.15),
                        border: Border.all(color: _urgencyColor.withValues(alpha: 0.4)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text((task.urgency ?? '').toUpperCase(),
                          style: AppTextStyles.labelCaps(color: _urgencyColor).copyWith(fontSize: 10)),
                    ),
                    const SizedBox(width: 12),
                    Text('REF: ${task.ref ?? ''}',
                        style: AppTextStyles.technical(color: AppColors.onSurfaceVar)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(task.title ?? '',
                    style: AppTextStyles.h2().copyWith(height: 1.2),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 0.5;
    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override bool shouldRepaint(_) => false;
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../core/mock_data.dart';
import '../../models/need_report.dart';
import '../../models/volunteer.dart';
import '../../widgets/shared/glass_card.dart';

class NeedDetailPanel extends StatefulWidget {
  final NeedReport need;
  final VoidCallback onClose;
  final VoidCallback? onNotify;

  const NeedDetailPanel({
    super.key,
    required this.need,
    required this.onClose,
    this.onNotify,
  });

  @override
  State<NeedDetailPanel> createState() => _NeedDetailPanelState();
}

class _NeedDetailPanelState extends State<NeedDetailPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _scoreController;
  late Animation<double> _scoreAnimation;

  // Match factor weights per spec
  static const List<Map<String, dynamic>> _factors = [
    {'label': 'Skill Match',   'weight': 0.35, 'value': 0.97},
    {'label': 'Proximity',     'weight': 0.25, 'value': 0.90},
    {'label': 'Availability',  'weight': 0.20, 'value': 1.00},
    {'label': 'Reliability',   'weight': 0.10, 'value': 0.85},
    {'label': 'Workload',      'weight': 0.10, 'value': 0.70},
  ];

  @override
  void initState() {
    super.initState();
    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _scoreAnimation = Tween<double>(
      begin: 0,
      end: widget.need.urgencyScore,
    ).animate(CurvedAnimation(parent: _scoreController, curve: Curves.easeOutExpo));
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _scoreController.forward();
    });
  }

  @override
  void dispose() {
    _scoreController.dispose();
    super.dispose();
  }

  Color get _urgencyColor {
    final s = widget.need.urgencyScore;
    if (s >= 8) return AppColors.criticalRed;
    if (s >= 5) return AppColors.warningAmber;
    return AppColors.safeGreen;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 520,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(left: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 20, 20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 18),
                  onPressed: widget.onClose,
                  tooltip: 'Close panel',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ID ${widget.need.crisisId ?? ''}',
                        style: AppTextStyles.labelCaps(color: AppColors.onSecContainer),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.need.title,
                        style: AppTextStyles.bodyMd().copyWith(fontWeight: FontWeight.w600, height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _urgencyPill(),
              ],
            ),
          ),

          // ── Scrollable content ───────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // AI Urgency Score Card
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('AI URGENCY RATING', style: AppTextStyles.labelCaps(color: AppColors.onSecContainer)),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _urgencyColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.psychology, color: _urgencyColor, size: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Animated score
                      AnimatedBuilder(
                        animation: _scoreAnimation,
                        builder: (_, __) => Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              _scoreAnimation.value.toStringAsFixed(1),
                              style: AppTextStyles.h1().copyWith(
                                fontSize: 52,
                                color: _urgencyColor,
                                shadows: [Shadow(color: _urgencyColor.withValues(alpha: 0.4), blurRadius: 24)],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text('/ 10', style: AppTextStyles.h3(color: AppColors.onSecContainer)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Score bar
                      AnimatedBuilder(
                        animation: _scoreAnimation,
                        builder: (_, __) => ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _scoreAnimation.value / 10,
                            minHeight: 6,
                            backgroundColor: Colors.white.withValues(alpha: 0.08),
                            valueColor: AlwaysStoppedAnimation(_urgencyColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Core analysis
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.terminal, size: 14, color: AppColors.onSecContainer),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.need.aiReason ?? '',
                                style: AppTextStyles.technical(color: AppColors.onBackground).copyWith(height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fade(delay: 100.ms).slideY(begin: 0.05),

                const SizedBox(height: 16),

                // Scoring factor breakdown
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SCORING FACTORS', style: AppTextStyles.labelCaps(color: AppColors.onSecContainer)),
                      const SizedBox(height: 16),
                      ..._factors.asMap().entries.map((e) {
                        final i = e.key;
                        final f = e.value;
                        final pct = ((f['value'] as double) * 100).round();
                        final wt = ((f['weight'] as double) * 100).round();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(f['label'] as String, style: AppTextStyles.bodyMd()),
                                  Row(
                                    children: [
                                      Text('$pct%', style: AppTextStyles.technical(color: AppColors.primary).copyWith(fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 6),
                                      Text('(wt $wt%)', style: AppTextStyles.technical(color: AppColors.onSecContainer).copyWith(fontSize: 10)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: f['value'] as double,
                                  minHeight: 4,
                                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                                  valueColor: AlwaysStoppedAnimation(AppColors.primary.withValues(alpha: 0.7)),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fade(delay: Duration(milliseconds: 200 + i * 80)).slideX(begin: 0.05);
                      }),
                    ],
                  ),
                ).animate().fade(delay: 200.ms).slideY(begin: 0.05),

                const SizedBox(height: 16),

                // Operational notes
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('OPERATIONAL NOTES', style: AppTextStyles.labelCaps(color: AppColors.onSecContainer)),
                          GestureDetector(
                            onTap: () {},
                            child: Row(
                              children: [
                                const Icon(Icons.add, size: 14, color: Colors.white54),
                                const SizedBox(width: 4),
                                Text('Add Note', style: AppTextStyles.technical(color: Colors.white54).copyWith(fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '"${widget.need.notes ?? ''}"',
                        style: AppTextStyles.bodyMd(color: AppColors.onBackground.withValues(alpha: 0.8))
                            .copyWith(fontStyle: FontStyle.italic, height: 1.5),
                      ),
                      const SizedBox(height: 12),
                      Divider(color: Colors.white.withValues(alpha: 0.05)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 24, height: 24,
                            decoration: const BoxDecoration(color: AppColors.surfaceVariant, shape: BoxShape.circle),
                            child: const Icon(Icons.person, size: 14, color: AppColors.onSurfaceVar),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${widget.need.reporterName ?? 'Unknown'}  ·  ${widget.need.reportedMinutesAgo ?? 0}m ago',
                            style: AppTextStyles.technical(color: AppColors.onSecContainer).copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fade(delay: 300.ms).slideY(begin: 0.05),

                const SizedBox(height: 16),

                // Recommended Volunteers
                Row(
                  children: [
                    const Icon(Icons.group, size: 14, color: AppColors.onSecContainer),
                    const SizedBox(width: 8),
                    Text('RECOMMENDED VOLUNTEERS', style: AppTextStyles.labelCaps(color: AppColors.onSecContainer)),
                  ],
                ).animate().fade(delay: 380.ms),
                const SizedBox(height: 12),
                ...mockVolunteers.take(3).toList().asMap().entries.map((e) {
                  return _buildVolunteerCard(e.value, e.key).animate()
                      .fade(delay: Duration(milliseconds: 420 + e.key * 80))
                      .slideY(begin: 0.05);
                }),

                const SizedBox(height: 80),
              ],
            ),
          ),

          // ── Footer CTA ───────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.background,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    // TODO(backend): trigger Cloud Function + FCM push notification
                    onPressed: widget.onNotify ?? widget.onClose,
                    icon: const Icon(Icons.bolt, size: 18),
                    label: Text('NOTIFY & ASSIGN', style: AppTextStyles.labelCaps(color: AppColors.background).copyWith(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'BROADCASTS TO TOP-MATCHED RESPONDERS',
                  style: AppTextStyles.technical(color: AppColors.onSecContainer).copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _urgencyPill() {
    final label = widget.need.urgencyLabel.toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _urgencyColor.withValues(alpha: 0.12),
        border: Border.all(color: _urgencyColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: AppTextStyles.labelCaps(color: _urgencyColor).copyWith(fontSize: 10)),
    );
  }

  Widget _buildVolunteerCard(Volunteer v, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar + match badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: AppColors.surfaceVariant,
                  ),
                  child: const Icon(Icons.person, color: AppColors.onSurfaceVar, size: 28),
                ),
                Positioned(
                  bottom: -4, right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${v.matchScore}%',
                      style: AppTextStyles.technical(color: AppColors.background).copyWith(fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(v.name, style: AppTextStyles.bodyMd().copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text('${v.distanceKm} km', style: AppTextStyles.technical(color: AppColors.onSecContainer).copyWith(fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: v.skills.map((s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(s, style: AppTextStyles.technical(color: AppColors.outline).copyWith(fontSize: 10)),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

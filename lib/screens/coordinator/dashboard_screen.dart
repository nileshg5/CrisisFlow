import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme.dart';
import '../../models/need_report.dart';
import '../../models/task_assignment.dart';
import '../../models/volunteer.dart';
import '../../services/firebase_service.dart';
import '../../services/gemini_service.dart';
import '../../widgets/shared/side_nav.dart';
import '../../widgets/shared/top_nav.dart';
import '../../widgets/shared/glass_card.dart';
import 'need_detail_panel.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const LatLng _indiaCenter = LatLng(20.5937, 78.9629);
  final _tileProvider = CancellableNetworkTileProvider();

  NeedReport? _selectedNeed;
  bool _alertDismissed = false;

  void _openDetail(NeedReport need) => setState(() => _selectedNeed = need);
  void _closeDetail() => setState(() => _selectedNeed = null);

  void _notifyAndAssign() {
    setState(() => _selectedNeed = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 32, right: 32, left: 32),
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppColors.safeGreen.withValues(alpha: 0.3)),
        ),
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.safeGreen.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.safeGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Responders Notified',
                    style: AppTextStyles.bodyMd()
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Top 3 matched volunteers have been dispatched.',
                    style: AppTextStyles.technical(
                      color: AppColors.onSurfaceVar,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const SideNav(activeRoute: '/coordinator/dashboard'),
          Expanded(
            child: Stack(
              children: [
                Column(
                  children: [
                    const TopNav(title: 'Coordinator Dashboard'),
                    if (!_alertDismissed) _buildAlertBanner(),
                    Expanded(
                      child: StreamBuilder<List<NeedReport>>(
                        stream: FirebaseService.instance.watchNeeds(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Failed to load needs: ${snapshot.error}',
                                style: AppTextStyles.technical(
                                  color: AppColors.error,
                                ),
                              ),
                            );
                          }

                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            );
                          }

                          final needs =
                              List<NeedReport>.from(snapshot.data ?? [])
                                ..sort(
                                  (a, b) => b.urgencyScore.compareTo(
                                    a.urgencyScore,
                                  ),
                                );

                          return Padding(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildStatsRow(needs)
                                    .animate()
                                    .fade(duration: 500.ms)
                                    .slideY(begin: 0.08),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: Column(
                                    children: [
                                       Expanded(
                                        flex: 65,
                                        child: _buildMapArea(needs)
                                            .animate()
                                            .fade(delay: 200.ms)
                                            .slideY(begin: 0.04),
                                       ),
                                       const SizedBox(height: 16),
                                       Expanded(
                                        flex: 35,
                                        child: _buildQueueArea(needs)
                                            .animate()
                                            .fade(delay: 300.ms)
                                            .slideY(begin: 0.04),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildResourceArea(needs)
                                    .animate()
                                    .fade(delay: 400.ms)
                                    .slideY(begin: 0.08),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                if (_selectedNeed != null) ...[
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: _closeDetail,
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.45),
                      ).animate().fade(duration: 200.ms),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: 0,
                    child: NeedDetailPanel(
                      need: _selectedNeed!,
                      onClose: _closeDetail,
                      onNotify: _notifyAndAssign,
                    ).animate().slideX(
                          begin: 1.0,
                          curve: Curves.easeOutCubic,
                          duration: 380.ms,
                        ),
                  ),
                ],
                Positioned(
                  right: 20,
                  bottom: 20,
                  child: _SeedButton(onSeed: _seedDemoData),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.criticalRed.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(
            color: AppColors.criticalRed.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.criticalRed,
            size: 18,
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fade(begin: 0.5, end: 1.0, duration: 800.ms),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: AppTextStyles.technical(),
                children: const [
                  TextSpan(
                    text: 'SPIKE ALERT  ',
                    style: TextStyle(
                      color: AppColors.criticalRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(text: 'Food insecurity reports from Dharavi up '),
                  TextSpan(
                    text: '+40% WoW',
                    style: TextStyle(
                      color: AppColors.warningAmber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(text: '. Emerging crisis zone detected.'),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _alertDismissed = true),
            child: Text(
              'DISMISS',
              style: AppTextStyles.labelCaps(color: AppColors.outline)
                  .copyWith(fontSize: 10),
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: -1.0, duration: 400.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildStatsRow(List<NeedReport> needs) {
    final resolvedCount = needs
        .where((n) => n.status == 'resolved' || n.status == 'completed')
        .length;
    final total = needs.length;
    final matchRate = total == 0 ? 0 : ((resolvedCount / total) * 100).round();

    return StreamBuilder<List<Volunteer>>(
      stream: FirebaseService.instance.watchVolunteers(),
      builder: (context, snapshot) {
        final volunteers = snapshot.data ?? const <Volunteer>[];
        final availableVolunteers =
            volunteers.where((v) => v.isAvailable).length;

        final stats = [
          {
            'label': 'NEEDS RESOLVED',
            'value': '$resolvedCount',
            'sub': '$total total reports',
            'icon': Icons.check_circle_outline,
          },
          {
            'label': 'ACTIVE VOLUNTEERS',
            'value': '$availableVolunteers',
            'sub': 'Real-time availability',
            'icon': Icons.bolt,
          },
          {
            'label': 'MATCH RATE',
            'value': '$matchRate%',
            'sub': 'Resolved / total needs',
            'icon': Icons.analytics_outlined,
          },
        ];

        return Row(
          children: stats.asMap().entries.map((entry) {
            final index = entry.key;
            final stat = entry.value;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  right: index < stats.length - 1 ? 16 : 0,
                ),
                child: GlassCard(
                  padding: const EdgeInsets.all(22),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stat['label']! as String,
                              style: AppTextStyles.labelCaps(
                                color: AppColors.onSecContainer,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              stat['value']! as String,
                              style: AppTextStyles.h2(),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              stat['sub']! as String,
                              style: AppTextStyles.technical(
                                color: AppColors.safeGreen,
                              ).copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        stat['icon']! as IconData,
                        size: 40,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildMapArea(List<NeedReport> needs) {
    final markers = _buildNeedMarkers(needs);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REGIONAL_SCAN_V4.2',
                      style: AppTextStyles.technical().copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _legendDot(AppColors.criticalRed),
                        const SizedBox(width: 6),
                        Text(
                          'Urgency 70+',
                          style: AppTextStyles.technical(
                            color: AppColors.onSecContainer,
                          ).copyWith(fontSize: 11),
                        ),
                        const SizedBox(width: 14),
                        _legendDot(AppColors.warningAmber),
                        const SizedBox(width: 6),
                        Text(
                          'Urgency 40+',
                          style: AppTextStyles.technical(
                            color: AppColors.onSecContainer,
                          ).copyWith(fontSize: 11),
                        ),
                        const SizedBox(width: 14),
                        _legendDot(AppColors.safeGreen),
                        const SizedBox(width: 6),
                        Text(
                          'Under 40',
                          style: AppTextStyles.technical(
                            color: AppColors.onSecContainer,
                          ).copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.safeGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.safeGreen.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.safeGreen,
                              shape: BoxShape.circle,
                            ),
                          )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .fade(begin: 0.4, end: 1.0, duration: 900.ms),
                          const SizedBox(width: 6),
                          Text(
                            'LIVE NEED MARKERS',
                            style: AppTextStyles.labelCaps(
                              color: AppColors.safeGreen,
                            ).copyWith(fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Expand map',
                      onPressed: () => _openExpandedMap(needs),
                      icon: const Icon(
                        Icons.open_in_full,
                        size: 18,
                        color: AppColors.onSurfaceVar,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: FlutterMap(
                  options: const MapOptions(
                    initialCenter: _indiaCenter,
                    initialZoom: 5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      tileProvider: _tileProvider,
                    ),
                    MarkerLayer(markers: markers),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color c) =>
      Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle));

  Future<void> _openExpandedMap(List<NeedReport> needs) async {
    final markers = _buildNeedMarkers(needs);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppColors.surfaceLow,
          insetPadding: const EdgeInsets.all(24),
          child: SizedBox(
            width: 1200,
            height: 700,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                  child: Row(
                    children: [
                      Text('LIVE MAP (EXPANDED)', style: AppTextStyles.h3()),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Back to dashboard',
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(
                          Icons.close_fullscreen,
                          color: AppColors.onSurfaceVar,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.outlineVariant),
                Expanded(
                  child: FlutterMap(
                    options: const MapOptions(
                      initialCenter: _indiaCenter,
                      initialZoom: 5,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        tileProvider: _tileProvider,
                      ),
                      MarkerLayer(markers: markers),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQueueArea(List<NeedReport> needs) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Priority Queue', style: AppTextStyles.h3()),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.criticalRed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${needs.length} UNRESOLVED',
                    style: AppTextStyles.labelCaps(color: AppColors.criticalRed)
                        .copyWith(fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: needs.isEmpty
                ? Center(
                    child: Text(
                      'No live needs found.',
                      style: AppTextStyles.technical(color: AppColors.outline),
                    ),
                  )
                : ListView.builder(
                    itemCount: needs.length,
                    itemBuilder: (context, index) => _buildQueueItem(needs[index]),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {},
                child: Text(
                  'VIEW ALL PENDING NEEDS',
                  style: AppTextStyles.labelCaps(color: AppColors.outline)
                      .copyWith(fontSize: 10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueItem(NeedReport n) {
    final borderColor = _urgencyColor(n.urgencyScore);
    final category = n.needType.isEmpty ? (n.category ?? 'need') : n.needType;

    return InkWell(
      onTap: () => _openDetail(n),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: borderColor, width: 3),
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${category.toUpperCase()} / ${n.urgencyLabel.toUpperCase()}',
                  style: AppTextStyles.labelCaps(color: borderColor)
                      .copyWith(fontSize: 9),
                ),
                const Spacer(),
                Text(
                  n.timeAgo ?? _formatReportedTime(n),
                  style: AppTextStyles.technical(color: AppColors.outline)
                      .copyWith(fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              n.title,
              style: AppTextStyles.bodyMd().copyWith(fontSize: 13, height: 1.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ...n.assignedInitials.take(2).map(
                      (init) => Container(
                        width: 22,
                        height: 22,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceVariant,
                          border: Border.all(
                            color: AppColors.background,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            init,
                            style: AppTextStyles.technical().copyWith(fontSize: 8),
                          ),
                        ),
                      ),
                    ),
                const Spacer(),
                Text(
                  n.actionLabel ?? 'VIEW DETAILS',
                  style: AppTextStyles.labelCaps(color: AppColors.primary)
                      .copyWith(fontSize: 9),
                ),
                const Icon(Icons.chevron_right, size: 14, color: AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceArea(List<NeedReport> needs) {
    final totalNeeds = needs.isEmpty ? 1 : needs.length;
    final medical = needs.where((n) => n.needType == 'medical').length;
    final foodWater =
        needs.where((n) => n.needType == 'food' || n.needType == 'water').length;
    final shelter = needs.where((n) => n.needType == 'shelter').length;
    final commSupport = needs
        .where((n) => n.needType == 'safety' || n.needType == 'education')
        .length;

    final resources = [
      {'label': 'MEDICAL_UNITS', 'value': medical / totalNeeds},
      {'label': 'FOOD_&_WATER', 'value': foodWater / totalNeeds},
      {'label': 'SHELTER_ASSETS', 'value': shelter / totalNeeds},
      {'label': 'COMM_NODES', 'value': commSupport / totalNeeds},
    ];

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Resource Allocation', style: AppTextStyles.h3()),
                  Text(
                    'REAL-TIME TELEMETRY / ASSET TRACKING',
                    style: AppTextStyles.labelCaps(
                      color: AppColors.onSecContainer,
                    ).copyWith(fontSize: 9),
                  ),
                ],
              ),
              const Spacer(),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onPressed: () {},
                child: Text(
                  'GENERATE REPORT',
                  style: AppTextStyles.labelCaps().copyWith(fontSize: 10),
                ),
              ),
            ],
          ),
           const SizedBox(height: 24),
           Row(
            children: resources.map((r) {
              final pct = ((r['value'] as double) * 100).round();
              Color barColor;
              if (pct > 70) {
                barColor = AppColors.primary;
              } else if (pct > 40) {
                barColor = AppColors.warningAmber;
              } else {
                barColor = AppColors.criticalRed;
              }
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r['label'] as String,
                        style: AppTextStyles.labelCaps(
                          color: AppColors.onSecContainer,
                        ).copyWith(fontSize: 9),
                      ),
                      const SizedBox(height: 6),
                      Text('$pct%', style: AppTextStyles.h3(color: barColor)),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: r['value'] as double,
                          minHeight: 4,
                          backgroundColor: Colors.white.withValues(alpha: 0.06),
                          valueColor: AlwaysStoppedAnimation(barColor),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<Marker> _buildNeedMarkers(List<NeedReport> needs) {
    return needs
        .where((need) => need.geoLocation != null)
        .map((need) {
          final point = need.geoLocation!;
          return Marker(
            point: LatLng(point.latitude, point.longitude),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () => _showNeedBottomSheet(need),
              child: Icon(
                Icons.location_on,
                color: _urgencyColor(need.urgencyScore),
                size: 32,
              ),
            ),
          );
        })
        .toList();
  }

  Color _urgencyColor(double urgencyScore) {
    if (urgencyScore >= 70) return AppColors.criticalRed;
    if (urgencyScore >= 40) return AppColors.warningAmber;
    return AppColors.safeGreen;
  }

  Future<void> _showNeedBottomSheet(NeedReport need) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(need.title, style: AppTextStyles.h3()),
              const SizedBox(height: 8),
              Text(
                need.description.isEmpty ? 'No description available.' : need.description,
                style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVar),
              ),
              const SizedBox(height: 10),
              Text(
                'Urgency: ${need.urgencyScore.toStringAsFixed(0)} • '
                'Affected: ${need.affectedCount}',
                style: AppTextStyles.technical(color: AppColors.outline),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                  ),
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    await _matchVolunteersForNeed(need);
                  },
                  child: Text(
                    'Match Volunteers',
                    style: AppTextStyles.labelCaps(color: AppColors.background),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _matchVolunteersForNeed(NeedReport need) async {
    try {
      final volunteers = await FirebaseService.instance.watchVolunteers().first;
      final ranked = await GeminiService.matchVolunteers(
        _needToGeminiMap(need),
        volunteers.map(_volunteerToGeminiMap).toList(),
      );
      final top3 = ranked.take(3).toList();

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text('Top Volunteer Matches', style: AppTextStyles.h3()),
            content: SizedBox(
              width: 420,
              child: top3.isEmpty
                  ? Text(
                      'No matches returned.',
                      style: AppTextStyles.technical(color: AppColors.outline),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: top3.map((match) {
                        final volunteerId = '${match['volunteerId'] ?? ''}';
                        final matchScore = '${match['matchScore'] ?? ''}';
                        final matchReason = '${match['matchReason'] ?? ''}';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$volunteerId • Score $matchScore',
                                style: AppTextStyles.bodyMd().copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                matchReason,
                                style: AppTextStyles.technical(
                                  color: AppColors.onSurfaceVar,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  'Close',
                  style: AppTextStyles.labelCaps(color: AppColors.primary),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
          content: Text(
            'Volunteer matching failed: $e',
            style: AppTextStyles.technical(),
          ),
        ),
      );
    }
  }

  Map<String, dynamic> _needToGeminiMap(NeedReport need) {
    return {
      'id': need.id,
      'title': need.title,
      'description': need.description,
      'needType': need.needType.isEmpty ? (need.category ?? '') : need.needType,
      'urgencyScore': need.urgencyScore,
      'urgencyLabel': need.urgencyLabel,
      'affectedCount': need.affectedCount,
      'location': need.location,
      'status': need.status,
      'tags': need.geminiTags,
    };
  }

  Map<String, dynamic> _volunteerToGeminiMap(Volunteer volunteer) {
    return {
      'id': volunteer.id,
      'name': volunteer.name,
      'skills': volunteer.skills,
      'address': volunteer.address,
      'isAvailable': volunteer.isAvailable,
      'languages': volunteer.languages,
      'reliabilityScore': volunteer.reliabilityScore,
    };
  }

  String _formatReportedTime(NeedReport need) {
    if (need.reportedAt == null) return '';
    final diff = DateTime.now().difference(need.reportedAt!);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Future<void> _seedDemoData() async {
    try {
      final now = DateTime.now();
      final needs = <NeedReport>[
        NeedReport(
          id: 'seed_need_1',
          title: 'Emergency food kits needed',
          description: 'Families near Kurla station need dry ration kits.',
          needType: 'food',
          urgencyScore: 76,
          urgencyLabel: 'Critical',
          affectedCount: 120,
          location: 'Kurla, Mumbai',
          geoLocation: const GeoPoint(19.0728, 72.8826),
          status: 'pending',
          reportedAt: now,
          geminiTags: const ['food', 'families', 'ration'],
          reportedBy: 'seed',
        ),
        NeedReport(
          id: 'seed_need_2',
          title: 'Mobile clinic medicine shortage',
          description: 'Essential medicines and bandages running low.',
          needType: 'medical',
          urgencyScore: 82,
          urgencyLabel: 'Critical',
          affectedCount: 65,
          location: 'Dharavi, Mumbai',
          geoLocation: const GeoPoint(19.0380, 72.8570),
          status: 'pending',
          reportedAt: now,
          geminiTags: const ['medical', 'clinic'],
          reportedBy: 'seed',
        ),
        NeedReport(
          id: 'seed_need_3',
          title: 'Temporary shelter tarpaulins needed',
          description: 'Rain damage displaced several families overnight.',
          needType: 'shelter',
          urgencyScore: 58,
          urgencyLabel: 'High',
          affectedCount: 40,
          location: 'Sion, Mumbai',
          geoLocation: const GeoPoint(19.0477, 72.8645),
          status: 'pending',
          reportedAt: now,
          geminiTags: const ['shelter', 'rain'],
          reportedBy: 'seed',
        ),
        NeedReport(
          id: 'seed_need_4',
          title: 'Safe drinking water shortage',
          description: 'Tank supply disrupted in local settlement.',
          needType: 'water',
          urgencyScore: 44,
          urgencyLabel: 'High',
          affectedCount: 90,
          location: 'Chembur, Mumbai',
          geoLocation: const GeoPoint(19.0522, 72.9005),
          status: 'pending',
          reportedAt: now,
          geminiTags: const ['water', 'supply'],
          reportedBy: 'seed',
        ),
        NeedReport(
          id: 'seed_need_5',
          title: 'Child safety support request',
          description: 'Need volunteers for child-safe help desk and guidance.',
          needType: 'safety',
          urgencyScore: 38,
          urgencyLabel: 'Normal',
          affectedCount: 25,
          location: 'Ghatkopar, Mumbai',
          geoLocation: const GeoPoint(19.0856, 72.9081),
          status: 'pending',
          reportedAt: now,
          geminiTags: const ['safety', 'children'],
          reportedBy: 'seed',
        ),
      ];

      final volunteers = <Volunteer>[
        const Volunteer(
          id: 'volunteer_demo',
          name: 'Aarav Mehta',
          skills: ['Medical', 'First Aid'],
          address: 'Dadar, Mumbai',
          isAvailable: true,
          phone: '+91-900000001',
          reliabilityScore: 86,
        ),
        const Volunteer(
          id: 'seed_vol_2',
          name: 'Nisha Sharma',
          skills: ['Food Distribution', 'Logistics'],
          address: 'Kurla, Mumbai',
          isAvailable: true,
          phone: '+91-900000002',
          reliabilityScore: 79,
        ),
        const Volunteer(
          id: 'seed_vol_3',
          name: 'Rahul Iyer',
          skills: ['Shelter', 'Transport'],
          address: 'Sion, Mumbai',
          isAvailable: false,
          phone: '+91-900000003',
          reliabilityScore: 72,
        ),
      ];

      for (final n in needs) {
        await FirebaseService.instance.addNeed(n);
      }
      for (final v in volunteers) {
        await FirebaseService.instance.addVolunteer(v);
      }

      final tasks = <TaskAssignment>[
        const TaskAssignment(
          id: 'seed_task_1',
          needId: 'seed_need_2',
          volunteerId: 'volunteer_demo',
          status: 'matched',
          notes: 'Prioritize medicine shipment.',
        ),
        const TaskAssignment(
          id: 'seed_task_2',
          needId: 'seed_need_1',
          volunteerId: 'seed_vol_2',
          status: 'in_progress',
          notes: 'Food kits en route.',
        ),
      ];

      for (final task in tasks) {
        await FirebaseService.instance.assignTask(task);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.safeGreen,
          content: Text(
            'Demo data seeded (5 needs, 3 volunteers).',
            style: AppTextStyles.technical(color: AppColors.background),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
          content: Text('Seeding failed: $e', style: AppTextStyles.technical()),
        ),
      );
    }
  }
}

// ── Seed Demo Data Button ─────────────────────────────────────────────────────
class _SeedButton extends StatefulWidget {
  final Future<void> Function() onSeed;
  const _SeedButton({required this.onSeed});

  @override
  State<_SeedButton> createState() => _SeedButtonState();
}

class _SeedButtonState extends State<_SeedButton> {
  bool _loading = false;
  bool _done = false;

  Future<void> _handleSeed() async {
    // Confirm before writing
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Seed Demo Data?', style: AppTextStyles.h3()),
        content: Text(
          'This will write 5 needs, 3 volunteers, and 2 tasks to Firestore.\n\n'
          'Run this only once — clicking again will overwrite existing seed data.',
          style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVar),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: AppTextStyles.labelCaps(color: AppColors.outline)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Seed Now', style: AppTextStyles.labelCaps(color: AppColors.background)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() { _loading = true; _done = false; });
    try {
      await widget.onSeed();
      if (mounted) setState(() { _loading = false; _done = true; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _loading
          ? const SizedBox(
              key: ValueKey('loading'),
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            )
          : ElevatedButton.icon(
              key: ValueKey(_done ? 'done' : 'idle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _done
                    ? AppColors.safeGreen
                    : AppColors.surface,
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: _done
                      ? AppColors.safeGreen
                      : Colors.white.withValues(alpha: 0.15),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: _done ? null : _handleSeed,
              icon: Icon(
                _done ? Icons.check_circle_outline : Icons.upload_rounded,
                size: 16,
              ),
              label: Text(
                _done ? 'Data Seeded!' : 'Seed Demo Data',
                style: AppTextStyles.labelCaps().copyWith(fontSize: 11),
              ),
            ),
    );
  }
}

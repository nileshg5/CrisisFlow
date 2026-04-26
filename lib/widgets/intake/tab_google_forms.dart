import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../core/mock_data.dart';
import '../../widgets/shared/glass_card.dart';

class TabGoogleForms extends StatefulWidget {
  const TabGoogleForms({super.key});

  @override
  State<TabGoogleForms> createState() => _TabGoogleFormsState();
}

class _TabGoogleFormsState extends State<TabGoogleForms> {
  bool _syncing = false;
  bool _synced = false;

  Future<void> _simulateSync() async {
    setState(() { _syncing = true; _synced = false; });
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() { _syncing = false; _synced = true; });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Connected form header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.assignment_outlined, color: Colors.blue, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Crisis Report Form — Region 7', style: AppTextStyles.bodyMd().copyWith(fontWeight: FontWeight.w600)),
                          Text('forms.google.com/d/1BxiM...  •  Auto-sync every 5 min', style: AppTextStyles.technical(color: AppColors.outline).copyWith(fontSize: 11)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Sync status badge
                    if (_syncing)
                      Row(
                        children: [
                          const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                          const SizedBox(width: 8),
                          Text('Syncing...', style: AppTextStyles.technical(color: AppColors.primary)),
                        ],
                      )
                    else if (_synced)
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppColors.safeGreen, size: 16),
                          const SizedBox(width: 6),
                          Text('Synced', style: AppTextStyles.technical(color: AppColors.safeGreen)),
                        ],
                      )
                    else
                      TextButton.icon(
                        onPressed: _simulateSync,
                        icon: const Icon(Icons.sync, size: 16, color: AppColors.primary),
                        label: Text('SYNC NOW', style: AppTextStyles.labelCaps(color: AppColors.primary).copyWith(fontSize: 11)),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Responses table header
                Row(
                  children: [
                    Text('LATEST RESPONSES', style: AppTextStyles.labelCaps(color: AppColors.onSecContainer)),
                    const Spacer(),
                    Text('${mockFormsResponses.length} total  •  ${mockFormsResponses.where((r) => r['isNew'] == true).length} new', style: AppTextStyles.technical(color: AppColors.outline)),
                  ],
                ),
                const SizedBox(height: 12),

                // Table header row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text('TIMESTAMP', style: AppTextStyles.labelCaps(color: AppColors.onSecContainer))),
                      Expanded(flex: 2, child: Text('LOCATION', style: AppTextStyles.labelCaps(color: AppColors.onSecContainer))),
                      Expanded(flex: 2, child: Text('NEED', style: AppTextStyles.labelCaps(color: AppColors.onSecContainer))),
                      Expanded(flex: 1, child: Text('COUNT', style: AppTextStyles.labelCaps(color: AppColors.onSecContainer))),
                      Expanded(flex: 1, child: Text('STATUS', style: AppTextStyles.labelCaps(color: AppColors.onSecContainer))),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Response rows
                ...mockFormsResponses.asMap().entries.map((e) {
                  final row = e.value;
                  final isNew = row['isNew'] == true;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isNew ? AppColors.primary.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isNew ? AppColors.primary.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: Text(row['timestamp'].toString(), style: AppTextStyles.technical())),
                        Expanded(flex: 2, child: Text(row['location'].toString(), style: AppTextStyles.technical())),
                        Expanded(flex: 2, child: Text(row['need'].toString(), style: AppTextStyles.technical())),
                        Expanded(flex: 1, child: Text(row['count'].toString(), style: AppTextStyles.technical(color: AppColors.primary))),
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isNew ? AppColors.primary.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isNew ? 'NEW' : 'LOGGED',
                              style: AppTextStyles.labelCaps(color: isNew ? AppColors.primary : AppColors.outline).copyWith(fontSize: 9),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fade(delay: Duration(milliseconds: e.key * 80)).slideY(begin: 0.05);
                }),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.upload),
                    label: Text('INGEST ${mockFormsResponses.where((r) => r['isNew'] == true).length} NEW RECORDS', style: AppTextStyles.labelCaps(color: AppColors.background).copyWith(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 3,
          child: GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CONNECTION', style: AppTextStyles.labelCaps(color: AppColors.onSecContainer)),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.link, 'Status', 'Connected', AppColors.safeGreen),
                _buildInfoRow(Icons.schedule, 'Last Sync', '4 min ago', null),
                _buildInfoRow(Icons.cloud_download, 'Total Pulled', '284 records', null),
                _buildInfoRow(Icons.pending_actions, 'Pending Ingest', '2 records', AppColors.warningAmber),
                const SizedBox(height: 20),
                Divider(color: Colors.white.withValues(alpha: 0.06)),
                const SizedBox(height: 16),
                Text('CONNECT NEW FORM', style: AppTextStyles.labelCaps(color: AppColors.onSecContainer)),
                const SizedBox(height: 12),
                TextField(
                  style: AppTextStyles.technical(),
                  decoration: InputDecoration(
                    hintText: 'Paste Google Form URL...',
                    hintStyle: AppTextStyles.technical(color: AppColors.outline),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.04),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {},
                    child: Text('CONNECT', style: AppTextStyles.labelCaps()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color? valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.outline),
          const SizedBox(width: 10),
          Text(label, style: AppTextStyles.technical(color: AppColors.onSurfaceVar)),
          const Spacer(),
          Text(value, style: AppTextStyles.technical(color: valueColor ?? AppColors.onBackground).copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

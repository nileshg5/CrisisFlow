import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../widgets/shared/side_nav.dart';
import '../../widgets/shared/top_nav.dart';
import '../../widgets/intake/tab_photo_ocr.dart';
import '../../widgets/intake/tab_csv_upload.dart';
import '../../widgets/intake/tab_google_forms.dart';
import '../../widgets/intake/tab_sms_gateway.dart';
import '../../widgets/intake/tab_manual_entry.dart';
import '../../widgets/intake/tab_voice_input.dart';

class IntakeHubScreen extends StatefulWidget {
  const IntakeHubScreen({super.key});

  @override
  State<IntakeHubScreen> createState() => _IntakeHubScreenState();
}

class _IntakeHubScreenState extends State<IntakeHubScreen> {
  int _activeTabIndex = 0;

  static const List<Map<String, dynamic>> _tabs = [
    {'icon': Icons.photo_camera_outlined,  'label': 'Photo OCR'},
    {'icon': Icons.table_chart_outlined,   'label': 'CSV Upload'},
    {'icon': Icons.assignment_outlined,    'label': 'Google Forms'},
    {'icon': Icons.chat_bubble_outline,    'label': 'SMS / WhatsApp'},
    {'icon': Icons.edit_note_outlined,     'label': 'Manual Entry'},
    {'icon': Icons.mic_none,               'label': 'Voice Input'},
  ];

  static const List<Widget> _tabWidgets = [
    TabPhotoOcr(),
    TabCsvUpload(),
    TabGoogleForms(),
    TabSmsGateway(),
    TabManualEntry(),
    TabVoiceInput(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const SideNav(activeRoute: '/coordinator/intake'),
          Expanded(
            child: Column(
              children: [
                const TopNav(title: 'Report Intake Hub'),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Text('Data Ingestion Engine', style: AppTextStyles.h2())
                            .animate().fade(duration: 400.ms).slideX(begin: -0.04),
                        const SizedBox(height: 6),
                        Text(
                          'Ingest crisis reports from any field source — photos, spreadsheets, messages, or voice.',
                          style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVar),
                        ).animate().fade(delay: 100.ms),
                        const SizedBox(height: 28),

                        // Tab bar
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(_tabs.length, (i) {
                              final tab = _tabs[i];
                              final isActive = i == _activeTabIndex;
                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: InkWell(
                                  onTap: () => setState(() => _activeTabIndex = i),
                                  borderRadius: BorderRadius.circular(24),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isActive ? AppColors.primary : Colors.white.withValues(alpha: 0.04),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: isActive ? AppColors.primary : Colors.white.withValues(alpha: 0.08),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(tab['icon'] as IconData, size: 16,
                                            color: isActive ? AppColors.background : AppColors.outline),
                                        const SizedBox(width: 8),
                                        Text(
                                          tab['label'] as String,
                                          style: AppTextStyles.technical(
                                            color: isActive ? AppColors.background : AppColors.outline,
                                          ).copyWith(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ).animate().fade(delay: 200.ms).slideY(begin: 0.06),
                        const SizedBox(height: 28),

                        // Tab content with crossfade
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child: KeyedSubtree(
                            key: ValueKey(_activeTabIndex),
                            child: _tabWidgets[_activeTabIndex],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

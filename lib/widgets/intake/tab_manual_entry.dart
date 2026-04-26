import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/need_report.dart';
import '../../services/firebase_service.dart';
import '../shared/glass_card.dart';

class TabManualEntry extends StatefulWidget {
  const TabManualEntry({super.key});

  @override
  State<TabManualEntry> createState() => _TabManualEntryState();
}

class _TabManualEntryState extends State<TabManualEntry> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _categoryController = TextEditingController();
  final _urgencyController = TextEditingController(text: '50');
  final _affectedController = TextEditingController(text: '1');
  final _notesController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _categoryController.dispose();
    _urgencyController.dispose();
    _affectedController.dispose();
    _notesController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: GlassCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Direct Digital Entry', style: AppTextStyles.h3()),
              const SizedBox(height: 8),
              Text(
                'Input crisis reports manually from offline channels (calls, walk-ins).',
                style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVar),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildInput(
                      'Title',
                      Icons.title,
                      controller: _titleController,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildInput(
                      'Location / Sector',
                      Icons.location_on,
                      controller: _locationController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildInput(
                      'Need Category',
                      Icons.category,
                      controller: _categoryController,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildInput(
                      'Urgency Score (0-100)',
                      Icons.warning_amber,
                      controller: _urgencyController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildInput(
                      'People Affected',
                      Icons.group,
                      controller: _affectedController,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildInput(
                            'Latitude (optional)',
                            Icons.pin_drop_outlined,
                            controller: _latController,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInput(
                            'Longitude (optional)',
                            Icons.pin_drop_outlined,
                            controller: _lngController,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildInput(
                'Operational Notes',
                Icons.notes,
                controller: _notesController,
                maxLines: 4,
              ),
              const SizedBox(height: 10),
              Text(
                'Tip: Add latitude/longitude to place this report directly on the live map.',
                style: AppTextStyles.technical(color: AppColors.outline)
                    .copyWith(fontSize: 11),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'SUBMIT REPORT',
                            style: AppTextStyles.labelCaps()
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(
    String label,
    IconData icon, {
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.onSurfaceVar),
            const SizedBox(width: 8),
            Text(
              label.toUpperCase(),
              style: AppTextStyles.labelCaps(color: AppColors.onSurfaceVar),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: AppTextStyles.bodyMd(),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final description = _notesController.text.trim();
    final location = _locationController.text.trim();
    final category = _categoryController.text.trim().toLowerCase();
    final urgency = _clampScore(_toDouble(_urgencyController.text, 50));
    final affectedCount = _toInt(_affectedController.text, 1);

    if (title.isEmpty || description.isEmpty || category.isEmpty) {
      _showSnack(
        'Please fill title, category, and operational notes.',
        AppColors.error,
      );
      return;
    }

    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    final geoPoint = _resolveGeoPoint(
      location: location,
      latitude: lat,
      longitude: lng,
      seed: title.hashCode,
    );

    final need = NeedReport(
      id: 'need_${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      description: description,
      needType: category,
      urgencyScore: urgency,
      urgencyLabel: _urgencyLabel(urgency),
      affectedCount: affectedCount,
      location: location,
      geoLocation: geoPoint,
      status: 'pending',
      reportedAt: DateTime.now(),
      geminiTags: <String>[category, 'manual-entry'],
      reportedBy: 'manual_entry',
    );

    setState(() => _isSubmitting = true);
    try {
      await FirebaseService.instance.addNeed(need);
      if (!mounted) return;
      _showSnack('Report submitted and synced.', AppColors.safeGreen);
      _clearForm();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to submit report: $e', AppColors.error);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _clearForm() {
    _titleController.clear();
    _locationController.clear();
    _categoryController.clear();
    _urgencyController.text = '50';
    _affectedController.text = '1';
    _notesController.clear();
    _latController.clear();
    _lngController.clear();
  }

  double _toDouble(String value, double fallback) {
    return double.tryParse(value) ?? fallback;
  }

  int _toInt(String value, int fallback) {
    return int.tryParse(value) ?? fallback;
  }

  double _clampScore(double score) {
    if (score < 0) return 0;
    if (score > 100) return 100;
    return score;
  }

  String _urgencyLabel(double score) {
    if (score >= 70) return 'Critical';
    if (score >= 40) return 'High';
    return 'Normal';
  }

  GeoPoint _resolveGeoPoint({
    required String location,
    required double? latitude,
    required double? longitude,
    required int seed,
  }) {
    if (latitude != null && longitude != null) {
      return GeoPoint(latitude, longitude);
    }

    final lower = location.toLowerCase();
    if (lower.contains('dharavi')) return const GeoPoint(19.0380, 72.8570);
    if (lower.contains('kurla')) return const GeoPoint(19.0728, 72.8826);
    if (lower.contains('sion')) return const GeoPoint(19.0477, 72.8645);
    if (lower.contains('chembur')) return const GeoPoint(19.0522, 72.9005);
    if (lower.contains('ghatkopar')) return const GeoPoint(19.0856, 72.9081);

    final hash = seed.abs();
    final latOffset = ((hash % 9) - 4) * 0.01;
    final lngOffset = (((hash ~/ 10) % 9) - 4) * 0.01;
    return GeoPoint(19.0760 + latOffset, 72.8777 + lngOffset);
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
        content: Text(message, style: AppTextStyles.technical()),
      ),
    );
  }
}

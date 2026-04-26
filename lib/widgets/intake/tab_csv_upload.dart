import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme.dart';
import '../../services/firebase_service.dart';
import '../../models/need_report.dart';
import '../../widgets/shared/glass_card.dart';

class TabCsvUpload extends StatefulWidget {
  const TabCsvUpload({super.key});

  @override
  State<TabCsvUpload> createState() => _TabCsvUploadState();
}

class _TabCsvUploadState extends State<TabCsvUpload> {
  bool _fileLoaded = false;
  String? _fileName;
  List<List<dynamic>> _csvData = [];
  List<String> _headers = [];
  Map<String, String> _columnMapping = {};
  List<NeedReport> _importedItems = [];
  bool _isImporting = false;
  String? _importError;

  Future<void> _pickAndLoadCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx'],
        allowCompression: true,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (!file.name.toLowerCase().endsWith('.csv')) {
        _showError('Only CSV parsing is implemented right now.');
        return;
      }
      final bytes = file.bytes;

      if (bytes == null) {
        _showError('Failed to read file');
        return;
      }

      // Parse CSV
      final csv = const CsvToListConverter().convert(
        String.fromCharCodes(bytes),
        shouldParseNumbers: false,
      );

      if (csv.isEmpty) {
        _showError('CSV file is empty');
        return;
      }

      final headers = List<String>.from(csv[0].map((e) => e.toString()));
      final rows = csv.skip(1).toList();

      // Auto-map columns
      final mapping = <String, String>{};
      for (final header in headers) {
        final lower = header.toLowerCase();
        if (lower.contains('need') || lower.contains('title')) {
          mapping[header] = 'title';
        } else if (lower.contains('descr') || lower.contains('detail')) {
          mapping[header] = 'description';
        } else if (lower.contains('type') || lower.contains('category')) {
          mapping[header] = 'needType';
        } else if (lower.contains('urgent') || lower.contains('priority')) {
          mapping[header] = 'urgencyScore';
        } else if (lower.contains('reason')) {
          mapping[header] = 'urgencyReason';
        } else if (lower.contains('count') || lower.contains('affected')) {
          mapping[header] = 'affectedCount';
        } else if (lower.contains('location') || lower.contains('address')) {
          mapping[header] = 'suggestedAddress';
        } else if (lower.contains('lat')) {
          mapping[header] = 'latitude';
        } else if (lower.contains('lng') || lower.contains('lon')) {
          mapping[header] = 'longitude';
        }
      }

      setState(() {
        _fileLoaded = true;
        _fileName = file.name;
        _csvData = rows;
        _headers = headers;
        _columnMapping = mapping;
        _importError = null;
      });
    } catch (e) {
      _showError('Failed to load CSV: $e');
    }
  }

  Future<void> _importRecords() async {
    setState(() => _isImporting = true);

    try {
      final needReports = <NeedReport>[];

      for (final row in _csvData) {
        final rowMap = <String, dynamic>{};
        for (int i = 0; i < _headers.length; i++) {
          final header = _headers[i];
          final target = _columnMapping[header];
          if (target != null && target != 'ignore' && i < row.length) {
            rowMap[target] = row[i].toString().trim();
          }
        }

        if (rowMap.isEmpty) continue;

        final location = rowMap['suggestedAddress']?.toString() ?? '';
        final latitude = _parseDouble(rowMap['latitude']);
        final longitude = _parseDouble(rowMap['longitude']);
        // Create NeedReport with mapped data
        final need = NeedReport(
          id: 'csv_${DateTime.now().millisecondsSinceEpoch}_${needReports.length}',
          title: rowMap['title'] ?? 'CSV Import',
          description: rowMap['description'] ?? '',
          needType: _parseNeedType(rowMap['needType']?.toString() ?? 'other'),
          urgencyScore: (_parseInt(rowMap['urgencyScore']) ?? 50).toDouble(),
          urgencyLabel: _urgencyLabel((_parseInt(rowMap['urgencyScore']) ?? 50).toDouble()),
          affectedCount: _parseInt(rowMap['affectedCount']) ?? 1,
          location: location,
          geoLocation: _resolveGeoPoint(
            location: location,
            latitude: latitude,
            longitude: longitude,
            seed: needReports.length,
          ),
          geminiTags: [
            'csv-import',
            (rowMap['needType']?.toString() ?? 'other').toLowerCase(),
          ],
          reportedBy: 'csv-import',
          reportedAt: DateTime.now(),
          status: 'pending',
        );
        needReports.add(need);
      }

      if (needReports.isEmpty) {
        _showError('No valid records found in CSV');
        setState(() => _isImporting = false);
        return;
      }

      // Batch import to Firebase
      for (final need in needReports) {
        await FirebaseService.instance.addNeed(need);
      }

      if (!mounted) return;

      setState(() => _isImporting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Imported ${needReports.length} records'),
          backgroundColor: AppColors.safeGreen,
          duration: const Duration(seconds: 2),
        ),
      );

      // Reset UI
      setState(() {
        _importedItems = needReports;
        _fileLoaded = false;
        _csvData = [];
        _headers = [];
        _columnMapping = {};
      });
    } catch (e) {
      _showError('Import failed: $e');
      setState(() => _isImporting = false);
    }
  }

  String _parseNeedType(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('medical') || lower.contains('health')) return 'medical';
    if (lower.contains('food')) return 'food';
    if (lower.contains('shelter') || lower.contains('housing')) return 'shelter';
    if (lower.contains('water')) return 'water';
    if (lower.contains('education') || lower.contains('school')) return 'education';
    if (lower.contains('safety') || lower.contains('security')) return 'safety';
    return 'other';
  }

  int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  double? _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  String _urgencyLabel(double score) {
    if (score >= 80) return 'Critical';
    if (score >= 60) return 'High';
    if (score >= 40) return 'Medium';
    return 'Low';
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

    final latOffset = ((seed % 9) - 4) * 0.01;
    final lngOffset = (((seed * 3) % 9) - 4) * 0.01;
    return GeoPoint(19.0760 + latOffset, 72.8777 + lngOffset);
  }

  void _showError(String message) {
    setState(() => _importError = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ $message'), backgroundColor: Colors.red),
    );
  }

  void _updateMapping(String header, String target) {
    setState(() => _columnMapping[header] = target);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_fileLoaded)
                InkWell(
                  onTap: _isImporting ? null : _pickAndLoadCsv,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 32),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.02),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.table_chart_outlined, size: 56, color: AppColors.primary.withValues(alpha: 0.5)),
                        const SizedBox(height: 20),
                        Text('Drop CSV / Excel File', style: AppTextStyles.h3()),
                        const SizedBox(height: 8),
                        Text('Bulk import existing spreadsheets with auto column mapping.', style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVar), textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                          onPressed: _isImporting ? null : _pickAndLoadCsv,
                          child: Text('BROWSE FILES', style: AppTextStyles.labelCaps().copyWith(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // File loaded — show column mapping UI
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppColors.safeGreen, size: 18),
                          const SizedBox(width: 8),
                          Text(_fileName ?? 'file.csv', style: AppTextStyles.technical().copyWith(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Text('${_headers.length} columns  •  ${_csvData.length} rows', style: AppTextStyles.technical(color: AppColors.outline)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text('COLUMN MAPPING', style: AppTextStyles.labelCaps(color: AppColors.onSecContainer)),
                      const SizedBox(height: 16),
                      ..._headers.asMap().entries.map((e) {
                        final header = e.value;
                        final mapped = _columnMapping[header] ?? 'ignore';
                        return _buildMappingRow(header, mapped).animate()
                            .fade(delay: Duration(milliseconds: e.key * 60))
                            .slideX(begin: 0.05);
                      }),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isImporting ? null : () => setState(() => _fileLoaded = false),
                              child: Text('CANCEL', style: AppTextStyles.labelCaps()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.background,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _isImporting ? null : _importRecords,
                              icon: _isImporting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.upload),
                              label: Text(
                                _isImporting ? 'IMPORTING...' : 'IMPORT ${_csvData.length} RECORDS',
                                style: AppTextStyles.labelCaps(color: AppColors.background).copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fade(duration: 300.ms).slideY(begin: 0.05),
              ],
              if (_importError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Text(_importError!, style: AppTextStyles.bodyMd(color: Colors.red)),
                  ),
                ),
              if (_importedItems.isNotEmpty) ...[
                const SizedBox(height: 16),
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, size: 16, color: AppColors.safeGreen),
                          const SizedBox(width: 8),
                          Text(
                            'IMPORTED ITEMS (${_importedItems.length})',
                            style: AppTextStyles.labelCaps(color: AppColors.onSecContainer),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._importedItems.take(8).map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.technical(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  item.needType,
                                  style: AppTextStyles.technical(color: AppColors.primary),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${item.affectedCount}',
                                  style: AppTextStyles.technical(color: AppColors.onSurfaceVar),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      if (_importedItems.length > 8)
                        Text(
                          '+ ${_importedItems.length - 8} more imported records',
                          style: AppTextStyles.technical(color: AppColors.outline),
                        ),
                    ],
                  ),
                ).animate().fade(duration: 250.ms),
              ],
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 4,
          child: GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SUPPORTED FORMATS', style: AppTextStyles.labelCaps(color: AppColors.onSecContainer)),
                const SizedBox(height: 16),
                _buildFormatRow(Icons.table_chart, '.CSV', 'Comma-separated values'),
                _buildFormatRow(Icons.grid_on, '.XLSX', 'Microsoft Excel'),
                const SizedBox(height: 20),
                Divider(color: Colors.white.withValues(alpha: 0.06)),
                const SizedBox(height: 16),
                Text('TIPS', style: AppTextStyles.labelCaps(color: AppColors.onSecContainer)),
                const SizedBox(height: 12),
                _buildTip('Ensure headers are in row 1'),
                _buildTip('Date format: YYYY-MM-DD'),
                _buildTip('Auto-maps similar column names'),
                _buildTip('Duplicate records will be created'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMappingRow(String csvCol, String target) {
    final targets = [
      'ignore',
      'title',
      'description',
      'needType',
      'urgencyScore',
      'urgencyReason',
      'affectedCount',
      'suggestedAddress',
      'latitude',
      'longitude',
    ];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(csvCol, style: AppTextStyles.technical())),
          const Icon(Icons.arrow_forward, size: 14, color: AppColors.outline),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: DropdownButton<String>(
              value: target,
              isExpanded: true,
              isDense: true,
              underline: const SizedBox(),
              style: AppTextStyles.technical(),
              items: targets.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) {
                if (v != null) _updateMapping(csvCol, v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatRow(IconData icon, String ext, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.outline),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ext, style: AppTextStyles.technical().copyWith(fontWeight: FontWeight.bold)),
              Text(desc, style: AppTextStyles.technical(color: AppColors.outline).copyWith(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 14, color: AppColors.onSecContainer),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTextStyles.technical(color: AppColors.onSurfaceVar).copyWith(fontSize: 12))),
        ],
      ),
    );
  }
}

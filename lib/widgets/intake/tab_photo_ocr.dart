import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme.dart';
import '../../core/mock_data.dart';
import '../../services/gemini_service.dart';
import '../../services/vision_service.dart';
import '../../services/firebase_service.dart';
import '../../models/need_report.dart';
import '../shared/glass_card.dart';


class TabPhotoOcr extends StatefulWidget {
  const TabPhotoOcr({super.key});

  @override
  State<TabPhotoOcr> createState() => _TabPhotoOcrState();
}

class _TabPhotoOcrState extends State<TabPhotoOcr> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _textController = TextEditingController();

  XFile? _selectedImage;
  bool _isProcessing = false;
  bool _showResult = false;
  String? _errorMessage;
  
  // Parsed AI data
  Map<String, dynamic>? _parsedData;
  bool _isParsingWithAI = false;
  String? _parseErrorMessage;

  // ── Image selection ──────────────────────────────────────────────────────────

  Future<void> _pickFromCamera() async {
    try {
      final granted = await _requestPermission(Permission.camera);
      if (!granted) return;
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (image != null) _processImage(image);
    } catch (e) {
      _showError('Camera access failed: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final granted = await _requestPhotosPermission();
      if (!granted) return;
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (image != null) _processImage(image);
    } catch (e) {
      _showError('Gallery access failed: $e');
    }
  }

  // ── Vision API processing ────────────────────────────────────────────────────

  Future<void> _processImage(XFile image) async {
    setState(() {
      _selectedImage = image;
      _isProcessing = true;
      _showResult = false;
      _errorMessage = null;
      _textController.clear();
    });

    final result = kIsWeb
        ? await VisionService.instance.extractFromBytes(await image.readAsBytes())
        : await VisionService.instance.extractFromImage(File(image.path));

    if (!mounted) return;

    final error = result['error'] as String?;
    final rawText = result['rawText'] as String? ?? '';
    final hasError = error != null && error.isNotEmpty;

    setState(() {
      _isProcessing = false;
      if (hasError) {
        _errorMessage = error;
        // Still show the result area so the user can type manually
        _showResult = true;
      } else {
        _showResult = true;
        _textController.text = rawText;
      }
    });

    if (hasError) {
      _showError('Vision API failed. You can enter text manually.');
    }
  }

  Future<bool> _requestPermission(Permission permission) async {
    if (kIsWeb) return true;

    final status = await permission.request();
    if (status.isGranted) return true;

    if (!mounted) return false;
    if (status.isPermanentlyDenied) {
      _showError('Permission permanently denied. Enable it in app settings.');
      await openAppSettings();
    } else {
      _showError('Permission denied.');
    }
    return false;
  }

  Future<bool> _requestPhotosPermission() async {
    if (kIsWeb) return true;

    final photosPermission = await _requestPermission(Permission.photos);
    if (photosPermission) return true;
    return _requestPermission(Permission.storage);
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.error,
        content: Text(msg, style: AppTextStyles.technical()),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ── Parse with Gemini ────────────────────────────────────────────────────────

  Future<void> _parseWithAI() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _showError('No text to parse. Enter or extract text first.');
      return;
    }

    setState(() {
      _isParsingWithAI = true;
      _parseErrorMessage = null;
      _parsedData = null;
    });

    try {
      final result = await GeminiService.parseNeedFromText(text);
      if (!mounted) return;
      setState(() {
        _parsedData = result;
        _isParsingWithAI = false;
      });
      debugPrint('Parsed need: $result');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isParsingWithAI = false;
        _parseErrorMessage = 'Failed to parse with AI: $e';
      });
      _showError(_parseErrorMessage!);
    }
  }

  Future<void> _submitToDashboard() async {
    if (_parsedData == null) {
      _showError('No parsed data to submit.');
      return;
    }

    try {
      final need = NeedReport(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _parsedData!['title'] as String? ?? 'Untitled',
        description: _parsedData!['description'] as String? ?? '',
        needType: _parsedData!['needType'] as String? ?? 'other',
        urgencyScore: (_parsedData!['urgencyScore'] as num?)?.toDouble() ?? 0,
        urgencyLabel: _getLabelFromScore(
            (_parsedData!['urgencyScore'] as num?)?.toInt() ?? 0),
        affectedCount: _parsedData!['affectedCount'] as int? ?? 1,
        location: _parsedData!['suggestedAddress'] as String? ?? '',
        geminiTags: List<String>.from(_parsedData!['tags'] as List<dynamic>? ?? []),
        reportedAt: DateTime.now(),
        status: 'pending',
      );

      await FirebaseService.instance.addNeed(need);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.safeGreen,
          content: Text(
            'Need added to dashboard',
            style: AppTextStyles.technical(color: AppColors.background),
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      // Reset form
      setState(() {
        _selectedImage = null;
        _showResult = false;
        _textController.clear();
        _parsedData = null;
        _errorMessage = null;
        _parseErrorMessage = null;
      });
    } catch (e) {
      _showError('Failed to submit: $e');
    }
  }

  String _getLabelFromScore(int score) {
    if (score >= 80) return 'Critical';
    if (score >= 60) return 'High';
    if (score >= 40) return 'Medium';
    return 'Low';
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Left: Upload + Preview + Extracted Text ──
        Expanded(
          flex: 8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUploadZone(),
              const SizedBox(height: 24),

              // Image thumbnail preview
              if (_selectedImage != null) ...[
                _buildImagePreview(),
                const SizedBox(height: 24),
              ],

              // Processing spinner
              if (_isProcessing)
                Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 16),
                      Text('Vision API Extracting Text...',
                          style: AppTextStyles.technical(
                              color: AppColors.primary)),
                    ],
                  ),
                ).animate().fade(duration: 300.ms)

              // Result area (extracted text + parse button)
              else if (_showResult) ...[
                _buildResultArea(),
                const SizedBox(height: 24),
                
                // Parsed results
                if (_parsedData != null)
                  _buildParsedResultsArea(),
                
                // Parsing error
                if (_parseErrorMessage != null && _parsedData == null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            size: 16, color: AppColors.error),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _parseErrorMessage!,
                            style: AppTextStyles.technical(color: AppColors.error)
                                .copyWith(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fade(duration: 300.ms),
              ],
            ],
          ),
        ),
        const SizedBox(width: 24),

        // ── Right: Sidebar (integrity check + history) ──
        Expanded(
          flex: 4,
          child: Column(
            children: [
              _buildIntegrityCard(),
              const SizedBox(height: 24),
              _buildHistoryCard(),
            ],
          ),
        ),
      ],
    );
  }

  // ── Upload Zone ──────────────────────────────────────────────────────────────

  Widget _buildUploadZone() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      child: Column(
        children: [
          Icon(Icons.document_scanner_outlined,
              size: 56, color: AppColors.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 20),
          Text('Scan Situation Report', style: AppTextStyles.h3()),
          const SizedBox(height: 8),
          Text(
            'Take a photo of a paper form or upload an image from your gallery.',
            style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVar),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Take Photo button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isProcessing ? null : _pickFromCamera,
                icon: const Icon(Icons.camera_alt, size: 18),
                label: Text('TAKE PHOTO',
                    style: AppTextStyles.labelCaps(color: AppColors.background)
                        .copyWith(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              // Upload from Gallery button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isProcessing ? null : _pickFromGallery,
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: Text('FROM GALLERY',
                    style: AppTextStyles.labelCaps()
                        .copyWith(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Image Preview ────────────────────────────────────────────────────────────

  Widget _buildImagePreview() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: kIsWeb
                ? Image.network(
                    _selectedImage!.path,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 80,
                      height: 80,
                      color: AppColors.surfaceVariant,
                      child: const Icon(Icons.image,
                          color: AppColors.outline, size: 32),
                    ),
                  )
                : Image.file(
                    File(_selectedImage!.path),
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 80,
                      height: 80,
                      color: AppColors.surfaceVariant,
                      child: const Icon(Icons.image,
                          color: AppColors.outline, size: 32),
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedImage!.name,
                  style: AppTextStyles.technical()
                      .copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _isProcessing ? 'Processing…' : 'Ready',
                  style: AppTextStyles.technical(
                    color:
                        _isProcessing ? AppColors.warningAmber : AppColors.safeGreen,
                  ),
                ),
              ],
            ),
          ),
          // Remove image button
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: AppColors.outline),
            onPressed: () {
              setState(() {
                _selectedImage = null;
                _showResult = false;
                _textController.clear();
                _errorMessage = null;
                _parsedData = null;
                _parseErrorMessage = null;
              });
            },
          ),
        ],
      ),
    ).animate().fade(duration: 300.ms).slideY(begin: 0.05);
  }

  // ── Extracted Text Result ────────────────────────────────────────────────────

  Widget _buildResultArea() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.text_snippet_outlined,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('EXTRACTED TEXT', style: AppTextStyles.labelCaps(color: AppColors.onSecContainer)),
              const Spacer(),
              if (_errorMessage != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warningAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber,
                          size: 12, color: AppColors.warningAmber),
                      const SizedBox(width: 6),
                      Text('MANUAL ENTRY',
                          style:
                              AppTextStyles.labelCaps(color: AppColors.warningAmber)
                                  .copyWith(fontSize: 9)),
                    ],
                  ),
                ),
            ],
          ),

          // Error banner
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      size: 16, color: AppColors.error),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: AppTextStyles.technical(color: AppColors.error)
                          .copyWith(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Editable text field
          TextField(
            controller: _textController,
            maxLines: 8,
            style: AppTextStyles.technical()
                .copyWith(height: 1.6, fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText:
                  'Extracted text will appear here.\nYou can also type or edit manually…',
              hintStyle: AppTextStyles.technical(color: AppColors.outline),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),

          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              // Re-scan
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.15)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                onPressed: () {
                  setState(() {
                    _selectedImage = null;
                    _showResult = false;
                    _textController.clear();
                    _errorMessage = null;
                    _parsedData = null;
                    _parseErrorMessage = null;
                  });
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: Text('RE-SCAN',
                    style: AppTextStyles.labelCaps()),
              ),
              const SizedBox(width: 12),
              // Parse with AI
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _isParsingWithAI ? null : _parseWithAI,
                  icon: _isParsingWithAI
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.background,
                            ),
                          ),
                        )
                      : const Icon(Icons.auto_awesome, size: 16),
                  label: Text(_isParsingWithAI ? 'PARSING...' : 'PARSE WITH AI →',
                      style:
                          AppTextStyles.labelCaps(color: AppColors.background)
                              .copyWith(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildParsedResultsArea() {
    final data = _parsedData ?? const <String, dynamic>{};
    final tags = (data['tags'] is List)
        ? List<String>.from((data['tags'] as List).map((e) => e.toString()))
        : const <String>[];
    final urgencyScore = (data['urgencyScore'] as num?)?.toInt() ?? 0;
    final affectedCount = (data['affectedCount'] as num?)?.toInt() ?? 1;

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'PARSED WITH AI',
                style: AppTextStyles.labelCaps(color: AppColors.onSecContainer),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildParsedField('TITLE', data['title']?.toString() ?? ''),
          const SizedBox(height: 10),
          _buildParsedField('NEED TYPE', data['needType']?.toString() ?? 'other'),
          const SizedBox(height: 10),
          _buildParsedField('URGENCY SCORE', '$urgencyScore'),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: (urgencyScore.clamp(0, 100)) / 100.0,
            minHeight: 6,
            color: _getScoreColor(urgencyScore),
            backgroundColor: Colors.white.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 10),
          _buildParsedField(
              'URGENCY REASON', data['urgencyReason']?.toString() ?? ''),
          const SizedBox(height: 10),
          _buildParsedField('AFFECTED COUNT', '$affectedCount'),
          const SizedBox(height: 14),
          if (tags.isNotEmpty) ...[
            Text(
              'TAGS',
              style: AppTextStyles.labelCaps(color: AppColors.onSecContainer),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Text(
                        tag,
                        style: AppTextStyles.technical(
                          color: AppColors.onSurfaceVar,
                        ).copyWith(fontSize: 11),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 14),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _submitToDashboard,
              icon: const Icon(Icons.cloud_upload_outlined, size: 16),
              label: Text(
                'SUBMIT TO DASHBOARD',
                style: AppTextStyles.labelCaps(color: AppColors.background)
                    .copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 300.ms).slideY(begin: 0.03);
  }

  Widget _buildParsedField(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelCaps(color: AppColors.onSecContainer)
                .copyWith(fontSize: 10),
          ),
          const SizedBox(height: 6),
          Text(
            value.isEmpty ? '-' : value,
            style: AppTextStyles.technical(),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppColors.criticalRed;
    if (score >= 60) return AppColors.warningAmber;
    if (score >= 40) return AppColors.safeGreen;
    return AppColors.outline;
  }

  // ── Right Sidebar: Source Integrity Card ──────────────────────────────────────

  Widget _buildIntegrityCard() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified, color: AppColors.safeGreen, size: 20),
              const SizedBox(width: 8),
              Text('Source Integrity', style: AppTextStyles.h3()),
            ],
          ),
          const SizedBox(height: 24),
          Text('Confidence Matrix:',
              style: AppTextStyles.technical(color: AppColors.onSurfaceVar)),
          const SizedBox(height: 8),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (mockOcrResult['confidence'] as int) / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.safeGreen,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('${mockOcrResult['confidence']}% MATCH',
              style: AppTextStyles.labelCaps(color: AppColors.safeGreen)),
          const SizedBox(height: 24),
          Text('Meta Tags:',
              style: AppTextStyles.technical(color: AppColors.onSurfaceVar)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (mockOcrResult['tags'] as List<String>)
                .map((tag) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(tag,
                          style: AppTextStyles.bodyMd(color: AppColors.outline)
                              .copyWith(fontSize: 12)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── Right Sidebar: Recent History Card ────────────────────────────────────────

  Widget _buildHistoryCard() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Intake History', style: AppTextStyles.h3()),
          const SizedBox(height: 24),
          ...mockIntakeHistory.map((history) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Icon(
                      history['icon'] == 'description'
                          ? Icons.description
                          : Icons.table_chart,
                      color: AppColors.outline,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(history['file'].toString(),
                            style: AppTextStyles.technical()),
                        Text(history['detail'].toString(),
                            style: AppTextStyles.bodyMd(color: AppColors.outline)
                                .copyWith(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

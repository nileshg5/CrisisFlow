import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import '../../core/theme.dart';
import '../../models/need_report.dart';
import '../../services/firebase_service.dart';
import '../../services/gemini_service.dart';
import '../../services/voice_service.dart';
import '../../widgets/shared/glass_card.dart';

class TabVoiceInput extends StatefulWidget {
  const TabVoiceInput({super.key});

  @override
  State<TabVoiceInput> createState() => _TabVoiceInputState();
}

class _TabVoiceInputState extends State<TabVoiceInput>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  final TextEditingController _textController = TextEditingController();
  late final AnimationController _pulseController;

  bool _isRecording = false;
  bool _isTranscribing = false;
  bool _isParsing = false;
  bool _isSubmitting = false;
  String? _recordingPath;
  Map<String, dynamic>? _parsedNeed;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _textController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _onMicPressed() async {
    if (_isTranscribing || _isSubmitting || _isParsing) return;
    if (_isRecording) {
      await _stopRecordingAndTranscribe();
      return;
    }
    await _startRecording();
  }

  Future<void> _startRecording() async {
    try {
      final granted = await _requestMicPermission();
      if (!granted) return;

      String path;
      if (!kIsWeb) {
        final dir = await getTemporaryDirectory();
        path = '${dir.path}/voice_need.wav';
      } else {
        path = 'voice_need.webm';
      }

      const config = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 256000,
      );

      await _recorder.start(
        config,
        path: path,
      );

      if (!mounted) return;
      setState(() {
        _isRecording = true;
        _isTranscribing = false;
        _recordingPath = path;
      });
      _pulseController.repeat(reverse: true);
    } catch (e) {
      _showError('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecordingAndTranscribe() async {
    try {
      final filePath = await _recorder.stop();
      _pulseController.stop();
      _pulseController.reset();

      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _isTranscribing = true;
      });

      final path = filePath ?? _recordingPath;
      if (path == null || path.isEmpty) {
        throw Exception(
          kIsWeb
              ? 'No browser recording captured. Allow microphone access and retry.'
              : 'No audio file found to transcribe.',
        );
      }

      final transcript = await _transcribe(path);
      if (!mounted) return;
      setState(() {
        _isTranscribing = false;
        _textController.text = transcript;
        _parsedNeed = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTranscribing = false;
      });
      _showError('Transcription failed: $e');
    }
  }

  Future<String> _transcribe(String path) async {
    await VoiceService.instance.ensureServerReachable();
    if (kIsWeb) {
      final response = await http.get(Uri.parse(path));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        throw Exception('Could not access recorded audio in browser.');
      }
      return VoiceService.instance.transcribeAudioBytes(
        response.bodyBytes,
        filename: 'voice_need.webm',
      );
    }
    return VoiceService.instance.transcribeAudio(File(path));
  }

  Future<void> _parseWithAI() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _showError('No transcribed text available to parse.');
      return;
    }

    setState(() => _isParsing = true);
    try {
      final parsed = await GeminiService.parseNeedFromText(text);
      if (!mounted) return;
      setState(() {
        _parsedNeed = parsed;
        _isParsing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isParsing = false);
      _showError('AI parsing failed: $e');
    }
  }

  Future<void> _submitNeed() async {
    if (_parsedNeed == null) {
      _showError('Parse with AI before submitting.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final parsed = _parsedNeed!;
      final now = DateTime.now();
      final need = NeedReport(
        id: 'need_${now.microsecondsSinceEpoch}',
        title: (parsed['title'] ?? 'Voice Report Need').toString(),
        description: (parsed['description'] ?? _textController.text.trim())
            .toString(),
        needType: (parsed['needType'] ?? 'other').toString(),
        urgencyScore: _toDouble(parsed['urgencyScore']),
        urgencyLabel: _urgencyLabel(_toDouble(parsed['urgencyScore'])),
        affectedCount: _toInt(parsed['affectedCount'], fallback: 1),
        location: (parsed['suggestedAddress'] ?? '').toString(),
        status: 'pending',
        reportedAt: now,
        geminiTags: _toTags(parsed['tags']),
        reportedBy: 'voice_intake',
      );

      await FirebaseService.instance.addNeed(need);
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.safeGreen,
          content: Text(
            'Need submitted successfully.',
            style: AppTextStyles.technical(color: AppColors.background),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showError('Failed to submit need: $e');
    }
  }

  Future<bool> _requestMicPermission() async {
    if (kIsWeb) return true;
    final status = await Permission.microphone.request();
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      _showError('Microphone permission permanently denied. Open settings.');
      await openAppSettings();
    } else {
      _showError('Microphone permission denied.');
    }
    return false;
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.error,
        content: Text(msg, style: AppTextStyles.technical()),
      ),
    );
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? fallback;
  }

  List<String> _toTags(dynamic value) {
    if (value is List) return value.map((e) => '$e').toList();
    return const [];
  }

  String _urgencyLabel(double score) {
    if (score >= 70) return 'Critical';
    if (score >= 40) return 'High';
    return 'Normal';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildRecorderCard(),
              const SizedBox(height: 20),
              _buildTranscriptCard(),
              if (_parsedNeed != null) ...[
                const SizedBox(height: 16),
                _buildParsedCard(),
              ],
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 3,
          child: _buildTipsCard(),
        ),
      ],
    );
  }

  Widget _buildRecorderCard() {
    final micBg = _isRecording
        ? AppColors.criticalRed.withValues(alpha: 0.25)
        : AppColors.primary.withValues(alpha: 0.2);
    final micBorder = _isRecording ? AppColors.criticalRed : AppColors.primary;
    final micIcon = _isRecording ? Icons.mic : Icons.mic_none;

    return GlassCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          GestureDetector(
            onTap: _onMicPressed,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) {
                final pulseScale = _isRecording ? 1 + (_pulseController.value * 0.06) : 1.0;
                return Transform.scale(
                  scale: pulseScale,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: micBg,
                      border: Border.all(color: micBorder, width: 2),
                      boxShadow: _isRecording
                          ? [
                              BoxShadow(
                                color: AppColors.criticalRed
                                    .withValues(alpha: 0.25 + _pulseController.value * 0.2),
                                blurRadius: 30,
                                spreadRadius: 2,
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      micIcon,
                      size: 48,
                      color: micBorder,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _isRecording
                ? 'Recording...'
                : (_isTranscribing ? 'Transcribing...' : 'Tap mic to start'),
            style: AppTextStyles.h3(
              color: _isRecording
                  ? AppColors.criticalRed
                  : (_isTranscribing ? AppColors.primary : AppColors.onBackground),
            ),
          ),
          const SizedBox(height: 8),
          if (_isRecording) _buildWaveform(),
          if (_isTranscribing)
            const Padding(
              padding: EdgeInsets.only(top: 14),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
        ],
      ),
    ).animate().fade(duration: 300.ms);
  }

  Widget _buildTranscriptCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.record_voice_over,
                size: 16,
                color: AppColors.onSecContainer,
              ),
              const SizedBox(width: 8),
              Text(
                'TRANSCRIBED TEXT',
                style: AppTextStyles.labelCaps(color: AppColors.onSecContainer),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _textController,
            maxLines: 8,
            style: AppTextStyles.technical().copyWith(height: 1.6),
            decoration: InputDecoration(
              hintText: 'Your voice transcription will appear here...',
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _onMicPressed,
                  icon: const Icon(Icons.mic, size: 16),
                  label: Text('RECORD AGAIN', style: AppTextStyles.labelCaps()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isParsing ? null : _parseWithAI,
                  icon: _isParsing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome, size: 16),
                  label: Text(
                    'PARSE WITH AI →',
                    style: AppTextStyles.labelCaps(color: AppColors.background)
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildParsedCard() {
    final parsed = _parsedNeed!;
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PARSED RESULT',
            style: AppTextStyles.labelCaps(color: AppColors.onSecContainer),
          ),
          const SizedBox(height: 10),
          _parsedRow('Need Type', '${parsed['needType'] ?? 'other'}'),
          _parsedRow('Urgency Score', '${parsed['urgencyScore'] ?? 0}'),
          _parsedRow(
            'Urgency Reason',
            '${parsed['urgencyReason'] ?? 'No reason provided.'}',
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.safeGreen,
                foregroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _isSubmitting ? null : _submitNeed,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload, size: 16),
              label: Text(
                'SUBMIT NEED',
                style: AppTextStyles.labelCaps(color: AppColors.background)
                    .copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 350.ms).slideY(begin: 0.04);
  }

  Widget _parsedRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: AppTextStyles.technical(color: AppColors.onBackground),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VOICE INTAKE TIPS',
            style: AppTextStyles.labelCaps(color: AppColors.onSecContainer),
          ),
          const SizedBox(height: 16),
          _buildTip('Speak clearly and slowly for best transcription quality.'),
          _buildTip('Mention need type, location, affected count, and urgency.'),
          _buildTip('Edit transcript before parsing if needed.'),
          _buildTip('Tap Parse with AI before submitting to Firestore.'),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.circle, size: 6, color: AppColors.outline),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.technical(color: AppColors.outline),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveform() {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(12, (i) {
          return AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) {
              final h =
                  8.0 + (i % 3 == 0 ? 18 : (i % 2 == 0 ? 12 : 7)) * _pulseController.value;
              return Container(
                width: 4,
                height: h,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: AppColors.criticalRed.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

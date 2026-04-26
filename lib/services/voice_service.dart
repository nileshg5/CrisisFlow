import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class VoiceService {
  VoiceService._internal();
  static final VoiceService _instance = VoiceService._internal();
  static VoiceService get instance => _instance;

  Uri get _transcribeUri => Uri.parse('$_baseUrl/transcribe');
  Uri get _healthUri => Uri.parse('$_baseUrl/health');

  String get _baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8000'
        : 'http://localhost:8000';
  }

  Future<String> transcribeAudio(File audioFile) async {
    final request = http.MultipartRequest('POST', _transcribeUri);
    request.files.add(await http.MultipartFile.fromPath('file', audioFile.path));
    final response = await _send(request);

    return _extractTranscript(response);
  }

  Future<String> transcribeAudioBytes(
    Uint8List bytes, {
    String filename = 'voice_input.webm',
  }) async {
    final request = http.MultipartRequest('POST', _transcribeUri);
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: filename),
    );
    final response = await _send(request);
    return _extractTranscript(response);
  }

  Future<http.Response> _send(http.MultipartRequest request) async {
    final streamed = await request.send();
    return http.Response.fromStream(streamed);
  }

  String _extractTranscript(http.Response response) {
    if (response.statusCode != 200) {
      throw Exception(
        'Whisper server error ${response.statusCode}: ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final transcript = decoded['text'] as String?;
    if (transcript == null || transcript.trim().isEmpty) {
      throw const FormatException('Whisper server returned an empty transcript.');
    }

    return transcript.trim();
  }

  Future<void> ensureServerReachable() async {
    try {
      final response = await http.get(_healthUri);
      if (response.statusCode != 200) {
        throw Exception('Whisper server is not reachable.');
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final ffmpegFound = body['ffmpegFound'] as bool?;
      if (ffmpegFound == false) {
        throw Exception(
          'Whisper server is running but ffmpeg is missing. '
          'Install ffmpeg and restart the server.',
        );
      }
    } on SocketException {
      throw Exception(
        'Whisper server is not running on ${_healthUri.host}:8000. '
        'Start whisper_server.py first.',
      );
    } on http.ClientException {
      throw Exception(
        'Whisper server is not running on ${_healthUri.host}:8000. '
        'Start whisper_server.py first.',
      );
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class GeminiService {
  GeminiService._();

  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const List<String> _endpoints = [
    'https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent',
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent',
    'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash-latest:generateContent',
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent',
    'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent',
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent',
    'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-pro:generateContent',
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent',
  ];
  static String? _resolvedEndpoint;

  static Future<Map<String, dynamic>> parseNeedFromText(String rawText) async {
    const systemPrompt =
        'You are a community needs analyst. Extract structured data from this '
        'field report text.\n'
        'Return ONLY valid JSON with these exact keys:\n'
        '{\n'
        '  title: string (short 5-word summary),\n'
        '  description: string (cleaned full description),\n'
        '  needType: string (one of: food, medical, shelter, water, education, '
        'safety, other),\n'
        '  urgencyScore: int (0-100, based on: medical=+40, large affected '
        'count=+20,\n'
        '                time sensitive language=+20, multiple needs=+10, '
        'elderly/children=+10),\n'
        '  urgencyReason: string (one sentence explaining the score),\n'
        '  affectedCount: int (estimated people affected, default 1 if not '
        'mentioned),\n'
        '  tags: array of strings (relevant tags),\n'
        '  suggestedAddress: string (any location mentioned or empty string)\n'
        '}\n'
        'Do not include markdown, backticks, or any text outside the JSON.';

    final responseText = await _generateContent(
      systemPrompt: systemPrompt,
      userPrompt: rawText,
    );

    try {
      final decoded = jsonDecode(responseText);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      final candidate = _extractBalancedJson(responseText, '{', '}');
      if (candidate != null) {
        final decoded = jsonDecode(candidate);
        if (decoded is Map<String, dynamic>) return decoded;
      }
    }
    throw const FormatException('Failed to parse Gemini need JSON response.');
  }

  static Future<List<Map<String, dynamic>>> matchVolunteers(
    Map<String, dynamic> need,
    List<Map<String, dynamic>> volunteers,
  ) async {
    const systemPrompt =
        'You are a volunteer coordination AI. Given a community need and a list '
        'of volunteers,\n'
        'rank the top 3 best-matched volunteers.\n'
        'Return ONLY a valid JSON array with objects:\n'
        '[{\n'
        '  volunteerId: string,\n'
        '  matchScore: int (0-100),\n'
        '  matchReason: string (one sentence why this volunteer fits),\n'
        '  skillMatch: bool,\n'
        '  distanceOk: bool\n'
        '}]\n'
        'Prioritize: skill match > proximity > availability > reliability score.\n'
        'Do not include markdown or text outside the JSON array.';

    final userPrompt = jsonEncode({
      'need': need,
      'volunteers': volunteers,
    });

    final responseText = await _generateContent(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
    );

    try {
      final decoded = jsonDecode(responseText);
      if (decoded is List) {
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {
      final candidate = _extractBalancedJson(responseText, '[', ']');
      if (candidate != null) {
        final decoded = jsonDecode(candidate);
        if (decoded is List) {
          return decoded
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
      }
    }
    throw const FormatException('Failed to parse Gemini volunteer match JSON array.');
  }

  static Future<String> _generateContent({
    required String systemPrompt,
    required String userPrompt,
  }) 
  async {
    if (_apiKey.isEmpty) {
      throw Exception(
        'GEMINI_API_KEY not configured. Run with: '
        '--dart-define=GEMINI_API_KEY=YOUR_KEY',
      );
    }
    // At top of _generateContent method, add:
   if (kIsWeb) {
  // Use local proxy for web to avoid CORS
  final proxyUri = Uri.parse('http://localhost:8000/gemini');
  final response = await http.post(
    proxyUri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'apiKey': _apiKey,
      'prompt': '$systemPrompt\n\n$userPrompt',
    }),
  );
  
  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);
final candidates = decoded['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('Gemini returned no candidates: ${response.body}');
    }
    
    final content = candidates[0]['content'];
    final parts = content['parts'] as List?;
    if (parts == null || parts.isEmpty) {
      throw Exception('Gemini returned no parts');
    }
    
    final text = parts[0]['text'] as String?;
    if (text == null || text.isEmpty) {
      throw Exception('Gemini returned empty text');
    }    return text.trim();
  }
  throw Exception('Gemini proxy error: ${response.body}');
}

// Original code continues for non-web platforms...

    final requestBodies = <String>[
      jsonEncode({
        'systemInstruction': {
          'parts': [
            {'text': systemPrompt},
          ],
        },
        'contents': [
          {
            'parts': [
              {'text': userPrompt},
            ],
          },
        ],
        'generationConfig': {
          'responseMimeType': 'application/json',
        },
      }),
      jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text':
                    '$systemPrompt\n\nField report text:\n$userPrompt\n\nReturn only valid JSON.',
              },
            ],
          },
        ],
      }),
    ];

    final orderedEndpoints = <String>[
      if (_resolvedEndpoint != null) _resolvedEndpoint!,
      ..._endpoints.where((e) => e != _resolvedEndpoint),
    ];

    String? lastError;
    for (final endpoint in orderedEndpoints) {
      final uri = Uri.parse('$endpoint?key=$_apiKey');
      for (var i = 0; i < requestBodies.length; i++) {
        final response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: requestBodies[i],
        );

        if (response.statusCode == 200) {
          _resolvedEndpoint = endpoint;
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          final candidates = decoded['candidates'] as List<dynamic>?;
          if (candidates == null || candidates.isEmpty) {
            throw const FormatException('Gemini response missing candidates.');
          }

          final content = (candidates.first as Map<String, dynamic>)['content']
              as Map<String, dynamic>?;
          final parts = content?['parts'] as List<dynamic>?;
          if (parts == null || parts.isEmpty) {
            throw const FormatException('Gemini response missing text parts.');
          }

          final text = (parts.first as Map<String, dynamic>)['text'] as String?;
          if (text == null || text.trim().isEmpty) {
            throw const FormatException('Gemini response returned empty content.');
          }
          return text.trim();
        }

        final responseBody = response.body;
        if (_isUnknownFieldPayload(response.statusCode, responseBody) &&
            i < requestBodies.length - 1) {
          continue;
        }
        if (_isEndpointNotAvailable(response.statusCode, responseBody)) {
          lastError =
              'Gemini endpoint unavailable (${response.statusCode}): $responseBody';
          break;
        }

        throw Exception(
          'Gemini API error ${response.statusCode}: $responseBody',
        );
      }
    }

    throw Exception(
      'No supported Gemini endpoint worked for this API key. ${lastError ?? ''}',
    );
  }

  static bool _isEndpointNotAvailable(int statusCode, String responseBody) {
    if (statusCode != 404 && statusCode != 400) return false;
    final lower = responseBody.toLowerCase();
    return lower.contains('not found') ||
        lower.contains('is not found for api version') ||
        lower.contains('not supported for generatecontent') ||
        lower.contains('model');
  }

  static bool _isUnknownFieldPayload(int statusCode, String responseBody) {
    if (statusCode != 400) return false;
    final lower = responseBody.toLowerCase();
    return lower.contains('unknown name') ||
        lower.contains('cannot find field') ||
        lower.contains('invalid json payload');
  }

  static String? _extractBalancedJson(
    String source,
    String openChar,
    String closeChar,
  ) {
    final start = source.indexOf(openChar);
    if (start < 0) return null;

    var depth = 0;
    for (var i = start; i < source.length; i++) {
      final char = source[i];
      if (char == openChar) {
        depth++;
      } else if (char == closeChar) {
        depth--;
        if (depth == 0) return source.substring(start, i + 1);
      }
    }
    return null;
  }
}

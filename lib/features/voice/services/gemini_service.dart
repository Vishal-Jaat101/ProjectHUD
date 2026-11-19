/// Gemini API integration for voice command processing.
///
/// Sends rider speech + ride context to Gemini and returns a structured
/// [AssistantResponse] with text and an optional action.
///
/// System prompt keeps replies under 15 words — the rider is driving.

import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:project_hud/app/constants/app_constants.dart';

// ── Assistant Response Model ───────────────────────────────────────

/// Actions the assistant can trigger from a voice command.
enum AssistantAction {
  /// Navigate to a destination.
  navigate,

  /// Report a road hazard.
  reportHazard,

  /// Confirm or deny a hazard ("still there?").
  confirmHazard,

  /// Rider asked to repeat the last instruction.
  repeat,

  /// Rider asked how much time / distance is left.
  timeLeft,

  /// Rider wants to call their emergency contact.
  callEmergency,

  /// Stop the current navigation session.
  stopNavigation,

  /// No actionable intent — informational reply only.
  none,
}

/// Structured response from the Gemini-powered assistant.
class AssistantResponse {
  /// Spoken text the TTS engine will read aloud.
  final String text;

  /// Semantic action derived from the rider's command.
  final AssistantAction action;

  /// Optional payload for the action (e.g. destination name, hazard type).
  final Map<String, dynamic> actionData;

  const AssistantResponse({
    required this.text,
    this.action = AssistantAction.none,
    this.actionData = const {},
  });

  factory AssistantResponse.fromJson(Map<String, dynamic> json) {
    return AssistantResponse(
      text: json['text'] as String? ?? '',
      action: AssistantAction.values.firstWhere(
        (a) => a.name == json['action'],
        orElse: () => AssistantAction.none,
      ),
      actionData:
          (json['actionData'] as Map<String, dynamic>?) ?? const {},
    );
  }

  factory AssistantResponse.error(String message) {
    return AssistantResponse(
      text: message,
      action: AssistantAction.none,
    );
  }
}

// ── Ride Context ───────────────────────────────────────────────────

/// Minimal ride context passed alongside rider speech so Gemini can
/// give distance-aware, context-aware answers.
class RideContext {
  final bool isNavigating;
  final double? remainingDistanceMeters;
  final double? remainingDurationSeconds;
  final double? currentSpeedKmh;
  final String? destinationName;
  final String? nextInstruction;
  final String? language; // 'en-IN' or 'hi-IN'

  const RideContext({
    this.isNavigating = false,
    this.remainingDistanceMeters,
    this.remainingDurationSeconds,
    this.currentSpeedKmh,
    this.destinationName,
    this.nextInstruction,
    this.language,
  });

  Map<String, dynamic> toJson() {
    return {
      'isNavigating': isNavigating,
      if (remainingDistanceMeters != null)
        'remainingDistanceMeters': remainingDistanceMeters,
      if (remainingDurationSeconds != null)
        'remainingDurationSeconds': remainingDurationSeconds,
      if (currentSpeedKmh != null) 'currentSpeedKmh': currentSpeedKmh,
      if (destinationName != null) 'destinationName': destinationName,
      if (nextInstruction != null) 'nextInstruction': nextInstruction,
      if (language != null) 'language': language,
    };
  }
}

// ── Gemini Service ─────────────────────────────────────────────────

/// Service that calls Gemini API to interpret rider voice commands.
class GeminiService {
  GeminiService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  /// Base URL for the Gemini REST API.
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  /// Model to use. Gemini 1.5 Flash is fast enough for <15-word replies.
  static const String _model = 'gemini-1.5-flash';

  /// System prompt keeps answers ultra-short and safety-first.
  static const String _systemPrompt = '''
You are HUD Assistant, a road safety AI for Indian two-wheeler riders.
Keep responses under 15 words — the rider is driving.
Respond in the same language the rider speaks.

You can understand the following intents:
- "navigate to <place>" → action: navigate, actionData: {"destination": "<place>"}
- "report pothole" → action: reportHazard, actionData: {"hazardType": "pothole"}
- "report accident" → action: reportHazard, actionData: {"hazardType": "accident"}
- "yes" / "haan" → action: confirmHazard, actionData: {"confirmed": true}
- "no" / "nahi" → action: confirmHazard, actionData: {"confirmed": false}
- "repeat" / "dobara bolo" → action: repeat
- "how much time left" / "kitna time baaki hai" → action: timeLeft
- "call emergency contact" / "emergency call karo" → action: callEmergency
- "stop navigation" / "navigation band karo" → action: stopNavigation

Always reply with a JSON object: {"text": "...", "action": "...", "actionData": {...}}
If no action matches, use action "none" with an empty actionData.
''';

  /// Process a rider's voice command and return a structured response.
  ///
  /// [userSpeech] is the transcribed text from the STT engine.
  /// [rideContext] carries current ride state for context-aware answers.
  Future<AssistantResponse> processCommand(
    String userSpeech,
    RideContext rideContext,
  ) async {
    if (userSpeech.trim().isEmpty) {
      return AssistantResponse.error("I didn't catch that. Please repeat.");
    }

    try {
      final url =
          '$_baseUrl/models/$_model:generateContent?key=${AppConstants.geminiApiKey}';

      final body = {
        'system_instruction': {
          'parts': [
            {'text': _systemPrompt},
          ],
        },
        'contents': [
          {
            'parts': [
              {
                'text': 'Ride context: ${jsonEncode(rideContext.toJson())}\n'
                    'Rider says: "$userSpeech"',
              },
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.2,
          'maxOutputTokens': 256,
          'responseMimeType': 'application/json',
        },
      };

      final response = await _dio.post(
        url,
        data: body,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 5),
        ),
      );

      return _parseResponse(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 429) {
        return AssistantResponse.error('Too many requests. Try again.');
      }
      return AssistantResponse.error('Connection issue. Try again.');
    } catch (_) {
      return AssistantResponse.error('Something went wrong. Try again.');
    }
  }

  /// Parse the Gemini API response into an [AssistantResponse].
  AssistantResponse _parseResponse(Map<String, dynamic> responseData) {
    try {
      final candidates = responseData['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        return AssistantResponse.error('No response. Try again.');
      }

      final content =
          candidates[0]['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        return AssistantResponse.error('No response. Try again.');
      }

      final text = parts[0]['text'] as String? ?? '';

      // Gemini returns JSON thanks to responseMimeType setting.
      final parsed = jsonDecode(text) as Map<String, dynamic>;
      return AssistantResponse.fromJson(parsed);
    } catch (_) {
      // If JSON parsing fails, treat the raw text as a plain reply.
      try {
        final rawText = (responseData['candidates'] as List<dynamic>?)
                ?.first['content']['parts']
                ?.first['text'] as String? ??
            '';
        return AssistantResponse(text: rawText);
      } catch (_) {
        return AssistantResponse.error('Could not understand response.');
      }
    }
  }
}

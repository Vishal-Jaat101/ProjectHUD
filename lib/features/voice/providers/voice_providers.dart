/// Riverpod providers for the voice assistant feature.
///
/// Manages voice state (listening → processing → speaking → idle),
/// transcribed text, and assistant responses.

import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Voice State Machine ────────────────────────────────────────────

/// States the voice assistant cycles through.
enum VoiceState {
  /// No active voice interaction.
  idle,

  /// Microphone is open, speech-to-text is running.
  listening,

  /// Transcribed text sent to Gemini, awaiting response.
  processing,

  /// TTS is reading the assistant's reply to the rider.
  speaking,
}

/// Current phase of the voice assistant.
final voiceStateProvider = StateProvider<VoiceState>(
  (ref) => VoiceState.idle,
);

/// Whether the microphone is actively capturing audio.
final isListeningProvider = Provider<bool>(
  (ref) => ref.watch(voiceStateProvider) == VoiceState.listening,
);

// ── Text Content ───────────────────────────────────────────────────

/// What the rider just said (populated by speech-to-text).
final transcribedTextProvider = StateProvider<String>(
  (ref) => '',
);

/// The assistant's latest spoken reply.
final assistantResponseProvider = StateProvider<String>(
  (ref) => '',
);

// ── Language ───────────────────────────────────────────────────────

/// Currently selected voice language locale.
/// Defaults to Indian English; toggle to Hindi via settings or voice.
final voiceLanguageProvider = StateProvider<String>(
  (ref) => 'en-IN',
);

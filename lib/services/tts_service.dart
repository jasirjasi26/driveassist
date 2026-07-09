import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  late FlutterTts _flutterTts;
  bool _isInitialized = false;
  bool enabled = true;

  // Track timestamps of spoke announcements to enforce cooldowns
  final Map<String, DateTime> _cooldowns = {};

  Future<void> init() async {
    if (_isInitialized) return;
    _flutterTts = FlutterTts();

    try {
      // Set to female voice and standard pitch/speech rate
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setPitch(1.0);
      
      // Attempt to configure female voice if available
      dynamic voices = await _flutterTts.getVoices;
      if (voices != null) {
        for (var voice in voices) {
          if (voice is Map && 
              voice["name"] != null && 
              voice["name"].toString().toLowerCase().contains("female")) {
            await _flutterTts.setVoice(Map<String, String>.from(voice.cast<String, String>()));
            break;
          }
        }
      }
      _isInitialized = true;
    } catch (e) {
      print("TTS Initialisation error: $e");
    }
  }

  /// Speak a message if voice alerts are enabled and cooldown allows it.
  /// [cooldownSeconds] enforces a quiet period before this alert type can speak again.
  Future<void> speak(String text, {int cooldownSeconds = 0}) async {
    if (!enabled || !_isInitialized) return;

    final now = DateTime.now();
    if (cooldownSeconds > 0) {
      final lastSpoken = _cooldowns[text];
      if (lastSpoken != null && now.difference(lastSpoken).inSeconds < cooldownSeconds) {
        // Cooldown active, skip speaking
        return;
      }
      // Record timestamp
      _cooldowns[text] = now;
    }

    try {
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    } catch (e) {
      print("TTS speak failure: $e");
    }
  }

  Future<void> stop() async {
    if (!_isInitialized) return;
    await _flutterTts.stop();
  }
}

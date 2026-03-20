// ============================================================================
// VOICE ASSISTANT SERVICE - Speech recognition and text-to-speech
// FIX: Removed onPartial callback — user bubble now reads
//      voiceService.recognizedText directly via Consumer2/notifyListeners,
//      which is instant with zero delay. The onPartial callback approach
//      caused extra delay because it went through an async callback chain.
// NOTE: Light/bulb/lamp command block removed — no physical LED hardware.
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceService extends ChangeNotifier {
  // ============================================================================
  // PROPERTIES
  // ============================================================================

  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  bool _isListening = false;
  bool get isListening => _isListening;

  String _recognizedText = '';
  String get recognizedText => _recognizedText;

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  Future<void> initialize() async {
    final status = await Permission.microphone.request();

    if (status.isGranted) {
      _isAvailable = await _speechToText.initialize(
        onStatus: (status) {
          debugPrint('Speech status: $status');
          _isListening = status == 'listening';
          notifyListeners();
        },
        onError: (error) {
          debugPrint('Speech error: $error');
          _isListening = false;
          notifyListeners();
        },
      );

      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.5);

      notifyListeners();
    } else {
      debugPrint('Microphone permission denied');
    }
  }

  // ============================================================================
  // START LISTENING
  // FIX: No onPartial callback needed — _recognizedText is updated inside
  //      the listen() onResult for partial results and notifyListeners() is
  //      called immediately, so Consumer2 in voice_tab rebuilds instantly
  //      showing live words with zero callback delay.
  // ============================================================================

  Future<void> startListening({
    required Function(String) onResult,
  }) async {
    if (!_isAvailable) {
      await initialize();
    }

    // Clear previous text when starting fresh
    _recognizedText = '';
    notifyListeners();

    if (_isAvailable && !_isListening) {
      await _speechToText.listen(
        onResult: (result) {
          // Update recognized text live — Consumer2 rebuilds instantly
          _recognizedText = result.recognizedWords;
          notifyListeners();

          // Only fire command when speech is fully finalized
          if (result.finalResult) {
            onResult(_recognizedText);
          }
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 2), // reduced from 3 → less delay
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      );
    }
  }

  // ============================================================================
  // STOP LISTENING
  // ============================================================================

  Future<void> stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
      notifyListeners();
    }
  }

  // ============================================================================
  // SPEAK TEXT
  // ============================================================================

  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }

  // ============================================================================
  // PROCESS COMMAND
  // Returns action + state (true/false) + message.
  // Caller uses state to SET exact value, not toggle.
  // Light commands removed — no physical LED hardware.
  // ============================================================================

  Map<String, dynamic> processCommand(String command) {
    final lowerCommand = command.toLowerCase();

    // Water pump commands
    if (_containsAny(lowerCommand, ['water', 'pump', 'irrigation'])) {
      if (_containsAny(lowerCommand, ['on', 'start', 'turn on', 'switch on'])) {
        return {'action': 'pump', 'state': true, 'message': 'Turning on water pump'};
      } else if (_containsAny(lowerCommand, ['off', 'stop', 'turn off', 'switch off'])) {
        return {'action': 'pump', 'state': false, 'message': 'Turning off water pump'};
      }
    }

    // Window commands
    if (_containsAny(lowerCommand, ['window', 'ventilation', 'vent'])) {
      if (_containsAny(lowerCommand, ['open'])) {
        return {'action': 'window', 'state': true, 'message': 'Opening window'};
      } else if (_containsAny(lowerCommand, ['close', 'shut'])) {
        return {'action': 'window', 'state': false, 'message': 'Closing window'};
      }
    }

    // Light commands REMOVED — no physical LED hardware

    // Status check
    if (_containsAny(lowerCommand, ['status', 'how', 'condition', 'report'])) {
      return {'action': 'status', 'state': null, 'message': 'Checking greenhouse status'};
    }

    // Crop recommendation
    if (_containsAny(lowerCommand, ['recommend', 'suggest', 'crop', 'plant', 'grow'])) {
      return {'action': 'recommend', 'state': null, 'message': 'Getting crop recommendations'};
    }

    // Unknown
    return {
      'action': 'unknown',
      'state': null,
      'message': 'Sorry, I did not understand. Try "turn on water pump" or "check status"'
    };
  }

  // ============================================================================
  // HELPER
  // ============================================================================

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  // ============================================================================
  // CLEANUP
  // ============================================================================

  @override
  void dispose() {
    _speechToText.cancel();
    _flutterTts.stop();
    super.dispose();
  }
}
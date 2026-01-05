// ============================================================================
// VOICE ASSISTANT SERVICE - Speech recognition and text-to-speech
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceService extends ChangeNotifier {
  // ============================================================================
  // PROPERTIES
  // ============================================================================

  // Speech recognition instance
  final SpeechToText _speechToText = SpeechToText();

  // Text-to-speech instance
  final FlutterTts _flutterTts = FlutterTts();

  // Is voice assistant listening?
  bool _isListening = false;
  bool get isListening => _isListening;

  // Last recognized text
  String _recognizedText = '';
  String get recognizedText => _recognizedText;

  // Is voice assistant available?
  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  Future<void> initialize() async {
    // Request microphone permission
    final status = await Permission.microphone.request();

    if (status.isGranted) {
      // Initialize speech recognition
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

      // Configure text-to-speech
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
  // ============================================================================

  Future<void> startListening({
    required Function(String) onResult,
  }) async {
    if (!_isAvailable) {
      await initialize();
    }

    if (_isAvailable && !_isListening) {
      await _speechToText.listen(
        onResult: (result) {
          _recognizedText = result.recognizedWords;
          notifyListeners();

          // Call callback with final result
          if (result.finalResult) {
            onResult(_recognizedText);
          }
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
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
  // SPEAK TEXT (Text-to-Speech)
  // ============================================================================

  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  // ============================================================================
  // STOP SPEAKING
  // ============================================================================

  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }

  // ============================================================================
  // PROCESS COMMAND (Natural Language Understanding)
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

    // Light commands
    if (_containsAny(lowerCommand, ['light', 'bulb', 'lamp'])) {
      if (_containsAny(lowerCommand, ['on', 'turn on', 'switch on'])) {
        return {'action': 'light', 'state': true, 'message': 'Turning on light'};
      } else if (_containsAny(lowerCommand, ['off', 'turn off', 'switch off'])) {
        return {'action': 'light', 'state': false, 'message': 'Turning off light'};
      }
    }

    // Status check
    if (_containsAny(lowerCommand, ['status', 'how', 'condition', 'report'])) {
      return {'action': 'status', 'message': 'Checking greenhouse status'};
    }

    // Crop recommendation
    if (_containsAny(lowerCommand, ['recommend', 'suggest', 'crop', 'plant', 'grow'])) {
      return {'action': 'recommend', 'message': 'Getting crop recommendations'};
    }

    // Unknown command
    return {
      'action': 'unknown',
      'message': 'Sorry, I did not understand that command. Try saying "turn on water pump" or "check status"'
    };
  }

  // ============================================================================
  // HELPER METHOD - Check if text contains any of the keywords
  // ============================================================================

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  // ============================================================================
  // CLEANUP
  // ============================================================================

  @override
  void dispose() {
    _speechToText.stop();
    _flutterTts.stop();
    super.dispose();
  }
}
//meow meow meow meow
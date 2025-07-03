import 'package:flutter_tts/flutter_tts.dart';

class TtsManager {
  final FlutterTts _flutterTts = FlutterTts();

  static final TtsManager _instance = TtsManager._internal();
  factory TtsManager() => _instance;
  TtsManager._internal();

  Future<void> setSpeechSpeed(String speed) async {
    switch (speed) {
      case 'slow':
        await _flutterTts.setSpeechRate(0.1);
        break;
      case 'fast':
        await _flutterTts.setSpeechRate(1.0);
        break;
      default:
        await _flutterTts.setSpeechRate(0.5);
    }
  }

  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  Future<void> setLanguage(String lang) async {
    await _flutterTts.setLanguage(lang);
  }

  FlutterTts get flutterTts => _flutterTts;
}
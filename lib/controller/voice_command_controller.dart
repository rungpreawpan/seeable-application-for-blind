import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seeable/controller/bottom_nav_controller.dart';
import 'package:seeable/controller/tts_manager.dart';
import 'package:seeable/controller/voice_action_controller.dart';
import 'package:seeable/service/voice_commands.dart';
import 'package:seeable/views/navigation/selected_place_page.dart';
import 'package:seeable/views/object_detection/object_detect_page.dart';
import 'package:seeable/views/scan_text/scan_text_page.dart';
import 'package:seeable/views/settings/controller/settings_controller.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

enum VoiceMode { idle, wakeWord, command }

class VoiceNavigatorObserver extends NavigatorObserver {
  final VoiceCommandController controller;
  VoiceNavigatorObserver(this.controller);

  @override
  void didPop(Route route, Route? previousRoute) {
    Future.delayed(const Duration(milliseconds: 300), controller.resumeListening);
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    Future.delayed(const Duration(milliseconds: 300), controller.resumeListening);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    Future.delayed(const Duration(milliseconds: 300), controller.resumeListening);
  }
}

class VoiceCommandController extends GetxController {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TtsManager _ttsManager = TtsManager();
  final SettingsController _settingsController = Get.find();

  var mode = VoiceMode.idle.obs;
  var isInitialized = false.obs;
  var lastRecognizedText = ''.obs;

  bool _isRestarting = false;
  Timer? _watchdogTimer;

  @override
  void onInit() {
    super.onInit();

    ever(_settingsController.useSpeechRecognition, (bool enabled) {
      if (enabled) {
        _initAndStart();
        _startWatchdog();
      } else {
        _stop();
        _watchdogTimer?.cancel();
      }
    });

    // Delay init so the app is fully ready before starting speech
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_settingsController.useSpeechRecognition.value) {
        _initAndStart();
        _startWatchdog();
      }
    });
  }

  @override
  void onClose() {
    _watchdogTimer?.cancel();
    _speech.stop();
    super.onClose();
  }

  void _startWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!isInitialized.value) return;
      if (!_settingsController.useSpeechRecognition.value) return;
      if (mode.value != VoiceMode.idle && !_speech.isListening && !_isRestarting) {
        log('Watchdog: restarting (mode=${mode.value})');
        _startWakeWordListening();
      }
    });
  }

  Future<void> _initAndStart() async {
    if (!isInitialized.value) {
      final available = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: (error) {
          log('STT error: ${error.errorMsg} permanent=${error.permanent}');
          _isRestarting = false;
          switch (error.errorMsg) {
            case 'error_busy':
              // Engine busy — wait longer before retrying
              Future.delayed(const Duration(seconds: 2), _restartIfNeeded);
              break;
            case 'error_client':
              // Conflict (e.g. TTS playing) — wait for it to finish
              Future.delayed(const Duration(seconds: 2), _restartIfNeeded);
              break;
            case 'error_no_match':
              // No speech detected — restart immediately
              Future.delayed(const Duration(milliseconds: 300), _restartIfNeeded);
              break;
            default:
              if (!error.permanent) {
                Future.delayed(const Duration(seconds: 1), _restartIfNeeded);
              }
          }
        },
      );
      isInitialized.value = available;
      log('STT initialized: $available');
    }

    if (isInitialized.value) {
      _startWakeWordListening();
    }
  }

  void _onSpeechStatus(String status) {
    log('STT status: $status, mode: ${mode.value}');
    // React only to 'done' — both notListening+done fire together
    // causing double-restart and error_busy. 'done' is the final state.
    if (status == 'done') {
      _isRestarting = false;
      Future.delayed(const Duration(milliseconds: 500), _restartIfNeeded);
    }
  }

  void _restartIfNeeded() {
    if (!isInitialized.value) return;
    if (!_settingsController.useSpeechRecognition.value) return;
    if (_isRestarting) return;
    if (mode.value == VoiceMode.idle) return;
    // Any non-idle mode that stopped → restart from wake word
    if (!_speech.isListening) {
      _startWakeWordListening();
    }
  }

  void _startWakeWordListening() {
    if (!isInitialized.value) return;
    if (!_settingsController.useSpeechRecognition.value) return;
    if (_isRestarting) return;
    if (_speech.isListening) return;

    _isRestarting = true;
    mode.value = VoiceMode.wakeWord;

    final isThai =
        _settingsController.currentLocale.value.languageCode == 'th';
    final wakeWord = isThai ? 'สวัสดี' : 'hello';

    _speech
        .listen(
      localeId: _settingsController
          .localeToString(_settingsController.currentLocale.value),
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 10),
      onResult: (val) {
        if (val.recognizedWords.isNotEmpty) {
          final words = val.recognizedWords.toLowerCase();
          lastRecognizedText.value = words;
          log('Wake word listening — heard: $words');
          if (words.contains(wakeWord)) {
            _speech.stop();
            _onWakeWordDetected();
          }
        }
      },
      listenOptions: stt.SpeechListenOptions(cancelOnError: false),
    )
        .then((_) {
      _isRestarting = false;
    });
  }

  void _onWakeWordDetected() {
    log('Wake word detected!');
    final isThai =
        _settingsController.currentLocale.value.languageCode == 'th';
    _ttsManager
        .speak(isThai ? 'รับทราบ กรุณาพูดคำสั่ง' : 'Yes, please say a command');
    Future.delayed(const Duration(milliseconds: 1500), _startCommandListening);
  }

  void _startCommandListening() {
    if (!_settingsController.useSpeechRecognition.value) return;

    mode.value = VoiceMode.command;

    _speech.listen(
      localeId: _settingsController
          .localeToString(_settingsController.currentLocale.value),
      listenFor: const Duration(seconds: 7),
      pauseFor: const Duration(seconds: 3),
      onResult: (val) {
        if (val.finalResult) {
          final recognized = val.recognizedWords.toLowerCase();
          lastRecognizedText.value = recognized;
          log('Command heard: $recognized');
          _processCommand(recognized);
        }
      },
      listenOptions: stt.SpeechListenOptions(cancelOnError: false),
    );
  }

  void _processCommand(String recognized) {
    final isThai =
        _settingsController.currentLocale.value.languageCode == 'th';

    for (final command in voiceCommands) {
      final triggers = isThai ? command.thTriggers : command.enTriggers;
      if (triggers.any((t) => recognized.contains(t.toLowerCase()))) {
        _executeCommand(command.key, isThai);
        return;
      }
    }

    log('Command not recognized: $recognized');
    _ttsManager.speak(isThai
        ? 'ไม่เข้าใจคำสั่ง กรุณาลองอีกครั้ง'
        : 'Command not recognized, please try again');
    // Retry command listening so user doesn't need to say wake word again
    Future.delayed(const Duration(milliseconds: 500), _startCommandListening);
  }

  void _executeCommand(String key, bool isThai) {
    switch (key) {
      case 'navigation':
        _ttsManager.speak(isThai ? 'เปิดระบบนำทาง' : 'Opening navigation');
        Get.to(() => const SelectedPlacePage());
        break;
      case 'object_detection':
        _ttsManager
            .speak(isThai ? 'เปิดการตรวจจับวัตถุ' : 'Opening object detection');
        Get.to(() => const ObjectDetectPage());
        break;
      case 'scan_text':
        _ttsManager.speak(
            isThai ? 'เปิดการสแกนตัวหนังสือ' : 'Opening scan text');
        Get.to(() => const ScanTextPage());
        break;
      case 'settings':
        _ttsManager.speak(isThai ? 'เปิดการตั้งค่า' : 'Opening settings');
        Get.find<BottomNavController>().goToSettings();
        break;
      case 'home':
        _ttsManager.speak(isThai ? 'กลับหน้าหลัก' : 'Going to home');
        Get.find<BottomNavController>().goToHome();
        break;
      case 'back':
        _ttsManager.speak(isThai ? 'ย้อนกลับ' : 'Going back');
        Get.back();
        break;
      case 'switch_camera':
        _executePageAction(
          action: Get.find<VoiceActionController>().onSwitchCamera,
          speakText: isThai ? 'สลับกล้อง' : 'Switching camera',
          unavailableText: isThai
              ? 'ไม่สามารถสลับกล้องในหน้านี้ได้'
              : 'Cannot switch camera on this page',
        );
        break;
      case 'open_gallery':
        _executePageAction(
          action: Get.find<VoiceActionController>().onOpenGallery,
          speakText: isThai ? 'เปิดแกลเลอรี่' : 'Opening gallery',
          unavailableText: isThai
              ? 'ไม่สามารถเปิดแกลเลอรี่ในหน้านี้ได้'
              : 'Cannot open gallery on this page',
        );
        break;
      case 'toggle_detection':
        _executePageAction(
          action: Get.find<VoiceActionController>().onToggleDetection,
          speakText: null, // page handles its own TTS
          unavailableText: isThai
              ? 'กรุณาเปิดหน้าตรวจจับวัตถุก่อน'
              : 'Please open the object detection page first',
        );
        break;
      case 'capture_scan_text':
        _executePageAction(
          action: Get.find<VoiceActionController>().onCaptureScanText,
          speakText: isThai ? 'สแกนตัวหนังสือ' : 'Scanning text',
          unavailableText: isThai
              ? 'กรุณาเปิดหน้าสแกนตัวหนังสือก่อน'
              : 'Please open the scan text page first',
        );
        break;
      case 'select_location':
        _executePageAction(
          action: Get.find<VoiceActionController>().onSelectLocation,
          speakText: null, // page handles its own TTS
          unavailableText: isThai
              ? 'กรุณาเปิดหน้านำทางก่อน'
              : 'Please open the navigation page first',
        );
        break;
      case 'select_destination':
        _executePageAction(
          action: Get.find<VoiceActionController>().onSelectDestination,
          speakText: null,
          unavailableText: isThai
              ? 'กรุณาเปิดหน้านำทางก่อน'
              : 'Please open the navigation page first',
        );
        break;
      case 'scan_marker':
        _executePageAction(
          action: Get.find<VoiceActionController>().onScanMarker,
          speakText: null,
          unavailableText: isThai
              ? 'กรุณาเปิดหน้านำทางก่อน'
              : 'Please open the navigation page first',
        );
        break;
      case 'swap_location':
        _executePageAction(
          action: Get.find<VoiceActionController>().onSwapLocation,
          speakText: null,
          unavailableText: isThai
              ? 'กรุณาเปิดหน้านำทางก่อน'
              : 'Please open the navigation page first',
        );
        break;
      case 'start_navigation':
        _executePageAction(
          action: Get.find<VoiceActionController>().onStartNavigation,
          speakText: isThai ? 'เริ่มนำทาง' : 'Starting navigation',
          unavailableText: isThai
              ? 'กรุณาเลือกตำแหน่งและเป้าหมายก่อน'
              : 'Please select location and destination first',
        );
        break;
    }
    // onStatus 'done' will restart wake word listening
  }

  void _executePageAction({
    required void Function()? action,
    required String? speakText,
    required String unavailableText,
  }) {
    if (action != null) {
      if (speakText != null) _ttsManager.speak(speakText);
      action();
    } else {
      _ttsManager.speak(unavailableText);
    }
  }

  void _stop() {
    mode.value = VoiceMode.idle;
    _speech.stop();
  }

  void resumeListening() {
    if (!isInitialized.value) return;
    if (_settingsController.useSpeechRecognition.value &&
        !_speech.isListening) {
      _startWakeWordListening();
    }
  }
}

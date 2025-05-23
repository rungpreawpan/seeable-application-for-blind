import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/views/scan_text/controller/ocr_controller.dart';
import 'package:seeable/views/settings/model/settings_model.dart';
import 'package:seeable/widgets/main_template.dart';

class ScanTextResultPage extends StatefulWidget {
  final File? imageFile;

  const ScanTextResultPage({
    super.key,
    required this.imageFile,
  });

  @override
  State<ScanTextResultPage> createState() => _ScanTextResultPageState();
}

class _ScanTextResultPageState extends State<ScanTextResultPage> {
  final OcrController _ocrController = Get.find();

  final FlutterSecureStorage storage = const FlutterSecureStorage();

  final FlutterTts flutterTts = FlutterTts();

  SettingsModel? settingsInfo;

  @override
  void initState() {
    super.initState();

    _ttsSettings();
  }

  _ttsSettings() async {
    String? settingsData = await storage.read(key: 'settings_value');
    if (settingsData != null) {
      Map<String, dynamic> settingsValueMap = json.decode(settingsData);
      settingsInfo = SettingsModel.fromJSON(settingsValueMap);

      if (settingsInfo?.useSpeechRecognition == false) {
        return;
      } else {
        if (settingsInfo?.speed == 'slow') {
          await flutterTts.setSpeechRate(0.0);
        } else if (settingsInfo?.speed == 'fast') {
          await flutterTts.setSpeechRate(1.0);
        } else {
          await flutterTts.setSpeechRate(0.5);
        }
      }
    }

    _speak();
  }

  Future _speak() async {
    if (_ocrController.ocrText?.text != null) {
      await flutterTts.speak(_ocrController.ocrText!.text!);
    }
  }

  @override
  void dispose() {
    super.dispose();

    flutterTts.stop();
  }

  @override
  Widget build(BuildContext context) {
    return MainTemplate(
      appBarTitle: 'scan result'.tr,
      showBackButton: true,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(marginX2),
            child: Column(
              children: [
                widget.imageFile != null
                    ? Image.file(
                        widget.imageFile!,
                        fit: BoxFit.fitWidth,
                      )
                    : const SizedBox(),
                const SizedBox(height: marginX2),
                Text(
                  _ocrController.ocrText != null
                      ? _ocrController.ocrText!.text!
                      : '',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

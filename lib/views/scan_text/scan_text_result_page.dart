import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/controller/tts_manager.dart';
import 'package:seeable/views/scan_text/controller/ocr_controller.dart';
import 'package:seeable/views/settings/model/settings_model.dart';
import 'package:seeable/widgets/main_template.dart';
import 'package:seeable/widgets/text_font_style.dart';

class ScanTextResultPage extends StatefulWidget {
  final File imageFile;

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

  final ttsManager = TtsManager();

  SettingsModel? settingsInfo;

  @override
  void initState() {
    super.initState();

    _speak();
  }

  Future _speak() async {
    if (_ocrController.ocrText?.text != null) {
      await ttsManager.speak(_ocrController.ocrText!.text!);
    }
  }

  @override
  void dispose() {
    super.dispose();

    ttsManager.stop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                Image.file(
                  widget.imageFile,
                  fit: BoxFit.fitWidth,
                ),
                const SizedBox(height: marginX2),
                TextFontStyle(
                  _ocrController.ocrText != null
                      ? _ocrController.ocrText!.text!
                      : '',
                  style: theme.textTheme.displaySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

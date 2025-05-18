import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:seeable/views/scan_text/controller/ocr_controller.dart';
import 'package:seeable/widgets/main_template.dart';

class ScanTextResultPage extends StatefulWidget {
  const ScanTextResultPage({super.key});

  @override
  State<ScanTextResultPage> createState() => _ScanTextResultPageState();
}

class _ScanTextResultPageState extends State<ScanTextResultPage> {
  final OcrController _ocrController = Get.find();

  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();

    _ttsSettings();
    _speak();
  }

  _ttsSettings() async {
    await flutterTts.setSpeechRate(1.0);
  }

  Future _speak() async {
    if (_ocrController.ocrText?.text != null) {
      await flutterTts.speak(_ocrController.ocrText!.text!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainTemplate(
      appBarTitle: 'scan text'.tr, //TODO
      showBackButton: true,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              Text(
                _ocrController.ocrText != null ? _ocrController.ocrText!.text! : '',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

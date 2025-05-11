import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/views/scan_text/controller/ocr_controller.dart';
import 'package:seeable/widgets/custom_loading.dart';
import 'package:seeable/widgets/main_template.dart';
import 'package:seeable/widgets/select_camera_gallery_bottomsheet.dart';
import 'package:seeable/widgets/text_font_style.dart';

class ScanTextPage extends StatefulWidget {
  const ScanTextPage({super.key});

  @override
  State<ScanTextPage> createState() => _ScanTextPageState();
}

class _ScanTextPageState extends State<ScanTextPage> {
  final OcrController _ocrController = Get.put(OcrController());

  final FlutterTts flutterTts = FlutterTts();

  File? _imageFile;

  @override
  void initState() {
    super.initState();

    _ocrController.ocrText = null;
    _ttsSettings();
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
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainTemplate(
      appBarTitle: 'scan text'.tr,
      showBackButton: true,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _button(),
                  const SizedBox(height: marginX2),
                  _ocrImage(),
                  const SizedBox(height: marginX2),
                  _ocrLabels(),
                ],
              ),
            ),
            _loading(),
          ],
        ),
      ),
    );
  }

  _button() {
    return InkWell(
      onTap: () async {
        XFile? result =
            await Get.bottomSheet(const SelectCameraGalleryBottomSheet());

        if (result != null) {
          _imageFile = File(result.path);

          setState(() {
            _ocrController.isLoading.value = true;
          });

          await _ocrController.uploadImage(_imageFile!);

          setState(() {
            _ocrController.isLoading.value = false;
          });

          await _speak();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(marginX2),
        color: Colors.grey,
        child: const TextFontStyle('Pick Image'),
      ),
    );
  }

  _ocrImage() {
    if (_imageFile == null || _ocrController.ocrText == null) {
      return const SizedBox();
    }

    return Image.file(_imageFile!);
  }

  _ocrLabels() {
    return _ocrController.ocrText?.text != null
        ? TextFontStyle(_ocrController.ocrText!.text!)
        : const SizedBox();
  }

  _loading() {
    return Obx(() {
      return Visibility(
        visible: _ocrController.isLoading.value,
        child: const CustomLoading(),
      );
    });
  }
}

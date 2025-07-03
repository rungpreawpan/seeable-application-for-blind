import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/controller/tts_manager.dart';
import 'package:seeable/views/object_detection/controller/object_detection_controller.dart';
import 'package:seeable/views/object_detection/model/object_detection_model.dart';
import 'package:seeable/views/settings/controller/settings_controller.dart';
import 'package:seeable/widgets/custom_loading.dart';
import 'package:seeable/widgets/main_template.dart';
import 'package:seeable/widgets/text_font_style.dart';
import 'package:translator/translator.dart';

class ObjectDetectionResultPage extends StatefulWidget {
  final File imageFile;

  const ObjectDetectionResultPage({
    super.key,
    required this.imageFile,
  });

  @override
  State<ObjectDetectionResultPage> createState() =>
      _ObjectDetectionResultPageState();
}

class _ObjectDetectionResultPageState extends State<ObjectDetectionResultPage> {
  final ObjectDetectionController _objectDetectionController = Get.find();
  final SettingsController _settingsController = Get.find();

  final FlutterSecureStorage storage = const FlutterSecureStorage();

  final ttsManager = TtsManager();
  final translator = GoogleTranslator();

  Size? _imageSize;
  final Map<int, Color> _objectColors = {};

  String? translatedText;

  @override
  void initState() {
    super.initState();

    _prepareData();
  }

  _prepareData() async {
    _imageSize = await getImageSize(widget.imageFile);
    final random = math.Random();
    _objectDetectionController.objectDetected?.boxes
        ?.asMap()
        .forEach((index, _) {
      _objectColors[index] =
          Color((random.nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
    });

    setState(() {});

    _speak();
  }

  Future _speak() async {
    if (_objectDetectionController.objectDetected?.boxes != null) {
      List<String> objects = [];
      translatedText = null;

      for (BoxesModel object
          in _objectDetectionController.objectDetected!.boxes!) {
        if (object.label != null) {
          objects.add(object.label!);
        }
      }

      if (objects.isNotEmpty) {
        List translations = await Future.wait(
          objects.map((obj) async {
            // TODO
            Translation? translation;

            if (_settingsController.currentLocale.value.languageCode == 'th') {
              translation = await translator.translate(obj, to: 'th');
            } else {
              translation = await translator.translate(obj, to: 'en');
            }

            return translation.text;
          }),
        );

        translatedText = translations.toSet().toList().join(', ');
        await ttsManager.speak('${'detected'.tr} $translatedText');
      } else {
        await ttsManager.speak('unable to detect objects'.tr);
      }
    }
  }

  @override
  void dispose() {
    super.dispose();

    ttsManager.stop();
  }

  @override
  Widget build(BuildContext context) {
    return MainTemplate(
      appBarTitle: 'object detection results'.tr,
      showBackButton: true,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(marginX2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _objectImage(),
                    const SizedBox(height: marginX2),
                    _objectLabels(),
                  ],
                ),
              ),
            ),
            _loading(),
          ],
        ),
      ),
    );
  }

  _objectImage() {
    if (_objectDetectionController.objectDetected == null ||
        _imageSize == null) {
      return const SizedBox();
    }

    // print(imageSize);
    // print(_objectDetectionController.objectDetected?.imageWidth);
    // print(_objectDetectionController.objectDetected?.imageHeight);

    double displayWidth = Get.width;
    double scaleX =
        displayWidth / _objectDetectionController.objectDetected!.imageWidth!;
    double scaleY = (displayWidth * _imageSize!.height / _imageSize!.width) /
        _objectDetectionController.objectDetected!.imageHeight!;
    // print(scaleX);
    // print(scaleY);

    return Stack(
      children: [
        Image.file(widget.imageFile),
        ..._objectDetectionController.objectDetected!.boxes!
            .asMap()
            .entries
            .map((object) {
          final index = object.key;
          double left = object.value.x1! * scaleX;
          double top = object.value.y1! * scaleY;
          double width = (object.value.x2! - object.value.x1!) * scaleX;
          double height = (object.value.y2! - object.value.y1!) * scaleY;

          return Positioned(
            left: left,
            top: top,
            width: width,
            height: height,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _objectColors[index] ?? Colors.yellow,
                  width: 2.0,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  _objectLabels() {
    final theme = Theme.of(context);

    return _objectDetectionController.objectDetected != null &&
            _objectDetectionController.objectDetected!.boxes!.isNotEmpty
        ? ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _objectDetectionController.objectDetected!.boxes!.length,
            itemBuilder: (context, index) {
              BoxesModel item =
                  _objectDetectionController.objectDetected!.boxes![index];

              return ListTile(
                leading: Container(
                  height: 40.0,
                  width: 40.0,
                  color: _objectColors[index] ?? Colors.yellow,
                ),
                title: TextFontStyle(
                  '${item.label} ${(item.confidence! * 100).toStringAsFixed(2)}%',
                  style: theme.textTheme.displaySmall,
                ),
              );
            },
          )
        : TextFontStyle(
            'unable to detect objects'.tr,
            style: theme.textTheme.displaySmall,
          );
  }

  Future<Size?> getImageSize(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return null;

    return Size(image.width.toDouble(), image.height.toDouble());
  }

  _loading() {
    return Obx(() {
      return Visibility(
        visible: _objectDetectionController.isLoading.value,
        child: const CustomLoading(),
      );
    });
  }
}

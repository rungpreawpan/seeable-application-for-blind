import 'dart:io';

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/views/object_detection/object_detect_server/controller/object_detection_controller.dart';
import 'package:seeable/views/object_detection/object_detect_server/model/object_detection_model.dart';
import 'package:seeable/widgets/custom_loading.dart';
import 'package:seeable/widgets/select_camera_gallery_bottomsheet.dart';
import 'package:seeable/widgets/text_font_style.dart';
import 'package:image/image.dart' as img;

class ObjectDetectServerPage extends StatefulWidget {
  const ObjectDetectServerPage({super.key});

  @override
  State<ObjectDetectServerPage> createState() => _ObjectDetectServerPageState();
}

class _ObjectDetectServerPageState extends State<ObjectDetectServerPage> {
  final ObjectDetectionController _objectDetectionController =
      Get.put(ObjectDetectionController());

  File? _imageFile;
  Size? imageSize;

  @override
  void initState() {
    super.initState();

    _objectDetectionController.objectDetected = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  _button(),
                  const SizedBox(height: marginX2),
                  _objectImage(),
                  const SizedBox(height: marginX2),
                  _objectLabels(),
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
          imageSize = await getImageSize(_imageFile!);

          setState(() {
            _objectDetectionController.isLoading.value = true;
          });

          await _objectDetectionController.uploadObject(_imageFile!);

          setState(() {
            _objectDetectionController.isLoading.value = false;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(marginX2),
        color: Colors.grey,
        child: const TextFontStyle('Pick Image'),
      ),
    );
  }

  _objectImage() {
    if (_imageFile == null ||
        _objectDetectionController.objectDetected == null ||
        imageSize == null) {
      return const SizedBox();
    }

    print(imageSize);
    print(_objectDetectionController.objectDetected?.imageWidth);
    print(_objectDetectionController.objectDetected?.imageHeight);

    double displayWidth = Get.width;
    double scaleX =
        displayWidth / _objectDetectionController.objectDetected!.imageWidth!;
    double scaleY = (displayWidth * imageSize!.height / imageSize!.width) /
        _objectDetectionController.objectDetected!.imageHeight!;
    print(scaleX);
    print(scaleY);

    return Stack(
      children: [
        Image.file(_imageFile!),
        ..._objectDetectionController.objectDetected!.boxes!.map((object) {
          double left = object.x1! * scaleX;
          double top = object.y1! * scaleY;
          double width = (object.x2! - object.x1!) * scaleX;
          double height = (object.y2! - object.y1!) * scaleY;

          return Positioned(
            left: left,
            top: top,
            width: width,
            height: height,
            // left: object.x1,
            // top: object.y1,
            // width: object.x2! - object.x1!,
            // height: object.y2! - object.y1!,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.yellow,
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
    return _objectDetectionController.objectDetected != null &&
            _objectDetectionController.objectDetected!.boxes!.isNotEmpty
        ? ListView.builder(
            shrinkWrap: true,
            itemCount: _objectDetectionController.objectDetected!.boxes!.length,
            itemBuilder: (context, index) {
              BoxesModel item =
                  _objectDetectionController.objectDetected!.boxes![index];

              return ListTile(
                leading: Container(
                  height: 40.0,
                  width: 40.0,
                  color: Color((math.Random().nextDouble() * 0xFFFFFF).toInt())
                      .withOpacity(1.0),
                ),
                title: TextFontStyle(
                    '${item.label} ${(item.confidence! * 100).toStringAsFixed(2)}%'),
              );
            },
          )
        : const SizedBox();
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

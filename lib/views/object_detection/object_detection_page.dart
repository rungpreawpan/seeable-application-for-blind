import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/views/object_detection/test/yolo_home.dart';
import 'package:seeable/views/object_detection/yolo_detector.dart';
import 'package:seeable/widgets/custom_back_button.dart';
import 'package:seeable/widgets/select_camera_gallery_bottomsheet.dart';
import 'package:seeable/widgets/text_font_style.dart';

class ObjectDetectionPage extends StatefulWidget {
  const ObjectDetectionPage({super.key});

  @override
  State<ObjectDetectionPage> createState() => _ObjectDetectionPageState();
}

class _ObjectDetectionPageState extends State<ObjectDetectionPage> {
  File? _imageFile;

  Future getImageFromCamera() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      _imageFile = File(pickedFile.path);
    }

    setState(() {});
  }

  Future getImageFromGallery() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _imageFile = File(pickedFile.path);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextFontStyle(
          'object detection'.tr,
          size: fontAppbar,
          color: primaryColor,
          weight: FontWeight.bold,
          align: TextAlign.center,
        ),
        leading: const CustomBackButton(),
        centerTitle: true,
        backgroundColor: Colors.white,
        toolbarHeight: 90.0,
        elevation: 0.0,
      ),
      body: SizedBox.expand(
        child: Column(
          children: [
            _imageFile != null
                ? SizedBox(
                    height: 300,
                    width: 300,
                    child: Image.file(
                      _imageFile!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Container(
                    height: 300,
                    width: 300,
                    color: Colors.grey,
                  ),
            const SizedBox(height: marginX2),
            InkWell(
              onTap: () {
                // Get.to(() => );
                // Get.to(() => YoloHome());
                // Get.to(() => TestYolo());
                // Get.bottomSheet(
                //   SelectCameraGalleryBottomSheet(
                //     getImageFromCamera: getImageFromCamera,
                //     getImageFromGallery: getImageFromGallery,
                //   ),
                // );
              },
              child: Container(
                width: 150.0,
                padding: const EdgeInsets.all(marginX2),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: const Center(
                  child: TextFontStyle('Choose image'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

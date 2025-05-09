import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seeable/views/object_detection/server/controller/object_detection_controller.dart';
import 'package:seeable/widgets/custom_loading.dart';
import 'package:seeable/widgets/main_template.dart';
class RealTimeObjectDetectServerPage extends StatefulWidget {
  const RealTimeObjectDetectServerPage({super.key});

  @override
  State<RealTimeObjectDetectServerPage> createState() =>
      _RealTimeObjectDetectServerPageState();
}

class _RealTimeObjectDetectServerPageState
    extends State<RealTimeObjectDetectServerPage> {
  final ObjectDetectionController _objectDetectionController = Get.put(ObjectDetectionController());

  File? _imageFile;

  @override
  Widget build(BuildContext context) {
    return MainTemplate(
      appBarTitle: 'object detection'.tr,
      showBackButton: true,
      body: Stack(
        children: [
          Column(
            children: [],
          ),
          _loading(),
        ],
      ),
    );
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

import 'dart:io';

import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'dart:ui' as ui;
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:image_picker/image_picker.dart';

class ObjectDetectMlKit extends GetView<HomeController> {
  const ObjectDetectMlKit({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(HomeController());
    return GetBuilder<HomeController>(builder: (context) {
      return Scaffold(
          appBar: AppBar(
            title: Text("Object Detector flutter"),
            centerTitle: true,
            toolbarHeight: 40,
          ),
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                controller.isLoading.value
                    ? Center(child: CircularProgressIndicator())
                    : Center(
                        child: Container(
                          width: Get.width,
                          height: 200,
                          padding: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey)),
                          child: (controller.selectedImagePath.value.isEmpty)
                              ? Center(child: Text('No image selected'))
                              : FittedBox(
                                  child: SizedBox(
                                    width: controller.iimage?.width.toDouble(),
                                    height:
                                        controller.iimage?.height.toDouble(),
                                    child: Image.file(File(
                                        controller.selectedImagePath.value)),
                                  ),
                                ),
                        ),
                      ),
                SelectedButton(
                  btnColor: Colors.white,
                  press: () {
                    controller.getImageAndDetectObjects();
                  },
                  text: "Pick Image",
                ),
                Container(
                  width: Get.width,
                  height: 200,
                  padding: EdgeInsets.all(5),
                  decoration:
                      BoxDecoration(border: Border.all(color: Colors.grey)),
                  child: (controller.iimageFile == null)
                      ? const Center(child: Text('No object detected in image'))
                      : FittedBox(
                          child: SizedBox(
                            width: controller.iimage?.width.toDouble(),
                            height: controller.iimage?.height.toDouble(),
                            child: CustomPaint(
                              painter: ObjectPainter(
                                  controller.iimage!, controller.objectss!),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ));
    });
  }
}

class SelectedButton extends StatelessWidget {
  final String text;
  final Color btnColor;
  final Function? press;

  const SelectedButton({
    super.key,
    required this.text,
    required this.btnColor,
    this.press,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: Get.width,
      child: TextButton(
        style: TextButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: btnColor,
        ),
        onPressed: press as void Function()?,
        child: Text(
          text!,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

class ObjectPainter extends CustomPainter {
  final ui.Image image;
  final List<DetectedObject> objects;
  final List<Rect> rects = [];

  ObjectPainter(this.image, this.objects) {
    for (var i = 0; i < objects.length; i++) {
      rects.add(objects[i].boundingBox);
    }
  }

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.green;

    canvas.drawImage(image, Offset.zero, Paint());
    for (var i = 0; i < objects.length; i++) {
      canvas.drawRect(rects[i], paint);
    }
  }

  @override
  bool shouldRepaint(ObjectPainter oldDelegate) {
    return image != oldDelegate.image || objects != oldDelegate.objects;
  }
}

class HomeController extends GetxController {
  var selectedImagePath = ''.obs;
  RxBool isLoading = false.obs;
  XFile? iimageFile;
  List<DetectedObject>? objectss;
  ui.Image? iimage;
  late final ObjectDetector objectDetector;

  @override
  void onInit() {
    super.onInit();
    objectDetector = ObjectDetector(
      options: ObjectDetectorOptions(
        mode: DetectionMode.single,
        classifyObjects: true,
        multipleObjects: true,
      ),
    );
  }

  Future<void> getImageAndDetectObjects() async {
    final imageFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (imageFile == null) return;

    isLoading.value = true;
    selectedImagePath.value = imageFile.path;

    final inputImage = InputImage.fromFilePath(imageFile.path);
    try {
      List<DetectedObject> objects = await objectDetector.processImage(inputImage);

      iimageFile = imageFile;
      objectss = objects;
      print(objectss);
      await _loadImage(imageFile);
    } catch (e) {
      print('Error detecting objects: $e');
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<void> _loadImage(XFile file) async {
    final data = await file.readAsBytes();
    iimage = await decodeImageFromList(data);
  }

  @override
  void onClose() {
    objectDetector.close();
    super.onClose();
  }
}

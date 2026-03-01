import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:seeable/service/request_service.dart';
import 'package:seeable/utils/alert.dart';
import 'package:seeable/views/object_detection/model/object_detection_model.dart';

class ObjectDetectionController extends GetxController {
  var isLoading = false.obs;

  ObjectDetectionModel? objectDetected;

  uploadObject(File object) async {
    bool isOnline = await RequestService().checkInternetConnection();

    if (!isOnline) {
      showAlert('no internet connection'.tr);
      isLoading.value = false;

      return;
    }

    try {
      isLoading.value = true;

      var reqData = {
        "image":
            MultipartFile.fromFileSync(object.path, filename: 'object_image'),
      };

      FormData formData = FormData.fromMap(reqData);

      var response = await RequestService().request(
        '/object-detection',
        method: HttpMethod.post,
        data: formData,
      );

      if (response != null && response.statusCode == 200) {
        Map<String, dynamic> dataMap = response.data;
        Map<String, dynamic> dataJSON = dataMap['objects'];
        log(dataJSON.toString());

        objectDetected = ObjectDetectionModel.fromJSON(dataJSON);
      }
    } catch (e) {
      log(e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}

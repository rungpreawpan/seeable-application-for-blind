import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:seeable/service/request_service.dart';
import 'package:seeable/utils/alert.dart';
import 'package:seeable/views/scan_text/model/ocr_model.dart';

class OcrController extends GetxController {
  var isLoading = false.obs;

  OcrModel? ocrText;

  uploadText(File image) async {
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
            MultipartFile.fromFileSync(image.path, filename: 'object_image'),
      };

      FormData formData = FormData.fromMap(reqData);

      var response = await RequestService().request(
        '/ocr',
        method: HttpMethod.post,
        data: formData,
      );

      if (response != null && response.statusCode == 200) {
        Map<String, dynamic> dataMap = response.data;

        ocrText = OcrModel.fromJSON(dataMap);
      }
    } catch (e) {
      log(e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}

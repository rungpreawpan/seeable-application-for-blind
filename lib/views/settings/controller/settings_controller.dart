import 'dart:developer';

import 'package:get/get.dart';
import 'package:seeable/service/request_service.dart';
import 'package:seeable/utils/alert.dart';
import 'package:seeable/widgets/custom_alert_dialog.dart';

class SettingsController extends GetxController {
  var isLoading = false.obs;

  contactDev({
    required String name,
    required String email,
    required String message,
  }) async {
    bool isOnline = await RequestService().checkInternetConnection();

    if (!isOnline) {
      showAlert('ไม่มีสัญญาณอินเตอร์เน็ต');
      isLoading.value = false;

      return;
    }

    try {
      isLoading.value = true;

      var response = await RequestService().request(
        '/contact-dev',
        method: HttpMethod.post,
        data: {
          'name': name,
          'email': email,
          'message': message,
        },
      );

      if (response != null && response.statusCode == 200) {
        Get.dialog(
          CustomAlertDialog(
            title: 'send message successfully'.tr,
            onOk: () {
              Get.back();
            },
          ),
        );
      }
    } catch (e) {
      log(e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}

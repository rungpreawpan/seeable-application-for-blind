import 'dart:developer';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:seeable/service/request_service.dart';
import 'package:seeable/utils/alert.dart';
import 'package:seeable/views/login/login_page.dart';
import 'package:seeable/widgets/custom_alert_dialog.dart';

class RegisterController extends GetxController {
  var isLoading = false.obs;
  FlutterSecureStorage storage = const FlutterSecureStorage();

  validateRegister({
    required String firstname,
    required String lastname,
    required String username,
    required String password,
    required String email,
  }) async {
    if (firstname == '') {
      Get.dialog(
        CustomAlertDialog(title: '${'please enter your'.tr}${'firstname'.tr}'),
      );

      return;
    }

    if (lastname == '') {
      Get.dialog(
        CustomAlertDialog(title: '${'please enter your'.tr}${'lastname'.tr}'),
      );

      return;
    }

    if (username == '') {
      Get.dialog(
        CustomAlertDialog(title: '${'please enter your'.tr}${'username'.tr}'),
      );

      return;
    }

    if (password == '') {
      Get.dialog(
        CustomAlertDialog(title: '${'please enter your'.tr}${'password'.tr}'),
      );

      return;
    }

    if (email == '') {
      Get.dialog(
        CustomAlertDialog(title: '${'please enter your'.tr}${'email'.tr}'),
      );

      return;
    }

    await register(
      firstname: firstname,
      lastname: lastname,
      username: username,
      password: password,
      email: email,
    );
  }

  register({
    required String firstname,
    required String lastname,
    required String username,
    required String password,
    required String email,
  }) async {
    bool isOnline = await RequestService().checkInternetConnection();

    if (!isOnline) {
      showAlert('no internet connection'.tr);
      isLoading.value = false;

      return;
    }

    try {
      isLoading.value = true;

      var response = await RequestService().request(
        '/register',
        method: HttpMethod.post,
        data: {
          'firstname': firstname,
          'lastname': lastname,
          'username': username,
          'password': password,
          'email': email,
        },
      );

      if (response != null && response.statusCode == 201) {
        Get.dialog(
          CustomAlertDialog(
            title: 'register success'.tr,
            onOk: () async {
              await storage.write(key: 'register', value: 'true');
              Get.offAll(() => const LoginPage());
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

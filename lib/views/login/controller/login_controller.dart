import 'dart:developer';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:seeable/service/request_service.dart';
import 'package:seeable/utils/alert.dart';
import 'package:seeable/views/home/home_page.dart';
import 'package:seeable/views/login/model/user_model.dart';
import 'package:seeable/widgets/custom_alert_dialog.dart';

class LoginController extends GetxController {
  var isLoading = false.obs;
  FlutterSecureStorage storage = const FlutterSecureStorage();

  UserModel? user;

  validateLogin({
    required String username,
    required String password,
  }) async {
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

    await login(
      username: username,
      password: password,
    );
  }

  login({
    required String username,
    required String password,
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
        '/login',
        method: HttpMethod.post,
        data: {
          'username': username,
          'password': password,
        },
      );

      if (response != null && response.statusCode == 200) {
        await storage.write(key: 'register', value: 'true');
        await storage.write(key: 'login', value: 'true');

        await Get.offAll(() => const HomePage());
      }
    } catch (e) {
      log(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  getUser({required String uuid}) async {
    bool isOnline = await RequestService().checkInternetConnection();

    if (!isOnline) {
      showAlert('ไม่มีสัญญาณอินเตอร์เน็ต');
      isLoading.value = false;

      return;
    }

    try {
      isLoading.value = true;

      var response = await RequestService().request(
        '/user/$uuid',
        method: HttpMethod.get,
      );

      if (response != null && response.statusCode == 201) {
        // user = UserModel.fromJSON(response);
      }
    } catch (e) {
      log(e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}

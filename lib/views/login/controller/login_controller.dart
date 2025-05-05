import 'dart:convert';
import 'dart:developer';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:seeable/service/request_service.dart';
import 'package:seeable/utils/alert.dart';
import 'package:seeable/views/login/model/user_model.dart';
import 'package:seeable/widgets/custom_alert_dialog.dart';
import 'package:seeable/widgets/custom_nav_bar.dart';

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
        Map<String, dynamic> dataMap = response.data;
        Map<String, dynamic> dataJSON = dataMap['user'];

        user = UserModel.fromJSON(dataJSON);

        String userData = jsonEncode({
          'uuid': user?.uuid,
          'firstname': user?.firstname,
          'lastname': user?.lastname,
          'email': user?.email,
          'username': username,
        });

        await storage.write(key: 'register', value: 'true');
        await storage.write(key: 'login', value: 'true');
        await storage.write(key: 'user_data', value: userData);

        await Get.offAll(() => const CustomNavBar());
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

      if (response != null && response.statusCode == 200) {
        user = UserModel.fromJSON(response.data);

        String userData = jsonEncode({
          'uuid': user?.uuid,
          'firstname': user?.firstname,
          'lastname': user?.lastname,
          'email': user?.email,
          'username': user?.username,
        });

        await storage.write(key: 'user_data', value: userData);
      }
    } catch (e) {
      log(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  updateUser({
    required String uuid,
    required dynamic data,
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
        '/users/$uuid',
        method: HttpMethod.put,
        data: data,
      );

      if (response != null && response.statusCode == 200) {
        await getUser(uuid: uuid);

        Get.dialog(
          CustomAlertDialog(
            title: 'data update successful'.tr,
            onOk: () {
              Get.back(result: true);
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

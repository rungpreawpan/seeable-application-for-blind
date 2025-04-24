import 'dart:developer';

import 'package:get/get.dart';
import 'package:seeable/service/request_service.dart';
import 'package:seeable/utils/alert.dart';
import 'package:seeable/views/login/login_page.dart';
import 'package:seeable/views/login/reset_password_page.dart';
import 'package:seeable/views/login/send_otp_page.dart';
import 'package:seeable/widgets/custom_alert_dialog.dart';

class ForgetPasswordController extends GetxController {
  var isLoading = false.obs;

  String? user;
  String? reference;

  validateForgetPassword({
    required String username,
    required String email,
  }) async {
    if (username == '') {
      Get.dialog(
        CustomAlertDialog(title: '${'please enter your'.tr}${'username'.tr}'),
      );

      return;
    }

    if (email == '') {
      Get.dialog(
        CustomAlertDialog(title: '${'please enter your'.tr}${'email'.tr}'),
      );

      return;
    }

    await forgetPassword(
      username: username,
      email: email,
    );
  }

  validateSendOTP({required String otp}) async {
    if (otp == '') {
      Get.dialog(
        CustomAlertDialog(title: '${'please enter your'.tr}${'otp'.tr}'),
      );

      return;
    }

    await verifyOTP(
      username: user ?? '',
      otp: otp,
      reference: reference ?? '',
    );
  }

  validateResetPassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (newPassword == '') {
      Get.dialog(
        CustomAlertDialog(title: '${'please enter your'.tr}${'password'.tr}'),
      );

      return;
    }

    if (confirmPassword == '') {
      Get.dialog(
        CustomAlertDialog(title: '${'please enter your'.tr}${'confirm password'.tr}'),
      );

      return;
    }

    if (newPassword != confirmPassword) {
      Get.dialog(
        CustomAlertDialog(title: 'password not match'.tr),
      );

      return;
    }

    await resetPassword(newPassword: newPassword);
  }

  forgetPassword({
    required String username,
    required String email,
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
        '/forget/request-reset',
        method: HttpMethod.post,
        data: {
          'username': username,
          'email': email,
        },
      );

      if (response != null && response.statusCode == 200) {
        var dataJSON = response.data;
        reference = dataJSON['reference'];
        user = username;

        Get.to(() => const SendOtpPage());
      }
    } catch (e) {
      log(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  verifyOTP({
    required String username,
    required String otp,
    required String reference,
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
        '/forget/verify-otp',
        method: HttpMethod.post,
        data: {
          'username': user,
          'otp': otp,
          'reference': reference,
        },
      );

      if (response != null && response.statusCode == 200) {
        Get.to(() => const ResetPasswordPage());
      }
    } catch (e) {
      log(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  resetPassword({required String newPassword}) async {
    bool isOnline = await RequestService().checkInternetConnection();

    if (!isOnline) {
      showAlert('ไม่มีสัญญาณอินเตอร์เน็ต');
      isLoading.value = false;

      return;
    }

    try {
      isLoading.value = true;

      var response = await RequestService().request(
        '/forget/reset-password',
        method: HttpMethod.post,
        data: {
          'username': user,
          'new_password': newPassword,
        },
      );

      if (response != null && response.statusCode == 200) {
        var dataJSON = response.data;
        String message = dataJSON['message'];

        Get.dialog(
          CustomAlertDialog(
            title: message,
            onOk: () {
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

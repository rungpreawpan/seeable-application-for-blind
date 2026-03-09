import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:seeable/service/request_service.dart';
import 'package:seeable/utils/alert.dart';
import 'package:seeable/views/navigation/controller/aruco_detector.dart';
import 'package:seeable/views/navigation/model/ar_markers_model.dart';
import 'package:seeable/views/navigation/model/navigation_path_model.dart';
import 'package:seeable/views/navigation/model/obstacle_model.dart';
import 'package:seeable/views/navigation/model/update_position_model.dart';

class NavigationController extends GetxController {
  var isLoading = false.obs;
  var isScanning = false.obs;

  bool navigateByScan = false;

  List<ArMarkersModel> markersList = [];
  List<ArMarkersModel> frontDoorMarkersList = [];
  List<ArMarkersModel> selectedStartMarker = [];
  List<ArMarkersModel> selectedDestinationMarker = [];

  ArMarkersModel? detectedMarker;

  File? destinationMarkerImage;

  NavigationPathModel? navigationData;
  String? sessionId;

  UpdatePositionModel? positionData;
  RxnString updatePositionStatus = RxnString();
  RxnString updatePositionMessage = RxnString();

  bool stopUpdatePosition = false;

  ObstacleModel? obstacleDetected;

  ArucoDetector arDetector = ArucoDetector();

  getAllMarkers() async {
    bool isOnline = await RequestService().checkInternetConnection();

    if (!isOnline) {
      showAlert('no internet connection'.tr);
      isLoading.value = false;

      return;
    }

    try {
      isLoading.value = true;

      var response = await RequestService().request(
        '/ar-markers',
        method: HttpMethod.get,
      );

      if (response != null && response.statusCode == 200) {
        var dataJSON = response.data;
        markersList = dataJSON
            .map<ArMarkersModel>((json) => ArMarkersModel.fromJSON(json))
            .toList();
      }
    } catch (e) {
      log(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  getAllFrontDoors() async {
    bool isOnline = await RequestService().checkInternetConnection();

    if (!isOnline) {
      showAlert('no internet connection'.tr);
      isLoading.value = false;

      return;
    }

    try {
      isLoading.value = true;

      var response = await RequestService().request(
        '/ar-markers/front',
        method: HttpMethod.get,
      );

      if (response != null && response.statusCode == 200) {
        var dataJSON = response.data;
        frontDoorMarkersList = dataJSON
            .map<ArMarkersModel>((json) => ArMarkersModel.fromJSON(json))
            .toList();
      }
    } catch (e) {
      log(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  detectAndNavigate({
    String startMarker = '',
    required String destination,
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
        '/ar-markers/detect-and-navigate',
        method: HttpMethod.post,
        data: {
          'start_marker': startMarker,
          'destination': destination,
        },
      );

      if (response != null && response.statusCode == 200) {
        Map<String, dynamic> dataMap = response.data;
        log(dataMap.toString());

        navigationData = NavigationPathModel.fromJSON(dataMap);
        sessionId = navigationData?.sessionId;
      }
    } catch (e) {
      log(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  updatePosition({
    File? markerImage,
    String? detectedMarker,
  }) async {
    bool isOnline = await RequestService().checkInternetConnection();

    if (!isOnline) {
      showAlert('no internet connection'.tr);
      isLoading.value = false;

      return;
    }

    try {
      isLoading.value = true;

      clearUpdatePosition();

      FormData formData = FormData();

      if (markerImage != null) {
        formData = FormData.fromMap({
          'session_id': sessionId,
          'image': MultipartFile.fromFileSync(markerImage.path,
              filename: 'marker_image'),
        });
      } else {
        formData = FormData.fromMap({
          'session_id': sessionId,
          'detected_marker': detectedMarker,
        });
      }

      var response = await RequestService().request(
        '/ar-markers/update-position',
        method: HttpMethod.post,
        data: formData,
      );

      if (response != null && response.statusCode == 200) {
        Map<String, dynamic> dataMap = response.data;
        log(dataMap.toString());

        positionData = UpdatePositionModel.fromJSON(dataMap);
        updatePositionStatus.value = positionData?.status;
        String distance = positionData?.remainingDistance.toString() ?? '0';

        if (updatePositionStatus.value == 'ON_PATH') {
          updatePositionMessage.value =
              '${'continue walking'.tr} ${'meter_remaining'.trParams({
                'distance': distance.toString()
              })}';
        } else if (updatePositionStatus.value == 'OFF_PATH') {
          updatePositionMessage.value = 'you are off path'.tr;
        } else if (updatePositionStatus.value == 'OVERSHOOT') {
          updatePositionMessage.value = 'you have passed the destination'.tr;
        } else if (updatePositionStatus.value == 'ARRIVED') {
          updatePositionMessage.value = 'you are arrived'.tr;

          stopUpdatePosition = true;
        }
      }
    } catch (e) {
      log(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  uploadObstacle(File obstacle) async {
    bool isOnline = await RequestService().checkInternetConnection();

    if (!isOnline) {
      showAlert('no internet connection'.tr);
      isLoading.value = false;

      return;
    }

    try {
      isLoading.value = true;

      var reqData = {
        "image": MultipartFile.fromFileSync(obstacle.path,
            filename: 'obstacle_image'),
      };

      FormData formData = FormData.fromMap(reqData);

      var response = await RequestService().request(
        '/obstacle-detection',
        method: HttpMethod.post,
        data: formData,
      );

      if (response != null && response.statusCode == 200) {
        Map<String, dynamic> dataMap = response.data;
        Map<String, dynamic> dataJSON = dataMap['obstacle'];
        log(dataJSON.toString());

        obstacleDetected = ObstacleModel.fromJSON(dataJSON);
      }
    } catch (e) {
      log(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  detectARUcoMarker({
    bool isAllMarker = true,
    required CameraImage? cameraImage,
  }) async {
    if (cameraImage != null) {
      final markerId = await arDetector.detectMarker(cameraImage);

      if (isAllMarker) {
        detectedMarker = null;

        for (ArMarkersModel marker in markersList) {
          if (marker.markerId != null && marker.markerId! == markerId) {
            detectedMarker = marker;
          }
        }

        if (detectedMarker != null) {
          await updatePosition(
              detectedMarker: detectedMarker?.markerName?.replaceAll('-', ''));
        }
      } else {
        selectedStartMarker.clear();

        for (ArMarkersModel marker in frontDoorMarkersList) {
          if (marker.markerId != null && marker.markerId! == markerId) {
            selectedStartMarker.add(marker);

            Get.back(result: selectedStartMarker);
          }
        }
      }
    }
  }

  clearData() {
    selectedStartMarker.clear();
    selectedDestinationMarker.clear();
    destinationMarkerImage = null;
  }

  clearUpdatePosition() {
    updatePositionMessage.value = null;
    updatePositionStatus.value = null;
    stopUpdatePosition = false;
  }
}

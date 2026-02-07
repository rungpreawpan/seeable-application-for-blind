import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/views/navigation/controller/navigation_controller.dart';
import 'package:seeable/widgets/custom_submit_button.dart';
import 'package:seeable/widgets/main_template.dart';

class ArNavigationPage extends StatefulWidget {
  const ArNavigationPage({super.key});

  @override
  State<ArNavigationPage> createState() => _ArNavigationPageState();
}

class _ArNavigationPageState extends State<ArNavigationPage> {
  final NavigationController _navigationController = Get.find();

  @override
  void initState() {
    super.initState();

    // _prepareData();
  }

  // _prepareData() {
  //
  // }

  @override
  Widget build(BuildContext context) {
    return MainTemplate(
      appBarTitle: 'navigation'.tr,
      showBackButton: true,
      body: Column(
        children: [
          _map(),
          _navigationButton(),
        ],
      ),
    );
  }

  _map() {
    return Expanded(
      child: Container(
        color: Colors.grey,
      ),
    );
  }

  _navigationButton() {
    return CustomSubmitButton(
      onTap: () async {
        // _navigationController.destinationMarker != null
        //     ? _navigationController.detectAndNavigate(
        //         startMarker: 'C303F',
        //         destination: _navigationController.destinationMarker!.markerName!
        //             .replaceAll('-', ''))
        //     : null;
      },
      title: 'start'.tr,
      borderRadius: 25.0,
      buttonMargin: const EdgeInsets.all(marginX2),
    );
  }
}

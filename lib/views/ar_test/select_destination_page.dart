import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/controller/tts_manager.dart';
import 'package:seeable/views/ar_test/ar_navigate_page.dart';
import 'package:seeable/views/ar_test/ar_scan_page.dart';
import 'package:seeable/views/navigation/controller/navigation_controller.dart';
import 'package:seeable/views/navigation/model/ar_markers_model.dart';
import 'package:seeable/widgets/custom_item_picker.dart';
import 'package:seeable/widgets/custom_item_picker_cell.dart';
import 'package:seeable/widgets/custom_loading.dart';
import 'package:seeable/widgets/custom_submit_button.dart';
import 'package:seeable/widgets/main_template.dart';
import 'package:seeable/widgets/text_font_style.dart';

class SelectDestinationPage extends StatefulWidget {
  const SelectDestinationPage({super.key});

  @override
  State<SelectDestinationPage> createState() => _SelectDestinationPageState();
}

class _SelectDestinationPageState extends State<SelectDestinationPage> {
  final NavigationController _navigationController =
  Get.put(NavigationController());

  final ttsManager = TtsManager();

  @override
  void initState() {
    super.initState();

    _prepareData();
  }

  _prepareData() async {
    _navigationController.clearData();
    await _navigationController.getAllMarkers();
    await _navigationController.getAllFrontDoors();

    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();

    ttsManager.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MainTemplate(
          appBarTitle: 'navigation'.tr,
          showBackButton: true,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(
                left: marginX2,
                right: marginX2,
                bottom: marginX2,
              ),
              child: _content(),
            ),
          ),
        ),
        _loading(),
      ],
    );
  }

  _content() {
    return Column(
      children: [
        _selectedLocation(),
        _map(),
        _navigationButton(),
      ],
    );
  }

  _selectedLocation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: marginX2),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 10.0,
                backgroundColor: Colors.grey.shade400,
                child: Center(
                  child: CircleAvatar(
                    radius: 6.0,
                    backgroundColor: Colors.grey.shade600,
                  ),
                ),
              ),
              const SizedBox(height: 4.0),
              const SizedBox(
                height: 20.0,
                child: DottedLine(
                  direction: Axis.vertical,
                  lineThickness: 2.0,
                ),
              ),
              SvgPicture.asset(
                'assets/icons/location_icon.svg',
                height: 26.0,
              ),
            ],
          ),
          const SizedBox(width: margin),
          Expanded(
            child: Column(
              children: [
                _start(),
                Container(
                  height: 1.0,
                  color: Colors.grey.shade400,
                ),
                _destination(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _start() {
    return _selectedButton(
      child: Semantics(
        button: true,
        label: _navigationController.selectedStartMarker.isNotEmpty
            ? '${'your location'.tr} ${_navigationController.selectedStartMarker.first.markerName?.substring(0, 4)}'
            : 'your location'.tr,
        child: Row(
          children: [
            TextFontStyle(
              _navigationController.selectedStartMarker.isNotEmpty
                  ? _navigationController.selectedStartMarker.first.markerName
                  ?.substring(0, 4) ??
                  '-'
                  : 'your location'.tr,
              size: fontSizeL,
            ),
            const SizedBox(width: 4.0),
            Visibility(
              visible: _navigationController.selectedStartMarker.isEmpty,
              child: SvgPicture.asset(
                'assets/icons/navigation_45_icon.svg',
                height: 16.0,
              ),
            ),
          ],
        ),
      ),
      iconPath: 'assets/icons/scan_icon.svg',
      onTap: () async {
        await ttsManager.speak('choose your location'.tr);

        List? result = await Get.to(
              () => CustomItemPicker(
            title: 'location'.tr,
            hintText: 'search locations'.tr,
            items: _navigationController.frontDoorMarkersList,
            selectedItems: _navigationController.selectedStartMarker,
            onSearch: (searchText) {
              if (searchText != '') {
                return _navigationController.frontDoorMarkersList
                    .where(
                      (marker) => marker.markerName!
                      .toLowerCase()
                      .contains(searchText.toLowerCase()),
                )
                    .toList();
              } else {
                return _navigationController.frontDoorMarkersList;
              }
            },
            itemWidget: (item, isSelected) {
              ArMarkersModel castedItem = item;

              return CustomItemPickerCell(
                title: castedItem.markerName?.substring(0, 4) ?? '-',
                isSelected: isSelected,
              );
            },
            pickMultipleItem: false,
          ),
        );

        if (result != null) {
          await ttsManager.speak(_navigationController
              .selectedStartMarker.first.markerName!
              .substring(0, 4));

          setState(() {});
        }
      },
      onIconTap: () async {
        await ttsManager.speak('marker scan'.tr);

        // List? result = await Get.to(() => const ScanMarkerPage()); //TODO
        //
        // if (result != null) {
        //   await Future.delayed(const Duration(milliseconds: 500));
        //   await ttsManager.speak(_navigationController
        //       .selectedStartMarker.first.markerName!
        //       .substring(0, 4));
        //
        //   setState(() {});
        // }

        List? result = await Get.to(() => const ARScanPage());

        if (result != null) {
            await Future.delayed(const Duration(milliseconds: 500));
            await ttsManager.speak(_navigationController
                .selectedStartMarker.first.markerName!
                .substring(0, 4));

            setState(() {});
        }
      },
    );
  }

  _destination() {
    return _selectedButton(
      child: Semantics(
        button: true,
        label: _navigationController.selectedDestinationMarker.isNotEmpty
            ? '${'destination'.tr} ${_navigationController.selectedDestinationMarker.first.markerName?.substring(0, 4)}'
            : 'choose destination'.tr,
        child: TextFontStyle(
          _navigationController.selectedDestinationMarker.isNotEmpty
              ? _navigationController.selectedDestinationMarker.first.markerName
              ?.substring(0, 4) ??
              '-'
              : 'choose destination'.tr,
          size: fontSizeL,
        ),
      ),
      iconPath: 'assets/icons/swap_icon.svg',
      onTap: () async {
        await ttsManager.speak('choose destination'.tr);

        List? result = await Get.to(
              () => CustomItemPicker(
            title: 'location'.tr,
            hintText: 'search locations'.tr,
            items: _navigationController.frontDoorMarkersList,
            selectedItems: _navigationController.selectedDestinationMarker,
            onSearch: (searchText) {
              if (searchText != '') {
                return _navigationController.frontDoorMarkersList
                    .where(
                      (marker) => marker.markerName!
                      .toLowerCase()
                      .contains(searchText.toLowerCase()),
                )
                    .toList();
              } else {
                return _navigationController.frontDoorMarkersList;
              }
            },
            itemWidget: (item, isSelected) {
              ArMarkersModel castedItem = item;

              return CustomItemPickerCell(
                title: castedItem.markerName?.substring(0, 4) ?? '-',
                isSelected: isSelected,
              );
            },
            pickMultipleItem: false,
          ),
        );

        if (result != null) {
          await ttsManager.speak(_navigationController
              .selectedDestinationMarker.first.markerName!
              .substring(0, 4));

          setState(() {});
        }
      },
      onIconTap: _swapLocation,
    );
  }

  _swapLocation() async {
    await ttsManager.speak('swap location'.tr);

    ArMarkersModel? start;
    ArMarkersModel? destination;

    if (_navigationController.selectedStartMarker.isNotEmpty &&
        _navigationController.selectedDestinationMarker.isNotEmpty) {
      start = _navigationController.selectedStartMarker.first;
      destination = _navigationController.selectedDestinationMarker.first;

      _navigationController.selectedStartMarker.clear();
      _navigationController.selectedStartMarker.add(destination);
      _navigationController.selectedDestinationMarker.clear();
      _navigationController.selectedDestinationMarker.add(start);
    } else if (_navigationController.selectedStartMarker.isNotEmpty &&
        _navigationController.selectedDestinationMarker.isEmpty) {
      start = _navigationController.selectedStartMarker.first;

      _navigationController.selectedStartMarker.clear();
      _navigationController.selectedDestinationMarker.add(start);
    } else if (_navigationController.selectedDestinationMarker.isNotEmpty &&
        _navigationController.selectedStartMarker.isEmpty) {
      destination = _navigationController.selectedDestinationMarker.first;

      _navigationController.selectedDestinationMarker.clear();
      _navigationController.selectedStartMarker.add(destination);
    }

    setState(() {});
  }

  _selectedButton({
    required Widget child,
    required String iconPath,
    required Function() onTap,
    required Function() onIconTap,
  }) {
    return SizedBox(
      height: 50.0,
      child: Row(
        children: [
          Expanded(
            child: InkWell(onTap: onTap, child: child),
          ),
          const SizedBox(width: marginX2),
          Semantics(
            button: true,
            label: iconPath.contains('scan_icon')
                ? 'scan marker'.tr
                : 'swap location'.tr,
            child: InkWell(
              onTap: onIconTap,
              child: SvgPicture.asset(iconPath),
            ),
          ),
        ],
      ),
    );
  }

  _map() {
    return Expanded(
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: marginX2),
            child: Image.asset('assets/images/C3_floorplan.png'),
          ),
        ],
      ),
    );
  }

  _navigationButton() {
    return Visibility(
      visible: _navigationController.selectedStartMarker.isNotEmpty &&
          _navigationController.selectedDestinationMarker.isNotEmpty,
      child: CustomSubmitButton(
        onTap: () async {
          if (_navigationController.selectedStartMarker.isNotEmpty &&
              _navigationController.selectedDestinationMarker.isNotEmpty) {
            String startMarker =
                _navigationController.selectedStartMarker.first.markerName ??
                    '-';
            String destinationMarker = _navigationController
                .selectedDestinationMarker.first.markerName ??
                '-';

            if (kDebugMode) {
              print(startMarker);
              print(destinationMarker);
            }

            await _navigationController.detectAndNavigate(
              startMarker: startMarker,
              destination: destinationMarker,
            );

            Get.to(() => const ARNavigatePage());
          }
        },
        title: 'start navigation'.tr,
        buttonHeight: 60.0,
        borderRadius: 30.0,
        fontSize: fontSizeXL,
      ),
    );
  }

  _loading() {
    return Obx(() {
      return Visibility(
        visible: _navigationController.isLoading.value,
        child: const CustomLoading(),
      );
    });
  }
}

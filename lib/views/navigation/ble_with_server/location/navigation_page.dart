import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/views/navigation/ble_with_server/controller/ble_socket_service.dart';
import 'package:seeable/views/navigation/ble_with_server/controller/navigation_controller.dart';
import 'package:seeable/views/navigation/ble_with_server/model/ble_model.dart';
import 'package:seeable/views/navigation/ble_with_server/model/place_model.dart';
import 'package:seeable/widgets/custom_loading.dart';
import 'package:seeable/widgets/main_template.dart';
import 'package:seeable/widgets/text_font_style.dart';

class NavigationPage extends StatefulWidget {
  final PlaceModel place;

  const NavigationPage({
    super.key,
    required this.place,
  });

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  final NavigationController _navigationController = Get.find();

  bool isFavorite = false;
  bool isNavigate = false;

  @override
  void initState() {
    super.initState();

    _prepareData();
  }

  _prepareData() async {
    isFavorite = widget.place.isFavorite ?? false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MainTemplate(
          appBarTitle: widget.place.name ?? '-',
          showBackButton: true,
          actions: [
            InkWell(
              onTap: () async {
                isFavorite = !isFavorite;

                await _navigationController.setFavorite(
                  placeId: widget.place.id ?? 0,
                  isFavorite: isFavorite,
                );

                setState(() {});
              },
              child: SizedBox(
                child: Padding(
                  padding: const EdgeInsets.only(right: marginX2),
                  child: SvgPicture.asset(
                    isFavorite
                        ? 'assets/icons/favorite_filled_icon.svg'
                        : 'assets/icons/favorite_icon.svg',
                    color: primaryColor,
                    height: 30.0,
                  ),
                ),
              ),
            ),
          ],
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(marginX2),
              child: SizedBox.expand(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _mapPicture(),
                    _navigationButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
        _loading(),
      ],
    );
  }

  // TODO:
  _mapPicture() {
    return Expanded(
      child: ListView.builder(
        itemCount: _navigationController.bleDataList.length,
        itemBuilder: (context, index) {
          BLEListModel item = _navigationController.bleDataList[index];

          return TextFontStyle('${item.name}: ${item.rssiList}');
        },
      ),
    );
    // return Expanded(
    //   child: SingleChildScrollView(
    //     child: Column(
    //       children: [
    //         // InkWell(
    //         //   onTap: () {},
    //         //   child: Container(
    //         //     height: 100,
    //         //     width: 100,
    //         //     color: primaryColor,
    //         //   ),
    //         // ),
    //         TextFontStyle('${_navigationController.bleDataList}'),
    //       ],
    //     ),
    //   ),
    // );
  }

  _navigationButton() {
    return Visibility(
      visible: true,
      // visible: !isNavigate,
      child: Column(
        children: [
          const SizedBox(height: marginX2),
          InkWell(
            onTap: !isNavigate
                ? () async {
                    isNavigate = true;
                    await _navigationController
                        .startNavigation(widget.place.bleNames ?? []);

                    setState(() {});
                  }
                : () async {
                    isNavigate = false;
                    await _navigationController.stopNavigation();

                    setState(() {});
                  }, //TODO:
            child: Container(
              height: 80.0,
              margin: const EdgeInsets.all(marginX2),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(40.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RotationTransition(
                    turns: const AlwaysStoppedAnimation(45 / 360),
                    child: SvgPicture.asset(
                      'assets/icons/navigate_arrow_icon.svg',
                    ),
                  ),
                  const SizedBox(width: margin),
                  TextFontStyle(
                    'start navigation'.tr,
                    size: fontListViewButton,
                    weight: FontWeight.bold,
                  ),
                ],
              ),
            ),
          ),
        ],
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

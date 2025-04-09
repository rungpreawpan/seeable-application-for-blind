import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/widgets/text_font_style.dart';

class NavigationMainTemplate extends StatelessWidget {
  final String appBarTitle;
  final Function()? onBack;
  final List<Widget>? actions;
  final List items;
  final Widget? Function(BuildContext, int) itemWidget;

  const NavigationMainTemplate({
    super.key,
    this.appBarTitle = '',
    this.onBack,
    this.actions,
    required this.itemWidget,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: appBarTitle != ''
            ? TextFontStyle(
                appBarTitle,
                size: fontAppbar,
                color: primaryColor,
                weight: FontWeight.bold,
                align: TextAlign.center,
              )
            : SvgPicture.asset(
                'assets/logo/seeable_logo.svg',
                height: 90.0,
              ),
        leading: Visibility(
          visible: appBarTitle != '',
          child: InkWell(
            onTap: () {
              if (onBack != null) {
                onBack!();
              }

              Get.back();
            },
            child: const Padding(
              padding: EdgeInsets.only(left: marginX2),
              child: CircleAvatar(
                backgroundColor: primaryColor,
                radius: 20,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 19,
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: primaryColor,
                    size: 30.0,
                  ),
                ),
              ),
            ),
          ),
        ),
        actions: actions,
        centerTitle: true,
        backgroundColor: Colors.white,
        toolbarHeight: 90.0,
        elevation: 0.0,
      ),
      body: items.isNotEmpty
          ? ListView.separated(
              padding: const EdgeInsets.all(marginX2),
              physics: const BouncingScrollPhysics(),
              itemCount: items.length,
              itemBuilder: itemWidget,
              separatorBuilder: (context, index) {
                return const SizedBox(height: marginX2);
              },
            )
          : Center(
              child: TextFontStyle(
                'data not found'.tr,
                size: fontSizeM,
              ),
            ),
    );
  }
}

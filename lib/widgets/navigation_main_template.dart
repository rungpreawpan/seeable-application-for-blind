import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/views/settings/controller/settings_controller.dart';
import 'package:seeable/widgets/custom_back_button.dart';
import 'package:seeable/widgets/text_font_style.dart';

class NavigationMainTemplate extends StatefulWidget {
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
  State<NavigationMainTemplate> createState() => _NavigationMainTemplateState();
}

class _NavigationMainTemplateState extends State<NavigationMainTemplate> {
  final SettingsController _settingsController = Get.find();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: widget.appBarTitle != ''
            ? TextFontStyle(
                widget.appBarTitle,
                style: theme.textTheme.titleLarge,
                align: TextAlign.center,
              )
            : SvgPicture.asset(
                _settingsController.themeMode.value == ThemeMode.light
                    ? 'assets/logo/seeable_logo.svg'
                    : 'assets/logo/seeable_logo_dark_theme.svg',
                height: 90.0,
              ),
        leading: Visibility(
          visible: widget.appBarTitle != '',
          child: CustomBackButton(
            onTap: () {
              if (widget.onBack != null) {
                widget.onBack!();
              }

              Get.back();
            },
          ),
        ),
        actions: widget.actions,
        centerTitle: true,
        toolbarHeight: 90.0,
        elevation: 0.0,
      ),
      body: widget.items.isNotEmpty
          ? ListView.separated(
              padding: const EdgeInsets.all(marginX2),
              physics: const BouncingScrollPhysics(),
              itemCount: widget.items.length,
              itemBuilder: widget.itemWidget,
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

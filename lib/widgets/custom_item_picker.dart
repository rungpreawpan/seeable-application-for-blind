import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/widgets/custom_submit_button.dart';
import 'package:seeable/widgets/custom_textfield.dart';
import 'package:seeable/widgets/main_template.dart';
import 'package:seeable/widgets/text_font_style.dart';

class CustomItemPicker extends StatefulWidget {
  final bool isIngredientPage;
  final bool isProductTypePage;
  final String title;
  final String? hintText;
  final double? hintSize;
  final List items;
  final Widget Function(dynamic item, bool isSelected) itemWidget;
  final bool showSearchBar;
  final dynamic Function(String searchText) onSearch;
  final int maximumItem;
  final bool pickMultipleItem;
  final List selectedItems;
  final bool enabledSelect;
  final bool showConfirmButton;

  const CustomItemPicker({
    super.key,
    this.isIngredientPage = false,
    this.isProductTypePage = false,
    required this.title,
    this.hintText,
    this.hintSize,
    required this.items,
    required this.itemWidget,
    this.showSearchBar = true,
    required this.onSearch,
    this.maximumItem = 99,
    this.pickMultipleItem = true,
    required this.selectedItems,
    this.enabledSelect = true,
    this.showConfirmButton = true,
  });

  @override
  State<CustomItemPicker> createState() => _CustomItemPickerState();
}

class _CustomItemPickerState extends State<CustomItemPicker> {
  final TextEditingController _searchController = TextEditingController();
  List _filteredItems = [];

  late StreamSubscription<bool> _keyboardSubscription;
  bool _keyboardIsVisible = false;
  late int _maximumItem;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;

    if (widget.pickMultipleItem) {
      _maximumItem = widget.maximumItem;
    } else {
      _maximumItem = 1;
    }

    _keyboardSubscription = KeyboardVisibilityController().onChange.listen(
      (bool visible) {
        _keyboardIsVisible = visible;
        setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _keyboardSubscription.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainTemplate(
      appBarTitle: widget.title,
      showBackButton: true,
      body: SafeArea(
        child: Column(
          children: [
            _searchBar(),
            const SizedBox(height: margin),
            Expanded(
              child: _dataList(),
            ),
            const SizedBox(height: margin),
            _confirmButton(),
          ],
        ),
      ),
    );
  }

  _searchBar() {
    return widget.showSearchBar
        ? Padding(
            padding: const EdgeInsets.all(marginX2),
            child: CustomTextField(
              textEditingController: _searchController,
              hintText: widget.hintText,
              padding: const EdgeInsets.all(marginX2),
              onChanged: (value) {
                _filteredItems = widget.onSearch(value);
                setState(() {});
              },
            ),
          )
        : const SizedBox();
  }

  _dataList() {
    return _filteredItems.isNotEmpty
        ? ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: marginX2),
            itemCount: _filteredItems.length,
            itemBuilder: (context, index) {
              var item = _filteredItems[index];
              bool isSelected;
              if (widget.isIngredientPage) {
                isSelected = widget.selectedItems
                    .map((e) => e.ingredientName)
                    .contains(item.ingredientName);
              } else if (widget.isProductTypePage) {
                isSelected =
                    widget.selectedItems.map((e) => e.name).contains(item.name);
              } else {
                isSelected = widget.selectedItems.contains(item);
              }

              return InkWell(
                onTap: widget.enabledSelect
                    ? () {
                        if (isSelected) {
                          widget.selectedItems.remove(item);
                        } else {
                          if (widget.pickMultipleItem) {
                            if (widget.selectedItems.length < _maximumItem) {
                              widget.selectedItems.insert(0, item);
                            }
                          } else {
                            widget.selectedItems.clear();
                            widget.selectedItems.add(item);
                          }
                        }

                        setState(() {});
                      }
                    : null,
                child: widget.itemWidget(
                  item,
                  isSelected,
                ),
              );
            },
            separatorBuilder: (context, index) {
              return const SizedBox(height: marginX2);
            },
          )
        : const Padding(
            padding: EdgeInsets.all(20.0),
            child: TextFontStyle(
              'ไม่พบข้อมูล',
              size: fontSizeL,
            ),
          );
  }

  _confirmButton() {
    bool enabled = widget.selectedItems.isNotEmpty;

    return Visibility(
      visible: widget.showConfirmButton && !_keyboardIsVisible,
      child: SafeArea(
        child: enabled
            ? CustomSubmitButton(
                onTap: () {
                  Get.back(result: widget.selectedItems);
                },
                title: 'ยืนยัน',
                fontSize: fontSizeL,
                borderRadius: 10,
                buttonColor: primaryColor,
                buttonMargin: const EdgeInsets.all(marginX2),
              )
            : CustomSubmitButton(
                onTap: () {},
                title: 'ยืนยัน',
                fontSize: fontSizeL,
                borderRadius: 10,
                buttonColor: Colors.transparent,
                fontColor: Colors.grey.shade400,
                showBorder: true,
                borderColor: Colors.grey.shade400,
                buttonMargin: const EdgeInsets.all(marginX2),
              ),
      ),
    );
  }
}

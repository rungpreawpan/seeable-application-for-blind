import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomGalleryButton extends StatelessWidget {
  final Function() onTap;
  final Uint8List? thumbnailImage;

  const CustomGalleryButton({
    super.key,
    required this.onTap,
    required this.thumbnailImage,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 50.0,
        width: 50.0,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: thumbnailImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Image.memory(
                  thumbnailImage!,
                  fit: BoxFit.cover,
                ),
              )
            : const Icon(
                Icons.image_outlined,
                color: Colors.black,
              ),
      ),
    );
  }
}

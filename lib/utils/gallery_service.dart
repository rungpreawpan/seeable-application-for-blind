import 'package:photo_manager/photo_manager.dart';
import 'dart:typed_data';

class GalleryService {
  Future<Uint8List?> loadLatestImage() async {
    final permission = await PhotoManager.requestPermissionExtend();

    if (permission.isAuth || permission == PermissionState.limited) {
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: true,
      );

      if (albums.isNotEmpty) {
        final recentAssets =
        await albums.first.getAssetListPaged(page: 0, size: 1);

        if (recentAssets.isNotEmpty) {
          return await recentAssets.first
              .thumbnailDataWithSize(const ThumbnailSize(200, 200));
        }
      }

      if (permission == PermissionState.limited) {
        await PhotoManager.presentLimited();
      }
    }
    return null;
  }
}
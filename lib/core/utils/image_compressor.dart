import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

Future<File?> compressImage(File file) async {

  final dir = await getTemporaryDirectory();

  final target =
      "${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg";

  final result =
      await FlutterImageCompress.compressAndGetFile(
    file.path,
    target,
    quality: 70,
    minWidth: 1080,
    minHeight: 1080,
  );

  if (result == null) return null;

  return File(result.path);
}
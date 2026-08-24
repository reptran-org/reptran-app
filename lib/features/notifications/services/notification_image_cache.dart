import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class NotificationImageCache {
  static final Map<String, String> _memory = {};

  static Future<String?> getImagePath(String url) async {
    try {
      if (_memory.containsKey(url)) {
        return _memory[url];
      }

      final dir = await getTemporaryDirectory();
      final fileName = url.hashCode.toString();
      final file = File("${dir.path}/$fileName.png");

      if (await file.exists()) {
        _memory[url] = file.path;
        return file.path;
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) return null;

      final circularBytes = await _createCircularImage(response.bodyBytes);

      if (circularBytes == null) return null;

      await file.writeAsBytes(circularBytes);

      _memory[url] = file.path;

      return file.path;
    } catch (e) {
    }

    return null;
  }

  static Future<Uint8List?> _createCircularImage(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final size = image.width < image.height ? image.width : image.height;

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      final paint = ui.Paint();

      final rect = ui.Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble());

      final path = ui.Path()..addOval(rect);

      canvas.clipPath(path);

      canvas.drawImageRect(
        image,
        ui.Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
        rect,
        paint,
      );

      final picture = recorder.endRecording();
      final img = await picture.toImage(size, size);

      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
    }

    return null;
  }



}
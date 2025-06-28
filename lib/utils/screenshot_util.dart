import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;

class ScreenshotUtil {
  static Future<Uint8List?> captureWidgetAsImage(GlobalKey key) async {
    try {
      RenderRepaintBoundary boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Error capturing screenshot: $e');
      return null;
    }
  }

  static Future<String?> saveScreenshot(Uint8List bytes) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${directory.path}/screenshot_$timestamp.png';
      final file = File(path);
      await file.writeAsBytes(bytes);
      return path;
    } catch (e) {
      print('Error saving screenshot: $e');
      return null;
    }
  }

  static Future<String?> captureAndSaveScreenshot(GlobalKey key) async {
    final bytes = await captureWidgetAsImage(key);
    if (bytes != null) {
      return await saveScreenshot(bytes);
    }
    return null;
  }
}

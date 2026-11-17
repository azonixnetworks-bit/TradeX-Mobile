import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/app_platform.dart';

class AppPlatformImpl implements AppPlatform {
  AppPlatformImpl() {
    timezone_data.initializeTimeZones();
  }

  @override
  Future<SelectedImage?> pickImage({
    required bool camera,
    int imageQuality = 88,
    double? maxWidth,
    double? maxHeight,
  }) async {
    final file = await ImagePicker().pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: imageQuality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
    return file == null
        ? null
        : SelectedImage(
            path: file.path,
            name: file.name,
            bytes: await file.readAsBytes(),
          );
  }

  @override
  Future<bool> launchExternal(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Future<String> timezoneId() async =>
      (await FlutterTimezone.getLocalTimezone()).identifier;

  @override
  DateTime timeInZone(String timezoneName, DateTime fallback) {
    try {
      return timezone.TZDateTime.now(timezone.getLocation(timezoneName));
    } catch (_) {
      return fallback.toUtc();
    }
  }

  @override
  Future<void> shareImage({
    required Uint8List bytes,
    required String fileName,
    required String text,
    double? originLeft,
    double? originTop,
    double? originWidth,
    double? originHeight,
  }) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);
    final hasOrigin =
        originLeft != null &&
        originTop != null &&
        originWidth != null &&
        originHeight != null;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png', name: fileName)],
        text: text,
        sharePositionOrigin: hasOrigin
            ? Rect.fromLTWH(originLeft, originTop, originWidth, originHeight)
            : null,
      ),
    );
  }

  @override
  Future<void> shareFile({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String text,
  }) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: mimeType, name: fileName)],
        text: text,
      ),
    );
  }
}

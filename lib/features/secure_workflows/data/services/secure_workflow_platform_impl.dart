import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../domain/services/secure_workflow_platform.dart';

class SecureWorkflowPlatformImpl implements SecureWorkflowPlatform {
  const SecureWorkflowPlatformImpl();

  @override
  Future<PickedImage?> pickImage({
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
    return file == null ? null : PickedImage(path: file.path, name: file.name);
  }

  @override
  Future<bool> launchExternal(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Future<String> timezoneId() async =>
      (await FlutterTimezone.getLocalTimezone()).identifier;

  @override
  String newUuid() => const Uuid().v4();
}

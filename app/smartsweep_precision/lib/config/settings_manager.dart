import 'dart:io';

import 'package:path_provider/path_provider.dart';

class SettingsManager {
  static Future<File> get settingsFile async {
    final Directory directory = await getApplicationSupportDirectory();
    final String path = "${directory.path}/settings.json";
    final File file = File(path);
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    return file;
  }
}

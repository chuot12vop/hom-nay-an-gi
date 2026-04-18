import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/saved_filters.dart';

class FilterStorageService {
  Future<void> save(SavedFilters filters) async {
    final File file = await _file();
    await file.writeAsString(filters.toPrettyString());
  }

  Future<SavedFilters?> read() async {
    final File file = await _file();
    if (!await file.exists()) {
      return null;
    }

    final String content = await file.readAsString();
    final Map<String, dynamic> json = jsonDecode(content) as Map<String, dynamic>;
    return SavedFilters.fromJson(json);
  }

  Future<String> filePath() async {
    final File file = await _file();
    return file.path;
  }

  Future<File> _file() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/food_filters.json');
  }
}

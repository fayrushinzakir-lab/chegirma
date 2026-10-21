import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Простое сохранение состояния в JSON-файл (без БД-плагинов).
class Persist {
  static File? _file;
  static Map<String, dynamic> _data = {};

  static Future<void> init() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      _file = File('${dir.path}/chegirmalar_state.json');
      if (await _file!.exists()) {
        _data = json.decode(await _file!.readAsString()) as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Persist.init error: $e');
    }
  }

  static T? get<T>(String key) => _data[key] as T?;

  static List<String> getList(String key) =>
      (_data[key] as List?)?.map((e) => '$e').toList() ?? <String>[];

  static Future<void> set(String key, dynamic value) async {
    _data[key] = value;
    await _flush();
  }

  static Future<void> _flush() async {
    try {
      await _file?.writeAsString(json.encode(_data));
    } catch (e) {
      if (kDebugMode) debugPrint('Persist.flush error: $e');
    }
  }
}

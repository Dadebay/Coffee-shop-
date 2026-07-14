import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';

/// Loads UI strings from `assets/translations/{locale}.json`.
///
/// Call [AppTranslations.load] once, before `runApp`, so [keys] is
/// populated by the time GetX builds the widget tree.
class AppTranslations extends Translations {
  static const supportedLocales = ['tr', 'ru', 'tk'];

  static Map<String, Map<String, String>> _loadedKeys = {};

  static Future<void> load() async {
    final entries = await Future.wait(
      supportedLocales.map((code) async => MapEntry(code, await _loadLocale(code))),
    );
    _loadedKeys = Map.fromEntries(entries);
  }

  static Future<Map<String, String>> _loadLocale(String code) async {
    final raw = await rootBundle.loadString('assets/translations/$code.json');
    final decoded = json.decode(raw) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, value.toString()));
  }

  @override
  Map<String, Map<String, String>> get keys => _loadedKeys;
}

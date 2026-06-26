import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends GetxController {
  static LocaleController get to => Get.find();

  static const _key = 'locale_code';

  final Rx<Locale> locale = const Locale('ru').obs;

  String get currentCode => locale.value.languageCode;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key) ?? 'ru';
    final l = Locale(code);
    locale.value = l;
    Get.updateLocale(l);
  }

  Future<void> setLocale(Locale l) async {
    locale.value = l;
    Get.updateLocale(l);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, l.languageCode);
  }
}

import 'package:shared_preferences/shared_preferences.dart';

class Storage {
  static const _kToken = 'token';
  static const _kRole = 'role';
  static const _kName = 'name';
  static const _kBaseUrl = 'base_url';
  static const _kDarkMode = 'dark_mode';

  static Future<String?> getToken() async =>
      (await SharedPreferences.getInstance()).getString(_kToken);
  static Future<void> saveToken(String t) async =>
      (await SharedPreferences.getInstance()).setString(_kToken, t);
  static Future<void> clearToken() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kToken);
    await p.remove(_kRole);
    await p.remove(_kName);
  }

  static Future<String?> getRole() async =>
      (await SharedPreferences.getInstance()).getString(_kRole);
  static Future<void> saveRole(String r) async =>
      (await SharedPreferences.getInstance()).setString(_kRole, r);
  static Future<String?> getName() async =>
      (await SharedPreferences.getInstance()).getString(_kName);
  static Future<void> saveName(String n) async =>
      (await SharedPreferences.getInstance()).setString(_kName, n);

  static Future<String?> getBaseUrl() async =>
      (await SharedPreferences.getInstance()).getString(_kBaseUrl);
  static Future<void> saveBaseUrl(String url) async =>
      (await SharedPreferences.getInstance()).setString(_kBaseUrl, url);

  static Future<bool> isDarkMode() async =>
      (await SharedPreferences.getInstance()).getBool(_kDarkMode) ?? false;
  static Future<void> setDarkMode(bool v) async =>
      (await SharedPreferences.getInstance()).setBool(_kDarkMode, v);
}

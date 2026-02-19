import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/admin.dart';

class AuthHelper {
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  static Future<Admin?> getAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    final adminJson = prefs.getString('admin');
    if (adminJson == null) return null;
    return Admin.fromJson(json.decode(adminJson));
  }

  static Future<void> saveAdmin(Admin admin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('admin', json.encode(admin.toJson()));
    await prefs.setBool('has_admin', true);
  }

  static Future<void> login(String fullName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('current_user', fullName);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    await prefs.remove('current_user');
  }

  static Future<bool> hasAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('has_admin') ?? false;
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  static Future<String> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_user') ?? 'Teacher';
  }
}

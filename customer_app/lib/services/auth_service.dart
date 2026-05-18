import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  static const _userKey = 'user_data';

  static Future<UserModel?> login(String email, String password) async {
    final res = await ApiService.post('auth/login.php', {
      'email': email,
      'password': password,
      'role': 'customer',
    });
    if (res['success'] == true) {
      final user = UserModel.fromJson(res['user'], token: res['token']);
      await _saveUser(user);
      ApiService.setToken(user.token);
      return user;
    }
    throw Exception(res['error'] ?? 'Login failed');
  }

  static Future<UserModel?> register(String name, String email, String phone, String password, String address) async {
    final res = await ApiService.post('auth/register.php', {
      'name': name, 'email': email, 'phone': phone,
      'password': password, 'address': address, 'role': 'customer',
    });
    if (res['success'] == true) {
      final user = UserModel.fromJson(res['user'], token: res['token']);
      await _saveUser(user);
      ApiService.setToken(user.token);
      return user;
    }
    throw Exception(res['error'] ?? 'Registration failed');
  }

  static Future<void> _saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  static Future<UserModel?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_userKey);
    if (data != null) {
      final json = jsonDecode(data) as Map<String, dynamic>;
      final token = (json['token'] as String?) ?? '';
      final user = UserModel.fromJson(json, token: token);
      if (token.isNotEmpty) ApiService.setToken(token);
      return user;
    }
    return null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    ApiService.clearToken();
  }
}

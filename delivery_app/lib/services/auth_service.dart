import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class DeliveryUser {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String token;

  DeliveryUser({required this.id, required this.name, required this.email, required this.phone, required this.token});

  factory DeliveryUser.fromJson(Map<String, dynamic> json, {String token = ''}) =>
    DeliveryUser(id: json['id'] ?? 0, name: json['name'] ?? '', email: json['email'] ?? '', phone: json['phone'] ?? '', token: token);

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email, 'phone': phone, 'token': token};
}

class AuthService {
  static const _key = 'delivery_user';

  static Future<DeliveryUser?> login(String email, String password) async {
    final res = await ApiService.post('auth/login.php', {
      'email': email, 'password': password, 'role': 'delivery_boy',
    });
    if (res['success'] == true) {
      final user = DeliveryUser.fromJson(res['user'], token: res['token']);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(user.toJson()));
      ApiService.setToken(user.token);
      return user;
    }
    throw Exception(res['error'] ?? 'Login failed');
  }

  static Future<DeliveryUser?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data != null) {
      final user = DeliveryUser.fromJson(jsonDecode(data));
      ApiService.setToken(user.token);
      return user;
    }
    return null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    ApiService.clearToken();
  }
}

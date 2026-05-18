class UserModel {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String address;
  final String token;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    required this.role,
    this.address = '',
    required this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {String token = ''}) {
    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'customer',
      address: json['address'] ?? '',
      token: json['token'] ?? token,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'email': email,
    'phone': phone, 'role': role, 'address': address, 'token': token,
  };
}

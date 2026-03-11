class UserModel {
  final String id;
  final String name;
  final String email;
  final String password;
  final String role; // admin, master_baker, helper

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'],
        name: map['name'],
        email: map['email'],
        password: map['password'],
        role: map['role'],
      );

  UserModel copyWith({
    String? name,
    String? email,
    String? password,
    String? role,
  }) =>
      UserModel(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        password: password ?? this.password,
        role: role ?? this.role,
      );

  String get roleDisplay {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'master_baker':
        return 'Master Baker';
      case 'helper':
        return 'Helper';
      default:
        return role;
    }
  }

  bool get isAdmin => role == 'admin';
  bool get isMasterBaker => role == 'master_baker';
  bool get isHelper => role == 'helper';
}

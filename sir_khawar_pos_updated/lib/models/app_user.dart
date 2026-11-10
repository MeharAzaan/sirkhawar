
class AppUser {
  final String id;
  final String name;
  final String role; // 'admin' or 'employee'
  final String password;
  final List<String> allowedScreens;

  AppUser({
    required this.id,
    required this.name,
    required this.role,
    this.password = 'admin123',
    required this.allowedScreens,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';

  bool hasAccess(String screenKey) {
    if (isAdmin) return true;
    return allowedScreens.contains(screenKey);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'password': password,
      'allowedScreens': allowedScreens,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map, String docId) {
    final rawList = map['allowedScreens'] as List<dynamic>? ?? [];
    return AppUser(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      name: map['name'] ?? '',
      role: map['role'] ?? 'employee',
      password: map['password'] ?? 'admin123',
      allowedScreens: rawList.map((e) => e.toString()).toList(),
    );
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? role,
    String? password,
    List<String>? allowedScreens,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      password: password ?? this.password,
      allowedScreens: allowedScreens ?? this.allowedScreens,
    );
  }
}
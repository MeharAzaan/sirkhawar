class AppUser {
  final String id;
  final String name;
  final String role; // 'admin' or 'employee'
  final List<String> allowedScreens;

  AppUser({
    required this.id,
    required this.name,
    this.role = 'employee',
    this.allowedScreens = const [],
  });

  bool get isAdmin => role == 'admin';
}
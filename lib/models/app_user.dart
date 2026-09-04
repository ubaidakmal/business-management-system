/// Example model for Phase 1. Future models should follow the same pattern.
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    this.fullName,
    this.role,
  });

  final String id;
  final String email;
  final String? fullName;
  final String? role;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      role: json['role'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'email': email, 'full_name': fullName, 'role': role};
  }
}

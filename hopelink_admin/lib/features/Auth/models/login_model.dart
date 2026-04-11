class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

// ── Response ─────────────────────────────────────────────────
class LoginResponse {
  final bool success;
  final String token;
  final LoginUser user;

  const LoginResponse({
    required this.success,
    required this.token,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] as bool,
      token: json['token'] as String,
      user: LoginUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class LoginUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool isVerified;
  final bool isActive;
  final LoginOrganization organization;

  const LoginUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isVerified,
    required this.isActive,
    required this.organization,
  });

  factory LoginUser.fromJson(Map<String, dynamic> json) {
    final organizationJson = json['organization'] as Map<String, dynamic>?;
    return LoginUser(
      id: json['_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      isVerified: json['isVerified'] as bool,
      isActive: json['isActive'] as bool,
      organization: LoginOrganization.fromJson(organizationJson),
    );
  }
}

class LoginOrganization {
  final String id;
  final String name;
  final String type;
  final String status;

  const LoginOrganization({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
  });

  factory LoginOrganization.fromJson(Map<String, dynamic>? json) {
    return LoginOrganization(
      id: json?['_id'] as String? ?? '',
      name: json?['name'] as String? ?? '',
      type: json?['type'] as String? ?? '',
      status: json?['status'] as String? ?? '',
    );
  }
}

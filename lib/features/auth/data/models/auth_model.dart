class AuthResponseModel {
  final String access;
  final String refresh;
  final UserModel user;

  AuthResponseModel({
    required this.access,
    required this.refresh,
    required this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      access: json['access'] ?? '',
      refresh: json['refresh'] ?? '',
      user: UserModel.fromJson(
        json['user'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class UserModel {
  final int id;
  final String email;
  final String gmailAccount;
  final String username;
  final String firstName;
  final String lastName;
  final String phone;
  final String fullName;
  final String role;
  final int roleLevel;
  final bool isActive;
  final bool isEmailVerified;
  final String authProvider;
  final String microsoftId;
  final String googleId;

  final String identifier;

  UserModel({
    required this.id,
    required this.email,
    this.gmailAccount = '',
    required this.username,
    required this.firstName,
    required this.lastName,
    this.phone = '',
    required this.fullName,
    required this.role,
    this.roleLevel = 0,
    required this.isActive,
    required this.isEmailVerified,
    this.authProvider = '',
    this.microsoftId = '',
    this.googleId = '',
    required this.identifier,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id'] ?? 0}') ?? 0,
      email: json['email']?.toString() ?? '',
      gmailAccount: json['gmail_account']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      fullName: json['full_name']?.toString().trim().isNotEmpty == true
          ? json['full_name'].toString()
          : '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim(),
      role: json['role']?.toString() ?? 'user',
      roleLevel: json['role_level'] is int
          ? json['role_level'] as int
          : int.tryParse('${json['role_level'] ?? 0}') ?? 0,
      isActive: json['is_active'] == true,
      isEmailVerified: json['is_email_verified'] == true,
      authProvider: json['auth_provider']?.toString() ?? '',
      microsoftId: json['microsoft_id']?.toString() ?? '',
      googleId: json['google_id']?.toString() ?? '',
      identifier:
          json['identifier']?.toString() ?? json['email']?.toString() ?? '',
    );
  }

  String get displayName =>
      fullName.isNotEmpty ? fullName : (username.isNotEmpty ? username : email);
}

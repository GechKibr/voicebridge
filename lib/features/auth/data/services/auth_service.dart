import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/config/backend_endpoints.dart';
import '../models/auth_model.dart';

class MicrosoftBackendAuthResult {
  final bool userExists;
  final AuthResponseModel? authResponse;
  final Map<String, dynamic> payload;

  const MicrosoftBackendAuthResult({
    required this.userExists,
    required this.authResponse,
    required this.payload,
  });
}

class AuthService {
  final _storage = const FlutterSecureStorage();

  void _assertSecureBackend() {
    final backend = Uri.parse(ApiConfig.backendUrl);
    final host = backend.host.toLowerCase();
    final isLocal = host == 'localhost' || host == '127.0.0.1';
    if (!isLocal && backend.scheme != 'https') {
      throw Exception('Insecure backend URL. Use HTTPS in production.');
    }
  }

  Future<AuthResponseModel> login(String email, String password) async {
    _assertSecureBackend();

    try {
      final response = await http.post(
        ApiConfig.uri(BackendEndpoints.accountsLogin),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'identifier': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final authResponse = AuthResponseModel.fromJson(data);

        await _persistTokens(authResponse.access, authResponse.refresh);

        return authResponse;
      } else if (response.statusCode == 400 || response.statusCode == 401) {
        throw Exception('Invalid email or password');
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network failure: $e');
    }
  }

  Future<AuthResponseModel> register({
    required String email,
    required String gmailAccount,
    required String username,
    required String firstName,
    required String lastName,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    _assertSecureBackend();

    final response = await http.post(
      ApiConfig.uri(BackendEndpoints.accountsRegister),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'gmail_account': gmailAccount,
        'username': username,
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'password': password,
        'confirm_password': confirmPassword,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final authResponse = AuthResponseModel.fromJson(data);
      if (authResponse.access.isNotEmpty && authResponse.refresh.isNotEmpty) {
        await _persistTokens(authResponse.access, authResponse.refresh);
      }
      return authResponse;
    }

    final payload = _decodeError(response.body);
    throw Exception(payload ?? 'Registration failed: ${response.statusCode}');
  }

  Future<MicrosoftBackendAuthResult> authenticateMicrosoftAccessToken(
    String accessToken,
  ) async {
    _assertSecureBackend();

    final response = await http.post(
      ApiConfig.uri(BackendEndpoints.authMicrosoftMobile),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'access_token': accessToken}),
    );

    final body = _decodeJsonMap(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final hasTokens =
          (body['access']?.toString().trim().isNotEmpty ?? false) &&
          (body['refresh']?.toString().trim().isNotEmpty ?? false);

      final requiresRegistration = _isMicrosoftRegistrationResponse(
        statusCode: response.statusCode,
        payload: body,
      );

      if (hasTokens && !requiresRegistration) {
        final authResponse = AuthResponseModel.fromJson(body);
        await _persistTokens(authResponse.access, authResponse.refresh);
        return MicrosoftBackendAuthResult(
          userExists: true,
          authResponse: authResponse,
          payload: body,
        );
      }

      return MicrosoftBackendAuthResult(
        userExists: false,
        authResponse: null,
        payload: body,
      );
    }

    if (_isMicrosoftRegistrationResponse(
      statusCode: response.statusCode,
      payload: body,
    )) {
      return MicrosoftBackendAuthResult(
        userExists: false,
        authResponse: null,
        payload: body,
      );
    }

    final payload = _decodeError(response.body);
    throw Exception(
      payload ?? 'Microsoft authentication failed: ${response.statusCode}',
    );
  }

  Map<String, dynamic> _decodeJsonMap(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // Non-JSON responses are handled by caller using generic fallback messages.
    }
    return const {};
  }

  bool _isMicrosoftRegistrationResponse({
    required int statusCode,
    required Map<String, dynamic> payload,
  }) {
    if (statusCode == 202 || statusCode == 404 || statusCode == 409) {
      return true;
    }

    final registrationKeys = [
      'requires_registration',
      'need_registration',
      'needs_registration',
      'register_required',
      'is_new_user',
      'new_user',
      'user_exists',
    ];

    for (final key in registrationKeys) {
      if (!payload.containsKey(key)) continue;

      final value = payload[key];
      if (value is bool) {
        if (key == 'user_exists') {
          if (!value) return true;
        } else if (value) {
          return true;
        }
      }

      final normalized = value?.toString().toLowerCase().trim() ?? '';
      if (normalized.isEmpty) continue;

      if (key == 'user_exists') {
        if (normalized == 'false' || normalized == '0' || normalized == 'no') {
          return true;
        }
      } else if (normalized == 'true' ||
          normalized == '1' ||
          normalized == 'yes') {
        return true;
      }
    }

    final message = [
      payload['detail'],
      payload['error'],
      payload['message'],
      payload['non_field_errors'],
    ].map((e) => e?.toString().toLowerCase() ?? '').join(' ');

    return message.contains('register') ||
        message.contains('registration') ||
        message.contains('user not found') ||
        message.contains('no account');
  }

  Future<void> logout() async {
    try {
      final token = await getAccessToken();
      final refresh = await getRefreshToken();
      if (token != null && token.isNotEmpty) {
        await http.post(
          ApiConfig.uri(BackendEndpoints.accountsLogout),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            if (refresh != null && refresh.isNotEmpty) 'refresh': refresh,
          }),
        );
      }
    } catch (_) {
      // Best effort only. Local session cleanup still runs below.
    }

    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  Future<void> _persistTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refresh_token');
  }

  Future<String?> getToken() async {
    return getAccessToken();
  }

  Future<Map<String, String>> buildAuthHeaders({
    bool includeContentType = true,
  }) async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token is missing. Please log in again.');
    }

    final headers = <String, String>{'Authorization': 'Bearer $token'};
    if (includeContentType) {
      headers['Content-Type'] = 'application/json';
    }
    return headers;
  }

  Future<UserModel> fetchCurrentUserProfile() async {
    _assertSecureBackend();

    final token = await getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token is missing. Please log in again.');
    }

    final response = await http.get(
      ApiConfig.uri(BackendEndpoints.accountsMe),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load current user: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return UserModel.fromJson(decoded);
    }

    throw Exception('Invalid user profile response');
  }

  Future<void> requestPasswordReset(String identifier) async {
    _assertSecureBackend();

    final response = await http.post(
      ApiConfig.uri(BackendEndpoints.accountsPasswordResetRequest),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'identifier': identifier}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final payload = _decodeError(response.body);
      throw Exception(payload ?? 'Failed to request password reset.');
    }
  }

  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    _assertSecureBackend();

    final response = await http.post(
      ApiConfig.uri(BackendEndpoints.accountsPasswordReset),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token, 'password': password}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final payload = _decodeError(response.body);
      throw Exception(payload ?? 'Failed to reset password.');
    }
  }

  String? _decodeError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final fieldErrors = <String>[];
        for (final entry in decoded.entries) {
          if (entry.key == 'detail' ||
              entry.key == 'error' ||
              entry.key == 'message') {
            continue;
          }

          final value = entry.value;
          if (value is List) {
            final joined = value.map((item) => item.toString()).join(', ');
            if (joined.trim().isNotEmpty) {
              fieldErrors.add('${entry.key}: $joined');
            }
          } else if (value is String && value.trim().isNotEmpty) {
            fieldErrors.add('${entry.key}: ${value.trim()}');
          }
        }

        if (fieldErrors.isNotEmpty) {
          return fieldErrors.join('\n');
        }

        if (decoded['detail'] != null) return decoded['detail'].toString();
        if (decoded['error'] != null) return decoded['error'].toString();
        if (decoded['message'] != null) return decoded['message'].toString();
      } else if (decoded is List) {
        final joined = decoded.map((item) => item.toString()).join('\n');
        if (joined.trim().isNotEmpty) {
          return joined;
        }
      }
    } catch (_) {}
    return null;
  }
}

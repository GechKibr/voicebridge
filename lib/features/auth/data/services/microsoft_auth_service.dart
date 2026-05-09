import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_appauth/flutter_appauth.dart';

import '../../../../core/config/api_config.dart';

class MicrosoftIdentity {
  final String microsoftAccessToken;
  final String? idToken;

  final String email;
  final String displayName;
  final String firstName;
  final String lastName;

  const MicrosoftIdentity({
    required this.microsoftAccessToken,
    required this.idToken,
    required this.email,
    required this.displayName,
    required this.firstName,
    required this.lastName,
  });

  String get suggestedUsername {
    final localPart = email.split('@').first.trim();

    if (localPart.isEmpty) {
      return 'user';
    }

    return localPart.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '').toLowerCase();
  }
}

class MicrosoftAuthService {
  MicrosoftAuthService();

  final FlutterAppAuth _appAuth = const FlutterAppAuth();

  Future<MicrosoftIdentity> authenticate() async {
    if (!ApiConfig.hasMicrosoftAppAuthConfig) {
      throw Exception('Microsoft authentication is not configured correctly.');
    }

    try {
      debugPrint('Starting Microsoft OAuth flow...');
      debugPrint('Redirect URI: ${ApiConfig.microsoftRedirectUri}');

      final AuthorizationTokenResponse response = await _appAuth
          .authorizeAndExchangeCode(
            AuthorizationTokenRequest(
              ApiConfig.microsoftClientId,
              ApiConfig.microsoftRedirectUri,

              serviceConfiguration: AuthorizationServiceConfiguration(
                authorizationEndpoint: ApiConfig.microsoftAuthorizationEndpoint,
                tokenEndpoint: ApiConfig.microsoftTokenEndpoint,
              ),

              scopes: ApiConfig.microsoftScopeList,

              promptValues: const ['select_account'],

              allowInsecureConnections: false,
            ),
          );

      final accessToken = response.accessToken;

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Microsoft login did not return an access token.');
      }

      final idToken = response.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception('Microsoft login did not return an ID token.');
      }

      final claims = _decodeJwtPayload(idToken);

      debugPrint('Microsoft claims: $claims');

      final email = _firstString(claims, const [
        'preferred_username',
        'email',
        'upn',
      ]);

      final fallbackEmail = email.isEmpty
          ? 'microsoft-user@local.invalid'
          : email;

      final displayName = _firstString(claims, const ['name']).trim().isNotEmpty
          ? _firstString(claims, const ['name'])
          : fallbackEmail.split('@').first;

      final firstName =
          _firstString(claims, const ['given_name']).trim().isNotEmpty
          ? _firstString(claims, const ['given_name'])
          : _splitName(displayName).first;

      final lastName =
          _firstString(claims, const ['family_name']).trim().isNotEmpty
          ? _firstString(claims, const ['family_name'])
          : _splitName(displayName).last;

      return MicrosoftIdentity(
        microsoftAccessToken: accessToken,
        idToken: idToken,
        email: fallbackEmail.toLowerCase(),
        displayName: displayName,
        firstName: firstName,
        lastName: lastName,
      );
    } on FlutterAppAuthUserCancelledException {
      throw Exception('Microsoft sign-in was cancelled by the user.');
    } on FlutterAppAuthPlatformException catch (e, stackTrace) {
      debugPrint('FlutterAppAuthPlatformException: ${e.code}');

      debugPrint('Message: ${e.message}');
      debugPrint('Details: ${e.details}');
      debugPrintStack(stackTrace: stackTrace);

      throw Exception(
        'Microsoft authentication failed. '
        'Code: ${e.code}. '
        'Message: ${e.message}',
      );
    } on PlatformException catch (e, stackTrace) {
      debugPrint('PlatformException: ${e.code}');

      debugPrint('Message: ${e.message}');
      debugPrint('Details: ${e.details}');
      debugPrintStack(stackTrace: stackTrace);

      throw Exception('Platform authentication error: ${e.message}');
    } catch (e, stackTrace) {
      debugPrint('Unexpected Microsoft auth error: $e');
      debugPrintStack(stackTrace: stackTrace);

      throw Exception('Unexpected Microsoft login error: $e');
    }
  }

  Future<String> getAccessToken() async {
    final identity = await authenticate();
    return identity.microsoftAccessToken;
  }

  Map<String, dynamic> _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');

      if (parts.length != 3) {
        return const {};
      }

      final payload = parts[1];

      final normalizedPayload = base64Url.normalize(payload);

      final payloadMap = jsonDecode(
        utf8.decode(base64Url.decode(normalizedPayload)),
      );

      if (payloadMap is Map<String, dynamic>) {
        return payloadMap;
      }

      return const {};
    } catch (_) {
      return const {};
    }
  }

  String _firstString(Map<String, dynamic> claims, List<String> keys) {
    for (final key in keys) {
      final value = claims[key];

      if (value == null) {
        continue;
      }

      final text = value.toString().trim();

      if (text.isNotEmpty) {
        return text;
      }
    }

    return '';
  }

  List<String> _splitName(String name) {
    final cleaned = name.trim();

    if (cleaned.isEmpty) {
      return const ['', ''];
    }

    final parts = cleaned.split(RegExp(r'\s+'));

    if (parts.length == 1) {
      return [parts.first, ''];
    }

    return [parts.first, parts.skip(1).join(' ')];
  }
}

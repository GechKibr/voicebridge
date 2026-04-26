import 'dart:convert';

import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter/services.dart';
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
    this.idToken,
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
  final FlutterAppAuth _appAuth = const FlutterAppAuth();

  String _platformErrorHint({
    required String configuredRedirectUri,
    required List<String> redirectCandidates,
  }) {
    final candidates = redirectCandidates.join(', ');
    return 'Check redirect URI setup. Configured MICROSOFT_REDIRECT_URI=$configuredRedirectUri. Tried callbacks: $candidates. Android manifest placeholders must match scheme and host from this URI.';
  }

  List<String> _redirectUriCandidates(String configured) {
    final normalized = configured.trim();
    if (normalized.isEmpty) {
      return const [];
    }

    final candidates = <String>[normalized];
    final parsed = Uri.tryParse(normalized);
    if (parsed == null || parsed.scheme.isEmpty) {
      return candidates;
    }

    // Accept both scheme://host and scheme:/path callback formats.
    if (parsed.host.isNotEmpty && (parsed.path.isEmpty || parsed.path == '/')) {
      final singleSlash = '${parsed.scheme}:/${parsed.host}';
      if (!candidates.contains(singleSlash)) {
        candidates.add(singleSlash);
      }
    }

    if (parsed.host.isEmpty && parsed.path.isNotEmpty) {
      final host = parsed.path.replaceFirst(RegExp(r'^/+'), '');
      if (host.isNotEmpty) {
        final doubleSlash = '${parsed.scheme}://$host';
        if (!candidates.contains(doubleSlash)) {
          candidates.add(doubleSlash);
        }
      }
    }

    return candidates;
  }

  Future<MicrosoftIdentity> authenticate() async {
    if (!ApiConfig.hasMicrosoftAppAuthConfig) {
      throw Exception(
        'Microsoft auth is not configured. Set MICROSOFT_CLIENT_ID and MICROSOFT_REDIRECT_URI.',
      );
    }

    final configuredRedirectUri = ApiConfig.microsoftRedirectUri;
    final redirectCandidates = _redirectUriCandidates(configuredRedirectUri);
    AuthorizationTokenResponse? response;
    Object? lastError;

    for (final redirectUri in redirectCandidates) {
      try {
        response = await _appAuth.authorizeAndExchangeCode(
          AuthorizationTokenRequest(
            ApiConfig.microsoftClientId,
            redirectUri,
            serviceConfiguration: AuthorizationServiceConfiguration(
              authorizationEndpoint: ApiConfig.microsoftAuthorizationEndpoint,
              tokenEndpoint: ApiConfig.microsoftTokenEndpoint,
            ),
            scopes: ApiConfig.microsoftScopeList,
            promptValues: const ['select_account'],
          ),
        );
        break;
      } on FlutterAppAuthUserCancelledException {
        throw Exception('Microsoft sign-in was cancelled.');
      } on FlutterAppAuthPlatformException catch (e) {
        lastError = e;
        // Try the next URI candidate.
      } on PlatformException catch (e) {
        lastError = e;
        // Try the next URI candidate.
      }
    }

    if (response == null) {
      if (lastError is FlutterAppAuthPlatformException) {
        final message = lastError.message?.trim();
        final code = lastError.code;
        final details = lastError.details?.toString().trim();
        final hint = _platformErrorHint(
          configuredRedirectUri: configuredRedirectUri,
          redirectCandidates: redirectCandidates,
        );
        throw Exception(
          message == null || message.isEmpty
              ? 'Microsoft sign-in failed on device. $hint'
              : 'Microsoft sign-in failed ($code): $message${details == null || details.isEmpty ? '' : ' | details: $details'}. $hint',
        );
      }

      if (lastError is PlatformException) {
        final message = lastError.message?.trim();
        final code = lastError.code;
        final details = lastError.details?.toString().trim();
        final hint = _platformErrorHint(
          configuredRedirectUri: configuredRedirectUri,
          redirectCandidates: redirectCandidates,
        );
        throw Exception(
          message == null || message.isEmpty
              ? 'Microsoft sign-in failed due to platform error ($code). $hint'
              : 'Microsoft sign-in failed ($code): $message${details == null || details.isEmpty ? '' : ' | details: $details'}. $hint',
        );
      }

      throw Exception('Microsoft sign-in failed before completing callback.');
    }

    final accessToken = response.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Microsoft login did not return an access_token.');
    }

    final idToken = response.idToken;
    var claims = _decodeJwtPayload(idToken);
    if (claims.isEmpty) {
      claims = _decodeJwtPayload(accessToken);
    }

    final email = _firstString(claims, ['preferred_username', 'email', 'upn']);
    final fallbackEmail = email.isEmpty
        ? 'microsoft-user@local.invalid'
        : email;

    final displayName = _firstString(claims, ['name']).trim().isNotEmpty
        ? _firstString(claims, ['name'])
        : fallbackEmail.split('@').first;
    final firstName = _firstString(claims, ['given_name']).trim().isNotEmpty
        ? _firstString(claims, ['given_name'])
        : _splitName(displayName).first;
    final lastName = _firstString(claims, ['family_name']).trim().isNotEmpty
        ? _firstString(claims, ['family_name'])
        : _splitName(displayName).last;

    return MicrosoftIdentity(
      microsoftAccessToken: accessToken,
      idToken: idToken,
      email: fallbackEmail.toLowerCase(),
      displayName: displayName,
      firstName: firstName,
      lastName: lastName,
    );
  }

  Future<String> getAccessToken() async {
    return (await authenticate()).microsoftAccessToken;
  }

  Map<String, dynamic> _decodeJwtPayload(String? token) {
    if (token == null || token.isEmpty) {
      return const {};
    }

    final parts = token.split('.');
    if (parts.length < 2) {
      return const {};
    }

    try {
      final normalized = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalized));
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      return const {};
    }

    return const {};
  }

  String _firstString(Map<String, dynamic> claims, List<String> keys) {
    for (final key in keys) {
      final value = claims[key];
      if (value != null) {
        final text = value.toString().trim();
        if (text.isNotEmpty) {
          return text;
        }
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

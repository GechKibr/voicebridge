import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get backendUrl =>
      dotenv.env['BACKEND_URL']?.trim().isNotEmpty == true
      ? dotenv.env['BACKEND_URL']!.trim()
      : 'http://localhost:8000';

  static String get microsoftClientId =>
      dotenv.env['MICROSOFT_CLIENT_ID']?.trim() ?? '';

  static String get microsoftTenantId =>
      dotenv.env['MICROSOFT_TENANT_ID']?.trim().isNotEmpty == true
      ? dotenv.env['MICROSOFT_TENANT_ID']!.trim()
      : 'common';

  static String get microsoftRedirectUri =>
      dotenv.env['MICROSOFT_REDIRECT_URI']?.trim().isNotEmpty == true
      ? dotenv.env['MICROSOFT_REDIRECT_URI']!.trim()
      : 'com.voicebridge://callback';

  static String get microsoftScopes =>
      dotenv.env['MICROSOFT_SCOPES']?.trim().isNotEmpty == true
      ? dotenv.env['MICROSOFT_SCOPES']!.trim()
      : 'openid profile email offline_access';

  static const String apiPrefix = '/api';

  static String get apiBaseUrl {
    final normalizedBase = backendUrl.endsWith('/')
        ? backendUrl.substring(0, backendUrl.length - 1)
        : backendUrl;
    return '$normalizedBase$apiPrefix';
  }

  static Uri uri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$apiBaseUrl$normalizedPath');
  }

  static List<String> get microsoftScopeList {
    const requiredScopes = [
      'openid',
      'profile',
      'email',
      'offline_access',
      'User.Read',
    ];
    final configuredScopes = microsoftScopes
        .split(RegExp(r'\s+'))
        .where((scope) => scope.trim().isNotEmpty)
        .toList();

    for (final scope in requiredScopes) {
      if (!configuredScopes.contains(scope)) {
        configuredScopes.add(scope);
      }
    }

    return configuredScopes.toList(growable: false);
  }

  static String get microsoftAuthorizationEndpoint {
    return 'https://login.microsoftonline.com/$microsoftTenantId/oauth2/v2.0/authorize';
  }

  static String get microsoftTokenEndpoint {
    return 'https://login.microsoftonline.com/$microsoftTenantId/oauth2/v2.0/token';
  }

  static bool get hasMicrosoftAppAuthConfig {
    return microsoftClientId.trim().isNotEmpty &&
        microsoftRedirectUri.trim().isNotEmpty;
  }
}

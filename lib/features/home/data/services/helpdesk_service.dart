import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/api_config.dart';
import '../../../auth/data/services/auth_service.dart';
import '../models/helpdesk_models.dart';

class HelpdeskService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers({bool includeContentType = true}) async {
    return _authService.buildAuthHeaders(
      includeContentType: includeContentType,
    );
  }

  Uri _uri(String path) {
    return ApiConfig.uri(path);
  }

  List<dynamic> _decodeList(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded;
    }
    if (decoded is Map<String, dynamic> && decoded['results'] is List) {
      return decoded['results'] as List;
    }
    return const [];
  }

  String _errorMessage(http.Response response, String fallback) {
    try {
      final payload = jsonDecode(response.body);
      if (payload is Map<String, dynamic>) {
        final detail = payload['detail']?.toString().trim() ?? '';
        if (detail.isNotEmpty) {
          return detail;
        }
      }
    } catch (_) {
      // Keep fallback when response body is not json.
    }
    return fallback;
  }

  Future<List<HelpdeskSession>> getSessions() async {
    final response = await http.get(
      _uri('/helpdesk/sessions/'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        _errorMessage(response, 'Failed to load helpdesk sessions.'),
      );
    }

    return _decodeList(response)
        .whereType<Map<String, dynamic>>()
        .map(HelpdeskSession.fromJson)
        .toList(growable: false);
  }

  Future<HelpdeskSession> createSession({
    required String kind,
    required List<int> participantIds,
    String title = '',
  }) async {
    final response = await http.post(
      _uri('/helpdesk/sessions/'),
      headers: await _headers(),
      body: jsonEncode({
        'title': title,
        'kind': kind,
        'participant_ids': participantIds,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(
        _errorMessage(response, 'Failed to create helpdesk session.'),
      );
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return HelpdeskSession.fromJson(payload);
  }

  Future<void> deleteSession(String sessionId) async {
    final response = await http.delete(
      _uri('/helpdesk/sessions/$sessionId/'),
      headers: await _headers(),
    );

    if (response.statusCode != 204) {
      throw Exception(
        _errorMessage(response, 'Failed to delete helpdesk session.'),
      );
    }
  }

  Future<HelpdeskSession> startSession(String sessionId) async {
    final response = await http.post(
      _uri('/helpdesk/sessions/$sessionId/start/'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        _errorMessage(response, 'Failed to start helpdesk session.'),
      );
    }

    return HelpdeskSession.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<HelpdeskSession> endSession(String sessionId) async {
    final response = await http.post(
      _uri('/helpdesk/sessions/$sessionId/end/'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        _errorMessage(response, 'Failed to end helpdesk session.'),
      );
    }

    return HelpdeskSession.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<HelpdeskMessage>> getMessages(String sessionId) async {
    final response = await http.get(
      _uri('/helpdesk/messages/?session_id=$sessionId'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        _errorMessage(response, 'Failed to load helpdesk messages.'),
      );
    }

    return _decodeList(response)
        .whereType<Map<String, dynamic>>()
        .map(HelpdeskMessage.fromJson)
        .toList(growable: false);
  }

  Future<HelpdeskMessage> postMessage({
    required String sessionId,
    required String content,
    String messageType = 'text',
    Map<String, dynamic> payload = const <String, dynamic>{},
  }) async {
    final response = await http.post(
      _uri('/helpdesk/messages/'),
      headers: await _headers(),
      body: jsonEncode({
        'session': sessionId,
        'message_type': messageType,
        'content': content,
        'payload': payload,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(
        _errorMessage(response, 'Failed to send helpdesk message.'),
      );
    }

    return HelpdeskMessage.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<HelpdeskCandidateUser>> getSessionCandidates() async {
    final response = await http.get(
      _uri('/helpdesk/sessions/candidates/'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        _errorMessage(response, 'Failed to load helpdesk candidates.'),
      );
    }

    return _decodeList(response)
        .whereType<Map<String, dynamic>>()
        .map(HelpdeskCandidateUser.fromJson)
        .where((user) => user.id > 0)
        .toList(growable: false);
  }

  Future<HelpdeskLivekitToken> getLivekitToken(String sessionId) async {
    final response = await http.post(
      _uri('/helpdesk/sessions/$sessionId/livekit-token/'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        _errorMessage(
          response,
          'Failed to get LiveKit token for helpdesk call.',
        ),
      );
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final token = HelpdeskLivekitToken.fromJson(payload);
    if (!token.isValid) {
      throw Exception('LiveKit token response is invalid.');
    }
    return token;
  }
}

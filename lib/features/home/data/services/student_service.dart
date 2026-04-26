import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/config/backend_endpoints.dart';
import '../../../auth/data/services/auth_service.dart';
import '../models/student_models.dart';

class StudentService {
  final AuthService _authService = AuthService();

  Uri _backendAnnouncementUri(String path) {
    final base = ApiConfig.backendUrl.endsWith('/')
        ? ApiConfig.backendUrl.substring(0, ApiConfig.backendUrl.length - 1)
        : ApiConfig.backendUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base/api$normalizedPath');
  }

  Future<bool> hasAuthenticatedSession() async {
    final token = await _authService.getAccessToken();
    return token != null && token.trim().isNotEmpty;
  }

  Future<Map<String, String>> _authHeaders({
    bool includeContentType = true,
  }) async {
    return _authService.buildAuthHeaders(
      includeContentType: includeContentType,
    );
  }

  List<dynamic> _decodeListResponse(String body) {
    final decoded = jsonDecode(body);
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic>) {
      final results = decoded['results'];
      if (results is List) return results;
    }
    return const [];
  }

  Map<String, dynamic> _cleanJson(Map<String, dynamic> payload) {
    payload.removeWhere((key, value) => value == null || value == '');
    return payload;
  }

  Map<String, dynamic> _complaintPayload({
    required String title,
    required String description,
    String? categoryId,
    int? ccOfficerId,
    List<int> ccOfficerIds = const [],
    bool anonymous = false,
    String? attachmentPath,
  }) {
    final normalizedCcIds = ccOfficerIds
        .where((id) => id > 0)
        .toList(growable: true);
    if (ccOfficerId != null &&
        ccOfficerId > 0 &&
        !normalizedCcIds.contains(ccOfficerId)) {
      normalizedCcIds.add(ccOfficerId);
    }

    return _cleanJson({
      'title': title,
      'description': description,
      'category': categoryId,
      'cc_officer_ids': normalizedCcIds,
      'is_anonymous': anonymous,
      'attachment_path': attachmentPath,
    });
  }

  String _extractErrorMessage(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is String && decoded.trim().isNotEmpty) {
        return decoded;
      }
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail']?.toString().trim() ?? '';
        if (detail.isNotEmpty) {
          return detail;
        }
        final firstEntry = decoded.entries.firstWhere(
          (entry) => entry.value != null,
          orElse: () => const MapEntry('', null),
        );
        if (firstEntry.key.isNotEmpty) {
          final value = firstEntry.value;
          if (value is List && value.isNotEmpty) {
            return '${firstEntry.key}: ${value.first}';
          }
          final text = '$value'.trim();
          if (text.isNotEmpty) {
            return '${firstEntry.key}: $text';
          }
        }
      }
    } catch (_) {
      // Return fallback when response body is not JSON.
    }
    return fallback;
  }

  MediaType? _inferAttachmentMediaType(String filePath) {
    final fileName = filePath.split(RegExp(r'[\\/]+')).last.toLowerCase();
    if (!fileName.contains('.')) return null;

    final extension = fileName.split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      case 'webp':
        return MediaType('image', 'webp');
      case 'bmp':
        return MediaType('image', 'bmp');
      case 'pdf':
        return MediaType('application', 'pdf');
      case 'txt':
        return MediaType('text', 'plain');
      case 'csv':
        return MediaType('text', 'csv');
      case 'doc':
        return MediaType('application', 'msword');
      case 'docx':
        return MediaType(
          'application',
          'vnd.openxmlformats-officedocument.wordprocessingml.document',
        );
      case 'xls':
        return MediaType('application', 'vnd.ms-excel');
      case 'xlsx':
        return MediaType(
          'application',
          'vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
      case 'ppt':
        return MediaType('application', 'vnd.ms-powerpoint');
      case 'pptx':
        return MediaType(
          'application',
          'vnd.openxmlformats-officedocument.presentationml.presentation',
        );
      default:
        return null;
    }
  }

  Future<http.Response> _sendMultipart({
    required String method,
    required Uri uri,
    required Map<String, dynamic> fields,
    String? attachmentPath,
  }) async {
    final headers = await _authHeaders(includeContentType: false);
    final request = http.MultipartRequest(method, uri);
    request.headers.addAll(headers);

    fields.forEach((key, value) {
      if (value != null && '$value'.trim().isNotEmpty) {
        if (value is List || value is Map<String, dynamic>) {
          request.fields[key] = jsonEncode(value);
        } else {
          request.fields[key] = '$value';
        }
      }
    });

    if (attachmentPath != null && attachmentPath.trim().isNotEmpty) {
      final file = File(attachmentPath);
      if (file.existsSync()) {
        final fileName = attachmentPath.split(RegExp(r'[\\/]+')).last;
        final contentType = _inferAttachmentMediaType(attachmentPath);
        if (contentType == null) {
          throw Exception(
            'Unsupported attachment type. Please upload an image, PDF, Word, Excel, PowerPoint, text, or CSV file.',
          );
        }
        request.files.add(
          await http.MultipartFile.fromPath(
            'attachment',
            attachmentPath,
            filename: fileName.isEmpty ? 'attachment' : fileName,
            contentType: contentType,
          ),
        );
      } else {
        request.fields['attachment_path'] = attachmentPath;
      }
    }

    final streamed = await request.send();
    return http.Response.fromStream(streamed);
  }

  Future<List<ComplaintCategory>> fetchComplaintCategories() async {
    final response = await http.get(
      ApiConfig.uri(BackendEndpoints.categories),
      headers: await _authHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load categories: ${response.statusCode}');
    }

    return _decodeListResponse(response.body)
        .whereType<Map<String, dynamic>>()
        .map(ComplaintCategory.fromJson)
        .where((category) => category.id.trim().isNotEmpty)
        .toList(growable: false);
  }

  Future<List<CategoryResolverOption>> fetchCategoryResolvers() async {
    final response = await http.get(
      ApiConfig.uri(BackendEndpoints.resolverAssignments),
      headers: await _authHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load category resolvers: ${response.statusCode}',
      );
    }

    return _decodeListResponse(response.body)
        .whereType<Map<String, dynamic>>()
        .map(CategoryResolverOption.fromJson)
        .where(
          (resolver) =>
              resolver.id > 0 && resolver.categoryId.trim().isNotEmpty,
        )
        .toList(growable: false);
  }

  Future<List<SelectableOfficer>> fetchOfficers() async {
    final candidatePaths = <String>[BackendEndpoints.officers];

    for (final path in candidatePaths) {
      try {
        final response = await http.get(
          ApiConfig.uri(path),
          headers: await _authHeaders(),
        );

        if (response.statusCode == 200) {
          final officers = _decodeListResponse(response.body)
              .whereType<Map<String, dynamic>>()
              .map(SelectableOfficer.fromJson)
              .where((officer) => officer.id > 0)
              .toList(growable: false);
          if (officers.isNotEmpty) {
            return officers;
          }
        }
      } catch (_) {
        // Try the next candidate path.
      }
    }

    return const [];
  }

  Future<List<StudentComplaint>> fetchMyComplaints() async {
    final response = await http.get(
      ApiConfig.uri('${BackendEndpoints.complaints}?mine=true'),
      headers: await _authHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load complaints: ${response.statusCode}');
    }

    return _decodeListResponse(response.body)
        .whereType<Map<String, dynamic>>()
        .map(StudentComplaint.fromJson)
        .toList(growable: false);
  }

  Future<void> submitComplaint({
    required String title,
    required String description,
    String? categoryId,
    int? ccOfficerId,
    List<int> ccOfficerIds = const [],
    bool anonymous = false,
    String? attachmentPath,
  }) async {
    final payload = _complaintPayload(
      title: title,
      description: description,
      categoryId: categoryId,
      ccOfficerId: ccOfficerId,
      ccOfficerIds: ccOfficerIds,
      anonymous: anonymous,
      attachmentPath: attachmentPath,
    );

    if (attachmentPath != null && attachmentPath.trim().isNotEmpty) {
      final response = await _sendMultipart(
        method: 'POST',
        uri: ApiConfig.uri(BackendEndpoints.complaints),
        fields: payload,
        attachmentPath: attachmentPath,
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception(
          _extractErrorMessage(
            response,
            'Failed to submit complaint: ${response.statusCode}',
          ),
        );
      }
      return;
    }

    final response = await http.post(
      ApiConfig.uri(BackendEndpoints.complaints),
      headers: await _authHeaders(),
      body: jsonEncode(payload),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(
        _extractErrorMessage(
          response,
          'Failed to submit complaint: ${response.statusCode}',
        ),
      );
    }
  }

  Future<void> updateComplaint({
    required int complaintId,
    required String title,
    required String description,
    String? categoryId,
    int? ccOfficerId,
    List<int> ccOfficerIds = const [],
    bool anonymous = false,
    String? attachmentPath,
  }) async {
    final payload = _complaintPayload(
      title: title,
      description: description,
      categoryId: categoryId,
      ccOfficerId: ccOfficerId,
      ccOfficerIds: ccOfficerIds,
      anonymous: anonymous,
      attachmentPath: attachmentPath,
    );

    if (attachmentPath != null && attachmentPath.trim().isNotEmpty) {
      final response = await _sendMultipart(
        method: 'PATCH',
        uri: ApiConfig.uri('${BackendEndpoints.complaints}$complaintId/'),
        fields: payload,
        attachmentPath: attachmentPath,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to update complaint: ${response.statusCode}');
      }
      return;
    }

    final response = await http.patch(
      ApiConfig.uri('${BackendEndpoints.complaints}$complaintId/'),
      headers: await _authHeaders(),
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to update complaint: ${response.statusCode}');
    }
  }

  Future<void> deleteComplaint(int complaintId) async {
    final response = await http.delete(
      ApiConfig.uri('${BackendEndpoints.complaints}$complaintId/'),
      headers: await _authHeaders(includeContentType: false),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete complaint: ${response.statusCode}');
    }
  }

  Future<List<StudentAppointment>> fetchAppointments() async {
    final response = await http.get(
      ApiConfig.uri('${BackendEndpoints.appointments}?mine=true'),
      headers: await _authHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load appointments: ${response.statusCode}');
    }

    return _decodeListResponse(response.body)
        .whereType<Map<String, dynamic>>()
        .map(StudentAppointment.fromJson)
        .toList(growable: false);
  }

  Future<void> requestAppointment({
    required String title,
    required String description,
    required DateTime scheduledFor,
  }) async {
    final response = await http.post(
      ApiConfig.uri(BackendEndpoints.appointments),
      headers: await _authHeaders(),
      body: jsonEncode({
        'title': title,
        'description': description,
        'scheduled_for': scheduledFor.toIso8601String(),
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to request appointment: ${response.statusCode}');
    }
  }

  Future<List<ServiceAssessmentForm>> fetchServiceAssessments() async {
    final candidatePaths = <String>[
      '${BackendEndpoints.responses}?kind=service_assessment',
      '${BackendEndpoints.responses}?kind=feedback',
      '${BackendEndpoints.responses}?kind=assessment',
    ];

    for (final path in candidatePaths) {
      try {
        final response = await http.get(
          ApiConfig.uri(path),
          headers: await _authHeaders(),
        );

        if (response.statusCode == 200) {
          final forms = _decodeListResponse(response.body)
              .whereType<Map<String, dynamic>>()
              .map(ServiceAssessmentForm.fromJson)
              .toList(growable: false);
          if (forms.isNotEmpty) {
            return forms;
          }
        }
      } catch (_) {
        // Try the next candidate path.
      }
    }

    return const [];
  }

  Future<List<UserNotification>> fetchNotifications() async {
    final response = await http.get(
      ApiConfig.uri(BackendEndpoints.notifications),
      headers: await _authHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load notifications: ${response.statusCode}');
    }

    return _decodeListResponse(response.body)
        .whereType<Map<String, dynamic>>()
        .map(UserNotification.fromJson)
        .toList(growable: false);
  }

  Future<void> markNotificationAsRead(int notificationId) async {
    final response = await http.post(
      ApiConfig.uri(
        '${BackendEndpoints.notifications}$notificationId/mark-as-read/',
      ),
      headers: await _authHeaders(includeContentType: false),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to update notification: ${response.statusCode}');
    }
  }

  Future<List<PublicAnnouncement>> fetchAnnouncements() async {
    final uri = _backendAnnouncementUri(BackendEndpoints.announcements);

    final publicResponse = await http.get(uri);
    if (publicResponse.statusCode == 200) {
      return _decodeListResponse(publicResponse.body)
          .whereType<Map<String, dynamic>>()
          .map(PublicAnnouncement.fromJson)
          .toList(growable: false);
    }

    final response = await http.get(uri, headers: await _authHeaders());

    if (response.statusCode != 200) {
      throw Exception('Failed to load announcements: ${response.statusCode}');
    }

    return _decodeListResponse(response.body)
        .whereType<Map<String, dynamic>>()
        .map(PublicAnnouncement.fromJson)
        .toList(growable: false);
  }

  Future<void> likeAnnouncement(int announcementId) async {
    final paths = <String>[
      '${BackendEndpoints.announcements}$announcementId/like/',
      '${BackendEndpoints.announcements}$announcementId/toggle-like/',
    ];

    http.Response? lastResponse;
    for (final path in paths) {
      final response = await http.post(
        _backendAnnouncementUri(path),
        headers: await _authHeaders(includeContentType: false),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Login required to like announcement.');
      }

      lastResponse = response;
      if (response.statusCode != 404) {
        throw Exception(
          _extractErrorMessage(
            response,
            'Failed to like announcement: ${response.statusCode}',
          ),
        );
      }
    }

    throw Exception(
      _extractErrorMessage(
        lastResponse ?? http.Response('', 404),
        'Failed to like announcement.',
      ),
    );
  }

  Future<void> commentAnnouncement({
    required int announcementId,
    required String message,
  }) async {
    final normalizedMessage = message.trim();
    if (normalizedMessage.isEmpty) {
      throw Exception('Comment cannot be empty.');
    }

    final paths = <String>[
      '${BackendEndpoints.announcements}$announcementId/comments/',
      '${BackendEndpoints.announcements}$announcementId/comment/',
    ];

    http.Response? lastResponse;
    for (final path in paths) {
      final response = await http.post(
        _backendAnnouncementUri(path),
        headers: await _authHeaders(),
        body: jsonEncode({'message': normalizedMessage}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Login required to comment on announcement.');
      }

      lastResponse = response;
      if (response.statusCode != 404) {
        throw Exception(
          _extractErrorMessage(
            response,
            'Failed to post announcement comment: ${response.statusCode}',
          ),
        );
      }
    }

    throw Exception(
      _extractErrorMessage(
        lastResponse ?? http.Response('', 404),
        'Failed to post announcement comment.',
      ),
    );
  }

  Future<void> submitFeedback({required String message, int rating = 5}) async {
    final response = await http.post(
      ApiConfig.uri(BackendEndpoints.responses),
      headers: await _authHeaders(),
      body: jsonEncode({
        'message': message,
        'rating': rating,
        'kind': 'feedback',
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to submit feedback: ${response.statusCode}');
    }
  }

  Future<List<FeedbackTemplateModel>> fetchFeedbackTemplates() async {
    final response = await http.get(
      ApiConfig.uri(BackendEndpoints.feedbackTemplates),
      headers: await _authHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load feedback templates: ${response.statusCode}',
      );
    }

    return _decodeListResponse(response.body)
        .whereType<Map<String, dynamic>>()
        .map(FeedbackTemplateModel.fromJson)
        .where((template) => template.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<FeedbackTemplateModel> createFeedbackTemplate({
    required String title,
    required String description,
    required List<Map<String, dynamic>> fields,
    String priority = 'low',
    String audienceScope = 'all',
    int? targetCampus,
    int? targetCollege,
    int? targetDepartment,
    List<int> targetUserIds = const [],
  }) async {
    final response = await http.post(
      ApiConfig.uri(BackendEndpoints.feedbackTemplates),
      headers: await _authHeaders(),
      body: jsonEncode(
        _cleanJson({
          'title': title,
          'description': description,
          'fields': fields,
          'priority': priority,
          'audience_scope': audienceScope,
          'target_campus': targetCampus,
          'target_college': targetCollege,
          'target_department': targetDepartment,
          'target_user_ids': targetUserIds,
        }),
      ),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(
        'Failed to create feedback template: ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected feedback template response.');
    }

    return FeedbackTemplateModel.fromJson(decoded);
  }

  Future<void> submitFeedbackTemplateResponse({
    required String templateId,
    required List<Map<String, dynamic>> answers,
  }) async {
    final response = await http.post(
      ApiConfig.uri(BackendEndpoints.feedbackResponses),
      headers: await _authHeaders(),
      body: jsonEncode({'template': templateId, 'answers': answers}),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to submit feedback form: ${response.statusCode}');
    }
  }

  Future<void> addComplaintRating({
    required String complaintRef,
    required int rating,
    String feedback = '',
  }) async {
    final response = await http.post(
      ApiConfig.uri(BackendEndpoints.comments),
      headers: await _authHeaders(),
      body: jsonEncode({
        'complaint': complaintRef,
        'comment_type': 'rating',
        'message': feedback.trim().isEmpty
            ? 'No feedback provided'
            : feedback.trim(),
        'rating': rating,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(
        'Failed to submit complaint rating: ${response.statusCode}',
      );
    }
  }

  Future<List<ComplaintRecord>> fetchAllComplaints() async {
    final response = await http.get(
      ApiConfig.uri(BackendEndpoints.complaints),
      headers: await _authHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load complaints: ${response.statusCode}');
    }

    return _decodeListResponse(response.body)
        .whereType<Map<String, dynamic>>()
        .map(ComplaintRecord.fromJson)
        .toList(growable: false);
  }

  Future<List<ComplaintRecord>> fetchCcComplaints() async {
    final response = await http.get(
      ApiConfig.uri('${BackendEndpoints.complaints}cc/'),
      headers: await _authHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load CC complaints: ${response.statusCode}');
    }

    return _decodeListResponse(response.body)
        .whereType<Map<String, dynamic>>()
        .map(ComplaintRecord.fromJson)
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> fetchUsers({String? role}) async {
    final query = role == null || role.trim().isEmpty
        ? BackendEndpoints.accountsList
        : '${BackendEndpoints.accountsList}?role=${Uri.encodeQueryComponent(role.trim())}';

    final response = await http.get(
      ApiConfig.uri(query),
      headers: await _authHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load users: ${response.statusCode}');
    }

    return _decodeListResponse(
      response.body,
    ).whereType<Map<String, dynamic>>().toList(growable: false);
  }

  Future<int> fetchInstitutionCount() async {
    final candidates = <String>[
      '/institutions/',
      BackendEndpoints.colleges,
      BackendEndpoints.campuses,
      BackendEndpoints.departments,
    ];

    for (final path in candidates) {
      try {
        final response = await http.get(
          ApiConfig.uri(path),
          headers: await _authHeaders(),
        );

        if (response.statusCode == 200) {
          return _decodeListResponse(response.body).length;
        }
      } catch (_) {
        // Try the next candidate endpoint.
      }
    }

    return 0;
  }

  Future<void> changeComplaintStatus({
    required int complaintId,
    required String status,
  }) async {
    final response = await http.post(
      ApiConfig.uri(
        '${BackendEndpoints.complaints}$complaintId/change-status/',
      ),
      headers: await _authHeaders(),
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Failed to update complaint status: ${response.statusCode}',
      );
    }
  }

  Future<void> reassignComplaint({
    required int complaintId,
    required int officerId,
    String reason = '',
  }) async {
    final response = await http.post(
      ApiConfig.uri('${BackendEndpoints.complaints}$complaintId/reassign/'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'officer_id': officerId,
        'reason': reason.isEmpty ? 'Reassigned from mobile app' : reason,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to reassign complaint: ${response.statusCode}');
    }
  }

  Future<void> createComplaintResponse({
    required String complaintRef,
    required String message,
    String title = 'Officer Response',
    String responseType = 'update',
  }) async {
    final response = await http.post(
      ApiConfig.uri(BackendEndpoints.responses),
      headers: await _authHeaders(),
      body: jsonEncode({
        'complaint': complaintRef,
        'title': title,
        'message': message,
        'response_type': responseType,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Failed to post complaint response: ${response.statusCode}',
      );
    }
  }

  Future<void> createComplaintComment({
    required String complaintRef,
    required String message,
    int? rating,
  }) async {
    final payload = <String, dynamic>{
      'complaint': complaintRef,
      'comment_type': 'comment',
      'message': message,
    };

    if (rating != null) {
      payload['rating'] = rating;
    }

    final response = await http.post(
      ApiConfig.uri(BackendEndpoints.comments),
      headers: await _authHeaders(),
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Failed to post complaint comment: ${response.statusCode}',
      );
    }
  }

  Future<List<Map<String, dynamic>>> fetchComplaintResponses({
    String? complaintRef,
    int? complaintId,
  }) async {
    final candidates = <String>[
      if (complaintRef != null && complaintRef.trim().isNotEmpty) ...[
        '${BackendEndpoints.responses}?complaint=${Uri.encodeQueryComponent(complaintRef)}',
        '${BackendEndpoints.responses}?complaint_id=${Uri.encodeQueryComponent(complaintRef)}',
        '${BackendEndpoints.responses}?complaint_uuid=${Uri.encodeQueryComponent(complaintRef)}',
      ],
      if (complaintId != null && complaintId > 0) ...[
        '${BackendEndpoints.responses}?complaint=$complaintId',
        '${BackendEndpoints.responses}?complaint_id=$complaintId',
        '${BackendEndpoints.complaints}$complaintId/responses/',
      ],
    ];

    http.Response? lastResponse;
    for (final path in candidates) {
      final response = await http.get(
        ApiConfig.uri(path),
        headers: await _authHeaders(),
      );

      if (response.statusCode == 200) {
        return _decodeListResponse(
          response.body,
        ).whereType<Map<String, dynamic>>().toList(growable: false);
      }

      lastResponse = response;
      if (response.statusCode != 404) {
        throw Exception(
          _extractErrorMessage(
            response,
            'Failed to load complaint responses: ${response.statusCode}',
          ),
        );
      }
    }

    throw Exception(
      _extractErrorMessage(
        lastResponse ?? http.Response('', 404),
        'Failed to load complaint responses: 404',
      ).trim(),
    );
  }

  Future<List<Map<String, dynamic>>> fetchComplaintComments(
    String complaintRef,
  ) async {
    final candidatePaths = <String>[
      '${BackendEndpoints.comments}?complaint=${Uri.encodeQueryComponent(complaintRef)}',
      '${BackendEndpoints.comments}?complaint_id=${Uri.encodeQueryComponent(complaintRef)}',
    ];

    for (final path in candidatePaths) {
      final response = await http.get(
        ApiConfig.uri(path),
        headers: await _authHeaders(),
      );

      if (response.statusCode == 200) {
        return _decodeListResponse(
          response.body,
        ).whereType<Map<String, dynamic>>().toList(growable: false);
      }
    }

    final numericId = int.tryParse(complaintRef);
    if (numericId != null && numericId > 0) {
      final legacyResponse = await http.get(
        ApiConfig.uri('${BackendEndpoints.complaints}$numericId/comments/'),
        headers: await _authHeaders(),
      );

      if (legacyResponse.statusCode == 200) {
        return _decodeListResponse(
          legacyResponse.body,
        ).whereType<Map<String, dynamic>>().toList(growable: false);
      }
    }

    throw Exception('Failed to load complaint comments for $complaintRef');
  }

  Future<List<Map<String, dynamic>>> fetchComplaintThread({
    String? complaintRef,
    int? complaintId,
  }) {
    return fetchComplaintResponses(
      complaintRef: complaintRef,
      complaintId: complaintId,
    );
  }

  Future<StudentProfile> fetchProfile() async {
    final response = await http.get(
      ApiConfig.uri(BackendEndpoints.accountsMe),
      headers: await _authHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load profile: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return StudentProfile.fromJson(decoded);
  }

  Future<void> updateProfile({
    String? email,
    String? gmailAccount,
    String? username,
    String? firstName,
    String? lastName,
    String? fullName,
    String? phone,
    Map<String, dynamic>? studentProfile,
    Map<String, dynamic>? officerProfile,
    String? password,
    String? confirmPassword,
  }) async {
    final body = _cleanJson({
      'email': email,
      'gmail_account': gmailAccount,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'full_name': fullName,
      'phone': phone,
      'student_profile': studentProfile,
      'officer_profile': officerProfile,
      'password': password,
      'confirm_password': confirmPassword,
    });

    final response = await http.patch(
      ApiConfig.uri(BackendEndpoints.accountsMeUpdate),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to update profile: ${response.statusCode}');
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final candidatePaths = <String>[
      '/accounts/change-password/',
      '/accounts/me/change-password/',
    ];

    Object? lastPayload;

    for (final path in candidatePaths) {
      final response = await http.post(
        ApiConfig.uri(path),
        headers: await _authHeaders(),
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
          'password': newPassword,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }

      lastPayload = 'Failed on $path: ${response.statusCode}';
    }

    throw Exception(lastPayload?.toString() ?? 'Failed to change password.');
  }
}

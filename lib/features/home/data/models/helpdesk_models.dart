class HelpdeskKinds {
  static const String audioCall = 'audio_call';
  static const String videoCall = 'video_call';
  static const String audioConference = 'audio_conference';
  static const String videoConference = 'video_conference';

  static const List<String> values = [
    audioCall,
    videoCall,
    audioConference,
    videoConference,
  ];
}

class HelpdeskSessionStatus {
  static const String pending = 'pending';
  static const String active = 'active';
  static const String ended = 'ended';
  static const String cancelled = 'cancelled';
}

class HelpdeskParticipant {
  final int userId;
  final String fullName;
  final String roleName;
  final String role;

  const HelpdeskParticipant({
    required this.userId,
    required this.fullName,
    required this.roleName,
    required this.role,
  });

  factory HelpdeskParticipant.fromJson(Map<String, dynamic> json) {
    return HelpdeskParticipant(
      userId: json['user_id'] is int
          ? json['user_id'] as int
          : int.tryParse('${json['user_id'] ?? 0}') ?? 0,
      fullName: json['full_name']?.toString() ?? '',
      roleName: json['role_name']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
    );
  }
}

class HelpdeskSession {
  final String id;
  final String title;
  final String kind;
  final String status;
  final int createdById;
  final List<HelpdeskParticipant> participants;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const HelpdeskSession({
    required this.id,
    required this.title,
    required this.kind,
    required this.status,
    required this.createdById,
    required this.participants,
    required this.startedAt,
    required this.endedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HelpdeskSession.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    final participantsRaw = json['participants'];
    final participants = participantsRaw is List
        ? participantsRaw
              .whereType<Map<String, dynamic>>()
              .map(HelpdeskParticipant.fromJson)
              .toList(growable: false)
        : const <HelpdeskParticipant>[];

    return HelpdeskSession(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      kind: json['kind']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdById: json['created_by_id'] is int
          ? json['created_by_id'] as int
          : int.tryParse('${json['created_by_id'] ?? 0}') ?? 0,
      participants: participants,
      startedAt: parseDate(json['started_at']),
      endedAt: parseDate(json['ended_at']),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  String get displayTitle => title.trim().isEmpty ? 'Untitled Session' : title;
}

class HelpdeskMessage {
  final String id;
  final String sessionId;
  final int senderId;
  final String senderName;
  final String messageType;
  final String content;
  final Map<String, dynamic> payload;
  final DateTime? createdAt;

  const HelpdeskMessage({
    required this.id,
    required this.sessionId,
    required this.senderId,
    required this.senderName,
    required this.messageType,
    required this.content,
    required this.payload,
    required this.createdAt,
  });

  factory HelpdeskMessage.fromJson(Map<String, dynamic> json) {
    final rawPayload = json['payload'];
    return HelpdeskMessage(
      id: json['id']?.toString() ?? '',
      sessionId: json['session']?.toString() ?? '',
      senderId: json['sender_id'] is int
          ? json['sender_id'] as int
          : int.tryParse('${json['sender_id'] ?? 0}') ?? 0,
      senderName: json['sender_name']?.toString() ?? '',
      messageType: json['message_type']?.toString() ?? 'text',
      content: json['content']?.toString() ?? '',
      payload: rawPayload is Map<String, dynamic>
          ? rawPayload
          : const <String, dynamic>{},
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

class HelpdeskCandidateUser {
  final int id;
  final String email;
  final String fullName;
  final String firstName;
  final String lastName;
  final String role;

  const HelpdeskCandidateUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.firstName,
    required this.lastName,
    required this.role,
  });

  factory HelpdeskCandidateUser.fromJson(Map<String, dynamic> json) {
    return HelpdeskCandidateUser(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id'] ?? 0}') ?? 0,
      email: json['email']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
    );
  }

  String get displayName {
    if (fullName.trim().isNotEmpty) {
      return fullName.trim();
    }
    final fallback = '${firstName.trim()} ${lastName.trim()}'.trim();
    if (fallback.isNotEmpty) {
      return fallback;
    }
    return email;
  }
}

class HelpdeskLivekitToken {
  final String url;
  final String token;
  final String roomName;
  final String sessionId;
  final String participantUserId;

  const HelpdeskLivekitToken({
    required this.url,
    required this.token,
    required this.roomName,
    required this.sessionId,
    required this.participantUserId,
  });

  factory HelpdeskLivekitToken.fromJson(Map<String, dynamic> json) {
    return HelpdeskLivekitToken(
      url: json['url']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
      roomName: json['room_name']?.toString() ?? '',
      sessionId: json['session_id']?.toString() ?? '',
      participantUserId: json['participant_user_id']?.toString() ?? '',
    );
  }

  String get connectUrl {
    final parsed = Uri.tryParse(url.trim());
    if (parsed == null) return url.trim();

    if (parsed.scheme == 'http' || parsed.scheme == 'https') {
      return parsed
          .replace(scheme: parsed.scheme == 'https' ? 'wss' : 'ws')
          .toString();
    }

    return parsed.toString();
  }

  bool get isValid =>
      url.trim().isNotEmpty && token.trim().isNotEmpty && roomName.isNotEmpty;
}

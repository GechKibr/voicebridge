class ComplaintCategory {
  final String id;
  final String submitCategoryId;
  final String name;
  final String description;
  final String officeScope;
  final String parentName;
  final String campusName;
  final String collegeName;
  final String departmentName;

  ComplaintCategory({
    required this.id,
    required this.submitCategoryId,
    required this.name,
    required this.description,
    required this.officeScope,
    required this.parentName,
    required this.campusName,
    required this.collegeName,
    required this.departmentName,
  });

  static String _firstNonEmpty(Iterable<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }

  static String _slug(String value) {
    final lower = value.toLowerCase();
    final normalized = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return normalized.replaceAll(RegExp(r'^_+|_+$'), '');
  }

  factory ComplaintCategory.fromJson(Map<String, dynamic> json) {
    final officeName = _firstNonEmpty([
      json['office_name'],
      json['name'],
      json['title'],
      'Category',
    ]);
    final officeScope = _firstNonEmpty([
      json['office_scope'],
      json['scope'],
      'general',
    ]);
    final campusName = _firstNonEmpty([json['campus_name']]);
    final collegeName = _firstNonEmpty([json['college_name']]);
    final departmentName = _firstNonEmpty([json['department_name']]);
    final parentName = _firstNonEmpty([json['parent_name'], json['parent']]);

    final explicitId = _firstNonEmpty([json['category_id'], json['id']]);

    final generatedId = _slug(
      [
        officeName,
        officeScope,
        campusName,
        collegeName,
        departmentName,
        parentName,
      ].where((part) => part.trim().isNotEmpty).join('_'),
    );

    return ComplaintCategory(
      id: explicitId.isNotEmpty ? explicitId : generatedId,
      submitCategoryId: explicitId,
      name: officeName,
      description: _firstNonEmpty([
        json['office_description'],
        json['description'],
      ]),
      officeScope: officeScope,
      parentName: parentName,
      campusName: campusName,
      collegeName: collegeName,
      departmentName: departmentName,
    );
  }
}

class CategoryResolverOption {
  final int id;
  final String categoryId;
  final String categoryName;
  final int levelId;
  final String levelName;
  final int officerId;
  final String officerName;
  final bool isActive;

  CategoryResolverOption({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.levelId,
    required this.levelName,
    required this.officerId,
    required this.officerName,
    required this.isActive,
  });

  factory CategoryResolverOption.fromJson(Map<String, dynamic> json) {
    int readInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse('$value') ?? 0;
    }

    return CategoryResolverOption(
      id: readInt(json['id']),
      categoryId: (json['category'] ?? '').toString(),
      categoryName: (json['category_name'] ?? '').toString(),
      levelId: readInt(json['level']),
      levelName: (json['level_name'] ?? '').toString(),
      officerId: readInt(json['officer']),
      officerName: (json['officer_name'] ?? '').toString(),
      isActive: json['active'] == true,
    );
  }
}

class FeedbackTemplateField {
  final String id;
  final String label;
  final String fieldType;
  final List<String> options;
  final bool isRequired;
  final int order;

  FeedbackTemplateField({
    required this.id,
    required this.label,
    required this.fieldType,
    required this.options,
    required this.isRequired,
    required this.order,
  });

  factory FeedbackTemplateField.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    final options = rawOptions is List
        ? rawOptions
              .map((item) => '$item')
              .where((item) => item.isNotEmpty)
              .toList(growable: false)
        : rawOptions is Map
        ? rawOptions.entries
              .map((entry) {
                final key = '${entry.key}'.trim();
                final value = '${entry.value}'.trim();
                return key.isNotEmpty ? key : value;
              })
              .where((item) => item.isNotEmpty)
              .toList(growable: false)
        : const <String>[];

    return FeedbackTemplateField(
      id: (json['id'] ?? '').toString(),
      label: (json['label'] ?? 'Field').toString(),
      fieldType: (json['field_type'] ?? 'text').toString(),
      options: options,
      isRequired: json['is_required'] == true,
      order: json['order'] is int
          ? json['order'] as int
          : int.tryParse('${json['order'] ?? 0}') ?? 0,
    );
  }
}

class FeedbackTemplateModel {
  final String id;
  final String title;
  final String description;
  final String office;
  final String status;
  final String priority;
  final List<FeedbackTemplateField> fields;

  FeedbackTemplateModel({
    required this.id,
    required this.title,
    required this.description,
    required this.office,
    required this.status,
    required this.priority,
    required this.fields,
  });

  bool get isActive => status.toLowerCase() == 'active';

  factory FeedbackTemplateModel.fromJson(Map<String, dynamic> json) {
    final rawFields = json['fields'];
    final fields = rawFields is List
        ? rawFields
              .whereType<Map<String, dynamic>>()
              .map(FeedbackTemplateField.fromJson)
              .toList(growable: false)
        : const <FeedbackTemplateField>[];

    return FeedbackTemplateModel(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Feedback Form').toString(),
      description: (json['description'] ?? '').toString(),
      office: (json['office'] ?? 'General').toString(),
      status: (json['status'] ?? 'inactive').toString(),
      priority: (json['priority'] ?? 'medium').toString(),
      fields: fields,
    );
  }
}

class SelectableOfficer {
  final int id;
  final String name;
  final String email;
  final String role;
  final String department;

  SelectableOfficer({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
  });

  factory SelectableOfficer.fromJson(Map<String, dynamic> json) {
    String readName(Map<String, dynamic> source) {
      final fullName = (source['full_name'] ?? '').toString().trim();
      if (fullName.isNotEmpty) return fullName;

      final firstName = (source['first_name'] ?? '').toString().trim();
      final lastName = (source['last_name'] ?? '').toString().trim();
      final combined = '$firstName $lastName'.trim();
      if (combined.isNotEmpty) return combined;

      final displayName = (source['display_name'] ?? source['name'] ?? '')
          .toString()
          .trim();
      if (displayName.isNotEmpty) return displayName;

      return (source['username'] ?? source['email'] ?? 'Officer').toString();
    }

    final source = json;
    return SelectableOfficer(
      id: source['id'] is int
          ? source['id'] as int
          : int.tryParse('${source['id'] ?? 0}') ?? 0,
      name: readName(source),
      email: (source['email'] ?? '').toString(),
      role: (source['role'] ?? 'officer').toString(),
      department: (source['department_name'] ?? source['department'] ?? '')
          .toString(),
    );
  }
}

class StudentComplaint {
  final int id;
  final String complaintRef;
  final String title;
  final String description;
  final String status;
  final String createdAt;
  final String? categoryId;
  final String categoryName;
  final int? assignedOfficerId;
  final String assignedOfficerName;
  final bool isAnonymous;
  final String attachmentName;

  StudentComplaint({
    required this.id,
    required this.complaintRef,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.categoryId,
    required this.categoryName,
    required this.assignedOfficerId,
    required this.assignedOfficerName,
    required this.isAnonymous,
    required this.attachmentName,
  });

  factory StudentComplaint.fromJson(Map<String, dynamic> json) {
    int? readId(dynamic value) {
      if (value is int && value > 0) return value;
      final parsed = int.tryParse('$value');
      return parsed != null && parsed > 0 ? parsed : null;
    }

    String? readCategoryId(dynamic value) {
      final normalized = (value ?? '').toString().trim();
      return normalized.isEmpty ? null : normalized;
    }

    String readName(dynamic value) {
      if (value is Map<String, dynamic>) {
        return (value['full_name'] ?? value['name'] ?? value['title'] ?? '')
            .toString()
            .trim();
      }
      return value?.toString().trim() ?? '';
    }

    final category = json['category'];
    final assignedOfficer = json['assigned_officer'];

    return StudentComplaint(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id'] ?? 0}') ?? 0,
      complaintRef: (json['complaint_id'] ?? json['uuid'] ?? json['id'] ?? '')
          .toString(),
      title: (json['title'] ?? json['subject'] ?? 'Untitled complaint')
          .toString(),
      description: (json['description'] ?? json['detail'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      createdAt: (json['created_at'] ?? json['created'] ?? '').toString(),
      categoryId:
          readCategoryId(json['category_id']) ??
          readCategoryId(
            category is Map<String, dynamic> ? category['category_id'] : null,
          ) ??
          readCategoryId(
            category is Map<String, dynamic> ? category['id'] : null,
          ),
      categoryName: category is Map<String, dynamic>
          ? (category['office_name'] ??
                    category['name'] ??
                    category['title'] ??
                    'Uncategorized')
                .toString()
          : (json['category_name'] ?? 'Uncategorized').toString(),
      assignedOfficerId:
          readId(json['assigned_officer_id']) ??
          readId(
            assignedOfficer is Map<String, dynamic>
                ? assignedOfficer['id']
                : null,
          ),
      assignedOfficerName: readName(assignedOfficer).isNotEmpty
          ? readName(assignedOfficer)
          : (json['assigned_officer_name'] ?? '').toString(),
      isAnonymous: json['is_anonymous'] == true || json['anonymous'] == true,
      attachmentName:
          (json['attachment_name'] ??
                  json['attachment'] ??
                  json['file_name'] ??
                  '')
              .toString(),
    );
  }
}

class StudentAppointment {
  final int id;
  final String title;
  final String description;
  final String scheduledFor;
  final String status;
  final String officerName;
  final String location;

  StudentAppointment({
    required this.id,
    required this.title,
    required this.description,
    required this.scheduledFor,
    required this.status,
    required this.officerName,
    required this.location,
  });

  factory StudentAppointment.fromJson(Map<String, dynamic> json) {
    String readName(dynamic value) {
      if (value is Map<String, dynamic>) {
        return (value['full_name'] ?? value['name'] ?? value['title'] ?? '')
            .toString()
            .trim();
      }
      return value?.toString().trim() ?? '';
    }

    final officer =
        json['officer'] ?? json['assigned_officer'] ?? json['created_by'];

    return StudentAppointment(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id'] ?? 0}') ?? 0,
      title: (json['title'] ?? json['subject'] ?? 'Appointment').toString(),
      description: (json['description'] ?? '').toString(),
      scheduledFor: (json['scheduled_for'] ?? json['date_time'] ?? '')
          .toString(),
      status: (json['status'] ?? 'pending').toString(),
      officerName: readName(officer).isNotEmpty
          ? readName(officer)
          : (json['officer_name'] ?? json['assigned_officer_name'] ?? '')
                .toString(),
      location: (json['location'] ?? json['venue'] ?? '').toString(),
    );
  }
}

class ServiceAssessmentForm {
  final int id;
  final String title;
  final String description;
  final String officerName;
  final String createdAt;

  ServiceAssessmentForm({
    required this.id,
    required this.title,
    required this.description,
    required this.officerName,
    required this.createdAt,
  });

  factory ServiceAssessmentForm.fromJson(Map<String, dynamic> json) {
    String readName(dynamic value) {
      if (value is Map<String, dynamic>) {
        return (value['full_name'] ?? value['name'] ?? value['title'] ?? '')
            .toString()
            .trim();
      }
      return value?.toString().trim() ?? '';
    }

    final creator =
        json['created_by'] ?? json['created_by_user'] ?? json['officer'];

    return ServiceAssessmentForm(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id'] ?? 0}') ?? 0,
      title:
          (json['title'] ??
                  json['subject'] ??
                  json['name'] ??
                  'Service assessment')
              .toString(),
      description:
          (json['description'] ?? json['message'] ?? json['detail'] ?? '')
              .toString(),
      officerName: readName(creator).isNotEmpty
          ? readName(creator)
          : (json['officer_name'] ?? json['created_by_name'] ?? 'Officer')
                .toString(),
      createdAt: (json['created_at'] ?? json['created'] ?? '').toString(),
    );
  }
}

class StudentProfile {
  final int id;
  final String email;
  final String gmailAccount;
  final String fullName;
  final String username;
  final String firstName;
  final String lastName;
  final String phone;
  final String role;
  final Map<String, dynamic>? studentProfile;
  final Map<String, dynamic>? officerProfile;

  StudentProfile({
    required this.id,
    required this.email,
    required this.gmailAccount,
    required this.fullName,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.role,
    this.studentProfile,
    this.officerProfile,
  });

  static int? _readInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse('${value ?? ''}');
  }

  String get studentId => (studentProfile?['student_id'] ?? '').toString();
  String get campusId => (studentProfile?['campus_id'] ?? '').toString();
  int? get yearOfStudy => _readInt(studentProfile?['year_of_study']);
  int? get studentTypeId => _readInt(studentProfile?['student_type']);
  int? get departmentId => _readInt(studentProfile?['department']);
  int? get programId => _readInt(studentProfile?['program']);

  String get employeeId => (officerProfile?['employee_id'] ?? '').toString();
  int? get officerCollegeId => _readInt(officerProfile?['college']);
  int? get officerDepartmentId => _readInt(officerProfile?['department']);

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    final fullName =
        (json['full_name'] ??
                '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}')
            .toString()
            .trim();
    return StudentProfile(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id'] ?? 0}') ?? 0,
      email: (json['email'] ?? '').toString(),
      gmailAccount: (json['gmail_account'] ?? json['email'] ?? '').toString(),
      fullName: fullName,
      username: (json['username'] ?? '').toString(),
      firstName: (json['first_name'] ?? '').toString(),
      lastName: (json['last_name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      role: (json['role'] ?? 'user').toString(),
      studentProfile: json['student_profile'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(
              json['student_profile'] as Map<String, dynamic>,
            )
          : null,
      officerProfile: json['officer_profile'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(
              json['officer_profile'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class ComplaintRecord {
  final int id;
  final String complaintRef;
  final String title;
  final String description;
  final String status;
  final String createdAt;
  final String priority;
  final String categoryName;
  final String assignedOfficerName;
  final String complainantName;
  final bool isCcUser;

  ComplaintRecord({
    required this.id,
    required this.complaintRef,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.priority,
    required this.categoryName,
    required this.assignedOfficerName,
    required this.complainantName,
    required this.isCcUser,
  });

  factory ComplaintRecord.fromJson(Map<String, dynamic> json) {
    String readName(dynamic value) {
      if (value is Map<String, dynamic>) {
        return (value['full_name'] ?? value['name'] ?? value['email'] ?? '')
            .toString()
            .trim();
      }
      return value?.toString().trim() ?? '';
    }

    final category = json['category'];
    final assignedOfficer = json['assigned_officer'];
    final complainant = json['complainant'];

    return ComplaintRecord(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id'] ?? 0}') ?? 0,
      complaintRef: (json['complaint_id'] ?? json['uuid'] ?? json['id'] ?? '')
          .toString(),
      title: (json['title'] ?? json['subject'] ?? 'Untitled complaint')
          .toString(),
      description: (json['description'] ?? json['detail'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      createdAt: (json['created_at'] ?? json['created'] ?? '').toString(),
      priority: (json['priority'] ?? 'normal').toString(),
      categoryName: category is Map<String, dynamic>
          ? (category['name'] ?? category['title'] ?? 'Uncategorized')
                .toString()
          : (json['category_name'] ?? 'Uncategorized').toString(),
      assignedOfficerName: readName(assignedOfficer).isNotEmpty
          ? readName(assignedOfficer)
          : (json['assigned_officer_name'] ?? '').toString(),
      complainantName: readName(complainant).isNotEmpty
          ? readName(complainant)
          : (json['complainant_name'] ?? '').toString(),
      isCcUser: json['is_cc_user'] == true,
    );
  }
}

class UserNotification {
  final int id;
  final String title;
  final String message;
  final String createdAt;
  final bool isRead;
  final String type;
  final String? targetType;
  final String? targetRoute;
  final String? targetId;
  final int? complaintId;
  final String? complaintRef;

  UserNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
    required this.type,
    this.targetType,
    this.targetRoute,
    this.targetId,
    this.complaintId,
    this.complaintRef,
  });

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    int? readInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse('$value');
    }

    String? readText(dynamic value) {
      final text = (value ?? '').toString().trim();
      return text.isEmpty ? null : text;
    }

    return UserNotification(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id'] ?? 0}') ?? 0,
      title: (json['title'] ?? json['subject'] ?? 'Notification').toString(),
      message: (json['message'] ?? json['body'] ?? '').toString(),
      createdAt: (json['created_at'] ?? json['created'] ?? '').toString(),
      isRead: json['is_read'] == true || json['read'] == true,
      type: (json['type'] ?? 'info').toString(),
      targetType: readText(json['target_type'] ?? json['targetType']),
      targetRoute: readText(
        json['route'] ?? json['target_route'] ?? json['targetRoute'],
      ),
      targetId: readText(json['target_id'] ?? json['targetId']),
      complaintId: readInt(json['complaint_id'] ?? json['complaintId']),
      complaintRef: readText(json['complaint_ref'] ?? json['complaintRef']),
    );
  }
}

class PublicAnnouncement {
  final int id;
  final String title;
  final String message;
  final String createdByName;
  final String createdAt;
  final bool isPinned;
  final int likesCount;
  final int commentsCount;
  final bool likedByUser;

  PublicAnnouncement({
    required this.id,
    required this.title,
    required this.message,
    required this.createdByName,
    required this.createdAt,
    required this.isPinned,
    required this.likesCount,
    required this.commentsCount,
    required this.likedByUser,
  });

  factory PublicAnnouncement.fromJson(Map<String, dynamic> json) {
    int readInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse('$value') ?? 0;
    }

    return PublicAnnouncement(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id'] ?? 0}') ?? 0,
      title: (json['title'] ?? json['heading'] ?? 'Announcement').toString(),
      message: (json['message'] ?? json['content'] ?? '').toString(),
      createdByName: (json['created_by_name'] ?? json['author_name'] ?? 'Staff')
          .toString(),
      createdAt: (json['created_at'] ?? json['published_at'] ?? '').toString(),
      isPinned: json['is_pinned'] == true || json['pinned'] == true,
      likesCount: readInt(json['likes_count'] ?? json['likes'] ?? 0),
      commentsCount: readInt(json['comments_count'] ?? json['comments'] ?? 0),
      likedByUser: json['liked_by_user'] == true,
    );
  }
}

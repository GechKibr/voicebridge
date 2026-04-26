import 'package:flutter/material.dart';

import '../../data/models/student_models.dart';
import '../../data/services/student_service.dart';

class StudentController with ChangeNotifier {
  final StudentService _service = StudentService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSubmittingComplaint = false;
  bool get isSubmittingComplaint => _isSubmittingComplaint;

  bool _isRequestingAppointment = false;
  bool get isRequestingAppointment => _isRequestingAppointment;

  bool _isSubmittingFeedback = false;
  bool get isSubmittingFeedback => _isSubmittingFeedback;

  bool _isUpdatingProfile = false;
  bool get isUpdatingProfile => _isUpdatingProfile;

  bool _isChangingPassword = false;
  bool get isChangingPassword => _isChangingPassword;

  bool _hasAuthenticatedSession = false;
  bool get hasAuthenticatedSession => _hasAuthenticatedSession;

  String? _error;
  String? get error => _error;

  List<ComplaintCategory> _categories = [];
  List<ComplaintCategory> get categories => _categories;

  List<SelectableOfficer> _officers = [];
  List<SelectableOfficer> get officers => _officers;

  List<CategoryResolverOption> _resolverOptions = [];
  List<CategoryResolverOption> get resolverOptions => _resolverOptions;

  List<StudentComplaint> _complaints = [];
  List<StudentComplaint> get complaints => _complaints;

  List<StudentAppointment> _appointments = [];
  List<StudentAppointment> get appointments => _appointments;

  List<ServiceAssessmentForm> _serviceAssessments = [];
  List<ServiceAssessmentForm> get serviceAssessments => _serviceAssessments;

  List<FeedbackTemplateModel> _feedbackTemplates = [];
  List<FeedbackTemplateModel> get feedbackTemplates => _feedbackTemplates;

  List<UserNotification> _notifications = [];
  List<UserNotification> get notifications => _notifications;

  List<PublicAnnouncement> _announcements = [];
  List<PublicAnnouncement> get announcements => _announcements;

  StudentProfile? _profile;
  StudentProfile? get profile => _profile;

  Future<T?> _runSafely<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      _error ??= e.toString();
      return null;
    }
  }

  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _hasAuthenticatedSession = await _service.hasAuthenticatedSession();

    if (!_hasAuthenticatedSession) {
      final publicAnnouncements = await _runSafely(
        () => _service.fetchAnnouncements(),
      );
      _announcements = publicAnnouncements ?? [];
      _categories = [];
      _resolverOptions = [];
      _officers = [];
      _complaints = [];
      _appointments = [];
      _profile = null;
      _notifications = [];
      _serviceAssessments = [];
      _feedbackTemplates = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    final results = await Future.wait([
      _runSafely(() => _service.fetchComplaintCategories()),
      _runSafely(() => _service.fetchCategoryResolvers()),
      _runSafely(() => _service.fetchOfficers()),
      _runSafely(() => _service.fetchMyComplaints()),
      _runSafely(() => _service.fetchAppointments()),
      _runSafely(() => _service.fetchProfile()),
      _runSafely(() => _service.fetchNotifications()),
      _runSafely(() => _service.fetchAnnouncements()),
      _runSafely(() => _service.fetchServiceAssessments()),
      _runSafely(() => _service.fetchFeedbackTemplates()),
    ]);

    _categories = results[0] as List<ComplaintCategory>? ?? [];
    _resolverOptions = results[1] as List<CategoryResolverOption>? ?? [];
    _officers = results[2] as List<SelectableOfficer>? ?? [];
    _complaints = results[3] as List<StudentComplaint>? ?? [];
    _appointments = results[4] as List<StudentAppointment>? ?? [];
    _profile = results[5] as StudentProfile?;
    _notifications = results[6] as List<UserNotification>? ?? [];
    _announcements = results[7] as List<PublicAnnouncement>? ?? [];
    _serviceAssessments = results[8] as List<ServiceAssessmentForm>? ?? [];
    _feedbackTemplates = results[9] as List<FeedbackTemplateModel>? ?? [];

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshComplaints() async {
    final updated = await _runSafely(() => _service.fetchMyComplaints());
    if (updated != null) {
      _complaints = updated;
      notifyListeners();
    }
  }

  Future<void> refreshAppointments() async {
    final updated = await _runSafely(() => _service.fetchAppointments());
    if (updated != null) {
      _appointments = updated;
      notifyListeners();
    }
  }

  Future<void> refreshNotifications() async {
    final updated = await _runSafely(() => _service.fetchNotifications());
    if (updated != null) {
      _notifications = updated;
      notifyListeners();
    }
  }

  Future<void> refreshAnnouncements() async {
    final updated = await _runSafely(() => _service.fetchAnnouncements());
    if (updated != null) {
      _announcements = updated;
      notifyListeners();
    }
  }

  Future<bool> likeAnnouncement(int announcementId) async {
    _error = null;
    notifyListeners();

    try {
      await _service.likeAnnouncement(announcementId);
      await refreshAnnouncements();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> commentAnnouncement({
    required int announcementId,
    required String message,
  }) async {
    _error = null;
    notifyListeners();

    try {
      await _service.commentAnnouncement(
        announcementId: announcementId,
        message: message,
      );
      await refreshAnnouncements();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshServiceAssessments() async {
    final updated = await _runSafely(() => _service.fetchServiceAssessments());
    if (updated != null) {
      _serviceAssessments = updated;
      notifyListeners();
    }
  }

  Future<void> refreshFeedbackTemplates() async {
    final updated = await _runSafely(() => _service.fetchFeedbackTemplates());
    if (updated != null) {
      _feedbackTemplates = updated;
      notifyListeners();
    }
  }

  Future<void> markNotificationAsRead(int notificationId) async {
    try {
      await _service.markNotificationAsRead(notificationId);
      await refreshNotifications();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    final unreadIds = _notifications
        .where((notification) => !notification.isRead)
        .map((notification) => notification.id)
        .toList(growable: false);

    if (unreadIds.isEmpty) {
      return;
    }

    _error = null;
    notifyListeners();

    try {
      await Future.wait(
        unreadIds.map(
          (notificationId) => _service.markNotificationAsRead(notificationId),
        ),
      );
      await refreshNotifications();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> submitComplaint({
    required String title,
    required String description,
    String? categoryId,
    int? ccOfficerId,
    List<int> ccOfficerIds = const [],
    bool anonymous = false,
    String? attachmentPath,
  }) async {
    _isSubmittingComplaint = true;
    _error = null;
    notifyListeners();

    try {
      await _service.submitComplaint(
        title: title,
        description: description,
        categoryId: categoryId,
        ccOfficerId: ccOfficerId,
        ccOfficerIds: ccOfficerIds,
        anonymous: anonymous,
        attachmentPath: attachmentPath,
      );
      await refreshComplaints();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSubmittingComplaint = false;
      notifyListeners();
    }
  }

  Future<bool> updateComplaint({
    required int complaintId,
    required String title,
    required String description,
    String? categoryId,
    int? ccOfficerId,
    List<int> ccOfficerIds = const [],
    bool anonymous = false,
    String? attachmentPath,
  }) async {
    _error = null;
    notifyListeners();

    try {
      await _service.updateComplaint(
        complaintId: complaintId,
        title: title,
        description: description,
        categoryId: categoryId,
        ccOfficerId: ccOfficerId,
        ccOfficerIds: ccOfficerIds,
        anonymous: anonymous,
        attachmentPath: attachmentPath,
      );
      await refreshComplaints();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteComplaint(int complaintId) async {
    _error = null;
    notifyListeners();

    try {
      await _service.deleteComplaint(complaintId);
      await refreshComplaints();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchComplaintThread({
    String? complaintRef,
    int? complaintId,
  }) {
    return _service.fetchComplaintThread(
      complaintRef: complaintRef,
      complaintId: complaintId,
    );
  }

  Future<List<Map<String, dynamic>>> fetchComplaintResponses({
    String? complaintRef,
    int? complaintId,
  }) {
    return _service.fetchComplaintResponses(
      complaintRef: complaintRef,
      complaintId: complaintId,
    );
  }

  Future<List<Map<String, dynamic>>> fetchComplaintComments(
    String complaintRef,
  ) {
    return _service.fetchComplaintComments(complaintRef);
  }

  Future<bool> addComplaintComment({
    required String complaintRef,
    required String message,
    int? rating,
  }) async {
    _error = null;
    notifyListeners();

    try {
      await _service.createComplaintComment(
        complaintRef: complaintRef,
        message: message,
        rating: rating,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addComplaintRating({
    required String complaintRef,
    required int rating,
    String feedback = '',
  }) async {
    _error = null;
    notifyListeners();

    try {
      await _service.addComplaintRating(
        complaintRef: complaintRef,
        rating: rating,
        feedback: feedback,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> requestAppointment({
    required String title,
    required String description,
    required DateTime scheduledFor,
  }) async {
    _isRequestingAppointment = true;
    _error = null;
    notifyListeners();

    try {
      await _service.requestAppointment(
        title: title,
        description: description,
        scheduledFor: scheduledFor,
      );
      await refreshAppointments();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isRequestingAppointment = false;
      notifyListeners();
    }
  }

  Future<bool> submitFeedback({required String message, int rating = 5}) async {
    _isSubmittingFeedback = true;
    _error = null;
    notifyListeners();

    try {
      await _service.submitFeedback(message: message, rating: rating);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSubmittingFeedback = false;
      notifyListeners();
    }
  }

  Future<bool> submitFeedbackTemplateResponse({
    required String templateId,
    required List<Map<String, dynamic>> answers,
  }) async {
    _isSubmittingFeedback = true;
    _error = null;
    notifyListeners();

    try {
      await _service.submitFeedbackTemplateResponse(
        templateId: templateId,
        answers: answers,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSubmittingFeedback = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
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
    _isUpdatingProfile = true;
    _error = null;
    notifyListeners();

    try {
      await _service.updateProfile(
        email: email,
        gmailAccount: gmailAccount,
        username: username,
        firstName: firstName,
        lastName: lastName,
        fullName: fullName,
        phone: phone,
        studentProfile: studentProfile,
        officerProfile: officerProfile,
        password: password,
        confirmPassword: confirmPassword,
      );
      _profile = await _service.fetchProfile();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isUpdatingProfile = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _isChangingPassword = true;
    _error = null;
    notifyListeners();

    try {
      await _service.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isChangingPassword = false;
      notifyListeners();
    }
  }
}

import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../data/models/student_models.dart';
import '../controllers/student_controller.dart';
import 'complaint_details_page.dart';
import 'helpdesk_tab_page.dart';

enum StudentDashboardTab {
  home,
  helpdesk,
  submit,
  myComplaints,
  appointments,
  feedback,
  notifications,
  announcements,
  profile,
}

enum _NotificationFilter { unread, all }

class StudentDashboardPage extends StatefulWidget {
  static const String routeHome = '/student';
  static const String routeHelpdesk = '/student/helpdesk';
  static const String routeSubmit = '/student/submit';
  static const String routeMyComplaints = '/student/my-complaints';
  static const String routeAppointments = '/student/appointments';
  static const String routeFeedback = '/student/feedback';
  static const String routeNotifications = '/student/notifications';
  static const String routeAnnouncements = '/student/announcements';
  static const String routeProfile = '/student/profile';

  final StudentDashboardTab initialTab;

  const StudentDashboardPage({
    super.key,
    this.initialTab = StudentDashboardTab.home,
  });

  static StudentDashboardTab tabFromRouteName(String? routeName) {
    switch (routeName) {
      case routeHelpdesk:
        return StudentDashboardTab.helpdesk;
      case routeSubmit:
        return StudentDashboardTab.submit;
      case routeMyComplaints:
        return StudentDashboardTab.myComplaints;
      case routeAppointments:
        return StudentDashboardTab.appointments;
      case routeFeedback:
        return StudentDashboardTab.feedback;
      case routeNotifications:
        return StudentDashboardTab.notifications;
      case routeAnnouncements:
        return StudentDashboardTab.announcements;
      case routeProfile:
        return StudentDashboardTab.profile;
      case routeHome:
      default:
        return StudentDashboardTab.home;
    }
  }

  static String routeForTab(StudentDashboardTab tab) {
    switch (tab) {
      case StudentDashboardTab.home:
        return routeHome;
      case StudentDashboardTab.helpdesk:
        return routeHelpdesk;
      case StudentDashboardTab.submit:
        return routeSubmit;
      case StudentDashboardTab.myComplaints:
        return routeMyComplaints;
      case StudentDashboardTab.appointments:
        return routeAppointments;
      case StudentDashboardTab.feedback:
        return routeFeedback;
      case StudentDashboardTab.notifications:
        return routeNotifications;
      case StudentDashboardTab.announcements:
        return routeAnnouncements;
      case StudentDashboardTab.profile:
        return routeProfile;
    }
  }

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  static const double _space1 = 8;
  static const double _space2 = 16;
  static const double _space3 = 24;
  static const double _maxContentWidth = 960;

  static const _NotificationFilter _defaultNotificationFilter =
      _NotificationFilter.unread;

  late final StudentController _studentController;

  int _currentTab = 0;
  bool _isSidebarCollapsed = false;
  _NotificationFilter _notificationFilter = _defaultNotificationFilter;

  final _complaintTitleController = TextEditingController();
  final _complaintDescriptionController = TextEditingController();
  final _complaintAttachmentController = TextEditingController();
  final _complaintFormKey = GlobalKey<FormState>();
  final _complaintTitleFocus = FocusNode();
  final _complaintDescriptionFocus = FocusNode();
  final _complaintAttachmentFocus = FocusNode();
  final _feedbackController = TextEditingController();

  String? _selectedCategoryId;
  List<int> _selectedCcOfficerIds = [];
  bool _anonymousComplaint = false;
  int _submitComplaintStep = 0;
  int _quickFeedbackRating = 5;

  FeedbackTemplateModel? _selectedFeedbackTemplate;
  final Map<String, dynamic> _feedbackAnswers = <String, dynamic>{};

  String _complaintStatusFilter = 'all';
  String _complaintCategoryFilter = 'all';

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab.index;
    _studentController = StudentController()..initialize();
  }

  @override
  void dispose() {
    _studentController.dispose();

    _complaintTitleController.dispose();
    _complaintDescriptionController.dispose();
    _complaintAttachmentController.dispose();
    _complaintTitleFocus.dispose();
    _complaintDescriptionFocus.dispose();
    _complaintAttachmentFocus.dispose();
    _feedbackController.dispose();

    super.dispose();
  }

  void _setTab(int index, {bool closeSidebar = false}) {
    setState(() => _currentTab = index);

    if (!closeSidebar) return;

    final scaffold = Scaffold.maybeOf(context);
    if (scaffold?.isDrawerOpen == true) {
      Navigator.of(context).pop();
    }
  }

  int _bottomNavIndexForTab(int tabIndex) {
    if (tabIndex == StudentDashboardTab.announcements.index) return 1;
    if (tabIndex == StudentDashboardTab.profile.index) return 2;
    return 0;
  }

  void _setBottomNavIndex(int index) {
    switch (index) {
      case 1:
        _setTab(StudentDashboardTab.announcements.index);
        return;
      case 2:
        _setTab(StudentDashboardTab.profile.index);
        return;
      case 0:
      default:
        _setTab(StudentDashboardTab.home.index);
    }
  }

  String _tabTitle(int index) {
    switch (index) {
      case 1:
        return 'Helpdesk';
      case 2:
        return 'Submit Complaint';
      case 3:
        return 'My Complaints';
      case 4:
        return 'Appointments';
      case 5:
        return 'Feedback';
      case 6:
        return 'Notifications';
      case 7:
        return 'Announcements';
      case 8:
        return 'Profile';
      case 0:
      default:
        return 'Student Dashboard';
    }
  }

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthController>().logout();
    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  int? _parseNullableInt(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return int.tryParse(trimmed);
  }

  List<ComplaintCategory> _uniqueCategories(
    List<ComplaintCategory> categories,
  ) {
    final map = <String, ComplaintCategory>{};
    for (final category in categories) {
      if (category.id.trim().isNotEmpty) {
        map.putIfAbsent(category.id, () => category);
      }
    }
    return map.values.toList(growable: false);
  }

  String _categoryLabel(ComplaintCategory category) {
    final scope = category.officeScope.trim();
    final parent = category.parentName.trim();
    final hierarchy = [
      category.campusName.trim(),
      category.collegeName.trim(),
      category.departmentName.trim(),
    ].where((value) => value.isNotEmpty).join(' / ');

    final suffixParts = <String>[
      if (scope.isNotEmpty) scope,
      if (hierarchy.isNotEmpty) hierarchy,
      if (parent.isNotEmpty) parent,
    ];

    if (suffixParts.isEmpty) {
      return category.name;
    }
    return '${category.name} [${suffixParts.join(' | ')}]';
  }

  List<CategoryResolverOption> _resolverOptionsForCategory(
    StudentController controller,
    String? categoryId,
  ) {
    if (categoryId == null || categoryId.trim().isEmpty) return const [];

    final options = controller.resolverOptions
        .where((option) => option.categoryId == categoryId && option.isActive)
        .toList(growable: false);
    options.sort((a, b) => a.levelId.compareTo(b.levelId));
    return options;
  }

  List<SelectableOfficer> _ccOfficersForCategory(
    StudentController controller,
    String? categoryId,
  ) {
    if (categoryId == null || categoryId.trim().isEmpty) {
      return const [];
    }

    final resolverOptions = controller.resolverOptions
        .where((option) => option.categoryId != categoryId && option.isActive)
        .toList(growable: false);

    if (resolverOptions.isEmpty) {
      final fallback = <int, SelectableOfficer>{};
      for (final officer in controller.officers) {
        if (officer.id > 0) {
          fallback.putIfAbsent(officer.id, () => officer);
        }
      }
      return fallback.values.toList(growable: false);
    }

    final byOfficerId = <int, SelectableOfficer>{};
    final fallbackById = <int, SelectableOfficer>{
      for (final officer in controller.officers) officer.id: officer,
    };

    for (final option in resolverOptions) {
      final fallback = fallbackById[option.officerId];
      byOfficerId[option.officerId] =
          fallback ??
          SelectableOfficer(
            id: option.officerId,
            name: option.officerName.isEmpty ? 'Officer' : option.officerName,
            email: '',
            role: 'officer',
            department: option.categoryName,
          );
    }

    return byOfficerId.values.toList(growable: false);
  }

  String _normalizeStatusValue(String value) {
    return value.toLowerCase().trim().replaceAll(' ', '_');
  }

  String _statusLabel(String value) {
    if (value == 'all') {
      return 'All status';
    }

    final cleaned = value.replaceAll('_', ' ').trim();
    if (cleaned.isEmpty) {
      return 'Unknown';
    }

    return cleaned
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  List<String> _complaintStatusOptions(List<StudentComplaint> complaints) {
    final canonical = <String>[
      'all',
      'pending',
      'in_progress',
      'resolved',
      'closed',
      'escalated',
      'approved',
      'completed',
      'rejected',
      'cancelled',
    ];

    final observed = complaints
        .map((complaint) => _normalizeStatusValue(complaint.status))
        .where((status) => status.isNotEmpty)
        .toSet();

    final options = <String>{...canonical, ...observed}.toList(growable: false);
    options.sort((left, right) {
      final leftIndex = canonical.indexOf(left);
      final rightIndex = canonical.indexOf(right);

      if (leftIndex != -1 || rightIndex != -1) {
        if (leftIndex == -1) return 1;
        if (rightIndex == -1) return -1;
        return leftIndex.compareTo(rightIndex);
      }

      return left.compareTo(right);
    });

    return options;
  }

  StudentComplaint? _complaintForNotification(
    StudentController controller,
    UserNotification notification,
  ) {
    final complaintId = notification.complaintId;
    if (complaintId != null && complaintId > 0) {
      for (final complaint in controller.complaints) {
        if (complaint.id == complaintId) {
          return complaint;
        }
      }
    }

    final complaintRef = notification.complaintRef?.trim();
    if (complaintRef != null && complaintRef.isNotEmpty) {
      for (final complaint in controller.complaints) {
        if (complaint.complaintRef == complaintRef) {
          return complaint;
        }
      }
    }

    return null;
  }

  StudentDashboardTab? _notificationTargetTab(UserNotification notification) {
    final target = (notification.targetType ?? notification.type)
        .toLowerCase()
        .trim();

    if (target.contains('complaint')) return StudentDashboardTab.myComplaints;
    if (target.contains('appointment')) return StudentDashboardTab.appointments;
    if (target.contains('feedback')) return StudentDashboardTab.feedback;
    if (target.contains('helpdesk')) return StudentDashboardTab.helpdesk;
    if (target.contains('announcement')) {
      return StudentDashboardTab.announcements;
    }
    if (target.contains('profile')) return StudentDashboardTab.profile;
    if (target.contains('home')) return StudentDashboardTab.home;
    return null;
  }

  String _notificationTypeLabel(UserNotification notification) {
    final raw = (notification.type).replaceAll('_', ' ').trim();
    if (raw.isEmpty) return 'Info';
    return raw[0].toUpperCase() + raw.substring(1);
  }

  Future<void> _openNotificationDestination(
    StudentController controller,
    UserNotification notification,
  ) async {
    if (!notification.isRead) {
      await controller.markNotificationAsRead(notification.id);
    }

    if (!mounted) return;

    final complaint = _complaintForNotification(controller, notification);
    if (complaint != null) {
      await _openComplaintDetailsPage(controller, complaint);
      return;
    }

    final targetTab = _notificationTargetTab(notification);
    if (targetTab != null) {
      setState(() => _currentTab = targetTab.index);
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _NotificationDetailPage(notification: notification),
      ),
    );
  }

  Widget _statusChip(String status) {
    final scheme = Theme.of(context).colorScheme;
    final normalized = status.toLowerCase();
    Color color;

    switch (normalized) {
      case 'resolved':
      case 'approved':
      case 'completed':
        color = scheme.tertiary;
        break;
      case 'rejected':
      case 'cancelled':
        color = scheme.error;
        break;
      case 'in_progress':
      case 'in progress':
        color = scheme.primary;
        break;
      case 'escalated':
        color = scheme.secondary;
        break;
      default:
        color = scheme.outline;
    }

    return Chip(
      label: Text(status),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.35)),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color color) {
    final cardColor = Theme.of(context).colorScheme.surfaceContainerHigh;
    return Container(
      padding: const EdgeInsets.all(_space2),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(label),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navigationPanel(
    StudentController controller, {
    bool compact = false,
    bool showCollapseToggle = false,
  }) {
    final unreadCount = controller.notifications.where((n) => !n.isRead).length;
    final user = context.watch<AuthController>().user;
    final profileName = controller.profile?.fullName.isNotEmpty == true
        ? controller.profile!.fullName
        : (user?.displayName ?? 'Student');
    final profileEmail = controller.profile?.email.isNotEmpty == true
        ? controller.profile!.email
        : (user?.email ?? '');

    final scheme = Theme.of(context).colorScheme;

    final entries = <_NavEntry>[
      const _NavEntry(
        tabIndex: 2,
        icon: Icons.edit_note_outlined,
        selectedIcon: Icons.edit_note,
        label: 'Submit Complaint',
        accent: Color(0xFF3B82F6),
      ),
      const _NavEntry(
        tabIndex: 3,
        icon: Icons.list_alt_outlined,
        selectedIcon: Icons.list_alt,
        label: 'My Complaints',
        accent: Color(0xFFF59E0B),
      ),
      const _NavEntry(
        tabIndex: 4,
        icon: Icons.event_note_outlined,
        selectedIcon: Icons.event_note,
        label: 'Appointments',
        accent: Color(0xFF6366F1),
      ),
      _NavEntry(
        tabIndex: 6,
        icon: Icons.notifications_outlined,
        selectedIcon: Icons.notifications,
        label: unreadCount > 0
            ? 'Notifications ($unreadCount)'
            : 'Notifications',
        accent: const Color(0xFFEF4444),
      ),
      const _NavEntry(
        tabIndex: 5,
        icon: Icons.fact_check_outlined,
        selectedIcon: Icons.fact_check,
        label: 'Feedback',
        accent: Color(0xFF8B5CF6),
      ),
      const _NavEntry(
        tabIndex: 1,
        icon: Icons.headset_mic_outlined,
        selectedIcon: Icons.headset_mic,
        label: 'Helpdesk',
        accent: Color(0xFF6B7280),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          right: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              compact ? 12 : _space3,
              20,
              compact ? 12 : _space3,
              compact ? 12 : _space3,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [scheme.primary, scheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (!compact)
                      const Expanded(child: SizedBox.shrink())
                    else
                      const Spacer(),
                    if (showCollapseToggle)
                      IconButton(
                        tooltip: compact
                            ? 'Show sidebar options'
                            : 'Hide sidebar options',
                        onPressed: () =>
                            setState(() => _isSidebarCollapsed = !compact),
                        icon: Icon(
                          compact
                              ? Icons.chevron_right_rounded
                              : Icons.chevron_left_rounded,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
                Container(
                  width: compact ? 44 : 56,
                  height: compact ? 44 : 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    color: Colors.white,
                    size: compact ? 24 : 30,
                  ),
                ),
                SizedBox(height: compact ? 10 : 16),
                if (!compact) ...[
                  Text(
                    profileName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profileEmail,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
                ] else ...[
                  const Text(
                    'CM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(
                vertical: 12,
                horizontal: compact ? 8 : 12,
              ),
              children: [
                for (final entry in entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _navigationTile(
                      entry: entry,
                      selected: _currentTab == entry.tabIndex,
                      compact: compact,
                      badgeCount: entry.tabIndex == 6 && unreadCount > 0
                          ? unreadCount
                          : null,
                      onTap: () => _setTab(entry.tabIndex, closeSidebar: true),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 8 : 12,
              0,
              compact ? 8 : 12,
              16,
            ),
            child: _navigationTile(
              entry: const _NavEntry(
                tabIndex: -1,
                icon: Icons.logout_outlined,
                selectedIcon: Icons.logout,
                label: 'Logout',
                accent: Color(0xFFDC2626),
              ),
              selected: false,
              compact: compact,
              destructive: true,
              onTap: () => _logout(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navigationTile({
    required _NavEntry entry,
    required bool selected,
    required VoidCallback onTap,
    bool compact = false,
    int? badgeCount,
    bool destructive = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = destructive
        ? scheme.error
        : selected
        ? scheme.primary
        : scheme.onSurfaceVariant;
    final background = selected
        ? scheme.primary.withValues(alpha: 0.12)
        : Colors.transparent;

    return Tooltip(
      message: entry.label,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 14,
              vertical: 14,
            ),
            child: Row(
              mainAxisAlignment: compact
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: (destructive ? scheme.error : entry.accent)
                            .withValues(alpha: selected ? 0.2 : 0.12),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        selected ? entry.selectedIcon : entry.icon,
                        color: foreground,
                        size: 20,
                      ),
                    ),
                    if (compact && badgeCount != null && badgeCount > 0)
                      Positioned(
                        top: -7,
                        right: -8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.error,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$badgeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (!compact) ...[
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      entry.label,
                      style: TextStyle(
                        color: foreground,
                        fontWeight: selected || destructive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (badgeCount != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.error,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _notificationAction(StudentController controller) {
    final unreadCount = controller.notifications.where((n) => !n.isRead).length;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Notifications',
          onPressed: () => _setTab(StudentDashboardTab.notifications.index),
          icon: const Icon(Icons.notifications_outlined),
        ),
        if (unreadCount > 0)
          Positioned(
            top: 4,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _pickComplaintAttachment() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
        withData: false,
      );

      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path?.trim() ?? '';
      if (path.isEmpty) {
        _showSnackBar('This picker returned no file path on this platform.');
        return;
      }

      if (!mounted) return;
      setState(() => _complaintAttachmentController.text = path);
    } catch (error) {
      _showSnackBar('Could not open file picker: $error');
    }
  }

  Future<void> _captureComplaintAttachment() async {
    try {
      final picker = ImagePicker();
      final captured = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 88,
      );

      if (captured == null) return;
      final path = captured.path.trim();
      if (path.isEmpty) {
        _showSnackBar('Camera did not return a valid file path.');
        return;
      }

      if (!mounted) return;
      setState(() => _complaintAttachmentController.text = path);
    } catch (error) {
      _showSnackBar('Could not open camera: $error');
    }
  }

  Future<void> _chooseComplaintAttachmentSource() async {
    if (!mounted) return;

    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.upload_file_outlined),
                title: const Text('Upload file'),
                onTap: () => Navigator.of(sheetContext).pop('file'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Use camera'),
                onTap: () => Navigator.of(sheetContext).pop('camera'),
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        );
      },
    );

    if (choice == 'file') {
      await _pickComplaintAttachment();
      return;
    }

    if (choice == 'camera') {
      await _captureComplaintAttachment();
    }
  }

  Future<void> _submitComplaint(StudentController controller) async {
    try {
      FocusScope.of(context).unfocus();
      if (!_validateComplaintDetails(redirectToDetailsStep: true)) {
        return;
      }

      final categories = _uniqueCategories(controller.categories);
      final title = _complaintTitleController.text.trim();
      final description = _complaintDescriptionController.text.trim();
      final attachmentPath = _complaintAttachmentController.text.trim();

      final selectedCategory = categories
          .where((category) => category.id == _selectedCategoryId)
          .cast<ComplaintCategory?>()
          .firstWhere((category) => category != null, orElse: () => null);

      if (selectedCategory == null) {
        _showSnackBar('Please select a category before submitting.');
        return;
      }

      if (selectedCategory.submitCategoryId.trim().isEmpty) {
        _showSnackBar(
          'This category is missing a backend category_id and cannot be submitted.',
        );
        return;
      }

      final success = await controller.submitComplaint(
        title: title,
        description: description,
        categoryId: selectedCategory.submitCategoryId,
        ccOfficerId: _selectedCcOfficerIds.isEmpty
            ? null
            : _selectedCcOfficerIds.first,
        ccOfficerIds: _selectedCcOfficerIds,
        anonymous: _anonymousComplaint,
        attachmentPath: attachmentPath.isEmpty ? null : attachmentPath,
      );

      if (!mounted) return;

      if (success) {
        _complaintTitleController.clear();
        _complaintDescriptionController.clear();
        _complaintAttachmentController.clear();
        setState(() {
          _selectedCategoryId = null;
          _selectedCcOfficerIds = [];
          _anonymousComplaint = false;
          _submitComplaintStep = 0;
        });
        _showSnackBar(
          'Complaint submitted successfully.',
          backgroundColor: Colors.green,
        );
        _setTab(2);
      } else {
        _showSnackBar(controller.error ?? 'Failed to submit complaint.');
      }
    } catch (error) {
      if (mounted) {
        _showSnackBar('Complaint submission failed: $error');
      }
    }
  }

  bool _validateComplaintDetails({bool redirectToDetailsStep = false}) {
    final title = _complaintTitleController.text.trim();
    final description = _complaintDescriptionController.text.trim();

    if (title.isEmpty) {
      _showSnackBar('Title is required.');
      if (redirectToDetailsStep) {
        setState(() => _submitComplaintStep = 1);
      }
      return false;
    }

    if (description.isEmpty) {
      _showSnackBar('Description is required.');
      if (redirectToDetailsStep) {
        setState(() => _submitComplaintStep = 1);
      }
      return false;
    }

    if (description.length < 10) {
      _showSnackBar('Please provide at least 10 characters in description.');
      if (redirectToDetailsStep) {
        setState(() => _submitComplaintStep = 1);
      }
      return false;
    }

    return true;
  }

  List<StudentComplaint> _filteredComplaints(StudentController controller) {
    return controller.complaints
        .where((complaint) {
          final matchesStatus =
              _complaintStatusFilter == 'all' ||
              _normalizeStatusValue(complaint.status) == _complaintStatusFilter;
          final matchesCategory =
              _complaintCategoryFilter == 'all' ||
              complaint.categoryId?.toString() == _complaintCategoryFilter;
          return matchesStatus && matchesCategory;
        })
        .toList(growable: false);
  }

  Future<void> _pickComplaintCategoryFilter(
    List<ComplaintCategory> categories,
  ) async {
    if (!mounted) return;

    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.84,
            child: Column(
              children: [
                ListTile(
                  title: const Text(
                    'Filter by category',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(sheetContext).pop(),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    children: [
                      ListTile(
                        leading: Icon(
                          _complaintCategoryFilter == 'all'
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                        ),
                        title: const Text('All categories'),
                        onTap: () => Navigator.of(sheetContext).pop('all'),
                      ),
                      ...categories.map(
                        (category) => ListTile(
                          leading: Icon(
                            _complaintCategoryFilter == category.id
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                          ),
                          title: Text(
                            _categoryLabel(category),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () =>
                              Navigator.of(sheetContext).pop(category.id),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null) return;
    setState(() => _complaintCategoryFilter = selected);
  }

  List<Map<String, dynamic>> _buildFeedbackAnswersPayload(
    FeedbackTemplateModel template,
  ) {
    final answers = <Map<String, dynamic>>[];

    for (final field in template.fields) {
      final answer = <String, dynamic>{'field_id': field.id};
      final value = _feedbackAnswers[field.id];

      switch (field.fieldType) {
        case 'number':
          answer['number_value'] = value is num
              ? value
              : num.tryParse('$value');
          answer['text_value'] = null;
          answer['rating_value'] = null;
          answer['choice_value'] = null;
          answer['checkbox_values'] = <String, bool>{};
          break;
        case 'rating':
          answer['rating_value'] = value is int
              ? value
              : int.tryParse('$value');
          answer['text_value'] = null;
          answer['number_value'] = null;
          answer['choice_value'] = null;
          answer['checkbox_values'] = <String, bool>{};
          break;
        case 'choice':
          answer['choice_value'] = (value ?? '').toString();
          answer['text_value'] = null;
          answer['number_value'] = null;
          answer['rating_value'] = null;
          answer['checkbox_values'] = <String, bool>{};
          break;
        case 'checkbox':
          final selected = value is List
              ? value.map((item) => '$item').where((item) => item.isNotEmpty)
              : const <String>[];
          answer['checkbox_values'] = {
            for (final option in selected) option: true,
          };
          answer['text_value'] = null;
          answer['number_value'] = null;
          answer['rating_value'] = null;
          answer['choice_value'] = null;
          break;
        case 'text':
        default:
          answer['text_value'] = (value ?? '').toString();
          answer['number_value'] = null;
          answer['rating_value'] = null;
          answer['choice_value'] = null;
          answer['checkbox_values'] = <String, bool>{};
      }

      answers.add(answer);
    }

    return answers;
  }

  Widget _feedbackFieldInput(
    FeedbackTemplateField field,
    dynamic value,
    void Function(dynamic value) onChanged,
  ) {
    switch (field.fieldType) {
      case 'number':
        return TextFormField(
          key: ValueKey('field_${field.id}_${value ?? ''}'),
          initialValue: value?.toString() ?? '',
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter number',
          ),
          onChanged: (text) => onChanged(num.tryParse(text)),
        );
      case 'rating':
        final current = value is int
            ? value.clamp(1, 5)
            : (int.tryParse('$value') ?? 1).clamp(1, 5);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rating: $current/5'),
            Slider(
              min: 1,
              max: 5,
              divisions: 4,
              value: current.toDouble(),
              label: '$current',
              onChanged: (next) => onChanged(next.round()),
            ),
          ],
        );
      case 'choice':
        final normalizedValue = field.options.contains(value)
            ? value as String
            : null;
        if (field.options.isEmpty) {
          return const Text(
            'No options configured for this field.',
            style: TextStyle(color: Colors.grey),
          );
        }
        return DropdownButtonFormField<String>(
          initialValue: normalizedValue,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: field.options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                ),
              )
              .toList(growable: false),
          onChanged: onChanged,
        );
      case 'checkbox':
        final selected = value is List
            ? value.map((item) => '$item').toSet()
            : <String>{};
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: field.options
              .map((option) {
                return FilterChip(
                  label: Text(option),
                  selected: selected.contains(option),
                  onSelected: (checked) {
                    final next = selected.toSet();
                    if (checked) {
                      next.add(option);
                    } else {
                      next.remove(option);
                    }
                    onChanged(next.toList(growable: false));
                  },
                );
              })
              .toList(growable: false),
        );
      case 'text':
      default:
        return TextFormField(
          key: ValueKey('field_${field.id}_${value ?? ''}'),
          initialValue: value?.toString() ?? '',
          maxLines: 4,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Type your response',
          ),
          onChanged: onChanged,
        );
    }
  }

  Widget _homeTab(StudentController controller) {
    final unreadCount = controller.notifications.where((n) => !n.isRead).length;
    final profileName = controller.profile?.fullName.isNotEmpty == true
        ? controller.profile!.fullName
        : (context.read<AuthController>().user?.displayName ?? 'Student');

    final scheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: controller.initialize,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(_space2),
        children: [
          Container(
            padding: const EdgeInsets.all(_space3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [scheme.primary, scheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.school_outlined, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, $profileName',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Submit complaints, track officer responses, and send structured feedback forms.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: _space2),
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  'Complaints',
                  controller.complaints.length.toString(),
                  Icons.report_outlined,
                  scheme.primary,
                ),
              ),
              const SizedBox(width: _space1),
              Expanded(
                child: _metricCard(
                  'Appointments',
                  controller.appointments.length.toString(),
                  Icons.event_note_outlined,
                  scheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: _space1),
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  'Alerts',
                  unreadCount.toString(),
                  Icons.notifications_outlined,
                  scheme.secondary,
                ),
              ),
              const SizedBox(width: _space1),
              Expanded(
                child: _metricCard(
                  'Feedback forms',
                  controller.feedbackTemplates
                      .where((t) => t.isActive)
                      .length
                      .toString(),
                  Icons.fact_check_outlined,
                  scheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: _space2),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(_space2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick access',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _quickAccessChip(
                        icon: Icons.edit_note_outlined,
                        label: 'Submit complaint',
                        tabIndex: 1,
                      ),
                      _quickAccessChip(
                        icon: Icons.list_alt_outlined,
                        label: 'My complaints',
                        tabIndex: 2,
                      ),
                      _quickAccessChip(
                        icon: Icons.event_note_outlined,
                        label: 'Appointments',
                        tabIndex: 3,
                      ),
                      _quickAccessChip(
                        icon: Icons.fact_check_outlined,
                        label: 'Feedback',
                        tabIndex: 4,
                      ),
                      _quickAccessChip(
                        icon: Icons.notifications_outlined,
                        label: 'Notifications',
                        tabIndex: 5,
                      ),
                      _quickAccessChip(
                        icon: Icons.person_outline,
                        label: 'Profile',
                        tabIndex: 7,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAccessChip({
    required IconData icon,
    required String label,
    required int tabIndex,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () => _setTab(tabIndex),
    );
  }

  Widget _submitComplaintTab(StudentController controller) {
    final categories = _uniqueCategories(controller.categories);
    final resolverOptions = _resolverOptionsForCategory(
      controller,
      _selectedCategoryId,
    );
    final ccOfficers = _ccOfficersForCategory(controller, _selectedCategoryId);

    final theme = Theme.of(context);
    final normalizedStep = _submitComplaintStep.clamp(0, 2);
    final canGoBack = normalizedStep > 0;
    final isLastStep = normalizedStep == 2;

    Future<void> handleNext() async {
      if (normalizedStep == 0) {
        if (categories.isEmpty) {
          _showSnackBar('No complaint categories are available right now.');
          return;
        }
        if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
          _showSnackBar('Please select a category before continuing.');
          return;
        }
        setState(() => _submitComplaintStep = 1);
        return;
      }

      if (normalizedStep == 1) {
        if (!_validateComplaintDetails()) {
          return;
        }
        setState(() => _submitComplaintStep = 2);
      }
    }

    void handleBack() {
      if (!canGoBack) return;
      setState(() => _submitComplaintStep = normalizedStep - 1);
    }

    Widget stepHeader() {
      final labels = const ['Category', 'Details', 'More Options'];

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Step ${normalizedStep + 1} of 3',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: List.generate(3, (index) {
                  final active = index == normalizedStep;
                  final completed = index < normalizedStep;
                  final color = completed || active
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant;

                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            labels[index],
                            style: TextStyle(
                              fontWeight: active
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: active
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      );
    }

    Widget stepOneCategory() {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose category',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              if (categories.isEmpty)
                const Text('No complaint categories are available right now.')
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 700;
                    final cardWidth = wide
                        ? (constraints.maxWidth - 10) / 2
                        : constraints.maxWidth;

                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: categories
                          .map((category) {
                            final selected = _selectedCategoryId == category.id;
                            final categoryTheme = Theme.of(context);

                            return SizedBox(
                              width: cardWidth,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    setState(() {
                                      _selectedCategoryId = category.id;
                                      _selectedCcOfficerIds = [];
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: selected
                                            ? categoryTheme.colorScheme.primary
                                            : categoryTheme
                                                  .colorScheme
                                                  .outlineVariant,
                                        width: selected ? 2 : 1,
                                      ),
                                      color: selected
                                          ? categoryTheme.colorScheme.primary
                                                .withValues(alpha: 0.08)
                                          : categoryTheme.colorScheme.surface,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          selected
                                              ? Icons.check_circle
                                              : Icons.radio_button_unchecked,
                                          color: selected
                                              ? categoryTheme
                                                    .colorScheme
                                                    .primary
                                              : categoryTheme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _categoryLabel(category),
                                            maxLines: wide ? 2 : 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: selected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          })
                          .toList(growable: false),
                    );
                  },
                ),
              const SizedBox(height: 12),
              const Text(
                'Responsible offices',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (_selectedCategoryId == null)
                const Text('Select a category to view resolver chain.')
              else if (resolverOptions.isEmpty)
                const Text('No resolver officers assigned yet.')
              else
                ...resolverOptions.map(
                  (option) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 110,
                          child: Text(
                            option.levelName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            option.officerName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    Widget stepTwoDetails() {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Form(
            key: _complaintFormKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complaint details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _complaintTitleController,
                  focusNode: _complaintTitleFocus,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) =>
                      _complaintDescriptionFocus.requestFocus(),
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title_outlined),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Title is required.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _complaintDescriptionController,
                  focusNode: _complaintDescriptionFocus,
                  maxLines: 6,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Description is required.';
                    }
                    if ((value ?? '').trim().length < 10) {
                      return 'Please provide at least 10 characters.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget stepThreeOptions() {
      return Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Anonymous complaint',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('No'),
                        selected: !_anonymousComplaint,
                        onSelected: (value) =>
                            setState(() => _anonymousComplaint = !value),
                      ),
                      ChoiceChip(
                        label: const Text('Yes'),
                        selected: _anonymousComplaint,
                        onSelected: (value) =>
                            setState(() => _anonymousComplaint = value),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Carbon copy officers',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select multiple officers if the complaint should reach more than one office.',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  if (ccOfficers.isEmpty)
                    const Text('No officers available for selected category.')
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 640;
                        final chipWidth = wide
                            ? (constraints.maxWidth - 16) / 2
                            : constraints.maxWidth;

                        final selectedCount = _selectedCcOfficerIds.length;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '$selectedCount selected',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedCcOfficerIds = ccOfficers
                                          .map((officer) => officer.id)
                                          .toList(growable: false);
                                    });
                                  },
                                  child: const Text('Select all'),
                                ),
                                TextButton(
                                  onPressed: _selectedCcOfficerIds.isEmpty
                                      ? null
                                      : () => setState(
                                          () => _selectedCcOfficerIds = [],
                                        ),
                                  child: const Text('Clear'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: ccOfficers
                                  .map((officer) {
                                    final selected = _selectedCcOfficerIds
                                        .contains(officer.id);
                                    return SizedBox(
                                      width: chipWidth.clamp(150, 260),
                                      child: FilterChip(
                                        tooltip:
                                            '${officer.name}${officer.department.isNotEmpty ? ' • ${officer.department}' : ''}',
                                        label: Text(
                                          officer.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        selected: selected,
                                        onSelected: (checked) {
                                          setState(() {
                                            if (checked) {
                                              _selectedCcOfficerIds = {
                                                ..._selectedCcOfficerIds,
                                                officer.id,
                                              }.toList(growable: false);
                                            } else {
                                              _selectedCcOfficerIds =
                                                  _selectedCcOfficerIds
                                                      .where(
                                                        (id) =>
                                                            id != officer.id,
                                                      )
                                                      .toList(growable: false);
                                            }
                                          });
                                        },
                                      ),
                                    );
                                  })
                                  .toList(growable: false),
                            ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Attachment (optional)',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _complaintAttachmentController,
                    focusNode: _complaintAttachmentFocus,
                    readOnly: true,
                    onTap: _chooseComplaintAttachmentSource,
                    decoration: InputDecoration(
                      labelText: 'Selected file',
                      helperText: 'Choose Upload file or Use camera',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.attach_file),
                      suffixIcon: IconButton(
                        tooltip: 'Attachment options',
                        onPressed: _chooseComplaintAttachmentSource,
                        icon: const Icon(Icons.more_horiz),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickComplaintAttachment,
                        icon: const Icon(Icons.upload_file_outlined),
                        label: const Text('Upload file'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _captureComplaintAttachment,
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: const Text('Use camera'),
                      ),
                      if (_complaintAttachmentController.text.trim().isNotEmpty)
                        TextButton.icon(
                          onPressed: () =>
                              setState(_complaintAttachmentController.clear),
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final steps = [stepOneCategory(), stepTwoDetails(), stepThreeOptions()];

    return RefreshIndicator(
      onRefresh: controller.initialize,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(_space2),
        children: [
          Text(
            'Submit Complaint',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: _space2),
          stepHeader(),
          const SizedBox(height: 12),
          steps[normalizedStep],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: canGoBack ? handleBack : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: controller.isSubmittingComplaint
                      ? null
                      : isLastStep
                      ? () => _submitComplaint(controller)
                      : handleNext,
                  icon: controller.isSubmittingComplaint
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(isLastStep ? Icons.send : Icons.arrow_forward),
                  label: Text(isLastStep ? 'Submit Complaint' : 'Next'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _myComplaintsTab(StudentController controller) {
    final allComplaints = controller.complaints;
    final complaints = _filteredComplaints(controller);

    final total = allComplaints.length;
    final pending = allComplaints
        .where((c) => c.status.toLowerCase() == 'pending')
        .length;
    final inProgress = allComplaints
        .where((c) => c.status.toLowerCase() == 'in_progress')
        .length;
    final resolved = allComplaints
        .where((c) => c.status.toLowerCase() == 'resolved')
        .length;

    final categories = _uniqueCategories(controller.categories);
    final statusOptions = _complaintStatusOptions(allComplaints);

    return RefreshIndicator(
      onRefresh: controller.refreshComplaints,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  'Total',
                  '$total',
                  Icons.list_alt_outlined,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricCard(
                  'Pending',
                  '$pending',
                  Icons.hourglass_bottom,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  'In progress',
                  '$inProgress',
                  Icons.timelapse,
                  Colors.indigo,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricCard(
                  'Resolved',
                  '$resolved',
                  Icons.check_circle_outline,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _complaintStatusFilter,
                    decoration: const InputDecoration(
                      labelText: 'Filter by status',
                      border: OutlineInputBorder(),
                    ),
                    items: statusOptions
                        .map(
                          (status) => DropdownMenuItem<String>(
                            value: status,
                            child: Text(_statusLabel(status)),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _complaintStatusFilter = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => _pickComplaintCategoryFilter(categories),
                    icon: const Icon(Icons.filter_alt_outlined),
                    label: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _complaintCategoryFilter == 'all'
                            ? 'Category: All categories'
                            : 'Category: ${categories.where((category) => category.id == _complaintCategoryFilter).map(_categoryLabel).cast<String?>().firstWhere((label) => label != null, orElse: () => 'Selected category')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (complaints.isEmpty)
            const _EmptyStateCard(
              icon: Icons.inbox_outlined,
              title: 'No complaints found',
              description: 'Try changing status or category filters.',
            )
          else
            ...complaints.map((complaint) {
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  complaint.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  complaint.categoryName,
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        complaint.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _statusChip(complaint.status),
                          if (complaint.isAnonymous)
                            const Chip(label: Text('Anonymous')),
                          if (complaint.assignedOfficerName.isNotEmpty)
                            Chip(
                              label: Text(
                                'CC: ${complaint.assignedOfficerName}',
                              ),
                            ),
                          if (complaint.attachmentName.isNotEmpty)
                            Chip(label: Text(complaint.attachmentName)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: () => _openComplaintDetailsPage(
                              controller,
                              complaint,
                            ),
                            icon: const Icon(Icons.forum_outlined),
                            label: const Text('Details'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () =>
                                _deleteComplaint(controller, complaint),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Delete'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _deleteComplaint(
    StudentController controller,
    StudentComplaint complaint,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete complaint'),
        content: Text('Delete "${complaint.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await controller.deleteComplaint(complaint.id);
    if (!mounted) return;

    _showSnackBar(
      success
          ? 'Complaint deleted.'
          : controller.error ?? 'Unable to delete complaint.',
      backgroundColor: success ? Colors.green : Colors.red,
    );
  }

  Future<void> _openComplaintDetailsPage(
    StudentController controller,
    StudentComplaint complaint,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ComplaintDetailsPage(controller: controller, complaint: complaint),
      ),
    );

    if (!mounted) return;
    await controller.refreshComplaints();
  }

  Widget _appointmentsTab(StudentController controller) {
    return RefreshIndicator(
      onRefresh: controller.refreshAppointments,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const Text(
            'Officer schedules',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (controller.appointments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text('No schedules have been set yet.'),
            )
          else
            ...controller.appointments.map(
              (appointment) => Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.event_available_outlined),
                  ),
                  title: Text(appointment.title),
                  subtitle: Text(
                    [
                      appointment.description,
                      appointment.scheduledFor,
                      appointment.officerName.isEmpty
                          ? ''
                          : 'Officer: ${appointment.officerName}',
                      appointment.location,
                    ].where((part) => part.trim().isNotEmpty).join('\n'),
                  ),
                  isThreeLine: true,
                  trailing: _statusChip(appointment.status),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _feedbackTab(StudentController controller) {
    final templates =
        controller.feedbackTemplates
            .where((template) => template.isActive)
            .toList(growable: false)
          ..sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
          );

    return RefreshIndicator(
      onRefresh: controller.refreshFeedbackTemplates,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (_selectedFeedbackTemplate == null) ...[
            const Text(
              'Available Feedback Forms',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Select a backend form to submit structured feedback.'),
            const SizedBox(height: 12),
            if (templates.isEmpty)
              const _EmptyStateCard(
                icon: Icons.fact_check_outlined,
                title: 'No active forms',
                description: 'New feedback templates will appear here.',
              )
            else
              ...templates.map((template) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (template.description.trim().isNotEmpty)
                          Text(template.description),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(label: Text('Office: ${template.office}')),
                            Chip(
                              label: Text('Fields: ${template.fields.length}'),
                            ),
                            Chip(label: Text('Priority: ${template.priority}')),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            onPressed: () {
                              setState(() {
                                _selectedFeedbackTemplate = template;
                                _feedbackAnswers.clear();
                              });
                            },
                            child: const Text('Fill form'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick feedback',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _feedbackController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Share quick feedback',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Rating: $_quickFeedbackRating/5'),
                        ),
                        Expanded(
                          flex: 2,
                          child: Slider(
                            min: 1,
                            max: 5,
                            divisions: 4,
                            value: _quickFeedbackRating.toDouble(),
                            label: '$_quickFeedbackRating',
                            onChanged: (value) {
                              setState(
                                () => _quickFeedbackRating = value.round(),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    FilledButton.icon(
                      onPressed: controller.isSubmittingFeedback
                          ? null
                          : () async {
                              final message = _feedbackController.text.trim();
                              if (message.isEmpty) {
                                _showSnackBar('Please write your feedback.');
                                return;
                              }

                              final success = await controller.submitFeedback(
                                message: message,
                                rating: _quickFeedbackRating,
                              );

                              if (!mounted) return;
                              if (success) {
                                _feedbackController.clear();
                                setState(() => _quickFeedbackRating = 5);
                                _showSnackBar(
                                  'Feedback submitted. Thank you!',
                                  backgroundColor: Colors.green,
                                );
                              } else {
                                _showSnackBar(
                                  controller.error ??
                                      'Failed to submit feedback.',
                                );
                              }
                            },
                      icon: controller.isSubmittingFeedback
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_outlined),
                      label: const Text('Send quick feedback'),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedFeedbackTemplate = null;
                      _feedbackAnswers.clear();
                    });
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to forms'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedFeedbackTemplate!.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    if (_selectedFeedbackTemplate!.description
                        .trim()
                        .isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(_selectedFeedbackTemplate!.description),
                    ],
                    const SizedBox(height: 8),
                    Text('Office: ${_selectedFeedbackTemplate!.office}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            ...(() {
              final fields = _selectedFeedbackTemplate!.fields.toList(
                growable: false,
              )..sort((a, b) => a.order.compareTo(b.order));
              return fields
                  .map((field) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${field.label}${field.isRequired ? ' *' : ''}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _feedbackFieldInput(
                              field,
                              _feedbackAnswers[field.id],
                              (value) => setState(
                                () => _feedbackAnswers[field.id] = value,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  })
                  .toList(growable: false);
            })(),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: controller.isSubmittingFeedback
                  ? null
                  : () async {
                      final template = _selectedFeedbackTemplate;
                      if (template == null) return;

                      final missingRequired = template.fields
                          .where((field) {
                            if (!field.isRequired) return false;
                            final value = _feedbackAnswers[field.id];
                            if (value == null) return true;
                            if (value is String) return value.trim().isEmpty;
                            if (value is List) return value.isEmpty;
                            return false;
                          })
                          .toList(growable: false);

                      if (missingRequired.isNotEmpty) {
                        _showSnackBar('Please complete required fields.');
                        return;
                      }

                      final success = await controller
                          .submitFeedbackTemplateResponse(
                            templateId: template.id,
                            answers: _buildFeedbackAnswersPayload(template),
                          );

                      if (!mounted) return;

                      if (success) {
                        setState(() {
                          _selectedFeedbackTemplate = null;
                          _feedbackAnswers.clear();
                        });
                        _showSnackBar(
                          'Feedback submitted successfully.',
                          backgroundColor: Colors.green,
                        );
                        await controller.refreshFeedbackTemplates();
                      } else {
                        _showSnackBar(
                          controller.error ?? 'Failed to submit feedback form.',
                        );
                      }
                    },
              icon: controller.isSubmittingFeedback
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.assignment_turned_in_outlined),
              label: const Text('Submit feedback form'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _notificationsTab(StudentController controller) {
    final notifications = controller.notifications;
    final unreadNotifications = notifications
        .where((notification) => !notification.isRead)
        .toList(growable: false);
    final filteredNotifications =
        _notificationFilter == _NotificationFilter.unread
        ? unreadNotifications
        : notifications;

    return RefreshIndicator(
      onRefresh: controller.refreshNotifications,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 500;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          'Notifications',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: unreadNotifications.isEmpty
                            ? null
                            : controller.markAllNotificationsAsRead,
                        icon: const Icon(Icons.done_all_outlined),
                        label: const Text('Mark all read'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${unreadNotifications.length} unread',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Unread'),
                        selected:
                            _notificationFilter == _NotificationFilter.unread,
                        onSelected: (_) {
                          setState(
                            () => _notificationFilter =
                                _NotificationFilter.unread,
                          );
                        },
                      ),
                      ChoiceChip(
                        label: const Text('All'),
                        selected:
                            _notificationFilter == _NotificationFilter.all,
                        onSelected: (_) {
                          setState(
                            () => _notificationFilter = _NotificationFilter.all,
                          );
                        },
                      ),
                    ],
                  ),
                  if (!isNarrow) const SizedBox(height: 4),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          if (filteredNotifications.isEmpty)
            const _EmptyStateCard(
              icon: Icons.notifications_off_outlined,
              title: 'No notifications',
              description: 'You are all caught up.',
            )
          else
            ...filteredNotifications.map(
              (notification) => Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () =>
                      _openNotificationDestination(controller, notification),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 420;
                      return Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: isCompact ? 18 : 20,
                              backgroundColor: notification.isRead
                                  ? Colors.grey.shade300
                                  : Colors.blue.withValues(alpha: 0.15),
                              child: Icon(
                                notification.isRead
                                    ? Icons.done_all_outlined
                                    : Icons.notifications_active_outlined,
                                color: notification.isRead
                                    ? Colors.grey
                                    : Colors.blue,
                                size: isCompact ? 18 : 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          notification.title,
                                          maxLines: isCompact ? 2 : 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: notification.isRead
                                                ? FontWeight.w600
                                                : FontWeight.w800,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      if (!notification.isRead)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            left: 8,
                                          ),
                                          width: 10,
                                          height: 10,
                                          decoration: const BoxDecoration(
                                            color: Colors.blue,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    notification.message,
                                    maxLines: isCompact ? 3 : 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.grey.shade800,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Chip(
                                        label: Text(
                                          _notificationTypeLabel(notification),
                                        ),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      if (notification.createdAt.isNotEmpty)
                                        Text(
                                          notification.createdAt,
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _announcementsTab(StudentController controller) {
    final announcements = controller.announcements;
    final isAuthenticated = context.watch<AuthController>().user != null;

    Future<void> handleLike(PublicAnnouncement announcement) async {
      if (!isAuthenticated) {
        _showSnackBar('Please log in to like announcements.');
        return;
      }

      final success = await controller.likeAnnouncement(announcement.id);
      if (!mounted) return;
      if (!success) {
        _showSnackBar(controller.error ?? 'Unable to like announcement.');
      }
    }

    Future<void> handleComment(PublicAnnouncement announcement) async {
      if (!isAuthenticated) {
        _showSnackBar('Please log in to comment on announcements.');
        return;
      }

      final commentController = TextEditingController();
      final submitted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Comment on announcement'),
            content: TextField(
              controller: commentController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Write your comment',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (commentController.text.trim().isEmpty) return;
                  Navigator.of(dialogContext).pop(true);
                },
                child: const Text('Send'),
              ),
            ],
          );
        },
      );

      if (submitted != true) {
        commentController.dispose();
        return;
      }

      final success = await controller.commentAnnouncement(
        announcementId: announcement.id,
        message: commentController.text.trim(),
      );
      commentController.dispose();

      if (!mounted) return;
      if (success) {
        _showSnackBar('Comment posted.', backgroundColor: Colors.green);
      } else {
        _showSnackBar(controller.error ?? 'Unable to comment.');
      }
    }

    return RefreshIndicator(
      onRefresh: controller.refreshAnnouncements,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Announcements',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (announcements.isEmpty)
            const _EmptyStateCard(
              icon: Icons.campaign_outlined,
              title: 'No announcements',
              description: 'Check again later for updates.',
            )
          else
            ...announcements.map(
              (announcement) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              announcement.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (announcement.isPinned)
                            const Chip(label: Text('Pinned')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(announcement.message),
                      const SizedBox(height: 10),
                      Text(
                        'By ${announcement.createdByName}',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => handleLike(announcement),
                            icon: Icon(
                              announcement.likedByUser
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                            ),
                            label: Text('Like (${announcement.likesCount})'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => handleComment(announcement),
                            icon: const Icon(Icons.comment_outlined),
                            label: Text(
                              'Comment (${announcement.commentsCount})',
                            ),
                          ),
                        ],
                      ),
                      if (!isAuthenticated)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Public read access enabled. Login is required to like or comment.',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showEditProfileDialog(StudentController controller) async {
    final authUser = context.read<AuthController>().user;
    final profile = controller.profile;

    final fullNameController = TextEditingController(
      text: profile?.fullName.isNotEmpty == true
          ? profile!.fullName
          : (authUser?.fullName ?? ''),
    );
    final firstNameController = TextEditingController(
      text: profile?.firstName.isNotEmpty == true
          ? profile!.firstName
          : (authUser?.firstName ?? ''),
    );
    final lastNameController = TextEditingController(
      text: profile?.lastName.isNotEmpty == true
          ? profile!.lastName
          : (authUser?.lastName ?? ''),
    );
    final usernameController = TextEditingController(
      text: profile?.username.isNotEmpty == true
          ? profile!.username
          : (authUser?.username ?? ''),
    );
    final emailController = TextEditingController(
      text: profile?.email.isNotEmpty == true
          ? profile!.email
          : (authUser?.email ?? ''),
    );
    final gmailController = TextEditingController(
      text: profile?.gmailAccount.isNotEmpty == true
          ? profile!.gmailAccount
          : (authUser?.gmailAccount ?? authUser?.email ?? ''),
    );
    final phoneController = TextEditingController(
      text: profile?.phone.isNotEmpty == true
          ? profile!.phone
          : (authUser?.phone ?? ''),
    );
    final studentIdController = TextEditingController(
      text: profile?.studentId ?? '',
    );
    final campusIdController = TextEditingController(
      text: profile?.campusId ?? '',
    );
    final yearOfStudyController = TextEditingController(
      text: profile?.yearOfStudy?.toString() ?? '',
    );

    bool isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Edit profile'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: fullNameController,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'First name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Last name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: gmailController,
                        decoration: const InputDecoration(
                          labelText: 'Gmail account',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: studentIdController,
                        decoration: const InputDecoration(
                          labelText: 'Student ID',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: campusIdController,
                        decoration: const InputDecoration(
                          labelText: 'Campus ID',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: yearOfStudyController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Year of study',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final authController = context.read<AuthController>();
                          final studentProfilePayload = <String, dynamic>{
                            if (profile?.studentTypeId != null)
                              'student_type': profile!.studentTypeId,
                            if (profile?.departmentId != null)
                              'department': profile!.departmentId,
                            if (profile?.programId != null)
                              'program': profile!.programId,
                            'student_id': studentIdController.text.trim(),
                            'campus_id': campusIdController.text.trim(),
                            if (_parseNullableInt(yearOfStudyController.text) !=
                                null)
                              'year_of_study': _parseNullableInt(
                                yearOfStudyController.text,
                              ),
                          };
                          setLocalState(() => isSaving = true);
                          final success = await controller.updateProfile(
                            fullName: fullNameController.text.trim(),
                            firstName: firstNameController.text.trim(),
                            lastName: lastNameController.text.trim(),
                            username: usernameController.text.trim(),
                            email: emailController.text.trim(),
                            gmailAccount: gmailController.text.trim(),
                            phone: phoneController.text.trim(),
                            studentProfile: studentProfilePayload,
                          );
                          if (!mounted) return;

                          if (success) {
                            await authController.bootstrap();
                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext);
                            _showSnackBar(
                              'Profile updated successfully.',
                              backgroundColor: Colors.green,
                            );
                          } else {
                            setLocalState(() => isSaving = false);
                            _showSnackBar(
                              controller.error ?? 'Failed to update profile.',
                            );
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    fullNameController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    gmailController.dispose();
    phoneController.dispose();
    studentIdController.dispose();
    campusIdController.dispose();
    yearOfStudyController.dispose();
  }

  Future<void> _showChangePasswordDialog(StudentController controller) async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    bool isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Change password'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: currentController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Current password',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: newController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'New password',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: confirmController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirm password',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final currentPassword = currentController.text.trim();
                          final newPassword = newController.text.trim();
                          final confirmPassword = confirmController.text.trim();

                          if (currentPassword.isEmpty ||
                              newPassword.isEmpty ||
                              confirmPassword.isEmpty) {
                            _showSnackBar('Please fill all password fields.');
                            return;
                          }

                          if (newPassword != confirmPassword) {
                            _showSnackBar(
                              'New password and confirmation do not match.',
                            );
                            return;
                          }

                          setLocalState(() => isSaving = true);
                          final success = await controller.changePassword(
                            currentPassword: currentPassword,
                            newPassword: newPassword,
                            confirmPassword: confirmPassword,
                          );
                          if (!mounted) return;

                          if (success) {
                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext);
                            _showSnackBar(
                              'Password changed successfully.',
                              backgroundColor: Colors.green,
                            );
                          } else {
                            setLocalState(() => isSaving = false);
                            _showSnackBar(
                              controller.error ?? 'Failed to change password.',
                            );
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );

    currentController.dispose();
    newController.dispose();
    confirmController.dispose();
  }

  Widget _profileTab(StudentController controller) {
    final authUser = context.watch<AuthController>().user;
    final profile = controller.profile;

    final rows = <_ProfileRow>[
      _ProfileRow('User ID', '${profile?.id ?? authUser?.id ?? '-'}'),
      _ProfileRow(
        'Full name',
        profile?.fullName.isNotEmpty == true
            ? profile!.fullName
            : (authUser?.fullName ?? '-'),
      ),
      _ProfileRow(
        'Email',
        profile?.email.isNotEmpty == true
            ? profile!.email
            : (authUser?.email ?? '-'),
      ),
      _ProfileRow(
        'Gmail account',
        profile?.gmailAccount.isNotEmpty == true
            ? profile!.gmailAccount
            : (authUser?.gmailAccount.isNotEmpty == true
                  ? authUser!.gmailAccount
                  : '-'),
      ),
      _ProfileRow('Username', authUser?.username ?? '-'),
      _ProfileRow(
        'Phone',
        profile?.phone.isNotEmpty == true
            ? profile!.phone
            : (authUser?.phone.isNotEmpty == true ? authUser!.phone : '-'),
      ),
      _ProfileRow(
        'Student ID',
        profile?.studentId.isNotEmpty == true ? profile!.studentId : '-',
      ),
      _ProfileRow(
        'Campus ID',
        profile?.campusId.isNotEmpty == true ? profile!.campusId : '-',
      ),
      _ProfileRow(
        'Year of study',
        profile?.yearOfStudy != null ? '${profile!.yearOfStudy}' : '-',
      ),
      _ProfileRow(
        'Role',
        profile?.role.isNotEmpty == true
            ? profile!.role
            : (authUser?.role ?? '-'),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Profile',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(
                    profile?.fullName.isNotEmpty == true
                        ? profile!.fullName
                        : (authUser?.displayName ?? 'Student'),
                  ),
                  subtitle: Text(
                    profile?.email.isNotEmpty == true
                        ? profile!.email
                        : (authUser?.email ?? ''),
                  ),
                ),
                const Divider(),
                ...rows.map(
                  (row) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            row.label,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Expanded(child: Text(row.value)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: controller.isUpdatingProfile
                  ? null
                  : () => _showEditProfileDialog(controller),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit profile'),
            ),
            OutlinedButton.icon(
              onPressed: controller.isChangingPassword
                  ? null
                  : () => _showChangePasswordDialog(controller),
              icon: const Icon(Icons.lock_reset_outlined),
              label: const Text('Change password'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _studentController,
      child: Consumer<StudentController>(
        builder: (context, controller, _) {
          final isWide = MediaQuery.sizeOf(context).width >= 1000;
          final pages = [
            _homeTab(controller),
            const HelpdeskTabPage(),
            _submitComplaintTab(controller),
            _myComplaintsTab(controller),
            _appointmentsTab(controller),
            _feedbackTab(controller),
            _notificationsTab(controller),
            _announcementsTab(controller),
            _profileTab(controller),
          ];

          final selectedIndex = _currentTab.clamp(0, pages.length - 1).toInt();

          return Scaffold(
            drawer: isWide
                ? null
                : Drawer(child: SafeArea(child: _navigationPanel(controller))),
            appBar: AppBar(
              title: Text(_tabTitle(selectedIndex)),
              actions: [
                _notificationAction(controller),
                IconButton(
                  onPressed: controller.isLoading
                      ? null
                      : controller.initialize,
                  icon: const Icon(Icons.refresh),
                ),
                IconButton(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout),
                ),
              ],
            ),
            body: controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : SafeArea(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 1000;

                        final content = Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: _maxContentWidth,
                            ),
                            child: Column(
                              children: [
                                if (controller.error != null)
                                  MaterialBanner(
                                    content: Text(controller.error!),
                                    actions: [
                                      TextButton(
                                        onPressed: controller.initialize,
                                        child: const Text('Retry'),
                                      ),
                                    ],
                                  ),
                                Expanded(
                                  child: IndexedStack(
                                    index: selectedIndex,
                                    children: pages,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );

                        if (!isWide) {
                          return content;
                        }

                        return Row(
                          children: [
                            SizedBox(
                              width: _isSidebarCollapsed ? 88 : 320,
                              child: _navigationPanel(
                                controller,
                                compact: _isSidebarCollapsed,
                                showCollapseToggle: true,
                              ),
                            ),
                            Expanded(child: content),
                          ],
                        );
                      },
                    ),
                  ),
            bottomNavigationBar: isWide
                ? null
                : NavigationBar(
                    selectedIndex: _bottomNavIndexForTab(selectedIndex),
                    onDestinationSelected: _setBottomNavIndex,
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.home_outlined),
                        selectedIcon: Icon(Icons.home),
                        label: 'Home',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.campaign_outlined),
                        selectedIcon: Icon(Icons.campaign),
                        label: 'Announcements',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.person_outline),
                        selectedIcon: Icon(Icons.person),
                        label: 'Profile',
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _NavEntry {
  final int tabIndex;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Color accent;

  const _NavEntry({
    required this.tabIndex,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.accent,
  });
}

class _ProfileRow {
  final String label;
  final String value;

  const _ProfileRow(this.label, this.value);
}

class _EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: scheme.primaryContainer,
              child: Icon(icon, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(description, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationDetailPage extends StatelessWidget {
  final UserNotification notification;

  const _NotificationDetailPage({required this.notification});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Notification')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Chip(
                          label: Text(notification.type),
                          backgroundColor: scheme.primaryContainer.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          notification.title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        Text(notification.message),
                        if (notification.createdAt.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Created at ${notification.createdAt}',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                        const SizedBox(height: 20),
                        const Text(
                          'This notification does not include a specific destination, so it is shown here as a detail view.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

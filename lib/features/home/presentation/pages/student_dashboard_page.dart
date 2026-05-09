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
import 'helpdesk_sessions_page.dart';

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

class _StudentDashboardPageState extends State<StudentDashboardPage>
    with TickerProviderStateMixin {
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
  final _complaintFormKey = GlobalKey<FormState>();
  final _complaintTitleFocus = FocusNode();
  final _complaintDescriptionFocus = FocusNode();

  String? _selectedCategoryId;
  List<int> _selectedCcOfficerIds = [];
  bool _anonymousComplaint = false;
  int _submitComplaintStep = 0;
  String _categorySearchText = '';
  bool _categoryRegexEnabled = false;
  String _ccOfficerSearchText = '';
  bool _ccRegexEnabled = false;
  List<PlatformFile> _complaintAttachments = [];
  Map<String, String> _resolverFilters = {
    'campus': '',
    'college': '',
    'department': '',
  };
  List<String> _selectedResolverIds = [];

  FeedbackTemplateModel? _selectedFeedbackTemplate;
  final Map<String, dynamic> _feedbackAnswers = <String, dynamic>{};

  String _complaintStatusFilter = 'all';
  String _complaintCategoryFilter = 'all';

  late final PageController _pageController;
  late final AnimationController _fadeAnimationController;
  late final AnimationController _stepHeaderAnimationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _stepHeaderAnimation;

  // Appointment request state
  bool _isRequestingAppointment = false;
  int _appointmentRequestStep = 0;
  AppointmentAvailabilityItem? _selectedAppointmentSlot;
  String _selectedIssueType = 'other';
  final TextEditingController _appointmentDescriptionController =
      TextEditingController();
  // final TextEditingController _appointmentLocationController =
  //     TextEditingController();
  final TextEditingController _appointmentNoteController =
      TextEditingController();
  final TextEditingController _appointmentPreferredDateController =
      TextEditingController();
  final GlobalKey<FormState> _appointmentFormKey = GlobalKey<FormState>();

  late final PageController _appointmentPageController;
  late final AnimationController _appointmentFadeAnimationController;
  late final AnimationController _appointmentStepHeaderAnimationController;
  late final Animation<double> _appointmentFadeAnimation;
  late final Animation<double> _appointmentStepHeaderAnimation;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab.index;
    _studentController = StudentController()..initialize();

    _pageController = PageController();
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _stepHeaderAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _stepHeaderAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _stepHeaderAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _appointmentPageController = PageController();
    _appointmentFadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _appointmentStepHeaderAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _appointmentFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _appointmentFadeAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _appointmentStepHeaderAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(
          CurvedAnimation(
            parent: _appointmentStepHeaderAnimationController,
            curve: Curves.easeOut,
          ),
        );

    _fadeAnimationController.forward();
    _stepHeaderAnimationController.forward();
    _appointmentFadeAnimationController.forward();
    _appointmentStepHeaderAnimationController.forward();
  }

  @override
  void dispose() {
    _studentController.dispose();

    _complaintTitleController.dispose();
    _complaintDescriptionController.dispose();
    _complaintTitleFocus.dispose();
    _complaintDescriptionFocus.dispose();

    _appointmentDescriptionController.dispose();
    // _appointmentLocationController.dispose();
    _appointmentNoteController.dispose();
    _appointmentPreferredDateController.dispose();

    _pageController.dispose();
    _fadeAnimationController.dispose();
    _stepHeaderAnimationController.dispose();
    _appointmentPageController.dispose();
    _appointmentFadeAnimationController.dispose();
    _appointmentStepHeaderAnimationController.dispose();

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

  bool _canDeleteComplaint(StudentComplaint complaint) {
    final status = _normalizeStatusValue(complaint.status);
    return status == 'pending' || status == 'draft';
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

  bool _matchesSearch(String text, String query, bool useRegex) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return true;
    if (!useRegex) {
      return text.toLowerCase().contains(trimmed.toLowerCase());
    }

    try {
      final regex = RegExp(trimmed, caseSensitive: false);
      return regex.hasMatch(text);
    } catch (_) {
      return false;
    }
  }

  String? _searchPatternError(String query, bool useRegex) {
    final trimmed = query.trim();
    if (!useRegex || trimmed.isEmpty) return null;

    try {
      RegExp(trimmed);
      return null;
    } catch (error) {
      return 'Invalid regular expression.';
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
      final attachmentPath = _complaintAttachments.isNotEmpty
          ? _complaintAttachments.first.path?.trim() ?? ''
          : '';

      // Collect resolver officer IDs
      final resolverOfficerIds = <int>[];
      for (final resolverId in _selectedResolverIds) {
        final resolver = controller.resolverOptions
            .where((r) => r.id.toString() == resolverId)
            .cast<CategoryResolverOption?>()
            .firstWhere((r) => r != null, orElse: () => null);
        if (resolver != null) {
          resolverOfficerIds.add(resolver.officerId);
        }
      }

      // Combine CC officer IDs and resolver officer IDs
      final allCcOfficerIds = <int>{
        ..._selectedCcOfficerIds,
        ...resolverOfficerIds,
      }.toList();

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
        ccOfficerId: allCcOfficerIds.isEmpty ? null : allCcOfficerIds.first,
        ccOfficerIds: allCcOfficerIds,
        anonymous: _anonymousComplaint,
        attachmentPath: attachmentPath.isEmpty ? null : attachmentPath,
      );
      if (!mounted) return;
      if (success) {
        _complaintTitleController.clear();
        _complaintDescriptionController.clear();
        setState(() {
          _selectedCategoryId = null;
          _selectedCcOfficerIds = [];
          _anonymousComplaint = false;
          _submitComplaintStep = 0;
          _categorySearchText = '';
          _categoryRegexEnabled = false;
          _ccOfficerSearchText = '';
          _ccRegexEnabled = false;
          _complaintAttachments = [];
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

  Future<void> _pickComplaintAttachments() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'jpg',
          'jpeg',
          'png',
          'gif',
          'pdf',
          'txt',
          'doc',
          'docx',
        ],
        allowMultiple: true,
        withData: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final validFiles = result.files.where((file) {
          final sizeInMB = file.size / (1024 * 1024);
          return sizeInMB <= 5.0;
        }).toList();

        if (validFiles.length != result.files.length) {
          _showSnackBar(
            'Some files were rejected. Only files under 5MB are allowed.',
          );
        }

        final newFiles = validFiles.take(5 - _complaintAttachments.length);
        if (newFiles.length < validFiles.length) {
          _showSnackBar('Maximum 5 files allowed. Some files were not added.');
        }

        setState(() {
          _complaintAttachments.addAll(newFiles);
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick files: $e');
    }
  }

  Future<void> _captureComplaintAttachment() async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(source: ImageSource.camera);

      if (photo != null) {
        final file = PlatformFile(
          name: photo.name,
          path: photo.path,
          size: await photo.length(),
          bytes: null,
        );

        final sizeInMB = file.size / (1024 * 1024);
        if (sizeInMB > 5.0) {
          _showSnackBar('Image is too large. Maximum size is 5MB.');
          return;
        }

        if (_complaintAttachments.length >= 5) {
          _showSnackBar('Maximum 5 files allowed.');
          return;
        }

        setState(() {
          _complaintAttachments.add(file);
        });
      }
    } catch (e) {
      _showSnackBar('Failed to capture image: $e');
    }
  }

  void _removeAttachment(PlatformFile file) {
    setState(() {
      _complaintAttachments.remove(file);
    });
  }

  IconData _getFileIcon(PlatformFile file) {
    final extension = file.extension?.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
      return Icons.image;
    } else if (extension == 'pdf') {
      return Icons.picture_as_pdf;
    } else if (['doc', 'docx'].contains(extension)) {
      return Icons.description;
    } else {
      return Icons.attach_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes == 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    final i = (bytes.bitLength - 1) ~/ 10;
    return '${(bytes / (1 << (i * 10))).toStringAsFixed(1)} ${units[i]}';
  }

  Widget _submitComplaintTab(StudentController controller) {
    final categories = _uniqueCategories(controller.categories);
    final categorySearchError = _searchPatternError(
      _categorySearchText,
      _categoryRegexEnabled,
    );
    final filteredCategories = categorySearchError != null
        ? <ComplaintCategory>[]
        : categories
              .where(
                (category) => _matchesSearch(
                  _categoryLabel(category),
                  _categorySearchText,
                  _categoryRegexEnabled,
                ),
              )
              .toList(growable: false);
    final resolverOptions = _resolverOptionsForCategory(
      controller,
      _selectedCategoryId,
    );
    final ccOfficers = _ccOfficersForCategory(controller, _selectedCategoryId);
    final ccSearchError = _searchPatternError(
      _ccOfficerSearchText,
      _ccRegexEnabled,
    );
    final filteredCcOfficers = ccSearchError != null
        ? <SelectableOfficer>[]
        : ccOfficers
              .where(
                (officer) => _matchesSearch(
                  '${officer.name} ${officer.department}',
                  _ccOfficerSearchText,
                  _ccRegexEnabled,
                ),
              )
              .toList(growable: false);

    ComplaintCategory? selectedCategory;
    for (final category in categories) {
      if (category.id == _selectedCategoryId) {
        selectedCategory = category;
        break;
      }
    }

    final theme = Theme.of(context);
    final normalizedStep = _submitComplaintStep.clamp(0, 4);
    final canGoBack = normalizedStep > 0;
    final isLastStep = normalizedStep == 4;

    Future<void> animateToNextStep() async {
      await Future.wait([
        _fadeAnimationController.reverse(),
        _stepHeaderAnimationController.reverse(),
      ]);
      setState(() => _submitComplaintStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      await Future.wait([
        _fadeAnimationController.forward(),
        _stepHeaderAnimationController.forward(),
      ]);
    }

    Future<void> animateToPreviousStep() async {
      await Future.wait([
        _fadeAnimationController.reverse(),
        _stepHeaderAnimationController.reverse(),
      ]);
      setState(() => _submitComplaintStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      await Future.wait([
        _fadeAnimationController.forward(),
        _stepHeaderAnimationController.forward(),
      ]);
    }

    Future<void> handleNext() async {
      if (_submitComplaintStep == 0) {
        if (categories.isEmpty) {
          _showSnackBar('No complaint categories are available right now.');
          return;
        }
        if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
          _showSnackBar('Please select a category before continuing.');
          return;
        }
        await animateToNextStep();
        return;
      }

      if (_submitComplaintStep == 1) {
        // Resolver selection - no validation needed, can proceed
        await animateToNextStep();
        return;
      }

      if (_submitComplaintStep == 2) {
        if (!_validateComplaintDetails()) {
          return;
        }
        await animateToNextStep();
        return;
      }

      if (_submitComplaintStep == 3) {
        // Validate attachments if needed
        await animateToNextStep();
        return;
      }

      // Step 4 is review & submit, handled by submit button
    }

    void handleBack() {
      if (_submitComplaintStep > 0) {
        animateToPreviousStep();
      }
    }

    Widget stepHeader() {
      final labels = const [
        'Category',
        'Resolver Selection',
        'Details',
        'Attachments',
        'Review & Submit',
      ];

      final icons = const [
        Icons.category,
        Icons.people,
        Icons.description,
        Icons.attach_file,
        Icons.send,
      ];

      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icons[_submitComplaintStep],
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Step ${_submitComplaintStep + 1} of 5: ${labels[_submitComplaintStep]}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: List.generate(5, (index) {
                  final active = index == _submitComplaintStep;
                  final completed = index < _submitComplaintStep;
                  final color = completed || active
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant;

                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: index == 4 ? 0 : 8),
                      child: Column(
                        children: [
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: active
                                  ? [
                                      BoxShadow(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.3 * 255),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Icon(
                            icons[index],
                            size: 16,
                            color: active
                                ? theme.colorScheme.primary
                                : completed
                                ? theme.colorScheme.primary.withValues(
                                    alpha: 0.7 * 255,
                                  )
                                : theme.colorScheme.onSurfaceVariant.withValues(
                                    alpha: 0.5 * 255,
                                  ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            labels[index],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: active
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: active
                                  ? theme.colorScheme.primary
                                  : completed
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search categories',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) =>
                          setState(() => _categorySearchText = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: _categoryRegexEnabled,
                            onChanged: (value) => setState(
                              () => _categoryRegexEnabled = value ?? false,
                            ),
                          ),
                          const Text('Regex'),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              if (categorySearchError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    categorySearchError,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 12),
              if (filteredCategories.isEmpty)
                const Text('No complaint categories match your search.')
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
                      children: filteredCategories
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
                                      _resolverFilters = {
                                        'campus': '',
                                        'college': '',
                                        'department': '',
                                      };
                                      _selectedResolverIds = [];
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
              if (selectedCategory != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected category',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _categoryLabel(selectedCategory),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${resolverOptions.length} responsible office${resolverOptions.length == 1 ? '' : 's'} will receive this complaint.',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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

    Widget stepTwoResolverSelection() {
      final resolverOptions = _resolverOptionsForCategory(
        controller,
        _selectedCategoryId,
      );

      final campusOptions =
          resolverOptions
              .map((r) => r.campusName)
              .where((name) => name != null && name.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

      final collegeOptions =
          resolverOptions
              .where(
                (r) =>
                    _resolverFilters['campus']!.isEmpty ||
                    r.campusName == _resolverFilters['campus'],
              )
              .map((r) => r.collegeName)
              .where((name) => name != null && name.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

      final departmentOptions =
          resolverOptions
              .where(
                (r) =>
                    (_resolverFilters['campus']!.isEmpty ||
                        r.campusName == _resolverFilters['campus']) &&
                    (_resolverFilters['college']!.isEmpty ||
                        r.collegeName == _resolverFilters['college']),
              )
              .map((r) => r.departmentName)
              .where((name) => name != null && name.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

      final filteredResolvers = resolverOptions.where((resolver) {
        if (_resolverFilters['campus']!.isNotEmpty &&
            resolver.campusName != _resolverFilters['campus']) {
          return false;
        }
        if (_resolverFilters['college']!.isNotEmpty &&
            resolver.collegeName != _resolverFilters['college']) {
          return false;
        }
        if (_resolverFilters['department']!.isNotEmpty &&
            resolver.departmentName != _resolverFilters['department']) {
          return false;
        }
        return true;
      }).toList();

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Resolver Route',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose how your complaint should be routed (optional)',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              // Campus Filter
              DropdownButtonFormField<String>(
                initialValue: _resolverFilters['campus']!.isEmpty
                    ? null
                    : _resolverFilters['campus'],
                decoration: const InputDecoration(
                  labelText: 'Campus (Optional)',
                  border: OutlineInputBorder(),
                ),
                items: campusOptions.map((campus) {
                  return DropdownMenuItem(value: campus, child: Text(campus!));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _resolverFilters['campus'] = value ?? '';
                    _resolverFilters['college'] = '';
                    _resolverFilters['department'] = '';
                    _selectedResolverIds.clear();
                  });
                },
              ),
              const SizedBox(height: 12),
              // College Filter
              DropdownButtonFormField<String>(
                initialValue: _resolverFilters['college']!.isEmpty
                    ? null
                    : _resolverFilters['college'],
                decoration: const InputDecoration(
                  labelText: 'College (Optional)',
                  border: OutlineInputBorder(),
                ),
                items: collegeOptions.map((college) {
                  return DropdownMenuItem(
                    value: college,
                    child: Text(college!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _resolverFilters['college'] = value ?? '';
                    _resolverFilters['department'] = '';
                    _selectedResolverIds.clear();
                  });
                },
              ),
              const SizedBox(height: 12),
              // Department Filter
              DropdownButtonFormField<String>(
                initialValue: _resolverFilters['department']!.isEmpty
                    ? null
                    : _resolverFilters['department'],
                decoration: const InputDecoration(
                  labelText: 'Department (Optional)',
                  border: OutlineInputBorder(),
                ),
                items: departmentOptions.map((department) {
                  return DropdownMenuItem(
                    value: department,
                    child: Text(department!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _resolverFilters['department'] = value ?? '';
                    _selectedResolverIds.clear();
                  });
                },
              ),
              const SizedBox(height: 16),
              if (filteredResolvers.isNotEmpty) ...[
                Text(
                  'Available Routes:',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...filteredResolvers.map((resolver) {
                  final isSelected = _selectedResolverIds.contains(
                    resolver.id.toString(),
                  );
                  return Card(
                    color: isSelected
                        ? theme.colorScheme.primaryContainer
                        : null,
                    child: ListTile(
                      title: Text(resolver.officerName),
                      subtitle: Text(
                        [
                          if (resolver.campusName != null) resolver.campusName,
                          if (resolver.collegeName != null)
                            resolver.collegeName,
                          if (resolver.departmentName != null)
                            resolver.departmentName,
                          resolver.levelName,
                        ].join(' • '),
                      ),
                      trailing: Checkbox(
                        value: isSelected,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedResolverIds.add(resolver.id.toString());
                            } else {
                              _selectedResolverIds.remove(
                                resolver.id.toString(),
                              );
                            }
                          });
                        },
                      ),
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedResolverIds.remove(resolver.id.toString());
                          } else {
                            _selectedResolverIds.add(resolver.id.toString());
                          }
                        });
                      },
                    ),
                  );
                }),
              ] else ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No resolver routes available for the selected filters.',
                      style: TextStyle(color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    Widget stepThreeDetails() {
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
                  maxLength: 500,
                  buildCounter:
                      (
                        context, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '$currentLength/500',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
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
                    if ((value ?? '').length > 500) {
                      return 'Description must be under 500 characters.';
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

    Widget stepFourOptions() {
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
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Search carbon copy officers',
                            hintText: 'Filter by name or department',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.search),
                          ),
                          onChanged: (value) =>
                              setState(() => _ccOfficerSearchText = value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: _ccRegexEnabled,
                                onChanged: (value) => setState(
                                  () => _ccRegexEnabled = value ?? false,
                                ),
                              ),
                              const Text('Regex'),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (ccSearchError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        ccSearchError,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (filteredCcOfficers.isEmpty)
                    Text(
                      ccOfficers.isEmpty
                          ? 'No officers available for selected category.'
                          : 'No officers match your search.',
                      style: TextStyle(color: Colors.grey.shade700),
                    )
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
                                      _selectedCcOfficerIds = filteredCcOfficers
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
                              children: filteredCcOfficers
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
                  Text(
                    'Evidence attachments',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Attach supporting files (optional)',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade50,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.attach_file,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Click to upload files or use camera',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Images, PDFs, Documents under 5MB (Max 5 files)',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _pickComplaintAttachments,
                              icon: const Icon(Icons.upload_file_outlined),
                              label: const Text('Upload files'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _captureComplaintAttachment,
                              icon: const Icon(Icons.photo_camera_outlined),
                              label: const Text('Use camera'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_complaintAttachments.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ..._complaintAttachments.map(
                      (file) => Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(
                                _getFileIcon(file),
                                size: 24,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      file.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      _formatFileSize(file.size),
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => _removeAttachment(file),
                                icon: const Icon(Icons.close),
                                color: Colors.red,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    }

    Widget buildReviewItem(String label, String value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                '$label:',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: Text(
                value.isEmpty ? '-' : value,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
          ],
        ),
      );
    }

    Widget stepFiveReview() {
      final selectedCategoryLabel = selectedCategory != null
          ? _categoryLabel(selectedCategory)
          : 'No category selected';

      final ccOfficers = _ccOfficersForCategory(
        controller,
        _selectedCategoryId,
      );
      final selectedCcOfficers = ccOfficers
          .where((officer) => _selectedCcOfficerIds.contains(officer.id))
          .toList();

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Review & submit',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              buildReviewItem('Title', _complaintTitleController.text),
              buildReviewItem(
                'Description',
                _complaintDescriptionController.text,
              ),
              buildReviewItem('Category', selectedCategoryLabel),
              buildReviewItem(
                'Identity',
                _anonymousComplaint ? 'Anonymous' : 'Visible',
              ),
              buildReviewItem(
                'CC Backend Offices',
                '${selectedCcOfficers.length} selected',
              ),
              if (selectedCcOfficers.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: selectedCcOfficers
                        .map(
                          (officer) => Text(
                            '• ${officer.name}',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
              buildReviewItem(
                'Resolver Routes',
                '${_selectedResolverIds.length} selected',
              ),
              if (_selectedResolverIds.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _selectedResolverIds
                        .map((resolverId) {
                          final resolver = controller.resolverOptions
                              .where((r) => r.id.toString() == resolverId)
                              .cast<CategoryResolverOption?>()
                              .firstWhere((r) => r != null, orElse: () => null);
                          return resolver != null
                              ? Text(
                                  '• ${resolver.officerName} (${resolver.levelName})',
                                  style: TextStyle(color: Colors.grey.shade700),
                                )
                              : const SizedBox.shrink();
                        })
                        .where((widget) => widget is! SizedBox)
                        .toList(),
                  ),
                ),
              ],
              buildReviewItem(
                'Attachments',
                '${_complaintAttachments.length} files',
              ),
            ],
          ),
        ),
      );
    }

    final steps = [
      stepOneCategory(),
      stepTwoResolverSelection(),
      stepThreeDetails(),
      stepFourOptions(),
      stepFiveReview(),
    ];

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
          FadeTransition(opacity: _stepHeaderAnimation, child: stepHeader()),
          const SizedBox(height: 12),
          Container(
            height: MediaQuery.of(context).size.height * 0.65,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.1 * 255),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: steps.length,
                itemBuilder: (context, index) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: steps[index],
                    ),
                  );
                },
              ),
            ),
          ),
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
                          if (_canDeleteComplaint(complaint))
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

  // Appointment Request Form Methods
  void _startAppointmentRequest(StudentController controller) {
    final availableSlots = controller.appointmentAvailabilities
        .where((slot) => slot.isFree)
        .toList(growable: false);

    if (availableSlots.isEmpty) {
      _showSnackBar(
        'No free appointment slots are available right now.',
        backgroundColor: Colors.red,
      );
      return;
    }

    setState(() {
      _isRequestingAppointment = true;
      _appointmentRequestStep = 0;
      _selectedAppointmentSlot = availableSlots.first;
      _selectedIssueType = 'other';
      _appointmentDescriptionController.clear();
      // _appointmentLocationController.clear();
      _appointmentNoteController.clear();
      _appointmentPreferredDateController.text =
          availableSlots.first.availableDate;
    });
  }

  void _cancelAppointmentRequest() {
    setState(() {
      _isRequestingAppointment = false;
      _appointmentRequestStep = 0;
      _selectedAppointmentSlot = null;
      _selectedIssueType = 'other';
      _appointmentDescriptionController.clear();
      // _appointmentLocationController.clear();
      _appointmentNoteController.clear();
      _appointmentPreferredDateController.clear();
    });
  }

  Future<void> _submitAppointmentRequest(StudentController controller) async {
    if (!_appointmentFormKey.currentState!.validate()) {
      return;
    }

    final preferredDateText = _appointmentPreferredDateController.text.trim();
    final preferredDate = DateTime.tryParse(
      preferredDateText.isNotEmpty
          ? preferredDateText
          : _selectedAppointmentSlot!.availableDate,
    );

    final success = await controller.requestAppointment(
      availabilitySlotId: _selectedAppointmentSlot!.id,
      description: _appointmentDescriptionController.text.trim(),
      issueType: _selectedIssueType,
      preferredDate: preferredDate,
      // location: _appointmentLocationController.text.trim().isEmpty
      //     ? null
      //     : _appointmentLocationController.text.trim(),
      note: _appointmentNoteController.text.trim().isEmpty
          ? null
          : _appointmentNoteController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      _cancelAppointmentRequest();
      _showSnackBar(
        'Appointment request submitted successfully.',
        backgroundColor: Colors.green,
      );
    } else {
      _showSnackBar(
        controller.error ?? 'Unable to request appointment.',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> appointmentAnimateToNextStep() async {
    await Future.wait([
      _appointmentFadeAnimationController.reverse(),
      _appointmentStepHeaderAnimationController.reverse(),
    ]);
    setState(() => _appointmentRequestStep++);
    _appointmentPageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    await Future.wait([
      _appointmentFadeAnimationController.forward(),
      _appointmentStepHeaderAnimationController.forward(),
    ]);
  }

  Future<void> appointmentAnimateToPreviousStep() async {
    await Future.wait([
      _appointmentFadeAnimationController.reverse(),
      _appointmentStepHeaderAnimationController.reverse(),
    ]);
    setState(() => _appointmentRequestStep--);
    _appointmentPageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    await Future.wait([
      _appointmentFadeAnimationController.forward(),
      _appointmentStepHeaderAnimationController.forward(),
    ]);
  }

  Future<void> handleAppointmentNext(StudentController controller) async {
    if (_appointmentRequestStep == 0) {
      // Category/Issue Type selection - always proceed
      await appointmentAnimateToNextStep();
      return;
    }

    if (_appointmentRequestStep == 1) {
      // Slot selection - always proceed
      await appointmentAnimateToNextStep();
      return;
    }

    if (_appointmentRequestStep == 2) {
      // Details - validate form
      if (!_appointmentFormKey.currentState!.validate()) {
        return;
      }
      await appointmentAnimateToNextStep();
      return;
    }

    // Step 3 is review & submit, handled by submit button
  }

  void handleAppointmentBack() {
    if (_appointmentRequestStep > 0) {
      appointmentAnimateToPreviousStep();
    }
  }

  Widget appointmentStepHeader() {
    final labels = const [
      'Issue Type',
      'Select Slot',
      'Details',
      'Review & Submit',
    ];

    final icons = const [
      Icons.category,
      Icons.schedule,
      Icons.description,
      Icons.send,
    ];

    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icons[_appointmentRequestStep],
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Step ${_appointmentRequestStep + 1} of 4: ${labels[_appointmentRequestStep]}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: List.generate(4, (index) {
                final active = index == _appointmentRequestStep;
                final completed = index < _appointmentRequestStep;
                final color = completed || active
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant;

                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: index == 3 ? 0 : 8),
                    child: Column(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: active
                                ? [
                                    BoxShadow(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.3 * 255),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Icon(
                          icons[index],
                          size: 16,
                          color: active
                              ? theme.colorScheme.primary
                              : completed
                              ? theme.colorScheme.primary.withValues(
                                  alpha: 0.7 * 255,
                                )
                              : theme.colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.5 * 255,
                                ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          labels[index],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: active
                                ? theme.colorScheme.primary
                                : completed
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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

  Widget appointmentStepOneIssueType() {
    final theme = Theme.of(context);
    final issueTypeOptions = <Map<String, String>>[
      {'value': 'complaint', 'label': 'Complaint'},
      {'value': 'support', 'label': 'Support'},
      {'value': 'inquiry', 'label': 'Inquiry'},
      {'value': 'service_request', 'label': 'Service Request'},
      {'value': 'other', 'label': 'Other'},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Issue Type',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Choose the type of issue you need assistance with. This helps us route your appointment to the right department.',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            ...issueTypeOptions.map((option) {
              final isSelected = _selectedIssueType == option['value'];
              return Card(
                color: isSelected ? theme.colorScheme.primaryContainer : null,
                child: ListTile(
                  leading: Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  title: Text(option['label']!),
                  subtitle: Text(_getIssueTypeDescription(option['value']!)),
                  onTap: () {
                    setState(() => _selectedIssueType = option['value']!);
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget appointmentStepTwoSlotSelection(StudentController controller) {
    final theme = Theme.of(context);
    final availableSlots = controller.appointmentAvailabilities
        .where((slot) => slot.isFree)
        .toList(growable: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Available Slot',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Choose a convenient time slot for your appointment. All times are displayed in your local timezone.',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            if (availableSlots.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No available slots found.'),
                ),
              )
            else
              ...availableSlots.map((slot) {
                final isSelected = _selectedAppointmentSlot?.id == slot.id;
                return Card(
                  color: isSelected ? theme.colorScheme.primaryContainer : null,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      isSelected ? Icons.check_circle : Icons.schedule,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    title: Text(
                      slot.officerName.isNotEmpty
                          ? slot.officerName
                          : 'Available Officer',
                    ),
                    subtitle: Text(
                      [
                        if (slot.availableDate.isNotEmpty) slot.availableDate,
                        if (slot.startTime.isNotEmpty &&
                            slot.endTime.isNotEmpty)
                          '${slot.startTime} - ${slot.endTime}',
                        if (slot.source.isNotEmpty) 'Source: ${slot.source}',
                      ].join(' • '),
                    ),
                    isThreeLine: true,
                    onTap: () {
                      setState(() {
                        _selectedAppointmentSlot = slot;
                        _appointmentPreferredDateController.text =
                            slot.availableDate;
                      });
                    },
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget appointmentStepThreeDetails() {
    final theme = Theme.of(context);

    return Form(
      key: _appointmentFormKey,
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appointment Details',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Provide details about your appointment request. Be specific about what you need help with.',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _appointmentDescriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description *',
                      hintText: 'Describe the issue you need assistance with',
                      border: OutlineInputBorder(),
                    ),
                    minLines: 3,
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // TextFormField(
                  //   controller: _appointmentLocationController,
                  //   decoration: const InputDecoration(
                  //     labelText: 'Preferred Location',
                  //     hintText: 'Where would you like to meet?',
                  //     border: OutlineInputBorder(),
                  //   ),
                  // ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _appointmentPreferredDateController,
                    decoration: const InputDecoration(
                      labelText: 'Preferred Date',
                      hintText: 'Leave empty to use selected slot date',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _appointmentNoteController,
                    decoration: const InputDecoration(
                      labelText: 'Additional Notes',
                      hintText: 'Any additional information',
                      border: OutlineInputBorder(),
                    ),
                    minLines: 2,
                    maxLines: 4,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget appointmentStepFourReview(StudentController controller) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review & Submit',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Please review your appointment request details before submitting.',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            _buildAppointmentReviewItem(
              'Issue Type',
              _getIssueTypeDisplay(_selectedIssueType),
            ),
            _buildAppointmentReviewItem(
              'Selected Slot',
              _appointmentSlotSummary(_selectedAppointmentSlot!),
            ),
            _buildAppointmentReviewItem(
              'Description',
              _appointmentDescriptionController.text.trim(),
            ),
            // if (_appointmentLocationController.text.trim().isNotEmpty)
            //   _buildAppointmentReviewItem(
            //     'Location',
            //     _appointmentLocationController.text.trim(),
            //   ),
            if (_appointmentPreferredDateController.text.trim().isNotEmpty)
              _buildAppointmentReviewItem(
                'Preferred Date',
                _appointmentPreferredDateController.text.trim(),
              ),
            if (_appointmentNoteController.text.trim().isNotEmpty)
              _buildAppointmentReviewItem(
                'Notes',
                _appointmentNoteController.text.trim(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _getIssueTypeDescription(String value) {
    switch (value) {
      case 'complaint':
        return 'File a formal complaint or grievance';
      case 'support':
        return 'Get technical or general support';
      case 'inquiry':
        return 'Ask questions or get information';
      case 'service_request':
        return 'Request a specific service or action';
      case 'other':
      default:
        return 'Other type of assistance needed';
    }
  }

  String _getIssueTypeDisplay(String value) {
    switch (value) {
      case 'complaint':
        return 'Complaint';
      case 'support':
        return 'Support';
      case 'inquiry':
        return 'Inquiry';
      case 'service_request':
        return 'Service Request';
      case 'other':
      default:
        return 'Other';
    }
  }

  String _appointmentSlotSummary(AppointmentAvailabilityItem slot) {
    final parts = <String>[];
    if (slot.officerName.isNotEmpty) {
      parts.add(slot.officerName);
    }
    if (slot.availableDate.isNotEmpty) {
      parts.add(slot.availableDate);
    }
    if (slot.startTime.isNotEmpty && slot.endTime.isNotEmpty) {
      parts.add('${slot.startTime} - ${slot.endTime}');
    }
    return parts.join(' • ');
  }

  Widget _appointmentsTab(StudentController controller) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          controller.refreshAppointments(),
          controller.refreshAppointmentAvailabilities(),
        ]);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const Text(
            'My Appointments',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (!_isRequestingAppointment)
            FilledButton.icon(
              onPressed:
                  controller.appointmentAvailabilities.any(
                    (slot) => slot.isFree,
                  )
                  ? () => _startAppointmentRequest(controller)
                  : null,
              icon: const Icon(Icons.add_task_outlined),
              label: const Text('Request Appointment'),
            )
          else
            OutlinedButton.icon(
              onPressed: _cancelAppointmentRequest,
              icon: const Icon(Icons.close),
              label: const Text('Cancel Request'),
            ),
          const SizedBox(height: 8),
          if (_isRequestingAppointment) ...[
            FadeTransition(
              opacity: _appointmentStepHeaderAnimation,
              child: appointmentStepHeader(),
            ),
            const SizedBox(height: 12),
            Container(
              height: MediaQuery.of(context).size.height * 0.65,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.shadow.withValues(alpha: 0.1 * 255),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: PageView.builder(
                  controller: _appointmentPageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    return FadeTransition(
                      opacity: _appointmentFadeAnimation,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: index == 0
                            ? appointmentStepOneIssueType()
                            : index == 1
                            ? appointmentStepTwoSlotSelection(controller)
                            : index == 2
                            ? appointmentStepThreeDetails()
                            : appointmentStepFourReview(controller),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _appointmentRequestStep > 0
                        ? appointmentAnimateToPreviousStep
                        : null,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _appointmentRequestStep == 3
                        ? () => _submitAppointmentRequest(controller)
                        : () => handleAppointmentNext(controller),
                    icon: _appointmentRequestStep == 3
                        ? const Icon(Icons.send)
                        : const Icon(Icons.arrow_forward),
                    label: Text(
                      _appointmentRequestStep == 3 ? 'Submit Request' : 'Next',
                    ),
                  ),
                ),
              ],
            ),
          ] else if (controller.appointments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text('No appointments have been scheduled yet.'),
            )
          else
            ...controller.appointments.map(
              (appointment) => Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.event_note_outlined),
                  ),
                  title: Text(
                    appointment.complaintTitle.isNotEmpty
                        ? appointment.complaintTitle
                        : appointment.title,
                  ),
                  subtitle: Text(
                    [
                      appointment.issueTypeDisplay.isNotEmpty
                          ? 'Type: ${appointment.issueTypeDisplay}'
                          : '',
                      appointment.description,
                      appointment.preferredDate.isNotEmpty
                          ? 'Preferred date: ${appointment.preferredDate}'
                          : '',
                      appointment.scheduledFor.isNotEmpty
                          ? 'Scheduled: ${appointment.scheduledFor}'
                          : '',
                      appointment.officerName.isEmpty
                          ? ''
                          : 'Officer: ${appointment.officerName}',
                      // appointment.location,
                      appointment.note.isEmpty
                          ? ''
                          : 'Note: ${appointment.note}',
                      appointment.rejectionReason.isEmpty
                          ? ''
                          : 'Reason: ${appointment.rejectionReason}',
                    ].where((part) => part.trim().isNotEmpty).join('\n'),
                  ),
                  isThreeLine: true,
                  trailing: _statusChip(
                    appointment.statusDisplay.isNotEmpty
                        ? appointment.statusDisplay
                        : appointment.status,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
          const Text(
            'Available Slots',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (controller.appointmentAvailabilities.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text(
                'No available appointment slots were returned by the backend.',
              ),
            )
          else
            ...controller.appointmentAvailabilities.map(
              (slot) => Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.schedule_outlined),
                  ),
                  title: Text(
                    slot.officerName.isNotEmpty
                        ? slot.officerName
                        : 'Available slot',
                  ),
                  subtitle: Text(
                    [
                      slot.availableDate,
                      slot.startTime.isNotEmpty && slot.endTime.isNotEmpty
                          ? '${slot.startTime} - ${slot.endTime}'
                          : '',
                      slot.source.isNotEmpty ? 'Source: ${slot.source}' : '',
                      slot.isFree ? 'Free' : 'Booked',
                    ].where((part) => part.trim().isNotEmpty).join('\n'),
                  ),
                  isThreeLine: true,
                  trailing: slot.isFree
                      ? FilledButton.tonalIcon(
                          onPressed: () {
                            _startAppointmentRequest(controller);
                            setState(() => _selectedAppointmentSlot = slot);
                          },
                          icon: const Icon(Icons.event_available_outlined),
                          label: const Text('Request'),
                        )
                      : const Icon(
                          Icons.block_outlined,
                          color: Colors.redAccent,
                        ),
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
    // final studentIdController = TextEditingController(
    //   text: profile?.studentId ?? '',
    // );
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
                      // TextField(
                      //   controller: studentIdController,
                      //   decoration: const InputDecoration(
                      //     labelText: 'Student ID',
                      //     border: OutlineInputBorder(),
                      //   ),
                      // ),
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
                            // 'student_id': studentIdController.text.trim(),
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
    // studentIdController.dispose();
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
      // _ProfileRow(
      //   'Student ID',
      //   profile?.studentId.isNotEmpty == true ? profile!.studentId : '-',
      // ),
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
            const HelpdeskSessionsPage(),
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
                        final isHelpdeskTab =
                            selectedIndex == StudentDashboardTab.helpdesk.index;

                        final Widget content = isHelpdeskTab
                            ? pages[selectedIndex]
                            : Center(
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

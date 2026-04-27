import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/models/helpdesk_models.dart';
import '../../data/services/helpdesk_service.dart';
import 'helpdesk_call_page.dart';

class HelpdeskTabPage extends StatefulWidget {
  const HelpdeskTabPage({super.key});

  @override
  State<HelpdeskTabPage> createState() => _HelpdeskTabPageState();
}

class _HelpdeskTabPageState extends State<HelpdeskTabPage> {
  final HelpdeskService _service = HelpdeskService();
  final TextEditingController _composerController = TextEditingController();

  final List<HelpdeskSession> _sessions = <HelpdeskSession>[];
  List<HelpdeskMessage> _messages = <HelpdeskMessage>[];

  bool _loadingSessions = false;
  bool _loadingMessages = false;
  bool _isSending = false;
  bool _isMutatingSession = false;
  bool _isJoiningCall = false;
  bool _isSidebarVisible = true;
  bool _showSessionList = false;

  String _query = '';
  String _statusFilter = 'all';
  String? _error;

  HelpdeskSession? _selectedSession;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _composerController.dispose();
    super.dispose();
  }

  bool _isWideLayout(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1000;

  String _kindLabel(String kind) {
    switch (kind) {
      case HelpdeskKinds.audioCall:
        return 'Audio Call';
      case HelpdeskKinds.videoCall:
        return 'Video Call';
      case HelpdeskKinds.audioConference:
        return 'Audio Conference';
      case HelpdeskKinds.videoConference:
        return 'Video Conference';
      default:
        return kind.replaceAll('_', ' ').trim();
    }
  }

  Color _statusColor(BuildContext context, String status) {
    final scheme = Theme.of(context).colorScheme;
    switch (status) {
      case HelpdeskSessionStatus.active:
        return scheme.primary;
      case HelpdeskSessionStatus.pending:
        return scheme.tertiary;
      case HelpdeskSessionStatus.ended:
        return scheme.outline;
      case HelpdeskSessionStatus.cancelled:
        return scheme.error;
      default:
        return scheme.secondary;
    }
  }

  String _statusLabel(String status) {
    if (status.trim().isEmpty) return 'Unknown';
    return status[0].toUpperCase() + status.substring(1);
  }

  bool _supportsRealtimeCall(String kind) {
    return kind == HelpdeskKinds.audioCall ||
        kind == HelpdeskKinds.videoCall ||
        kind == HelpdeskKinds.audioConference ||
        kind == HelpdeskKinds.videoConference;
  }

  bool _isVideoKind(String kind) =>
      kind == HelpdeskKinds.videoCall || kind == HelpdeskKinds.videoConference;

  List<HelpdeskSession> _filteredSessions() {
    final query = _query.trim().toLowerCase();
    return _sessions
        .where((session) {
          final statusMatch =
              _statusFilter == 'all' || session.status == _statusFilter;
          if (!statusMatch) return false;
          if (query.isEmpty) return true;

          final participants = session.participants
              .map((item) => item.fullName.toLowerCase())
              .join(' ');

          return session.displayTitle.toLowerCase().contains(query) ||
              session.kind.toLowerCase().contains(query) ||
              participants.contains(query);
        })
        .toList(growable: false);
  }

  Future<void> _loadSessions({bool preserveSelection = true}) async {
    setState(() {
      _loadingSessions = true;
      _error = null;
    });

    try {
      final sessions = await _service.getSessions();
      if (!mounted) return;

      sessions.sort((a, b) {
        final aTime =
            a.updatedAt ??
            a.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bTime =
            b.updatedAt ??
            b.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      final previousId = preserveSelection ? _selectedSession?.id : null;
      HelpdeskSession? nextSelected;
      if (previousId != null) {
        for (final session in sessions) {
          if (session.id == previousId) {
            nextSelected = session;
            break;
          }
        }
      }
      nextSelected ??= sessions.isNotEmpty ? sessions.first : null;

      setState(() {
        _sessions
          ..clear()
          ..addAll(sessions);
        _selectedSession = nextSelected;
      });

      if (nextSelected != null) {
        await _loadMessages(nextSelected.id);
        _startPolling(nextSelected.id);
      } else {
        _stopPolling();
        setState(() => _messages = <HelpdeskMessage>[]);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loadingSessions = false);
    }
  }

  Future<void> _loadMessages(String sessionId) async {
    setState(() {
      _loadingMessages = true;
      _error = null;
    });

    try {
      final messages = await _service.getMessages(sessionId);
      messages.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aTime.compareTo(bTime);
      });

      if (!mounted) return;
      setState(() => _messages = messages);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loadingMessages = false);
    }
  }

  void _startPolling(String sessionId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted || _selectedSession?.id != sessionId) return;
      try {
        final messages = await _service.getMessages(sessionId);
        if (!mounted || _selectedSession?.id != sessionId) return;
        messages.sort((a, b) {
          final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return aTime.compareTo(bTime);
        });
        setState(() => _messages = messages);
      } catch (_) {
        // Ignore background polling errors.
      }
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _selectSession(HelpdeskSession session) async {
    final hideSidebar = !_isWideLayout(context);
    setState(() => _selectedSession = session);
    await _loadMessages(session.id);
    if (!mounted) return;
    _startPolling(session.id);
    if (hideSidebar) setState(() => _isSidebarVisible = false);
  }

  Future<void> _sendMessage() async {
    final session = _selectedSession;
    if (session == null || _isSending) return;

    final text = _composerController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isSending = true;
      _error = null;
    });

    try {
      final message = await _service.postMessage(
        sessionId: session.id,
        content: text,
      );
      if (!mounted) return;
      setState(() {
        _composerController.clear();
        _messages = <HelpdeskMessage>[..._messages, message];
      });
      await _loadSessions();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _joinSelectedCall() async {
    final session = _selectedSession;
    if (session == null) return;
    if (!_supportsRealtimeCall(session.kind)) {
      setState(
        () => _error = 'This session type does not support audio/video call.',
      );
      return;
    }

    setState(() {
      _isJoiningCall = true;
      _error = null;
    });

    try {
      var activeSession = session;
      if (activeSession.status == HelpdeskSessionStatus.pending) {
        activeSession = await _service.startSession(activeSession.id);
        if (!mounted) return;
        setState(() => _selectedSession = activeSession);
      }

      final token = await _service.getLivekitToken(activeSession.id);
      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              HelpdeskCallPage(session: activeSession, token: token),
        ),
      );

      if (!mounted) return;
      await _loadSessions();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isJoiningCall = false);
    }
  }

  Future<void> _startSelectedSession() async {
    final session = _selectedSession;
    if (session == null) return;

    setState(() {
      _isMutatingSession = true;
      _error = null;
    });

    try {
      final updated = await _service.startSession(session.id);
      if (!mounted) return;
      setState(() => _selectedSession = updated);
      await _loadSessions();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isMutatingSession = false);
    }
  }

  Future<void> _endSelectedSession() async {
    final session = _selectedSession;
    if (session == null) return;

    setState(() {
      _isMutatingSession = true;
      _error = null;
    });

    try {
      final updated = await _service.endSession(session.id);
      if (!mounted) return;
      setState(() => _selectedSession = updated);
      await _loadSessions();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isMutatingSession = false);
    }
  }

  Future<void> _deleteSelectedSession() async {
    final session = _selectedSession;
    if (session == null) return;

    final user = context.read<AuthController>().user;
    final canDelete =
        user != null &&
        (user.role.toLowerCase() == 'admin' || user.id == session.createdById);
    if (!canDelete) {
      setState(
        () => _error =
            'Only the session creator or admins can delete this session.',
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete session?'),
        content: Text(
          'Delete "${session.displayTitle}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isMutatingSession = true;
      _error = null;
    });

    try {
      await _service.deleteSession(session.id);
      if (!mounted) return;
      setState(() {
        _selectedSession = null;
        _messages = <HelpdeskMessage>[];
      });
      await _loadSessions(preserveSelection: false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isMutatingSession = false);
    }
  }

  Future<void> _showCreateSessionDialog() async {
    final titleController = TextEditingController();
    final selectedKind = ValueNotifier<String>(HelpdeskKinds.audioCall);

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Create helpdesk session'),
          content: StatefulBuilder(
            builder: (context, setLocalState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedKind.value,
                      decoration: const InputDecoration(labelText: 'Kind'),
                      items: HelpdeskKinds.values
                          .map(
                            (kind) => DropdownMenuItem<String>(
                              value: kind,
                              child: Text(_kindLabel(kind)),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) return;
                        setLocalState(() => selectedKind.value = value);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    titleController.dispose();
    selectedKind.dispose();

    if (created != true) return;

    setState(() => _loadingSessions = true);
    try {
      await _service.createSession(
        kind: selectedKind.value,
        participantIds: const <int>[],
        title: titleController.text.trim(),
      );
      await _loadSessions(preserveSelection: false);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loadingSessions = false);
    }
  }

  Widget _statsCard(String label, int value, Color bg, Color fg) {
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 18,
              color: fg,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final sessions = _filteredSessions();
    final active = _sessions
        .where((item) => item.status == HelpdeskSessionStatus.active)
        .length;
    final pending = _sessions
        .where((item) => item.status == HelpdeskSessionStatus.pending)
        .length;
    final ended = _sessions
        .where((item) => item.status == HelpdeskSessionStatus.ended)
        .length;

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Helpdesk Sessions',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  tooltip: 'Hide sidebar',
                  onPressed: () => setState(() => _isSidebarVisible = false),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 360 ? 4 : 2;
                    final itemWidth =
                        (constraints.maxWidth - (columns - 1) * 8) / columns;

                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        SizedBox(
                          width: itemWidth,
                          child: _statsCard(
                            'Total',
                            _sessions.length,
                            const Color(0xFFE2E8F0),
                            const Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: _statsCard(
                            'Active',
                            active,
                            const Color(0xFFDCFCE7),
                            const Color(0xFF166534),
                          ),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: _statsCard(
                            'Pending',
                            pending,
                            const Color(0xFFFEF3C7),
                            const Color(0xFF92400E),
                          ),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: _statsCard(
                            'Ended',
                            ended,
                            const Color(0xFFF1F5F9),
                            const Color(0xFF475569),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search sessions',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 320;

                    return isNarrow
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              DropdownButtonFormField<String>(
                                initialValue: _statusFilter,
                                decoration: const InputDecoration(
                                  labelText: 'Status',
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'all',
                                    child: Text('All'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'pending',
                                    child: Text('Pending'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'active',
                                    child: Text('Active'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'ended',
                                    child: Text('Ended'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'cancelled',
                                    child: Text('Cancelled'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() => _statusFilter = value);
                                },
                              ),
                              const SizedBox(height: 8),
                              FilledButton.icon(
                                onPressed: _showCreateSessionDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('New'),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _statusFilter,
                                  decoration: const InputDecoration(
                                    labelText: 'Status',
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'all',
                                      child: Text('All'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'pending',
                                      child: Text('Pending'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'active',
                                      child: Text('Active'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'ended',
                                      child: Text('Ended'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'cancelled',
                                      child: Text('Cancelled'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() => _statusFilter = value);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              FilledButton.icon(
                                onPressed: _showCreateSessionDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('New'),
                              ),
                            ],
                          );
                  },
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () =>
                        setState(() => _showSessionList = !_showSessionList),
                    icon: Icon(
                      _showSessionList ? Icons.expand_less : Icons.expand_more,
                    ),
                    label: Text(
                      _showSessionList ? 'Hide sessions' : 'Show sessions',
                    ),
                  ),
                ),
                if (_showSessionList) ...[
                  const Divider(height: 1),
                  if (_loadingSessions)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (sessions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Center(child: Text('No sessions found.')),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sessions.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        final selected = _selectedSession?.id == session.id;
                        final statusColor = _statusColor(
                          context,
                          session.status,
                        );
                        final participantNames = session.participants
                            .take(3)
                            .map((item) => item.fullName)
                            .where((name) => name.trim().isNotEmpty)
                            .join(', ');

                        return ListTile(
                          selected: selected,
                          selectedTileColor: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.08),
                          title: Text(
                            session.displayTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${_kindLabel(session.kind)}\n${participantNames.isEmpty ? 'No participants' : participantNames}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _statusLabel(session.status),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ),
                          onTap: () => _selectSession(session),
                        );
                      },
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatPane(BuildContext context) {
    final user = context.watch<AuthController>().user;
    final selected = _selectedSession;

    if (selected == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.headset_mic_outlined, size: 56),
            const SizedBox(height: 12),
            Text(
              'Select a helpdesk session',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text('Open a session from the sidebar or create a new one.'),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_isSidebarVisible)
                IconButton(
                  tooltip: 'Show sidebar',
                  onPressed: () => setState(() => _isSidebarVisible = true),
                  icon: const Icon(Icons.menu_open_rounded),
                ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selected.displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      '${_kindLabel(selected.kind)} • ${selected.status}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: _loadingMessages
                          ? null
                          : () => _loadMessages(selected.id),
                      icon: const Icon(Icons.refresh),
                    ),
                    if (_supportsRealtimeCall(selected.kind))
                      FilledButton.icon(
                        onPressed: _isJoiningCall ? null : _joinSelectedCall,
                        icon: Icon(
                          _isVideoKind(selected.kind)
                              ? Icons.videocam_outlined
                              : Icons.call_outlined,
                        ),
                        label: Text(_isJoiningCall ? 'Joining...' : 'Join'),
                      ),
                    if (selected.status == HelpdeskSessionStatus.pending)
                      FilledButton.tonal(
                        onPressed: _isMutatingSession
                            ? null
                            : _startSelectedSession,
                        child: const Text('Start'),
                      ),
                    if (selected.status == HelpdeskSessionStatus.active)
                      FilledButton.tonal(
                        onPressed: _isMutatingSession
                            ? null
                            : _endSelectedSession,
                        child: const Text('End'),
                      ),
                    IconButton(
                      tooltip: 'Delete Session',
                      onPressed: _isMutatingSession
                          ? null
                          : _deleteSelectedSession,
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loadingMessages
              ? const Center(child: CircularProgressIndicator())
              : _messages.where((item) => item.messageType != 'signal').isEmpty
              ? const Center(child: Text('No messages yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    if (message.messageType == 'signal') {
                      return const SizedBox.shrink();
                    }
                    final own = user != null && message.senderId == user.id;
                    return Align(
                      alignment: own
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        constraints: const BoxConstraints(maxWidth: 420),
                        decoration: BoxDecoration(
                          color: own
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!own)
                              Text(
                                message.senderName.isEmpty
                                    ? 'Unknown sender'
                                    : message.senderName,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            Text(
                              message.content,
                              style: TextStyle(
                                color: own
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              message.createdAt == null
                                  ? ''
                                  : TimeOfDay.fromDateTime(
                                      message.createdAt!.toLocal(),
                                    ).format(context),
                              style: TextStyle(
                                fontSize: 10,
                                color: own
                                    ? Theme.of(context).colorScheme.onPrimary
                                          .withValues(alpha: 0.8)
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _composerController,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                    ),
                    onSubmitted: (_) => _isSending ? null : _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _isSending ? null : _sendMessage,
                  child: Text(_isSending ? 'Sending...' : 'Send'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = _isWideLayout(context);

    return Column(
      children: [
        if (_error != null)
          MaterialBanner(
            content: Text(_error!),
            actions: [
              TextButton(
                onPressed: () => setState(() => _error = null),
                child: const Text('Dismiss'),
              ),
            ],
          ),
        Expanded(
          child: isWide
              ? Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _isSidebarVisible ? 360 : 0,
                      child: _isSidebarVisible
                          ? _buildSidebar(context)
                          : const SizedBox.shrink(),
                    ),
                    Expanded(child: _buildChatPane(context)),
                  ],
                )
              : Stack(
                  children: [
                    Positioned.fill(child: _buildChatPane(context)),
                    if (_isSidebarVisible)
                      Positioned.fill(
                        child: Row(
                          children: [
                            SizedBox(
                              width: MediaQuery.sizeOf(
                                context,
                              ).width.clamp(260.0, 320.0).toDouble(),
                              child: Material(
                                elevation: 4,
                                child: _buildSidebar(context),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _isSidebarVisible = false),
                                child: Container(
                                  color: Colors.black.withValues(alpha: 0.28),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

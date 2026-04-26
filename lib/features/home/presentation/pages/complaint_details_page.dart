import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/models/student_models.dart';
import '../controllers/student_controller.dart';

class ComplaintDetailsPage extends StatefulWidget {
  final StudentController controller;
  final StudentComplaint complaint;

  const ComplaintDetailsPage({
    super.key,
    required this.controller,
    required this.complaint,
  });

  @override
  State<ComplaintDetailsPage> createState() => _ComplaintDetailsPageState();
}

class _ComplaintDetailsPageState extends State<ComplaintDetailsPage> {
  static const _pollInterval = Duration(seconds: 2);

  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_ComplaintThreadMessage> _messages = [];

  Timer? _pollTimer;
  bool _loading = true;
  bool _sending = false;
  String? _error;
  DateTime? _lastSyncedAt;
  bool _hasAutoScrolled = false;

  StudentController get _controller => widget.controller;
  StudentComplaint get _complaint => widget.complaint;

  @override
  void initState() {
    super.initState();
    _loadThread();
    _pollTimer = Timer.periodic(
      _pollInterval,
      (_) => _loadThread(silent: true),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadThread({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait([
        _controller.fetchComplaintResponses(
          complaintRef: _complaint.complaintRef,
          complaintId: _complaint.id,
        ),
        _controller.fetchComplaintComments(_complaint.complaintRef),
      ]);

      final responses = results[0];
      final comments = results[1];

      final merged =
          <_ComplaintThreadMessage>[
            ...responses.whereType<Map<String, dynamic>>().map(
              _ComplaintThreadMessage.fromOfficerResponse,
            ),
            ...comments
                .whereType<Map<String, dynamic>>()
                .where(_ComplaintThreadMessage.shouldKeepComment)
                .map(_ComplaintThreadMessage.fromStudentComment),
          ]..sort((left, right) {
            final leftTime =
                left.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
            final rightTime =
                right.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
            return leftTime.compareTo(rightTime);
          });

      final shouldStickToBottom = _isNearBottom();

      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(merged);
        _lastSyncedAt = DateTime.now();
        _error = null;
      });

      if (!mounted || _messages.isEmpty) return;

      if (!_hasAutoScrolled || (!silent && shouldStickToBottom)) {
        _hasAutoScrolled = true;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _scrollToBottom(animated: false),
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted && !_loading) {
        setState(() {});
      } else if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _sendComment() async {
    if (!_canCompose) {
      setState(() {
        _error = 'You can comment after the officer posts a response.';
      });
      return;
    }

    final message = _commentController.text.trim();
    if (message.isEmpty || _sending) return;

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      final success = await _controller.addComplaintComment(
        complaintRef: _complaint.complaintRef,
        message: message,
      );

      if (!mounted) return;

      if (!success) {
        setState(() {
          _error = _controller.error ?? 'Failed to post comment.';
        });
        return;
      }

      _commentController.clear();
      await _loadThread();
      _scrollToBottom();
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  String _syncLabel() {
    final syncedAt = _lastSyncedAt;
    if (syncedAt == null) {
      return 'Live updates waiting';
    }

    final local = syncedAt.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return 'Updated $hour:$minute';
  }

  bool get _canCompose => _messages.any((message) => !message.isOutgoing);

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;
    final position = _scrollController.position;
    final remaining = position.maxScrollExtent - position.pixels;
    return remaining <= 72;
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.position.maxScrollExtent;
    if (animated) {
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
      return;
    }
    _scrollController.jumpTo(offset);
  }

  Widget _buildMessageBubble(_ComplaintThreadMessage message) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isOutgoing = message.isOutgoing;
    final bubbleColor = isOutgoing
        ? scheme.primaryContainer
        : scheme.surfaceContainerHighest;
    final textColor = isOutgoing
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;
    final alignment = isOutgoing ? Alignment.centerRight : Alignment.centerLeft;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isOutgoing ? 18 : 4),
      bottomRight: Radius.circular(isOutgoing ? 4 : 18),
    );

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: borderRadius,
            border: Border.all(
              color: isOutgoing
                  ? scheme.primary.withValues(alpha: 0.18)
                  : scheme.outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.kindLabel.isNotEmpty) ...[
                Chip(
                  label: Text(message.kindLabel),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(height: 8),
              ],
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: isOutgoing
                        ? scheme.primary.withValues(alpha: 0.16)
                        : scheme.secondary.withValues(alpha: 0.16),
                    child: Icon(
                      isOutgoing ? Icons.person_outline : Icons.support_agent,
                      size: 14,
                      color: isOutgoing ? scheme.primary : scheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      message.authorName,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                message.message,
                style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
              ),
              if (message.attachmentUrl.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Attachment: ${message.attachmentUrl}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textColor.withValues(alpha: 0.85),
                  ),
                ),
              ],
              if (message.rating != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Rating: ${message.rating}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textColor.withValues(alpha: 0.85),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                message.timestampLabel,
                style: theme.textTheme.labelSmall?.copyWith(color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComposer() {
    final canCompose = _canCompose;

    return SafeArea(
      top: false,
      child: Material(
        elevation: 8,
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  enabled: canCompose,
                  decoration: const InputDecoration(
                    labelText: 'Write a comment',
                    hintText: 'Send a reply to the complaint thread',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _sendComment(),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _sending || !canCompose ? null : _sendComment,
                child: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaint Details'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : () => _loadThread(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _loadThread(),
                child: _loading && _messages.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _complaint.title,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(_complaint.description),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      Chip(label: Text(_complaint.status)),
                                      Chip(
                                        label: Text(_complaint.categoryName),
                                      ),
                                      if (_complaint.isAnonymous)
                                        const Chip(label: Text('Anonymous')),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _syncLabel(),
                                    style: theme.textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Card(
                                color: theme.colorScheme.errorContainer,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color:
                                            theme.colorScheme.onErrorContainer,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _error!,
                                          style: TextStyle(
                                            color: theme
                                                .colorScheme
                                                .onErrorContainer,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          if (_messages.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 72),
                              child: Center(
                                child: Text('No responses or comments yet.'),
                              ),
                            )
                          else
                            ..._messages.map(_buildMessageBubble),
                          if (!_canCompose)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Write comment becomes available once an officer responds.',
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
            _buildComposer(),
          ],
        ),
      ),
    );
  }
}

class _ComplaintThreadMessage {
  final String authorName;
  final String message;
  final DateTime? timestamp;
  final bool isOutgoing;
  final String kindLabel;
  final String attachmentUrl;
  final int? rating;

  const _ComplaintThreadMessage({
    required this.authorName,
    required this.message,
    required this.timestamp,
    required this.isOutgoing,
    required this.kindLabel,
    required this.attachmentUrl,
    required this.rating,
  });

  factory _ComplaintThreadMessage.fromOfficerResponse(
    Map<String, dynamic> data,
  ) {
    return _ComplaintThreadMessage(
      authorName: _readName(data, const [
        'responder',
        'responder_name',
        'title',
      ]).ifEmpty('Officer'),
      message: _readText(data, const [
        'message',
        'response',
        'detail',
      ]).ifEmpty('No message'),
      timestamp: _readTimestamp(data),
      isOutgoing: false,
      kindLabel: _readText(data, const ['response_type']).ifEmpty('Response'),
      attachmentUrl: _readText(data, const ['attachment', 'attachment_url']),
      rating: _readInt(data, const ['rating']),
    );
  }

  factory _ComplaintThreadMessage.fromStudentComment(
    Map<String, dynamic> data,
  ) {
    return _ComplaintThreadMessage(
      authorName: _readName(data, const [
        'author_name',
        'author',
        'created_by',
      ]).ifEmpty('You'),
      message: _readText(data, const [
        'message',
        'comment',
        'body',
      ]).ifEmpty('No comment'),
      timestamp: _readTimestamp(data),
      isOutgoing: true,
      kindLabel: _readText(data, const ['comment_type']).ifEmpty('Comment'),
      attachmentUrl: _readText(data, const ['attachment', 'attachment_url']),
      rating: _readInt(data, const ['rating']),
    );
  }

  static bool shouldKeepComment(Map<String, dynamic> data) {
    final type = _readText(data, const ['comment_type', 'type']).toLowerCase();
    return type.isEmpty || type == 'comment';
  }

  String get timestampLabel {
    final value = timestamp;
    if (value == null) return 'Just now';
    final local = value.toLocal();
    final year = local.year.toString();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }

  static String _readText(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  static int? _readInt(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;
      if (value is int) return value;
      final parsed = int.tryParse(value.toString().trim());
      if (parsed != null) return parsed;
    }
    return null;
  }

  static String _readName(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;
      if (value is Map<String, dynamic>) {
        final joined = [value['first_name'], value['last_name']]
            .map((part) => part?.toString().trim() ?? '')
            .where((part) => part.isNotEmpty)
            .join(' ');
        if (joined.isNotEmpty) return joined;

        final direct =
            (value['full_name'] ??
                    value['name'] ??
                    value['username'] ??
                    value['title'] ??
                    '')
                .toString()
                .trim();
        if (direct.isNotEmpty) return direct;
      } else {
        final text = value.toString().trim();
        if (text.isNotEmpty) return text;
      }
    }
    return '';
  }

  static DateTime? _readTimestamp(Map<String, dynamic> data) {
    final candidates = <dynamic>[
      data['created_at'],
      data['created'],
      data['timestamp'],
      data['sent_at'],
      data['updated_at'],
      data['date'],
    ];

    for (final candidate in candidates) {
      if (candidate == null) continue;
      final text = candidate.toString().trim();
      if (text.isEmpty) continue;
      final parsed = DateTime.tryParse(text);
      if (parsed != null) return parsed;
    }

    return null;
  }
}

extension on String {
  String ifEmpty(String fallback) {
    return trim().isEmpty ? fallback : this;
  }
}

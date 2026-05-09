import 'dart:async';

import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../data/models/helpdesk_models.dart';
import '../../data/services/helpdesk_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import 'package:provider/provider.dart';

class HelpdeskSessionCombinedPage extends StatefulWidget {
  final HelpdeskSession session;

  const HelpdeskSessionCombinedPage({super.key, required this.session});

  @override
  State<HelpdeskSessionCombinedPage> createState() =>
      _HelpdeskSessionCombinedPageState();
}

class _HelpdeskSessionCombinedPageState
    extends State<HelpdeskSessionCombinedPage> {
  final HelpdeskService _service = HelpdeskService();
  final TextEditingController _composerController = TextEditingController();

  late HelpdeskSession _session;
  List<HelpdeskMessage> _messages = [];
  bool _loadingMessages = false;
  bool _isSending = false;
  bool _isMutating = false;
  bool _isJoining = false;
  String? _error;
  Timer? _pollTimer;

  // LiveKit
  late final Room _room;
  EventsListener<RoomEvent>? _roomListener;
  bool _connecting = false;
  bool _connected = false;
  bool _micEnabled = true;
  bool _cameraEnabled = false;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _room = Room();
    _loadMessages();
    _startPolling();
    _initJoinIfActive();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _composerController.dispose();
    _roomListener?.dispose();
    _room.dispose();
    super.dispose();
  }

  Future<void> _initJoinIfActive() async {
    if (!_supportsRealtimeCall(_session.kind)) return;
    // Do not auto-connect; wait for user to press Join.
  }

  bool _supportsRealtimeCall(String kind) {
    return kind == HelpdeskKinds.audioCall ||
        kind == HelpdeskKinds.videoCall ||
        kind == HelpdeskKinds.audioConference ||
        kind == HelpdeskKinds.videoConference;
  }

  bool _isVideoKind(String kind) =>
      kind == HelpdeskKinds.videoCall || kind == HelpdeskKinds.videoConference;

  Future<void> _loadMessages() async {
    setState(() {
      _loadingMessages = true;
      _error = null;
    });
    try {
      final messages = await _service.getMessages(_session.id);
      messages.sort(
        (a, b) =>
            (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)),
      );
      if (!mounted) return;
      setState(() => _messages = messages);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loadingMessages = false);
      }
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted) return;
      try {
        final messages = await _service.getMessages(_session.id);
        messages.sort(
          (a, b) => (a.createdAt ?? DateTime(0)).compareTo(
            b.createdAt ?? DateTime(0),
          ),
        );
        if (!mounted) return;
        setState(() => _messages = messages);
      } catch (_) {}
    });
  }

  Future<void> _sendMessage() async {
    if (_isSending) return;
    final text = _composerController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _isSending = true;
      _error = null;
    });
    try {
      final message = await _service.postMessage(
        sessionId: _session.id,
        content: text,
      );
      if (!mounted) return;
      setState(() {
        _composerController.clear();
        _messages = [..._messages, message];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _toggleMic() async {
    if (!_connected) return;
    final next = !_micEnabled;
    try {
      await _room.localParticipant?.setMicrophoneEnabled(next);
      if (!mounted) return;
      setState(() => _micEnabled = next);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _toggleCamera() async {
    if (!_connected || !_isVideoKind(_session.kind)) return;
    final next = !_cameraEnabled;
    try {
      await _room.localParticipant?.setCameraEnabled(next);
      if (!mounted) return;
      setState(() => _cameraEnabled = next);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _joinCall() async {
    if (!_supportsRealtimeCall(_session.kind)) {
      setState(() => _error = 'This session does not support calls.');
      return;
    }

    setState(() {
      _isJoining = true;
      _error = null;
      _connecting = true;
    });

    try {
      if (_session.status == HelpdeskSessionStatus.pending) {
        final updated = await _service.startSession(_session.id);
        if (!mounted) return;
        setState(() => _session = updated);
      }

      final token = await _service.getLivekitToken(_session.id);
      if (!mounted) return;

      _roomListener = _room.createListener()
        ..on<RoomDisconnectedEvent>((_) {
          if (!mounted) return;
          setState(() => _connected = false);
        })
        ..on<ParticipantConnectedEvent>((_) {
          if (!mounted) return;
          setState(() {});
        })
        ..on<ParticipantDisconnectedEvent>((_) {
          if (!mounted) return;
          setState(() {});
        })
        ..on<TrackSubscribedEvent>((_) {
          if (!mounted) return;
          setState(() {});
        })
        ..on<TrackUnsubscribedEvent>((_) {
          if (!mounted) return;
          setState(() {});
        })
        ..on<LocalTrackPublishedEvent>((_) {
          if (!mounted) return;
          setState(() {});
        })
        ..on<LocalTrackUnpublishedEvent>((_) {
          if (!mounted) return;
          setState(() {});
        });

      await _room.connect(token.connectUrl, token.token);
      await _room.localParticipant?.setMicrophoneEnabled(true);
      if (_isVideoKind(_session.kind)) {
        await _room.localParticipant?.setCameraEnabled(true);
      }

      if (!mounted) return;
      setState(() {
        _connected = true;
        _connecting = false;
        _micEnabled = true;
        _cameraEnabled = _isVideoKind(_session.kind);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _connected = false;
        _connecting = false;
        _error = e.toString();
      });
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  Future<void> _leaveCall() async {
    try {
      await _room.disconnect();
    } catch (_) {}
  }

  VideoTrack? _localVideoTrack() {
    final local = _room.localParticipant;
    if (local == null) return null;
    for (final pub in local.videoTrackPublications) {
      final t = pub.track;
      if (t is VideoTrack) return t;
    }
    return null;
  }

  List<RemoteVideoTrack> _remoteVideoTracks() {
    final tracks = <RemoteVideoTrack>[];
    for (final p in _room.remoteParticipants.values) {
      for (final pub in p.videoTrackPublications) {
        final t = pub.track;
        if (t is RemoteVideoTrack) tracks.add(t);
      }
    }
    return tracks;
  }

  Widget _callArea() {
    if (!_connected) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.call, size: 56),
            const SizedBox(height: 12),
            Text(
              _connecting ? 'Connecting...' : 'Not connected',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (!_connecting)
              FilledButton(
                onPressed: _isJoining ? null : _joinCall,
                child: const Text('Join Call'),
              ),
          ],
        ),
      );
    }

    final local = _localVideoTrack();
    final remote = _remoteVideoTracks();
    final tiles = <Widget>[for (final t in remote) _videoTile(track: t)]
      ..addIf(local != null, _videoTile(track: local!));

    if (tiles.isEmpty) {
      return Center(child: Text('Waiting for participants...'));
    }

    return GridView.count(
      crossAxisCount: tiles.length == 1 ? 1 : 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 16 / 9,
      children: tiles,
    );
  }

  Widget _videoTile({required VideoTrack track}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [VideoTrackRenderer(track, fit: VideoViewFit.cover)],
      ),
    );
  }

  Widget _chatArea(BuildContext context) {
    final user = context.watch<AuthController>().user;
    return Column(
      children: [
        // Video/Conference Preview Header
        if (_connected) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Participants',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Local participant
                        Container(
                          width: 100,
                          height: 100,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _localVideoTrack() != null
                                  ? _videoTile(track: _localVideoTrack()!)
                                  : Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.person),
                                          const SizedBox(height: 4),
                                          Text(
                                            'You',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.labelSmall,
                                          ),
                                        ],
                                      ),
                                    ),
                              Positioned(
                                bottom: 4,
                                left: 4,
                                child: Chip(
                                  label: const Text(
                                    'Local',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                  backgroundColor: Colors.black.withValues(
                                    alpha: 0.5,
                                  ),
                                  labelStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Remote participants
                        for (final track in _remoteVideoTracks())
                          Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                _videoTile(track: track),
                                Positioned(
                                  bottom: 4,
                                  left: 4,
                                  child: Chip(
                                    label: const Text(
                                      'Remote',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                    backgroundColor: Colors.black.withValues(
                                      alpha: 0.5,
                                    ),
                                    labelStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        Expanded(
          child: _loadingMessages
              ? const Center(child: CircularProgressIndicator())
              : _messages.where((m) => m.messageType != 'signal').isEmpty
              ? const Center(child: Text('No messages yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    if (msg.messageType == 'signal') {
                      return const SizedBox.shrink();
                    }
                    final own = user != null && msg.senderId == user.id;
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
                                msg.senderName.isEmpty
                                    ? 'Unknown sender'
                                    : msg.senderName,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            Text(msg.content),
                            const SizedBox(height: 4),
                            Text(
                              msg.createdAt == null
                                  ? ''
                                  : TimeOfDay.fromDateTime(
                                      msg.createdAt!.toLocal(),
                                    ).format(context),
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_session.displayTitle),
        actions: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Tooltip(
                  message: _error!,
                  child: const Icon(Icons.error_outline),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 800;
                  if (!isWide) {
                    // On narrow screens keep the existing session room (chat first, join call button)
                    return Column(
                      children: [
                        Expanded(child: _chatArea(context)),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _isJoining ? null : _joinCall,
                                  icon: Icon(
                                    _isVideoKind(_session.kind)
                                        ? Icons.videocam_outlined
                                        : Icons.call_outlined,
                                  ),
                                  label: Text(
                                    _isJoining ? 'Joining...' : 'Join Call',
                                  ),
                                ),
                              ),
                              if (_connected &&
                                  _supportsRealtimeCall(_session.kind))
                                SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: IconButton(
                                    onPressed: _toggleMic,
                                    icon: Icon(
                                      _micEnabled ? Icons.mic : Icons.mic_off,
                                    ),
                                  ),
                                ),
                              if (_connected && _isVideoKind(_session.kind))
                                SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: IconButton(
                                    onPressed: _toggleCamera,
                                    icon: Icon(
                                      _cameraEnabled
                                          ? Icons.videocam
                                          : Icons.videocam_off,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _session.kind ==
                                            HelpdeskKinds.videoConference ||
                                        _session.kind ==
                                            HelpdeskKinds.audioConference
                                    ? 'Conference'
                                    : 'Call',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 12),
                              Expanded(child: _callArea()),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Expanded(
                                    child: FilledButton.tonalIcon(
                                      onPressed: _connected
                                          ? _leaveCall
                                          : (_isJoining ? null : _joinCall),
                                      icon: Icon(
                                        _connected
                                            ? Icons.call_end
                                            : Icons.call,
                                      ),
                                      label: Text(
                                        _connected
                                            ? 'Leave'
                                            : (_isJoining
                                                  ? 'Joining...'
                                                  : 'Join'),
                                      ),
                                    ),
                                  ),
                                  if (_connected &&
                                      _supportsRealtimeCall(_session.kind))
                                    SizedBox(
                                      width: 80,
                                      child: FilledButton.tonal(
                                        onPressed: _toggleMic,
                                        child: Icon(
                                          _micEnabled
                                              ? Icons.mic
                                              : Icons.mic_off,
                                        ),
                                      ),
                                    ),
                                  if (_connected && _isVideoKind(_session.kind))
                                    SizedBox(
                                      width: 80,
                                      child: FilledButton.tonal(
                                        onPressed: _toggleCamera,
                                        child: Icon(
                                          _cameraEnabled
                                              ? Icons.videocam
                                              : Icons.videocam_off,
                                        ),
                                      ),
                                    ),
                                  Expanded(
                                    child: FilledButton.tonal(
                                      onPressed: _isMutating
                                          ? null
                                          : () async {
                                              setState(
                                                () => _isMutating = true,
                                              );
                                              try {
                                                final updated = await _service
                                                    .startSession(_session.id);
                                                if (!mounted) return;
                                                setState(
                                                  () => _session = updated,
                                                );
                                              } catch (e) {
                                                if (!mounted) return;
                                                setState(
                                                  () => _error = e.toString(),
                                                );
                                              } finally {
                                                if (mounted) {
                                                  setState(
                                                    () => _isMutating = false,
                                                  );
                                                }
                                              }
                                            },
                                      child: const Text('Start'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(flex: 1, child: _chatArea(context)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension _ListHelpers<T> on List<T> {
  void addIf(bool cond, T value) {
    if (cond) add(value);
  }
}

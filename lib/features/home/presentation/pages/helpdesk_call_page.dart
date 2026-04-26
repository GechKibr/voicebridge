import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../data/models/helpdesk_models.dart';

class HelpdeskCallPage extends StatefulWidget {
  final HelpdeskSession session;
  final HelpdeskLivekitToken token;

  const HelpdeskCallPage({
    super.key,
    required this.session,
    required this.token,
  });

  @override
  State<HelpdeskCallPage> createState() => _HelpdeskCallPageState();
}

class _HelpdeskCallPageState extends State<HelpdeskCallPage> {
  late final Room _room;
  EventsListener<RoomEvent>? _roomListener;

  bool _connecting = true;
  bool _connected = false;
  bool _micEnabled = true;
  bool _cameraEnabled = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _room = Room();
    _joinRoom();
  }

  @override
  void dispose() {
    _roomListener?.dispose();
    _room.dispose();
    super.dispose();
  }

  bool get _isVideoSession =>
      widget.session.kind == HelpdeskKinds.videoCall ||
      widget.session.kind == HelpdeskKinds.videoConference;

  String _friendlyRtcError(Object error) {
    final raw = error.toString();
    final lower = raw.toLowerCase();

    if (error is MissingPluginException ||
        lower.contains('missingpluginexception') ||
        lower.contains('flutterwebrtc.method')) {
      return 'WebRTC native plugin is not available in this app runtime. '
          'Do a full restart/reinstall (not hot reload), then run again. '
          'If it still fails, rebuild the app from scratch with flutter clean and flutter pub get.';
    }

    if (lower.contains('notallowederror') || lower.contains('permission')) {
      return 'Microphone/Camera permission is denied. Allow permissions in device settings and retry.';
    }

    if (lower.contains('notfounderror') || lower.contains('no device')) {
      return 'No microphone/camera device was found. Attach an available device and retry.';
    }

    return raw;
  }

  Future<void> _joinRoom() async {
    setState(() {
      _connecting = true;
      _error = null;
    });

    try {
      _roomListener = _room.createListener()
        ..on<RoomDisconnectedEvent>((event) {
          if (!mounted) return;
          setState(() => _connected = false);
        })
        ..on<ParticipantConnectedEvent>((event) {
          if (!mounted) return;
          setState(() {});
        })
        ..on<ParticipantDisconnectedEvent>((event) {
          if (!mounted) return;
          setState(() {});
        });

      await _room.connect(widget.token.connectUrl, widget.token.token);
      await _room.localParticipant?.setMicrophoneEnabled(true);
      if (_isVideoSession) {
        await _room.localParticipant?.setCameraEnabled(true);
      }

      if (!mounted) return;
      setState(() {
        _connected = true;
        _connecting = false;
        _micEnabled = true;
        _cameraEnabled = _isVideoSession;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _connected = false;
        _connecting = false;
        _error = _friendlyRtcError(e);
      });
    }
  }

  Future<void> _leaveRoom() async {
    try {
      await _room.disconnect();
    } catch (_) {
      // Ignore disconnect errors while closing the screen.
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
      setState(() => _error = _friendlyRtcError(e));
    }
  }

  Future<void> _toggleCamera() async {
    if (!_connected || !_isVideoSession) return;
    final next = !_cameraEnabled;
    try {
      await _room.localParticipant?.setCameraEnabled(next);
      if (!mounted) return;
      setState(() => _cameraEnabled = next);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _friendlyRtcError(e));
    }
  }

  List<RemoteParticipant> _remoteParticipants() {
    return _room.remoteParticipants.values.toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final remoteParticipants = _remoteParticipants();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _leaveRoom();
        if (!context.mounted) return;
        Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.session.displayTitle),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await _leaveRoom();
              if (!context.mounted) return;
              Navigator.of(context).pop();
            },
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.session.kind == HelpdeskKinds.audioConference ||
                          widget.session.kind == HelpdeskKinds.videoConference
                      ? 'Conference Room'
                      : 'Call Room',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text('Room: ${widget.token.roomName}'),
                const SizedBox(height: 12),
                if (_connecting) const LinearProgressIndicator(),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    Chip(
                      avatar: Icon(
                        _connected ? Icons.check_circle : Icons.link_off,
                        color: _connected
                            ? Theme.of(context).colorScheme.tertiary
                            : Theme.of(context).colorScheme.error,
                      ),
                      label: Text(_connected ? 'Connected' : 'Disconnected'),
                    ),
                    Chip(
                      avatar: Icon(
                        Icons.people_alt_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      label: Text(
                        'Participants: ${remoteParticipants.length + 1}',
                      ),
                    ),
                    Chip(
                      avatar: Icon(
                        _micEnabled ? Icons.mic : Icons.mic_off,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      label: Text(_micEnabled ? 'Mic on' : 'Mic off'),
                    ),
                    if (_isVideoSession)
                      Chip(
                        avatar: Icon(
                          _cameraEnabled
                              ? Icons.videocam_outlined
                              : Icons.videocam_off_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        label: Text(
                          _cameraEnabled ? 'Camera on' : 'Camera off',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Participants',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    children: [
                      const ListTile(
                        dense: true,
                        leading: Icon(Icons.person),
                        title: Text('You'),
                        subtitle: Text('Local participant'),
                      ),
                      for (final participant in remoteParticipants)
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.person_outline),
                          title: Text(
                            participant.name.trim().isEmpty
                                ? participant.identity
                                : participant.name,
                          ),
                          subtitle: Text(participant.identity),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: _connected ? _toggleMic : null,
                        icon: Icon(_micEnabled ? Icons.mic_off : Icons.mic),
                        label: Text(_micEnabled ? 'Mute Mic' : 'Unmute Mic'),
                      ),
                    ),
                    if (_isVideoSession) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: _connected ? _toggleCamera : null,
                          icon: Icon(
                            _cameraEnabled
                                ? Icons.videocam_off_outlined
                                : Icons.videocam_outlined,
                          ),
                          label: Text(
                            _cameraEnabled ? 'Stop Camera' : 'Start Camera',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: () async {
                      await _leaveRoom();
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.call_end),
                    label: const Text('Leave Call'),
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

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

    if (lower.contains('404') ||
        lower.contains('page not found') ||
        lower.contains('not found')) {
      return 'LiveKit URL is not reachable (404). Verify LIVEKIT_URL in .env and that the LiveKit server is running.';
    }

    if (lower.contains('failed host lookup') ||
        lower.contains('no address associated with hostname')) {
      return 'LiveKit host cannot be resolved. Check LIVEKIT_URL in .env and your network/DNS, then try again.';
    }

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

  Widget _errorIllustration(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.wifi_off_rounded,
        size: 36,
        color: Theme.of(context).colorScheme.onErrorContainer,
      ),
    );
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
        })
        ..on<TrackSubscribedEvent>((event) {
          if (!mounted) return;
          setState(() {});
        })
        ..on<TrackUnsubscribedEvent>((event) {
          if (!mounted) return;
          setState(() {});
        })
        ..on<LocalTrackPublishedEvent>((event) {
          if (!mounted) return;
          setState(() {});
        })
        ..on<LocalTrackUnpublishedEvent>((event) {
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

  VideoTrack? _localVideoTrack() {
    final local = _room.localParticipant;
    if (local == null) return null;

    for (final publication in local.videoTrackPublications) {
      final track = publication.track;
      if (track is VideoTrack) return track;
    }

    return null;
  }

  List<RemoteVideoTrack> _remoteVideoTracks() {
    final tracks = <RemoteVideoTrack>[];
    for (final participant in _room.remoteParticipants.values) {
      for (final publication in participant.videoTrackPublications) {
        final track = publication.track;
        if (track != null) {
          tracks.add(track);
        }
      }
    }
    return tracks;
  }

  Widget _videoTile({required VideoTrack track, required String label}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          VideoTrackRenderer(track, fit: VideoViewFit.cover),
          Positioned(
            left: 10,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoSection(BuildContext context) {
    if (!_isVideoSession) return const SizedBox.shrink();

    final localTrack = _localVideoTrack();
    final remoteTracks = _remoteVideoTracks();
    final tiles = <Widget>[
      for (final track in remoteTracks)
        _videoTile(track: track, label: 'Remote'),
      if (localTrack != null) _videoTile(track: localTrack, label: 'You'),
    ];

    if (tiles.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.videocam_off_outlined),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _cameraEnabled
                    ? 'Waiting for video streams...'
                    : 'Start your camera to share video in real time.',
              ),
            ),
          ],
        ),
      );
    }

    final columns = tiles.length <= 1 ? 1 : 2;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: columns,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 16 / 9,
      children: tiles,
    );
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
          child: ListView(
            padding: const EdgeInsets.all(16),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _errorIllustration(context),
                      const SizedBox(height: 10),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: _connecting ? null : _joinRoom,
                        child: Text(
                          _connecting ? 'Connecting...' : 'Try again',
                        ),
                      ),
                    ],
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
                      label: Text(_cameraEnabled ? 'Camera on' : 'Camera off'),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              if (_isVideoSession) ...[
                Text(
                  'Live video',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _buildVideoSection(context),
                const SizedBox(height: 20),
              ],
              Text(
                'Participants',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
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
    );
  }
}

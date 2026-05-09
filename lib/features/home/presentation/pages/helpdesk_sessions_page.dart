import 'package:flutter/material.dart';

import '../../data/models/helpdesk_models.dart';
import '../../data/services/helpdesk_service.dart';
import 'helpdesk_session_combined_page.dart';

class HelpdeskSessionsPage extends StatefulWidget {
  const HelpdeskSessionsPage({super.key});

  @override
  State<HelpdeskSessionsPage> createState() => _HelpdeskSessionsPageState();
}

class _HelpdeskSessionsPageState extends State<HelpdeskSessionsPage> {
  final HelpdeskService _service = HelpdeskService();
  List<HelpdeskSession> _sessions = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final sessions = await _service.getSessions();
      sessions.sort(
        (a, b) => (b.updatedAt ?? b.createdAt ?? DateTime(0)).compareTo(
          a.updatedAt ?? a.createdAt ?? DateTime(0),
        ),
      );
      if (!mounted) return;
      setState(() => _sessions = sessions);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Helpdesk Sessions'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(child: Text(_error!))
            : _sessions.isEmpty
            ? const Center(child: Text('No sessions found.'))
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: _sessions.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final session = _sessions[index];
                  return ListTile(
                    title: Text(session.displayTitle),
                    subtitle: Text(session.kind),
                    trailing: Text(session.status),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              HelpdeskSessionCombinedPage(session: session),
                        ),
                      );
                      await _load();
                    },
                  );
                },
              ),
      ),
    );
  }
}

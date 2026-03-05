import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/sync_service.dart';

class LinkedDevicesScreen extends StatefulWidget {
  final String userId;
  final String serverUrl;

  const LinkedDevicesScreen({
    super.key,
    required this.userId,
    this.serverUrl = 'http://10.0.2.2:8000', // Default for emulator
  });

  @override
  State<LinkedDevicesScreen> createState() => _LinkedDevicesScreenState();
}

class _LinkedDevicesScreenState extends State<LinkedDevicesScreen> {
  List<dynamic> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSessions();
  }

  Future<void> _fetchSessions() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${widget.serverUrl}/api/sessions?user_id=${widget.userId}'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _sessions = data['sessions'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching sessions: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _revokeSession(String sessionId) async {
    try {
      final response = await http.post(
        Uri.parse('${widget.serverUrl}/api/sessions/revoke?session_id=$sessionId&user_id=${widget.userId}'),
      );
      if (response.statusCode == 200) {
        _fetchSessions();
      }
    } catch (e) {
      debugPrint('Error revoking session: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Linked Devices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchSessions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? const Center(child: Text('No linked devices'))
              : ListView.builder(
                  itemCount: _sessions.length,
                  itemBuilder: (context, index) {
                    final session = _sessions[index];
                    final lastActivity = DateTime.fromMillisecondsSinceEpoch(
                      (session['last_activity'] * 1000).toInt(),
                    );
                    final isOnline = session['is_online'] ?? false;

                    return ListTile(
                      leading: Icon(
                        session['user_agent'].toString().contains('Mobile')
                            ? Icons.smartphone
                            : Icons.laptop,
                        color: isOnline ? Colors.green : null,
                      ),
                      title: Text(session['user_agent'] ?? 'Unknown device'),
                      subtitle: Text(
                        'Last activity: ${DateFormat.yMMMd().add_jm().format(lastActivity)}',
                      ),
                      trailing: session['session_id'] == 'mobile'
                          ? const Text('(This device)', style: TextStyle(color: Colors.grey))
                          : TextButton(
                              onPressed: () => _revokeSession(session['session_id']),
                              child: const Text('Unlink', style: TextStyle(color: Colors.red)),
                            ),
                    );
                  },
                ),
    );
  }
}

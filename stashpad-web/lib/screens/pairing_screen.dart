import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../services/sync_service.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final String _sessionId = const Uuid().v4();
  final String _serverUrl = 'http://localhost:8000'; // Adjust for production
  bool _isPoling = false;
  Timer? _timer;
  String? _pairingCode;
  int _expiresIn = 45;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initiateSession();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initiateSession() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      final response = await http.post(
        Uri.parse('$_serverUrl/api/auth/request'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'session_id': _sessionId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _pairingCode = data['pairing_code'];
          _isLoading = false;
        });
        _startPolling();
      } else {
        setState(() {
          _error = 'Server returned ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error initiating session: $e');
      setState(() {
        _error = 'Could not connect to server';
        _isLoading = false;
      });
    }
  }

  void _startPolling() {
    _isPoling = true;
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!_isPoling) return;
      
      try {
        final response = await http.get(
          Uri.parse('$_serverUrl/api/auth/status?session_id=$_sessionId'),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['authorized'] == true) {
            _timer?.cancel();
            _isPoling = false;
            
            final userId = data['user_id'];
            final keyBase64 = data['pairing_key']; // Secret key shared during pairing
            
            if (mounted) {
              final syncService = Provider.of<SyncService>(context, listen: false);
              await syncService.connect(userId, _sessionId, base64.decode(keyBase64));
            }
          } else {
            // Update pairing code and timer from polling response
            if (mounted) {
              setState(() {
                _pairingCode = data['pairing_code'];
                _expiresIn = data['expires_in'] ?? 45;
              });
            }
          }
        }
      } catch (e) {
        print('Polling error: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final qrData = json.encode({
      'sessionId': _sessionId,
      'serverUrl': _serverUrl,
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Pair with Stashpad Mobile',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            const Text('Scan this QR code with your mobile app to sync your notes.'),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 250.0,
              ),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
               const Text('Loading pairing code...')
            else if (_error != null)
              Text(
                'Error: $_error',
                style: const TextStyle(color: Colors.red),
              )
            else if (_pairingCode != null) ...[
              const Text(
                'OR ENTER CODE',
                style: TextStyle(
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _pairingCode!,
                      style: GoogleFonts.firaCode(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Refreshes in $_expiresIn s',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Waiting for authorization...'),
            if (_error != null)
              TextButton(
                onPressed: _initiateSession,
                child: const Text('Retry connection'),
              ),
          ],
        ),
      ),
    );
  }
}

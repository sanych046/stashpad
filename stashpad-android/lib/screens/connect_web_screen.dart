import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:cryptography/cryptography.dart';
import 'package:provider/provider.dart';
import '../services/sync_service.dart';
import '../services/database_service.dart';

class ConnectWebScreen extends StatefulWidget {
  const ConnectWebScreen({super.key});

  @override
  State<ConnectWebScreen> createState() => _ConnectWebScreenState();
}

class _ConnectWebScreenState extends State<ConnectWebScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isConnecting = false;
  
  String get _serverUrl {
    final String host = kIsWeb ? 'localhost' : (defaultTargetPlatform == TargetPlatform.android ? '10.0.2.2' : 'localhost');
    return 'http://$host:8000';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isConnecting) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        setState(() {
          _isConnecting = true;
        });
        
        // Handle the scanned code
        _handleConnect(code);
      }
    }
  }

  void _handleConnect(String code) async {
    try {
      final Map<String, dynamic> data = json.decode(code);
      final String sessionId = data['sessionId'];
      final String serverUrl = data['serverUrl'] ?? _serverUrl;
      
      _authorizeSession(sessionId, serverUrl);
    } catch (e) {
      _showError('Invalid QR code format');
    }
  }

  void _showManualEntry() async {
    final TextEditingController codeController = TextEditingController();
    final String? code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Link by Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the 6-character code displayed on the web client.'),
            const SizedBox(height: 16),
              TextField(
                controller: codeController,
                autofocus: true,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 8),
                decoration: const InputDecoration(
                  hintText: 'XXXXXX',
                  counterText: '',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 20),
                ),
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  UpperCaseTextFormatter(),
                ],
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, codeController.text.trim().toUpperCase()),
            child: const Text('Link'),
          ),
        ],
      ),
    );

    if (code != null && code.length == 6) {
      _handleManualConnect(code);
    }
  }

  void _handleManualConnect(String code) async {
    setState(() => _isConnecting = true);
    
    try {
      final response = await http.get(
        Uri.parse('$_serverUrl/api/auth/lookup?code=$code'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final sessionId = data['session_id'];
        _authorizeSession(sessionId, _serverUrl);
      } else {
        throw Exception('Invalid or expired code');
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _authorizeSession(String sessionId, String serverUrl) async {
    try {
      setState(() => _isConnecting = true);
      
      // Generate a random 256-bit pairing key
      final algorithm = AesGcm.with256bits();
      final secretKey = await algorithm.newSecretKey();
      final secretKeyBytes = await secretKey.extractBytes();
      final pairingKeyBase64 = base64.encode(secretKeyBytes);
      
      const String userId = 'test-user-123'; // Placeholder for actual user account ID
      
      final response = await http.post(
        Uri.parse('$serverUrl/api/auth/verify?session_id=$sessionId&user_id=$userId&pairing_key=$pairingKeyBase64'),
      );

      if (response.statusCode == 200 && mounted) {
        final syncService = Provider.of<SyncService>(context, listen: false);
        final databaseService = Provider.of<DatabaseService>(context, listen: false);
        
        // Establish Sync Connection
        await syncService.connect(userId, sessionId, secretKeyBytes, databaseService);
        
        // Trigger Full Sync
        await syncService.syncAllNotes(databaseService);

        if (mounted) {
          setState(() => _isConnecting = false);
          _showSuccessDialog();
        }
      } else {
        throw Exception('Failed to verify session: ${response.statusCode}');
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 12),
            Text('Success!'),
          ],
        ),
        content: const Text('Successfully linked with web client. Your notes are now being synchronized.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Pop dialog
              Navigator.of(context).pop(); // Pop ConnectWebScreen
            },
            child: const Text('Great!'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      setState(() => _isConnecting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $message')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Web Client'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _showManualEntry,
            icon: const Icon(Icons.keyboard, color: Colors.white),
            label: const Text('Link by code', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // QR Viewfinder Overlay
          CustomPaint(
            painter: _ScannerOverlayPainter(),
            child: Container(),
          ),
          // Instructions
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Scan the QR code on stashpad.dev',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
          if (_isConnecting)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    const scanAreaSize = 250.0;
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanAreaSize,
      height: scanAreaSize,
    );

    // Darken the area outside the viewfinder
    final path = Path.combine(
      PathOperation.difference,
      Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
      Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12))),
    );
    canvas.drawPath(path, paint);

    // Draw viewfinder borders
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12)), borderPaint);
    
    // Draw corner accents
    final accentPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    const cornerLength = 40.0;
    
    // Top Left
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.top + cornerLength)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.left + cornerLength, rect.top),
      accentPaint,
    );
    
    // Top Right
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - cornerLength, rect.top)
        ..lineTo(rect.right, rect.top)
        ..lineTo(rect.right, rect.top + cornerLength),
      accentPaint,
    );
    
    // Bottom Left
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.bottom - cornerLength)
        ..lineTo(rect.left, rect.bottom)
        ..lineTo(rect.left + cornerLength, rect.bottom),
      accentPaint,
    );
    
    // Bottom Right
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - cornerLength, rect.bottom)
        ..lineTo(rect.right, rect.bottom)
        ..lineTo(rect.right, rect.bottom - cornerLength),
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

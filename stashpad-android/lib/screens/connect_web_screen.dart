import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ConnectWebScreen extends StatefulWidget {
  const ConnectWebScreen({super.key});

  @override
  State<ConnectWebScreen> createState() => _ConnectWebScreenState();
}

class _ConnectWebScreenState extends State<ConnectWebScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isConnecting = false;

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
        
        // Handle the scanned code (placeholder for actual sync logic)
        _handleConnect(code);
      }
    }
  }

  void _handleConnect(String code) {
    // In a real implementation, this would establish a secure connection (e.g. via WebSocket/Peer-to-Peer)
    // using the data provided in the QR code.
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Connecting to web client: ${code.substring(0, code.length > 20 ? 20 : code.length)}...'),
        duration: const Duration(seconds: 2),
      ),
    );

    // Mock successful connection after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connected to web client successfully!')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Web Client'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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

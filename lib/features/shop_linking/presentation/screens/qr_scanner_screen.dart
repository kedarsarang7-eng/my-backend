import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../services/connection_service.dart';
import '../../../../services/secure_qr_service.dart';
import '../../../../providers/app_state_providers.dart';
import 'shop_confirmation_screen.dart';
import 'manual_shop_add_screen.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  final SecureQrService _qrService = SecureQrService();
  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    for (final barcode in barcodes) {
      if (barcode.rawValue == null) continue;
      final rawValue = barcode.rawValue!;

      // Validate QR using SecureQrService (handles v2, v1, and legacy formats)
      final validationResult = _qrService.validateQrPayload(rawValue);

      if (validationResult.isValid && validationResult.shopId != null) {
        setState(() => _isProcessing = true);
        controller.stop();

        // Extract shop info from validated payload
        final shopId = validationResult.shopId!;
        final payload = validationResult.payload;
        final shopName = payload?['shopName'] as String?;
        final businessType = payload?['businessType'] as String?;

        // Navigate to confirmation screen with validated data
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ShopConfirmationScreen(
              ownerUid: shopId,
              shopName: shopName,
              businessType: businessType,
            ),
          ),
        ).then((_) {
          if (mounted) {
            setState(() => _isProcessing = false);
            controller.start();
          }
        });
        return; // Stop after first valid QR
      } else if (validationResult.error != null) {
        // Show error for invalid/expired QR
        if (validationResult.error!.contains('expired')) {
          _showError(
              'This QR code has expired. Please ask the shop for a new one.');
        } else if (validationResult.error!.contains('tampered')) {
          _showError('Invalid QR code. This may be a security issue.');
        }
        // Continue scanning for other barcodes
        continue;
      }

      // Fallback: Handle v1 format for backward compatibility
      if (rawValue.startsWith('v1:')) {
        setState(() => _isProcessing = true);
        controller.stop();

        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) {
            throw Exception("You must be logged in to connect.");
          }

          // Send request using ConnectionService (legacy flow)
          await ConnectionService().sendRequestFromQr(rawValue);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Connection request sent! Waiting for approval.'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }
        } catch (e) {
          if (mounted) {
            _showError('Failed: $e');
            setState(() => _isProcessing = false);
            controller.start();
          }
        }
        return;
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeStateProvider);
    // ignore: unused_local_variable
    final isDark = theme.isDark;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),

          // Overlay
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: Colors.blue,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            ),
          ),

          // Header
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: const Center(
              child: Text(
                "Scan Shop QR",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                ),
              ),
            ),
          ),

          // Tools
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ValueListenableBuilder(
                  valueListenable: controller,
                  builder: (context, state, child) {
                    final torchState = state.torchState;
                    return IconButton(
                      color: Colors.white,
                      icon: Icon(
                        torchState == TorchState.on
                            ? Icons.flash_on
                            : Icons.flash_off,
                        color: torchState == TorchState.on
                            ? Colors.yellow
                            : Colors.white,
                        size: 30,
                      ),
                      onPressed: () => controller.toggleTorch(),
                    );
                  },
                ),
                ValueListenableBuilder(
                  valueListenable: controller,
                  builder: (context, state, child) {
                    final cameraFacing = state.cameraDirection;
                    return IconButton(
                      color: Colors.white,
                      icon: Icon(
                        cameraFacing == CameraFacing.front
                            ? Icons.camera_front
                            : Icons.camera_rear,
                        size: 30,
                      ),
                      onPressed: () => controller.switchCamera(),
                    );
                  },
                ),
              ],
            ),
          ),

          // Manual Entry
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              onPressed: () {
                controller.stop();
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ManualShopAddScreen()));
              },
              icon: const Icon(Icons.keyboard, color: Colors.white),
              label: const Text("Enter Shop ID Manually",
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Overlay Shape
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;
  final double cutOutBottomOffset;

  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 10.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
    this.cutOutBottomOffset = 0,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final boxPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final cutOutRect = Rect.fromCenter(
      center: rect.center + Offset(0, -cutOutBottomOffset),
      width: cutOutSize,
      height: cutOutSize,
    );

    canvas.saveLayer(rect, backgroundPaint);
    canvas.drawRect(rect, backgroundPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
      boxPaint,
    );
    canvas.restore();

    // Draw corners
    final path = Path();
    // Top left
    path.moveTo(cutOutRect.left, cutOutRect.top + borderLength);
    path.lineTo(cutOutRect.left, cutOutRect.top + borderRadius);
    path.quadraticBezierTo(cutOutRect.left, cutOutRect.top,
        cutOutRect.left + borderRadius, cutOutRect.top);
    path.lineTo(cutOutRect.left + borderLength, cutOutRect.top);
    // Top right
    path.moveTo(cutOutRect.right - borderLength, cutOutRect.top);
    path.lineTo(cutOutRect.right - borderRadius, cutOutRect.top);
    path.quadraticBezierTo(cutOutRect.right, cutOutRect.top, cutOutRect.right,
        cutOutRect.top + borderRadius);
    path.lineTo(cutOutRect.right, cutOutRect.top + borderLength);
    // Bottom right
    path.moveTo(cutOutRect.right, cutOutRect.bottom - borderLength);
    path.lineTo(cutOutRect.right, cutOutRect.bottom - borderRadius);
    path.quadraticBezierTo(cutOutRect.right, cutOutRect.bottom,
        cutOutRect.right - borderRadius, cutOutRect.bottom);
    path.lineTo(cutOutRect.right - borderLength, cutOutRect.bottom);
    // Bottom left
    path.moveTo(cutOutRect.left + borderLength, cutOutRect.bottom);
    path.lineTo(cutOutRect.left + borderRadius, cutOutRect.bottom);
    path.quadraticBezierTo(cutOutRect.left, cutOutRect.bottom, cutOutRect.left,
        cutOutRect.bottom - borderRadius);
    path.lineTo(cutOutRect.left, cutOutRect.bottom - borderLength);

    canvas.drawPath(path, borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}

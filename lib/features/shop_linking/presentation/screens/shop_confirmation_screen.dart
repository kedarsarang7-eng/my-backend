import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../services/connection_service.dart';
import '../../../../providers/app_state_providers.dart';

class ShopConfirmationScreen extends ConsumerStatefulWidget {
  final String ownerUid;
  final Map<String, dynamic>? shopData;
  final String? shopName; // From v2 QR payload
  final String? businessType; // From v2 QR payload

  const ShopConfirmationScreen({
    super.key,
    required this.ownerUid,
    this.shopData,
    this.shopName,
    this.businessType,
  });

  @override
  ConsumerState<ShopConfirmationScreen> createState() =>
      _ShopConfirmationScreenState();
}

class _ShopConfirmationScreenState
    extends ConsumerState<ShopConfirmationScreen> {
  bool _isLinking = false;
  Map<String, dynamic>? _ownerData;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Use pre-filled data from v2 QR or shopData
    _ownerData = widget.shopData;
    if (_ownerData == null &&
        (widget.shopName != null || widget.businessType != null)) {
      // Pre-fill from v2 QR payload for immediate display
      _ownerData = {
        'shopId': widget.ownerUid,
        'shopName': widget.shopName ?? 'Unknown Shop',
        'businessType': widget.businessType,
      };
    }
    // Still fetch full details in background
    _fetchOwnerDetails();
  }

  Future<void> _fetchOwnerDetails() async {
    try {
      final shops = await sl<ConnectionService>().searchShops(widget.ownerUid);
      if (mounted) {
        setState(() {
          if (shops.isNotEmpty) {
            _ownerData = shops.first;
          } else {
            _error = "Shop not found. Please check the QR code or ID.";
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Error fetching details: $e";
        });
      }
    }
  }

  Future<void> _confirmJoin() async {
    setState(() => _isLinking = true);
    try {
      // Use ConnectionService to link shop
      await sl<ConnectionService>().linkShop(widget.ownerUid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Successfully linked to shop!")),
        );
        // Navigate to dashboard
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLinking = false);
        _showError("Failed to link: $e");
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeStateProvider);
    final isDark = theme.isDark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
      appBar: AppBar(
        title: const Text("Confirm Shop"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      body: _ownerData == null && _error == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Go Back"),
                    ),
                  ],
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Shop Card in Glassmorphism style
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.grey.shade200,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.store_rounded,
                            size: 40,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _ownerData?['shopName'] ??
                              _ownerData?['shopId'] ??
                              "Unknown Shop",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _ownerData?['ownerName'] ?? "Unknown Owner",
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _infoRow(
                          Icons.location_on,
                          _ownerData?['shopAddress'] ?? "No address",
                          isDark,
                        ),
                        const SizedBox(height: 12),
                        _infoRow(
                          Icons.phone,
                          _ownerData?['phone'] ?? "No phone",
                          isDark,
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLinking ? null : _confirmJoin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isLinking
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Confirm & Join Shop",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _infoRow(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 18, color: isDark ? Colors.white54 : Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

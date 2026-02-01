import 'package:flutter/material.dart';
import '../core/theme/futuristic_colors.dart';
import '../services/connection_service.dart';
import '../core/di/service_locator.dart';

class CustomerLinkAcceptScreen extends StatefulWidget {
  const CustomerLinkAcceptScreen({super.key});

  @override
  State<CustomerLinkAcceptScreen> createState() =>
      _CustomerLinkAcceptScreenState();
}

class _CustomerLinkAcceptScreenState extends State<CustomerLinkAcceptScreen> {
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController codeCtrl = TextEditingController();

  bool isLoading = false;
  bool isLinked = false;

  Future<void> _acceptLink() async {
    final phone = phoneCtrl.text.trim();
    final code = codeCtrl.text.trim();

    if (phone.isEmpty || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid 10-digit phone')),
      );
      return;
    }

    if (code.isEmpty || code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter 6-digit link code')),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final success =
          await sl<ConnectionService>().verifyLinkRequest(phone, code);

      if (success) {
        setState(() {
          isLinked = true;
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profile linked successfully!'),
            duration: Duration(seconds: 2),
          ),
        );

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            phoneCtrl.clear();
            codeCtrl.clear();
            setState(() => isLinked = false);
          }
        });
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Invalid code or expired')),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    phoneCtrl.dispose();
    codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Link Your Profile'),
        backgroundColor: Colors.purple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Accept Link from Business Owner',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ask your business owner for a 6-digit code and enter it below along with your phone number to link your profile.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Phone input
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: InputDecoration(
                hintText: '10-digit mobile',
                prefixIcon: const Icon(Icons.phone, color: Colors.purple),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.purple.shade50,
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),

            // Code input
            TextField(
              controller: codeCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                hintText: '6-digit code',
                prefixIcon: const Icon(Icons.vpn_key, color: Colors.purple),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.purple.shade50,
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),

            // Accept button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isLoading ? null : _acceptLink,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                child: isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Accept Link',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),

            if (isLinked) ...[
              const SizedBox(height: 24),
              Card(
                color: FuturisticColors.paidBackground,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: FuturisticColors.success, size: 32),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Profile Linked!',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: FuturisticColors.success)),
                            SizedBox(height: 4),
                            Text(
                                'You will now receive bills and reminders automatically',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Info card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ℹ️ About Linking:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  SizedBox(height: 8),
                  Text(
                      '• Linking connects your phone number to your owner\'s business',
                      style: TextStyle(fontSize: 11)),
                  Text(
                      '• All bills created for your phone will appear in your portal',
                      style: TextStyle(fontSize: 11)),
                  Text(
                      '• You can view pending dues, purchase history, and make payments',
                      style: TextStyle(fontSize: 11)),
                  Text('• Codes expire after 30 minutes',
                      style: TextStyle(fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../dashboard/presentation/screens/dashboard_controller.dart';
import '../../../customers/presentation/screens/customer_home_screen.dart';
import '../../../../screens/professional_startup_screen.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/session/session_manager.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sl<SessionManager>(),
      builder: (context, _) {
        final session = sl<SessionManager>();

        // 1. Connection State: Waiting (Handled by SessionManager's internal state)
        if (!session.isInitialized || session.isLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Loading your profile..."),
                ],
              ),
            ),
          );
        }

        // 2. No User -> Show Landing Screen
        if (!session.isAuthenticated) {
          return const ProfessionalStartupScreen();
        }

        // 3. User Logged In -> Navigate based on Role
        if (session.isOwner) {
          return const DashboardController();
        } else if (session.isCustomer) {
          return CustomerHomeScreen(customerId: session.userId!);
        } else {
          // Unknown role or error, default to owner onboarding if unassigned
          return const DashboardController();
        }
      },
    );
  }
}

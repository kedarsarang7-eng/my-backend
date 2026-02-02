// ============================================================================
// AUTH GATE - SINGLE ENTRY POINT
// ============================================================================
// The ONLY entry point after app launch
// Controls ALL navigation based on authentication and role state
//
// RULES:
// 1. Login success NEVER directly navigates to any dashboard
// 2. ALL navigation passes through this gate
// 3. Role MUST be confirmed before showing any dashboard
// 4. Unknown/error role → force logout
//
// Author: DukanX Engineering
// Version: 1.0.0
// ============================================================================

import 'package:flutter/material.dart';
import '../di/service_locator.dart';
import '../session/session_manager.dart';
import 'auth_loading_screen.dart';
import 'auth_error_screen.dart';

// Dashboards
import '../../features/dashboard/presentation/screens/owner_dashboard_screen.dart';
import '../../features/customers/presentation/screens/customer_home_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_selection_screen.dart';
import '../../features/auth/presentation/screens/customer_auth_screen.dart';
import '../../features/patient/presentation/screens/patient_home_screen.dart';

// Onboarding
import '../../features/onboarding/onboarding_models.dart';
import '../../features/onboarding/vendor_onboarding_screen.dart';
import '../../features/onboarding/login_onboarding_screen.dart';

// Guards
import '../../guards/license_guard.dart';

// Localization
import '../localization/localization_service.dart';
import '../../features/localization/presentation/screens/language_selection_screen.dart';

/// AuthGate - Single Entry Point for Authentication & Navigation
///
/// This widget:
/// 1. Listens to SessionManager for auth state changes
/// 2. Shows loading while auth is being resolved
/// 3. Routes to correct dashboard based on confirmed role
/// 4. Forces logout on unknown/error role
/// 5. NEVER assumes a default role
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _hasCheckedOnboarding = false;
  bool _needsLanguageSelection = false;
  bool _needsVendorOnboarding = false;
  bool _needsLoginOnboarding = false;

  @override
  void initState() {
    super.initState();
    debugPrint('[AuthGate] Initialized');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sl<SessionManager>(),
      builder: (context, _) {
        final session = sl<SessionManager>();

        debugPrint(
          '[AuthGate] Building - initialized: ${session.isInitialized}, '
          'loading: ${session.isLoading}, '
          'authenticated: ${session.isAuthenticated}, '
          'role: ${session.currentSession.role}',
        );

        // ============================================
        // STATE 1: Loading / Initializing
        // ============================================
        if (!session.isInitialized || session.isLoading) {
          return const AuthLoadingScreen(message: 'Initializing...');
        }

        // ============================================
        // STATE 1.5: Enforced Customer Mode
        // ============================================
        if (session.isCustomerOnlyMode) {
          // If logged in as Owner in Customer Mode -> Force Logout immediately
          if (session.isOwner) {
            debugPrint(
              '[AuthGate] Owner logged in during Customer Only Mode -> Forcing Logout',
            );
            // We can't await here easily, but we can schedule it
            WidgetsBinding.instance.addPostFrameCallback((_) {
              session.signOut();
            });
            return const AuthLoadingScreen(
              message: 'Switching to Customer Mode...',
            );
          }

          // If not authenticated, show Customer Auth directly (No Dashboard Selection)
          if (!session.isAuthenticated) {
            return const CustomerAuthScreen();
          }

          // If authenticated as customer, allow flow
          if (session.isCustomer) {
            return _buildCustomerFlow(session);
          }
        }

        // ============================================
        // STATE 2: Not Authenticated
        // ============================================
        if (!session.isAuthenticated) {
          // Show dashboard selection (vendor vs customer login)
          return const DashboardSelectionScreen();
        }

        // ============================================
        // STATE 3: Authenticated - Check Role
        // ============================================
        final role = session.currentSession.role;

        switch (role) {
          case UserRole.owner:
            // CRITICAL: Double check mode just in case
            if (session.isCustomerOnlyMode) {
              return const AuthErrorScreen(
                errorMessage: 'This app is locked to Customer Mode.',
                errorCode: 'MODE_LOCKED',
              ); // Should have been caught above, but safe fallback
            }
            return _buildVendorFlow(session);

          case UserRole.customer:
            return _buildCustomerFlow(session);

          case UserRole.patient:
            return const PatientHomeScreen();

          case UserRole.unknown:
            // Unknown role - show error and force logout
            return AuthErrorScreen(
              errorMessage:
                  'Unable to determine your account type. '
                  'Please contact support or try logging in again.',
              errorCode: 'ROLE_UNKNOWN',
              onRetry: () => _handleRetry(),
            );
        }
      },
    );
  }

  /// Build vendor/owner flow with onboarding checks
  Widget _buildVendorFlow(SessionManager session) {
    // Check onboarding status
    if (!_hasCheckedOnboarding) {
      return FutureBuilder<_OnboardingStatus>(
        future: _checkVendorOnboarding(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AuthLoadingScreen(message: 'Setting up your shop...');
          }

          if (snapshot.hasError) {
            return AuthErrorScreen(
              errorMessage: 'Failed to load your settings. Please try again.',
              errorCode: 'ONBOARDING_ERROR',
              onRetry: () => setState(() => _hasCheckedOnboarding = false),
            );
          }

          final status = snapshot.data!;
          _hasCheckedOnboarding = true;
          _needsLanguageSelection = status.needsLanguageSelection;
          _needsVendorOnboarding = status.needsVendorOnboarding;
          _needsLoginOnboarding = status.needsLoginOnboarding;

          return _resolveVendorScreen();
        },
      );
    }

    return _resolveVendorScreen();
  }

  Widget _resolveVendorScreen() {
    // LANGUAGE SELECTION FIRST - must happen before any onboarding
    // This ensures all onboarding screens are shown in user's language
    if (_needsLanguageSelection) {
      return const LanguageSelectionScreen();
    }

    // VendorOnboardingScreen and LoginOnboardingScreen navigate to
    // /owner_dashboard themselves after completion.
    if (_needsVendorOnboarding) {
      // Vendor onboarding navigates to dashboard on its own
      return const VendorOnboardingScreen();
    }

    if (_needsLoginOnboarding) {
      // Login onboarding navigates to dashboard on its own
      return const LoginOnboardingScreen();
    }

    // All onboarding complete - show vendor dashboard protected by license
    return LicenseGuard(
      businessType: sl<SessionManager>().activeBusinessType,
      child: const ProfessionalOwnerDashboard(),
    );
  }

  /// Build customer flow
  Widget _buildCustomerFlow(SessionManager session) {
    // Customers go directly to dashboard
    return CustomerHomeScreen(
      key: const ValueKey('customer_dashboard'),
      customerId: session.userId ?? '',
    );
  }

  /// Check vendor onboarding status (including language selection)
  Future<_OnboardingStatus> _checkVendorOnboarding() async {
    final localizationService = LocalizationService();
    final signupService = OnboardingService();
    final loginService = LoginOnboardingService();

    final needsLanguage = !(await localizationService
        .hasCompletedLanguageSelection());
    final needsSignup = !(await signupService.isOnboardingCompleted());
    final needsLogin = !(await loginService.hasSeenLoginOnboarding());

    return _OnboardingStatus(
      needsLanguageSelection: needsLanguage,
      needsVendorOnboarding: needsSignup,
      needsLoginOnboarding: needsLogin,
    );
  }

  /// Handle retry after error
  Future<void> _handleRetry() async {
    setState(() {
      _hasCheckedOnboarding = false;
    });

    try {
      await sl<SessionManager>().refreshSession();
    } catch (e) {
      debugPrint('[AuthGate] Retry failed: $e');
    }
  }
}

/// Internal class to hold onboarding status
class _OnboardingStatus {
  final bool needsLanguageSelection;
  final bool needsVendorOnboarding;
  final bool needsLoginOnboarding;

  _OnboardingStatus({
    required this.needsLanguageSelection,
    required this.needsVendorOnboarding,
    required this.needsLoginOnboarding,
  });
}

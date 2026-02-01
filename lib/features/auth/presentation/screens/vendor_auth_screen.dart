import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../core/auth/auth_intent_service.dart';
import '../../../../services/google_signin_service.dart';

import '../../../../core/repository/shop_repository.dart';
import '../widgets/fast_login_options.dart';
import '../widgets/security_upgrade_prompt.dart';
import '../../services/biometric_service.dart';
import '../../services/pin_service.dart';

/// Vendor Authentication Screen - Matches reference design
/// Space theme with glowing logo, login/signup forms
class VendorAuthScreen extends StatefulWidget {
  const VendorAuthScreen({super.key});

  @override
  State<VendorAuthScreen> createState() => _VendorAuthScreenState();
}

class _VendorAuthScreenState extends State<VendorAuthScreen>
    with TickerProviderStateMixin {
  // Controllers
  final _formKey = GlobalKey<FormState>();
  final _vendorNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // State
  bool _isLogin = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _generatedOwnerId;

  final _shopRepository = sl<ShopRepository>();

  // Animation
  late AnimationController _glowController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  // Theme Colors
  static const _primaryCyan = Color(0xFF00D4FF);
  static const _bgDark = Color(0xFF0B0D1F);

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _fadeController.dispose();
    _vendorNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Generate unique Owner ID: DX-VND-[timestamp]-[random4]
  String _generateOwnerId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final random = math.Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random4 =
        List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
    return 'DX-VND-$timestamp-$random4';
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await _handleLogin();
      } else {
        await _handleSignup();
      }
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      String message = _getFirebaseAuthErrorMessage(e.code);
      _showError(message);
    } catch (e) {
      final errorStr = e.toString();
      // Check for App Check specific errors
      if (errorStr.contains('firebase-app-check-token-is-invalid') ||
          errorStr.contains('app-check')) {
        _showError(
            'Security verification failed. Please restart the app and try again.');
        debugPrint('App Check Error: $e');
      } else {
        _showError(errorStr.replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Convert Firebase Auth error codes to user-friendly messages
  String _getFirebaseAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email. Please sign up first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters.';
      case 'firebase-app-check-token-is-invalid':
        return 'Security verification failed. Please restart the app.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'Authentication failed: $code';
    }
  }

  Future<void> _handleLogin() async {
    // Ensure intent is set (guard)
    await authIntent.initialize();
    if (!authIntent.isVendorIntent) {
      throw Exception('Invalid flow. Please select Vendor Dashboard first.');
    }

    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    // Force session refresh to get latest role
    final session = sl<SessionManager>();
    await session.refreshSession();

    if (!mounted) return;

    // STRICT ROLE VALIDATION
    final validationResult = authIntent.validateRole(
      session.isOwner
          ? 'vendor'
          : session.isCustomer
              ? 'customer'
              : null,
    );

    if (validationResult == RoleValidationResult.mismatch) {
      // BLOCK: Wrong login portal used
      final errorMessage = authIntent.getMismatchErrorMessage(
        session.isCustomer ? 'customer' : 'unknown',
      );

      // Sign out immediately
      await FirebaseAuth.instance.signOut();
      await authIntent.clearIntent();

      throw Exception(errorMessage);
    }

    // SUCCESS: Clear intent and navigate to AuthGate for role-based routing
    await authIntent.clearIntent();
    if (!mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil('/auth_gate', (route) => false);
  }

  Future<void> _handleSignup() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      throw Exception("Passwords do not match");
    }

    if (_passwordController.text.length < 8) {
      throw Exception("Password must be at least 8 characters");
    }

    debugPrint('VendorAuth: Starting signup...');

    // Set Intent BEFORE creating user
    await authIntent.setVendorIntent();

    // Create Firebase Auth user
    final userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
    final user = userCredential.user!;
    debugPrint('VendorAuth: Firebase user created: ${user.uid}');

    final ownerId = _generatedOwnerId ?? _generateOwnerId();
    debugPrint('VendorAuth: Generated ownerId: $ownerId');

    // Create local shop profile via Repository
    try {
      await _shopRepository.updateShopProfile(
        ownerId: user.uid,
        shopName: _vendorNameController.text.trim(),
        phone: _mobileController.text.trim(),
        email: _emailController.text.trim(),
      );
      debugPrint('VendorAuth: Local shop profile created');
    } catch (e) {
      debugPrint('VendorAuth: Repository error: $e');
    }

    if (!mounted) return;

    // Navigate directly to dashboard
    _navigateToDashboard();
  }

  void _navigateToDashboard() {
    debugPrint('VendorAuth: Navigating to AuthGate...');
    // Show quick success message
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 12),
          Text("Login successful!", style: GoogleFonts.outfit()),
        ],
      ),
      backgroundColor: const Color(0xFF00FF88).withOpacity(0.9),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));

    // Check for security upgrade
    _checkSecurityUpgrade().then((_) {
      if (!mounted) return;
      // Navigate to AuthGate - let it handle role-based routing
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/auth_gate',
        (route) => false,
      );
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: GoogleFonts.outfit(color: Colors.white)),
      backgroundColor: Colors.red.withOpacity(0.9),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: Stack(
        children: [
          // Space background
          _SpaceBackground(),

          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  // Top bar
                  _buildTopBar(),

                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),

                          // Glowing logo
                          _GlowingLogo(controller: _glowController),

                          const SizedBox(height: 30),

                          // Title
                          Text(
                            _isLogin
                                ? "Vendor Login"
                                : "Create Vendor\nAccount",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isLogin
                                ? "Log in to manage your vendor account"
                                : "Create an account to get started",
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Form
                          _buildForm(),

                          const SizedBox(height: 20),

                          // Toggle login/signup
                          _buildToggle(),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),

                  // Bottom glow
                  _BottomGlow(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!_isLogin)
            GestureDetector(
              onTap: () => setState(() => _isLogin = true),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white.withOpacity(0.7),
                  size: 20,
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white.withOpacity(0.7),
                  size: 20,
                ),
              ),
            ),
          Icon(
            Icons.menu,
            color: Colors.white.withOpacity(0.7),
            size: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(
          color: _primaryCyan.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isLogin) ...[
              // Vendor Name
              _buildTextField(
                label: "Vendor Name",
                controller: _vendorNameController,
                icon: Icons.store_rounded,
              ),
              const SizedBox(height: 16),

              // Owner ID (auto-generated)
              _buildOwnerIdField(),
              const SizedBox(height: 16),

              // Mobile Number
              _buildTextField(
                label: "Mobile Number",
                controller: _mobileController,
                icon: Icons.phone_android,
                keyboardType: TextInputType.phone,
                prefixText: "+91 ",
              ),
              const SizedBox(height: 16),
            ],

            // Email
            _buildTextField(
              label: "Email ID",
              controller: _emailController,
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Password
            _buildTextField(
              label: "Password",
              controller: _passwordController,
              icon: Icons.lock_outline,
              isPassword: true,
              obscure: _obscurePassword,
              onVisToggle: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),

            if (!_isLogin) ...[
              const SizedBox(height: 8),
              // Password validation hints
              if (_passwordController.text.isNotEmpty &&
                  _passwordController.text.length < 8)
                Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.orange.shade400, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      "Password must be at least 8 characters",
                      style: GoogleFonts.outfit(
                        color: Colors.orange.shade400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),

              // Confirm Password
              _buildTextField(
                label: "Confirm Password",
                controller: _confirmPasswordController,
                icon: Icons.lock_outline,
                isPassword: true,
                obscure: _obscureConfirmPassword,
                onVisToggle: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
              const SizedBox(height: 8),
              // Password match hint
              if (_confirmPasswordController.text.isNotEmpty &&
                  _confirmPasswordController.text != _passwordController.text)
                Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.orange.shade400, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      "Passwords do not match",
                      style: GoogleFonts.outfit(
                        color: Colors.orange.shade400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
            ],

            if (_isLogin) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/forgot_password'),
                  child: Text(
                    "Forgot password?",
                    style: GoogleFonts.outfit(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

              // Fast Login Options
              FastLoginOptions(
                onBiometricSuccess: () async {
                  final session = sl<SessionManager>();
                  await session.refreshSession();
                  if (mounted) {
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/auth_gate', (r) => false);
                  }
                },
                onPinSuccess: () async {
                  final session = sl<SessionManager>();
                  await session.refreshSession();
                  if (mounted) {
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/auth_gate', (r) => false);
                  }
                },
              ),
            ],

            const SizedBox(height: 24),

            // Submit Button
            _buildSubmitButton(),

            const SizedBox(height: 16),

            // Divider
            _buildDivider(),

            const SizedBox(height: 16),

            // Google Sign-In Button
            _buildGoogleButton(),
          ],
        ),
      ),
    );
  }

  /// Handle Google Sign-In
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);

    try {
      // Set vendor intent
      await authIntent.setVendorIntent();

      final userCredential = await GoogleSignInService().signIn();
      if (userCredential == null) {
        throw Exception('Google Sign-In cancelled');
      }

      final user = userCredential.user!;
      debugPrint('VendorAuth: Google user: ${user.uid}');

      // Force session refresh
      final session = sl<SessionManager>();
      await session.refreshSession();

      if (!mounted) return;

      // Check if new user (no role yet)
      if (!session.isOwner && !session.isCustomer) {
        // Auto-create vendor profile
        await _shopRepository.updateShopProfile(
          ownerId: user.uid,
          shopName: user.displayName ?? 'My Shop',
          email: user.email ?? '',
        );
        debugPrint('VendorAuth: Auto-created vendor profile');
      }

      // Navigate to dashboard
      await authIntent.clearIntent();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/auth_gate', (r) => false);

      // Check for security upgrade
      _checkSecurityUpgrade();
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: GoogleFonts.outfit(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white.withOpacity(0.3)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.white.withOpacity(0.05),
        ),
        child: _isGoogleLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/images/google_logo.svg',
                    width: 20,
                    height: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Continue with Google',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildOwnerIdField() {
    // Generate ID if not already generated
    _generatedOwnerId ??= _generateOwnerId();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Owner ID",
          style: GoogleFonts.outfit(
            color: Colors.white.withOpacity(0.7),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.black.withOpacity(0.3),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Icon(Icons.badge_outlined,
                  color: _primaryCyan.withOpacity(0.7), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _generatedOwnerId!,
                  style: GoogleFonts.shareTechMono(
                    color: _primaryCyan,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: _primaryCyan.withOpacity(0.15),
                ),
                child: Text(
                  "AUTO",
                  style: GoogleFonts.outfit(
                    color: _primaryCyan,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onVisToggle,
    String? prefixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white.withOpacity(0.7),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
          onChanged: (_) => setState(() {}), // For validation hints
          validator: (val) {
            if (val == null || val.isEmpty) return "Required";
            if (label.contains("Email") && !val.contains("@")) {
              return "Invalid email";
            }
            return null;
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black.withOpacity(0.3),
            prefixIcon:
                Icon(icon, color: _primaryCyan.withOpacity(0.7), size: 20),
            prefixText: prefixText,
            prefixStyle: GoogleFonts.outfit(color: Colors.white70),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white.withOpacity(0.4),
                      size: 20,
                    ),
                    onPressed: onVisToggle,
                  )
                : (controller.text.isNotEmpty
                    ? Icon(Icons.check_circle,
                        color: _primaryCyan.withOpacity(0.7), size: 20)
                    : null),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _primaryCyan.withOpacity(0.5)),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleAuth,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00D4FF), Color(0xFF0EA5E9)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: _primaryCyan.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    _isLogin ? "Login" : "Create Account",
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin ? "Don't have an account?" : "Already have an account?",
          style: GoogleFonts.outfit(
            color: Colors.white.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: () => setState(() {
            _isLogin = !_isLogin;
            _generatedOwnerId = null; // Reset for new signup
          }),
          child: Text(
            _isLogin ? "Create Account" : "Log in",
            style: GoogleFonts.outfit(
              color: _primaryCyan,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: _primaryCyan,
            ),
          ),
        ),
        if (!_isLogin) Icon(Icons.chevron_right, color: _primaryCyan, size: 18),
      ],
    );
  }

  Future<void> _checkSecurityUpgrade() async {
    if (!mounted) return;
    final bioEnabled = await biometricService.isBiometricsEnabled();
    final pinEnabled = await pinService.isPinSet();

    if (!bioEnabled && !pinEnabled) {
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => SecurityUpgradePrompt(
            onDismiss: () => Navigator.pop(context),
          ),
        );
      }
    }
  }
}

// ============================================================================
// SHARED WIDGETS
// ============================================================================

/// Glowing circular logo with rainbow gradient ring
class _GlowingLogo extends StatelessWidget {
  final AnimationController controller;

  const _GlowingLogo({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00D4FF).withOpacity(0.4),
                blurRadius: 40,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: const Color(0xFFAB5CF6).withOpacity(0.3),
                blurRadius: 60,
                spreadRadius: 10,
              ),
            ],
          ),
          child: CustomPaint(
            painter: _GlowRingPainter(progress: controller.value),
            child: Center(
              child: Container(
                width: 95,
                height: 95,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0B0D1F),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF00D4FF), Color(0xFFAB5CF6)],
                      ).createShader(bounds),
                      child: Text(
                        "dukanX",
                        style: GoogleFonts.orbitron(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Custom painter for the rainbow glow ring
class _GlowRingPainter extends CustomPainter {
  final double progress;

  _GlowRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;

    final gradient = SweepGradient(
      startAngle: progress * 2 * math.pi,
      colors: const [
        Color(0xFF00D4FF),
        Color(0xFF00FF88),
        Color(0xFFFFDD00),
        Color(0xFFFF6B00),
        Color(0xFFFF00FF),
        Color(0xFFAB5CF6),
        Color(0xFF00D4FF),
      ],
    );

    final paint = Paint()
      ..shader =
          gradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _GlowRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Space background with stars
class _SpaceBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0B0D1F),
            Color(0xFF0F1B3D),
            Color(0xFF0B0D1F),
          ],
        ),
      ),
      child: Stack(
        children: [
          ...List.generate(50, (index) {
            final random = math.Random(index);
            return Positioned(
              left: random.nextDouble() * MediaQuery.of(context).size.width,
              top: random.nextDouble() * MediaQuery.of(context).size.height,
              child: Container(
                width: random.nextDouble() * 2 + 1,
                height: random.nextDouble() * 2 + 1,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      Colors.white.withOpacity(random.nextDouble() * 0.5 + 0.2),
                ),
              ),
            );
          }),
          Positioned(
            right: -100,
            top: MediaQuery.of(context).size.height * 0.3,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF1E3A8A).withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom glow effect
class _BottomGlow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.5,
          colors: [
            const Color(0xFF00D4FF).withOpacity(0.15),
            const Color(0xFFAB5CF6).withOpacity(0.1),
            Colors.transparent,
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 150,
          height: 3,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: const LinearGradient(
              colors: [
                Colors.transparent,
                Color(0xFF00D4FF),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Success Screen after account creation
class _SuccessScreen extends StatefulWidget {
  final String message;
  final String subMessage;
  final VoidCallback onContinue;

  const _SuccessScreen({
    required this.message,
    required this.subMessage,
    required this.onContinue,
  });

  @override
  State<_SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<_SuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();

    // Auto-continue after delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) widget.onContinue();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D1F),
      body: Stack(
        children: [
          _SpaceBackground(),
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Icon(
                      Icons.history,
                      color: Colors.white.withOpacity(0.7),
                      size: 28,
                    ),
                  ),
                ),

                const Spacer(),

                // Success checkmark
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF00D4FF).withOpacity(0.1),
                      border: Border.all(
                        color: const Color(0xFF00D4FF).withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00D4FF).withOpacity(0.3),
                          blurRadius: 40,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Color(0xFF00D4FF),
                      size: 60,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                Text(
                  widget.message,
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const Spacer(),

                // Bottom message
                Container(
                  margin: const EdgeInsets.all(24),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withOpacity(0.05),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check,
                          color: const Color(0xFF00FF88), size: 20),
                      const SizedBox(width: 10),
                      Text(
                        widget.subMessage,
                        style: GoogleFonts.outfit(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                _BottomGlow(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

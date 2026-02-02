import 'package:flutter/material.dart';

/// Futuristic Color Palette for DukanX Desktop Redesign
class FuturisticColors {
  // Backgrounds - Deep Space Enterprise
  static const Color background = Color(0xFF0F172A); // Slate 900
  static const Color surface = Color(0xFF1E293B); // Slate 800
  static const Color surfaceGlass = Color(0xCC1E293B); // Translucent Slate 800

  // Primary Actions - Neon Cyan/Blue
  static const Color primary = Color(0xFF3B82F6); // Blue 500
  static const Color primaryDark = Color(0xFF1D4ED8); // Blue 700
  static const Color accent1 = Color(0xFF06B6D4); // Cyan 500
  static const Color accent2 = Color(0xFF8B5CF6); // Violet 500

  // Status Colors (Vibrant but legible)
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color info = Color(0xFF3B82F6); // Blue 500

  // Text
  static const Color textPrimary = Color(0xFFF8FAFC); // Slate 50
  static const Color textSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color textDisabled = Color(0xFF64748B); // Slate 500

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, accent1],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [
      Color(0x1A38BDF8), // Sky 400 with low opacity
      Color(0x0538BDF8),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkBackgroundGradient = LinearGradient(
    colors: [background, Color(0xFF020617)], // Slate 900 -> Slate 950
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadows/Glows
  static List<BoxShadow> neonShadow(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.25),
      blurRadius: 16,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> glassShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  // ===========================================================================
  // LEGACY COMPATIBILITY LAYER (To fix existing lints)
  // ===========================================================================
  static const Color secondary = accent1;
  static const Color accent = accent2;
  static const Color textMuted = textSecondary;
  static const Color darkBackground = background;
  static const Color darkSurface = surface;
  static const Color darkTextPrimary = textPrimary;
  static const Color darkTextSecondary = textSecondary;
  static Color darkDivider = Colors.white.withOpacity(0.1);
  static Color divider = Colors.white.withOpacity(0.1);

  static const LinearGradient lightBackgroundGradient = darkBackgroundGradient;

  static const LinearGradient errorGradient = LinearGradient(
    colors: [error, Color(0xFF991B1B)], // Red 500 -> Red 800
  );

  static const Color neonBlue = accent1;
  static const Color backgroundDark = background;
  static const Color paidBackground = Color(0xFF064E3B); // Emerald 900
  static const Color unpaidBackground = Color(0xFF7F1D1D); // Red 900

  static const LinearGradient successGradient = LinearGradient(
    colors: [success, Color(0xFF065F46)], // Emerald 500 -> Emerald 800
  );

  static const Color paid = success;
  static const Color unpaid = error;
  static const Color primaryLight = primary;
  static const Color darkSurfaceVariant = surface;
  static const Color surfaceVariant = surface;
  static const Color textHint = textDisabled;
  static const Color darkTextMuted = textSecondary;
  static const Color darkSurfaceElevated = surface;
  static const Color surfaceElevated = Color(0xFF334155); // Slate 700
  static const Color white = Colors.white;
  static const Color glassBorder = Color(0x1AFFFFFF);
  static const Color glassBorderDark = Color(0x1AFFFFFF);

  static const LinearGradient warningGradient = LinearGradient(
    colors: [warning, Color(0xFF92400E)], // Amber 500 -> Amber 800
  );

  static const Color successDark = Color(0xFF064E3B);
  static const Color errorDark = Color(0xFF7F1D1D);
  static const Color warningDark = Color(0xFF78350F);
  static const Color accent3 = accent2;
  static const Color secondaryLight = accent1;
  static const Color primaryLight2 = primary; // Fallback

  // Modern UI Aliases
  static const Color surfaceHighlight = Color(0xFF334155); // Slate 700
  static const Color cardBackground = surface;
  static const Color border = Color(0xFF334155); // Slate 700
  static const Color iconPrimary = textPrimary;

  // ===========================================================================
  // PREMIUM UI ENHANCEMENT - Futuristic Accents
  // ===========================================================================

  /// Premium blue accent for futuristic UI (matches reference image)
  static const Color premiumBlue = Color(0xFF00D4FF);
  static const Color premiumBlueDark = Color(0xFF0099CC);
  static const Color premiumBlueGlow = Color(0xFF00D4FF);

  /// Generate premium glow box shadow for cards and buttons
  static List<BoxShadow> premiumGlow({
    Color? color,
    double blurRadius = 12,
    double spreadRadius = 0,
    double opacity = 0.3,
  }) => [
    BoxShadow(
      color: (color ?? premiumBlue).withOpacity(opacity),
      blurRadius: blurRadius,
      spreadRadius: spreadRadius,
    ),
  ];

  /// Premium card border with glow effect
  static BoxDecoration premiumCardDecoration({
    Color? borderColor,
    double borderWidth = 1,
    double borderRadius = 12,
    Color? backgroundColor,
  }) => BoxDecoration(
    color: backgroundColor ?? surface,
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(
      color: (borderColor ?? premiumBlue).withOpacity(0.3),
      width: borderWidth,
    ),
    boxShadow: [
      BoxShadow(
        color: (borderColor ?? premiumBlue).withOpacity(0.1),
        blurRadius: 8,
        spreadRadius: 0,
      ),
    ],
  );

  /// Starfield overlay gradient for background texture
  static const LinearGradient starfieldOverlay = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x05FFFFFF), // Very subtle white stars effect
      Color(0x02FFFFFF),
      Color(0x05FFFFFF),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  /// Premium top bar gradient with subtle blue accent
  static const LinearGradient premiumTopBarGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0F172A), // Background
      Color(0xFF0D1526), // Slightly darker
    ],
  );

  /// Icon glow decoration for sidebar icons with blue accent
  static BoxDecoration iconGlowDecoration({
    Color? accentColor,
    bool isActive = false,
  }) => BoxDecoration(
    color: (accentColor ?? premiumBlue).withOpacity(isActive ? 0.2 : 0.1),
    borderRadius: BorderRadius.circular(10),
    boxShadow: isActive
        ? [
            BoxShadow(
              color: (accentColor ?? premiumBlue).withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ]
        : null,
  );

  /// Premium content area background decoration with star effect support
  static BoxDecoration premiumContentBackground({Color? backgroundColor}) =>
      BoxDecoration(
        color: backgroundColor ?? background,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            background,
            Color(0xFF0A0F1C), // Slightly darker for depth
          ],
        ),
      );

  /// Top bar glow border for premium effect
  static Border topBarGlowBorder() =>
      Border(bottom: BorderSide(color: premiumBlue.withOpacity(0.2), width: 1));
}

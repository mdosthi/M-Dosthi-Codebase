import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Official mDosthi 5-Color Brand Logo Design Tokens:
/// Deep Navy (#083A82), Clinical Blue (#0E76BC), Medical Cyan-Teal (#0BA5AE),
/// Brand Emerald (#129A58), Fresh Leaf Green (#6AC242), and Soft Mint (#E8F8F1).
class BrandColors {
  BrandColors._();

  static const Color navy = Color(0xFF083A82);
  static const Color blue = Color(0xFF0E76BC);
  static const Color cyanTeal = Color(0xFF0BA5AE);
  static const Color teal = Color(0xFF129A58);
  static const Color green = Color(0xFF6AC242);
  static const Color ice = Color(0xFFE8F8F1);
  static const Color light = ice;

  static const Color navyDark = Color(0xFF052659);
  static const Color tealDark = Color(0xFF0D7A46);
  static const Color emerald = Color(0xFF129A58);
  static const Color cyanBg = Color(0xFFE6F7F8);
  static const Color mintBg = Color(0xFFD6F5E3);
  static const Color donateText = Color(0xFF0D7A46);
  static const Color bodyInk = Color(0xFF1F3B4D);
  static const Color mutedInk = Color(0xFF4A6875);
  static const Color pageBg = Color(0xFFF3FAF8);
  static const Color borderSubtle = Color(0xFFCBEAD9);

  /// Primary CTA Gradient: linear-gradient(135deg, #129A58 0%, #0BA5AE 54%, #0E76BC 100%)
  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      teal,
      cyanTeal,
      blue,
    ],
    stops: [0.0, 0.54, 1.0],
  );

  /// Hero Header Gradient (Full Logo Spectrum: Navy -> Clinical Blue -> Cyan-Teal -> Emerald)
  static const LinearGradient heroHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      navy,
      blue,
      cyanTeal,
      teal,
    ],
    stops: [0.0, 0.34, 0.68, 1.0],
  );

  static const LinearGradient activeTabGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      teal,
      cyanTeal,
    ],
  );

  static const LinearGradient softPageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      ice,
      Color(0xFFF2FAFC),
      Colors.white,
    ],
  );
}

/// Official mDosthi Typography:
/// Poppins (Headings), Inter (Body), Lora (Subtext / Subtitles).
class BrandTypography {
  BrandTypography._();

  static TextStyle heading({
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w700,
    Color color = BrandColors.navy,
    double? height,
    double letterSpacing = -0.3,
  }) {
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle body({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = BrandColors.bodyInk,
    double? height,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  static TextStyle subtitle({
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w500,
    FontStyle fontStyle = FontStyle.italic,
    Color color = BrandColors.navy,
    double? height,
  }) {
    return GoogleFonts.lora(
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      color: color,
      height: height,
    );
  }
}

class BrandTheme {
  BrandTheme._();

  static ThemeData get lightTheme {
    final baseText = GoogleFonts.interTextTheme();
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: BrandColors.pageBg,
      colorScheme: const ColorScheme.light(
        primary: BrandColors.teal,
        onPrimary: Colors.white,
        primaryContainer: BrandColors.ice,
        onPrimaryContainer: BrandColors.navy,
        secondary: BrandColors.blue,
        onSecondary: Colors.white,
        secondaryContainer: BrandColors.mintBg,
        onSecondaryContainer: BrandColors.navy,
        tertiary: BrandColors.green,
        surface: Colors.white,
        onSurface: BrandColors.navy,
        onSurfaceVariant: BrandColors.mutedInk,
        outlineVariant: BrandColors.borderSubtle,
      ),
      textTheme: baseText.copyWith(
        displayLarge: BrandTypography.heading(fontSize: 38, fontWeight: FontWeight.w800),
        displayMedium: BrandTypography.heading(fontSize: 32, fontWeight: FontWeight.w700),
        headlineMedium: BrandTypography.heading(fontSize: 24, fontWeight: FontWeight.w700),
        titleLarge: BrandTypography.heading(fontSize: 20, fontWeight: FontWeight.w700),
        titleMedium: BrandTypography.heading(fontSize: 16, fontWeight: FontWeight.w600),
        titleSmall: BrandTypography.heading(fontSize: 14, fontWeight: FontWeight.w600),
        bodyLarge: BrandTypography.body(fontSize: 16),
        bodyMedium: BrandTypography.body(fontSize: 14),
        bodySmall: BrandTypography.subtitle(fontSize: 13),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: BrandColors.tealDark,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: BrandTypography.heading(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BrandColors.teal,
          foregroundColor: Colors.white,
          textStyle: BrandTypography.heading(fontSize: 14.5, fontWeight: FontWeight.w600, color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BrandColors.tealDark,
          side: const BorderSide(color: BrandColors.teal, width: 1.4),
          textStyle: BrandTypography.heading(fontSize: 14, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: BrandColors.tealDark,
          textStyle: BrandTypography.heading(fontSize: 14, fontWeight: FontWeight.w600, color: BrandColors.tealDark),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: BrandColors.teal,
        foregroundColor: Colors.white,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: BrandColors.teal,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return BrandColors.teal;
          return null;
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BrandColors.pageBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: BrandColors.teal.withOpacity(0.22)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: BrandColors.teal.withOpacity(0.22)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: BrandColors.teal, width: 1.8),
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
      ),
    );
  }
}

/// Primary Brand Wordmark ("m" in teal + "Dosthi" in deep navy)
class MdosthiWordmark extends StatelessWidget {
  final double fontSize;
  final bool showTagline;

  const MdosthiWordmark({
    super.key,
    this.fontSize = 36,
    this.showTagline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
            children: const [
              TextSpan(
                text: 'm',
                style: TextStyle(color: BrandColors.teal),
              ),
              TextSpan(
                text: 'Dosthi',
                style: TextStyle(color: BrandColors.navy),
              ),
            ],
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 4),
          Text(
            'Digital Health & Well-Being',
            textAlign: TextAlign.center,
            style: BrandTypography.body(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: BrandColors.navy,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '— Healthcare as Homecare —',
            textAlign: TextAlign.center,
            style: BrandTypography.heading(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: BrandColors.emerald,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Care  •  Support  •  Hope',
            textAlign: TextAlign.center,
            style: BrandTypography.subtitle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: BrandColors.navy,
            ),
          ),
        ],
      ],
    );
  }
}

/// Official mDosthi Primary Logo Banner (for splash, login, and official reports)
class MdosthiPrimaryLogo extends StatelessWidget {
  final double maxWidth;
  final double? height;
  final AlignmentGeometry alignment;

  const MdosthiPrimaryLogo({
    super.key,
    this.maxWidth = 300,
    this.height,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Image.asset(
        'assets/images/mdosthi-primary-logo.png',
        height: height,
        fit: BoxFit.contain,
        alignment: alignment,
        errorBuilder: (_, __, ___) =>
            const MdosthiWordmark(fontSize: 32, showTagline: true),
      ),
    );
  }
}

/// Official mDosthi Horizontal Logo (for top navbars, app bars, and report headers)
class MdosthiHorizontalLogo extends StatelessWidget {
  final double height;
  final double? maxWidth;
  final AlignmentGeometry alignment;

  const MdosthiHorizontalLogo({
    super.key,
    this.height = 36,
    this.maxWidth,
    this.alignment = Alignment.centerLeft,
  });

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/images/mdosthi-horizontal-logo.png',
      height: height,
      fit: BoxFit.contain,
      alignment: alignment,
      errorBuilder: (_, __, ___) => MdosthiWordmark(
        fontSize: (height * 0.56).clamp(16.0, 26.0),
      ),
    );
    if (maxWidth != null) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth!),
        child: image,
      );
    }
    return image;
  }
}

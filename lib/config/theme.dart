// lib/config/theme.dart - Enhanced version with missing properties
import 'package:flutter/material.dart';

enum ScreenSize { mobile, tablet, desktop }

class AppTheme {
  // Brand colors
  static const Color primaryColor = Color(0xFFF96A4C); // #feaf4e
  static const Color secondaryColor = Color(0xFFF96A4C); // #f96a4c
  static const Color accentColor = Color(0xFFE54481);
  static const Color backgroundColor = Color(0xFFFFF8F5);
  static const Color surfaceColor = Colors.white;
  static const Color errorColor = Color(0xFFE53E3E);
  static const Color successColor = Color(0xFF38A169);
  static const Color warningColor = Color(0xFFD69E2E);

  // Neutral colors
  static const Color textPrimary = Color(0xFF1A202C);
  static const Color textSecondary = Color(0xFF718096);
  static const Color textMuted = Color(0xFFA0AEC0);
  static const Color dividerColor = Color(0xFFE2E8F0);

// Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color(0xFFFEAF4E), // #feaf4e
      Color(0xFFF96A4C), // #f96a4c
      Color(0xFFE54481), // #e54481
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Responsive breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Spacing scale
  static const double space2xs = 4;
  static const double spaceXs = 8;
  static const double spaceSm = 12;
  static const double spaceMd = 16;
  static const double spaceLg = 20;
  static const double spaceXl = 24;
  static const double space2xl = 32;
  static const double space3xl = 48;

  // Get screen size category
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return ScreenSize.mobile;
    } else if (width < tabletBreakpoint) {
      return ScreenSize.tablet;
    } else {
      return ScreenSize.desktop;
    }
  }

  // Check if device is mobile
  static bool isMobile(BuildContext context) {
    return getScreenSize(context) == ScreenSize.mobile;
  }

  // Check if device is tablet
  static bool isTablet(BuildContext context) {
    return getScreenSize(context) == ScreenSize.tablet;
  }

  // Check if device is desktop
  static bool isDesktop(BuildContext context) {
    return getScreenSize(context) == ScreenSize.desktop;
  }

  // Responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return const EdgeInsets.all(spaceMd);
      case ScreenSize.tablet:
        return const EdgeInsets.all(spaceXl);
      case ScreenSize.desktop:
        return const EdgeInsets.all(space2xl);
    }
  }

  // Responsive horizontal padding
  static EdgeInsets getResponsiveHorizontalPadding(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return const EdgeInsets.symmetric(horizontal: spaceMd);
      case ScreenSize.tablet:
        return const EdgeInsets.symmetric(horizontal: spaceXl);
      case ScreenSize.desktop:
        return const EdgeInsets.symmetric(horizontal: space2xl);
    }
  }

  // Responsive vertical padding
  static EdgeInsets getResponsiveVerticalPadding(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return const EdgeInsets.symmetric(vertical: spaceMd);
      case ScreenSize.tablet:
        return const EdgeInsets.symmetric(vertical: spaceXl);
      case ScreenSize.desktop:
        return const EdgeInsets.symmetric(vertical: space2xl);
    }
  }

  // Responsive margin
  static EdgeInsets getResponsiveMargin(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return const EdgeInsets.all(spaceXs);
      case ScreenSize.tablet:
        return const EdgeInsets.all(spaceMd);
      case ScreenSize.desktop:
        return const EdgeInsets.all(spaceXl);
    }
  }

  // Responsive card padding
  static EdgeInsets getResponsiveCardPadding(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return const EdgeInsets.all(spaceSm);
      case ScreenSize.tablet:
        return const EdgeInsets.all(spaceMd);
      case ScreenSize.desktop:
        return const EdgeInsets.all(spaceLg);
    }
  }

  // Responsive font sizes
  static double getHeadlineFontSize(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return 24;
      case ScreenSize.tablet:
        return 28;
      case ScreenSize.desktop:
        return 32;
    }
  }

  static double getTitleFontSize(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return 18;
      case ScreenSize.tablet:
        return 20;
      case ScreenSize.desktop:
        return 22;
    }
  }

  static double getBodyFontSize(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return 14;
      case ScreenSize.tablet:
        return 15;
      case ScreenSize.desktop:
        return 16;
    }
  }

  static double getCaptionFontSize(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return 12;
      case ScreenSize.tablet:
        return 13;
      case ScreenSize.desktop:
        return 14;
    }
  }

  // Responsive icon sizes
  static double getIconSize(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return 24;
      case ScreenSize.tablet:
        return 26;
      case ScreenSize.desktop:
        return 28;
    }
  }

  static double getSmallIconSize(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return 16;
      case ScreenSize.tablet:
        return 18;
      case ScreenSize.desktop:
        return 20;
    }
  }

  static double getLargeIconSize(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return 32;
      case ScreenSize.tablet:
        return 36;
      case ScreenSize.desktop:
        return 40;
    }
  }

  // Responsive card elevation
  static double getCardElevation(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return 2;
      case ScreenSize.tablet:
        return 4;
      case ScreenSize.desktop:
        return 6;
    }
  }

  // Responsive border radius
  static double getCardRadius(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return 12;
      case ScreenSize.tablet:
        return 14;
      case ScreenSize.desktop:
        return 16;
    }
  }

  static double getButtonRadius(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return 8;
      case ScreenSize.tablet:
        return 10;
      case ScreenSize.desktop:
        return 12;
    }
  }

  // Responsive container constraints
  static BoxConstraints getMaxWidthConstraint(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return const BoxConstraints(maxWidth: double.infinity);
      case ScreenSize.tablet:
        return const BoxConstraints(maxWidth: 800);
      case ScreenSize.desktop:
        return const BoxConstraints(maxWidth: 1200);
    }
  }

  // Grid configurations
  static int getGridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return 2;
    if (width < 600) return 2;
    if (width < 900) return 3;
    if (width < 1200) return 4;
    return 5;
  }

  static double getGridChildAspectRatio(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return 0.75;
      case ScreenSize.tablet:
        return 0.8;
      case ScreenSize.desktop:
        return 0.85;
    }
  }

  static double getGridSpacing(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return spaceXs;
      case ScreenSize.tablet:
        return spaceSm;
      case ScreenSize.desktop:
        return spaceMd;
    }
  }

  // Button heights
  static double getButtonHeight(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return 44;
      case ScreenSize.tablet:
        return 48;
      case ScreenSize.desktop:
        return 52;
    }
  }

  static double getSmallButtonHeight(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return 36;
      case ScreenSize.tablet:
        return 40;
      case ScreenSize.desktop:
        return 44;
    }
  }

  // App bar height
  static double getAppBarHeight(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return 56;
      case ScreenSize.tablet:
        return 64;
      case ScreenSize.desktop:
        return 72;
    }
  }

  // Light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        background: backgroundColor,
        error: errorColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor),
        ),
        filled: true,
        fillColor: surfaceColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);

  // Custom shadows
  static List<BoxShadow> getCardShadow({double elevation = 2}) {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: elevation * 2,
        offset: Offset(0, elevation),
      ),
    ];
  }

  static List<BoxShadow> getBottomShadow() {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 10,
        offset: const Offset(0, -2),
      ),
    ];
  }

  static List<BoxShadow> getElevatedShadow({double elevation = 4}) {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.15),
        blurRadius: elevation * 2,
        offset: Offset(0, elevation / 2),
      ),
    ];
  }
}

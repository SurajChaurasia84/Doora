import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeModeProvider = StateProvider<ThemeMode>((_) => ThemeMode.system);

class AppTheme {
  static ThemeData light() {
    final colors = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0A7E8C),
      brightness: Brightness.light,
    );
    return _buildTheme(colors);
  }

  static ThemeData dark() {
    final colors = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0A7E8C),
      brightness: Brightness.dark,
    );
    return _buildTheme(colors);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    const pageTransitions = PageTransitionsTheme(
      builders: {
        TargetPlatform.android: AppFadePageTransitionsBuilder(),
        TargetPlatform.iOS: AppFadePageTransitionsBuilder(),
        TargetPlatform.linux: AppFadePageTransitionsBuilder(),
        TargetPlatform.macOS: AppFadePageTransitionsBuilder(),
        TargetPlatform.windows: AppFadePageTransitionsBuilder(),
      },
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      pageTransitionsTheme: pageTransitions,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}

class AppFadePageTransitionsBuilder extends PageTransitionsBuilder {
  const AppFadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubicEmphasized,
    );
    return FadeTransition(opacity: curved, child: child);
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';

import 'l10n/generated/app_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/session.dart';
import 'theme/cameroon_colors.dart';
import 'theme/locale_controller.dart';
import 'theme/theme_controller.dart';

void main() {
  // Needed for the Windows/Linux desktop video backend used by
  // AuthScaffold's login background video.
  if (!kIsWeb) {
    MediaKit.ensureInitialized();
  }
  runApp(const GlobeTrotterApp());
}

ThemeData _buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final colorScheme = ColorScheme.fromSeed(
    seedColor: CameroonColors.green,
    secondary: CameroonColors.sunsetOrange,
    tertiary: CameroonColors.oceanBlue,
    brightness: brightness,
  );
  final baseTextTheme = isDark ? GoogleFonts.interTextTheme(ThemeData(brightness: Brightness.dark).textTheme) : GoogleFonts.interTextTheme();
  final headingFont = isDark ? GoogleFonts.poppinsTextTheme(ThemeData(brightness: Brightness.dark).textTheme) : GoogleFonts.poppinsTextTheme();

  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: isDark ? const Color(0xFF14181A) : const Color(0xFFFAF8F4),
    textTheme: baseTextTheme.copyWith(
      headlineLarge: headingFont.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
      headlineMedium: headingFont.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
      headlineSmall: headingFont.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      titleLarge: headingFont.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: headingFont.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: headingFont.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: CameroonColors.sunsetOrange, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shadowColor: isDark ? Colors.black54 : CameroonColors.greenDark.withValues(alpha: 0.18),
      surfaceTintColor: isDark ? const Color(0xFF1E2426) : Colors.white,
      color: isDark ? const Color(0xFF1E2426) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: EdgeInsets.zero,
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide.none,
      backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: CameroonColors.green,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: isDark ? const Color(0xFF1E2426) : Colors.white,
      elevation: 4,
      indicatorColor: CameroonColors.sunsetOrange.withValues(alpha: 0.16),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return GoogleFonts.inter(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? CameroonColors.sunsetOrange : (isDark ? Colors.white70 : Colors.black54),
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(color: selected ? CameroonColors.sunsetOrange : (isDark ? Colors.white70 : Colors.black54));
      }),
    ),
  );
}

class GlobeTrotterApp extends StatelessWidget {
  const GlobeTrotterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => Session()),
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => LocaleController()),
      ],
      child: Consumer2<ThemeController, LocaleController>(
        builder: (context, themeController, localeController, _) => MaterialApp(
          title: 'GlobeTrotter',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          themeMode: themeController.mode,
          locale: localeController.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const _StartupGate(),
        ),
      ),
    );
  }
}

/// Restores a saved session (if any) before deciding whether to show the
/// login screen or jump straight to the authenticated home screen.
class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    Future.wait([
      context.read<Session>().restore(),
      context.read<ThemeController>().restore(),
      context.read<LocaleController>().restore(),
    ]).then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final session = context.watch<Session>();
    return session.isLoggedIn ? const HomeScreen() : const LoginScreen();
  }
}
